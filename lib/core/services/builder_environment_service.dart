import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/builder_environment.dart';
import '../models/tool_status.dart';
import 'toolchain_service.dart';

class BuilderEnvironmentService {
  Process? _activeInstallProcess;
  ContainerRuntime? _activeInstallRuntime;
  BuilderEnvironment? _activeInstallBuilder;
  var _cancelInstallRequested = false;

  Future<ToolAvailability> runtimeAvailability() async {
    final runtime = await resolveRuntime();
    return runtime == null
        ? ToolAvailability.missing
        : ToolAvailability.installed;
  }

  Future<ContainerRuntime?> resolveRuntime() async {
    for (final executable in const ['docker', 'podman']) {
      final file = await _findExecutable(executable);
      if (file == null) {
        continue;
      }
      final result =
          await Process.run(
            file.path,
            ['--version'],
            stdoutEncoding: utf8,
            stderrEncoding: utf8,
          ).timeout(
            const Duration(seconds: 4),
            onTimeout: () {
              return ProcessResult(0, 124, '', 'Timed out');
            },
          );
      if (result.exitCode == 0) {
        return ContainerRuntime(executable: file.path, name: executable);
      }
    }
    return null;
  }

  Future<ToolAvailability> builderAvailability(
    BuilderEnvironment builder,
  ) async {
    final runtime = await resolveRuntime();
    if (runtime == null) {
      return ToolAvailability.missing;
    }
    final result = await Process.run(
      runtime.executable,
      ['image', 'inspect', builder.imageTag],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return result.exitCode == 0
        ? ToolAvailability.installed
        : ToolAvailability.available;
  }

  Stream<BuilderInstallEvent> installBuilder(
    BuilderEnvironment builder,
  ) async* {
    final runtime = await resolveRuntime();
    if (runtime == null) {
      yield const BuilderInstallEvent.result(
        ToolInstallResult.failure(
          'Docker or Podman was not found. Install a container runtime first.',
        ),
      );
      return;
    }

    Directory? contextDirectory;
    Process? process;
    _cancelInstallRequested = false;
    _activeInstallRuntime = runtime;
    _activeInstallBuilder = builder;
    final stopwatch = Stopwatch()..start();
    var lastDetail = 'Preparing builder context.';

    try {
      contextDirectory = await Directory.systemTemp.createTemp(
        'pack_foundry_builder_',
      );
      final dockerfile = File(_joinPath(contextDirectory.path, 'Dockerfile'));
      await dockerfile.writeAsString(builder.dockerfile);
      yield BuilderInstallEvent.progress(
        _progressForElapsed(builder, stopwatch.elapsed),
        _remainingForElapsed(builder, stopwatch.elapsed),
        lastDetail,
      );

      process = await Process.start(runtime.executable, [
        'build',
        '--progress=plain',
        '-t',
        builder.imageTag,
        contextDirectory.path,
      ]);
      _activeInstallProcess = process;

      final outputTail = _OutputTail(maxLines: 80);
      final lines = _processLines(process);
      final exitCodeFuture = process.exitCode;
      var nextTick = DateTime.now();

      await for (final line in lines) {
        outputTail.add(line);
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          lastDetail = trimmed;
        }
        final now = DateTime.now();
        if (!now.isBefore(nextTick)) {
          nextTick = now.add(const Duration(seconds: 1));
          yield BuilderInstallEvent.progress(
            _progressForElapsed(builder, stopwatch.elapsed),
            _remainingForElapsed(builder, stopwatch.elapsed),
            lastDetail,
          );
        }
      }

      final exitCode = await exitCodeFuture;
      if (_cancelInstallRequested) {
        await Process.run(
          runtime.executable,
          ['image', 'rm', '-f', builder.imageTag],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        yield const BuilderInstallEvent.result(
          ToolInstallResult.failure(
            'Builder installation was cancelled. Temporary files and image tag were removed.',
          ),
        );
        return;
      }
      if (exitCode == 0) {
        yield const BuilderInstallEvent.progress(
          100,
          0,
          'Builder image is ready.',
        );
        yield BuilderInstallEvent.result(
          ToolInstallResult.success(
            '${builder.title} image is ready: ${builder.imageTag}.',
          ),
        );
        return;
      }

      yield BuilderInstallEvent.result(
        ToolInstallResult.failure(
          outputTail.text.isEmpty
              ? 'Container build exited with code $exitCode.'
              : outputTail.text,
        ),
      );
    } on ProcessException catch (error) {
      yield BuilderInstallEvent.result(
        ToolInstallResult.failure(error.message),
      );
    } on FileSystemException catch (error) {
      yield BuilderInstallEvent.result(
        ToolInstallResult.failure(error.message),
      );
    } finally {
      stopwatch.stop();
      if (identical(_activeInstallProcess, process)) {
        _activeInstallProcess = null;
        _activeInstallRuntime = null;
        _activeInstallBuilder = null;
      }
      if (contextDirectory != null && contextDirectory.existsSync()) {
        await contextDirectory.delete(recursive: true);
      }
    }
  }

  int _progressForElapsed(BuilderEnvironment builder, Duration elapsed) {
    final estimate = builder.estimatedInstallSeconds;
    if (estimate <= 0) {
      return 10;
    }
    final ratio = elapsed.inSeconds / estimate;
    return (8 + ratio.clamp(0, 1) * 87).round().clamp(8, 95);
  }

  int _remainingForElapsed(BuilderEnvironment builder, Duration elapsed) {
    final remaining = builder.estimatedInstallSeconds - elapsed.inSeconds;
    return remaining <= 0 ? 0 : remaining;
  }

  Stream<String> _processLines(Process process) {
    final controller = StreamController<String>();
    var openStreams = 2;

    void closeWhenReady() {
      openStreams -= 1;
      if (openStreams == 0) {
        unawaited(controller.close());
      }
    }

    void addLine(String line) {
      if (!controller.isClosed) {
        controller.add(line);
      }
    }

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(addLine, onDone: closeWhenReady, onError: controller.addError);
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(addLine, onDone: closeWhenReady, onError: controller.addError);

    return controller.stream;
  }

  Future<void> cancelActiveInstall() async {
    _cancelInstallRequested = true;
    _activeInstallProcess?.kill(ProcessSignal.sigterm);

    final runtime = _activeInstallRuntime;
    final builder = _activeInstallBuilder;
    if (runtime != null && builder != null) {
      await Process.run(
        runtime.executable,
        ['image', 'rm', '-f', builder.imageTag],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    }
  }

  Future<ToolInstallResult> removeBuilder(BuilderEnvironment builder) async {
    final runtime = await resolveRuntime();
    if (runtime == null) {
      return const ToolInstallResult.failure('Docker or Podman was not found.');
    }

    final result = await Process.run(
      runtime.executable,
      ['image', 'rm', builder.imageTag],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode == 0) {
      return ToolInstallResult.success(
        'Removed ${builder.title} image: ${builder.imageTag}.',
      );
    }
    return ToolInstallResult.failure(_shortProcessOutput(result));
  }

  Future<File?> _findExecutable(String executableName) async {
    final pathVariable = Platform.environment['PATH'];
    if (pathVariable == null || pathVariable.isEmpty) {
      return null;
    }

    for (final directory in pathVariable.split(':')) {
      final candidate = File(_joinPath(directory, executableName));
      if (candidate.existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  String _shortProcessOutput(ProcessResult result) {
    final output = [
      result.stdout.toString().trim(),
      result.stderr.toString().trim(),
    ].where((part) => part.isNotEmpty).join('\n');

    if (output.isEmpty) {
      return 'Process exited with code ${result.exitCode}.';
    }

    const maxLength = 1200;
    if (output.length <= maxLength) {
      return output;
    }
    return output.substring(output.length - maxLength);
  }

  String _joinPath(String first, String second) {
    if (second.isEmpty) {
      return first;
    }
    final normalizedSecond = second.replaceAll('/', Platform.pathSeparator);
    if (first.endsWith(Platform.pathSeparator)) {
      return '$first$normalizedSecond';
    }
    return '$first${Platform.pathSeparator}$normalizedSecond';
  }
}

class ContainerRuntime {
  const ContainerRuntime({required this.executable, required this.name});

  final String executable;
  final String name;

  String get displayName {
    return switch (name) {
      'docker' => 'Docker',
      'podman' => 'Podman',
      final value => value,
    };
  }
}

class BuilderInstallEvent {
  const BuilderInstallEvent.progress(
    this.progress,
    this.remainingSeconds,
    this.detail,
  ) : result = null;

  const BuilderInstallEvent.result(this.result)
    : progress = null,
      remainingSeconds = null,
      detail = null;

  final int? progress;
  final int? remainingSeconds;
  final String? detail;
  final ToolInstallResult? result;
}

class _OutputTail {
  _OutputTail({required this.maxLines});

  final int maxLines;
  final List<String> _lines = [];

  void add(String line) {
    _lines.add(line);
    if (_lines.length > maxLines) {
      _lines.removeAt(0);
    }
  }

  String get text => _lines.join('\n');
}

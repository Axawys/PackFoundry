import 'dart:io';

import '../models/package_inspection.dart';

class PackageInspectorService {
  const PackageInspectorService();

  static const _maxFileTreeDepth = 5;
  static const _maxFileTreeNodes = 700;

  Future<PackageInspection> inspect(String path) async {
    final file = File(path);
    final stat = await file.stat();
    final fileName = _fileName(path);
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.deb')) {
      return _inspectDeb(path, fileName, stat.size);
    }
    if (lower.endsWith('.rpm')) {
      return _inspectRpm(path, fileName, stat.size);
    }
    if (lower.endsWith('.appimage')) {
      return _basicInspection(
        path: path,
        fileName: fileName,
        format: 'AppImage',
        sizeBytes: stat.size,
        note:
            'AppImage metadata is embedded in the image. Edit it by rebuilding the AppImage from the project.',
      );
    }
    if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
      return _inspectArchive(path, fileName, stat.size, 'tar.gz');
    }
    if (lower.endsWith('.apk')) {
      return _inspectArchive(path, fileName, stat.size, 'APK');
    }
    if (lower.endsWith('.exe')) {
      return _basicInspection(
        path: path,
        fileName: fileName,
        format: 'EXE',
        sizeBytes: stat.size,
        note:
            'Windows installer metadata is compiled into the EXE. Edit it through the Inno Setup script and rebuild.',
      );
    }
    if (lower.endsWith('.zip')) {
      return _inspectArchive(path, fileName, stat.size, 'ZIP');
    }

    return _basicInspection(
      path: path,
      fileName: fileName,
      format: 'Unknown',
      sizeBytes: stat.size,
      note: 'PackFoundry does not know this package format yet.',
    );
  }

  Future<String> saveDebMetadata({
    required String packagePath,
    required String metadata,
    required String dependencies,
  }) async {
    final source = File(packagePath);
    final sourceName = _fileName(packagePath);
    final directory = source.parent.path;
    final outputName = sourceName.toLowerCase().endsWith('.deb')
        ? sourceName.replaceFirst(RegExp(r'\.deb$', caseSensitive: false), '')
        : sourceName;
    final outputPath = _joinPath(directory, '${outputName}_edited.deb');
    final temp = await Directory.systemTemp.createTemp(
      'pack_foundry_package_edit_',
    );

    try {
      final root = Directory(_joinPath(temp.path, 'root'));
      final extract = await Process.run('dpkg-deb', [
        '-R',
        packagePath,
        root.path,
      ]);
      if (extract.exitCode != 0) {
        throw PackageInspectorException(_processOutput(extract));
      }

      final controlFile = File(_joinPath(root.path, 'DEBIAN/control'));
      if (!controlFile.existsSync()) {
        throw const PackageInspectorException('DEBIAN/control was not found.');
      }

      final fields = _parseDebControl(metadata);
      final dependencyText = dependencies
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .join(', ');
      fields['Depends'] = dependencyText;
      await controlFile.writeAsString(_formatDebControl(fields));

      final build = await Process.run('dpkg-deb', [
        '--build',
        '--root-owner-group',
        root.path,
        outputPath,
      ]);
      if (build.exitCode != 0) {
        throw PackageInspectorException(_processOutput(build));
      }

      return outputPath;
    } finally {
      if (temp.existsSync()) {
        await temp.delete(recursive: true);
      }
    }
  }

  Future<PackageInspection> _inspectDeb(
    String path,
    String fileName,
    int sizeBytes,
  ) async {
    final extractedDirectory = await _extractDeb(path);
    final iconPath = extractedDirectory == null
        ? null
        : _findPackageIcon(extractedDirectory);
    final fileTree = extractedDirectory == null
        ? const <PackageFileNode>[]
        : _buildFileTree(extractedDirectory);
    final result = await Process.run('dpkg-deb', ['-f', path]);
    if (result.exitCode != 0) {
      return _basicInspection(
        path: path,
        fileName: fileName,
        format: 'DEB',
        sizeBytes: sizeBytes,
        fileTree: fileTree,
        iconPath: iconPath,
        note:
            'dpkg-deb could not read package metadata: ${_processOutput(result)}',
      );
    }

    final fields = _parseDebControl(result.stdout.toString());
    final dependencies = _splitDependencies(fields['Depends']);
    return PackageInspection(
      path: path,
      fileName: fileName,
      format: 'DEB',
      sizeBytes: sizeBytes,
      fields: fields,
      dependencies: dependencies,
      editable: true,
      saveSupported: true,
      fileTree: fileTree,
      iconPath: iconPath,
      note: 'DEB dependencies can be edited and saved into a new package copy.',
    );
  }

  Future<PackageInspection> _inspectRpm(
    String path,
    String fileName,
    int sizeBytes,
  ) async {
    final extractedDirectory = await _extractRpm(path);
    final iconPath = extractedDirectory == null
        ? null
        : _findPackageIcon(extractedDirectory);
    final fileTree = extractedDirectory == null
        ? const <PackageFileNode>[]
        : _buildFileTree(extractedDirectory);
    final info = await Process.run('rpm', ['-qpi', path]);
    final requires = await Process.run('rpm', ['-qpR', path]);
    if (info.exitCode != 0) {
      return _basicInspection(
        path: path,
        fileName: fileName,
        format: 'RPM',
        sizeBytes: sizeBytes,
        fileTree: fileTree,
        iconPath: iconPath,
        note: 'rpm could not read package metadata: ${_processOutput(info)}',
      );
    }

    return PackageInspection(
      path: path,
      fileName: fileName,
      format: 'RPM',
      sizeBytes: sizeBytes,
      fields: _parseRpmInfo(info.stdout.toString()),
      dependencies: requires.exitCode == 0
          ? _nonEmptyLines(requires.stdout.toString())
          : const [],
      editable: false,
      saveSupported: false,
      fileTree: fileTree,
      iconPath: iconPath,
      note:
          'RPM dependencies are stored in signed package metadata. Edit Requires in the build recipe and rebuild the RPM.',
    );
  }

  Future<PackageInspection> _inspectArchive(
    String path,
    String fileName,
    int sizeBytes,
    String format,
  ) async {
    final lowerFormat = format.toLowerCase();
    final extractedDirectory = await _extractArchive(path, lowerFormat);
    final iconPath = extractedDirectory == null
        ? null
        : _findPackageIcon(extractedDirectory);
    final fileTree = extractedDirectory == null
        ? const <PackageFileNode>[]
        : _buildFileTree(extractedDirectory);
    final result = lowerFormat == 'tar.gz'
        ? await Process.run('tar', ['-tzf', path])
        : await Process.run('unzip', ['-l', path]);
    final fields = <String, String>{};
    if (result.exitCode == 0) {
      fields['Contents preview'] = _nonEmptyLines(
        result.stdout.toString(),
      ).take(20).join('\n');
    }
    return PackageInspection(
      path: path,
      fileName: fileName,
      format: format,
      sizeBytes: sizeBytes,
      fields: fields,
      dependencies: const [],
      editable: false,
      saveSupported: false,
      fileTree: fileTree,
      iconPath: iconPath,
      note:
          '$format does not expose Linux package dependencies. Change metadata during build and rebuild the artifact.',
    );
  }

  PackageInspection _basicInspection({
    required String path,
    required String fileName,
    required String format,
    required int sizeBytes,
    List<PackageFileNode> fileTree = const [],
    String? iconPath,
    required String note,
  }) {
    return PackageInspection(
      path: path,
      fileName: fileName,
      format: format,
      sizeBytes: sizeBytes,
      fields: const {},
      dependencies: const [],
      editable: false,
      saveSupported: false,
      fileTree: fileTree,
      iconPath: iconPath,
      note: note,
    );
  }

  Future<Directory?> _extractDeb(String packagePath) async {
    final directory = await Directory.systemTemp.createTemp(
      'pack_foundry_package_inspect_',
    );
    final result = await Process.run('dpkg-deb', [
      '-R',
      packagePath,
      directory.path,
    ]);
    if (result.exitCode != 0) {
      await _deleteDirectoryIfEmpty(directory);
      return null;
    }
    return directory;
  }

  Future<Directory?> _extractRpm(String packagePath) async {
    final directory = await Directory.systemTemp.createTemp(
      'pack_foundry_package_inspect_',
    );
    final result = await Process.run('bash', [
      '-lc',
      r'cd "$1" && rpm2cpio "$2" | cpio -id --quiet',
      '_',
      directory.path,
      packagePath,
    ]);
    if (result.exitCode != 0) {
      await _deleteDirectoryIfEmpty(directory);
      return null;
    }
    return directory;
  }

  Future<Directory?> _extractArchive(String packagePath, String format) async {
    if (format != 'tar.gz' && format != 'apk' && format != 'zip') {
      return null;
    }
    final directory = await Directory.systemTemp.createTemp(
      'pack_foundry_package_inspect_',
    );
    final result = format == 'tar.gz'
        ? await Process.run('tar', ['-xzf', packagePath, '-C', directory.path])
        : await Process.run('unzip', ['-q', packagePath, '-d', directory.path]);
    if (result.exitCode != 0) {
      await _deleteDirectoryIfEmpty(directory);
      return null;
    }
    return directory;
  }

  List<PackageFileNode> _buildFileTree(Directory root) {
    var remainingNodes = _maxFileTreeNodes;
    return _buildDirectoryChildren(
      root,
      root.path,
      depth: 0,
      remainingNodes: () => remainingNodes,
      consumeNode: () => remainingNodes--,
    );
  }

  List<PackageFileNode> _buildDirectoryChildren(
    Directory directory,
    String rootPath, {
    required int depth,
    required int Function() remainingNodes,
    required void Function() consumeNode,
  }) {
    if (depth >= _maxFileTreeDepth || remainingNodes() <= 0) {
      return const [];
    }

    final entities = directory.listSync(followLinks: false)
      ..sort((a, b) {
        final aIsDirectory = a is Directory;
        final bIsDirectory = b is Directory;
        if (aIsDirectory != bIsDirectory) {
          return aIsDirectory ? -1 : 1;
        }
        return _fileName(
          a.path,
        ).toLowerCase().compareTo(_fileName(b.path).toLowerCase());
      });

    final nodes = <PackageFileNode>[];
    for (final entity in entities) {
      if (remainingNodes() <= 0) {
        break;
      }
      consumeNode();
      final name = _fileName(entity.path);
      final relativePath = _relativePath(rootPath, entity.path);
      if (entity is Directory) {
        nodes.add(
          PackageFileNode(
            name: name,
            path: relativePath,
            isDirectory: true,
            children: _buildDirectoryChildren(
              entity,
              rootPath,
              depth: depth + 1,
              remainingNodes: remainingNodes,
              consumeNode: consumeNode,
            ),
          ),
        );
      } else if (entity is File) {
        int? size;
        try {
          size = entity.lengthSync();
        } on FileSystemException {
          size = null;
        }
        nodes.add(
          PackageFileNode(
            name: name,
            path: relativePath,
            isDirectory: false,
            sizeBytes: size,
          ),
        );
      }
    }
    return nodes;
  }

  String? _findPackageIcon(Directory directory) {
    final candidates = <File>[];
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final lower = entity.path.toLowerCase();
      if (!lower.endsWith('.png') && !lower.endsWith('.svg')) {
        continue;
      }
      if (lower.contains('/usr/share/icons/') ||
          lower.contains('/usr/share/pixmaps/') ||
          lower.endsWith('/.diricon') ||
          lower.contains('pack_foundry_window_icon')) {
        candidates.add(entity);
      }
    }
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((a, b) => _iconScore(b).compareTo(_iconScore(a)));
    return candidates.first.path;
  }

  int _iconScore(File file) {
    final path = file.path.toLowerCase();
    var score = 0;
    if (path.endsWith('.png')) {
      score += 1000;
    }
    if (path.contains('/apps/')) {
      score += 500;
    }
    if (path.contains('256x256')) {
      score += 256;
    } else if (path.contains('128x128')) {
      score += 128;
    } else if (path.contains('64x64')) {
      score += 64;
    } else if (path.contains('scalable')) {
      score += 48;
    }
    return score;
  }

  Future<String?> _deleteDirectoryIfEmpty(Directory directory) async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
    return null;
  }

  Map<String, String> _parseDebControl(String text) {
    final fields = <String, String>{};
    String? currentKey;
    for (final line in text.replaceAll('\r\n', '\n').split('\n')) {
      if (line.isEmpty) {
        continue;
      }
      if ((line.startsWith(' ') || line.startsWith('\t')) &&
          currentKey != null) {
        fields[currentKey] = '${fields[currentKey]}\n${line.trim()}';
        continue;
      }
      final separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      currentKey = line.substring(0, separator).trim();
      fields[currentKey] = line.substring(separator + 1).trim();
    }
    return fields;
  }

  String _formatDebControl(Map<String, String> fields) {
    const preferredOrder = [
      'Package',
      'Version',
      'Section',
      'Priority',
      'Architecture',
      'Maintainer',
      'Depends',
      'Description',
    ];
    final orderedKeys = [
      for (final key in preferredOrder)
        if (fields.containsKey(key)) key,
      for (final key in fields.keys)
        if (!preferredOrder.contains(key)) key,
    ];
    return [
      for (final key in orderedKeys) '$key: ${fields[key]}',
      '',
    ].join('\n');
  }

  Map<String, String> _parseRpmInfo(String text) {
    final fields = <String, String>{};
    for (final line in text.replaceAll('\r\n', '\n').split('\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      fields[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }
    return fields;
  }

  List<String> _splitDependencies(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const [];
    }
    return [
      for (final dependency in value.split(','))
        if (dependency.trim().isNotEmpty) dependency.trim(),
    ];
  }

  List<String> _nonEmptyLines(String text) {
    return [
      for (final line in text.replaceAll('\r\n', '\n').split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }

  String _processOutput(ProcessResult result) {
    final stderr = result.stderr.toString().trim();
    if (stderr.isNotEmpty) {
      return stderr;
    }
    final stdout = result.stdout.toString().trim();
    return stdout.isEmpty ? 'Command failed with ${result.exitCode}.' : stdout;
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _relativePath(String rootPath, String path) {
    if (!path.startsWith(rootPath)) {
      return path;
    }
    final relative = path.substring(rootPath.length);
    return relative
        .replaceFirst(RegExp('^${RegExp.escape(Platform.pathSeparator)}'), '')
        .replaceAll(Platform.pathSeparator, '/');
  }

  String _joinPath(String first, String second) {
    if (first.endsWith(Platform.pathSeparator)) {
      return '$first$second';
    }
    return '$first${Platform.pathSeparator}$second';
  }
}

class PackageInspectorException implements Exception {
  const PackageInspectorException(this.message);

  final String message;

  @override
  String toString() => message;
}

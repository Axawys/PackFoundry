import 'dart:io';

import '../models/tool_status.dart';

class ToolchainService {
  Future<ToolAvailability> commandAvailability(
    String executable,
    List<String> arguments,
  ) async {
    try {
      final result = await Process.run(
        executable,
        arguments,
        runInShell: true,
      ).timeout(const Duration(seconds: 4));
      return result.exitCode == 0
          ? ToolAvailability.installed
          : ToolAvailability.missing;
    } on Object {
      return ToolAvailability.missing;
    }
  }

  Future<bool> anyCommandAvailable(List<CommandCheck> checks) async {
    for (final check in checks) {
      final status = await commandAvailability(
        check.executable,
        check.arguments,
      );
      if (status == ToolAvailability.installed) {
        return true;
      }
    }
    return false;
  }

  Future<bool> allCommandsAvailable(List<CommandCheck> checks) async {
    for (final check in checks) {
      final status = await commandAvailability(
        check.executable,
        check.arguments,
      );
      if (status != ToolAvailability.installed) {
        return false;
      }
    }
    return true;
  }
}

class CommandCheck {
  const CommandCheck(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}

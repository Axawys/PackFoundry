import 'build_target.dart';

class BuildConfiguration {
  const BuildConfiguration({
    required this.appName,
    required this.projectPath,
    required this.outputPath,
    required this.targets,
  });

  final String appName;
  final String projectPath;
  final String? outputPath;
  final List<BuildTarget> targets;
}

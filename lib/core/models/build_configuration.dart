import 'build_target.dart';

class BuildConfiguration {
  const BuildConfiguration({
    required this.appName,
    required this.projectPath,
    required this.outputPath,
    required this.iconPath,
    required this.windowWidth,
    required this.windowHeight,
    required this.targets,
  });

  final String appName;
  final String projectPath;
  final String? outputPath;
  final String? iconPath;
  final int? windowWidth;
  final int? windowHeight;
  final List<BuildTarget> targets;
}

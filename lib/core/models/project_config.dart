import 'build_configuration.dart';

class ProjectConfig {
  const ProjectConfig({
    required this.projectPath,
    required this.outputPath,
    required this.iconPath,
    required this.appName,
    required this.releaseTag,
    required this.developerEmail,
    required this.publisherName,
    required this.homepageUrl,
    required this.license,
    required this.description,
    required this.windowWidth,
    required this.windowHeight,
    required this.packageTypes,
    this.additionalDependencies = const {},
  });

  static const chooseInPackFoundry = r'$choose_in_packfoundry';
  static const schema = 'packfoundry.config.v1';

  final String? projectPath;
  final String? outputPath;
  final String? iconPath;
  final String? appName;
  final String? releaseTag;
  final String? developerEmail;
  final String? publisherName;
  final String? homepageUrl;
  final String? license;
  final String? description;
  final int? windowWidth;
  final int? windowHeight;
  final List<String> packageTypes;
  final Map<String, String> additionalDependencies;

  bool get choosesProject => _isChooseMarker(projectPath);
  bool get choosesOutput => _isChooseMarker(outputPath);
  bool get choosesIcon => _isChooseMarker(iconPath);

  Map<String, Object?> toJson() {
    return {
      'schema': schema,
      'projectPath': projectPath ?? chooseInPackFoundry,
      'outputPath': outputPath ?? chooseInPackFoundry,
      'iconPath': iconPath ?? chooseInPackFoundry,
      'appName': appName,
      'releaseTag': releaseTag,
      'developerEmail': developerEmail,
      'publisherName': publisherName,
      'homepageUrl': homepageUrl,
      'license': license,
      'description': description,
      'window': {'width': windowWidth, 'height': windowHeight},
      'packageTypes': packageTypes,
      'additionalDependencies': additionalDependencies,
    };
  }

  static ProjectConfig fromJson(Map<String, Object?> json) {
    final window = json['window'];
    final additionalDependencies = json['additionalDependencies'];
    return ProjectConfig(
      projectPath: _stringValue(json['projectPath']),
      outputPath: _stringValue(json['outputPath']),
      iconPath: _stringValue(json['iconPath']),
      appName: _stringValue(json['appName']),
      releaseTag: _stringValue(json['releaseTag']),
      developerEmail: _stringValue(json['developerEmail']),
      publisherName: _stringValue(json['publisherName']),
      homepageUrl: _stringValue(json['homepageUrl']),
      license: _stringValue(json['license']),
      description: _stringValue(json['description']),
      windowWidth: window is Map ? _intValue(window['width']) : null,
      windowHeight: window is Map ? _intValue(window['height']) : null,
      packageTypes: _packageTypes(json),
      additionalDependencies: additionalDependencies is Map
          ? _stringMap(additionalDependencies)
          : const {},
    );
  }

  static ProjectConfig fromBuildConfiguration(BuildConfiguration config) {
    return ProjectConfig(
      projectPath: config.projectPath,
      outputPath: config.outputPath,
      iconPath: config.iconPath,
      appName: config.appName,
      releaseTag: config.releaseTag,
      developerEmail: config.developerEmail,
      publisherName: config.publisherName,
      homepageUrl: config.homepageUrl,
      license: config.license,
      description: config.description,
      windowWidth: config.windowWidth,
      windowHeight: config.windowHeight,
      packageTypes: [
        for (final target in config.targets)
          if (target.selected)
            packageTypeForTarget(target.platform, target.artifact),
      ],
      additionalDependencies: config.additionalDependencies,
    );
  }

  static String packageTypeForTarget(String platform, String artifact) {
    return switch ((platform, artifact)) {
      ('Linux', 'AppImage') => 'appimage',
      ('Linux', 'deb package') => 'deb',
      ('Linux', 'rpm package') => 'rpm',
      ('Linux', 'tar.gz bundle') => 'tar.gz',
      ('Windows', 'Inno Setup exe') => 'exe',
      ('Android', 'APK') => 'apk',
      ('macOS', 'dmg') => 'dmg',
      ('iOS', 'ipa') => 'ipa',
      _ => '${platform.toLowerCase()}:${artifact.toLowerCase()}',
    };
  }

  static bool targetMatchesPackageType(
    String packageType,
    String platform,
    String artifact,
  ) {
    final normalized = packageType.trim().toLowerCase();
    return normalized == packageTypeForTarget(platform, artifact) ||
        normalized == artifact.toLowerCase() ||
        normalized == '$platform:$artifact'.toLowerCase();
  }

  static bool _isChooseMarker(String? value) {
    return value == null ||
        value.trim().isEmpty ||
        value.trim() == chooseInPackFoundry;
  }

  static String? _stringValue(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static List<String> _packageTypes(Map<String, Object?> json) {
    final rawTypes =
        json['packageTypes'] ?? json['targets'] ?? json['packages'];
    if (rawTypes is! List) {
      return const [];
    }

    return [
      for (final value in rawTypes)
        if (value is String && value.trim().isNotEmpty) value.trim(),
    ];
  }

  static Map<String, String> _stringMap(Map<Object?, Object?> values) {
    return {
      for (final entry in values.entries)
        if (entry.key is String && entry.value is String)
          (entry.key! as String).trim(): (entry.value! as String).trim(),
    }..removeWhere((key, value) => key.isEmpty || value.isEmpty);
  }
}

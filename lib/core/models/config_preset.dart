import 'project_config.dart';

/// A config file pinned in the project workspace so it can be applied with one
/// click. Presets live on disk: the list only keeps paths, and an entry
/// disappears once its file is gone.
class ConfigPreset {
  const ConfigPreset({
    required this.path,
    required this.name,
    this.iconPath,
    this.packageTypes = const [],
    this.isBroken = false,
  });

  factory ConfigPreset.fromConfig(String path, ProjectConfig config) {
    return ConfigPreset(
      path: path,
      name: displayNameOf(path),
      iconPath: config.choosesIcon ? null : config.iconPath,
      packageTypes: config.packageTypes,
    );
  }

  factory ConfigPreset.broken(String path) {
    return ConfigPreset(path: path, name: displayNameOf(path), isBroken: true);
  }

  final String path;
  final String name;

  /// Icon declared by the config, already resolved against the config folder.
  final String? iconPath;
  final List<String> packageTypes;
  final bool isBroken;

  /// SVG icons are valid in a config but cannot be decoded by `Image.file`,
  /// so only raster icons are offered to the card.
  String? get bitmapIconPath {
    final path = iconPath;
    if (path == null) {
      return null;
    }
    final lower = path.toLowerCase();
    const supported = ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif'];
    return supported.any(lower.endsWith) ? path : null;
  }

  static String fileNameOf(String path) {
    final separator = path.lastIndexOf(RegExp(r'[/\\]'));
    final name = separator == -1 ? path : path.substring(separator + 1);
    return name.isEmpty ? path : name;
  }

  /// The file name without the `.json` extension, used as the preset label.
  static String displayNameOf(String path) {
    final name = fileNameOf(path);
    final extension = name.length - 5;
    if (extension > 0 && name.substring(extension).toLowerCase() == '.json') {
      return name.substring(0, extension);
    }
    return name;
  }
}

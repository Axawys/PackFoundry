class PackageInspection {
  const PackageInspection({
    required this.path,
    required this.fileName,
    required this.format,
    required this.sizeBytes,
    required this.fields,
    required this.dependencies,
    required this.editable,
    required this.saveSupported,
    this.fileTree = const [],
    this.iconPath,
    this.note,
  });

  final String path;
  final String fileName;
  final String format;
  final int sizeBytes;
  final Map<String, String> fields;
  final List<String> dependencies;
  final bool editable;
  final bool saveSupported;
  final List<PackageFileNode> fileTree;
  final String? iconPath;
  final String? note;

  String get dependencyText => dependencies.join('\n');
}

class PackageFileNode {
  const PackageFileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.sizeBytes,
    this.children = const [],
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? sizeBytes;
  final List<PackageFileNode> children;
}

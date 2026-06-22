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
  final String? note;

  String get dependencyText => dependencies.join('\n');
}

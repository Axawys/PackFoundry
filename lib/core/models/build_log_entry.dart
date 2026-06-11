class BuildLogEntry {
  const BuildLogEntry({
    required this.title,
    required this.detail,
    required this.state,
  });

  final String title;
  final String detail;
  final BuildLogState state;
}

enum BuildLogState { idle, running, success, warning }

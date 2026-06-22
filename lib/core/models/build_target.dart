class BuildTarget {
  BuildTarget({
    required this.platform,
    required this.artifact,
    required this.status,
    this.selected = false,
  });

  final String platform;
  final String artifact;
  TargetStatus status;
  bool selected;

  bool get canSelect {
    return status == TargetStatus.ready || status == TargetStatus.installable;
  }

  String get statusLabel {
    return switch (status) {
      TargetStatus.ready => 'Ready to build on this machine',
      TargetStatus.installable => 'Install extra tools to enable',
      TargetStatus.blocked => 'Blocked until SDK/toolchain is installed',
      TargetStatus.hostLimited => 'Requires native host or remote builder',
    };
  }
}

enum TargetStatus { ready, installable, blocked, hostLimited }

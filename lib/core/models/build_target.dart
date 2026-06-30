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

  /// Short, language-agnostic package-format label shown in the target picker
  /// (e.g. `appimage`, `deb`, `.exe`). Falls back to [artifact] for formats
  /// without a dedicated short name.
  String get displayLabel {
    return switch (artifact) {
      'AppImage' => 'appimage',
      'deb package' => 'deb',
      'rpm package' => 'rpm',
      'tar.gz bundle' => 'tar.gz',
      'Inno Setup exe' => '.exe',
      _ => artifact,
    };
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

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

class BuildRoadmapStep {
  const BuildRoadmapStep({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.state,
    this.progress = 0,
    this.estimatedSeconds,
    this.detail,
  });

  final String id;
  final int number;
  final String title;
  final String description;
  final BuildRoadmapStepState state;
  final int progress;
  final int? estimatedSeconds;
  final String? detail;

  BuildRoadmapStep copyWith({
    BuildRoadmapStepState? state,
    int? progress,
    String? detail,
  }) {
    return BuildRoadmapStep(
      id: id,
      number: number,
      title: title,
      description: description,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      estimatedSeconds: estimatedSeconds,
      detail: detail ?? this.detail,
    );
  }
}

class BuildRoadmapUpdate {
  const BuildRoadmapUpdate({
    required this.id,
    required this.state,
    this.progress,
    this.detail,
  });

  final String id;
  final BuildRoadmapStepState state;
  final int? progress;
  final String? detail;
}

enum BuildRoadmapStepState { pending, running, success, warning, skipped }

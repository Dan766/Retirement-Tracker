class ProjectionSettings {
  final double inflationRate;
  final List<int> timeHorizons;

  const ProjectionSettings({
    this.inflationRate = 2.5,
    this.timeHorizons = const [5, 10, 20, 30],
  });

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'inflationRate': inflationRate,
        'timeHorizons': timeHorizons,
      };

  factory ProjectionSettings.fromJson(Map<String, dynamic> json) =>
      ProjectionSettings(
        inflationRate: (json['inflationRate'] as num?)?.toDouble() ?? 2.5,
        timeHorizons: (json['timeHorizons'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [5, 10, 20, 30],
      );

  // CopyWith for editing
  ProjectionSettings copyWith({
    double? inflationRate,
    List<int>? timeHorizons,
  }) {
    return ProjectionSettings(
      inflationRate: inflationRate ?? this.inflationRate,
      timeHorizons: timeHorizons ?? this.timeHorizons,
    );
  }
}

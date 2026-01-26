class FireSettings {
  final double annualRetirementIncome;
  final bool useRealValue;

  const FireSettings({
    this.annualRetirementIncome = 0.0,
    this.useRealValue = true,
  });

  // Computed property: FIRE number using 4% rule (25x annual income)
  double get fireNumber =>
      annualRetirementIncome > 0 ? annualRetirementIncome * 25 : 0.0;

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'annualRetirementIncome': annualRetirementIncome,
        'useRealValue': useRealValue,
      };

  factory FireSettings.fromJson(Map<String, dynamic> json) => FireSettings(
        annualRetirementIncome:
            (json['annualRetirementIncome'] as num?)?.toDouble() ?? 0.0,
        useRealValue: json['useRealValue'] as bool? ?? true,
      );

  // CopyWith for editing
  FireSettings copyWith({
    double? annualRetirementIncome,
    bool? useRealValue,
  }) {
    return FireSettings(
      annualRetirementIncome:
          annualRetirementIncome ?? this.annualRetirementIncome,
      useRealValue: useRealValue ?? this.useRealValue,
    );
  }
}

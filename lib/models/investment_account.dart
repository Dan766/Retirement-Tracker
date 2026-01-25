enum ContributionFrequency { weekly, yearly }

class InvestmentAccount {
  final String id;
  final String name;
  final double currentBalance;
  final ContributionFrequency frequency;
  final double contributionAmount;
  final double expectedAnnualReturn;
  final DateTime createdDate;

  const InvestmentAccount({
    required this.id,
    required this.name,
    required this.currentBalance,
    required this.frequency,
    required this.contributionAmount,
    required this.expectedAnnualReturn,
    required this.createdDate,
  });

  // Computed properties
  double get weeklyContribution => frequency == ContributionFrequency.weekly
      ? contributionAmount
      : contributionAmount / 52;

  double get annualContribution => frequency == ContributionFrequency.yearly
      ? contributionAmount
      : contributionAmount * 52;

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currentBalance': currentBalance,
        'frequency': frequency.name,
        'contributionAmount': contributionAmount,
        'expectedAnnualReturn': expectedAnnualReturn,
        'createdDate': createdDate.toIso8601String(),
      };

  factory InvestmentAccount.fromJson(Map<String, dynamic> json) =>
      InvestmentAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        currentBalance: (json['currentBalance'] as num).toDouble(),
        frequency: ContributionFrequency.values.firstWhere(
          (e) => e.name == json['frequency'],
        ),
        contributionAmount: (json['contributionAmount'] as num).toDouble(),
        expectedAnnualReturn: (json['expectedAnnualReturn'] as num).toDouble(),
        createdDate: DateTime.parse(json['createdDate'] as String),
      );

  // CopyWith for editing
  InvestmentAccount copyWith({
    String? id,
    String? name,
    double? currentBalance,
    ContributionFrequency? frequency,
    double? contributionAmount,
    double? expectedAnnualReturn,
    DateTime? createdDate,
  }) {
    return InvestmentAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      currentBalance: currentBalance ?? this.currentBalance,
      frequency: frequency ?? this.frequency,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      expectedAnnualReturn: expectedAnnualReturn ?? this.expectedAnnualReturn,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

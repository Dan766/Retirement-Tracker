class Asset {
  final String id;
  final String name;
  final String category;
  final double currentValue;
  final double expectedAnnualGrowth;
  final DateTime purchaseDate;
  final String? notes;

  const Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.currentValue,
    required this.expectedAnnualGrowth,
    required this.purchaseDate,
    this.notes,
  });

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'currentValue': currentValue,
        'expectedAnnualGrowth': expectedAnnualGrowth,
        'purchaseDate': purchaseDate.toIso8601String(),
        'notes': notes,
      };

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        currentValue: (json['currentValue'] as num).toDouble(),
        expectedAnnualGrowth: (json['expectedAnnualGrowth'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchaseDate'] as String),
        notes: json['notes'] as String?,
      );

  // CopyWith for editing
  Asset copyWith({
    String? id,
    String? name,
    String? category,
    double? currentValue,
    double? expectedAnnualGrowth,
    DateTime? purchaseDate,
    String? notes,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentValue: currentValue ?? this.currentValue,
      expectedAnnualGrowth: expectedAnnualGrowth ?? this.expectedAnnualGrowth,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
    );
  }
}

// Asset category constants
class AssetCategory {
  static const String house = 'House';
  static const String car = 'Car';
  static const String collectibles = 'Collectibles';
  static const String other = 'Other';

  static const List<String> all = [house, car, collectibles, other];
}

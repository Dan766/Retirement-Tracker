import '../models/investment_account.dart';
import '../models/asset.dart';
import '../models/projection_settings.dart';
import '../models/fire_settings.dart';
import 'projection_calculator.dart';

class FireResult {
  final double fireNumber;
  final double currentPortfolio;
  final double currentProgress; // percentage
  final int? yearsToFire; // null if unachievable
  final DateTime? fireDate; // null if unachievable
  final bool isAchievable;
  final bool isAchieved; // true if already at FIRE number

  const FireResult({
    required this.fireNumber,
    required this.currentPortfolio,
    required this.currentProgress,
    this.yearsToFire,
    this.fireDate,
    required this.isAchievable,
    required this.isAchieved,
  });
}

class FireCalculator {
  /// Calculate comprehensive FIRE metrics
  static FireResult calculateFireMetrics({
    required FireSettings fireSettings,
    required List<InvestmentAccount> investments,
    required List<Asset> assets,
    required ProjectionSettings projectionSettings,
  }) {
    final fireNumber = fireSettings.fireNumber;
    final currentPortfolio = ProjectionCalculator.calculateCurrentTotal(
      investments: investments,
      assets: assets,
    );

    // Calculate progress percentage
    final progress = calculateCurrentProgress(
      currentPortfolio: currentPortfolio,
      fireNumber: fireNumber,
    );

    // Check if already achieved
    final isAchieved = currentPortfolio >= fireNumber && fireNumber > 0;

    // Calculate years to FIRE
    final yearsToFire = isAchieved
        ? 0
        : calculateYearsToFire(
            targetAmount: fireNumber,
            investments: investments,
            assets: assets,
            settings: projectionSettings,
            useRealValue: fireSettings.useRealValue,
          );

    // Calculate FIRE date
    final fireDate = yearsToFire != null
        ? DateTime.now().add(Duration(days: yearsToFire * 365))
        : null;

    return FireResult(
      fireNumber: fireNumber,
      currentPortfolio: currentPortfolio,
      currentProgress: progress,
      yearsToFire: yearsToFire,
      fireDate: fireDate,
      isAchievable: yearsToFire != null,
      isAchieved: isAchieved,
    );
  }

  /// Calculate current progress towards FIRE as a percentage
  static double calculateCurrentProgress({
    required double currentPortfolio,
    required double fireNumber,
  }) {
    if (fireNumber == 0) return 0;
    return (currentPortfolio / fireNumber) * 100;
  }

  /// Find the year when FIRE number is reached
  /// Returns null if unachievable within maxYears
  static int? calculateYearsToFire({
    required double targetAmount,
    required List<InvestmentAccount> investments,
    required List<Asset> assets,
    required ProjectionSettings settings,
    bool useRealValue = true,
    int maxYears = 50,
  }) {
    // If target is 0 or negative, not achievable
    if (targetAmount <= 0) return null;

    // Generate year-by-year projections
    final projections = ProjectionCalculator.calculateYearlyProjections(
      investments: investments,
      assets: assets,
      settings: settings,
      maxYears: maxYears,
    );

    // Find first year where portfolio meets or exceeds target
    for (int year = 0; year <= maxYears; year++) {
      final projection = projections[year];
      if (projection == null) continue;

      final portfolioValue =
          useRealValue ? projection.realValue : projection.nominalValue;

      if (portfolioValue >= targetAmount) {
        return year;
      }
    }

    // Not achievable within maxYears
    return null;
  }
}

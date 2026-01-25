import 'dart:math';
import '../models/investment_account.dart';
import '../models/asset.dart';
import '../models/projection_settings.dart';

class ProjectionResult {
  final int years;
  final double nominalValue;
  final double realValue;
  final double investmentsValue;
  final double assetsValue;
  final double inflationImpact;

  const ProjectionResult({
    required this.years,
    required this.nominalValue,
    required this.realValue,
    required this.investmentsValue,
    required this.assetsValue,
    required this.inflationImpact,
  });

  double get inflationPercentage =>
      nominalValue > 0 ? (inflationImpact / nominalValue) * 100 : 0;
}

class ProjectionCalculator {
  /// Calculate future value of investment with regular contributions
  /// Using Future Value of Annuity formula:
  /// FV = PV * (1 + r)^n + PMT * [(1 + r)^n - 1] / r
  static double calculateInvestmentProjection({
    required double currentBalance,
    required double annualContribution,
    required double annualReturnRate,
    required int years,
  }) {
    if (years == 0) return currentBalance;

    final r = annualReturnRate / 100; // Convert percentage to decimal
    final n = years;

    // Future value of current balance (lump sum)
    final fvLumpSum = currentBalance * pow(1 + r, n);

    // Future value of annual contributions (annuity)
    // Handle edge case where r is 0 (no return)
    final fvAnnuity = r == 0
        ? annualContribution * n
        : annualContribution * ((pow(1 + r, n) - 1) / r);

    return fvLumpSum + fvAnnuity;
  }

  /// Calculate future value of asset with compound growth
  /// FV = PV * (1 + r)^n
  static double calculateAssetProjection({
    required double currentValue,
    required double annualGrowthRate,
    required int years,
  }) {
    if (years == 0) return currentValue;

    final r = annualGrowthRate / 100;
    return currentValue * pow(1 + r, years);
  }

  /// Adjust for inflation to get real value
  /// Real Value = Nominal Value / (1 + inflation)^n
  static double adjustForInflation({
    required double nominalValue,
    required double inflationRate,
    required int years,
  }) {
    if (years == 0) return nominalValue;

    final i = inflationRate / 100;
    return nominalValue / pow(1 + i, years);
  }

  /// Calculate total portfolio projection for a specific number of years
  static ProjectionResult calculatePortfolioProjection({
    required List<InvestmentAccount> investments,
    required List<Asset> assets,
    required ProjectionSettings settings,
    required int years,
  }) {
    double totalInvestments = 0;
    double totalAssets = 0;

    // Sum all investment projections
    for (final inv in investments) {
      totalInvestments += calculateInvestmentProjection(
        currentBalance: inv.currentBalance,
        annualContribution: inv.annualContribution,
        annualReturnRate: inv.expectedAnnualReturn,
        years: years,
      );
    }

    // Sum all asset projections
    for (final asset in assets) {
      totalAssets += calculateAssetProjection(
        currentValue: asset.currentValue,
        annualGrowthRate: asset.expectedAnnualGrowth,
        years: years,
      );
    }

    final totalNominal = totalInvestments + totalAssets;
    final totalReal = adjustForInflation(
      nominalValue: totalNominal,
      inflationRate: settings.inflationRate,
      years: years,
    );

    return ProjectionResult(
      years: years,
      nominalValue: totalNominal,
      realValue: totalReal,
      investmentsValue: totalInvestments,
      assetsValue: totalAssets,
      inflationImpact: totalNominal - totalReal,
    );
  }

  /// Calculate portfolio projections for all time horizons
  static Map<int, ProjectionResult> calculatePortfolioProjections({
    required List<InvestmentAccount> investments,
    required List<Asset> assets,
    required ProjectionSettings settings,
  }) {
    final results = <int, ProjectionResult>{};

    for (final years in settings.timeHorizons) {
      results[years] = calculatePortfolioProjection(
        investments: investments,
        assets: assets,
        settings: settings,
        years: years,
      );
    }

    return results;
  }

  /// Calculate year-by-year projections for charting
  /// Returns a map of year -> ProjectionResult for each year from 0 to maxYears
  static Map<int, ProjectionResult> calculateYearlyProjections({
    required List<InvestmentAccount> investments,
    required List<Asset> assets,
    required ProjectionSettings settings,
    required int maxYears,
  }) {
    final results = <int, ProjectionResult>{};

    for (int year = 0; year <= maxYears; year++) {
      results[year] = calculatePortfolioProjection(
        investments: investments,
        assets: assets,
        settings: settings,
        years: year,
      );
    }

    return results;
  }

  /// Calculate current total portfolio value (0 years projection)
  static double calculateCurrentTotal({
    required List<InvestmentAccount> investments,
    required List<Asset> assets,
  }) {
    double total = 0;

    for (final inv in investments) {
      total += inv.currentBalance;
    }

    for (final asset in assets) {
      total += asset.currentValue;
    }

    return total;
  }
}

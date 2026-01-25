import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/investment_account.dart';
import '../models/asset.dart';
import '../models/projection_settings.dart';
import '../services/storage_service.dart';
import '../utils/projection_calculator.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final StorageService _storage = StorageService();

  List<InvestmentAccount> _investments = [];
  List<Asset> _assets = [];
  ProjectionSettings _settings = const ProjectionSettings();
  bool _isLoading = true;
  int _selectedHorizon = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final investments = await _storage.loadInvestments();
      final assets = await _storage.loadAssets();
      final settings = await _storage.loadSettings();
      setState(() {
        _investments = investments;
        _assets = assets;
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  bool get _hasData => _investments.isNotEmpty || _assets.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasData) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildTimeHorizonSelector(),
          const SizedBox(height: 24),
          _buildChart(),
          const SizedBox(height: 24),
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Data Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add investments and assets in the Portfolio tab\nto see projections',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currentTotal = ProjectionCalculator.calculateCurrentTotal(
      investments: _investments,
      assets: _assets,
    );

    final projection = ProjectionCalculator.calculatePortfolioProjection(
      investments: _investments,
      assets: _assets,
      settings: _settings,
      years: _selectedHorizon,
    );

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Current Value',
            currentTotal,
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            '$_selectedHorizon Yr Nominal',
            projection.nominalValue,
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            '$_selectedHorizon Yr Real',
            projection.realValue,
            Icons.attach_money,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, double value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatCompactCurrency(value),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeHorizonSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Horizon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _settings.timeHorizons.map((years) {
            return ChoiceChip(
              label: Text('$years years'),
              selected: _selectedHorizon == years,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedHorizon = years;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final yearlyProjections = ProjectionCalculator.calculateYearlyProjections(
      investments: _investments,
      assets: _assets,
      settings: _settings,
      maxYears: _selectedHorizon,
    );

    final nominalSpots = <FlSpot>[];
    final realSpots = <FlSpot>[];

    yearlyProjections.forEach((year, projection) {
      nominalSpots.add(FlSpot(year.toDouble(), projection.nominalValue));
      realSpots.add(FlSpot(year.toDouble(), projection.realValue));
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projected Portfolio Growth',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem('Nominal Value', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('Real Value (Inflation-Adjusted)', Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: null,
                    verticalInterval: null,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            Formatters.formatCompactCurrency(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _selectedHorizon > 10 ? 5 : null,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: nominalSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: realSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isNominal = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isNominal ? 'Nominal' : 'Real'}\nYear ${spot.x.toInt()}\n${Formatters.formatCurrency(spot.y)}',
                            TextStyle(
                              color: isNominal ? Colors.blue : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildComparisonTable() {
    final projections = ProjectionCalculator.calculatePortfolioProjections(
      investments: _investments,
      assets: _assets,
      settings: _settings,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projection Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Inflation Rate: ${Formatters.formatPercentage(_settings.inflationRate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Years')),
                  DataColumn(label: Text('Nominal Value')),
                  DataColumn(label: Text('Real Value')),
                  DataColumn(label: Text('Inflation Impact')),
                ],
                rows: _settings.timeHorizons.map((years) {
                  final projection = projections[years]!;
                  return DataRow(
                    cells: [
                      DataCell(Text('$years')),
                      DataCell(Text(
                        Formatters.formatCurrency(projection.nominalValue),
                      )),
                      DataCell(Text(
                        Formatters.formatCurrency(projection.realValue),
                      )),
                      DataCell(
                        Text(
                          '${Formatters.formatCurrency(projection.inflationImpact)} (${Formatters.formatPercentage(projection.inflationPercentage, decimals: 1)})',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

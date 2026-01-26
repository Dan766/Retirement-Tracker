import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/investment_account.dart';
import '../models/asset.dart';
import '../models/projection_settings.dart';
import '../models/fire_settings.dart';
import '../services/storage_service.dart';
import '../utils/fire_calculator.dart';
import '../utils/projection_calculator.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

class FireScreen extends StatefulWidget {
  const FireScreen({Key? key}) : super(key: key);

  @override
  State<FireScreen> createState() => _FireScreenState();
}

class _FireScreenState extends State<FireScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _incomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<InvestmentAccount> _investments = [];
  List<Asset> _assets = [];
  ProjectionSettings _projectionSettings = const ProjectionSettings();
  FireSettings _fireSettings = const FireSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final investments = await _storage.loadInvestments();
      final assets = await _storage.loadAssets();
      final projectionSettings = await _storage.loadSettings();
      final fireSettings = await _storage.loadFireSettings();
      setState(() {
        _investments = investments;
        _assets = assets;
        _projectionSettings = projectionSettings;
        _fireSettings = fireSettings;
        _incomeController.text = fireSettings.annualRetirementIncome > 0
            ? fireSettings.annualRetirementIncome.toStringAsFixed(0)
            : '';
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

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final income = double.tryParse(_incomeController.text) ?? 0.0;
      final updatedSettings = _fireSettings.copyWith(
        annualRetirementIncome: income,
      );
      await _storage.saveFireSettings(updatedSettings);
      setState(() {
        _fireSettings = updatedSettings;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FIRE settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _toggleRealValue(bool value) async {
    try {
      final updatedSettings = _fireSettings.copyWith(useRealValue: value);
      await _storage.saveFireSettings(updatedSettings);
      setState(() {
        _fireSettings = updatedSettings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  bool get _hasData => _investments.isNotEmpty || _assets.isNotEmpty;
  bool get _hasFireGoal => _fireSettings.annualRetirementIncome > 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasData || !_hasFireGoal) {
      return _buildEmptyState();
    }

    final fireResult = FireCalculator.calculateFireMetrics(
      fireSettings: _fireSettings,
      investments: _investments,
      assets: _assets,
      projectionSettings: _projectionSettings,
    );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(fireResult),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildInputCard(),
          const SizedBox(height: 24),
          _buildProgressSection(fireResult),
          const SizedBox(height: 24),
          _buildChart(fireResult),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'FIRE Calculator',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              !_hasData
                  ? 'Add investments and assets in the Portfolio tab\nto start tracking your FIRE progress'
                  : 'Set your annual retirement income below\nto calculate your FIRE number',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildInputCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(FireResult fireResult) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40) / 2,
          child: _buildSummaryCard(
            'FIRE Number',
            fireResult.fireNumber,
            Icons.flag,
            Colors.orange,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40) / 2,
          child: _buildSummaryCard(
            'Current Portfolio',
            fireResult.currentPortfolio,
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40) / 2,
          child: _buildProgressCard(fireResult),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40) / 2,
          child: _buildYearsToFireCard(fireResult),
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

  Widget _buildProgressCard(FireResult fireResult) {
    final progress = fireResult.currentProgress.clamp(0.0, 100.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Progress',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearsToFireCard(FireResult fireResult) {
    String displayText;
    Color color;

    if (fireResult.isAchieved) {
      displayText = 'Achieved!';
      color = Colors.green;
    } else if (fireResult.isAchievable) {
      displayText = '${fireResult.yearsToFire} years';
      color = Colors.purple;
    } else {
      displayText = 'Not achievable';
      color = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Years to FIRE',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayText,
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

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'What is FIRE?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'FIRE stands for Financial Independence, Retire Early. It\'s a movement focused on achieving financial freedom through aggressive saving and smart investing.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'The 4% Rule',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The 4% rule suggests that you can safely withdraw 4% of your portfolio annually in retirement. Your FIRE number is calculated as: Annual Income ÷ 0.04 = Required Portfolio.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'For example, if you need \$40,000 per year, your FIRE number would be \$1,000,000 (\$40,000 ÷ 0.04).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIRE Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _incomeController,
                decoration: const InputDecoration(
                  labelText: 'Annual Retirement Income',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  helperText: 'Your required annual income in retirement',
                ),
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use inflation-adjusted values'),
                subtitle: const Text('Calculate FIRE using real (purchasing power) values'),
                value: _fireSettings.useRealValue,
                onChanged: _toggleRealValue,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Calculate FIRE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(FireResult fireResult) {
    final progress = fireResult.currentProgress.clamp(0.0, 100.0) / 100;
    final remaining = fireResult.fireNumber - fireResult.currentPortfolio;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIRE Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                fireResult.isAchieved ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      Formatters.formatCurrency(fireResult.currentPortfolio),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      Formatters.formatCurrency(remaining > 0 ? remaining : 0),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(FireResult fireResult) {
    final maxYears = fireResult.isAchievable
        ? (fireResult.yearsToFire! + 5).clamp(10, 50)
        : 30;

    final yearlyProjections = ProjectionCalculator.calculateYearlyProjections(
      investments: _investments,
      assets: _assets,
      settings: _projectionSettings,
      maxYears: maxYears,
    );

    final portfolioSpots = <FlSpot>[];
    final fireLineSpots = <FlSpot>[];

    yearlyProjections.forEach((year, projection) {
      final value = _fireSettings.useRealValue
          ? projection.realValue
          : projection.nominalValue;
      portfolioSpots.add(FlSpot(year.toDouble(), value));
      fireLineSpots.add(FlSpot(year.toDouble(), fireResult.fireNumber));
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Path to FIRE',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem('Portfolio', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('FIRE Target', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
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
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: portfolioSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: fireLineSpots,
                      isCurved: false,
                      color: Colors.orange,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
            if (fireResult.isAchievable && !fireResult.isAchieved)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'You can achieve FIRE in ${fireResult.yearsToFire} years (${fireResult.fireDate?.year})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (fireResult.isAchieved)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Congratulations! You have achieved FIRE! 🎉',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (!fireResult.isAchievable && fireResult.fireNumber > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'FIRE not achievable with current trajectory. Consider increasing contributions or reducing target income.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

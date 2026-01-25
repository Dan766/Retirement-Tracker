import 'package:flutter/material.dart';
import '../models/investment_account.dart';
import '../models/asset.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import 'investment_form_screen.dart';
import 'asset_form_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storage = StorageService();

  List<InvestmentAccount> _investments = [];
  List<Asset> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final investments = await _storage.loadInvestments();
      final assets = await _storage.loadAssets();
      setState(() {
        _investments = investments;
        _assets = assets;
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

  double get _totalInvestments {
    return _investments.fold(0, (sum, inv) => sum + inv.currentBalance);
  }

  double get _totalAssets {
    return _assets.fold(0, (sum, asset) => sum + asset.currentValue);
  }

  double get _totalPortfolio => _totalInvestments + _totalAssets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSummaryCards(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Investments'),
              Tab(text: 'Assets'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInvestmentsTab(),
                      _buildAssetsTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: _tabController.index == 0 ? 'Add Investment' : 'Add Asset',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Investments',
              _totalInvestments,
              Icons.trending_up,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Assets',
              _totalAssets,
              Icons.home,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Total',
              _totalPortfolio,
              Icons.account_balance_wallet,
              Colors.purple,
            ),
          ),
        ],
      ),
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

  Widget _buildInvestmentsTab() {
    if (_investments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.account_balance,
        title: 'No Investments Yet',
        message: 'Tap the + button to add your first investment account',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _investments.length,
        itemBuilder: (context, index) {
          final investment = _investments[index];
          return _buildInvestmentCard(investment);
        },
      ),
    );
  }

  Widget _buildAssetsTab() {
    if (_assets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.home,
        title: 'No Assets Yet',
        message: 'Tap the + button to add your first asset',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assets.length,
        itemBuilder: (context, index) {
          final asset = _assets[index];
          return _buildAssetCard(asset);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(InvestmentAccount investment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(investment.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Balance: ${Formatters.formatCurrency(investment.currentBalance)}'),
            Text(
              'Contributing: ${Formatters.formatCurrency(investment.contributionAmount)}/${investment.frequency == ContributionFrequency.weekly ? 'week' : 'year'}',
            ),
            Text('Expected Return: ${Formatters.formatPercentage(investment.expectedAnnualReturn)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editInvestment(investment),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteInvestment(investment),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildAssetCard(Asset asset) {
    IconData categoryIcon;
    switch (asset.category) {
      case AssetCategory.house:
        categoryIcon = Icons.home;
        break;
      case AssetCategory.car:
        categoryIcon = Icons.directions_car;
        break;
      case AssetCategory.collectibles:
        categoryIcon = Icons.collections;
        break;
      default:
        categoryIcon = Icons.category;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(categoryIcon, size: 32),
        title: Text(asset.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Value: ${Formatters.formatCurrency(asset.currentValue)}'),
            Text('Expected Growth: ${Formatters.formatPercentage(asset.expectedAnnualGrowth)}'),
            Text('Purchased: ${Formatters.formatShortDate(asset.purchaseDate)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editAsset(asset),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteAsset(asset),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _addItem() {
    if (_tabController.index == 0) {
      _addInvestment();
    } else {
      _addAsset();
    }
  }

  void _addInvestment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvestmentFormScreen(
          onSave: (investment) async {
            final updated = [..._investments, investment];
            await _storage.saveInvestments(updated);
            await _loadData();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Investment added')),
              );
            }
          },
        ),
      ),
    );
  }

  void _editInvestment(InvestmentAccount investment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvestmentFormScreen(
          investment: investment,
          onSave: (updated) async {
            final index = _investments.indexWhere((inv) => inv.id == investment.id);
            if (index != -1) {
              final updatedList = [..._investments];
              updatedList[index] = updated;
              await _storage.saveInvestments(updatedList);
              await _loadData();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Investment updated')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _deleteInvestment(InvestmentAccount investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text('Are you sure you want to delete "${investment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updated = _investments.where((inv) => inv.id != investment.id).toList();
              await _storage.saveInvestments(updated);
              await _loadData();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Investment deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addAsset() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetFormScreen(
          onSave: (asset) async {
            final updated = [..._assets, asset];
            await _storage.saveAssets(updated);
            await _loadData();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Asset added')),
              );
            }
          },
        ),
      ),
    );
  }

  void _editAsset(Asset asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetFormScreen(
          asset: asset,
          onSave: (updated) async {
            final index = _assets.indexWhere((a) => a.id == asset.id);
            if (index != -1) {
              final updatedList = [..._assets];
              updatedList[index] = updated;
              await _storage.saveAssets(updatedList);
              await _loadData();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Asset updated')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _deleteAsset(Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Are you sure you want to delete "${asset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updated = _assets.where((a) => a.id != asset.id).toList();
              await _storage.saveAssets(updated);
              await _loadData();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Asset deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

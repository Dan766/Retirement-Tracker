import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/investment_account.dart';
import '../utils/validators.dart';

class InvestmentFormScreen extends StatefulWidget {
  final InvestmentAccount? investment;
  final Function(InvestmentAccount) onSave;

  const InvestmentFormScreen({
    Key? key,
    this.investment,
    required this.onSave,
  }) : super(key: key);

  @override
  State<InvestmentFormScreen> createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends State<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _contributionController = TextEditingController();
  final _returnController = TextEditingController();

  ContributionFrequency _frequency = ContributionFrequency.weekly;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.investment != null;

    if (_isEditing) {
      final inv = widget.investment!;
      _nameController.text = inv.name;
      _balanceController.text = inv.currentBalance.toString();
      _contributionController.text = inv.contributionAmount.toString();
      _returnController.text = inv.expectedAnnualReturn.toString();
      _frequency = inv.frequency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _contributionController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final investment = InvestmentAccount(
        id: widget.investment?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        currentBalance: double.parse(_balanceController.text),
        frequency: _frequency,
        contributionAmount: double.parse(_contributionController.text),
        expectedAnnualReturn: double.parse(_returnController.text),
        createdDate: widget.investment?.createdDate ?? DateTime.now(),
      );
      widget.onSave(investment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Investment' : 'Add Investment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g., 401(k), IRA, Brokerage',
                border: OutlineInputBorder(),
              ),
              validator: Validators.requiredText,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Current Balance',
                hintText: '0.00',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveNumberOrZero,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contributionController,
              decoration: InputDecoration(
                labelText: 'Contribution Amount',
                hintText: '0.00',
                prefixText: '\$',
                border: const OutlineInputBorder(),
                helperText: 'How much you contribute per ${_frequency == ContributionFrequency.weekly ? 'week' : 'year'}',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveNumberOrZero,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contribution Frequency',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ContributionFrequency>(
                      segments: const [
                        ButtonSegment(
                          value: ContributionFrequency.weekly,
                          label: Text('Weekly'),
                          icon: Icon(Icons.calendar_view_week),
                        ),
                        ButtonSegment(
                          value: ContributionFrequency.yearly,
                          label: Text('Yearly'),
                          icon: Icon(Icons.calendar_today),
                        ),
                      ],
                      selected: {_frequency},
                      onSelectionChanged: (Set<ContributionFrequency> selected) {
                        setState(() {
                          _frequency = selected.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _returnController,
              decoration: const InputDecoration(
                labelText: 'Expected Annual Return',
                hintText: '7.0',
                suffixText: '%',
                border: OutlineInputBorder(),
                helperText: 'Typical range: 6-10% for stocks, 2-4% for bonds',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.returnPercentage,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(_isEditing ? 'Update' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

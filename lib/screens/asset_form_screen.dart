import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

class AssetFormScreen extends StatefulWidget {
  final Asset? asset;
  final Function(Asset) onSave;

  const AssetFormScreen({
    Key? key,
    this.asset,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _growthController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = AssetCategory.house;
  DateTime _purchaseDate = DateTime.now();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.asset != null;

    if (_isEditing) {
      final asset = widget.asset!;
      _nameController.text = asset.name;
      _valueController.text = asset.currentValue.toString();
      _growthController.text = asset.expectedAnnualGrowth.toString();
      _notesController.text = asset.notes ?? '';
      _category = asset.category;
      _purchaseDate = asset.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _growthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final asset = Asset(
        id: widget.asset?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _category,
        currentValue: double.parse(_valueController.text),
        expectedAnnualGrowth: double.parse(_growthController.text),
        purchaseDate: _purchaseDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      widget.onSave(asset);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Asset' : 'Add Asset'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Asset Name',
                hintText: 'e.g., Primary Residence, Rental Property',
                border: OutlineInputBorder(),
              ),
              validator: Validators.requiredText,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: AssetCategory.all.map((category) {
                IconData icon;
                switch (category) {
                  case AssetCategory.house:
                    icon = Icons.home;
                    break;
                  case AssetCategory.car:
                    icon = Icons.directions_car;
                    break;
                  case AssetCategory.collectibles:
                    icon = Icons.collections;
                    break;
                  default:
                    icon = Icons.category;
                }
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _category = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Current Value',
                hintText: '0.00',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _growthController,
              decoration: const InputDecoration(
                labelText: 'Expected Annual Growth',
                hintText: '3.0',
                suffixText: '%',
                border: OutlineInputBorder(),
                helperText: 'Typical range: 2-5% for real estate, varies for others',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.returnPercentage,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Purchase Date'),
                subtitle: Text(Formatters.formatShortDate(_purchaseDate)),
                trailing: const Icon(Icons.edit),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Additional information about this asset',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
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

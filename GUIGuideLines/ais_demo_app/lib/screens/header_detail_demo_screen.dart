import 'package:flutter/material.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_header_detail_shell.dart';

/// Demo screen for AIS Header/Detail Shell (§1.2)
/// Shows invariant enforcement - debits must equal credits
class HeaderDetailDemoScreen extends StatefulWidget {
  const HeaderDetailDemoScreen({super.key});

  @override
  State<HeaderDetailDemoScreen> createState() => _HeaderDetailDemoScreenState();
}

class _HeaderDetailDemoScreenState extends State<HeaderDetailDemoScreen> {
  // Journal entry - classic invariant: debits must equal credits
  double _totalAmount = 1000.00;
  final List<_JournalLine> _lines = [
    _JournalLine(description: 'Cash', amount: 500.00, isDebit: true),
    _JournalLine(description: 'Accounts Receivable', amount: 500.00, isDebit: true),
    _JournalLine(description: 'Revenue', amount: 800.00, isDebit: false),
  ];

  double get _totalDebits =>
      _lines.where((l) => l.isDebit).fold(0.0, (sum, l) => sum + l.amount);

  double get _totalCredits =>
      _lines.where((l) => !l.isDebit).fold(0.0, (sum, l) => sum + l.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Header/Detail Shell Demo'),
      ),
      body: AisHeaderDetailShell(
        // AIS §1.2: The invariant is a REQUIRED parameter
        invariant: (
          description: 'Debits must equal Credits',
          calculateActual: () => _totalDebits,
          calculateExpected: () => _totalCredits,
        ),
        currency: 'USD',
        header: _buildHeader(),
        children: _lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          return AisHeaderDetailLine(
            description: '${line.isDebit ? "DR" : "CR"} ${line.description}',
            amount: line.amount,
            currency: 'USD',
            onEdit: () => _editLine(index),
            onDelete: () => _deleteLine(index),
          );
        }).toList(),
        onAddLine: () => _addLine(),
        onSave: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journal entry saved!')),
          );
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journal Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingXs),
                  Text(
                    'JE-2024-001',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AisTheme.spacingMd,
                vertical: AisTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AisTheme.radiusSm),
              ),
              child: const Text(
                'Draft',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AisTheme.spacingMd),
        Row(
          children: [
            _HeaderField(label: 'Date', value: 'Dec 15, 2024'),
            const SizedBox(width: AisTheme.spacingLg),
            _HeaderField(label: 'Period', value: 'FY2024-Q4'),
            const SizedBox(width: AisTheme.spacingLg),
            _HeaderField(label: 'Source', value: 'Manual Entry'),
          ],
        ),
      ],
    );
  }

  void _addLine() {
    showDialog(
      context: context,
      builder: (context) => _LineEditDialog(
        onSave: (description, amount, isDebit) {
          setState(() {
            _lines.add(_JournalLine(
              description: description,
              amount: amount,
              isDebit: isDebit,
            ));
          });
        },
      ),
    );
  }

  void _editLine(int index) {
    showDialog(
      context: context,
      builder: (context) => _LineEditDialog(
        initialLine: _lines[index],
        onSave: (description, amount, isDebit) {
          setState(() {
            _lines[index] = _JournalLine(
              description: description,
              amount: amount,
              isDebit: isDebit,
            );
          });
        },
      ),
    );
  }

  void _deleteLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
  }
}

class _JournalLine {
  final String description;
  final double amount;
  final bool isDebit;

  const _JournalLine({
    required this.description,
    required this.amount,
    required this.isDebit,
  });
}

class _HeaderField extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _LineEditDialog extends StatefulWidget {
  final _JournalLine? initialLine;
  final void Function(String description, double amount, bool isDebit) onSave;

  const _LineEditDialog({
    this.initialLine,
    required this.onSave,
  });

  @override
  State<_LineEditDialog> createState() => _LineEditDialogState();
}

class _LineEditDialogState extends State<_LineEditDialog> {
  late TextEditingController _descController;
  late TextEditingController _amountController;
  late bool _isDebit;

  @override
  void initState() {
    super.initState();
    _descController =
        TextEditingController(text: widget.initialLine?.description ?? '');
    _amountController = TextEditingController(
        text: widget.initialLine?.amount.toStringAsFixed(2) ?? '');
    _isDebit = widget.initialLine?.isDebit ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialLine == null ? 'Add Line' : 'Edit Line'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Account',
            ),
          ),
          const SizedBox(height: AisTheme.spacingMd),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Row(
            children: [
              const Text('Type: '),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Debit')),
                  ButtonSegment(value: false, label: Text('Credit')),
                ],
                selected: {_isDebit},
                onSelectionChanged: (selected) {
                  setState(() {
                    _isDebit = selected.first;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            widget.onSave(_descController.text, amount, _isDebit);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

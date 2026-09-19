import 'package:flutter/material.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_report_shell.dart';

/// Demo screen for AIS Report Shell (§1.3)
class ReportDemoScreen extends StatefulWidget {
  const ReportDemoScreen({super.key});

  @override
  State<ReportDemoScreen> createState() => _ReportDemoScreenState();
}

class _ReportDemoScreenState extends State<ReportDemoScreen> {
  String _currentPeriod = 'Q4 2024';
  String _comparisonPeriod = 'Q4 2023';
  String _grouping = 'Category';
  List<String> _drillPath = ['All Expenses'];

  // Sample data
  final List<_ReportData> _data = [
    _ReportData('Marketing', 45000, 38000),
    _ReportData('Engineering', 120000, 105000),
    _ReportData('Operations', 35000, 32000),
    _ReportData('Sales', 55000, 48000),
    _ReportData('Support', 28000, 25000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Shell Demo'),
      ),
      body: AisReportShell(
        title: 'Expense Report',
        currentPeriod: _currentPeriod,
        comparisonPeriod: _comparisonPeriod,
        currency: 'USD',
        grouping: _grouping,
        groupingOptions: const ['Category', 'Department', 'Cost Center'],
        drillPath: _drillPath,
        basis: 'Accrual',
        dataSufficiency: 'High',
        dataAsOf: DateTime.now(),
        onPeriodChange: () => _showPeriodPicker(),
        onComparisonChange: () => _showComparisonPicker(),
        onGroupingChange: (value) {
          if (value != null) {
            setState(() => _grouping = value);
          }
        },
        onDrillUp: (index) {
          setState(() {
            _drillPath = _drillPath.sublist(0, index + 1);
          });
        },
        onExport: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export would include annotation bar'),
            ),
          );
        },
        rows: _data.map((item) {
          return AisReportRow(
            label: item.category,
            value: item.current,
            comparisonValue: item.previous,
            currency: 'USD',
            // AIS §1.3: Drill-through is MANDATORY
            canDrillThrough: true,
            onDrillThrough: () {
              setState(() {
                _drillPath = [..._drillPath, item.category];
              });
              // Would show source rows
              _showDrillThrough(item);
            },
          );
        }).toList(),
        footer: AisReportFooter(
          label: 'Total Expenses',
          total: _data.fold(0.0, (sum, item) => sum + item.current),
          currency: 'USD',
          // Could show refusal if mixed currencies
          // refusalReason: 'Mixed currencies cannot be totaled',
        ),
      ),
    );
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AisTheme.spacingMd),
              child: Text(
                'Select Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...['Q4 2024', 'Q3 2024', 'Q2 2024', 'Q1 2024'].map(
              (period) => ListTile(
                title: Text(period),
                trailing:
                    period == _currentPeriod ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _currentPeriod = period);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComparisonPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AisTheme.spacingMd),
              child: Text(
                'Compare To',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...['Q4 2023', 'Q3 2024', 'Budget 2024'].map(
              (period) => ListTile(
                title: Text(period),
                trailing: period == _comparisonPeriod
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() => _comparisonPeriod = period);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AIS §1.3: Drill-through to source rows is MANDATORY
  void _showDrillThrough(_ReportData item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Scaffold(
          appBar: AppBar(
            title: Text('${item.category} - Source Rows'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            controller: controller,
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            children: [
              // Reconciliation header
              Container(
                padding: const EdgeInsets.all(AisTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: AisTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reconciled to Parent',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sum of source rows: \$${item.current.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AisTheme.spacingMd),

              // Source rows
              ...List.generate(5, (index) {
                final amount = item.current / 5 + (index * 100);
                return Card(
                  margin: const EdgeInsets.only(bottom: AisTheme.spacingSm),
                  child: ListTile(
                    title: Text('Invoice INV-${2024000 + index}'),
                    subtitle: Text('Vendor ${index + 1}'),
                    trailing: Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportData {
  final String category;
  final double current;
  final double previous;

  const _ReportData(this.category, this.current, this.previous);
}

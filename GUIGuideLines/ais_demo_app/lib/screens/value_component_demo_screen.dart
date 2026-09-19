import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_value_component.dart';
import '../widgets/ais_state_badge.dart';

/// Demo screen for AIS Value Component (§3.1)
/// Interactive editable version with date/time pickers
class ValueComponentDemoScreen extends StatefulWidget {
  const ValueComponentDemoScreen({super.key});

  @override
  State<ValueComponentDemoScreen> createState() =>
      _ValueComponentDemoScreenState();
}

class _ValueComponentDemoScreenState extends State<ValueComponentDemoScreen> {
  // Editable monetary values
  double _postedAmount = 15750.00;
  String _postedCurrency = 'USD';
  DateTime _postedDate = DateTime(2024, 12, 15);
  TimeOfDay _postedTime = const TimeOfDay(hour: 14, minute: 30);
  String _postedBasis = 'Accrual';

  double _draftAmount = 8500.00;
  String _draftCurrency = 'EUR';
  DateTime _draftDate = DateTime(2024, 10, 1);
  TimeOfDay _draftTime = const TimeOfDay(hour: 9, minute: 0);

  double _sourceAmount = 42000.00;
  String _sourceCurrency = 'GBP';
  DateTime _sourceDate = DateTime(2024, 1, 1);
  TimeOfDay _sourceTime = const TimeOfDay(hour: 12, minute: 0);
  String _sourceBasis = 'Cash';
  String _sourceOrigin = 'Import';

  // Editable metric values with freshness dates
  String _metricName1 = 'Customer Acquisition Cost';
  double _metricValue1 = 45.82;
  String _metricUnit1 = 'USD';
  String _metricVersion1 = '2.1';
  String _metricSufficiency1 = 'High';
  String _metricDenominator1 = 'per customer';
  DateTime _metricFreshness1 = DateTime.now();

  String _metricName2 = 'Conversion Rate';
  double _metricValue2 = 3.45;
  String _metricUnit2 = '%';
  String _metricVersion2 = '1.0';
  String _metricSufficiency2 = 'Medium';
  DateTime _metricFreshness2 = DateTime.now().subtract(const Duration(days: 2));

  String _metricName3 = 'Lifetime Value';
  double _metricValue3 = 1250.00;
  String _metricUnit3 = 'USD';
  String _metricVersion3 = '0.9-beta';
  String _metricSufficiency3 = 'Low';
  DateTime? _metricFreshness3;

  // Unavailable reason
  String _unavailableReason = 'Data not collected';

  // Get locale-aware date format
  DateFormat get _dateFormat {
    final locale = Localizations.localeOf(context);
    // Use locale-specific date format
    return DateFormat.yMd(locale.toString());
  }

  DateFormat get _timeFormat {
    final locale = Localizations.localeOf(context);
    return DateFormat.jm(locale.toString());
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final dateStr = _dateFormat.format(date);
    final timeStr = _timeFormat.format(
      DateTime(2024, 1, 1, time.hour, time.minute),
    );
    return '$dateStr $timeStr';
  }

  String _formatPeriod(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Value Components Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to defaults',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: No Bare Values
            _SectionHeader(
              title: 'No Bare Consequential Values',
              subtitle: 'AIS §3.1 - Values require annotations to be meaningful',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.stateError.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: tokens.stateError.color,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      Text(
                        'BAD: Bare value without context',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tokens.stateError.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AisTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: Text(
                      '\$1,234.56',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: tokens.stateError.color,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  Text(
                    'What currency? What period? Is this draft or posted?',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: tokens.stateError.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.actionConfirm.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: tokens.actionConfirm.color,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      Text(
                        'GOOD: Value with required annotations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tokens.actionConfirm.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AisTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: const AisMonetaryValue(
                      amount: 1234.56,
                      currency: 'USD',
                      period: 'Q4 2024',
                      basis: 'Accrual',
                      isPosted: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Date/Time Input Demo
            _SectionHeader(
              title: 'Date & Time Input (Editable)',
              subtitle:
                  'Locale-aware date/time pickers with keyboard entry support',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.stateInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        tokens.stateInfo.icon,
                        color: tokens.stateInfo.color,
                        size: 18,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      Text(
                        'Current locale: ${Localizations.localeOf(context)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  Text(
                    'Date format: ${_dateFormat.pattern}',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.onSurfaceSecondary,
                    ),
                  ),
                  Text(
                    'Time format: ${_timeFormat.pattern}',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Editable Monetary Values with Date/Time
            _SectionHeader(
              title: 'Monetary Values (Editable)',
              subtitle: 'Click "Edit" to modify values, dates, and times',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            _EditableValueCard(
              title: 'Posted Amount',
              subtitle: _formatDateTime(_postedDate, _postedTime),
              onEdit: () => _editPostedAmount(context),
              child: AisMonetaryValue(
                amount: _postedAmount,
                currency: _postedCurrency,
                period: _formatPeriod(_postedDate),
                basis: _postedBasis,
                isPosted: true,
              ),
            ),

            const SizedBox(height: AisTheme.spacingMd),

            _EditableValueCard(
              title: 'Draft Amount',
              subtitle: _formatDateTime(_draftDate, _draftTime),
              onEdit: () => _editDraftAmount(context),
              child: AisMonetaryValue(
                amount: _draftAmount,
                currency: _draftCurrency,
                period: _formatPeriod(_draftDate),
                isDraft: true,
              ),
            ),

            const SizedBox(height: AisTheme.spacingMd),

            _EditableValueCard(
              title: 'With Source',
              subtitle: _formatDateTime(_sourceDate, _sourceTime),
              onEdit: () => _editSourceAmount(context),
              child: AisMonetaryValue(
                amount: _sourceAmount,
                currency: _sourceCurrency,
                period: _formatPeriod(_sourceDate),
                basis: _sourceBasis,
                source: _sourceOrigin,
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Editable Metric Values with Freshness Date
            _SectionHeader(
              title: 'Metric Values (Editable)',
              subtitle: 'Definition version, data sufficiency, and freshness date',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            _EditableValueCard(
              title: 'Marketing Metric',
              subtitle: 'Freshness: ${_dateFormat.format(_metricFreshness1)}',
              onEdit: () => _editMetric1(context),
              child: AisMetricValue(
                metricName: _metricName1,
                value: _metricValue1,
                unit: _metricUnit1,
                definitionVersion: _metricVersion1,
                dataSufficiency: _metricSufficiency1,
                denominator: _metricDenominator1,
                freshness: _metricFreshness1,
              ),
            ),

            const SizedBox(height: AisTheme.spacingMd),

            _EditableValueCard(
              title: 'Engagement Metric',
              subtitle: 'Freshness: ${_dateFormat.format(_metricFreshness2)}',
              onEdit: () => _editMetric2(context),
              child: AisMetricValue(
                metricName: _metricName2,
                value: _metricValue2,
                unit: _metricUnit2,
                definitionVersion: _metricVersion2,
                dataSufficiency: _metricSufficiency2,
                freshness: _metricFreshness2,
              ),
            ),

            const SizedBox(height: AisTheme.spacingMd),

            _EditableValueCard(
              title: 'Low Confidence Metric',
              subtitle: _metricFreshness3 != null
                  ? 'Freshness: ${_dateFormat.format(_metricFreshness3!)}'
                  : 'No freshness date',
              onEdit: () => _editMetric3(context),
              child: AisMetricValue(
                metricName: _metricName3,
                value: _metricValue3,
                unit: _metricUnit3,
                definitionVersion: _metricVersion3,
                dataSufficiency: _metricSufficiency3,
                freshness: _metricFreshness3,
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Unavailable Values
            _SectionHeader(
              title: 'Unavailable vs Zero (Editable)',
              subtitle: 'AIS §2.3 - Must be distinguishable by MORE than color',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Row(
              children: [
                Expanded(
                  child: _ValueShowcase(
                    title: 'Zero Value',
                    child: const AisMonetaryValue(
                      amount: 0.00,
                      currency: 'USD',
                      period: 'Q4 2024',
                    ),
                  ),
                ),
                const SizedBox(width: AisTheme.spacingMd),
                Expanded(
                  child: _EditableValueCard(
                    title: 'Unavailable',
                    onEdit: () => _editUnavailableReason(context),
                    child: AisUnavailableValue(
                      reason: _unavailableReason,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.stateInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        tokens.stateInfo.icon,
                        color: tokens.stateInfo.color,
                        size: 18,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      const Text(
                        'Non-color distinctions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  const _DistinctionItem(
                    label: 'Icon present',
                    description: 'Unavailable shows a block icon',
                  ),
                  const _DistinctionItem(
                    label: 'Typography',
                    description: 'Italic text for unavailable',
                  ),
                  const _DistinctionItem(
                    label: 'Symbol',
                    description: 'Em dash (—) instead of numeric zero',
                  ),
                  const _DistinctionItem(
                    label: 'Explanation',
                    description: 'Optional reason text',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Annotation Bar
            _SectionHeader(
              title: 'Annotation Bar',
              subtitle: 'AIS §3.2 - Every report carries its annotations',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                border: Border.all(
                  color: tokens.onSurface.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AisTheme.spacingSm,
                      vertical: AisTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.stateInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tokens.stateInfo.icon,
                          size: 14,
                          color: tokens.stateInfo.color,
                        ),
                        const SizedBox(width: AisTheme.spacingSm),
                        const Expanded(
                          child: Wrap(
                            spacing: 16,
                            children: [
                              _AnnotationItem(label: 'Currency', value: 'USD'),
                              _AnnotationItem(label: 'Period', value: 'Q4 2024'),
                              _AnnotationItem(label: 'Basis', value: 'Accrual'),
                              _AnnotationItem(
                                  label: 'Data', value: 'High confidence'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingMd),
                  Text(
                    '\$1,234,567.89',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: tokens.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _postedAmount = 15750.00;
      _postedCurrency = 'USD';
      _postedDate = DateTime(2024, 12, 15);
      _postedTime = const TimeOfDay(hour: 14, minute: 30);
      _postedBasis = 'Accrual';
      _draftAmount = 8500.00;
      _draftCurrency = 'EUR';
      _draftDate = DateTime(2024, 10, 1);
      _draftTime = const TimeOfDay(hour: 9, minute: 0);
      _sourceAmount = 42000.00;
      _sourceCurrency = 'GBP';
      _sourceDate = DateTime(2024, 1, 1);
      _sourceTime = const TimeOfDay(hour: 12, minute: 0);
      _sourceBasis = 'Cash';
      _sourceOrigin = 'Import';
      _metricName1 = 'Customer Acquisition Cost';
      _metricValue1 = 45.82;
      _metricUnit1 = 'USD';
      _metricVersion1 = '2.1';
      _metricSufficiency1 = 'High';
      _metricDenominator1 = 'per customer';
      _metricFreshness1 = DateTime.now();
      _metricName2 = 'Conversion Rate';
      _metricValue2 = 3.45;
      _metricUnit2 = '%';
      _metricVersion2 = '1.0';
      _metricSufficiency2 = 'Medium';
      _metricFreshness2 = DateTime.now().subtract(const Duration(days: 2));
      _metricName3 = 'Lifetime Value';
      _metricValue3 = 1250.00;
      _metricUnit3 = 'USD';
      _metricVersion3 = '0.9-beta';
      _metricSufficiency3 = 'Low';
      _metricFreshness3 = null;
      _unavailableReason = 'Data not collected';
    });
  }

  Future<void> _editPostedAmount(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MonetaryEditDialog(
        title: 'Edit Posted Amount',
        amount: _postedAmount,
        currency: _postedCurrency,
        date: _postedDate,
        time: _postedTime,
        basis: _postedBasis,
      ),
    );
    if (result != null) {
      setState(() {
        _postedAmount = result['amount'] as double;
        _postedCurrency = result['currency'] as String;
        _postedDate = result['date'] as DateTime;
        _postedTime = result['time'] as TimeOfDay;
        _postedBasis = result['basis'] as String;
      });
    }
  }

  Future<void> _editDraftAmount(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MonetaryEditDialog(
        title: 'Edit Draft Amount',
        amount: _draftAmount,
        currency: _draftCurrency,
        date: _draftDate,
        time: _draftTime,
        showBasis: false,
      ),
    );
    if (result != null) {
      setState(() {
        _draftAmount = result['amount'] as double;
        _draftCurrency = result['currency'] as String;
        _draftDate = result['date'] as DateTime;
        _draftTime = result['time'] as TimeOfDay;
      });
    }
  }

  Future<void> _editSourceAmount(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MonetaryEditDialog(
        title: 'Edit Source Amount',
        amount: _sourceAmount,
        currency: _sourceCurrency,
        date: _sourceDate,
        time: _sourceTime,
        basis: _sourceBasis,
        source: _sourceOrigin,
        showSource: true,
      ),
    );
    if (result != null) {
      setState(() {
        _sourceAmount = result['amount'] as double;
        _sourceCurrency = result['currency'] as String;
        _sourceDate = result['date'] as DateTime;
        _sourceTime = result['time'] as TimeOfDay;
        _sourceBasis = result['basis'] as String;
        _sourceOrigin = result['source'] as String;
      });
    }
  }

  Future<void> _editMetric1(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MetricEditDialog(
        title: 'Edit Marketing Metric',
        metricName: _metricName1,
        value: _metricValue1,
        unit: _metricUnit1,
        version: _metricVersion1,
        sufficiency: _metricSufficiency1,
        denominator: _metricDenominator1,
        freshness: _metricFreshness1,
      ),
    );
    if (result != null) {
      setState(() {
        _metricName1 = result['metricName'] as String;
        _metricValue1 = result['value'] as double;
        _metricUnit1 = result['unit'] as String;
        _metricVersion1 = result['version'] as String;
        _metricSufficiency1 = result['sufficiency'] as String;
        _metricDenominator1 = result['denominator'] as String;
        _metricFreshness1 = result['freshness'] as DateTime;
      });
    }
  }

  Future<void> _editMetric2(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MetricEditDialog(
        title: 'Edit Engagement Metric',
        metricName: _metricName2,
        value: _metricValue2,
        unit: _metricUnit2,
        version: _metricVersion2,
        sufficiency: _metricSufficiency2,
        freshness: _metricFreshness2,
      ),
    );
    if (result != null) {
      setState(() {
        _metricName2 = result['metricName'] as String;
        _metricValue2 = result['value'] as double;
        _metricUnit2 = result['unit'] as String;
        _metricVersion2 = result['version'] as String;
        _metricSufficiency2 = result['sufficiency'] as String;
        _metricFreshness2 = result['freshness'] as DateTime;
      });
    }
  }

  Future<void> _editMetric3(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MetricEditDialog(
        title: 'Edit Low Confidence Metric',
        metricName: _metricName3,
        value: _metricValue3,
        unit: _metricUnit3,
        version: _metricVersion3,
        sufficiency: _metricSufficiency3,
        freshness: _metricFreshness3,
        allowNullFreshness: true,
      ),
    );
    if (result != null) {
      setState(() {
        _metricName3 = result['metricName'] as String;
        _metricValue3 = result['value'] as double;
        _metricUnit3 = result['unit'] as String;
        _metricVersion3 = result['version'] as String;
        _metricSufficiency3 = result['sufficiency'] as String;
        _metricFreshness3 = result['freshness'] as DateTime?;
      });
    }
  }

  Future<void> _editUnavailableReason(BuildContext context) async {
    final controller = TextEditingController(text: _unavailableReason);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Unavailable Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _unavailableReason = result;
      });
    }
  }
}

// Edit dialog for monetary values with date/time pickers
class _MonetaryEditDialog extends StatefulWidget {
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final TimeOfDay time;
  final String? basis;
  final String? source;
  final bool showBasis;
  final bool showSource;

  const _MonetaryEditDialog({
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.time,
    this.basis,
    this.source,
    this.showBasis = true,
    this.showSource = false,
  });

  @override
  State<_MonetaryEditDialog> createState() => _MonetaryEditDialogState();
}

class _MonetaryEditDialogState extends State<_MonetaryEditDialog> {
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _basisController;
  late TextEditingController _sourceController;
  late String _selectedCurrency;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF'];

  DateFormat get _dateFormat {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMd(locale.toString());
  }

  DateFormat get _timeFormat {
    final locale = Localizations.localeOf(context);
    return DateFormat.jm(locale.toString());
  }

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.amount.toStringAsFixed(2));
    _basisController = TextEditingController(text: widget.basis ?? 'Accrual');
    _sourceController = TextEditingController(text: widget.source ?? '');
    _selectedCurrency = widget.currency;
    _selectedDate = widget.date;
    _selectedTime = widget.time;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize date/time controllers after context is available
    _dateController = TextEditingController(
      text: _dateFormat.format(_selectedDate),
    );
    _timeController = TextEditingController(
      text: _timeFormat.format(
        DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _basisController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select date',
      cancelText: 'Cancel',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Select time',
      cancelText: 'Cancel',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _timeFormat.format(
          DateTime(2024, 1, 1, picked.hour, picked.minute),
        );
      });
    }
  }

  void _parseDate(String value) {
    try {
      final parsed = _dateFormat.parse(value);
      setState(() {
        _selectedDate = parsed;
      });
    } catch (_) {
      // Invalid format, ignore
    }
  }

  void _parseTime(String value) {
    try {
      final parsed = _timeFormat.parse(value);
      setState(() {
        _selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      });
    } catch (_) {
      // Invalid format, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: AisTheme.spacingMd),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Currency * (Required)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                }
              },
            ),
            const SizedBox(height: AisTheme.spacingMd),

            // Date input with calendar picker
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Date (${_dateFormat.pattern})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Pick date',
                  onPressed: _pickDate,
                ),
                hintText: _dateFormat.pattern,
              ),
              keyboardType: TextInputType.datetime,
              onChanged: _parseDate,
              onSubmitted: _parseDate,
            ),
            const SizedBox(height: AisTheme.spacingMd),

            // Time input with time picker
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Time (${_timeFormat.pattern})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.access_time),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.schedule),
                  tooltip: 'Pick time',
                  onPressed: _pickTime,
                ),
                hintText: _timeFormat.pattern,
              ),
              keyboardType: TextInputType.datetime,
              onChanged: _parseTime,
              onSubmitted: _parseTime,
            ),

            if (widget.showBasis) ...[
              const SizedBox(height: AisTheme.spacingMd),
              TextField(
                controller: _basisController,
                decoration: const InputDecoration(
                  labelText: 'Basis',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                  hintText: 'e.g., Accrual, Cash',
                ),
              ),
            ],
            if (widget.showSource) ...[
              const SizedBox(height: AisTheme.spacingMd),
              TextField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.source),
                  hintText: 'e.g., Import, Manual',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final amount =
                double.tryParse(_amountController.text) ?? widget.amount;
            Navigator.pop(context, {
              'amount': amount,
              'currency': _selectedCurrency,
              'date': _selectedDate,
              'time': _selectedTime,
              'basis': _basisController.text,
              'source': _sourceController.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Edit dialog for metric values with freshness date picker
class _MetricEditDialog extends StatefulWidget {
  final String title;
  final String metricName;
  final double value;
  final String unit;
  final String version;
  final String sufficiency;
  final String? denominator;
  final DateTime? freshness;
  final bool allowNullFreshness;

  const _MetricEditDialog({
    required this.title,
    required this.metricName,
    required this.value,
    required this.unit,
    required this.version,
    required this.sufficiency,
    this.denominator,
    this.freshness,
    this.allowNullFreshness = false,
  });

  @override
  State<_MetricEditDialog> createState() => _MetricEditDialogState();
}

class _MetricEditDialogState extends State<_MetricEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late TextEditingController _unitController;
  late TextEditingController _versionController;
  late TextEditingController _denominatorController;
  late TextEditingController _freshnessController;
  late String _selectedSufficiency;
  DateTime? _selectedFreshness;
  bool _hasFreshness = true;

  final _sufficiencies = ['High', 'Medium', 'Low', 'Insufficient'];

  DateFormat get _dateFormat {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMd(locale.toString());
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.metricName);
    _valueController =
        TextEditingController(text: widget.value.toStringAsFixed(2));
    _unitController = TextEditingController(text: widget.unit);
    _versionController = TextEditingController(text: widget.version);
    _denominatorController =
        TextEditingController(text: widget.denominator ?? '');
    _selectedSufficiency = widget.sufficiency;
    _selectedFreshness = widget.freshness;
    _hasFreshness = widget.freshness != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _freshnessController = TextEditingController(
      text: _selectedFreshness != null
          ? _dateFormat.format(_selectedFreshness!)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _unitController.dispose();
    _versionController.dispose();
    _denominatorController.dispose();
    _freshnessController.dispose();
    super.dispose();
  }

  Future<void> _pickFreshness() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFreshness ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select freshness date',
    );
    if (picked != null) {
      setState(() {
        _selectedFreshness = picked;
        _hasFreshness = true;
        _freshnessController.text = _dateFormat.format(picked);
      });
    }
  }

  void _parseFreshness(String value) {
    if (value.isEmpty && widget.allowNullFreshness) {
      setState(() {
        _selectedFreshness = null;
        _hasFreshness = false;
      });
      return;
    }
    try {
      final parsed = _dateFormat.parse(value);
      setState(() {
        _selectedFreshness = parsed;
        _hasFreshness = true;
      });
    } catch (_) {
      // Invalid format, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Metric Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.analytics),
              ),
            ),
            const SizedBox(height: AisTheme.spacingMd),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: AisTheme.spacingMd),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
                hintText: 'e.g., USD, %, ms',
              ),
            ),
            const SizedBox(height: AisTheme.spacingMd),
            TextField(
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: 'Definition Version * (Required)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                hintText: 'e.g., 1.0, 2.1-beta',
              ),
            ),
            const SizedBox(height: AisTheme.spacingMd),
            DropdownButtonFormField<String>(
              value: _selectedSufficiency,
              decoration: const InputDecoration(
                labelText: 'Data Sufficiency * (Required)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bar_chart),
              ),
              items: _sufficiencies
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSufficiency = value);
                }
              },
            ),
            const SizedBox(height: AisTheme.spacingMd),
            TextField(
              controller: _denominatorController,
              decoration: const InputDecoration(
                labelText: 'Denominator',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
                hintText: 'e.g., per customer, per day',
              ),
            ),
            const SizedBox(height: AisTheme.spacingMd),

            // Freshness date picker
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _freshnessController,
                    decoration: InputDecoration(
                      labelText: widget.allowNullFreshness
                          ? 'Freshness Date (optional)'
                          : 'Freshness Date',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.update),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        tooltip: 'Pick date',
                        onPressed: _pickFreshness,
                      ),
                      hintText: _dateFormat.pattern,
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: _parseFreshness,
                    onSubmitted: _parseFreshness,
                  ),
                ),
                if (widget.allowNullFreshness && _hasFreshness) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear date',
                    onPressed: () {
                      setState(() {
                        _selectedFreshness = null;
                        _hasFreshness = false;
                        _freshnessController.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value =
                double.tryParse(_valueController.text) ?? widget.value;
            Navigator.pop(context, {
              'metricName': _nameController.text,
              'value': value,
              'unit': _unitController.text,
              'version': _versionController.text,
              'sufficiency': _selectedSufficiency,
              'denominator': _denominatorController.text,
              'freshness': _selectedFreshness,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AisTheme.spacingXs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: tokens.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }
}

class _EditableValueCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback onEdit;

  const _EditableValueCard({
    required this.title,
    this.subtitle,
    required this.child,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
        border: Border.all(
          color: tokens.actionPrimary.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.onSurfaceSecondary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.onSurfaceSecondary.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AisTheme.spacingSm,
                    vertical: AisTheme.spacingXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: tokens.actionPrimary.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.actionPrimary.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AisTheme.spacingSm),
          child,
        ],
      ),
    );
  }
}

class _ValueShowcase extends StatelessWidget {
  final String title;
  final Widget child;

  const _ValueShowcase({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
        border: Border.all(
          color: tokens.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: tokens.onSurfaceSecondary,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          child,
        ],
      ),
    );
  }
}

class _DistinctionItem extends StatelessWidget {
  final String label;
  final String description;

  const _DistinctionItem({
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Padding(
      padding: const EdgeInsets.only(top: AisTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_rounded,
            size: 14,
            color: tokens.actionConfirm.color,
          ),
          const SizedBox(width: AisTheme.spacingSm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnotationItem extends StatelessWidget {
  final String label;
  final String value;

  const _AnnotationItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: tokens.onSurfaceSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

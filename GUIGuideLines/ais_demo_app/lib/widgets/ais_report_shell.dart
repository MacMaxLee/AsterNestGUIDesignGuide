import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Report Shell (§1.3)
///
/// Key requirements:
/// - Period selector, comparison period, grouping, drill path
/// - Drill-through to source records is MANDATORY
/// - Footing assertion: residual displayed, non-zero flagged
/// - Annotation bar on every report
/// - Export carries the annotation bar

class AisReportShell extends StatelessWidget {
  final String title;
  final Widget? header;
  final List<AisReportRow> rows;
  final AisReportFooter? footer;

  // Period controls
  final String currentPeriod;
  final String? comparisonPeriod;
  final VoidCallback? onPeriodChange;
  final VoidCallback? onComparisonChange;

  // Grouping
  final String? grouping;
  final List<String>? groupingOptions;
  final void Function(String?)? onGroupingChange;

  // Drill path
  final List<String> drillPath;
  final void Function(int index)? onDrillUp;

  // Annotations (§3.2)
  final String currency;
  final String? basis;
  final String? dataSufficiency;
  final DateTime? dataAsOf;

  // Export
  final VoidCallback? onExport;

  const AisReportShell({
    super.key,
    required this.title,
    required this.rows,
    required this.currentPeriod,
    required this.currency,
    required this.drillPath,
    this.header,
    this.footer,
    this.comparisonPeriod,
    this.onPeriodChange,
    this.onComparisonChange,
    this.grouping,
    this.groupingOptions,
    this.onGroupingChange,
    this.onDrillUp,
    this.basis,
    this.dataSufficiency,
    this.dataAsOf,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Report header with controls
        Container(
          color: tokens.surface,
          padding: const EdgeInsets.all(AisTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and export
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onExport != null)
                    TextButton.icon(
                      onPressed: onExport,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export'),
                    ),
                ],
              ),

              const SizedBox(height: AisTheme.spacingMd),

              // Drill path breadcrumbs
              if (drillPath.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < drillPath.length; i++) ...[
                        if (i > 0)
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: tokens.onSurfaceSecondary,
                          ),
                        InkWell(
                          onTap: i < drillPath.length - 1
                              ? () => onDrillUp?.call(i)
                              : null,
                          child: Text(
                            drillPath[i],
                            style: TextStyle(
                              color: i < drillPath.length - 1
                                  ? tokens.actionPrimary.color
                                  : tokens.onSurface,
                              fontWeight: i < drillPath.length - 1
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: AisTheme.spacingMd),

              // Period and grouping controls
              Wrap(
                spacing: AisTheme.spacingMd,
                runSpacing: AisTheme.spacingSm,
                children: [
                  // Period selector
                  _ControlChip(
                    icon: Icons.calendar_today_rounded,
                    label: currentPeriod,
                    onTap: onPeriodChange,
                  ),

                  // Comparison period
                  if (comparisonPeriod != null)
                    _ControlChip(
                      icon: Icons.compare_arrows_rounded,
                      label: 'vs $comparisonPeriod',
                      onTap: onComparisonChange,
                    ),

                  // Grouping
                  if (grouping != null)
                    _ControlChip(
                      icon: Icons.view_list_rounded,
                      label: grouping!,
                      onTap: () => _showGroupingSheet(context),
                    ),
                ],
              ),

              const SizedBox(height: AisTheme.spacingMd),

              // Annotation bar (§3.2) - ALWAYS visible
              _AnnotationBar(
                currency: currency,
                period: currentPeriod,
                basis: basis,
                dataSufficiency: dataSufficiency,
                dataAsOf: dataAsOf,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Custom header if provided
        if (header != null) ...[
          header!,
          const Divider(height: 1),
        ],

        // Report rows
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: tokens.onSurfaceSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AisTheme.spacingMd),
                      Text(
                        'No data for this period',
                        style: TextStyle(
                          color: tokens.onSurfaceSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AisTheme.spacingMd),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AisTheme.spacingSm),
                  itemBuilder: (context, index) => rows[index],
                ),
        ),

        // Footer with totals
        if (footer != null) ...[
          const Divider(height: 1),
          footer!,
        ],
      ],
    );
  }

  void _showGroupingSheet(BuildContext context) {
    if (groupingOptions == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AisTheme.spacingMd),
              child: Text(
                'Group By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...groupingOptions!.map((option) => ListTile(
                  title: Text(option),
                  trailing: option == grouping
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onGroupingChange?.call(option);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

/// Control chip for report filters
class _ControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ControlChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AisTheme.spacingSm,
          vertical: AisTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: tokens.onSurface.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(AisTheme.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tokens.onSurfaceSecondary),
            const SizedBox(width: AisTheme.spacingXs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: tokens.onSurface,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AisTheme.spacingXs),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: tokens.onSurfaceSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Annotation bar (§3.2)
class _AnnotationBar extends StatelessWidget {
  final String currency;
  final String period;
  final String? basis;
  final String? dataSufficiency;
  final DateTime? dataAsOf;

  const _AnnotationBar({
    required this.currency,
    required this.period,
    this.basis,
    this.dataSufficiency,
    this.dataAsOf,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Semantics(
      label: 'Report annotations: Currency $currency, Period $period'
          '${basis != null ? ', Basis $basis' : ''}'
          '${dataSufficiency != null ? ', Data sufficiency $dataSufficiency' : ''}',
      child: Container(
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
            Expanded(
              child: Wrap(
                spacing: AisTheme.spacingMd,
                children: [
                  _AnnotationItem(label: 'Currency', value: currency),
                  _AnnotationItem(label: 'Period', value: period),
                  if (basis != null) _AnnotationItem(label: 'Basis', value: basis!),
                  if (dataSufficiency != null)
                    _AnnotationItem(label: 'Data', value: dataSufficiency!),
                  if (dataAsOf != null)
                    _AnnotationItem(
                      label: 'As of',
                      value: DateFormat.MMMd().format(dataAsOf!),
                    ),
                ],
              ),
            ),
          ],
        ),
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

/// Report row with drill-through
class AisReportRow extends StatelessWidget {
  final String label;
  final double value;
  final double? comparisonValue;
  final String currency;
  final bool canDrillThrough;
  final VoidCallback? onDrillThrough;
  final int indentLevel;

  const AisReportRow({
    super.key,
    required this.label,
    required this.value,
    required this.currency,
    this.comparisonValue,
    this.canDrillThrough = true, // AIS §1.3: Drill-through is MANDATORY
    this.onDrillThrough,
    this.indentLevel = 0,
  });

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      case 'JPY':
        return '\u00A5';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );

    final variance = comparisonValue != null ? value - comparisonValue! : null;
    final variancePercent = comparisonValue != null && comparisonValue != 0
        ? (variance! / comparisonValue!) * 100
        : null;

    return InkWell(
      onTap: canDrillThrough ? onDrillThrough : null,
      borderRadius: BorderRadius.circular(AisTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(AisTheme.radiusMd),
          border: Border.all(
            color: tokens.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Indent
            SizedBox(width: indentLevel * AisTheme.spacingMd),

            // Label
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // Drill-through indicator (§1.3: MANDATORY)
                  if (canDrillThrough) ...[
                    const SizedBox(width: AisTheme.spacingXs),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: tokens.actionPrimary.color,
                    ),
                  ],
                ],
              ),
            ),

            // Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (variance != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        variance >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: variance >= 0
                            ? tokens.actionConfirm.color
                            : tokens.stateError.color,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${variancePercent!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: variance >= 0
                              ? tokens.actionConfirm.color
                              : tokens.stateError.color,
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
}

/// Report footer with totals and footing assertion
class AisReportFooter extends StatelessWidget {
  final String label;
  final double total;
  final double? expectedTotal;
  final String currency;
  final String? refusalReason; // §3.3: When aggregation cannot be done

  const AisReportFooter({
    super.key,
    required this.label,
    required this.total,
    required this.currency,
    this.expectedTotal,
    this.refusalReason,
  });

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      case 'JPY':
        return '\u00A5';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );

    // AIS §1.3: Non-zero residual is flagged
    final residual = expectedTotal != null ? total - expectedTotal! : 0.0;
    final hasResidual = residual.abs() > 0.005;

    // AIS §3.3: Aggregation refusal
    if (refusalReason != null) {
      return Container(
        color: tokens.surface,
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                Icon(
                  tokens.stateWarning.icon,
                  size: 16,
                  color: tokens.stateWarning.color,
                ),
                const SizedBox(width: AisTheme.spacingXs),
                Text(
                  refusalReason!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: tokens.stateWarning.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      color: tokens.surface,
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasResidual)
                Row(
                  children: [
                    Icon(
                      tokens.stateError.icon,
                      size: 12,
                      color: tokens.stateError.color,
                    ),
                    const SizedBox(width: AisTheme.spacingXs),
                    Text(
                      'Residual: ${formatter.format(residual)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.stateError.color,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

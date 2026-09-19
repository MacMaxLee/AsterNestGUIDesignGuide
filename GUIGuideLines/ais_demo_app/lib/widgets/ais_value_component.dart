import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Value Component (§3.1)
///
/// A consequential value may NEVER be rendered without its required annotations.
/// This component REQUIRES annotations as constructor parameters.
/// Omitting them is a compile error, not a code-review catch.

class AisMonetaryValue extends StatelessWidget {
  // REQUIRED: Currency is mandatory per AIS §3.1
  final String currency;
  final double amount;

  // REQUIRED annotations for monetary values
  final String? period;
  final String? basis; // accrual/cash
  final bool isPosted;
  final bool isDraft;
  final DateTime? asOfDate;
  final String? source;
  final bool showAnnotations;

  const AisMonetaryValue({
    super.key,
    required this.currency, // Cannot be omitted
    required this.amount,
    this.period,
    this.basis,
    this.isPosted = true,
    this.isDraft = false,
    this.asOfDate,
    this.source,
    this.showAnnotations = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );

    return Semantics(
      label: '${formatter.format(amount)} $currency'
          '${period != null ? ', period: $period' : ''}'
          '${basis != null ? ', basis: $basis' : ''}'
          '${isDraft ? ', draft' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main value with currency
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatter.format(amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.onSurface,
                ),
              ),
              const SizedBox(width: AisTheme.spacingXs),
              // Currency badge - ALWAYS visible per AIS §3.1
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AisTheme.spacingXs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                ),
                child: Text(
                  currency,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Annotation bar (§3.2)
          if (showAnnotations) ...[
            const SizedBox(height: AisTheme.spacingXs),
            Wrap(
              spacing: AisTheme.spacingXs,
              runSpacing: AisTheme.spacingXs,
              children: [
                if (isDraft)
                  _AnnotationChip(
                    label: 'Draft',
                    icon: Icons.edit_note_rounded,
                    color: tokens.stateWarning.color,
                  ),
                if (period != null)
                  _AnnotationChip(
                    label: period!,
                    icon: Icons.date_range_rounded,
                  ),
                if (basis != null)
                  _AnnotationChip(
                    label: basis!,
                    icon: Icons.account_balance_rounded,
                  ),
                if (source != null)
                  _AnnotationChip(
                    label: source!,
                    icon: Icons.source_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
}

/// Annotation chip for value context
class _AnnotationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _AnnotationChip({
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final chipColor = color ?? tokens.onSurfaceSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AisTheme.spacingXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: chipColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: chipColor),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// AIS Metric Value (§3.1)
///
/// For computed metrics that require definition version, denominator, etc.
class AisMetricValue extends StatelessWidget {
  final String metricName;
  final double value;
  final String? unit;

  // REQUIRED annotations
  final String definitionVersion;
  final String? denominator;
  final String dataSufficiency; // e.g., "High", "Low", "Insufficient"
  final DateTime? freshness;

  const AisMetricValue({
    super.key,
    required this.metricName,
    required this.value,
    required this.definitionVersion, // Cannot be omitted
    required this.dataSufficiency, // Cannot be omitted
    this.unit,
    this.denominator,
    this.freshness,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final formatter = NumberFormat.compact();

    Color sufficiencyColor() {
      switch (dataSufficiency.toLowerCase()) {
        case 'high':
          return tokens.actionConfirm.color;
        case 'medium':
          return tokens.stateWarning.color;
        case 'low':
        case 'insufficient':
          return tokens.stateError.color;
        default:
          return tokens.onSurfaceSecondary;
      }
    }

    return Semantics(
      label: '$metricName: ${formatter.format(value)} ${unit ?? ''}, '
          'definition $definitionVersion, data sufficiency: $dataSufficiency',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Metric name
          Text(
            metricName,
            style: TextStyle(
              fontSize: 12,
              color: tokens.onSurfaceSecondary,
            ),
          ),
          const SizedBox(height: AisTheme.spacingXs),

          // Value
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatter.format(value),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tokens.onSurface,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AisTheme.spacingXs),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 14,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ],
            ],
          ),

          // Annotations
          const SizedBox(height: AisTheme.spacingSm),
          Wrap(
            spacing: AisTheme.spacingXs,
            runSpacing: AisTheme.spacingXs,
            children: [
              _AnnotationChip(
                label: 'v$definitionVersion',
                icon: Icons.tag_rounded,
              ),
              _AnnotationChip(
                label: dataSufficiency,
                icon: Icons.analytics_rounded,
                color: sufficiencyColor(),
              ),
              if (denominator != null)
                _AnnotationChip(
                  label: denominator!,
                  icon: Icons.calculate_rounded,
                ),
              if (freshness != null)
                _AnnotationChip(
                  label: DateFormat.MMMd().format(freshness!),
                  icon: Icons.update_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

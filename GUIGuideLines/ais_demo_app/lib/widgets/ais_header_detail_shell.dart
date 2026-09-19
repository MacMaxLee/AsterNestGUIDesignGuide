import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Header/Detail Shell (§1.2)
///
/// Used ONLY where child lines must satisfy an assertion the header makes.
/// The invariant is a REQUIRED parameter - construction without one must fail.
///
/// Examples:
/// - Journal entry: Debits equal credits
/// - Cost record: Allocations total the cost amount
/// - Invoice: Lines plus tax equal the total

/// The invariant assertion type
typedef AisInvariantAssertion = ({
  String description,
  double Function() calculateActual,
  double Function() calculateExpected,
});

class AisHeaderDetailShell extends StatelessWidget {
  // REQUIRED: The invariant MUST be declared (§1.2)
  final AisInvariantAssertion invariant;

  // Header content
  final Widget header;

  // Child lines
  final List<Widget> children;

  // Currency for display
  final String currency;

  // Actions
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onAddLine;

  // Whether changes are being saved
  final bool isSaving;

  const AisHeaderDetailShell({
    super.key,
    required this.invariant, // Cannot be omitted - compile error
    required this.header,
    required this.children,
    required this.currency,
    this.onSave,
    this.onCancel,
    this.onAddLine,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final actual = invariant.calculateActual();
    final expected = invariant.calculateExpected();
    final residual = actual - expected;
    final isBalanced = residual.abs() < 0.005; // Account for floating point

    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );

    return Scaffold(
      body: Column(
        children: [
          // Header section
          Container(
            color: tokens.surface,
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: AisTheme.spacingMd),

                // Invariant assertion bar - always visible (§1.2)
                _InvariantBar(
                  invariant: invariant,
                  actual: actual,
                  expected: expected,
                  residual: residual,
                  isBalanced: isBalanced,
                  currency: currency,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Child lines
          Expanded(
            child: children.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          size: 48,
                          color: tokens.onSurfaceSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AisTheme.spacingMd),
                        Text(
                          'No lines yet',
                          style: TextStyle(
                            color: tokens.onSurfaceSecondary,
                          ),
                        ),
                        if (onAddLine != null) ...[
                          const SizedBox(height: AisTheme.spacingMd),
                          TextButton.icon(
                            onPressed: onAddLine,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Line'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AisTheme.spacingMd),
                    children: [
                      ...children,
                      if (onAddLine != null) ...[
                        const SizedBox(height: AisTheme.spacingMd),
                        Center(
                          child: TextButton.icon(
                            onPressed: onAddLine,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Line'),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          // Footer with actions
          Container(
            color: tokens.surface,
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            child: Row(
              children: [
                // Residual summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Residual',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.onSurfaceSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isBalanced
                                ? tokens.actionConfirm.icon
                                : tokens.stateError.icon,
                            size: 16,
                            color: isBalanced
                                ? tokens.actionConfirm.color
                                : tokens.stateError.color,
                          ),
                          const SizedBox(width: AisTheme.spacingXs),
                          Text(
                            formatter.format(residual),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isBalanced
                                  ? tokens.actionConfirm.color
                                  : tokens.stateError.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  children: [
                    if (onCancel != null)
                      TextButton(
                        onPressed: isSaving ? null : onCancel,
                        child: Row(
                          children: [
                            Icon(tokens.actionNeutral.icon, size: 16),
                            const SizedBox(width: AisTheme.spacingXs),
                            const Text('Cancel'),
                          ],
                        ),
                      ),
                    const SizedBox(width: AisTheme.spacingSm),
                    if (onSave != null)
                      ElevatedButton(
                        // AIS §1.2: Save is BLOCKED while residual ≠ 0
                        onPressed: isBalanced && !isSaving ? onSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.actionConfirm.color,
                          disabledBackgroundColor:
                              tokens.stateUnavailable.color.withOpacity(0.3),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(tokens.actionConfirm.icon, size: 16),
                                  const SizedBox(width: AisTheme.spacingXs),
                                  const Text('Save'),
                                ],
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
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

/// Invariant bar showing running total, target, and residual
class _InvariantBar extends StatelessWidget {
  final AisInvariantAssertion invariant;
  final double actual;
  final double expected;
  final double residual;
  final bool isBalanced;
  final String currency;

  const _InvariantBar({
    required this.invariant,
    required this.actual,
    required this.expected,
    required this.residual,
    required this.isBalanced,
    required this.currency,
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

    return Semantics(
      label: 'Invariant: ${invariant.description}. '
          'Actual: ${formatter.format(actual)}, '
          'Expected: ${formatter.format(expected)}, '
          'Residual: ${formatter.format(residual)}',
      child: Container(
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        decoration: BoxDecoration(
          color: isBalanced
              ? tokens.actionConfirm.color.withOpacity(0.1)
              : tokens.stateError.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AisTheme.radiusMd),
          border: Border.all(
            color: isBalanced
                ? tokens.actionConfirm.color.withOpacity(0.3)
                : tokens.stateError.color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invariant description
            Row(
              children: [
                Icon(
                  isBalanced
                      ? tokens.actionConfirm.icon
                      : tokens.stateWarning.icon,
                  size: 16,
                  color: isBalanced
                      ? tokens.actionConfirm.color
                      : tokens.stateWarning.color,
                ),
                const SizedBox(width: AisTheme.spacingSm),
                Text(
                  invariant.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isBalanced
                        ? tokens.actionConfirm.color
                        : tokens.stateWarning.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingSm),

            // Values row
            Row(
              children: [
                Expanded(
                  child: _ValueColumn(
                    label: 'Actual',
                    value: formatter.format(actual),
                  ),
                ),
                Expanded(
                  child: _ValueColumn(
                    label: 'Expected',
                    value: formatter.format(expected),
                  ),
                ),
                Expanded(
                  child: _ValueColumn(
                    label: 'Residual',
                    value: formatter.format(residual),
                    valueColor: isBalanced
                        ? tokens.actionConfirm.color
                        : tokens.stateError.color,
                    isBold: true,
                  ),
                ),
              ],
            ),

            // Warning if not balanced
            if (!isBalanced) ...[
              const SizedBox(height: AisTheme.spacingSm),
              Row(
                children: [
                  Icon(
                    tokens.stateError.icon,
                    size: 14,
                    color: tokens.stateError.color,
                  ),
                  const SizedBox(width: AisTheme.spacingXs),
                  Text(
                    'Save is blocked until residual equals zero',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.stateError.color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _ValueColumn({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: tokens.onSurfaceSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? tokens.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Line item widget for header/detail
class AisHeaderDetailLine extends StatelessWidget {
  final String description;
  final double amount;
  final String currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isEditing;

  const AisHeaderDetailLine({
    super.key,
    required this.description,
    required this.amount,
    required this.currency,
    this.onEdit,
    this.onDelete,
    this.isEditing = false,
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

    return Container(
      margin: const EdgeInsets.only(bottom: AisTheme.spacingSm),
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
        border: Border.all(
          color: isEditing
              ? tokens.actionPrimary.color
              : tokens.onSurface.withOpacity(0.1),
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            formatter.format(amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: AisTheme.spacingSm),
            if (onEdit != null)
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: tokens.actionPrimary.color,
                ),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_rounded,
                  size: 18,
                  color: tokens.actionDestructive.color,
                ),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
          ],
        ],
      ),
    );
  }
}

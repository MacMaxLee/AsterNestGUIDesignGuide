import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS History Viewer (§1.4)
///
/// Key requirements:
/// - Two entry points: standalone AND from the record itself
/// - Field-level before/after diff
/// - READ-ONLY: No mutation affordance may exist ANYWHERE

/// A single field change in history
class AisFieldChange {
  final String fieldName;
  final String? oldValue;
  final String? newValue;

  const AisFieldChange({
    required this.fieldName,
    this.oldValue,
    this.newValue,
  });
}

/// A history entry representing a change event
class AisHistoryEntry {
  final String id;
  final DateTime timestamp;
  final String action; // created, updated, deleted
  final String actorName;
  final String? actorId;
  final List<AisFieldChange> changes;
  final String? description;

  const AisHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.actorName,
    this.actorId,
    required this.changes,
    this.description,
  });
}

/// AIS History Viewer Widget
///
/// C-30: History UI exposes NO mutation affordance anywhere
class AisHistoryViewer extends StatelessWidget {
  final String recordTitle;
  final List<AisHistoryEntry> entries;
  final VoidCallback? onClose;
  final bool isStandalone;

  const AisHistoryViewer({
    super.key,
    required this.recordTitle,
    required this.entries,
    this.onClose,
    this.isStandalone = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('History'),
            Text(
              recordTitle,
              style: TextStyle(
                fontSize: 12,
                color: tokens.onSurfaceSecondary,
              ),
            ),
          ],
        ),
        leading: onClose != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
              )
            : null,
        // No actions - READ ONLY per AIS §1.4
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: tokens.onSurfaceSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: AisTheme.spacingMd),
                  Text(
                    'No history available',
                    style: TextStyle(
                      color: tokens.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isLast = index == entries.length - 1;

                return _HistoryEntryCard(
                  entry: entry,
                  isLast: isLast,
                );
              },
            ),
    );
  }
}

/// Individual history entry card
class _HistoryEntryCard extends StatelessWidget {
  final AisHistoryEntry entry;
  final bool isLast;

  const _HistoryEntryCard({
    required this.entry,
    required this.isLast,
  });

  IconData _getActionIcon() {
    switch (entry.action.toLowerCase()) {
      case 'created':
        return Icons.add_circle_rounded;
      case 'deleted':
        return Icons.remove_circle_rounded;
      default:
        return Icons.edit_rounded;
    }
  }

  Color _getActionColor(AisTokens tokens) {
    switch (entry.action.toLowerCase()) {
      case 'created':
        return tokens.actionConfirm.color;
      case 'deleted':
        return tokens.actionDestructive.color;
      default:
        return tokens.actionPrimary.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getActionColor(tokens).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(),
                  size: 16,
                  color: _getActionColor(tokens),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: tokens.onSurface.withOpacity(0.1),
                  ),
                ),
            ],
          ),

          const SizedBox(width: AisTheme.spacingMd),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AisTheme.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatAction(entry.action),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${dateFormat.format(entry.timestamp)} at ${timeFormat.format(entry.timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.onSurfaceSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AisTheme.spacingXs),

                  // Actor
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: tokens.onSurfaceSecondary,
                      ),
                      const SizedBox(width: AisTheme.spacingXs),
                      Text(
                        entry.actorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.onSurfaceSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (entry.description != null) ...[
                    const SizedBox(height: AisTheme.spacingSm),
                    Text(
                      entry.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],

                  // Field changes (before/after diff)
                  if (entry.changes.isNotEmpty) ...[
                    const SizedBox(height: AisTheme.spacingSm),
                    Container(
                      decoration: BoxDecoration(
                        color: tokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < entry.changes.length; i++) ...[
                            _FieldChangeDiff(change: entry.changes[i]),
                            if (i < entry.changes.length - 1)
                              Divider(
                                height: 1,
                                color: tokens.onSurface.withOpacity(0.1),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAction(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return 'Record Created';
      case 'updated':
        return 'Record Updated';
      case 'deleted':
        return 'Record Deleted';
      default:
        return action;
    }
  }
}

/// Field-level before/after diff display
class _FieldChangeDiff extends StatelessWidget {
  final AisFieldChange change;

  const _FieldChangeDiff({required this.change});

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final isNew = change.oldValue == null;
    final isDeleted = change.newValue == null;

    return Padding(
      padding: const EdgeInsets.all(AisTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field name
          Text(
            change.fieldName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tokens.onSurfaceSecondary,
            ),
          ),
          const SizedBox(height: AisTheme.spacingXs),

          // Values
          Row(
            children: [
              // Old value
              if (!isNew)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AisTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: tokens.actionDestructive.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.remove_rounded,
                          size: 12,
                          color: tokens.actionDestructive.color,
                        ),
                        const SizedBox(width: AisTheme.spacingXs),
                        Expanded(
                          child: Text(
                            change.oldValue ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.actionDestructive.color,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!isNew && !isDeleted) ...[
                const SizedBox(width: AisTheme.spacingXs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: tokens.onSurfaceSecondary,
                ),
                const SizedBox(width: AisTheme.spacingXs),
              ],

              // New value
              if (!isDeleted)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AisTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: tokens.actionConfirm.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 12,
                          color: tokens.actionConfirm.color,
                        ),
                        const SizedBox(width: AisTheme.spacingXs),
                        Expanded(
                          child: Text(
                            change.newValue ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.actionConfirm.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Button to access history from a record (§1.4 - second entry point)
class AisHistoryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AisHistoryButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Semantics(
      button: true,
      label: 'View history',
      child: IconButton(
        icon: Icon(
          Icons.history_rounded,
          color: tokens.onSurfaceSecondary,
        ),
        onPressed: onPressed,
        tooltip: 'View History',
      ),
    );
  }
}

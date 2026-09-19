import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_list_detail_shell.dart';
import '../widgets/ais_button.dart';
import '../widgets/ais_history_viewer.dart';

/// Demo screen for AIS List-Detail Shell (§1.1)
class ListDetailDemoScreen extends StatefulWidget {
  const ListDetailDemoScreen({super.key});

  @override
  State<ListDetailDemoScreen> createState() => _ListDetailDemoScreenState();
}

class _ListDetailDemoScreenState extends State<ListDetailDemoScreen> {
  final List<_DemoRecord> _records = List.generate(
    20,
    (i) => _DemoRecord(
      id: 'REC-${1000 + i}',
      title: 'Record ${i + 1}',
      description: 'This is a sample record for demonstration',
      amount: (i + 1) * 125.50,
      status: i % 3 == 0 ? 'Active' : (i % 3 == 1 ? 'Pending' : 'Complete'),
      date: DateTime.now().subtract(Duration(days: i)),
    ),
  );

  int? _selectedIndex;
  bool _hasUnsavedChanges = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List-Detail Shell Demo'),
      ),
      body: AisListDetailShell<_DemoRecord>(
        title: 'Records',
        items: _records,
        selectedIndex: _selectedIndex,
        hasUnsavedChanges: _hasUnsavedChanges,
        searchHint: 'Search records...',
        sortLabel: 'Date',
        itemSearchableText: (record) => '${record.title} ${record.description}',
        itemBuilder: (record, isSelected) => _RecordListItem(
          record: record,
          isSelected: isSelected,
        ),
        onSelectionChanged: (index) {
          setState(() {
            _selectedIndex = index >= 0 ? index : null;
            _hasUnsavedChanges = false;
            if (_selectedIndex != null) {
              _titleController.text = _records[_selectedIndex!].title;
              _descController.text = _records[_selectedIndex!].description;
            }
          });
        },
        onDiscardChanges: () {
          setState(() {
            _hasUnsavedChanges = false;
          });
        },
        onSaveChanges: () {
          if (_selectedIndex != null) {
            setState(() {
              _records[_selectedIndex!] = _records[_selectedIndex!].copyWith(
                title: _titleController.text,
                description: _descController.text,
              );
              _hasUnsavedChanges = false;
            });
          }
        },
        onNewRecordPressed: () {
          setState(() {
            _records.insert(
              0,
              _DemoRecord(
                id: 'REC-${1000 + _records.length}',
                title: 'New Record',
                description: 'Enter description',
                amount: 0,
                status: 'Draft',
                date: DateTime.now(),
              ),
            );
            _selectedIndex = 0;
          });
        },
        detailBuilder: (record) => _buildDetailPane(record),
      ),
    );
  }

  Widget _buildDetailPane(_DemoRecord? record) {
    final tokens = context.aisTokens;

    if (record == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 48,
              color: tokens.onSurfaceSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AisTheme.spacingMd),
            Text(
              'Select a record to view details',
              style: TextStyle(
                color: tokens.onSurfaceSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.id,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.onSurfaceSecondary,
                      ),
                    ),
                    const SizedBox(height: AisTheme.spacingXs),
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // History button (§1.4 - second entry point)
              AisHistoryButton(
                onPressed: () => _showHistory(record),
              ),
            ],
          ),

          const SizedBox(height: AisTheme.spacingLg),
          const Divider(),
          const SizedBox(height: AisTheme.spacingLg),

          // Edit form
          Text(
            'Edit Record',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingMd),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
            ),
            onChanged: (_) => setState(() => _hasUnsavedChanges = true),
          ),
          const SizedBox(height: AisTheme.spacingMd),

          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
            maxLines: 3,
            onChanged: (_) => setState(() => _hasUnsavedChanges = true),
          ),

          const Spacer(),

          // Unsaved changes indicator
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingSm),
              margin: const EdgeInsets.only(bottom: AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.stateWarning.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AisTheme.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    tokens.stateWarning.icon,
                    size: 16,
                    color: tokens.stateWarning.color,
                  ),
                  const SizedBox(width: AisTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'You have unsaved changes',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.stateWarning.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AisOutlinedButton(
                label: 'Cancel',
                type: AisButtonType.neutral,
                onPressed: _hasUnsavedChanges
                    ? () {
                        setState(() {
                          _titleController.text = record.title;
                          _descController.text = record.description;
                          _hasUnsavedChanges = false;
                        });
                      }
                    : null,
              ),
              const SizedBox(width: AisTheme.spacingSm),
              AisButton(
                label: 'Save',
                type: AisButtonType.confirm,
                onPressed: _hasUnsavedChanges
                    ? () {
                        setState(() {
                          _records[_selectedIndex!] = record.copyWith(
                            title: _titleController.text,
                            description: _descController.text,
                          );
                          _hasUnsavedChanges = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Record saved')),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHistory(_DemoRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => AisHistoryViewer(
          recordTitle: record.title,
          onClose: () => Navigator.pop(context),
          entries: [
            AisHistoryEntry(
              id: '3',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              action: 'updated',
              actorName: 'John Doe',
              changes: [
                const AisFieldChange(
                  fieldName: 'Status',
                  oldValue: 'Pending',
                  newValue: 'Active',
                ),
              ],
            ),
            AisHistoryEntry(
              id: '2',
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
              action: 'updated',
              actorName: 'Jane Smith',
              changes: [
                AisFieldChange(
                  fieldName: 'Description',
                  oldValue: 'Initial description',
                  newValue: record.description,
                ),
                AisFieldChange(
                  fieldName: 'Amount',
                  oldValue: '\$100.00',
                  newValue: '\$${record.amount.toStringAsFixed(2)}',
                ),
              ],
            ),
            AisHistoryEntry(
              id: '1',
              timestamp: DateTime.now().subtract(const Duration(days: 7)),
              action: 'created',
              actorName: 'John Doe',
              changes: [
                AisFieldChange(
                  fieldName: 'Title',
                  newValue: record.title,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

class _DemoRecord {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String status;
  final DateTime date;

  const _DemoRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.status,
    required this.date,
  });

  _DemoRecord copyWith({
    String? title,
    String? description,
    double? amount,
    String? status,
  }) {
    return _DemoRecord(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      date: date,
    );
  }
}

class _RecordListItem extends StatelessWidget {
  final _DemoRecord record;
  final bool isSelected;

  const _RecordListItem({
    required this.record,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    Color statusColor() {
      switch (record.status) {
        case 'Active':
          return tokens.actionConfirm.color;
        case 'Pending':
          return tokens.stateWarning.color;
        default:
          return tokens.onSurfaceSecondary;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.id,
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AisTheme.spacingSm,
              vertical: AisTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: statusColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(AisTheme.radiusSm),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                fontSize: 11,
                color: statusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

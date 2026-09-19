import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS List-Detail Shell (§1.1)
///
/// The primary screen pattern per AIS.
/// Key requirements:
/// - List KEEPS ITS PLACE: selection, scroll, filter, sort survive edit-save
/// - Unsaved changes BLOCK selection change, not just navigation
/// - Compact viewport: separate routes
/// - Deep link addresses a record and restores surrounding list state
/// - TWO empty states: no-records vs no-matches

class AisListDetailShell<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item, bool isSelected) itemBuilder;
  final Widget Function(T? selectedItem)? detailBuilder;
  final String Function(T item) itemSearchableText;
  final int? selectedIndex;
  final void Function(int index)? onSelectionChanged;
  final bool hasUnsavedChanges;
  final VoidCallback? onDiscardChanges;
  final VoidCallback? onSaveChanges;
  final String? searchHint;
  final Widget? emptyStateNoRecords;
  final Widget? emptyStateNoMatches;
  final List<Widget>? filterChips;
  final VoidCallback? onClearFilters;
  final bool isFiltered;
  final String? sortLabel;
  final VoidCallback? onSortPressed;
  final VoidCallback? onNewRecordPressed;
  final String? title;

  const AisListDetailShell({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemSearchableText,
    this.detailBuilder,
    this.selectedIndex,
    this.onSelectionChanged,
    this.hasUnsavedChanges = false,
    this.onDiscardChanges,
    this.onSaveChanges,
    this.searchHint,
    this.emptyStateNoRecords,
    this.emptyStateNoMatches,
    this.filterChips,
    this.onClearFilters,
    this.isFiltered = false,
    this.sortLabel,
    this.onSortPressed,
    this.onNewRecordPressed,
    this.title,
  });

  @override
  State<AisListDetailShell<T>> createState() => _AisListDetailShellState<T>();
}

class _AisListDetailShellState<T> extends State<AisListDetailShell<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      return widget.itemSearchableText(item)
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _handleSelectionAttempt(int index) {
    // AIS §1.1: Unsaved changes BLOCK selection change
    if (widget.hasUnsavedChanges) {
      _showUnsavedChangesDialog(index);
    } else {
      widget.onSelectionChanged?.call(index);
    }
  }

  Future<void> _showUnsavedChangesDialog(int pendingIndex) async {
    final tokens = context.aisTokens;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              tokens.stateWarning.icon,
              color: tokens.stateWarning.color,
            ),
            const SizedBox(width: AisTheme.spacingSm),
            const Text('Unsaved Changes'),
          ],
        ),
        content: const Text(
          'You have unsaved changes. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(
              'Cancel',
              style: TextStyle(color: tokens.actionNeutral.color),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(
              'Discard',
              style: TextStyle(color: tokens.actionDestructive.color),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.actionConfirm.color,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tokens.actionConfirm.icon, size: 16),
                const SizedBox(width: AisTheme.spacingXs),
                const Text('Save'),
              ],
            ),
          ),
        ],
      ),
    );

    if (result == 'discard') {
      widget.onDiscardChanges?.call();
      widget.onSelectionChanged?.call(pendingIndex);
    } else if (result == 'save') {
      widget.onSaveChanges?.call();
      widget.onSelectionChanged?.call(pendingIndex);
    }
    // 'cancel' - selection does NOT move (AIS §1.1)
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final isCompact = context.isCompact;

    // At compact breakpoint, show only list or detail
    if (isCompact) {
      if (widget.selectedIndex != null && widget.detailBuilder != null) {
        return _buildDetailPane(tokens);
      }
      return _buildListPane(tokens, isCompact: true);
    }

    // Medium and expanded: side-by-side
    return Row(
      children: [
        // List pane
        SizedBox(
          width: context.isMedium ? 280 : 350,
          child: _buildListPane(tokens, isCompact: false),
        ),
        VerticalDivider(width: 1, color: tokens.onSurface.withOpacity(0.1)),
        // Detail pane
        Expanded(
          child: _buildDetailPane(tokens),
        ),
      ],
    );
  }

  Widget _buildListPane(AisTokens tokens, {required bool isCompact}) {
    return Container(
      color: tokens.surface,
      child: Column(
        children: [
          // Header with title
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.onNewRecordPressed != null)
                    IconButton(
                      icon: Icon(
                        Icons.add_rounded,
                        color: tokens.actionPrimary.color,
                      ),
                      tooltip: 'New Record',
                      onPressed: widget.onNewRecordPressed,
                    ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AisTheme.spacingMd),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint ?? 'Search...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          if (widget.filterChips != null && widget.filterChips!.isNotEmpty) ...[
            const SizedBox(height: AisTheme.spacingSm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AisTheme.spacingMd),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.filterChips!,
                ),
              ),
            ),
          ],

          // Sort and count
          Padding(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            child: Row(
              children: [
                Text(
                  '${_filteredItems.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
                const Spacer(),
                if (widget.sortLabel != null)
                  TextButton.icon(
                    onPressed: widget.onSortPressed,
                    icon: const Icon(Icons.sort_rounded, size: 16),
                    label: Text(widget.sortLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.onSurfaceSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _buildListContent(tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(AisTokens tokens) {
    // AIS §1.1: TWO empty states, never one
    if (widget.items.isEmpty) {
      // No records exist
      return widget.emptyStateNoRecords ??
          _AisEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No Records',
            subtitle: 'Get started by creating your first record',
            actionLabel: 'Create Record',
            onAction: widget.onNewRecordPressed,
          );
    }

    if (_filteredItems.isEmpty) {
      // No records match filter - different state per AIS §1.1
      return widget.emptyStateNoMatches ??
          _AisEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No Matches',
            subtitle: 'Try adjusting your search or filters',
            actionLabel: 'Clear Filters',
            onAction: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              widget.onClearFilters?.call();
            },
          );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = widget.selectedIndex == widget.items.indexOf(item);

        return InkWell(
          onTap: () => _handleSelectionAttempt(widget.items.indexOf(item)),
          child: Container(
            color: isSelected
                ? tokens.actionPrimary.color.withOpacity(0.1)
                : null,
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 3,
                  height: 48,
                  color: isSelected ? tokens.actionPrimary.color : Colors.transparent,
                ),
                Expanded(
                  child: widget.itemBuilder(item, isSelected),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPane(AisTokens tokens) {
    final selectedItem = widget.selectedIndex != null &&
            widget.selectedIndex! < widget.items.length
        ? widget.items[widget.selectedIndex!]
        : null;

    if (widget.detailBuilder == null) {
      return Container(
        color: tokens.surfaceSecondary,
        child: const Center(
          child: Text('Select an item to view details'),
        ),
      );
    }

    if (context.isCompact && widget.selectedIndex != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (widget.hasUnsavedChanges) {
                _showUnsavedChangesDialog(-1);
              } else {
                widget.onSelectionChanged?.call(-1);
              }
            },
          ),
          title: const Text('Details'),
        ),
        body: widget.detailBuilder!(selectedItem),
      );
    }

    return Container(
      color: tokens.surfaceSecondary,
      child: widget.detailBuilder!(selectedItem),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Empty state widget for list
class _AisEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AisEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AisTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: tokens.onSurfaceSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AisTheme.spacingMd),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.onSurface,
              ),
            ),
            const SizedBox(height: AisTheme.spacingSm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.onSurfaceSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AisTheme.spacingMd),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

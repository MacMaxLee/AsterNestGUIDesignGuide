import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Navigation (§1.5)
///
/// Key requirements:
/// - Task-oriented grouping, not entity-oriented
/// - Maximum TWO levels
/// - Categories fold/unfold, state persisted per user
/// - NOT an accordion - expanding one does not collapse others
/// - Permission filtering SERVER-SIDE
/// - Unavailable ≠ unauthorized
/// - Command palette with fuzzy search

/// Navigation item model
class AisNavItem {
  final String id;
  final String label;
  final IconData icon;
  final String? route;
  final bool isAvailable; // In plan/licence
  final String? upgradeMessage; // If not available
  final List<AisNavItem>? children;

  const AisNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.route,
    this.isAvailable = true,
    this.upgradeMessage,
    this.children,
  });
}

/// Navigation category with fold state
class AisNavCategory {
  final String id;
  final String label;
  final IconData icon;
  final List<AisNavItem> items;
  bool isExpanded;

  AisNavCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
    this.isExpanded = true,
  });
}

/// Main navigation widget
class AisNavigation extends StatefulWidget {
  final List<AisNavCategory> categories;
  final String? selectedItemId;
  final void Function(AisNavItem item) onItemSelected;
  final VoidCallback? onCommandPaletteOpen;

  const AisNavigation({
    super.key,
    required this.categories,
    required this.onItemSelected,
    this.selectedItemId,
    this.onCommandPaletteOpen,
  });

  @override
  State<AisNavigation> createState() => _AisNavigationState();
}

class _AisNavigationState extends State<AisNavigation> {
  @override
  void initState() {
    super.initState();
    // Auto-expand category containing active route (§1.5)
    _autoExpandActiveCategory();
  }

  void _autoExpandActiveCategory() {
    if (widget.selectedItemId == null) return;

    for (final category in widget.categories) {
      final containsActive = category.items.any((item) =>
          item.id == widget.selectedItemId ||
          (item.children?.any((c) => c.id == widget.selectedItemId) ?? false));

      if (containsActive) {
        category.isExpanded = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      color: tokens.surface,
      child: Column(
        children: [
          // Command palette trigger
          Padding(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            child: InkWell(
              onTap: widget.onCommandPaletteOpen ??
                  () => _showCommandPalette(context),
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AisTheme.spacingMd,
                  vertical: AisTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: tokens.onSurfaceSecondary,
                    ),
                    const SizedBox(width: AisTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'Search commands...',
                        style: TextStyle(
                          color: tokens.onSurfaceSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AisTheme.spacingXs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '\u2318K',
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.onSurfaceSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AisTheme.spacingSm),
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                return _CategorySection(
                  category: category,
                  selectedItemId: widget.selectedItemId,
                  onItemSelected: widget.onItemSelected,
                  onToggleExpand: () {
                    // NOT an accordion - just toggle this one (§1.5)
                    setState(() {
                      category.isExpanded = !category.isExpanded;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCommandPalette(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AisCommandPalette(
        categories: widget.categories,
        onItemSelected: (item) {
          Navigator.pop(context);
          widget.onItemSelected(item);
        },
      ),
    );
  }
}

/// Category section with expand/collapse
class _CategorySection extends StatelessWidget {
  final AisNavCategory category;
  final String? selectedItemId;
  final void Function(AisNavItem) onItemSelected;
  final VoidCallback onToggleExpand;

  const _CategorySection({
    required this.category,
    required this.selectedItemId,
    required this.onItemSelected,
    required this.onToggleExpand,
  });

  bool get _containsActiveItem {
    return category.items.any((item) =>
        item.id == selectedItemId ||
        (item.children?.any((c) => c.id == selectedItemId) ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        InkWell(
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AisTheme.spacingMd,
              vertical: AisTheme.spacingSm,
            ),
            child: Row(
              children: [
                Icon(
                  category.isExpanded
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: tokens.onSurfaceSecondary,
                ),
                const SizedBox(width: AisTheme.spacingXs),
                Icon(
                  category.icon,
                  size: 16,
                  color: tokens.onSurfaceSecondary,
                ),
                const SizedBox(width: AisTheme.spacingSm),
                Expanded(
                  child: Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.onSurfaceSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Indicator for collapsed category with active item (§1.5)
                if (!category.isExpanded && _containsActiveItem)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tokens.actionPrimary.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Items
        if (category.isExpanded)
          ...category.items.map((item) => _NavItemTile(
                item: item,
                isSelected: item.id == selectedItemId,
                onTap: () => onItemSelected(item),
                selectedItemId: selectedItemId,
                onChildSelected: onItemSelected,
              )),
      ],
    );
  }
}

/// Individual nav item tile
class _NavItemTile extends StatelessWidget {
  final AisNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final String? selectedItemId;
  final void Function(AisNavItem) onChildSelected;
  final int level;

  const _NavItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.selectedItemId,
    required this.onChildSelected,
    this.level = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    // AIS §1.5: Maximum TWO levels
    if (level > 1) return const SizedBox.shrink();

    // AIS §1.5: Unavailable items show upgrade path, look different from forbidden
    // Forbidden items are ABSENT (filtered server-side)
    // Unavailable items are VISIBLE with upgrade message

    return Column(
      children: [
        InkWell(
          onTap: item.isAvailable
              ? onTap
              : () => _showUpgradeDialog(context, tokens),
          child: Container(
            color: isSelected
                ? tokens.actionPrimary.color.withOpacity(0.1)
                : null,
            padding: EdgeInsets.only(
              left: AisTheme.spacingMd + (level * AisTheme.spacingMd),
              right: AisTheme.spacingMd,
              top: AisTheme.spacingSm,
              bottom: AisTheme.spacingSm,
            ),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 3,
                  height: 24,
                  margin: const EdgeInsets.only(right: AisTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tokens.actionPrimary.color
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icon (§1.5: Module identity carried by ICON)
                Icon(
                  item.icon,
                  size: 18,
                  color: item.isAvailable
                      ? (isSelected
                          ? tokens.actionPrimary.color
                          : tokens.onSurfaceSecondary)
                      : tokens.stateUnavailable.color,
                ),
                const SizedBox(width: AisTheme.spacingSm),

                // Label (§1.5: Menu items use action.neutral)
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: item.isAvailable
                          ? tokens.onSurface
                          : tokens.stateUnavailable.color,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),

                // Unavailable indicator
                if (!item.isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AisTheme.spacingXs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.stateInfo.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upgrade_rounded,
                          size: 10,
                          color: tokens.stateInfo.color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Upgrade',
                          style: TextStyle(
                            fontSize: 10,
                            color: tokens.stateInfo.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Has children indicator
                if (item.children != null && item.children!.isNotEmpty)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: tokens.onSurfaceSecondary,
                  ),
              ],
            ),
          ),
        ),

        // Children (max 2 levels)
        if (item.children != null && level < 1)
          ...item.children!.map((child) => _NavItemTile(
                item: child,
                isSelected: child.id == selectedItemId,
                onTap: () => onChildSelected(child),
                selectedItemId: selectedItemId,
                onChildSelected: onChildSelected,
                level: level + 1,
              )),
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context, AisTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(tokens.stateInfo.icon, color: tokens.stateInfo.color),
            const SizedBox(width: AisTheme.spacingSm),
            const Text('Feature Unavailable'),
          ],
        ),
        content: Text(
          item.upgradeMessage ??
              'This feature is not included in your current plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Would navigate to upgrade page
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}

/// Command palette with fuzzy search (§1.5)
class AisCommandPalette extends StatefulWidget {
  final List<AisNavCategory> categories;
  final void Function(AisNavItem) onItemSelected;

  const AisCommandPalette({
    super.key,
    required this.categories,
    required this.onItemSelected,
  });

  @override
  State<AisCommandPalette> createState() => _AisCommandPaletteState();
}

class _AisCommandPaletteState extends State<AisCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<AisNavItem> get _filteredItems {
    final allItems = <AisNavItem>[];
    for (final category in widget.categories) {
      for (final item in category.items) {
        // C-28: Palette applies IDENTICAL filtering
        // Only show available items
        if (item.isAvailable) {
          allItems.add(item);
        }
        if (item.children != null) {
          for (final child in item.children!) {
            if (child.isAvailable) {
              allItems.add(child);
            }
          }
        }
      }
    }

    if (_query.isEmpty) return allItems;

    // Fuzzy search
    return allItems.where((item) {
      return item.label.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type to search...',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),

            const Divider(height: 1),

            // Results
            Flexible(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AisTheme.spacingXl),
                        child: Text(
                          'No results found',
                          style: TextStyle(color: tokens.onSurfaceSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          leading: Icon(item.icon),
                          title: Text(item.label),
                          onTap: () => widget.onItemSelected(item),
                        );
                      },
                    ),
            ),

            // Footer with keyboard hints
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingSm),
              decoration: BoxDecoration(
                color: tokens.surfaceSecondary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AisTheme.radiusMd),
                  bottomRight: Radius.circular(AisTheme.radiusMd),
                ),
              ),
              child: Row(
                children: [
                  _KeyHint(label: '\u2191\u2193', description: 'Navigate'),
                  const SizedBox(width: AisTheme.spacingMd),
                  _KeyHint(label: '\u21B5', description: 'Select'),
                  const SizedBox(width: AisTheme.spacingMd),
                  _KeyHint(label: 'esc', description: 'Close'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _KeyHint extends StatelessWidget {
  final String label;
  final String description;

  const _KeyHint({
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: tokens.onSurface.withOpacity(0.2)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: tokens.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_navigation.dart';

/// Demo screen for AIS Navigation (§1.5)
class NavigationDemoScreen extends StatefulWidget {
  const NavigationDemoScreen({super.key});

  @override
  State<NavigationDemoScreen> createState() => _NavigationDemoScreenState();
}

class _NavigationDemoScreenState extends State<NavigationDemoScreen> {
  String? _selectedItemId;

  // Sample navigation structure
  // Note: Forbidden items are ABSENT (filtered server-side per §1.5)
  // Only unavailable (outside plan) items are shown
  final List<AisNavCategory> _categories = [
    AisNavCategory(
      id: 'work',
      label: 'WORK',
      icon: Icons.work_rounded,
      items: [
        const AisNavItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          route: '/dashboard',
        ),
        const AisNavItem(
          id: 'transactions',
          label: 'Transactions',
          icon: Icons.receipt_long_rounded,
          route: '/transactions',
          children: [
            AisNavItem(
              id: 'new-transaction',
              label: 'New Transaction',
              icon: Icons.add_rounded,
              route: '/transactions/new',
            ),
            AisNavItem(
              id: 'pending',
              label: 'Pending',
              icon: Icons.pending_rounded,
              route: '/transactions/pending',
            ),
          ],
        ),
        const AisNavItem(
          id: 'reports',
          label: 'Reports',
          icon: Icons.analytics_rounded,
          route: '/reports',
        ),
        const AisNavItem(
          id: 'invoices',
          label: 'Invoices',
          icon: Icons.description_rounded,
          route: '/invoices',
        ),
      ],
    ),
    AisNavCategory(
      id: 'manage',
      label: 'MANAGE',
      icon: Icons.settings_rounded,
      items: [
        const AisNavItem(
          id: 'customers',
          label: 'Customers',
          icon: Icons.people_rounded,
          route: '/customers',
        ),
        const AisNavItem(
          id: 'products',
          label: 'Products',
          icon: Icons.inventory_2_rounded,
          route: '/products',
        ),
        const AisNavItem(
          id: 'vendors',
          label: 'Vendors',
          icon: Icons.store_rounded,
          route: '/vendors',
        ),
      ],
    ),
    AisNavCategory(
      id: 'advanced',
      label: 'ADVANCED',
      icon: Icons.auto_awesome_rounded,
      items: [
        // §1.5: Unavailable items show upgrade path
        const AisNavItem(
          id: 'automation',
          label: 'Automation',
          icon: Icons.smart_toy_rounded,
          route: '/automation',
          isAvailable: false,
          upgradeMessage:
              'Automation is available in the Pro plan. Upgrade to automate recurring tasks and workflows.',
        ),
        const AisNavItem(
          id: 'integrations',
          label: 'Integrations',
          icon: Icons.extension_rounded,
          route: '/integrations',
          isAvailable: false,
          upgradeMessage:
              'Connect to third-party services with the Enterprise plan.',
        ),
        const AisNavItem(
          id: 'api',
          label: 'API Access',
          icon: Icons.api_rounded,
          route: '/api',
          isAvailable: false,
          upgradeMessage:
              'API access requires the Developer add-on. Contact sales for more information.',
        ),
      ],
      isExpanded: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final isCompact = context.isCompact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Demo'),
      ),
      body: Row(
        children: [
          // Navigation sidebar
          SizedBox(
            width: isCompact ? 250 : 280,
            child: AisNavigation(
              categories: _categories,
              selectedItemId: _selectedItemId,
              onItemSelected: (item) {
                setState(() {
                  _selectedItemId = item.id;
                });
              },
            ),
          ),

          VerticalDivider(width: 1, color: tokens.onSurface.withOpacity(0.1)),

          // Content area
          Expanded(
            child: _buildContent(tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AisTokens tokens) {
    if (_selectedItemId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.navigation_rounded,
              size: 64,
              color: tokens.onSurfaceSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AisTheme.spacingMd),
            Text(
              'Select an item from the navigation',
              style: TextStyle(
                color: tokens.onSurfaceSecondary,
              ),
            ),
            const SizedBox(height: AisTheme.spacingXl),
            _buildFeatureHighlights(tokens),
          ],
        ),
      );
    }

    // Find selected item
    AisNavItem? selectedItem;
    for (final category in _categories) {
      for (final item in category.items) {
        if (item.id == _selectedItemId) {
          selectedItem = item;
          break;
        }
        if (item.children != null) {
          for (final child in item.children!) {
            if (child.id == _selectedItemId) {
              selectedItem = child;
              break;
            }
          }
        }
      }
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedItem?.icon ?? Icons.help_outline,
            size: 48,
            color: tokens.actionPrimary.color,
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Text(
            selectedItem?.label ?? 'Unknown',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Text(
            'Route: ${selectedItem?.route ?? "none"}',
            style: TextStyle(
              color: tokens.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlights(AisTokens tokens) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AIS Navigation Features (§1.5)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingMd),
          _FeatureItem(
            icon: Icons.search,
            title: 'Command Palette',
            description: 'Quick access with fuzzy search (Cmd+K)',
          ),
          _FeatureItem(
            icon: Icons.category,
            title: 'Task-Oriented Grouping',
            description: 'Organized by what you want to do, not entities',
          ),
          _FeatureItem(
            icon: Icons.expand_more,
            title: 'Non-Accordion Collapse',
            description: 'Categories fold independently',
          ),
          _FeatureItem(
            icon: Icons.upgrade,
            title: 'Unavailable vs Unauthorized',
            description: 'Clear distinction with upgrade paths',
          ),
          _FeatureItem(
            icon: Icons.security,
            title: 'Server-Side Filtering',
            description: 'Forbidden items never reach the client',
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: AisTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: tokens.actionPrimary.color,
          ),
          const SizedBox(width: AisTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

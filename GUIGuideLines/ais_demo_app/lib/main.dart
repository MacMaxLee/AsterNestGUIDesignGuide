import 'package:flutter/material.dart';
import 'theme/ais_theme.dart';
import 'theme/ais_tokens.dart';
import 'screens/token_demo_screen.dart';
import 'screens/list_detail_demo_screen.dart';
import 'screens/header_detail_demo_screen.dart';
import 'screens/report_demo_screen.dart';
import 'screens/error_demo_screen.dart';
import 'screens/navigation_demo_screen.dart';
import 'screens/validation_demo_screen.dart';
import 'screens/value_component_demo_screen.dart';
import 'screens/data_grid_demo_screen.dart';

void main() {
  runApp(const AisDemoApp());
}

class AisDemoApp extends StatefulWidget {
  const AisDemoApp({super.key});

  @override
  State<AisDemoApp> createState() => _AisDemoAppState();
}

class _AisDemoAppState extends State<AisDemoApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIS Demo App',
      debugShowCheckedModeBanner: false,
      theme: AisTheme.light,
      darkTheme: AisTheme.dark,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AisDemoHome(
        isDarkMode: _isDarkMode,
        onThemeToggle: () => setState(() => _isDarkMode = !_isDarkMode),
      ),
    );
  }
}

class AisDemoHome extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const AisDemoHome({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIS v1.0 Demo'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: onThemeToggle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingLg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.actionPrimary.color,
                    tokens.actionPrimary.color.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AisTheme.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asternest Interface Standard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  Text(
                    'Version 1.0 - Flutter Implementation Demo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingMd),
                  Wrap(
                    spacing: AisTheme.spacingSm,
                    runSpacing: AisTheme.spacingSm,
                    children: [
                      _InfoChip(
                        icon: Icons.palette_rounded,
                        label: '9 Core Tokens',
                      ),
                      _InfoChip(
                        icon: Icons.grid_view_rounded,
                        label: '4 Shell Patterns',
                      ),
                      _InfoChip(
                        icon: Icons.check_circle_rounded,
                        label: '30 Conformance Tests',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),

            // Demo Categories
            Text(
              'Explore AIS Components',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.onSurface,
              ),
            ),
            const SizedBox(height: AisTheme.spacingMd),

            // Core Components
            _DemoCategory(
              title: 'Core Components',
              subtitle: 'AIS §2 - Semantic tokens and theming',
              items: [
                _DemoItem(
                  title: 'Token System',
                  description: '9 core semantic tokens with icon pairing',
                  icon: Icons.color_lens_rounded,
                  color: tokens.actionPrimary.color,
                  onTap: () => _navigate(context, const TokenDemoScreen()),
                ),
                _DemoItem(
                  title: 'Value Components',
                  description: 'Monetary and metric values with annotations',
                  icon: Icons.attach_money_rounded,
                  color: tokens.actionConfirm.color,
                  onTap: () => _navigate(context, const ValueComponentDemoScreen()),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingLg),

            // Structural Patterns
            _DemoCategory(
              title: 'Structural Patterns',
              subtitle: 'AIS §1 - Screen shells and layouts',
              items: [
                _DemoItem(
                  title: 'List-Detail Shell',
                  description: 'Primary CRUD pattern with state retention',
                  icon: Icons.view_sidebar_rounded,
                  color: tokens.stateInfo.color,
                  onTap: () => _navigate(context, const ListDetailDemoScreen()),
                ),
                _DemoItem(
                  title: 'Header-Detail Shell',
                  description: 'Invariant-bearing screens (debits = credits)',
                  icon: Icons.view_list_rounded,
                  color: tokens.actionCaution.color,
                  onTap: () => _navigate(context, const HeaderDetailDemoScreen()),
                ),
                _DemoItem(
                  title: 'Report Shell',
                  description: 'Drill-through, annotations, footings',
                  icon: Icons.analytics_rounded,
                  color: tokens.stateWarning.color,
                  onTap: () => _navigate(context, const ReportDemoScreen()),
                ),
                _DemoItem(
                  title: 'Navigation',
                  description: 'Task-oriented nav with command palette',
                  icon: Icons.menu_rounded,
                  color: tokens.actionNeutral.color,
                  onTap: () => _navigate(context, const NavigationDemoScreen()),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingLg),

            // Infrastructure
            _DemoCategory(
              title: 'Infrastructure',
              subtitle: 'AIS §4-5 - Errors, validation, diagnostics',
              items: [
                _DemoItem(
                  title: 'Error Handling',
                  description: 'Envelope, redaction, copyable diagnostics',
                  icon: Icons.error_rounded,
                  color: tokens.stateError.color,
                  onTap: () => _navigate(context, const ErrorDemoScreen()),
                ),
                _DemoItem(
                  title: 'Validation',
                  description: 'Platform-free validators, country-aware',
                  icon: Icons.rule_rounded,
                  color: tokens.actionConfirm.color,
                  onTap: () => _navigate(context, const ValidationDemoScreen()),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingLg),

            // Data & Media
            _DemoCategory(
              title: 'Data & Media',
              subtitle: 'AIS §3 - Data grids, layouts, file handling',
              items: [
                _DemoItem(
                  title: 'Data Grid & Media',
                  description: 'Excel-like grid, media picker, file info',
                  icon: Icons.grid_on_rounded,
                  color: tokens.stateInfo.color,
                  onTap: () => _navigate(context, const DataGridDemoScreen()),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),

            // Conformance Info
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: tokens.actionConfirm.color,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      Text(
                        'Conformance Suite',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tokens.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  Text(
                    'AIS v1.0 defines 30 conformance tests (C-01 to C-30). '
                    'This demo implements the UI patterns - a production app '
                    'would run the full test suite.',
                    style: TextStyle(
                      fontSize: 13,
                      color: tokens.onSurfaceSecondary,
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingMd),
                  Wrap(
                    spacing: AisTheme.spacingXs,
                    runSpacing: AisTheme.spacingXs,
                    children: [
                      _ConformanceChip('C-01 Contrast'),
                      _ConformanceChip('C-05 List State'),
                      _ConformanceChip('C-08 Invariant'),
                      _ConformanceChip('C-15 Redaction'),
                      _ConformanceChip('C-19 Money'),
                      _ConformanceChip('C-27 Menu Filter'),
                    ],
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

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AisTheme.spacingSm,
        vertical: AisTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: AisTheme.spacingXs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCategory extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_DemoItem> items;

  const _DemoCategory({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: tokens.onSurface,
          ),
        ),
        const SizedBox(height: AisTheme.spacingXs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: tokens.onSurfaceSecondary,
          ),
        ),
        const SizedBox(height: AisTheme.spacingMd),
        Wrap(
          spacing: AisTheme.spacingMd,
          runSpacing: AisTheme.spacingMd,
          children: items,
        ),
      ],
    );
  }
}

class _DemoItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DemoItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AisTheme.radiusMd),
      child: Container(
        width: 280,
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AisTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: tokens.onSurfaceSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConformanceChip extends StatelessWidget {
  final String label;

  const _ConformanceChip(this.label);

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AisTheme.spacingSm,
        vertical: AisTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
        border: Border.all(
          color: tokens.onSurface.withOpacity(0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          color: tokens.onSurfaceSecondary,
        ),
      ),
    );
  }
}

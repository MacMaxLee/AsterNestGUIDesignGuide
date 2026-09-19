import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_button.dart';
import '../widgets/ais_state_badge.dart';

/// Demo screen for AIS Token System (§2)
class TokenDemoScreen extends StatelessWidget {
  const TokenDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIS Token System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Toggle Theme',
            onPressed: () {
              // Theme toggle would be handled by app state
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Core Token Set
            _SectionHeader(
              title: 'Core Token Set',
              subtitle: 'AIS §2.2 - Nine semantic tokens',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            // Action Tokens
            _SubsectionHeader(title: 'Action Tokens'),
            const SizedBox(height: AisTheme.spacingSm),
            Wrap(
              spacing: AisTheme.spacingSm,
              runSpacing: AisTheme.spacingSm,
              children: [
                _TokenDemo(
                  token: tokens.actionPrimary,
                  name: 'action.primary',
                  description: 'Main forward action',
                ),
                _TokenDemo(
                  token: tokens.actionConfirm,
                  name: 'action.confirm',
                  description: 'Approval, acceptance',
                ),
                _TokenDemo(
                  token: tokens.actionDestructive,
                  name: 'action.destructive',
                  description: 'Irreversible, data-removing',
                ),
                _TokenDemo(
                  token: tokens.actionCaution,
                  name: 'action.caution',
                  description: 'Externally visible actions',
                ),
                _TokenDemo(
                  token: tokens.actionNeutral,
                  name: 'action.neutral',
                  description: 'Cancel, close, back',
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingLg),

            // State Tokens
            _SubsectionHeader(title: 'State Tokens'),
            const SizedBox(height: AisTheme.spacingSm),
            Wrap(
              spacing: AisTheme.spacingSm,
              runSpacing: AisTheme.spacingSm,
              children: [
                _TokenDemo(
                  token: tokens.stateInfo,
                  name: 'state.info',
                  description: 'Informational',
                ),
                _TokenDemo(
                  token: tokens.stateWarning,
                  name: 'state.warning',
                  description: 'Needs attention',
                ),
                _TokenDemo(
                  token: tokens.stateError,
                  name: 'state.error',
                  description: 'Failed or invalid',
                ),
                _TokenDemo(
                  token: tokens.stateUnavailable,
                  name: 'state.unavailable',
                  description: 'Cannot be computed',
                  isSpecial: true,
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Buttons with Icon Pairing
            _SectionHeader(
              title: 'Button Components',
              subtitle: 'AIS §2.3 - Every token pairs with required icon',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            // Primary buttons
            Wrap(
              spacing: AisTheme.spacingMd,
              runSpacing: AisTheme.spacingMd,
              children: const [
                AisButton(
                  label: 'Continue',
                  type: AisButtonType.primary,
                  onPressed: null,
                ),
                AisButton(
                  label: 'Approve',
                  type: AisButtonType.confirm,
                  onPressed: null,
                ),
                AisButton(
                  label: 'Delete',
                  type: AisButtonType.destructive,
                  onPressed: null,
                ),
                AisButton(
                  label: 'Publish',
                  type: AisButtonType.caution,
                  onPressed: null,
                ),
                AisButton(
                  label: 'Cancel',
                  type: AisButtonType.neutral,
                  onPressed: null,
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingMd),

            // Outlined buttons
            Wrap(
              spacing: AisTheme.spacingMd,
              runSpacing: AisTheme.spacingMd,
              children: const [
                AisOutlinedButton(
                  label: 'Continue',
                  type: AisButtonType.primary,
                ),
                AisOutlinedButton(
                  label: 'Approve',
                  type: AisButtonType.confirm,
                ),
                AisOutlinedButton(
                  label: 'Delete',
                  type: AisButtonType.destructive,
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: State Badges
            _SectionHeader(
              title: 'State Badges',
              subtitle: 'Color is never the sole signal',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Wrap(
              spacing: AisTheme.spacingSm,
              runSpacing: AisTheme.spacingSm,
              children: const [
                AisStateBadge(label: 'Information', type: AisStateType.info),
                AisStateBadge(label: 'Warning', type: AisStateType.warning),
                AisStateBadge(label: 'Error', type: AisStateType.error),
                AisStateBadge(
                  label: 'Not Available',
                  type: AisStateType.unavailable,
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingMd),

            // Compact badges
            Text(
              'Compact variant:',
              style: TextStyle(
                fontSize: 12,
                color: tokens.onSurfaceSecondary,
              ),
            ),
            const SizedBox(height: AisTheme.spacingSm),
            Wrap(
              spacing: AisTheme.spacingSm,
              runSpacing: AisTheme.spacingSm,
              children: const [
                AisStateBadge(
                  label: 'Info',
                  type: AisStateType.info,
                  compact: true,
                ),
                AisStateBadge(
                  label: 'Warn',
                  type: AisStateType.warning,
                  compact: true,
                ),
                AisStateBadge(
                  label: 'Error',
                  type: AisStateType.error,
                  compact: true,
                ),
                AisStateBadge(
                  label: 'N/A',
                  type: AisStateType.unavailable,
                  compact: true,
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Zero vs Unavailable
            _SectionHeader(
              title: 'Zero vs Unavailable',
              subtitle: 'AIS §2.3 - Must be distinguishable by MORE than color',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AisTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                      border: Border.all(
                        color: tokens.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Zero Value',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.onSurfaceSecondary,
                          ),
                        ),
                        const SizedBox(height: AisTheme.spacingSm),
                        Text(
                          '\$0.00',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: tokens.onSurface,
                          ),
                        ),
                        const SizedBox(height: AisTheme.spacingXs),
                        Text(
                          'A known value of zero',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AisTheme.spacingMd),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AisTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                      border: Border.all(
                        color: tokens.stateUnavailable.color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.stateUnavailable.color,
                          ),
                        ),
                        const SizedBox(height: AisTheme.spacingSm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tokens.stateUnavailable.icon,
                              color: tokens.stateUnavailable.color,
                            ),
                            const SizedBox(width: AisTheme.spacingXs),
                            Text(
                              '—',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: tokens.stateUnavailable.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AisTheme.spacingXs),
                        Text(
                          'Cannot be computed',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: tokens.stateUnavailable.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),
          ],
        ),
      ),
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

class _SubsectionHeader extends StatelessWidget {
  final String title;

  const _SubsectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TokenDemo extends StatelessWidget {
  final AisSemanticToken token;
  final String name;
  final String description;
  final bool isSpecial;

  const _TokenDemo({
    required this.token,
    required this.name,
    required this.description,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
        border: Border.all(
          color: isSpecial
              ? token.color.withOpacity(0.5)
              : tokens.onSurface.withOpacity(0.1),
          width: isSpecial ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: token.color,
                  borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                ),
                child: Icon(
                  token.icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AisTheme.spacingSm),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tokens.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: tokens.onSurfaceSecondary,
            ),
          ),
          if (isSpecial) ...[
            const SizedBox(height: AisTheme.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AisTheme.spacingXs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: token.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: token.color,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      'Non-color distinction',
                      style: TextStyle(
                        fontSize: 9,
                        color: token.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

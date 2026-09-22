// =============================================================================
// ai_settings_screen.dart
// AI Provider Settings Configuration Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_settings.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/widgets.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AISettingsService _settingsService = AISettingsService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _settingsService.loadSettings();
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    final success = await _settingsService.saveSettings();

    setState(() {
      _isSaving = false;
      _hasChanges = false;
      _statusMessage = success ? 'Settings saved successfully' : 'Failed to save settings';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _statusMessage = null);
    });
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        title: const Text('AI Provider Settings'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: () => _showResetDialog(tokens),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.cloud), text: 'Cloud AI'),
            Tab(icon: Icon(Icons.computer), text: 'Local AI'),
            Tab(icon: Icon(Icons.phone_android), text: 'On-Device'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status message
                if (_statusMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AisTheme.spacingSm),
                    color: _statusMessage!.contains('success')
                        ? tokens.actionConfirm.color.withOpacity(0.1)
                        : tokens.stateError.color.withOpacity(0.1),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage!.contains('success')
                            ? tokens.actionConfirm.color
                            : tokens.stateError.color,
                      ),
                    ),
                  ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCloudProvidersTab(tokens),
                      _buildLocalProvidersTab(tokens),
                      _buildOnDeviceTab(tokens),
                    ],
                  ),
                ),

                // Footer with file info
                _buildFooter(tokens),
              ],
            ),
    );
  }

  // MARK: - Cloud Providers Tab

  Widget _buildCloudProvidersTab(AisTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AisTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            tokens,
            title: 'Cloud LLM Providers',
            subtitle: 'Configure API keys for cloud-based AI services',
            icon: Icons.cloud,
          ),
          const SizedBox(height: AisTheme.spacingMd),

          // Provider cards
          ...CloudLLMProvider.values.map((provider) {
            final config = _settingsService.settings.cloudProviders
                .firstWhere((p) => p.provider == provider);
            return _buildCloudProviderCard(provider, config, tokens);
          }),

          const SizedBox(height: AisTheme.spacingXl),

          // Preferred tier selector
          _buildPreferredTierSelector(tokens),
        ],
      ),
    );
  }

  Widget _buildCloudProviderCard(
    CloudLLMProvider provider,
    CloudLLMConfig config,
    AisTokens tokens,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AisTheme.spacingMd),
      child: ExpansionTile(
        leading: _getProviderIcon(provider, tokens),
        title: Text(provider.displayName),
        subtitle: Text(
          config.isEnabled && config.apiKey.isNotEmpty
              ? 'Configured'
              : 'Not configured',
          style: TextStyle(
            color: config.isEnabled && config.apiKey.isNotEmpty
                ? tokens.actionConfirm.color
                : tokens.onSurfaceSecondary,
          ),
        ),
        trailing: Switch(
          value: config.isEnabled,
          onChanged: (value) {
            setState(() {
              config.isEnabled = value;
              _markChanged();
            });
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // API Key
                _buildTextField(
                  tokens,
                  label: 'API Key',
                  value: config.apiKey,
                  obscureText: true,
                  onChanged: (value) {
                    config.apiKey = value;
                    _markChanged();
                  },
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, size: 18),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        setState(() {
                          config.apiKey = data!.text!;
                          _markChanged();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: AisTheme.spacingMd),

                // Model
                _buildTextField(
                  tokens,
                  label: 'Model',
                  value: config.model,
                  onChanged: (value) {
                    config.model = value;
                    _markChanged();
                  },
                ),
                const SizedBox(height: AisTheme.spacingMd),

                // Endpoint (collapsible)
                ExpansionTile(
                  title: const Text('Advanced Settings'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    _buildTextField(
                      tokens,
                      label: 'API Endpoint',
                      value: config.endpoint,
                      onChanged: (value) {
                        config.endpoint = value;
                        _markChanged();
                      },
                    ),
                    const SizedBox(height: AisTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            tokens,
                            label: 'Max Tokens',
                            value: config.maxTokens.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              config.maxTokens = int.tryParse(value) ?? 4096;
                              _markChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: AisTheme.spacingMd),
                        Expanded(
                          child: _buildTextField(
                            tokens,
                            label: 'Temperature',
                            value: config.temperature.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              config.temperature = double.tryParse(value) ?? 0.3;
                              _markChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AisTheme.spacingMd),

                // Test button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AisButton(
                      label: 'Test Connection',
                      type: AisButtonType.neutral,
                      onPressed: () => _testCloudConnection(config, tokens),
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

  Widget _getProviderIcon(CloudLLMProvider provider, AisTokens tokens) {
    IconData icon;
    Color color;

    switch (provider) {
      case CloudLLMProvider.claude:
        icon = Icons.auto_awesome;
        color = const Color(0xFFD97706); // Amber
      case CloudLLMProvider.chatgpt:
        icon = Icons.chat;
        color = const Color(0xFF10B981); // Green
      case CloudLLMProvider.gemini:
        icon = Icons.diamond;
        color = const Color(0xFF3B82F6); // Blue
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // MARK: - Local Providers Tab

  Widget _buildLocalProvidersTab(AisTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AisTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            tokens,
            title: 'Local AI Providers',
            subtitle: 'Configure locally-hosted AI models (Ollama, LM Studio)',
            icon: Icons.computer,
          ),
          const SizedBox(height: AisTheme.spacingMd),

          // Info card
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            decoration: BoxDecoration(
              color: tokens.stateInfo.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: tokens.stateInfo.color),
                const SizedBox(width: AisTheme.spacingMd),
                Expanded(
                  child: Text(
                    'Local AI runs on your machine for privacy and offline use. '
                    'Ensure your local AI server is running before testing.',
                    style: TextStyle(
                      fontSize: 13,
                      color: tokens.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AisTheme.spacingLg),

          // Provider cards
          ...LocalAIProvider.values.map((provider) {
            final config = _settingsService.settings.localProviders
                .firstWhere((p) => p.provider == provider);
            return _buildLocalProviderCard(provider, config, tokens);
          }),
        ],
      ),
    );
  }

  Widget _buildLocalProviderCard(
    LocalAIProvider provider,
    LocalAIConfig config,
    AisTokens tokens,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AisTheme.spacingMd),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tokens.actionPrimary.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            provider == LocalAIProvider.ollama
                ? Icons.memory
                : provider == LocalAIProvider.lmStudio
                    ? Icons.laptop
                    : Icons.settings,
            color: tokens.actionPrimary.color,
            size: 20,
          ),
        ),
        title: Text(provider.displayName),
        subtitle: Text(
          config.isEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            color: config.isEnabled
                ? tokens.actionConfirm.color
                : tokens.onSurfaceSecondary,
          ),
        ),
        trailing: Switch(
          value: config.isEnabled,
          onChanged: (value) {
            setState(() {
              config.isEnabled = value;
              _markChanged();
            });
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Endpoint
                _buildTextField(
                  tokens,
                  label: 'API Endpoint',
                  value: config.endpoint,
                  onChanged: (value) {
                    config.endpoint = value;
                    _markChanged();
                  },
                ),
                const SizedBox(height: AisTheme.spacingMd),

                // Model
                _buildTextField(
                  tokens,
                  label: 'Model Name',
                  value: config.model,
                  onChanged: (value) {
                    config.model = value;
                    _markChanged();
                  },
                ),
                const SizedBox(height: AisTheme.spacingMd),

                // Advanced settings
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        tokens,
                        label: 'Max Tokens',
                        value: config.maxTokens.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          config.maxTokens = int.tryParse(value) ?? 4096;
                          _markChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: AisTheme.spacingMd),
                    Expanded(
                      child: _buildTextField(
                        tokens,
                        label: 'Context Length',
                        value: config.contextLength.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          config.contextLength = int.tryParse(value) ?? 8192;
                          _markChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AisTheme.spacingMd),

                // Test button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AisButton(
                      label: 'Test Connection',
                      type: AisButtonType.neutral,
                      onPressed: () => _testLocalConnection(config, tokens),
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

  // MARK: - On-Device Tab

  Widget _buildOnDeviceTab(AisTokens tokens) {
    final config = _settingsService.settings.onDeviceConfig;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AisTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            tokens,
            title: 'On-Device AI',
            subtitle: 'Configure built-in OCR and vision capabilities',
            icon: Icons.phone_android,
          ),
          const SizedBox(height: AisTheme.spacingMd),

          // Google ML Kit
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Color(0xFF4285F4),
                  size: 20,
                ),
              ),
              title: const Text('Google ML Kit'),
              subtitle: const Text('On-device text recognition (Android/iOS)'),
              value: config.useGoogleMLKit,
              onChanged: (value) {
                setState(() {
                  config.useGoogleMLKit = value;
                  _markChanged();
                });
              },
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),

          // Apple Vision
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.apple,
                  color: Color(0xFF000000),
                  size: 20,
                ),
              ),
              title: const Text('Apple Vision'),
              subtitle: const Text('On-device text recognition (macOS/iOS)'),
              value: config.useAppleVision,
              onChanged: (value) {
                setState(() {
                  config.useAppleVision = value;
                  _markChanged();
                });
              },
            ),
          ),
          const SizedBox(height: AisTheme.spacingLg),

          // Language setting
          _buildSectionHeader(
            tokens,
            title: 'Language',
            subtitle: 'Preferred language for OCR recognition',
            icon: Icons.language,
          ),
          const SizedBox(height: AisTheme.spacingMd),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              child: DropdownButtonFormField<String>(
                value: config.preferredLanguage,
                decoration: const InputDecoration(
                  labelText: 'Recognition Language',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'zh', child: Text('Chinese')),
                  DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                  DropdownMenuItem(value: 'ko', child: Text('Korean')),
                  DropdownMenuItem(value: 'es', child: Text('Spanish')),
                  DropdownMenuItem(value: 'fr', child: Text('French')),
                  DropdownMenuItem(value: 'de', child: Text('German')),
                ],
                onChanged: (value) {
                  setState(() {
                    config.preferredLanguage = value ?? 'en';
                    _markChanged();
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: AisTheme.spacingXl),

          // Fallback settings
          _buildSectionHeader(
            tokens,
            title: 'Fallback Behavior',
            subtitle: 'How to handle extraction failures',
            icon: Icons.sync_alt,
          ),
          const SizedBox(height: AisTheme.spacingMd),

          Card(
            child: SwitchListTile(
              title: const Text('Enable Automatic Fallback'),
              subtitle: const Text(
                'Automatically try next provider if current one fails',
              ),
              value: _settingsService.settings.enableFallback,
              onChanged: (value) {
                setState(() {
                  _settingsService.settings.enableFallback = value;
                  _markChanged();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Preferred Tier Selector

  Widget _buildPreferredTierSelector(AisTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          tokens,
          title: 'Preferred Processing Tier',
          subtitle: 'Choose which AI tier to use first',
          icon: Icons.sort,
        ),
        const SizedBox(height: AisTheme.spacingMd),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            child: Column(
              children: [
                _buildTierRadio(
                  tokens,
                  value: 'onDevice',
                  title: 'On-Device First',
                  subtitle: 'Fastest, works offline (Google ML Kit / Apple Vision)',
                  icon: Icons.phone_android,
                ),
                _buildTierRadio(
                  tokens,
                  value: 'local',
                  title: 'Local AI First',
                  subtitle: 'Private, runs on your machine (Ollama / LM Studio)',
                  icon: Icons.computer,
                ),
                _buildTierRadio(
                  tokens,
                  value: 'cloud',
                  title: 'Cloud AI First',
                  subtitle: 'Most accurate, requires internet (Claude / ChatGPT)',
                  icon: Icons.cloud,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierRadio(
    AisTokens tokens, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: _settingsService.settings.preferredTier,
      onChanged: (v) {
        setState(() {
          _settingsService.settings.preferredTier = v ?? 'onDevice';
          _markChanged();
        });
      },
      secondary: Icon(icon, color: tokens.actionPrimary.color),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }

  // MARK: - Helper Widgets

  Widget _buildSectionHeader(
    AisTokens tokens, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: tokens.actionPrimary.color),
        const SizedBox(width: AisTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: tokens.onSurfaceSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    AisTokens tokens, {
    required String label,
    required String value,
    required Function(String) onChanged,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      initialValue: value,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildFooter(AisTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surfaceSecondary,
        border: Border(
          top: BorderSide(color: tokens.onSurface.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 16, color: tokens.onSurfaceSecondary),
          const SizedBox(width: AisTheme.spacingSm),
          Expanded(
            child: FutureBuilder<String>(
              future: _settingsService.getSettingsFilePath(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: tokens.onSurfaceSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          TextButton.icon(
            onPressed: () => _showExportImportDialog(tokens),
            icon: const Icon(Icons.import_export, size: 16),
            label: const Text('Export/Import'),
          ),
        ],
      ),
    );
  }

  // MARK: - Actions

  Future<void> _testCloudConnection(CloudLLMConfig config, AisTokens tokens) async {
    final result = await _settingsService.testCloudConnection(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result
                ? 'API key format looks valid'
                : 'API key format may be invalid',
          ),
          backgroundColor: result
              ? tokens.actionConfirm.color
              : tokens.stateWarning.color,
        ),
      );
    }
  }

  Future<void> _testLocalConnection(LocalAIConfig config, AisTokens tokens) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing connection...')),
    );

    final result = await _settingsService.testLocalConnection(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result
                ? 'Connection successful!'
                : 'Connection failed. Is the server running?',
          ),
          backgroundColor: result
              ? tokens.actionConfirm.color
              : tokens.stateError.color,
        ),
      );
    }
  }

  void _showResetDialog(AisTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will clear all API keys and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _settingsService.resetToDefaults();
              setState(() {
                _hasChanges = false;
                _statusMessage = 'Settings reset to defaults';
              });
            },
            style: TextButton.styleFrom(foregroundColor: tokens.stateError.color),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showExportImportDialog(AisTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export/Import Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Export Settings'),
              subtitle: const Text('Save settings to a file'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement file picker for export
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Export not yet implemented')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import Settings'),
              subtitle: const Text('Load settings from a file'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement file picker for import
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Import not yet implemented')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

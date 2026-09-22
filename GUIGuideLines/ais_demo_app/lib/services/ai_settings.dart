// =============================================================================
// ai_settings.dart
// AI Provider Settings and Configuration
// =============================================================================
//
// PURPOSE:
// Manages AI provider configuration including API keys, endpoints, and
// local AI model settings. Persists settings to a JSON file.
//
// SUPPORTED PROVIDERS:
// - Cloud LLMs: Claude (Anthropic), ChatGPT (OpenAI), Gemini (Google)
// - Local AI: Ollama, LM Studio, Custom endpoints
// - On-Device: Google ML Kit, Apple Vision (no config needed)
//
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// MARK: - AI Provider Types

/// Cloud LLM provider types
enum CloudLLMProvider {
  claude('Claude (Anthropic)', 'https://api.anthropic.com/v1/messages'),
  chatgpt('ChatGPT (OpenAI)', 'https://api.openai.com/v1/chat/completions'),
  gemini('Gemini (Google)', 'https://generativelanguage.googleapis.com/v1beta/models');

  final String displayName;
  final String defaultEndpoint;

  const CloudLLMProvider(this.displayName, this.defaultEndpoint);
}

/// Local AI provider types
enum LocalAIProvider {
  ollama('Ollama', 'http://localhost:11434/api/generate'),
  lmStudio('LM Studio', 'http://localhost:1234/v1/chat/completions'),
  custom('Custom Endpoint', '');

  final String displayName;
  final String defaultEndpoint;

  const LocalAIProvider(this.displayName, this.defaultEndpoint);
}

// MARK: - Settings Models

/// Configuration for a cloud LLM provider
class CloudLLMConfig {
  final CloudLLMProvider provider;
  String apiKey;
  String endpoint;
  String model;
  bool isEnabled;
  int maxTokens;
  double temperature;

  CloudLLMConfig({
    required this.provider,
    this.apiKey = '',
    String? endpoint,
    String? model,
    this.isEnabled = false,
    this.maxTokens = 4096,
    this.temperature = 0.3,
  })  : endpoint = endpoint ?? provider.defaultEndpoint,
        model = model ?? _defaultModel(provider);

  static String _defaultModel(CloudLLMProvider provider) {
    switch (provider) {
      case CloudLLMProvider.claude:
        return 'claude-3-5-sonnet-20241022';
      case CloudLLMProvider.chatgpt:
        return 'gpt-4o';
      case CloudLLMProvider.gemini:
        return 'gemini-1.5-pro';
    }
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'endpoint': endpoint,
        'model': model,
        'isEnabled': isEnabled,
        'maxTokens': maxTokens,
        'temperature': temperature,
      };

  factory CloudLLMConfig.fromJson(Map<String, dynamic> json) {
    final provider = CloudLLMProvider.values.firstWhere(
      (p) => p.name == json['provider'],
      orElse: () => CloudLLMProvider.claude,
    );
    return CloudLLMConfig(
      provider: provider,
      apiKey: json['apiKey'] ?? '',
      endpoint: json['endpoint'],
      model: json['model'],
      isEnabled: json['isEnabled'] ?? false,
      maxTokens: json['maxTokens'] ?? 4096,
      temperature: (json['temperature'] ?? 0.3).toDouble(),
    );
  }
}

/// Configuration for a local AI provider
class LocalAIConfig {
  final LocalAIProvider provider;
  String endpoint;
  String model;
  bool isEnabled;
  int maxTokens;
  double temperature;
  int contextLength;

  LocalAIConfig({
    required this.provider,
    String? endpoint,
    this.model = 'llama3.2',
    this.isEnabled = false,
    this.maxTokens = 4096,
    this.temperature = 0.3,
    this.contextLength = 8192,
  }) : endpoint = endpoint ?? provider.defaultEndpoint;

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'endpoint': endpoint,
        'model': model,
        'isEnabled': isEnabled,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'contextLength': contextLength,
      };

  factory LocalAIConfig.fromJson(Map<String, dynamic> json) {
    final provider = LocalAIProvider.values.firstWhere(
      (p) => p.name == json['provider'],
      orElse: () => LocalAIProvider.ollama,
    );
    return LocalAIConfig(
      provider: provider,
      endpoint: json['endpoint'],
      model: json['model'] ?? 'llama3.2',
      isEnabled: json['isEnabled'] ?? false,
      maxTokens: json['maxTokens'] ?? 4096,
      temperature: (json['temperature'] ?? 0.3).toDouble(),
      contextLength: json['contextLength'] ?? 8192,
    );
  }
}

/// On-device AI configuration
class OnDeviceAIConfig {
  bool useGoogleMLKit;
  bool useAppleVision;
  String preferredLanguage;

  OnDeviceAIConfig({
    this.useGoogleMLKit = true,
    this.useAppleVision = true,
    this.preferredLanguage = 'en',
  });

  Map<String, dynamic> toJson() => {
        'useGoogleMLKit': useGoogleMLKit,
        'useAppleVision': useAppleVision,
        'preferredLanguage': preferredLanguage,
      };

  factory OnDeviceAIConfig.fromJson(Map<String, dynamic> json) {
    return OnDeviceAIConfig(
      useGoogleMLKit: json['useGoogleMLKit'] ?? true,
      useAppleVision: json['useAppleVision'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
    );
  }
}

/// Complete AI settings
class AISettings {
  List<CloudLLMConfig> cloudProviders;
  List<LocalAIConfig> localProviders;
  OnDeviceAIConfig onDeviceConfig;
  String preferredTier; // 'onDevice', 'local', 'cloud'
  bool enableFallback;
  DateTime lastUpdated;

  AISettings({
    List<CloudLLMConfig>? cloudProviders,
    List<LocalAIConfig>? localProviders,
    OnDeviceAIConfig? onDeviceConfig,
    this.preferredTier = 'onDevice',
    this.enableFallback = true,
    DateTime? lastUpdated,
  })  : cloudProviders = cloudProviders ?? _defaultCloudProviders(),
        localProviders = localProviders ?? _defaultLocalProviders(),
        onDeviceConfig = onDeviceConfig ?? OnDeviceAIConfig(),
        lastUpdated = lastUpdated ?? DateTime.now();

  static List<CloudLLMConfig> _defaultCloudProviders() {
    return CloudLLMProvider.values
        .map((p) => CloudLLMConfig(provider: p))
        .toList();
  }

  static List<LocalAIConfig> _defaultLocalProviders() {
    return LocalAIProvider.values
        .map((p) => LocalAIConfig(provider: p))
        .toList();
  }

  /// Get the first enabled cloud provider
  CloudLLMConfig? get activeCloudProvider {
    try {
      return cloudProviders.firstWhere((p) => p.isEnabled && p.apiKey.isNotEmpty);
    } catch (_) {
      return null;
    }
  }

  /// Get the first enabled local provider
  LocalAIConfig? get activeLocalProvider {
    try {
      return localProviders.firstWhere((p) => p.isEnabled);
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // BACKWARD COMPATIBILITY GETTERS
  // These getters provide backward compatibility with the old flat API
  // ==========================================================================

  /// Get Claude API key
  String get claudeApiKey {
    try {
      return cloudProviders
          .firstWhere((p) => p.provider == CloudLLMProvider.claude)
          .apiKey;
    } catch (_) {
      return '';
    }
  }

  /// Get ChatGPT API key
  String get chatgptApiKey {
    try {
      return cloudProviders
          .firstWhere((p) => p.provider == CloudLLMProvider.chatgpt)
          .apiKey;
    } catch (_) {
      return '';
    }
  }

  /// Get Gemini API key
  String get geminiApiKey {
    try {
      return cloudProviders
          .firstWhere((p) => p.provider == CloudLLMProvider.gemini)
          .apiKey;
    } catch (_) {
      return '';
    }
  }

  /// Check if Ollama is enabled
  bool get useOllama {
    try {
      return localProviders
          .firstWhere((p) => p.provider == LocalAIProvider.ollama)
          .isEnabled;
    } catch (_) {
      return false;
    }
  }

  /// Get Ollama host
  String get ollamaHost {
    try {
      return localProviders
          .firstWhere((p) => p.provider == LocalAIProvider.ollama)
          .endpoint;
    } catch (_) {
      return '';
    }
  }

  /// Check if LM Studio is enabled
  bool get useLMStudio {
    try {
      return localProviders
          .firstWhere((p) => p.provider == LocalAIProvider.lmStudio)
          .isEnabled;
    } catch (_) {
      return false;
    }
  }

  /// Get LM Studio host
  String get lmStudioHost {
    try {
      return localProviders
          .firstWhere((p) => p.provider == LocalAIProvider.lmStudio)
          .endpoint;
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> toJson() => {
        'cloudProviders': cloudProviders.map((p) => p.toJson()).toList(),
        'localProviders': localProviders.map((p) => p.toJson()).toList(),
        'onDeviceConfig': onDeviceConfig.toJson(),
        'preferredTier': preferredTier,
        'enableFallback': enableFallback,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory AISettings.fromJson(Map<String, dynamic> json) {
    return AISettings(
      cloudProviders: (json['cloudProviders'] as List?)
          ?.map((p) => CloudLLMConfig.fromJson(p))
          .toList(),
      localProviders: (json['localProviders'] as List?)
          ?.map((p) => LocalAIConfig.fromJson(p))
          .toList(),
      onDeviceConfig: json['onDeviceConfig'] != null
          ? OnDeviceAIConfig.fromJson(json['onDeviceConfig'])
          : null,
      preferredTier: json['preferredTier'] ?? 'onDevice',
      enableFallback: json['enableFallback'] ?? true,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}

// MARK: - Settings Service

/// Service for managing AI settings persistence
class AISettingsService extends ChangeNotifier {
  static const String _settingsFileName = 'ai_settings.json';

  AISettings _settings = AISettings();
  bool _isLoaded = false;
  String? _error;

  AISettings get settings => _settings;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  /// Get the settings file path
  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final aisDir = Directory('${directory.path}/AIS');
    if (!await aisDir.exists()) {
      await aisDir.create(recursive: true);
    }
    return File('${aisDir.path}/$_settingsFileName');
  }

  /// Load settings from JSON file
  Future<void> loadSettings() async {
    try {
      final file = await _getSettingsFile();

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString);
        _settings = AISettings.fromJson(json);
      } else {
        // Create default settings
        _settings = AISettings();
        await saveSettings();
      }

      _isLoaded = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load settings: $e';
      _settings = AISettings();
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save settings to JSON file
  Future<bool> saveSettings() async {
    try {
      final file = await _getSettingsFile();
      _settings.lastUpdated = DateTime.now();

      final jsonString = const JsonEncoder.withIndent('  ').convert(_settings.toJson());
      await file.writeAsString(jsonString);

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save settings: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update cloud provider config
  void updateCloudProvider(CloudLLMProvider provider, CloudLLMConfig config) {
    final index = _settings.cloudProviders.indexWhere((p) => p.provider == provider);
    if (index >= 0) {
      _settings.cloudProviders[index] = config;
      notifyListeners();
    }
  }

  /// Update local provider config
  void updateLocalProvider(LocalAIProvider provider, LocalAIConfig config) {
    final index = _settings.localProviders.indexWhere((p) => p.provider == provider);
    if (index >= 0) {
      _settings.localProviders[index] = config;
      notifyListeners();
    }
  }

  /// Update on-device config
  void updateOnDeviceConfig(OnDeviceAIConfig config) {
    _settings.onDeviceConfig = config;
    notifyListeners();
  }

  /// Update preferred tier
  void setPreferredTier(String tier) {
    _settings.preferredTier = tier;
    notifyListeners();
  }

  /// Toggle fallback
  void setEnableFallback(bool enable) {
    _settings.enableFallback = enable;
    notifyListeners();
  }

  /// Test cloud provider connection
  Future<bool> testCloudConnection(CloudLLMConfig config) async {
    // TODO: Implement actual API test
    // For now, just validate API key format
    if (config.apiKey.isEmpty) return false;

    switch (config.provider) {
      case CloudLLMProvider.claude:
        return config.apiKey.startsWith('sk-ant-');
      case CloudLLMProvider.chatgpt:
        return config.apiKey.startsWith('sk-');
      case CloudLLMProvider.gemini:
        return config.apiKey.length > 20;
    }
  }

  /// Test local provider connection
  Future<bool> testLocalConnection(LocalAIConfig config) async {
    try {
      final uri = Uri.parse(config.endpoint);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(uri);
      final response = await request.close();
      client.close();

      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Get settings file path for display
  Future<String> getSettingsFilePath() async {
    final file = await _getSettingsFile();
    return file.path;
  }

  /// Export settings to a custom location
  Future<bool> exportSettings(String path) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(_settings.toJson());
      await File(path).writeAsString(jsonString);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Import settings from a custom location
  Future<bool> importSettings(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);
      _settings = AISettings.fromJson(json);

      await saveSettings();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _settings = AISettings();
    await saveSettings();
    notifyListeners();
  }
}

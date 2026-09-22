// =============================================================================
// ai_service.dart
// AI Service for Document Processing
// =============================================================================
//
// PURPOSE:
// Provides a unified interface for AI-powered document analysis using
// configured providers. Supports tiered fallback from on-device to local
// to cloud AI providers.
//
// USAGE:
// final service = AIService(settingsService);
// final result = await service.analyzeDocument(text, documentType: 'invoice');
//
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ai_settings.dart';

// MARK: - Request/Response Models

/// Document analysis request
class AIDocumentRequest {
  final String text;
  final String documentType;
  final String? customPrompt;
  final Map<String, dynamic>? context;

  AIDocumentRequest({
    required this.text,
    this.documentType = 'general',
    this.customPrompt,
    this.context,
  });
}

/// Document analysis result
class AIDocumentResult {
  final bool success;
  final String? extractedData;
  final Map<String, dynamic>? structuredData;
  final String? error;
  final String providerUsed;
  final Duration processingTime;
  final int? tokensUsed;

  AIDocumentResult({
    required this.success,
    this.extractedData,
    this.structuredData,
    this.error,
    required this.providerUsed,
    required this.processingTime,
    this.tokensUsed,
  });

  factory AIDocumentResult.error(String message, String provider) {
    return AIDocumentResult(
      success: false,
      error: message,
      providerUsed: provider,
      processingTime: Duration.zero,
    );
  }
}

/// Provider tier enumeration
enum AITier {
  onDevice,
  local,
  cloud,
}

// MARK: - AI Service

/// Service for AI-powered document analysis
class AIService extends ChangeNotifier {
  final AISettingsService _settingsService;
  bool _isProcessing = false;
  String? _lastError;
  AITier? _lastTierUsed;

  AIService(this._settingsService);

  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  AITier? get lastTierUsed => _lastTierUsed;
  AISettings get settings => _settingsService.settings;

  /// Check if any AI provider is configured (cloud or local)
  bool get isConfigured {
    final s = settings;
    // Check cloud providers
    if (s.claudeApiKey.isNotEmpty ||
        s.chatgptApiKey.isNotEmpty ||
        s.geminiApiKey.isNotEmpty) {
      return true;
    }
    // Check local providers
    if ((s.useOllama && s.ollamaHost.isNotEmpty) ||
        (s.useLMStudio && s.lmStudioHost.isNotEmpty)) {
      return true;
    }
    return false;
  }

  /// Analyze document text using configured AI providers
  Future<AIDocumentResult> analyzeDocument(
    AIDocumentRequest request,
  ) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Determine processing order based on preferred tier
      final tiers = _getTierOrder();

      for (final tier in tiers) {
        final result = await _processWithTier(tier, request);

        if (result.success) {
          _lastTierUsed = tier;
          _isProcessing = false;
          notifyListeners();
          return result;
        }

        // If fallback is disabled, stop after first attempt
        if (!settings.enableFallback) {
          break;
        }
      }

      // All tiers failed
      _lastError = 'All AI providers failed to process the document';
      _isProcessing = false;
      notifyListeners();

      return AIDocumentResult.error(
        _lastError!,
        'none',
      );
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();

      return AIDocumentResult.error(
        _lastError!,
        'none',
      );
    }
  }

  /// Get tier processing order based on settings
  List<AITier> _getTierOrder() {
    final preferredTier = settings.preferredTier;

    switch (preferredTier) {
      case 'onDevice':
        return [AITier.onDevice, AITier.local, AITier.cloud];
      case 'local':
        return [AITier.local, AITier.onDevice, AITier.cloud];
      case 'cloud':
        return [AITier.cloud, AITier.local, AITier.onDevice];
      default:
        return [AITier.onDevice, AITier.local, AITier.cloud];
    }
  }

  /// Process with a specific tier
  Future<AIDocumentResult> _processWithTier(
    AITier tier,
    AIDocumentRequest request,
  ) async {
    switch (tier) {
      case AITier.onDevice:
        // On-device processing is handled by DocScan directly
        // Return failure to trigger fallback to other tiers
        return AIDocumentResult.error(
          'On-device AI requires native OCR pipeline',
          'onDevice',
        );

      case AITier.local:
        return _processWithLocalAI(request);

      case AITier.cloud:
        return _processWithCloudAI(request);
    }
  }

  // MARK: - Local AI Processing

  /// Process with local AI (Ollama, LM Studio)
  Future<AIDocumentResult> _processWithLocalAI(
    AIDocumentRequest request,
  ) async {
    final activeProvider = settings.activeLocalProvider;

    if (activeProvider == null) {
      return AIDocumentResult.error(
        'No local AI provider configured',
        'local',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final prompt = _buildPrompt(request);

      switch (activeProvider.provider) {
        case LocalAIProvider.ollama:
          return _callOllama(activeProvider, prompt, stopwatch);
        case LocalAIProvider.lmStudio:
          return _callLMStudio(activeProvider, prompt, stopwatch);
        case LocalAIProvider.custom:
          return _callCustomEndpoint(activeProvider, prompt, stopwatch);
      }
    } catch (e) {
      return AIDocumentResult.error(
        'Local AI error: $e',
        activeProvider.provider.displayName,
      );
    }
  }

  /// Call Ollama API
  Future<AIDocumentResult> _callOllama(
    LocalAIConfig config,
    String prompt,
    Stopwatch stopwatch,
  ) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      final uri = Uri.parse(config.endpoint);
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'model': config.model,
        'prompt': prompt,
        'stream': false,
        'options': {
          'num_predict': config.maxTokens,
          'temperature': config.temperature,
        },
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode != 200) {
        return AIDocumentResult.error(
          'Ollama error: ${response.statusCode}',
          'Ollama',
        );
      }

      final json = jsonDecode(responseBody);
      final generatedText = json['response'] as String?;

      stopwatch.stop();

      return AIDocumentResult(
        success: true,
        extractedData: generatedText,
        structuredData: _parseStructuredData(generatedText),
        providerUsed: 'Ollama (${config.model})',
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      return AIDocumentResult.error('Ollama error: $e', 'Ollama');
    }
  }

  /// Call LM Studio API (OpenAI-compatible)
  Future<AIDocumentResult> _callLMStudio(
    LocalAIConfig config,
    String prompt,
    Stopwatch stopwatch,
  ) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      final uri = Uri.parse(config.endpoint);
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'model': config.model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': config.maxTokens,
        'temperature': config.temperature,
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode != 200) {
        return AIDocumentResult.error(
          'LM Studio error: ${response.statusCode}',
          'LM Studio',
        );
      }

      final json = jsonDecode(responseBody);
      final generatedText = json['choices']?[0]?['message']?['content'] as String?;

      stopwatch.stop();

      return AIDocumentResult(
        success: true,
        extractedData: generatedText,
        structuredData: _parseStructuredData(generatedText),
        providerUsed: 'LM Studio (${config.model})',
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      return AIDocumentResult.error('LM Studio error: $e', 'LM Studio');
    }
  }

  /// Call custom endpoint
  Future<AIDocumentResult> _callCustomEndpoint(
    LocalAIConfig config,
    String prompt,
    Stopwatch stopwatch,
  ) async {
    // Custom endpoints use OpenAI-compatible format by default
    return _callLMStudio(config, prompt, stopwatch);
  }

  // MARK: - Cloud AI Processing

  /// Process with cloud AI (Claude, ChatGPT, Gemini)
  Future<AIDocumentResult> _processWithCloudAI(
    AIDocumentRequest request,
  ) async {
    final activeProvider = settings.activeCloudProvider;

    if (activeProvider == null) {
      return AIDocumentResult.error(
        'No cloud AI provider configured',
        'cloud',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final prompt = _buildPrompt(request);

      switch (activeProvider.provider) {
        case CloudLLMProvider.claude:
          return _callClaude(activeProvider, prompt, stopwatch);
        case CloudLLMProvider.chatgpt:
          return _callChatGPT(activeProvider, prompt, stopwatch);
        case CloudLLMProvider.gemini:
          return _callGemini(activeProvider, prompt, stopwatch);
      }
    } catch (e) {
      return AIDocumentResult.error(
        'Cloud AI error: $e',
        activeProvider.provider.displayName,
      );
    }
  }

  /// Call Claude API
  Future<AIDocumentResult> _callClaude(
    CloudLLMConfig config,
    String prompt,
    Stopwatch stopwatch,
  ) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 60);

      final uri = Uri.parse(config.endpoint);
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('x-api-key', config.apiKey);
      request.headers.set('anthropic-version', '2023-06-01');

      final body = jsonEncode({
        'model': config.model,
        'max_tokens': config.maxTokens,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode != 200) {
        final errorJson = jsonDecode(responseBody);
        return AIDocumentResult.error(
          'Claude error: ${errorJson['error']?['message'] ?? response.statusCode}',
          'Claude',
        );
      }

      final json = jsonDecode(responseBody);
      final generatedText = json['content']?[0]?['text'] as String?;
      final tokensUsed = json['usage']?['output_tokens'] as int?;

      stopwatch.stop();

      return AIDocumentResult(
        success: true,
        extractedData: generatedText,
        structuredData: _parseStructuredData(generatedText),
        providerUsed: 'Claude (${config.model})',
        processingTime: stopwatch.elapsed,
        tokensUsed: tokensUsed,
      );
    } catch (e) {
      return AIDocumentResult.error('Claude error: $e', 'Claude');
    }
  }

  /// Call ChatGPT API
  Future<AIDocumentResult> _callChatGPT(
    CloudLLMConfig config,
    String prompt,
    Stopwatch stopwatch,
  ) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 60);

      final uri = Uri.parse(config.endpoint);
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer ${config.apiKey}');

      final body = jsonEncode({
        'model': config.model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': config.maxTokens,
        'temperature': config.temperature,
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode != 200) {
        final errorJson = jsonDecode(responseBody);
        return AIDocumentResult.error(
          'ChatGPT error: ${errorJson['error']?['message'] ?? response.statusCode}',
          'ChatGPT',
        );
      }

      final json = jsonDecode(responseBody);
      final generatedText = json['choices']?[0]?['message']?['content'] as String?;
      final tokensUsed = json['usage']?['total_tokens'] as int?;

      stopwatch.stop();

      return AIDocumentResult(
        success: true,
        extractedData: generatedText,
        structuredData: _parseStructuredData(generatedText),
        providerUsed: 'ChatGPT (${config.model})',
        processingTime: stopwatch.elapsed,
        tokensUsed: tokensUsed,
      );
    } catch (e) {
      return AIDocumentResult.error('ChatGPT error: $e', 'ChatGPT');
    }
  }

  /// Call Gemini API
  Future<AIDocumentResult> _callGemini(
    CloudLLMConfig config,
    String prompt,
    Stopwatch stopwatch,
  ) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 60);

      // Gemini uses a different URL format
      final endpoint = '${config.endpoint}/${config.model}:generateContent?key=${config.apiKey}';
      final uri = Uri.parse(endpoint);
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': config.maxTokens,
          'temperature': config.temperature,
        },
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode != 200) {
        final errorJson = jsonDecode(responseBody);
        return AIDocumentResult.error(
          'Gemini error: ${errorJson['error']?['message'] ?? response.statusCode}',
          'Gemini',
        );
      }

      final json = jsonDecode(responseBody);
      final generatedText = json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      stopwatch.stop();

      return AIDocumentResult(
        success: true,
        extractedData: generatedText,
        structuredData: _parseStructuredData(generatedText),
        providerUsed: 'Gemini (${config.model})',
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      return AIDocumentResult.error('Gemini error: $e', 'Gemini');
    }
  }

  // MARK: - Prompt Building

  /// Build prompt for document analysis
  String _buildPrompt(AIDocumentRequest request) {
    if (request.customPrompt != null) {
      return '${request.customPrompt}\n\nDocument text:\n${request.text}';
    }

    switch (request.documentType) {
      case 'invoice':
        return _buildInvoicePrompt(request.text);
      case 'receipt':
        return _buildReceiptPrompt(request.text);
      case 'contract':
        return _buildContractPrompt(request.text);
      case 'id':
        return _buildIdPrompt(request.text);
      default:
        return _buildGeneralPrompt(request.text);
    }
  }

  String _buildInvoicePrompt(String text) {
    return '''Extract the following information from this invoice document and return it as valid JSON:

- invoice_number: The invoice number/ID
- invoice_date: The invoice date (format: YYYY-MM-DD)
- due_date: The payment due date (format: YYYY-MM-DD)
- vendor_name: The vendor/seller company name
- vendor_address: The vendor address
- customer_name: The customer/buyer name
- customer_address: The customer address
- subtotal: The subtotal amount (number only)
- tax: The tax amount (number only)
- total: The total amount (number only)
- currency: The currency code (e.g., USD, EUR)
- line_items: Array of items with description, quantity, unit_price, amount

Return ONLY valid JSON, no other text.

Document text:
$text''';
  }

  String _buildReceiptPrompt(String text) {
    return '''Extract the following information from this receipt and return it as valid JSON:

- merchant_name: Store/merchant name
- merchant_address: Store address
- date: Transaction date (format: YYYY-MM-DD)
- time: Transaction time (format: HH:MM)
- items: Array of purchased items with name, quantity, price
- subtotal: Subtotal amount
- tax: Tax amount
- total: Total amount
- payment_method: Payment method used
- currency: Currency code

Return ONLY valid JSON, no other text.

Document text:
$text''';
  }

  String _buildContractPrompt(String text) {
    return '''Extract key information from this contract document and return it as valid JSON:

- contract_type: Type of contract
- parties: Array of party names involved
- effective_date: Contract start date (format: YYYY-MM-DD)
- expiration_date: Contract end date if applicable (format: YYYY-MM-DD)
- key_terms: Array of important terms and conditions
- payment_terms: Payment-related terms
- signatures: Whether signatures are present (boolean)

Return ONLY valid JSON, no other text.

Document text:
$text''';
  }

  String _buildIdPrompt(String text) {
    return '''Extract information from this ID document and return it as valid JSON:

- document_type: Type of ID (passport, driver's license, etc.)
- full_name: Full name on the document
- date_of_birth: Date of birth (format: YYYY-MM-DD)
- document_number: ID/Document number
- issue_date: Issue date (format: YYYY-MM-DD)
- expiry_date: Expiration date (format: YYYY-MM-DD)
- issuing_authority: Issuing authority/country
- address: Address if present

Return ONLY valid JSON, no other text.

Document text:
$text''';
  }

  String _buildGeneralPrompt(String text) {
    return '''Analyze this document and extract all relevant information.
Return the extracted data as structured JSON with appropriate field names.
Identify the document type and include it as a "document_type" field.

Return ONLY valid JSON, no other text.

Document text:
$text''';
  }

  // MARK: - Response Parsing

  /// Parse structured data from AI response
  Map<String, dynamic>? _parseStructuredData(String? response) {
    if (response == null || response.isEmpty) return null;

    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }

      // Try parsing the whole response as JSON
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      // If parsing fails, return null
      debugPrint('Failed to parse structured data: $e');
      return null;
    }
  }

  // MARK: - Utility Methods

  /// Check if any AI provider is available
  bool get hasAvailableProvider {
    return settings.activeCloudProvider != null ||
        settings.activeLocalProvider != null ||
        settings.onDeviceConfig.useGoogleMLKit ||
        settings.onDeviceConfig.useAppleVision;
  }

  /// Get list of available providers
  List<String> get availableProviders {
    final providers = <String>[];

    if (settings.onDeviceConfig.useGoogleMLKit) {
      providers.add('Google ML Kit');
    }
    if (settings.onDeviceConfig.useAppleVision) {
      providers.add('Apple Vision');
    }

    for (final local in settings.localProviders) {
      if (local.isEnabled) {
        providers.add(local.provider.displayName);
      }
    }

    for (final cloud in settings.cloudProviders) {
      if (cloud.isEnabled && cloud.apiKey.isNotEmpty) {
        providers.add(cloud.provider.displayName);
      }
    }

    return providers;
  }
}

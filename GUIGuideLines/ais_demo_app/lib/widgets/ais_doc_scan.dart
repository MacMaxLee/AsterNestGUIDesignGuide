// =============================================================================
// ais_doc_scan.dart
// AIS DocScan AP Module - Flutter Implementation
// =============================================================================
//
// PURPOSE:
// Document scanning widget for Accounts Payable processing with AI-powered
// field extraction. Integrates with AisMediaPicker for file selection.
//
// AI ROUTER PROVIDER CHAIN:
// Tier 0: Self mapping (manual user entry)
// Tier 1: Google ML Kit Vision (on-device OCR)
// Tier 2: Local Agentic AI (on-device model)
// Tier 3: LLM Fallback (Claude/ChatGPT/Gemini cloud API)
//
// USAGE:
// ```dart
// AisDocScanWidget(
//   onComplete: (result) {
//     // Post to accounting system
//     viewModel.createAPEntry(result);
//   },
//   onCancel: () => Navigator.pop(context),
// )
// ```
//
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as mlkit;
import 'package:flutter_ocr_native/flutter_ocr_native.dart' as native_ocr;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../services/ai_settings.dart';
import '../services/ai_service.dart';
import 'ais_media_picker.dart';
import 'ais_button.dart';
import 'ais_state_badge.dart';

/// Check if ML Kit is supported on current platform (iOS/Android only)
bool get _isMLKitSupported {
  if (kIsWeb) return false;
  return Platform.isIOS || Platform.isAndroid;
}

/// Check if native OCR is supported (macOS, Windows, Linux)
/// Uses flutter_ocr_native: Apple Vision on macOS, WinRT on Windows, Tesseract on Linux
bool get _isNativeOCRSupported {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

// MARK: - AI Provider Types

/// Represents the AI provider used for document extraction
enum AIProviderTier {
  selfMapping(0, 'Manual Entry', Icons.person, 'User fills all fields manually'),
  googleMLKit(1, 'On-Device OCR', Icons.visibility, 'Native OCR (ML Kit/Vision/Tesseract)'),
  localAgentic(2, 'Local AI', Icons.memory, 'On-device AI model'),
  cloudLLM(3, 'Cloud AI', Icons.cloud, 'Cloud LLM (requires API key)');

  final int tier;
  final String displayName;
  final IconData icon;
  final String description;

  const AIProviderTier(this.tier, this.displayName, this.icon, this.description);

  bool get requiresNetwork => this == cloudLLM;

  /// Get platform-specific display name
  String get platformDisplayName {
    if (this == googleMLKit) {
      if (_isMLKitSupported) return 'Google ML Kit';
      if (_isNativeOCRSupported) {
        if (Platform.isMacOS) return 'Apple Vision';
        if (Platform.isWindows) return 'Windows OCR';
        if (Platform.isLinux) return 'Tesseract OCR';
      }
      return 'On-Device OCR';
    }
    return displayName;
  }
}

// MARK: - Extraction Confidence

/// Confidence level for extracted field values
enum ExtractionConfidence {
  high(0.9, Colors.green),
  medium(0.7, Colors.orange),
  low(0.0, Colors.red),
  manual(1.0, Colors.blue);

  final double threshold;
  final Color color;

  const ExtractionConfidence(this.threshold, this.color);

  static ExtractionConfidence fromScore(double score, {bool isEdited = false}) {
    if (isEdited) return manual;
    if (score >= 0.9) return high;
    if (score >= 0.7) return medium;
    return low;
  }
}

// MARK: - Extracted Field

/// Represents a single extracted field with value and confidence
class ExtractedField {
  final String id;
  final String fieldKey;
  final String displayName;
  String extractedValue;
  String mappedValue;
  double confidence;
  ExtractionConfidence confidenceLevel;
  final bool isRequired;
  bool isEdited;
  Rect? boundingBox;

  ExtractedField({
    String? id,
    required this.fieldKey,
    required this.displayName,
    this.extractedValue = '',
    String? mappedValue,
    this.confidence = 0.0,
    this.isRequired = false,
    this.isEdited = false,
    this.boundingBox,
  })  : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_$fieldKey',
        mappedValue = mappedValue ?? extractedValue,
        confidenceLevel = ExtractionConfidence.fromScore(confidence, isEdited: isEdited);

  void updateValue(String newValue) {
    mappedValue = newValue;
    isEdited = true;
    confidenceLevel = ExtractionConfidence.manual;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'fieldKey': fieldKey,
        'displayName': displayName,
        'extractedValue': extractedValue,
        'mappedValue': mappedValue,
        'confidence': confidence,
        'isRequired': isRequired,
        'isEdited': isEdited,
      };
}

// MARK: - Line Item

/// Represents a single line item on an invoice
class InvoiceLineItem {
  final String id;
  int lineNumber;
  String description;
  double quantity;
  double unitPrice;
  double amount;
  String? glAccountCode;
  String? costCenter;
  String? taxCode;
  double confidence;

  InvoiceLineItem({
    String? id,
    required this.lineNumber,
    this.description = '',
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.amount = 0.0,
    this.glAccountCode,
    this.costCenter,
    this.taxCode,
    this.confidence = 0.0,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_line$lineNumber';

  double get calculatedAmount => quantity * unitPrice;
  bool get amountMatches => (calculatedAmount - amount).abs() < 0.01;

  Map<String, dynamic> toMap() => {
        'id': id,
        'lineNumber': lineNumber,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'amount': amount,
        'glAccountCode': glAccountCode,
        'costCenter': costCenter,
        'taxCode': taxCode,
        'confidence': confidence,
      };
}

// MARK: - Document Scan Result

/// Complete result from document scanning and extraction
class DocScanResult {
  final String id;
  final String sourceFileId;
  final DateTime scanDate;
  AIProviderTier providerUsed;
  int processingTimeMs;

  // Header fields
  ExtractedField vendorName;
  ExtractedField vendorAddress;
  ExtractedField invoiceNumber;
  ExtractedField invoiceDate;
  ExtractedField dueDate;
  ExtractedField poNumber;

  // Amounts
  ExtractedField subtotal;
  ExtractedField taxAmount;
  ExtractedField totalAmount;
  ExtractedField currency;

  // Line items
  List<InvoiceLineItem> lineItems;

  // Processing state
  DocScanStatus status;
  List<String> validationErrors;

  // Raw OCR text for debugging
  String? rawOCRText;

  DocScanResult({
    String? id,
    required this.sourceFileId,
    DateTime? scanDate,
    this.providerUsed = AIProviderTier.selfMapping,
    this.processingTimeMs = 0,
    this.status = DocScanStatus.pending,
    List<String>? validationErrors,
    this.rawOCRText,
  })  : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_scan',
        scanDate = scanDate ?? DateTime.now(),
        validationErrors = validationErrors ?? [],
        vendorName = ExtractedField(fieldKey: 'vendor_name', displayName: 'Vendor Name', isRequired: true),
        vendorAddress = ExtractedField(fieldKey: 'vendor_address', displayName: 'Vendor Address'),
        invoiceNumber = ExtractedField(fieldKey: 'invoice_number', displayName: 'Invoice Number', isRequired: true),
        invoiceDate = ExtractedField(fieldKey: 'invoice_date', displayName: 'Invoice Date', isRequired: true),
        dueDate = ExtractedField(fieldKey: 'due_date', displayName: 'Due Date'),
        poNumber = ExtractedField(fieldKey: 'po_number', displayName: 'PO Number'),
        subtotal = ExtractedField(fieldKey: 'subtotal', displayName: 'Subtotal'),
        taxAmount = ExtractedField(fieldKey: 'tax_amount', displayName: 'Tax Amount'),
        totalAmount = ExtractedField(fieldKey: 'total_amount', displayName: 'Total Amount', isRequired: true),
        currency = ExtractedField(fieldKey: 'currency', displayName: 'Currency', extractedValue: 'USD', mappedValue: 'USD'),
        lineItems = [];

  List<ExtractedField> get allHeaderFields => [vendorName, vendorAddress, invoiceNumber, invoiceDate, dueDate, poNumber];

  List<ExtractedField> get allAmountFields => [subtotal, taxAmount, totalAmount, currency];

  bool get amountsBalance {
    final calcTotal = (double.tryParse(subtotal.mappedValue) ?? 0) +
        (double.tryParse(taxAmount.mappedValue) ?? 0);
    final declaredTotal = double.tryParse(totalAmount.mappedValue) ?? 0;
    return (calcTotal - declaredTotal).abs() < 0.01;
  }

  double get overallConfidence {
    final fields = [...allHeaderFields, ...allAmountFields];
    final totalConf = fields.fold<double>(0.0, (sum, f) => sum + f.confidence);
    return fields.isEmpty ? 0 : totalConf / fields.length;
  }

  bool get hasRequiredFields {
    final required = [...allHeaderFields, ...allAmountFields].where((f) => f.isRequired);
    return required.every((f) => f.mappedValue.isNotEmpty);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sourceFileId': sourceFileId,
        'scanDate': scanDate.toIso8601String(),
        'providerUsed': providerUsed.name,
        'processingTimeMs': processingTimeMs,
        'vendorName': vendorName.toMap(),
        'invoiceNumber': invoiceNumber.toMap(),
        'invoiceDate': invoiceDate.toMap(),
        'totalAmount': totalAmount.toMap(),
        'lineItems': lineItems.map((li) => li.toMap()).toList(),
        'status': status.name,
        'validationErrors': validationErrors,
      };
}

// MARK: - Processing Status

/// Status of document scanning process
enum DocScanStatus {
  pending('Pending', Icons.schedule, AisStateType.info),
  scanning('Scanning...', Icons.document_scanner, AisStateType.info),
  extracting('Extracting...', Icons.psychology, AisStateType.info),
  review('Ready for Review', Icons.visibility, AisStateType.warning),
  approved('Approved', Icons.check_circle, AisStateType.info),  // Use info for success-like
  posted('Posted', Icons.verified, AisStateType.info),  // Use info for success-like
  rejected('Rejected', Icons.cancel, AisStateType.error),
  error('Error', Icons.error, AisStateType.error);

  final String displayName;
  final IconData icon;
  final AisStateType badgeType;

  const DocScanStatus(this.displayName, this.icon, this.badgeType);
}

// MARK: - DocScan Service

/// Main service for document scanning with AI Router pattern
class DocScanService extends ChangeNotifier {
  DocScanResult? currentResult;
  DocScanStatus status = DocScanStatus.pending;
  double progress = 0.0;
  String? error;
  AIProviderTier activeProvider = AIProviderTier.selfMapping;
  AIProviderTier preferredProvider = AIProviderTier.googleMLKit;

  String? cloudAPIKey;

  // Google ML Kit text recognizer (only created on supported platforms)
  mlkit.TextRecognizer? _textRecognizer;

  // Native OCR reader for desktop platforms (macOS/Windows/Linux)
  native_ocr.OcrReader? _nativeOcrReader;

  // AI Service for cloud/local AI processing
  AIService? _aiService;

  DocScanService() {
    // Only create ML Kit recognizer on supported platforms (iOS/Android)
    if (_isMLKitSupported) {
      _textRecognizer = mlkit.TextRecognizer();
    }
    // Create native OCR reader for desktop platforms
    if (_isNativeOCRSupported) {
      _nativeOcrReader = native_ocr.OcrReader();
    }
  }

  /// Get the AI service instance
  AIService? get aiService => _aiService;

  /// Initialize with AI settings service for cloud/local AI support
  void initializeAIService(AISettingsService settingsService) {
    _aiService = AIService(settingsService);
  }

  @override
  void dispose() {
    _textRecognizer?.close();
    super.dispose();
  }

  Future<DocScanResult> processDocument(AisFileInfo fileInfo) async {
    status = DocScanStatus.scanning;
    progress = 0.1;
    error = null;
    notifyListeners();

    final startTime = DateTime.now();

    try {
      // Determine file type and extract text accordingly
      final extension = fileInfo.extension.toLowerCase();
      String recognizedText = '';

      progress = 0.2;
      status = DocScanStatus.extracting;
      notifyListeners();

      // Handle different file types
      if (_isPlainTextFile(extension)) {
        // Plain text files - read directly
        recognizedText = await _extractTextFromTextFile(fileInfo);
        activeProvider = AIProviderTier.selfMapping; // No AI needed for text
      } else if (extension == '.pdf') {
        // PDF files - extract text using Syncfusion PDF
        recognizedText = await _extractTextFromPDF(fileInfo);
        activeProvider = AIProviderTier.googleMLKit; // Mark as processed
      } else {
        // Image files - use OCR
        activeProvider = preferredProvider;

        Uint8List? imageData;
        String? imagePath;

        if (fileInfo.fullPath.isNotEmpty) {
          imagePath = fileInfo.fullPath;
          imageData = await File(fileInfo.fullPath).readAsBytes();
        } else if (fileInfo.bytes != null) {
          imageData = Uint8List.fromList(fileInfo.bytes!);
          // Write bytes to temp file for ML Kit
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(imageData);
          imagePath = tempFile.path;
        }

        if (imageData == null || imagePath == null) {
          throw Exception('Unable to read file: ${fileInfo.fileName}');
        }

        progress = 0.4;
        notifyListeners();

        if (preferredProvider == AIProviderTier.googleMLKit && _isMLKitSupported) {
          // Use Google ML Kit on iOS/Android
          recognizedText = await _performGoogleMLKitOCR(imagePath);
        } else if (preferredProvider == AIProviderTier.googleMLKit && _isNativeOCRSupported) {
          // Use native OCR on desktop (macOS Vision, Windows WinRT, Linux Tesseract)
          recognizedText = await _performNativeOCR(imagePath);
          debugPrint('Using native OCR (Apple Vision/WinRT/Tesseract) on desktop platform');
        } else if (preferredProvider == AIProviderTier.googleMLKit && !_isMLKitSupported && !_isNativeOCRSupported) {
          // No OCR available on this platform (web)
          // Try to use AI Service if available for image analysis
          if (_aiService != null && _aiService!.isConfigured) {
            activeProvider = AIProviderTier.cloudLLM;
            debugPrint('No native OCR available. Attempting Cloud AI for OCR...');
            recognizedText = '';
          } else {
            // Fall back to manual entry mode
            activeProvider = AIProviderTier.selfMapping;
            debugPrint('No OCR available on this platform. Using manual entry mode.');
          }
        } else if (preferredProvider == AIProviderTier.cloudLLM || preferredProvider == AIProviderTier.localAgentic) {
          // User explicitly chose Cloud or Local AI - use that for OCR
          activeProvider = preferredProvider;
          // Let _enhanceWithAIService handle the extraction
          recognizedText = '';
        }
      }

      progress = 0.7;
      notifyListeners();

      // Create result and parse extracted text
      var result = DocScanResult(
        sourceFileId: fileInfo.id,
        providerUsed: activeProvider,
      );
      result.rawOCRText = recognizedText;

      // Parse invoice fields from extracted text
      _parseInvoiceFields(result, recognizedText);

      progress = 0.8;
      notifyListeners();

      // If Cloud AI or Local AI is preferred, enhance extraction with AI Service
      // Also try AI Service if we have no OCR text (e.g., on macOS with images)
      final shouldUseAI = (preferredProvider == AIProviderTier.cloudLLM ||
              preferredProvider == AIProviderTier.localAgentic ||
              activeProvider == AIProviderTier.cloudLLM ||
              activeProvider == AIProviderTier.localAgentic) &&
          _aiService != null &&
          _aiService!.isConfigured;

      if (shouldUseAI) {
        // If we have no OCR text for an image, try to analyze the image directly
        // For now, we still use the text-based API but could be extended for vision
        if (recognizedText.isNotEmpty) {
          await _enhanceWithAIService(result, recognizedText);
        } else {
          // No OCR text available - inform user that manual entry is needed
          // In a full implementation, we could send the image bytes to a vision API
          debugPrint('No OCR text available. AI analysis requires text input.');
        }
      }

      progress = 0.9;
      notifyListeners();

      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      result.processingTimeMs = processingTime;
      result.status = DocScanStatus.review;

      currentResult = result;
      status = DocScanStatus.review;
      progress = 1.0;
      notifyListeners();

      return result;
    } catch (e) {
      // Fallback to manual entry
      var manualResult = DocScanResult(
        sourceFileId: fileInfo.id,
        providerUsed: AIProviderTier.selfMapping,
      );
      manualResult.status = DocScanStatus.review;

      currentResult = manualResult;
      status = DocScanStatus.review;
      error = e.toString();
      progress = 1.0;
      notifyListeners();

      return manualResult;
    }
  }

  /// Check if the file is a plain text file
  bool _isPlainTextFile(String extension) {
    const textExtensions = ['.txt', '.md', '.json', '.xml', '.csv', '.html', '.htm'];
    return textExtensions.contains(extension);
  }

  /// Extract text directly from plain text files
  Future<String> _extractTextFromTextFile(AisFileInfo fileInfo) async {
    if (fileInfo.fullPath.isNotEmpty) {
      final file = File(fileInfo.fullPath);
      return await file.readAsString();
    } else if (fileInfo.bytes != null) {
      return String.fromCharCodes(fileInfo.bytes!);
    }
    throw Exception('Unable to read text file: ${fileInfo.fileName}');
  }

  /// Extract text from PDF files using Syncfusion PDF
  Future<String> _extractTextFromPDF(AisFileInfo fileInfo) async {
    Uint8List? pdfBytes;

    if (fileInfo.fullPath.isNotEmpty) {
      pdfBytes = await File(fileInfo.fullPath).readAsBytes();
    } else if (fileInfo.bytes != null) {
      pdfBytes = Uint8List.fromList(fileInfo.bytes!);
    }

    if (pdfBytes == null) {
      throw Exception('Unable to read PDF file: ${fileInfo.fileName}');
    }

    // Load the PDF document
    final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

    // Extract text from all pages
    final StringBuffer textBuffer = StringBuffer();
    final PdfTextExtractor extractor = PdfTextExtractor(document);

    for (int i = 0; i < document.pages.count; i++) {
      final String pageText = extractor.extractText(startPageIndex: i);
      textBuffer.writeln(pageText);
      textBuffer.writeln(); // Add spacing between pages
    }

    // Dispose the document
    document.dispose();

    return textBuffer.toString();
  }

  /// Perform OCR using Google ML Kit Text Recognition
  Future<String> _performGoogleMLKitOCR(String imagePath) async {
    if (_textRecognizer == null) {
      throw Exception('ML Kit Text Recognition is not available on this platform');
    }

    final inputImage = mlkit.InputImage.fromFilePath(imagePath);
    final mlkit.RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);

    // Extract all text blocks
    final StringBuffer buffer = StringBuffer();
    for (mlkit.TextBlock block in recognizedText.blocks) {
      for (mlkit.TextLine line in block.lines) {
        buffer.writeln(line.text);
      }
      buffer.writeln(); // Add spacing between blocks
    }

    return buffer.toString();
  }

  /// Perform OCR using native platform APIs (macOS Vision, Windows WinRT, Linux Tesseract)
  Future<String> _performNativeOCR(String imagePath) async {
    if (_nativeOcrReader == null) {
      throw Exception('Native OCR is not available on this platform');
    }

    try {
      final result = await _nativeOcrReader!.readFromPath(imagePath);

      // Extract text from result blocks for more structured output
      final StringBuffer buffer = StringBuffer();
      for (final block in result.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
        buffer.writeln(); // Add spacing between blocks
      }

      // If structured extraction is empty, fall back to plain text
      final structuredText = buffer.toString().trim();
      if (structuredText.isNotEmpty) {
        return structuredText;
      }

      // Return the plain text if structured is empty
      return result.text;
    } catch (e) {
      debugPrint('Native OCR failed: $e');
      rethrow;
    }
  }

  /// Enhance extraction using AI Service (Claude, ChatGPT, Gemini, or Local AI)
  Future<void> _enhanceWithAIService(DocScanResult result, String text) async {
    if (_aiService == null) return;

    try {
      final request = AIDocumentRequest(
        text: text,
        documentType: 'invoice',
      );

      final aiResult = await _aiService!.analyzeDocument(request);

      if (aiResult.success && aiResult.structuredData != null) {
        final data = aiResult.structuredData!;

        // Update fields from AI extraction with higher confidence
        _updateFieldFromAI(result.invoiceNumber, data['invoice_number'], 0.95);
        _updateFieldFromAI(result.invoiceDate, data['invoice_date'], 0.90);
        _updateFieldFromAI(result.dueDate, data['due_date'], 0.85);
        _updateFieldFromAI(result.vendorName, data['vendor_name'], 0.90);
        _updateFieldFromAI(result.vendorAddress, data['vendor_address'], 0.85);
        _updateFieldFromAI(result.poNumber, data['po_number'], 0.85);
        _updateFieldFromAI(result.subtotal, data['subtotal']?.toString(), 0.90);
        _updateFieldFromAI(result.taxAmount, data['tax']?.toString(), 0.90);
        _updateFieldFromAI(result.totalAmount, data['total']?.toString(), 0.95);
        _updateFieldFromAI(result.currency, data['currency'], 0.95);

        // Parse line items if available
        if (data['line_items'] is List) {
          result.lineItems.clear();
          int lineNum = 1;
          for (final item in data['line_items']) {
            if (item is Map) {
              result.lineItems.add(InvoiceLineItem(
                lineNumber: lineNum++,
                description: item['description']?.toString() ?? '',
                quantity: (item['quantity'] is num)
                    ? (item['quantity'] as num).toDouble()
                    : double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0,
                unitPrice: (item['unit_price'] is num)
                    ? (item['unit_price'] as num).toDouble()
                    : double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0,
                amount: (item['amount'] is num)
                    ? (item['amount'] as num).toDouble()
                    : double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
                confidence: 0.85,
              ));
            }
          }
        }

        // Update provider tier based on what was actually used
        if (aiResult.providerUsed.contains('Claude') ||
            aiResult.providerUsed.contains('ChatGPT') ||
            aiResult.providerUsed.contains('Gemini')) {
          activeProvider = AIProviderTier.cloudLLM;
          result.providerUsed = AIProviderTier.cloudLLM;
        } else if (aiResult.providerUsed.contains('Ollama') ||
            aiResult.providerUsed.contains('LM Studio')) {
          activeProvider = AIProviderTier.localAgentic;
          result.providerUsed = AIProviderTier.localAgentic;
        }
      }
    } catch (e) {
      // AI enhancement failed, keep regex-based extraction
      debugPrint('AI enhancement failed: $e');
    }
  }

  /// Update a field from AI extraction if the value is present
  void _updateFieldFromAI(ExtractedField field, dynamic value, double confidence) {
    if (value == null) return;
    final strValue = value.toString().trim();
    if (strValue.isEmpty || strValue == 'null') return;

    // Only update if AI confidence is higher or field was empty
    if (field.mappedValue.isEmpty || confidence > field.confidence) {
      field.extractedValue = strValue;
      field.mappedValue = strValue;
      field.confidence = confidence;
      field.confidenceLevel = ExtractionConfidence.fromScore(confidence);
    }
  }

  /// Parse invoice fields from OCR text using regex patterns
  void _parseInvoiceFields(DocScanResult result, String text) {
    if (text.isEmpty) return;

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // Known retail store names for high-confidence vendor matching
    const knownStores = [
      'COSTCO', 'WALMART', 'TARGET', 'SAFEWAY', 'KROGER', 'WHOLE FOODS',
      'TRADER JOE', 'CVS', 'WALGREENS', 'HOME DEPOT', 'LOWES', 'AMAZON',
      'BEST BUY', 'STAPLES', 'OFFICE DEPOT', 'NORDSTROM', 'MACY'
    ];

    // Invoice/Receipt/Transaction Number patterns - expanded for retail receipts
    final invoicePatterns = [
      RegExp(r'(?:invoice|receipt|trans(?:action)?|order|ref(?:erence)?)\s*(?:#|no\.?|number|:)?\s*[:\s]?([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'#\s*(\d{4,})', caseSensitive: false),
    ];
    for (final pattern in invoicePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.trim() ?? '';
        if (value.isNotEmpty) {
          result.invoiceNumber.extractedValue = value;
          result.invoiceNumber.mappedValue = value;
          result.invoiceNumber.confidence = 0.85;
          result.invoiceNumber.confidenceLevel = ExtractionConfidence.fromScore(0.85);
          break;
        }
      }
    }

    // Date patterns (various formats) - expanded for retail receipts
    final datePatterns = [
      RegExp(r'(?:date|time|purchased)[:\s]+(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})\s+\d{1,2}:\d{2}', caseSensitive: false),
      RegExp(r'(\w{3,9}\s+\d{1,2},?\s+\d{4})', caseSensitive: false),
    ];
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        result.invoiceDate.extractedValue = match.group(1) ?? '';
        result.invoiceDate.mappedValue = result.invoiceDate.extractedValue;
        result.invoiceDate.confidence = 0.80;
        result.invoiceDate.confidenceLevel = ExtractionConfidence.fromScore(0.80);
        break;
      }
    }

    // Due Date
    final dueDatePattern = RegExp(
      r'(?:due\s*(?:date)?|payment\s*due)\s*[:\s]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|\w+\s+\d{1,2},?\s*\d{4})',
      caseSensitive: false,
    );
    final dueDateMatch = dueDatePattern.firstMatch(text);
    if (dueDateMatch != null) {
      result.dueDate.extractedValue = dueDateMatch.group(1) ?? '';
      result.dueDate.mappedValue = result.dueDate.extractedValue;
      result.dueDate.confidence = 0.75;
      result.dueDate.confidenceLevel = ExtractionConfidence.fromScore(0.75);
    }

    // PO Number
    final poPattern = RegExp(
      r'(?:p\.?o\.?\s*(?:#|no\.?|number)?|purchase\s*order)\s*[:\s]?\s*([A-Z0-9\-]+)',
      caseSensitive: false,
    );
    final poMatch = poPattern.firstMatch(text);
    if (poMatch != null) {
      result.poNumber.extractedValue = poMatch.group(1) ?? '';
      result.poNumber.mappedValue = result.poNumber.extractedValue;
      result.poNumber.confidence = 0.80;
      result.poNumber.confidenceLevel = ExtractionConfidence.fromScore(0.80);
    }

    // Total Amount - expanded patterns for retail receipts
    final totalPatterns = [
      RegExp(r'(?:total|grand\s*total|amount\s*due|balance\s*due)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'\*+\s*total\s*\$?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];
    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amount = match.group(1)?.replaceAll(',', '') ?? '';
        if (amount.isNotEmpty) {
          result.totalAmount.extractedValue = amount;
          result.totalAmount.mappedValue = amount;
          result.totalAmount.confidence = 0.90;
          result.totalAmount.confidenceLevel = ExtractionConfidence.fromScore(0.90);
          break;
        }
      }
    }

    // Subtotal
    final subtotalPattern = RegExp(
      r'(?:subtotal|sub\s*total)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    final subtotalMatch = subtotalPattern.firstMatch(text);
    if (subtotalMatch != null) {
      final amount = subtotalMatch.group(1)?.replaceAll(',', '') ?? '';
      result.subtotal.extractedValue = amount;
      result.subtotal.mappedValue = amount;
      result.subtotal.confidence = 0.85;
      result.subtotal.confidenceLevel = ExtractionConfidence.fromScore(0.85);
    }

    // Tax Amount - expanded patterns
    final taxPatterns = [
      RegExp(r'(?:tax|vat|gst|hst|sales\s*tax)\s*(?:amount)?\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];
    for (final pattern in taxPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amount = match.group(1)?.replaceAll(',', '') ?? '';
        if (amount.isNotEmpty) {
          result.taxAmount.extractedValue = amount;
          result.taxAmount.mappedValue = amount;
          result.taxAmount.confidence = 0.85;
          result.taxAmount.confidenceLevel = ExtractionConfidence.fromScore(0.85);
          break;
        }
      }
    }

    // Vendor Name - First check for known retail stores (high confidence)
    final upperText = text.toUpperCase();
    bool foundKnownStore = false;
    for (final store in knownStores) {
      if (upperText.contains(store)) {
        // Find the full line containing the store name
        for (final line in lines.take(10)) {
          if (line.toUpperCase().contains(store)) {
            result.vendorName.extractedValue = line.trim();
            result.vendorName.mappedValue = result.vendorName.extractedValue;
            result.vendorName.confidence = 0.90;
            result.vendorName.confidenceLevel = ExtractionConfidence.fromScore(0.90);
            foundKnownStore = true;
            break;
          }
        }
        if (foundKnownStore) break;
      }
    }

    // Fallback: Try "From:" section or first substantial line
    if (!foundKnownStore) {
      final fromPattern = RegExp(
        r'(?:from|vendor|supplier|bill\s*from)\s*[:\s]?\s*(.+)',
        caseSensitive: false,
      );
      final fromMatch = fromPattern.firstMatch(text);
      if (fromMatch != null) {
        result.vendorName.extractedValue = fromMatch.group(1)?.trim() ?? '';
        result.vendorName.mappedValue = result.vendorName.extractedValue;
        result.vendorName.confidence = 0.75;
        result.vendorName.confidenceLevel = ExtractionConfidence.fromScore(0.75);
      } else if (lines.isNotEmpty) {
        // Use first substantial non-numeric line as vendor name
        for (final line in lines.take(5)) {
          final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(line);
          final isNotPrice = !line.contains('\$') && !line.toUpperCase().contains('TOTAL');
          if (hasLetters && isNotPrice && line.length > 3) {
            result.vendorName.extractedValue = line.trim();
            result.vendorName.mappedValue = result.vendorName.extractedValue;
            result.vendorName.confidence = 0.60;
            result.vendorName.confidenceLevel = ExtractionConfidence.fromScore(0.60);
            break;
          }
        }
      }
    }

    // Vendor Address - Look for address patterns
    final addressPattern = RegExp(
      r'(\d+\s+[\w\s]+(?:street|st|avenue|ave|road|rd|drive|dr|lane|ln|blvd|boulevard)[\s\S]*?(?:\d{5}(?:\-\d{4})?))',
      caseSensitive: false,
    );
    final addressMatch = addressPattern.firstMatch(text);
    if (addressMatch != null) {
      result.vendorAddress.extractedValue = addressMatch.group(1)?.trim() ?? '';
      result.vendorAddress.mappedValue = result.vendorAddress.extractedValue;
      result.vendorAddress.confidence = 0.70;
      result.vendorAddress.confidenceLevel = ExtractionConfidence.fromScore(0.70);
    }

    // Parse line items from receipt/invoice
    _parseLineItems(result, lines);
  }

  /// Parse line items from OCR text lines
  /// Supports Costco format: SKU + description on one line, price on next line
  void _parseLineItems(DocScanResult result, List<String> lines) {
    result.lineItems.clear();
    int lineNumber = 1;

    debugPrint('=== Parsing ${lines.length} lines for line items ===');

    // Skip header/footer keywords - but NOT standalone tax codes like "A" or "E"
    final skipKeywords = [
      'SUBTOTAL', 'SUB TOTAL', 'TOTAL', 'TAX', 'CASH', 'CREDIT', 'DEBIT',
      'CHANGE', 'BALANCE', 'PAYMENT', 'THANK YOU', 'WELCOME', 'MEMBER',
      'CARD', 'VISA', 'MASTERCARD', 'AMEX', 'DISCOVER', 'DATE', 'TIME',
      'RECEIPT', 'TRANSACTION', 'REGISTER', 'CASHIER', 'STORE', 'TEL',
      'PHONE', 'ADDRESS', 'WWW', 'HTTP', '.COM', 'SAVINGS', 'DISCOUNT',
      'ITEMS SOLD', 'AMOUNT', 'WHSE', 'TRM', 'TRN', 'OP#', 'SEG#', 'AID',
      'WHOLESALE', 'APPROVAL', 'REF', 'ENTRY', 'CHIP READ', 'COSTCO',
    ];

    // Skip patterns for non-item lines (locations, card numbers, identifiers)
    final skipPatterns = [
      RegExp(r'^[A-Za-z]+\s*#\s*\d+$'),                    // "Eastvale #1317"
      RegExp(r'^X{4,}', caseSensitive: false),             // "XXXXXXXXXXXX8071"
      RegExp(r'^\*{4,}'),                                  // "****1234"
      RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4}'),                 // Date lines
      RegExp(r'^\d+\s+[A-Za-z]+\s+(Ave|St|Rd|Blvd|Dr)', caseSensitive: false), // Address
      RegExp(r'^[A-Z]{2}\s+\d{5}'),                        // State ZIP
      RegExp(r'^Member\s', caseSensitive: false),          // Member info
      RegExp(r'^\(\d{3}\)'),                               // Phone numbers
      RegExp(r'^\d{3}[-.\s]\d{3}[-.\s]\d{4}'),             // Phone numbers
      RegExp(r'^AMOUNT:', caseSensitive: false),           // "AMOUNT:" line
    ];

    // Pattern for Costco SKU line: 6-7 digit SKU followed by description
    final skuPattern = RegExp(r'^(\d{6,7})\s+(.+)$');

    // Pattern for price line: captures price and anything after it
    // Handles OCR errors like "399.90 Ii" by extracting price and validating tax code separately
    final priceLinePattern = RegExp(r'^-?(\d+\.\d{2})(.*)$');

    // Pattern for price at end of line (requires decimal: ###.##)
    final priceEndPattern = RegExp(r'\$?\s*(\d+\.\d{2})\s*([A-Za-z]*)?\s*$');

    // Helper to validate tax code - must be single uppercase letter
    bool isValidTaxCode(String? code) {
      if (code == null || code.isEmpty) return false;
      return RegExp(r'^[A-Z]$').hasMatch(code.trim());
    }

    // Pattern for quantity indicators
    final qtyPatterns = [
      RegExp(r'(\d+)\s*[@xX]\s*\$?(\d+\.\d{2})'), // "2 @ $5.99" or "2 x 5.99"
      RegExp(r'QTY\s*:?\s*(\d+)', caseSensitive: false), // "QTY: 2" or "QTY 2"
    ];

    int i = 0;
    while (i < lines.length) {
      final trimmedLine = lines[i].trim();
      if (trimmedLine.isEmpty) {
        i++;
        continue;
      }

      // Skip lines that are likely headers/footers by keyword
      final upperLine = trimmedLine.toUpperCase();
      bool shouldSkip = false;
      for (final keyword in skipKeywords) {
        if (upperLine.contains(keyword)) {
          shouldSkip = true;
          break;
        }
      }
      if (shouldSkip) {
        i++;
        continue;
      }

      // Skip by pattern
      for (final pattern in skipPatterns) {
        if (pattern.hasMatch(trimmedLine)) {
          shouldSkip = true;
          break;
        }
      }
      if (shouldSkip) {
        i++;
        continue;
      }

      // Costco format: SKU (6-7 digits) + description on one line, price on next line
      // Example: "1806222 KOHLER SINK" followed by "399.99 A" or "399.90 Ii" (OCR error)
      final skuMatch = skuPattern.firstMatch(trimmedLine);
      if (skuMatch != null) {
        final description = skuMatch.group(2)?.trim() ?? '';
        debugPrint('Found SKU line: "$trimmedLine" -> description: "$description"');

        // Look at next line for price
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          debugPrint('  Next line: "$nextLine"');

          // Extract price and potential tax code (handles OCR errors)
          final priceLineMatch = priceLinePattern.firstMatch(nextLine);

          if (priceLineMatch != null) {
            final priceStr = priceLineMatch.group(1) ?? '0';
            final remainder = priceLineMatch.group(2)?.trim() ?? '';
            final amount = double.tryParse(priceStr) ?? 0.0;

            // Only use tax code if it's a valid single uppercase letter
            String? taxCode = isValidTaxCode(remainder) ? remainder : null;
            debugPrint('  Price match: $priceStr, remainder: "$remainder", taxCode: $taxCode, amount: $amount');

            // Skip negative amounts (discounts) and invalid amounts
            if (amount > 0 && amount <= 10000 && description.isNotEmpty) {
              debugPrint('  ADDING LINE ITEM: $description @ $amount');
              result.lineItems.add(InvoiceLineItem(
                lineNumber: lineNumber++,
                description: description,
                quantity: 1.0,
                unitPrice: amount,
                amount: amount,
                confidence: 0.80,
                taxCode: taxCode,
              ));
              i += 2; // Skip both lines
              continue;
            }
          } else {
            debugPrint('  Price pattern did not match');
          }
        }
      }

      // Standard format: description + price on same line
      // Require price to have decimal point (###.##)
      final priceMatch = priceEndPattern.firstMatch(trimmedLine);

      if (priceMatch != null) {
        final priceStr = priceMatch.group(1) ?? '0';
        final remainder = priceMatch.group(2)?.trim() ?? '';
        final amount = double.tryParse(priceStr) ?? 0.0;

        // Only use tax code if it's a valid single uppercase letter
        String? taxCode = isValidTaxCode(remainder) ? remainder : null;

        // Skip very small amounts or very large (likely totals)
        if (amount >= 0.01 && amount <= 10000) {
          // Extract description (everything before the price)
          String description = trimmedLine.substring(0, priceMatch.start).trim();

          // Default quantity and unit price
          double quantity = 1.0;
          double unitPrice = amount;

          // Check for quantity patterns
          for (final qtyPattern in qtyPatterns) {
            final qtyMatch = qtyPattern.firstMatch(description);
            if (qtyMatch != null) {
              final qtyStr = qtyMatch.group(1);
              final qty = double.tryParse(qtyStr ?? '1') ?? 1.0;
              if (qty > 0 && qty < 1000) {
                quantity = qty;
                // If we have "2 @ $5.99", extract unit price
                if (qtyMatch.groupCount >= 2) {
                  final unitStr = qtyMatch.group(2);
                  final parsedUnit = double.tryParse(unitStr ?? '0');
                  if (parsedUnit != null && parsedUnit > 0) {
                    unitPrice = parsedUnit;
                  } else {
                    unitPrice = amount / quantity;
                  }
                } else {
                  unitPrice = amount / quantity;
                }
                // Remove quantity pattern from description
                description = description.replaceFirst(qtyPattern, '').trim();
              }
              break;
            }
          }

          // Clean up description - remove SKU numbers at start
          description = description
              .replaceAll(RegExp(r'^\d{6,}\s+'), '') // Remove leading SKU
              .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
              .trim();

          // Skip if description is too short or doesn't have at least 2 consecutive letters
          if (description.length >= 2 && RegExp(r'[a-zA-Z]{2,}').hasMatch(description)) {
            result.lineItems.add(InvoiceLineItem(
              lineNumber: lineNumber++,
              description: description,
              quantity: quantity,
              unitPrice: unitPrice,
              amount: amount,
              confidence: 0.70,
              taxCode: taxCode,
            ));
          }
        }
      }

      i++;

      // Limit to reasonable number of line items
      if (lineNumber > 100) break;
    }

    debugPrint('=== Found ${result.lineItems.length} line items ===');
    for (final item in result.lineItems) {
      debugPrint('  ${item.lineNumber}. ${item.description}: \$${item.amount} (tax: ${item.taxCode ?? "none"})');
    }
  }

  List<String> validateResult() {
    if (currentResult == null) return ['No document scanned'];

    final errors = <String>[];
    if (currentResult!.vendorName.mappedValue.isEmpty) {
      errors.add('Vendor name is required');
    }
    if (currentResult!.invoiceNumber.mappedValue.isEmpty) {
      errors.add('Invoice number is required');
    }
    if (currentResult!.invoiceDate.mappedValue.isEmpty) {
      errors.add('Invoice date is required');
    }
    if (currentResult!.totalAmount.mappedValue.isEmpty) {
      errors.add('Total amount is required');
    }

    if (currentResult!.subtotal.mappedValue.isNotEmpty &&
        currentResult!.taxAmount.mappedValue.isNotEmpty) {
      if (!currentResult!.amountsBalance) {
        errors.add('Subtotal + Tax does not equal Total');
      }
    }

    return errors;
  }

  void approveResult() {
    if (currentResult == null) return;
    currentResult!.validationErrors = validateResult();
    currentResult!.status = DocScanStatus.approved;
    status = currentResult!.validationErrors.isEmpty
        ? DocScanStatus.approved
        : DocScanStatus.review;
    notifyListeners();
  }

  void rejectResult() {
    if (currentResult == null) return;
    currentResult!.status = DocScanStatus.rejected;
    status = DocScanStatus.rejected;
    notifyListeners();
  }

  void reset() {
    currentResult = null;
    status = DocScanStatus.pending;
    progress = 0.0;
    error = null;
    activeProvider = AIProviderTier.selfMapping;
    notifyListeners();
  }
}

// MARK: - Main Widget

/// Main widget for document scanning and AP entry creation
class AisDocScanWidget extends StatefulWidget {
  final void Function(DocScanResult result)? onComplete;
  final VoidCallback? onCancel;

  const AisDocScanWidget({
    super.key,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<AisDocScanWidget> createState() => _AisDocScanWidgetState();
}

class _AisDocScanWidgetState extends State<AisDocScanWidget> {
  final DocScanService _scanService = DocScanService();
  AisFileInfo? _selectedFile;
  bool _showRawOCR = false;
  bool _showOCROutputDialog = false;

  @override
  void dispose() {
    _scanService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return ListenableBuilder(
      listenable: _scanService,
      builder: (context, _) {
        return Column(
          children: [
            // Header
            _buildHeader(tokens),
            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AisTheme.spacingLg),
                child: _buildContent(tokens),
              ),
            ),

            const Divider(height: 1),

            // Footer
            _buildFooter(tokens),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AisTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Scanner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.onSurface,
                ),
              ),
              Text(
                'AP Invoice Entry',
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.onSurfaceSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AisTheme.spacingSm,
              vertical: AisTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: tokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(AisTheme.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _scanService.activeProvider.icon,
                  size: 16,
                  color: tokens.actionPrimary.color,
                ),
                const SizedBox(width: 4),
                Text(
                  _scanService.activeProvider.displayName,
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

  Widget _buildContent(AisTokens tokens) {
    switch (_scanService.status) {
      case DocScanStatus.pending:
        return _buildFileSelection(tokens);
      case DocScanStatus.scanning:
      case DocScanStatus.extracting:
        return _buildProcessing(tokens);
      case DocScanStatus.review:
      case DocScanStatus.approved:
        return _buildReview(tokens);
      case DocScanStatus.rejected:
        return _buildRejected(tokens);
      case DocScanStatus.error:
        return _buildError(tokens);
      case DocScanStatus.posted:
        return _buildPosted(tokens);
    }
  }

  Widget _buildFileSelection(AisTokens tokens) {
    return Column(
      children: [
        const SizedBox(height: AisTheme.spacingXl),

        // Icon
        Icon(
          Icons.document_scanner,
          size: 64,
          color: tokens.actionPrimary.color,
        ),
        const SizedBox(height: AisTheme.spacingMd),

        Text(
          'Scan Invoice Document',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: tokens.onSurface,
          ),
        ),
        const SizedBox(height: AisTheme.spacingSm),

        Text(
          'Select an invoice image or PDF to extract vendor, amounts, and line items automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.onSurfaceSecondary,
          ),
        ),
        const SizedBox(height: AisTheme.spacingXl),

        // Media Picker
        AisMediaPicker(
          allowedTypes: const [AisMediaType.image, AisMediaType.pdf],
          multiple: false,
          maxSizeBytes: 50 * 1024 * 1024, // 50MB
          label: 'Select Invoice',
          onFilesSelected: (files) {
            if (files.isNotEmpty) {
              setState(() => _selectedFile = files.first);
              _processFile(files.first);
            }
          },
        ),

        const SizedBox(height: AisTheme.spacingLg),

        // Provider selection
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Provider',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.onSurfaceSecondary,
                    ),
                  ),
                  // Setup button
                  TextButton.icon(
                    icon: Icon(Icons.settings, size: 16, color: tokens.actionPrimary.color),
                    label: Text(
                      'Setup',
                      style: TextStyle(fontSize: 12, color: tokens.actionPrimary.color),
                    ),
                    onPressed: () => _showAISettingsDialog(context, tokens),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AisTheme.spacingSm),
              SegmentedButton<AIProviderTier>(
                segments: AIProviderTier.values
                    .map((tier) => ButtonSegment(
                          value: tier,
                          label: Text(tier.displayName, style: const TextStyle(fontSize: 11)),
                          icon: Icon(tier.icon, size: 16),
                        ))
                    .toList(),
                selected: {_scanService.preferredProvider},
                onSelectionChanged: (selection) {
                  setState(() {
                    _scanService.preferredProvider = selection.first;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show AI Settings dialog with test connection functionality
  void _showAISettingsDialog(BuildContext context, AisTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => _AisDocScanSettingsDialog(tokens: tokens),
    );
  }

  Widget _buildProcessing(AisTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: LinearProgressIndicator(
              value: _scanService.progress,
              backgroundColor: tokens.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(tokens.actionPrimary.color),
            ),
          ),
          const SizedBox(height: AisTheme.spacingLg),
          Icon(
            _scanService.status == DocScanStatus.scanning
                ? Icons.document_scanner
                : Icons.psychology,
            size: 48,
            color: tokens.actionPrimary.color,
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Text(
            _scanService.status.displayName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Text(
            'Using ${_scanService.activeProvider.displayName}',
            style: TextStyle(
              color: tokens.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview(AisTokens tokens) {
    final result = _scanService.currentResult;
    if (result == null) return const SizedBox.shrink();

    // Check if we're in manual entry mode
    final isManualEntry = (result.rawOCRText == null || result.rawOCRText!.isEmpty) &&
        result.providerUsed == AIProviderTier.selfMapping;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manual entry notice
        if (isManualEntry)
          Container(
            margin: const EdgeInsets.only(bottom: AisTheme.spacingMd),
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            decoration: BoxDecoration(
              color: tokens.stateWarning.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              border: Border.all(color: tokens.stateWarning.color.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, size: 20, color: tokens.stateWarning.color),
                    const SizedBox(width: AisTheme.spacingSm),
                    Text(
                      'Manual Entry Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tokens.stateWarning.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AisTheme.spacingSm),
                Text(
                  'OCR is not available on this platform for images. Please fill in the fields below manually, or select Cloud AI provider and configure it in Settings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurface,
                  ),
                ),
                const SizedBox(height: AisTheme.spacingSm),
                Text(
                  'Tip: Tap the edit icon next to each field to enter values.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),

        // Status badge
        Row(
          children: [
            AisStateBadge(
              label: isManualEntry ? 'Manual Entry' : _scanService.status.displayName,
              type: isManualEntry ? AisStateType.info : _scanService.status.badgeType,
            ),
            const Spacer(),
            if (result.rawOCRText != null) ...[
              TextButton.icon(
                icon: const Icon(Icons.description, size: 16),
                label: const Text('Raw OCR'),
                onPressed: () => setState(() => _showRawOCR = !_showRawOCR),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.output, size: 16),
                label: const Text('View Full Output'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.actionPrimary.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AisDocScanOCROutputDialog(
                      result: result,
                      tokens: tokens,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: AisTheme.spacingMd),

        // Confidence bar
        _buildConfidenceBar(result.overallConfidence, tokens),
        const SizedBox(height: AisTheme.spacingMd),

        // Validation errors
        if (result.validationErrors.isNotEmpty) ...[
          _buildValidationErrors(result.validationErrors, tokens),
          const SizedBox(height: AisTheme.spacingMd),
        ],

        // Header Fields
        _buildSectionHeader('Invoice Details', Icons.description, tokens),
        const SizedBox(height: AisTheme.spacingSm),
        _buildHeaderFieldsGrid(result, tokens),
        const SizedBox(height: AisTheme.spacingLg),

        // Amount Fields
        _buildSectionHeader('Amounts', Icons.attach_money, tokens),
        const SizedBox(height: AisTheme.spacingSm),
        _buildAmountFieldsGrid(result, tokens),

        // Line Items
        if (result.lineItems.isNotEmpty) ...[
          const SizedBox(height: AisTheme.spacingLg),
          _buildSectionHeader('Line Items', Icons.list, tokens),
          const SizedBox(height: AisTheme.spacingSm),
          _buildLineItemsTable(result.lineItems, tokens),
        ],

        // Raw OCR
        if (_showRawOCR && result.rawOCRText != null) ...[
          const SizedBox(height: AisTheme.spacingLg),
          _buildRawOCRSection(result.rawOCRText!, tokens),
        ],
      ],
    );
  }

  Widget _buildRejected(AisTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cancel,
            size: 64,
            color: tokens.stateError.color,
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Text(
            'Document Rejected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Text(
            'This invoice has been rejected and will not be posted.',
            style: TextStyle(color: tokens.onSurfaceSecondary),
          ),
          const SizedBox(height: AisTheme.spacingLg),
          AisButton(
            label: 'Scan Another',
            type: AisButtonType.primary,
            onPressed: () {
              _scanService.reset();
              setState(() => _selectedFile = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildError(AisTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: tokens.stateError.color,
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Text(
            'Processing Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          if (_scanService.error != null) ...[
            const SizedBox(height: AisTheme.spacingSm),
            Text(
              _scanService.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.onSurfaceSecondary),
            ),
          ],
          const SizedBox(height: AisTheme.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AisButton(
                label: 'Try Again',
                type: AisButtonType.neutral,
                onPressed: () {
                  if (_selectedFile != null) {
                    _processFile(_selectedFile!);
                  }
                },
              ),
              const SizedBox(width: AisTheme.spacingMd),
              AisButton(
                label: 'Manual Entry',
                type: AisButtonType.primary,
                onPressed: () {
                  var result = DocScanResult(
                    sourceFileId: _selectedFile?.id ?? 'manual',
                    providerUsed: AIProviderTier.selfMapping,
                  );
                  result.status = DocScanStatus.review;
                  _scanService.currentResult = result;
                  _scanService.status = DocScanStatus.review;
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPosted(AisTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            size: 64,
            color: tokens.actionConfirm.color,
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Text(
            'Invoice Posted',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Text(
            'The AP entry has been created successfully.',
            style: TextStyle(color: tokens.onSurfaceSecondary),
          ),
          const SizedBox(height: AisTheme.spacingLg),
          AisButton(
            label: 'Scan Another',
            type: AisButtonType.primary,
            onPressed: () {
              _scanService.reset();
              setState(() => _selectedFile = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AisTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Row(
        children: [
          AisButton(
            label: 'Cancel',
            type: AisButtonType.neutral,
            onPressed: widget.onCancel,
          ),
          const Spacer(),
          if (_scanService.status == DocScanStatus.review ||
              _scanService.status == DocScanStatus.approved) ...[
            AisButton(
              label: 'Reject',
              type: AisButtonType.destructive,
              onPressed: _scanService.rejectResult,
            ),
            const SizedBox(width: AisTheme.spacingMd),
            AisButton(
              label: _scanService.status == DocScanStatus.approved ? 'Post' : 'Approve',
              type: AisButtonType.confirm,
              onPressed: () {
                if (_scanService.status == DocScanStatus.approved) {
                  if (_scanService.currentResult != null) {
                    widget.onComplete?.call(_scanService.currentResult!);
                  }
                } else {
                  _scanService.approveResult();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, AisTokens tokens) {
    return Row(
      children: [
        Icon(icon, size: 20, color: tokens.actionPrimary.color),
        const SizedBox(width: AisTheme.spacingSm),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBar(double confidence, AisTokens tokens) {
    final color = confidence >= 0.9
        ? tokens.actionConfirm.color
        : confidence >= 0.7
            ? tokens.stateWarning.color
            : tokens.stateError.color;

    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingSm),
      decoration: BoxDecoration(
        color: tokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
      ),
      child: Row(
        children: [
          Text(
            'Extraction Confidence',
            style: TextStyle(
              fontSize: 12,
              color: tokens.onSurfaceSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: AisTheme.spacingSm),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: tokens.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationErrors(List<String> errors, AisTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingSm),
      decoration: BoxDecoration(
        color: tokens.stateError.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors
            .map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error, size: 14, color: tokens.stateError.color),
                      const SizedBox(width: 4),
                      Text(
                        error,
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.stateError.color,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildHeaderFieldsGrid(DocScanResult result, AisTokens tokens) {
    return Wrap(
      spacing: AisTheme.spacingMd,
      runSpacing: AisTheme.spacingMd,
      children: [
        _EditableFieldRow(field: result.vendorName, tokens: tokens),
        _EditableFieldRow(field: result.invoiceNumber, tokens: tokens),
        _EditableFieldRow(field: result.invoiceDate, tokens: tokens),
        _EditableFieldRow(field: result.dueDate, tokens: tokens),
        _EditableFieldRow(field: result.poNumber, tokens: tokens),
        _EditableFieldRow(field: result.vendorAddress, tokens: tokens),
      ],
    );
  }

  Widget _buildAmountFieldsGrid(DocScanResult result, AisTokens tokens) {
    return Wrap(
      spacing: AisTheme.spacingMd,
      runSpacing: AisTheme.spacingMd,
      children: [
        _EditableFieldRow(field: result.subtotal, prefix: r'$', tokens: tokens),
        _EditableFieldRow(field: result.taxAmount, prefix: r'$', tokens: tokens),
        _EditableFieldRow(field: result.totalAmount, prefix: r'$', tokens: tokens),
      ],
    );
  }

  Widget _buildLineItemsTable(List<InvoiceLineItem> items, AisTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingSm),
            decoration: BoxDecoration(
              color: tokens.surfaceSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AisTheme.radiusMd)),
            ),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tokens.onSurfaceSecondary))),
                Expanded(child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tokens.onSurfaceSecondary))),
                SizedBox(width: 60, child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tokens.onSurfaceSecondary))),
                SizedBox(width: 80, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tokens.onSurfaceSecondary))),
                SizedBox(width: 80, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tokens.onSurfaceSecondary))),
              ],
            ),
          ),
          // Rows
          ...items.map((item) => Container(
                padding: const EdgeInsets.all(AisTheme.spacingSm),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: tokens.onSurface.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Text('${item.lineNumber}', style: TextStyle(fontSize: 12, color: tokens.onSurface))),
                    Expanded(child: Text(item.description, style: TextStyle(fontSize: 12, color: tokens.onSurface))),
                    SizedBox(width: 60, child: Text('${item.quantity.toInt()}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: tokens.onSurface))),
                    SizedBox(width: 80, child: Text('\$${item.unitPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: tokens.onSurface))),
                    SizedBox(width: 80, child: Text('\$${item.amount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: tokens.onSurface))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRawOCRSection(String text, AisTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Raw OCR Text',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: tokens.onSurfaceSecondary,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: tokens.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processFile(AisFileInfo file) async {
    await _scanService.processDocument(file);
    setState(() {});
  }
}

// MARK: - Editable Field Row

class _EditableFieldRow extends StatefulWidget {
  final ExtractedField field;
  final String prefix;
  final AisTokens tokens;

  const _EditableFieldRow({
    required this.field,
    this.prefix = '',
    required this.tokens,
  });

  @override
  State<_EditableFieldRow> createState() => _EditableFieldRowState();
}

class _EditableFieldRowState extends State<_EditableFieldRow> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.mappedValue);
  }

  @override
  void didUpdateWidget(_EditableFieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.field.mappedValue != _controller.text && !_isEditing) {
      _controller.text = widget.field.mappedValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _confidenceColor {
    switch (widget.field.confidenceLevel) {
      case ExtractionConfidence.high:
        return widget.tokens.actionConfirm.color;
      case ExtractionConfidence.medium:
        return widget.tokens.stateWarning.color;
      case ExtractionConfidence.low:
        return widget.tokens.stateError.color;
      case ExtractionConfidence.manual:
        return widget.tokens.stateInfo.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(AisTheme.spacingSm),
        decoration: BoxDecoration(
          color: widget.tokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(AisTheme.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label with confidence
            Row(
              children: [
                Text(
                  widget.field.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.tokens.onSurfaceSecondary,
                  ),
                ),
                if (widget.field.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: widget.tokens.stateError.color,
                    ),
                  ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _confidenceColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Value
            Row(
              children: [
                if (widget.prefix.isNotEmpty)
                  Text(
                    widget.prefix,
                    style: TextStyle(color: widget.tokens.onSurfaceSecondary),
                  ),
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          style: TextStyle(color: widget.tokens.onSurface, fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) {
                            widget.field.updateValue(_controller.text);
                            setState(() => _isEditing = false);
                          },
                        )
                      : Text(
                          widget.field.mappedValue.isEmpty ? '-' : widget.field.mappedValue,
                          style: TextStyle(
                            color: widget.field.mappedValue.isEmpty
                                ? widget.tokens.onSurfaceSecondary
                                : widget.tokens.onSurface,
                          ),
                        ),
                ),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check_circle : Icons.edit,
                    size: 18,
                    color: widget.tokens.actionPrimary.color,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    if (_isEditing) {
                      widget.field.updateValue(_controller.text);
                    }
                    setState(() => _isEditing = !_isEditing);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AI Settings Dialog with Test Connection
// ============================================================================

class _AisDocScanSettingsDialog extends StatefulWidget {
  final AisTokens tokens;

  const _AisDocScanSettingsDialog({required this.tokens});

  @override
  State<_AisDocScanSettingsDialog> createState() => _AisDocScanSettingsDialogState();
}

class _AisDocScanSettingsDialogState extends State<_AisDocScanSettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cloud LLM settings
  final _claudeApiKeyController = TextEditingController();
  final _chatgptApiKeyController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();

  // Local AI settings
  final _ollamaEndpointController = TextEditingController(text: 'http://localhost:11434');
  final _lmStudioEndpointController = TextEditingController(text: 'http://localhost:1234');
  bool _ollamaEnabled = false;
  bool _lmStudioEnabled = false;

  // Test connection state
  bool _testingCloud = false;
  bool _testingLocal = false;
  String? _cloudTestResult;
  String? _localTestResult;
  bool? _cloudTestSuccess;
  bool? _localTestSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _claudeApiKeyController.dispose();
    _chatgptApiKeyController.dispose();
    _geminiApiKeyController.dispose();
    _ollamaEndpointController.dispose();
    _lmStudioEndpointController.dispose();
    super.dispose();
  }

  Future<void> _testCloudConnection() async {
    setState(() {
      _testingCloud = true;
      _cloudTestResult = 'Testing connection...';
      _cloudTestSuccess = null;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    // Check API keys
    String result;
    bool success = false;

    if (_claudeApiKeyController.text.isNotEmpty) {
      if (_claudeApiKeyController.text.startsWith('sk-ant-')) {
        result = 'Claude API key format is valid';
        success = true;
      } else {
        result = 'Claude API key format is invalid (should start with sk-ant-)';
        success = false;
      }
    } else if (_chatgptApiKeyController.text.isNotEmpty) {
      if (_chatgptApiKeyController.text.startsWith('sk-')) {
        result = 'ChatGPT API key format is valid';
        success = true;
      } else {
        result = 'ChatGPT API key format is invalid (should start with sk-)';
        success = false;
      }
    } else if (_geminiApiKeyController.text.isNotEmpty) {
      if (_geminiApiKeyController.text.length > 20) {
        result = 'Gemini API key format is valid';
        success = true;
      } else {
        result = 'Gemini API key format is invalid (too short)';
        success = false;
      }
    } else {
      result = 'No API key configured';
      success = false;
    }

    if (mounted) {
      setState(() {
        _testingCloud = false;
        _cloudTestResult = result;
        _cloudTestSuccess = success;
      });
    }
  }

  Future<void> _testLocalConnection() async {
    setState(() {
      _testingLocal = true;
      _localTestResult = 'Testing connection...';
      _localTestSuccess = null;
    });

    String endpoint = '';
    if (_ollamaEnabled) {
      endpoint = _ollamaEndpointController.text;
    } else if (_lmStudioEnabled) {
      endpoint = _lmStudioEndpointController.text;
    }

    if (endpoint.isEmpty) {
      setState(() {
        _testingLocal = false;
        _localTestResult = 'No local AI endpoint configured';
        _localTestSuccess = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(endpoint);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(uri);
      final response = await request.close();
      client.close();

      if (mounted) {
        setState(() {
          _testingLocal = false;
          if (response.statusCode < 500) {
            _localTestResult = 'Connection successful! Status: ${response.statusCode}';
            _localTestSuccess = true;
          } else {
            _localTestResult = 'Server error: ${response.statusCode}';
            _localTestSuccess = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testingLocal = false;
          _localTestResult = 'Connection failed: ${e.toString().split(':').last.trim()}';
          _localTestSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.tokens.surfaceSecondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AisTheme.radiusMd),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: widget.tokens.actionPrimary.color),
                  const SizedBox(width: 8),
                  Text(
                    'AI Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.tokens.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: widget.tokens.actionPrimary.color,
              unselectedLabelColor: widget.tokens.onSurfaceSecondary,
              tabs: const [
                Tab(text: 'Cloud LLM', icon: Icon(Icons.cloud, size: 18)),
                Tab(text: 'Local AI', icon: Icon(Icons.computer, size: 18)),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCloudTab(),
                  _buildLocalTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: widget.tokens.onSurface.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.tokens.actionPrimary.color,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Save settings here
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Claude
          _buildApiKeyField('Claude (Anthropic)', _claudeApiKeyController, 'sk-ant-...'),
          const SizedBox(height: 16),

          // ChatGPT
          _buildApiKeyField('ChatGPT (OpenAI)', _chatgptApiKeyController, 'sk-...'),
          const SizedBox(height: 16),

          // Gemini
          _buildApiKeyField('Gemini (Google)', _geminiApiKeyController, 'AIza...'),
          const SizedBox(height: 24),

          // Test connection button
          Row(
            children: [
              ElevatedButton.icon(
                icon: _testingCloud
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wifi_tethering, size: 18),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.tokens.stateInfo.color,
                  foregroundColor: Colors.white,
                ),
                onPressed: _testingCloud ? null : _testCloudConnection,
              ),
              if (_cloudTestResult != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _cloudTestSuccess == true
                          ? widget.tokens.actionConfirm.color.withOpacity(0.1)
                          : _cloudTestSuccess == false
                              ? widget.tokens.stateError.color.withOpacity(0.1)
                              : widget.tokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _cloudTestSuccess == true
                              ? Icons.check_circle
                              : _cloudTestSuccess == false
                                  ? Icons.error
                                  : Icons.hourglass_empty,
                          size: 16,
                          color: _cloudTestSuccess == true
                              ? widget.tokens.actionConfirm.color
                              : _cloudTestSuccess == false
                                  ? widget.tokens.stateError.color
                                  : widget.tokens.onSurfaceSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _cloudTestResult!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _cloudTestSuccess == true
                                  ? widget.tokens.actionConfirm.color
                                  : _cloudTestSuccess == false
                                      ? widget.tokens.stateError.color
                                      : widget.tokens.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ollama
          _buildLocalProviderField(
            'Ollama',
            _ollamaEndpointController,
            _ollamaEnabled,
            (value) => setState(() => _ollamaEnabled = value),
          ),
          const SizedBox(height: 16),

          // LM Studio
          _buildLocalProviderField(
            'LM Studio',
            _lmStudioEndpointController,
            _lmStudioEnabled,
            (value) => setState(() => _lmStudioEnabled = value),
          ),
          const SizedBox(height: 24),

          // Test connection button
          Row(
            children: [
              ElevatedButton.icon(
                icon: _testingLocal
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wifi_tethering, size: 18),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.tokens.stateInfo.color,
                  foregroundColor: Colors.white,
                ),
                onPressed: (_testingLocal || (!_ollamaEnabled && !_lmStudioEnabled))
                    ? null
                    : _testLocalConnection,
              ),
              if (_localTestResult != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _localTestSuccess == true
                          ? widget.tokens.actionConfirm.color.withOpacity(0.1)
                          : _localTestSuccess == false
                              ? widget.tokens.stateError.color.withOpacity(0.1)
                              : widget.tokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _localTestSuccess == true
                              ? Icons.check_circle
                              : _localTestSuccess == false
                                  ? Icons.error
                                  : Icons.hourglass_empty,
                          size: 16,
                          color: _localTestSuccess == true
                              ? widget.tokens.actionConfirm.color
                              : _localTestSuccess == false
                                  ? widget.tokens.stateError.color
                                  : widget.tokens.onSurfaceSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _localTestResult!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _localTestSuccess == true
                                  ? widget.tokens.actionConfirm.color
                                  : _localTestSuccess == false
                                      ? widget.tokens.stateError.color
                                      : widget.tokens.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: widget.tokens.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: widget.tokens.onSurfaceSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalProviderField(
    String label,
    TextEditingController controller,
    bool enabled,
    ValueChanged<bool> onEnabledChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: enabled,
              onChanged: (value) => onEnabledChanged(value ?? false),
            ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: widget.tokens.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: 'Endpoint URL',
            hintStyle: TextStyle(color: widget.tokens.onSurfaceSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// OCR Output Dialog with Text/JSON tabs
// ============================================================================

class AisDocScanOCROutputDialog extends StatefulWidget {
  final DocScanResult result;
  final AisTokens tokens;

  const AisDocScanOCROutputDialog({
    super.key,
    required this.result,
    required this.tokens,
  });

  @override
  State<AisDocScanOCROutputDialog> createState() => _AisDocScanOCROutputDialogState();
}

class _AisDocScanOCROutputDialogState extends State<AisDocScanOCROutputDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _copiedText = false;
  bool _copiedJson = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _rawOCRText => widget.result.rawOCRText ?? 'No OCR text available';

  String get _jsonOutput {
    final Map<String, dynamic> output = {
      'id': widget.result.id,
      'sourceFileId': widget.result.sourceFileId,
      'scanDate': widget.result.scanDate.toIso8601String(),
      'providerUsed': widget.result.providerUsed.toString(),
      'processingTimeMs': widget.result.processingTimeMs,
      'status': widget.result.status.toString(),
      'fields': {
        'vendorName': {
          'value': widget.result.vendorName.mappedValue,
          'confidence': widget.result.vendorName.confidence,
        },
        'vendorAddress': {
          'value': widget.result.vendorAddress.mappedValue,
          'confidence': widget.result.vendorAddress.confidence,
        },
        'invoiceNumber': {
          'value': widget.result.invoiceNumber.mappedValue,
          'confidence': widget.result.invoiceNumber.confidence,
        },
        'invoiceDate': {
          'value': widget.result.invoiceDate.mappedValue,
          'confidence': widget.result.invoiceDate.confidence,
        },
        'dueDate': {
          'value': widget.result.dueDate.mappedValue,
          'confidence': widget.result.dueDate.confidence,
        },
        'poNumber': {
          'value': widget.result.poNumber.mappedValue,
          'confidence': widget.result.poNumber.confidence,
        },
        'subtotal': {
          'value': widget.result.subtotal.mappedValue,
          'confidence': widget.result.subtotal.confidence,
        },
        'taxAmount': {
          'value': widget.result.taxAmount.mappedValue,
          'confidence': widget.result.taxAmount.confidence,
        },
        'totalAmount': {
          'value': widget.result.totalAmount.mappedValue,
          'confidence': widget.result.totalAmount.confidence,
        },
        'currency': {
          'value': widget.result.currency.mappedValue,
          'confidence': widget.result.currency.confidence,
        },
      },
      'lineItems': widget.result.lineItems.map((item) => {
        'lineNumber': item.lineNumber,
        'description': item.description,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'amount': item.amount,
        'glAccountCode': item.glAccountCode,
        'costCenter': item.costCenter,
        'confidence': item.confidence,
      }).toList(),
      'rawOCRText': widget.result.rawOCRText,
    };

    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(output);
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _rawOCRText));
    setState(() => _copiedText = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedText = false);
    });
  }

  void _copyJson() {
    Clipboard.setData(ClipboardData(text: _jsonOutput));
    setState(() => _copiedJson = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedJson = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.tokens.surfaceSecondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AisTheme.radiusMd),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.document_scanner, color: widget.tokens.actionPrimary.color),
                  const SizedBox(width: 8),
                  Text(
                    'OCR Output',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.tokens.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.tokens.actionPrimary.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.result.processingTimeMs}ms',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.tokens.actionPrimary.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: widget.tokens.actionPrimary.color,
              unselectedLabelColor: widget.tokens.onSurfaceSecondary,
              tabs: const [
                Tab(text: 'Text', icon: Icon(Icons.text_snippet, size: 18)),
                Tab(text: 'JSON', icon: Icon(Icons.code, size: 18)),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Text tab
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.tokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _rawOCRText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: widget.tokens.onSurface,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        right: 24,
                        child: ElevatedButton.icon(
                          icon: Icon(_copiedText ? Icons.check : Icons.copy, size: 16),
                          label: Text(_copiedText ? 'Copied!' : 'Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _copiedText
                                ? widget.tokens.actionConfirm.color
                                : widget.tokens.actionPrimary.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: _copyText,
                        ),
                      ),
                    ],
                  ),
                  // JSON tab
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.tokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _jsonOutput,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: widget.tokens.onSurface,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        right: 24,
                        child: ElevatedButton.icon(
                          icon: Icon(_copiedJson ? Icons.check : Icons.copy, size: 16),
                          label: Text(_copiedJson ? 'Copied!' : 'Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _copiedJson
                                ? widget.tokens.actionConfirm.color
                                : widget.tokens.actionPrimary.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: _copyJson,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: widget.tokens.onSurface.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.tokens.actionPrimary.color,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

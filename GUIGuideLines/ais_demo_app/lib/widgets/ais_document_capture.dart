// =============================================================================
// ais_document_capture.dart
// AIS Document Capture - Integrated Media Picker + Document Scanner
// =============================================================================
//
// PURPOSE:
// A standalone, reusable widget that combines AISMediaPicker and AISDocScan
// into a single integrated document capture experience. This widget provides
// a complete workflow for capturing documents via file selection, camera, or
// clipboard, then processing them with OCR and AI-powered field extraction.
//
// USAGE:
// ```dart
// AisDocumentCapture(
//   documentType: AisDocumentType.invoice,
//   inputSources: [AisInputSource.files, AisInputSource.camera],
//   onDocumentCaptured: (result) {
//     // Handle the captured and processed document
//     print('Captured: ${result.invoiceNumber.mappedValue}');
//   },
//   onCancel: () => Navigator.pop(context),
// )
// ```
//
// FEATURES:
// - Unified document capture workflow
// - Multiple input sources (files, camera, clipboard)
// - AI-powered OCR and field extraction
// - Editable extracted fields with confidence indicators
// - Validation and approval workflow
// - Customizable document types (Invoice, Receipt, PO, etc.)
//
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../services/ai_settings.dart';
import '../services/ai_service.dart';
import 'ais_media_picker.dart';
import 'ais_doc_scan.dart';
import 'ais_button.dart';
import 'ais_state_badge.dart';

// MARK: - Document Types

/// Supported document types for capture
enum AisDocumentType {
  invoice('Invoice', Icons.receipt_long, 'Capture vendor invoices for AP processing'),
  receipt('Receipt', Icons.receipt, 'Capture expense receipts'),
  purchaseOrder('Purchase Order', Icons.shopping_cart, 'Capture purchase orders'),
  contract('Contract', Icons.description, 'Capture contract documents'),
  general('General Document', Icons.article, 'Capture any document type');

  final String displayName;
  final IconData icon;
  final String description;

  const AisDocumentType(this.displayName, this.icon, this.description);
}

/// Capture workflow state
enum AisCaptureState {
  selectSource,    // Initial: choose input source
  selectFile,      // Picking file/camera/clipboard
  processing,      // OCR and extraction in progress
  review,          // Review extracted fields
  approved,        // Document approved
  rejected,        // Document rejected
}

// MARK: - Document Capture Widget

/// Integrated document capture widget combining media picker and doc scanner
class AisDocumentCapture extends StatefulWidget {
  /// The type of document being captured
  final AisDocumentType documentType;

  /// Available input sources
  final List<AisInputSource> inputSources;

  /// Called when document is captured and approved
  final void Function(DocScanResult result)? onDocumentCaptured;

  /// Called when user cancels
  final VoidCallback? onCancel;

  /// Preferred AI provider for OCR
  final AIProviderTier preferredProvider;

  /// Whether to show the source selector initially
  final bool showSourceSelector;

  /// Maximum file size in bytes
  final int maxSizeBytes;

  /// Custom title
  final String? title;

  /// Custom subtitle
  final String? subtitle;

  const AisDocumentCapture({
    super.key,
    this.documentType = AisDocumentType.invoice,
    this.inputSources = const [
      AisInputSource.files,
      AisInputSource.camera,
      AisInputSource.clipboard,
    ],
    this.onDocumentCaptured,
    this.onCancel,
    this.preferredProvider = AIProviderTier.googleMLKit,
    this.showSourceSelector = true,
    this.maxSizeBytes = 50 * 1024 * 1024, // 50MB
    this.title,
    this.subtitle,
  });

  @override
  State<AisDocumentCapture> createState() => _AisDocumentCaptureState();
}

class _AisDocumentCaptureState extends State<AisDocumentCapture> {
  final DocScanService _scanService = DocScanService();
  late AISettingsService _aiSettingsService;
  AisCaptureState _captureState = AisCaptureState.selectSource;
  AisFileInfo? _selectedFile;
  AisInputSource? _selectedSource;

  @override
  void initState() {
    super.initState();
    _scanService.preferredProvider = widget.preferredProvider;

    // Initialize AI service for document processing
    _aiSettingsService = AISettingsService();
    _aiSettingsService.loadSettings().then((_) {
      _scanService.initializeAIService(_aiSettingsService);
    });

    // Skip source selection if only one source
    if (widget.inputSources.length == 1 && !widget.showSourceSelector) {
      _selectedSource = widget.inputSources.first;
      _captureState = AisCaptureState.selectFile;
    }
  }

  @override
  void dispose() {
    _scanService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusLg),
      ),
      child: Column(
        children: [
          _buildHeader(tokens),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(tokens),
            ),
          ),
          const Divider(height: 1),
          _buildFooter(tokens),
        ],
      ),
    );
  }

  Widget _buildHeader(AisTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingSm),
            decoration: BoxDecoration(
              color: tokens.actionPrimary.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AisTheme.radiusSm),
            ),
            child: Icon(
              widget.documentType.icon,
              color: tokens.actionPrimary.color,
              size: 24,
            ),
          ),
          const SizedBox(width: AisTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? 'Capture ${widget.documentType.displayName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.onSurface,
                  ),
                ),
                Text(
                  widget.subtitle ?? widget.documentType.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildStateIndicator(tokens),
        ],
      ),
    );
  }

  Widget _buildStateIndicator(AisTokens tokens) {
    // Check if we're in manual entry mode (review state with no OCR)
    final isManualEntry = _captureState == AisCaptureState.review &&
        _scanService.currentResult != null &&
        (_scanService.currentResult!.rawOCRText == null ||
         _scanService.currentResult!.rawOCRText!.isEmpty) &&
        _scanService.currentResult!.providerUsed == AIProviderTier.selfMapping;

    final (label, type) = switch (_captureState) {
      AisCaptureState.selectSource => ('Select Source', AisStateType.info),
      AisCaptureState.selectFile => ('Ready', AisStateType.info),
      AisCaptureState.processing => ('Processing', AisStateType.warning),
      AisCaptureState.review => isManualEntry
          ? ('Manual Entry', AisStateType.info)
          : ('Review', AisStateType.warning),
      AisCaptureState.approved => ('Approved', AisStateType.info),
      AisCaptureState.rejected => ('Rejected', AisStateType.error),
    };

    return AisStateBadge(label: label, type: type);
  }

  Widget _buildContent(AisTokens tokens) {
    switch (_captureState) {
      case AisCaptureState.selectSource:
        return _buildSourceSelector(tokens);
      case AisCaptureState.selectFile:
        return _buildFilePicker(tokens);
      case AisCaptureState.processing:
        return _buildProcessing(tokens);
      case AisCaptureState.review:
        return _buildReview(tokens);
      case AisCaptureState.approved:
        return _buildApproved(tokens);
      case AisCaptureState.rejected:
        return _buildRejected(tokens);
    }
  }

  Widget _buildSourceSelector(AisTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(AisTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose Input Source',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Text(
            'Select how you want to capture the ${widget.documentType.displayName.toLowerCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.onSurfaceSecondary),
          ),
          const SizedBox(height: AisTheme.spacingXl),
          Wrap(
            spacing: AisTheme.spacingMd,
            runSpacing: AisTheme.spacingMd,
            alignment: WrapAlignment.center,
            children: widget.inputSources.map((source) {
              return _buildSourceCard(source, tokens);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(AisInputSource source, AisTokens tokens) {
    final (icon, label, description) = switch (source) {
      AisInputSource.files => (
          Icons.folder_open,
          'Browse Files',
          'Select from device storage'
        ),
      AisInputSource.camera => (
          Icons.camera_alt,
          'Take Photo',
          'Capture with camera'
        ),
      AisInputSource.clipboard => (
          Icons.content_paste,
          'Paste Image',
          'From clipboard'
        ),
    };

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSource = source;
          _captureState = AisCaptureState.selectFile;
        });
      },
      borderRadius: BorderRadius.circular(AisTheme.radiusMd),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        decoration: BoxDecoration(
          color: tokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(AisTheme.radiusMd),
          border: Border.all(
            color: tokens.onSurface.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.actionPrimary.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: tokens.actionPrimary.color,
                size: 32,
              ),
            ),
            const SizedBox(height: AisTheme.spacingMd),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tokens.onSurface,
              ),
            ),
            const SizedBox(height: AisTheme.spacingXs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: tokens.onSurfaceSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(AisTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AisTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.documentType.icon,
            size: 64,
            color: tokens.actionPrimary.color,
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Text(
            'Select ${widget.documentType.displayName}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingXl),
          AisMediaPicker(
            allowedTypes: const [AisMediaType.image, AisMediaType.pdf, AisMediaType.text],
            multiple: false,
            maxSizeBytes: widget.maxSizeBytes,
            label: 'Select Document',
            inputSources: _selectedSource != null
                ? [_selectedSource!]
                : widget.inputSources,
            showSourceSelector: false,
            onFilesSelected: (files) {
              if (files.isNotEmpty) {
                _processFile(files.first);
              }
            },
          ),
          const SizedBox(height: AisTheme.spacingLg),
          // AI Provider selector
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            decoration: BoxDecoration(
              color: tokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Processing',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
                const SizedBox(height: AisTheme.spacingSm),
                SegmentedButton<AIProviderTier>(
                  segments: [
                    ButtonSegment(
                      value: AIProviderTier.selfMapping,
                      label: const Text('Manual', style: TextStyle(fontSize: 11)),
                      icon: const Icon(Icons.person, size: 16),
                    ),
                    ButtonSegment(
                      value: AIProviderTier.googleMLKit,
                      label: const Text('ML Kit', style: TextStyle(fontSize: 11)),
                      icon: const Icon(Icons.visibility, size: 16),
                    ),
                    ButtonSegment(
                      value: AIProviderTier.cloudLLM,
                      label: const Text('Cloud AI', style: TextStyle(fontSize: 11)),
                      icon: const Icon(Icons.cloud, size: 16),
                    ),
                  ],
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
      ),
    );
  }

  Widget _buildProcessing(AisTokens tokens) {
    return ListenableBuilder(
      listenable: _scanService,
      builder: (context, _) {
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
                style: TextStyle(color: tokens.onSurfaceSecondary),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: AisTheme.spacingMd),
                Text(
                  _selectedFile!.fileName,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReview(AisTokens tokens) {
    final result = _scanService.currentResult;
    if (result == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: _scanService,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AisTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File info
              if (_selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(AisTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 16,
                        color: tokens.actionPrimary.color,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      Expanded(
                        child: Text(
                          _selectedFile!.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${result.processingTimeMs}ms',
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.onSurfaceSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AisTheme.spacingMd),

              // Manual entry note when no OCR text available
              if ((result.rawOCRText == null || result.rawOCRText!.isEmpty) &&
                  result.providerUsed == AIProviderTier.selfMapping)
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
                        'OCR is not available on macOS/Windows/Linux for images. Please fill in the fields below manually, or configure Cloud AI in Settings for automatic extraction.',
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

              // Confidence indicator
              _buildConfidenceBar(result.overallConfidence, tokens),
              const SizedBox(height: AisTheme.spacingMd),

              // Validation errors
              if (result.validationErrors.isNotEmpty)
                _buildValidationErrors(result.validationErrors, tokens),

              // Header Fields
              _buildSectionHeader('${widget.documentType.displayName} Details', Icons.description, tokens),
              const SizedBox(height: AisTheme.spacingSm),
              _buildFieldsGrid(result.allHeaderFields, tokens),
              const SizedBox(height: AisTheme.spacingLg),

              // Amount Fields
              _buildSectionHeader('Amounts', Icons.attach_money, tokens),
              const SizedBox(height: AisTheme.spacingSm),
              _buildFieldsGrid(result.allAmountFields, tokens),

              // Line Items
              if (result.lineItems.isNotEmpty) ...[
                const SizedBox(height: AisTheme.spacingLg),
                _buildSectionHeader('Line Items (${result.lineItems.length})', Icons.list, tokens),
                const SizedBox(height: AisTheme.spacingSm),
                _buildLineItemsTable(result.lineItems, tokens),
              ],

              // View Details button (Text/JSON output)
              const SizedBox(height: AisTheme.spacingLg),
              Center(
                child: AisButton(
                  label: 'View Details (Text/JSON)',
                  type: AisButtonType.neutral,
                  customIcon: Icons.description,
                  onPressed: () => _showDetailsSheet(result, tokens),
                ),
              ),

              // Raw OCR (collapsible) - for debugging
              if (result.rawOCRText != null && result.rawOCRText!.isNotEmpty) ...[
                const SizedBox(height: AisTheme.spacingLg),
                ExpansionTile(
                  title: Text(
                    'Raw OCR Text (Debug)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: tokens.onSurface,
                    ),
                  ),
                  leading: Icon(Icons.text_snippet, color: tokens.actionPrimary.color),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AisTheme.spacingMd),
                      margin: const EdgeInsets.symmetric(horizontal: AisTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: tokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                      ),
                      child: SelectableText(
                        result.rawOCRText!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: tokens.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildApproved(AisTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: tokens.actionConfirm.color,
          ),
          const SizedBox(height: AisTheme.spacingMd),
          Text(
            '${widget.documentType.displayName} Captured',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          Text(
            'Document has been processed successfully.',
            style: TextStyle(color: tokens.onSurfaceSecondary),
          ),
          const SizedBox(height: AisTheme.spacingXl),
          AisButton(
            label: 'Capture Another',
            type: AisButtonType.primary,
            onPressed: _reset,
          ),
        ],
      ),
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
            'The document was not accepted.',
            style: TextStyle(color: tokens.onSurfaceSecondary),
          ),
          const SizedBox(height: AisTheme.spacingXl),
          AisButton(
            label: 'Try Again',
            type: AisButtonType.primary,
            onPressed: _reset,
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
          if (_captureState != AisCaptureState.selectSource)
            AisButton(
              label: 'Back',
              type: AisButtonType.neutral,
              onPressed: _goBack,
            )
          else
            AisButton(
              label: 'Cancel',
              type: AisButtonType.neutral,
              onPressed: widget.onCancel,
            ),
          const Spacer(),
          if (_captureState == AisCaptureState.review) ...[
            AisButton(
              label: 'Reject',
              type: AisButtonType.destructive,
              onPressed: () {
                _scanService.rejectResult();
                setState(() => _captureState = AisCaptureState.rejected);
              },
            ),
            const SizedBox(width: AisTheme.spacingMd),
            AisButton(
              label: 'Approve',
              type: AisButtonType.confirm,
              onPressed: _approveDocument,
            ),
          ],
        ],
      ),
    );
  }

  // Helper widgets

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
      margin: const EdgeInsets.only(bottom: AisTheme.spacingMd),
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

  Widget _buildFieldsGrid(List<ExtractedField> fields, AisTokens tokens) {
    return Wrap(
      spacing: AisTheme.spacingMd,
      runSpacing: AisTheme.spacingMd,
      children: fields.map((field) {
        return _EditableField(field: field, tokens: tokens);
      }).toList(),
    );
  }

  Widget _buildLineItemsTable(List<InvoiceLineItem> lineItems, AisTokens tokens) {
    final hasTaxCode = lineItems.any((item) => item.taxCode != null && item.taxCode!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: AisTheme.spacingMd,
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 48,
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: tokens.onSurface,
          ),
          dataTextStyle: TextStyle(
            fontSize: 12,
            color: tokens.onSurface,
          ),
          columns: [
            const DataColumn(label: Text('#')),
            const DataColumn(label: Text('Description')),
            const DataColumn(label: Text('Qty'), numeric: true),
            const DataColumn(label: Text('Unit Price'), numeric: true),
            const DataColumn(label: Text('Amount'), numeric: true),
            if (hasTaxCode) const DataColumn(label: Text('Tax')),
          ],
          rows: lineItems.map((item) {
            return DataRow(
              cells: [
                DataCell(Text('${item.lineNumber}')),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      item.description,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2))),
                DataCell(Text('\$${item.unitPrice.toStringAsFixed(2)}')),
                DataCell(
                  Text(
                    '\$${item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (hasTaxCode) DataCell(Text(item.taxCode ?? '-')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDetailsSheet(DocScanResult result, AisTokens tokens) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AisTheme.radiusLg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _DetailsSheet(
          doc: result,
          tokens: tokens,
          scrollController: scrollController,
        ),
      ),
    );
  }

  // Actions

  void _processFile(AisFileInfo file) async {
    setState(() {
      _selectedFile = file;
      _captureState = AisCaptureState.processing;
    });

    await _scanService.processDocument(file);

    setState(() {
      _captureState = AisCaptureState.review;
    });
  }

  void _approveDocument() {
    _scanService.approveResult();

    final result = _scanService.currentResult;
    if (result != null && result.validationErrors.isEmpty) {
      setState(() => _captureState = AisCaptureState.approved);
      widget.onDocumentCaptured?.call(result);
    } else {
      // Stay in review if validation fails
      setState(() {});
    }
  }

  void _goBack() {
    setState(() {
      switch (_captureState) {
        case AisCaptureState.selectFile:
          _captureState = AisCaptureState.selectSource;
          _selectedSource = null;
          break;
        case AisCaptureState.review:
          _captureState = AisCaptureState.selectFile;
          _scanService.reset();
          break;
        default:
          _captureState = AisCaptureState.selectSource;
          _selectedSource = null;
          _scanService.reset();
      }
    });
  }

  void _reset() {
    setState(() {
      _captureState = AisCaptureState.selectSource;
      _selectedFile = null;
      _selectedSource = null;
      _scanService.reset();
    });
  }
}

// MARK: - Editable Field Widget

class _EditableField extends StatefulWidget {
  final ExtractedField field;
  final AisTokens tokens;

  const _EditableField({
    required this.field,
    required this.tokens,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.mappedValue);
  }

  @override
  void didUpdateWidget(_EditableField oldWidget) {
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
                    style: TextStyle(color: widget.tokens.stateError.color),
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
            Row(
              children: [
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
                          onSubmitted: (_) => _saveEdit(),
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
                      _saveEdit();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveEdit() {
    widget.field.updateValue(_controller.text);
    setState(() => _isEditing = false);
  }
}

// MARK: - Details Sheet with Text/JSON tabs

class _DetailsSheet extends StatefulWidget {
  final DocScanResult doc;
  final AisTokens tokens;
  final ScrollController scrollController;

  const _DetailsSheet({
    required this.doc,
    required this.tokens,
    required this.scrollController,
  });

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  int _selectedTab = 0; // 0 = Text, 1 = JSON

  String get _textOutput {
    final doc = widget.doc;
    final lineItemsText = doc.lineItems.isNotEmpty
        ? doc.lineItems.map((item) =>
            '${item.description.padRight(30).substring(0, item.description.length > 30 ? 30 : item.description.length).padRight(30)}  ${item.quantity.toStringAsFixed(0).padLeft(3)} x \$${item.unitPrice.toStringAsFixed(2).padLeft(8)} = \$${item.amount.toStringAsFixed(2).padLeft(8)}${item.taxCode != null ? " ${item.taxCode}" : ""}'
          ).join('\n')
        : 'No line items detected';

    return '''==========================================
INVOICE
==========================================

Invoice Number: ${doc.invoiceNumber.mappedValue}
Invoice Date: ${doc.invoiceDate.mappedValue}

FROM:
${doc.vendorName.mappedValue}
${doc.vendorAddress.mappedValue.isNotEmpty ? doc.vendorAddress.mappedValue : '(No address)'}

------------------------------------------
ITEMS:
------------------------------------------
$lineItemsText

------------------------------------------
SUBTOTAL:                       \$${doc.subtotal.mappedValue.isNotEmpty ? doc.subtotal.mappedValue : doc.totalAmount.mappedValue}
TAX:                            \$${doc.taxAmount.mappedValue.isNotEmpty ? doc.taxAmount.mappedValue : '0.00'}
------------------------------------------
TOTAL DUE:                      \$${doc.totalAmount.mappedValue}
==========================================

Provider: ${doc.providerUsed.displayName}
Processing Time: ${doc.processingTimeMs}ms
''';
  }

  String get _jsonOutput {
    final doc = widget.doc;
    final lineItemsJson = doc.lineItems.map((item) => {
      'description': item.description,
      'quantity': item.quantity,
      'unitPrice': item.unitPrice,
      'amount': item.amount,
      if (item.taxCode != null) 'taxCode': item.taxCode,
    }).toList();

    final output = {
      'store': {
        'name': doc.vendorName.mappedValue,
        if (doc.vendorAddress.mappedValue.isNotEmpty)
          'address': doc.vendorAddress.mappedValue,
      },
      'transaction': {
        'invoiceNumber': doc.invoiceNumber.mappedValue,
        'date': doc.invoiceDate.mappedValue,
      },
      'items': lineItemsJson,
      'totals': {
        'subtotal': double.tryParse(doc.subtotal.mappedValue.replaceAll(',', '')) ?? 0.0,
        'tax': double.tryParse(doc.taxAmount.mappedValue.replaceAll(',', '')) ?? 0.0,
        'total': double.tryParse(doc.totalAmount.mappedValue.replaceAll(',', '')) ?? 0.0,
      },
      'extraction': {
        'provider': doc.providerUsed.displayName,
        'processingTimeMs': doc.processingTimeMs,
        'status': doc.status.displayName,
      },
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(output);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: AisTheme.spacingMd),
          decoration: BoxDecoration(
            color: tokens.onSurface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AisTheme.spacingLg),
          child: Row(
            children: [
              Text(
                'OCR Output',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy, color: tokens.onSurfaceSecondary),
                onPressed: () {
                  final content = _selectedTab == 0 ? _textOutput : _jsonOutput;
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard'),
                      backgroundColor: tokens.actionConfirm.color,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.close, color: tokens.onSurfaceSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Tab selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AisTheme.spacingLg),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AisTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? tokens.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                      ),
                      child: Text(
                        'Text',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 0
                              ? tokens.actionPrimary.color
                              : tokens.onSurfaceSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AisTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? tokens.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                      ),
                      child: Text(
                        'JSON',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 1
                              ? tokens.actionPrimary.color
                              : tokens.onSurfaceSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AisTheme.spacingMd),

        // Content
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(AisTheme.spacingLg),
            children: [
              Container(
                padding: const EdgeInsets.all(AisTheme.spacingMd),
                decoration: BoxDecoration(
                  color: tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                ),
                child: SelectableText(
                  _selectedTab == 0 ? _textOutput : _jsonOutput,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: tokens.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

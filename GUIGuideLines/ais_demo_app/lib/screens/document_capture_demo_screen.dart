import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/widgets.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// Demo screen for AisDocumentCapture widget
class DocumentCaptureDemoScreen extends StatefulWidget {
  const DocumentCaptureDemoScreen({super.key});

  @override
  State<DocumentCaptureDemoScreen> createState() => _DocumentCaptureDemoScreenState();
}

class _DocumentCaptureDemoScreenState extends State<DocumentCaptureDemoScreen> {
  final List<DocScanResult> _capturedDocuments = [];
  AisDocumentType _selectedDocType = AisDocumentType.invoice;
  bool _showCaptureWidget = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        title: const Text('Document Capture'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showCaptureWidget) {
              setState(() => _showCaptureWidget = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _showCaptureWidget
          ? _buildCaptureView(tokens)
          : _buildMainView(tokens),
    );
  }

  Widget _buildMainView(AisTokens tokens) {
    return Column(
      children: [
        // Header description
        Container(
          padding: const EdgeInsets.all(AisTheme.spacingLg),
          decoration: BoxDecoration(
            color: tokens.surfaceSecondary,
            border: Border(
              bottom: BorderSide(color: tokens.onSurface.withOpacity(0.1)),
            ),
          ),
          child: Text(
            'Integrated document capture combining AISMediaPicker and AISDocScan with OCR-powered field extraction.',
            style: TextStyle(
              color: tokens.onSurfaceSecondary,
            ),
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AisTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document Type Selector
                _buildSection(
                  tokens,
                  title: 'Document Type',
                  child: Wrap(
                    spacing: AisTheme.spacingMd,
                    runSpacing: AisTheme.spacingMd,
                    children: AisDocumentType.values.map((type) {
                      final isSelected = _selectedDocType == type;
                      return InkWell(
                        onTap: () => setState(() => _selectedDocType = type),
                        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AisTheme.spacingMd,
                            vertical: AisTheme.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tokens.actionPrimary.color.withOpacity(0.1)
                                : tokens.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                            border: Border.all(
                              color: isSelected
                                  ? tokens.actionPrimary.color
                                  : tokens.onSurface.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.icon,
                                size: 20,
                                color: isSelected
                                    ? tokens.actionPrimary.color
                                    : tokens.onSurfaceSecondary,
                              ),
                              const SizedBox(width: AisTheme.spacingSm),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? tokens.actionPrimary.color
                                      : tokens.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AisTheme.spacingXl),

                // Capture Button
                Center(
                  child: AisButton(
                    label: 'Capture ${_selectedDocType.displayName}',
                    type: AisButtonType.primary,
                    onPressed: () => setState(() => _showCaptureWidget = true),
                  ),
                ),
                const SizedBox(height: AisTheme.spacingXl),

                // Captured Documents
                if (_capturedDocuments.isNotEmpty) ...[
                  _buildSection(
                    tokens,
                    title: 'Captured Documents (${_capturedDocuments.length})',
                    child: Column(
                      children: _capturedDocuments.reversed.map((doc) {
                        return _buildDocumentCard(doc, tokens);
                      }).toList(),
                    ),
                  ),
                ],

                // Features Section
                _buildSection(
                  tokens,
                  title: 'Features',
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        tokens,
                        icon: Icons.merge_type,
                        title: 'Integrated Workflow',
                        description: 'Combines AISMediaPicker and AISDocScan into a single widget',
                      ),
                      _buildFeatureItem(
                        tokens,
                        icon: Icons.input,
                        title: 'Multiple Input Sources',
                        description: 'Supports file picker, camera capture, and clipboard paste',
                      ),
                      _buildFeatureItem(
                        tokens,
                        icon: Icons.psychology,
                        title: 'AI-Powered OCR',
                        description: 'Google ML Kit on-device text recognition with field extraction',
                      ),
                      _buildFeatureItem(
                        tokens,
                        icon: Icons.edit,
                        title: 'Editable Fields',
                        description: 'Review and edit extracted values with confidence indicators',
                      ),
                      _buildFeatureItem(
                        tokens,
                        icon: Icons.check_circle,
                        title: 'Validation Workflow',
                        description: 'Built-in validation, approval, and rejection handling',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AisTheme.spacingXl),

                // Usage Example
                _buildSection(
                  tokens,
                  title: 'Usage Example',
                  child: Container(
                    padding: const EdgeInsets.all(AisTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: tokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                    ),
                    child: SelectableText(
                      '''AisDocumentCapture(
  documentType: AisDocumentType.invoice,
  inputSources: [
    AisInputSource.files,
    AisInputSource.camera,
    AisInputSource.clipboard,
  ],
  preferredProvider: AIProviderTier.googleMLKit,
  onDocumentCaptured: (result) {
    // Handle captured document
    print('Invoice: \${result.invoiceNumber.mappedValue}');
    print('Amount: \${result.totalAmount.mappedValue}');

    // Post to accounting system
    viewModel.createAPEntry(result);
  },
  onCancel: () => Navigator.pop(context),
)''',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: tokens.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureView(AisTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(AisTheme.spacingLg),
      child: AisDocumentCapture(
              documentType: _selectedDocType,
              inputSources: const [
                AisInputSource.files,
                AisInputSource.camera,
                AisInputSource.clipboard,
              ],
              preferredProvider: AIProviderTier.googleMLKit,
              onDocumentCaptured: (result) {
                setState(() {
                  _capturedDocuments.add(result);
                  _showCaptureWidget = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_selectedDocType.displayName} captured successfully!'),
                    backgroundColor: tokens.actionConfirm.color,
                  ),
                );
              },
        onCancel: () => setState(() => _showCaptureWidget = false),
      ),
    );
  }

  Widget _buildSection(
    AisTokens tokens, {
    required String title,
    required Widget child,
  }) {
    return Column(
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
        const SizedBox(height: AisTheme.spacingMd),
        child,
      ],
    );
  }

  Widget _buildFeatureItem(
    AisTokens tokens, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AisTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingSm),
            decoration: BoxDecoration(
              color: tokens.actionPrimary.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AisTheme.radiusSm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: tokens.actionPrimary.color,
            ),
          ),
          const SizedBox(width: AisTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tokens.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildDocumentCard(DocScanResult doc, AisTokens tokens) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.only(bottom: AisTheme.spacingMd),
          padding: const EdgeInsets.all(AisTheme.spacingMd),
          decoration: BoxDecoration(
            color: tokens.surfaceSecondary,
            borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: tokens.actionPrimary.color,
                    size: 20,
                  ),
                  const SizedBox(width: AisTheme.spacingSm),
                  Expanded(
                    child: Text(
                      doc.invoiceNumber.mappedValue.isNotEmpty
                          ? 'Invoice #${doc.invoiceNumber.mappedValue}'
                          : 'Document ${doc.id.substring(0, 8)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tokens.onSurface,
                      ),
                    ),
                  ),
                  AisStateBadge(
                    label: doc.status.displayName,
                    type: doc.status.badgeType,
                  ),
                ],
              ),
              const SizedBox(height: AisTheme.spacingSm),
              Wrap(
                spacing: AisTheme.spacingLg,
                runSpacing: AisTheme.spacingSm,
                children: [
                  if (doc.vendorName.mappedValue.isNotEmpty)
                    _buildDocField('Vendor', doc.vendorName.mappedValue, tokens),
                  if (doc.invoiceDate.mappedValue.isNotEmpty)
                    _buildDocField('Date', doc.invoiceDate.mappedValue, tokens),
                  if (doc.totalAmount.mappedValue.isNotEmpty)
                    _buildDocField('Total', '\$${doc.totalAmount.mappedValue}', tokens),
                ],
              ),

              // Line Items Section
              if (doc.lineItems.isNotEmpty) ...[
                const SizedBox(height: AisTheme.spacingSm),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: AisTheme.spacingSm),
                  title: Text(
                    'Line Items (${doc.lineItems.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.actionPrimary.color,
                    ),
                  ),
                  leading: Icon(Icons.list, size: 18, color: tokens.actionPrimary.color),
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AisTheme.spacingSm,
                              vertical: AisTheme.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.onSurface.withOpacity(0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AisTheme.radiusSm),
                                topRight: Radius.circular(AisTheme.radiusSm),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.onSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    'Qty',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.onSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'Amount',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Line items
                          ...doc.lineItems.map((item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AisTheme.spacingSm,
                              vertical: AisTheme.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: tokens.onSurface.withOpacity(0.05),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tokens.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tokens.onSurfaceSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    '\$${item.amount.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AisTheme.spacingSm),
              Row(
                children: [
                  Icon(
                    doc.providerUsed.icon,
                    size: 14,
                    color: tokens.onSurfaceSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Processed with ${doc.providerUsed.displayName} in ${doc.processingTimeMs}ms',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.onSurfaceSecondary,
                      ),
                    ),
                  ),
                  // View Details button
                  InkWell(
                    onTap: () => _showDocumentDetails(doc, tokens),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description,
                          size: 12,
                          color: tokens.actionPrimary.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tokens.actionPrimary.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentDetails(DocScanResult doc, AisTokens tokens) {
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
        builder: (context, scrollController) => _DocumentDetailsSheet(
          doc: doc,
          tokens: tokens,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Widget _buildDocField(String label, String value, AisTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: tokens.onSurfaceSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: tokens.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Document Details Sheet with Text/JSON tabs
class _DocumentDetailsSheet extends StatefulWidget {
  final DocScanResult doc;
  final AisTokens tokens;
  final ScrollController scrollController;

  const _DocumentDetailsSheet({
    required this.doc,
    required this.tokens,
    required this.scrollController,
  });

  @override
  State<_DocumentDetailsSheet> createState() => _DocumentDetailsSheetState();
}

class _DocumentDetailsSheetState extends State<_DocumentDetailsSheet> {
  int _selectedTab = 0; // 0 = Text, 1 = JSON

  String get _textOutput {
    final doc = widget.doc;
    final lineItemsText = doc.lineItems.isNotEmpty
        ? doc.lineItems.map((item) =>
            '${item.description.padRight(30).substring(0, 30)}  ${item.quantity.toStringAsFixed(0).padLeft(3)} x \$${item.unitPrice.toStringAsFixed(2).padLeft(8)} = \$${item.amount.toStringAsFixed(2).padLeft(8)}${item.taxCode != null ? " ${item.taxCode}" : ""}'
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

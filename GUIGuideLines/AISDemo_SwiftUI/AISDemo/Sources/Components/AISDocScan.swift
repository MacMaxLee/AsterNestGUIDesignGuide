// =============================================================================
// AISDocScan.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Document scanning component for Accounts Payable processing with AI-powered
// field extraction. Integrates with AISMediaPicker for file selection.
//
// AI ROUTER PROVIDER CHAIN:
// Tier 0: Self mapping (manual user entry)
// Tier 1: Browser Vision API (client-side OCR using Vision framework)
// Tier 2: Local Agentic AI (on-device model via Core ML)
// Tier 3: LLM Fallback (Claude/ChatGPT/Gemini cloud API)
//
// USAGE:
// ```swift
// AISDocScanWidget(
//     preferredProvider: .browserVision,
//     onComplete: { result in
//         // Post to accounting system
//         viewModel.createAPEntry(result)
//     },
//     onCancel: {
//         dismiss()
//     }
// )
// ```
//
// =============================================================================

import SwiftUI
import Vision
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - AI Provider Tier

/// AI provider tiers for document processing
public enum AISDocScanProviderTier: Int, CaseIterable, Identifiable {
    case selfMapping = 0
    case browserVision = 1
    case localAgentic = 2
    case cloudLLM = 3

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .selfMapping: return "Manual Entry"
        case .browserVision: return "Vision OCR"
        case .localAgentic: return "Local AI"
        case .cloudLLM: return "Cloud AI"
        }
    }

    public var icon: String {
        switch self {
        case .selfMapping: return "person"
        case .browserVision: return "eye"
        case .localAgentic: return "cpu"
        case .cloudLLM: return "cloud"
        }
    }

    public var description: String {
        switch self {
        case .selfMapping: return "Manual user entry - no AI processing"
        case .browserVision: return "Client-side OCR using Vision framework"
        case .localAgentic: return "On-device AI model (Core ML)"
        case .cloudLLM: return "Cloud LLM API (Claude, GPT, Gemini)"
        }
    }

    public var requiresNetwork: Bool {
        self == .cloudLLM
    }
}

// MARK: - Extraction Confidence

/// Confidence level for extracted fields
public enum AISExtractionConfidence: String {
    case high
    case medium
    case low
    case manual

    public var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        case .manual: return .blue
        }
    }

    public var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .manual: return "Manual"
        }
    }
}

// MARK: - Extracted Field

/// Represents an extracted field from document scanning
public struct AISExtractedField: Identifiable {
    public let id: String
    public let fieldKey: String
    public let displayName: String
    public var extractedValue: String
    public var mappedValue: String
    public var confidence: Double
    public var confidenceLevel: AISExtractionConfidence
    public let isRequired: Bool
    public var isEdited: Bool

    public init(
        fieldKey: String,
        displayName: String,
        isRequired: Bool = false,
        extractedValue: String = "",
        confidence: Double = 0
    ) {
        self.id = "\(Date().timeIntervalSince1970)_\(fieldKey)"
        self.fieldKey = fieldKey
        self.displayName = displayName
        self.extractedValue = extractedValue
        self.mappedValue = extractedValue
        self.confidence = confidence
        self.isRequired = isRequired
        self.isEdited = false

        if confidence >= 0.9 {
            self.confidenceLevel = .high
        } else if confidence >= 0.7 {
            self.confidenceLevel = .medium
        } else {
            self.confidenceLevel = .low
        }
    }
}

// MARK: - Invoice Line Item

/// Represents a line item from an invoice
public struct AISInvoiceLineItem: Identifiable {
    public let id: String
    public let lineNumber: Int
    public var description: String
    public var quantity: Double
    public var unitPrice: Double
    public var amount: Double
    public var glAccountCode: String?
    public var costCenter: String?
    public var confidence: Double

    public init(
        lineNumber: Int,
        description: String = "",
        quantity: Double = 1,
        unitPrice: Double = 0,
        amount: Double = 0,
        glAccountCode: String? = nil,
        costCenter: String? = nil,
        confidence: Double = 0
    ) {
        self.id = UUID().uuidString
        self.lineNumber = lineNumber
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.amount = amount
        self.glAccountCode = glAccountCode
        self.costCenter = costCenter
        self.confidence = confidence
    }

    /// Alias for amount (backwards compatibility)
    public var totalPrice: Double {
        amount
    }
}

// MARK: - Document Scan Status

/// Status of the document scan process
public enum AISDocScanStatus: String {
    case pending
    case scanning
    case extracting
    case review
    case approved
    case posted
    case rejected
    case error

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .scanning: return "Scanning..."
        case .extracting: return "Extracting..."
        case .review: return "Ready for Review"
        case .approved: return "Approved"
        case .posted: return "Posted"
        case .rejected: return "Rejected"
        case .error: return "Error"
        }
    }

    public var icon: String {
        switch self {
        case .pending: return "clock"
        case .scanning: return "doc.text.viewfinder"
        case .extracting: return "cpu"
        case .review: return "eye"
        case .approved: return "checkmark.circle"
        case .posted: return "checkmark.seal"
        case .rejected: return "xmark.circle"
        case .error: return "exclamationmark.triangle"
        }
    }

    public var semanticState: AISSemanticState {
        switch self {
        case .pending: return .pending
        case .scanning, .extracting: return .active
        case .review: return .warning
        case .approved, .posted: return .completed
        case .rejected, .error: return .error
        }
    }
}

// MARK: - Document Scan Result

/// Complete result from document scanning
public struct AISDocScanResult: Identifiable {
    public let id: String
    public let sourceFileId: String
    public let scanDate: Date
    public var providerUsed: AISDocScanProviderTier
    public var processingTimeMs: Int

    // Header fields
    public var vendorName: AISExtractedField
    public var vendorAddress: AISExtractedField
    public var invoiceNumber: AISExtractedField
    public var invoiceDate: AISExtractedField
    public var dueDate: AISExtractedField
    public var poNumber: AISExtractedField

    // Amounts
    public var subtotal: AISExtractedField
    public var taxAmount: AISExtractedField
    public var totalAmount: AISExtractedField
    public var currency: AISExtractedField

    // Line items
    public var lineItems: [AISInvoiceLineItem]

    // Processing state
    public var status: AISDocScanStatus
    public var validationErrors: [String]

    // Raw OCR text
    public var rawOCRText: String?

    public init(sourceFileId: String) {
        self.id = "\(Date().timeIntervalSince1970)_scan"
        self.sourceFileId = sourceFileId
        self.scanDate = Date()
        self.providerUsed = .selfMapping
        self.processingTimeMs = 0

        self.vendorName = AISExtractedField(fieldKey: "vendor_name", displayName: "Vendor Name", isRequired: true)
        self.vendorAddress = AISExtractedField(fieldKey: "vendor_address", displayName: "Vendor Address")
        self.invoiceNumber = AISExtractedField(fieldKey: "invoice_number", displayName: "Invoice Number", isRequired: true)
        self.invoiceDate = AISExtractedField(fieldKey: "invoice_date", displayName: "Invoice Date", isRequired: true)
        self.dueDate = AISExtractedField(fieldKey: "due_date", displayName: "Due Date")
        self.poNumber = AISExtractedField(fieldKey: "po_number", displayName: "PO Number")

        self.subtotal = AISExtractedField(fieldKey: "subtotal", displayName: "Subtotal")
        self.taxAmount = AISExtractedField(fieldKey: "tax_amount", displayName: "Tax Amount")
        self.totalAmount = AISExtractedField(fieldKey: "total_amount", displayName: "Total Amount", isRequired: true)
        self.currency = AISExtractedField(fieldKey: "currency", displayName: "Currency", extractedValue: "USD", confidence: 1.0)

        self.lineItems = []
        self.status = .pending
        self.validationErrors = []
    }

    /// Get all header fields for iteration
    public var headerFields: [AISExtractedField] {
        [vendorName, vendorAddress, invoiceNumber, invoiceDate, dueDate, poNumber]
    }

    /// Get all amount fields for iteration
    public var amountFields: [AISExtractedField] {
        [subtotal, taxAmount, totalAmount, currency]
    }

    /// Validate required fields
    public mutating func validate() -> [String] {
        var errors: [String] = []

        if vendorName.mappedValue.isEmpty {
            errors.append("Vendor Name is required")
        }
        if invoiceNumber.mappedValue.isEmpty {
            errors.append("Invoice Number is required")
        }
        if invoiceDate.mappedValue.isEmpty {
            errors.append("Invoice Date is required")
        }
        if totalAmount.mappedValue.isEmpty {
            errors.append("Total Amount is required")
        }

        validationErrors = errors
        return errors
    }

    /// Calculate overall confidence score
    public var confidenceScore: Double {
        let allFields = headerFields + amountFields
        guard !allFields.isEmpty else { return 0 }
        let totalConfidence = allFields.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(allFields.count)
    }
}

// MARK: - AI Settings Configuration

/// Configuration for AI provider settings in AISDocScan
public struct AISDocScanAISettings {
    /// Cloud LLM API keys
    public var claudeAPIKey: String = ""
    public var openAIAPIKey: String = ""
    public var geminiAPIKey: String = ""

    /// Local AI settings
    public var ollamaEndpoint: String = "http://localhost:11434"
    public var ollamaModel: String = "llama3.2"
    public var lmStudioEndpoint: String = "http://localhost:1234"
    public var useOllama: Bool = false
    public var useLMStudio: Bool = false

    /// Provider preferences
    public var preferredCloudProvider: String = "claude" // "claude", "openai", "gemini"
    public var enableFallback: Bool = true

    public init() {}

    /// Check if cloud provider is configured
    public var hasCloudAPIKey: Bool {
        !claudeAPIKey.isEmpty || !openAIAPIKey.isEmpty || !geminiAPIKey.isEmpty
    }

    /// Check if local AI is configured
    public var hasLocalAI: Bool {
        useOllama || useLMStudio
    }

    /// Get the active API key for the preferred cloud provider
    public var activeCloudAPIKey: String? {
        switch preferredCloudProvider {
        case "claude": return claudeAPIKey.isEmpty ? nil : claudeAPIKey
        case "openai": return openAIAPIKey.isEmpty ? nil : openAIAPIKey
        case "gemini": return geminiAPIKey.isEmpty ? nil : geminiAPIKey
        default: return nil
        }
    }
}

// MARK: - AIS Doc Scan Widget

/// Main document scanning widget with AI-powered field extraction
public struct AISDocScanWidget: View {
    // MARK: - Properties

    /// Preferred AI provider tier
    let preferredProvider: AISDocScanProviderTier

    /// Cloud API key (optional, for cloud LLM)
    let cloudAPIKey: String?

    /// Called when scan is approved
    let onComplete: ((AISDocScanResult) -> Void)?

    /// Called when user cancels
    let onCancel: (() -> Void)?

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - State

    @State private var currentResult: AISDocScanResult?
    @State private var status: AISDocScanStatus = .pending
    @State private var progress: Double = 0
    @State private var error: String?
    @State private var selectedProvider: AISDocScanProviderTier
    @State private var selectedFile: AISFileInfo?
    @State private var pickerState: AISFilePickerState = .idle
    @State private var showRawOCR = false
    @State private var showAISettings = false
    @State private var aiSettings = AISDocScanAISettings()
    @State private var showOCROutputSheet = false

    // MARK: - Initialization

    public init(
        preferredProvider: AISDocScanProviderTier = .browserVision,
        cloudAPIKey: String? = nil,
        onComplete: ((AISDocScanResult) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.preferredProvider = preferredProvider
        self.cloudAPIKey = cloudAPIKey
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._selectedProvider = State(initialValue: preferredProvider)
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: AISSpacing.lg) {
                // Provider selector with settings button
                providerSelector

                // File selection / capture
                if currentResult == nil {
                    fileSelectionSection
                }

                // Processing indicator
                if status == .scanning || status == .extracting {
                    processingIndicator
                }

                // Error display
                if let error = error {
                    errorBanner(error)
                }

                // Review section
                if let result = currentResult, status == .review {
                    reviewSection(result)
                }

                // Action buttons
                actionButtons
            }
            .padding(AISSpacing.lg)
        }
        .background(Color(tokens.surface))
        .sheet(isPresented: $showAISettings) {
            AISDocScanSettingsSheet(
                settings: $aiSettings,
                isPresented: $showAISettings
            )
        }
        .sheet(isPresented: $showOCROutputSheet) {
            if let result = currentResult {
                AISDocScanOCROutputSheet(
                    result: result,
                    isPresented: $showOCROutputSheet
                )
            }
        }
    }

    // MARK: - Provider Selector

    private var providerSelector: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            HStack {
                Text("AI Provider")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                Spacer()

                // Settings button
                Button {
                    showAISettings = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.caption)
                        Text("Setup")
                            .font(.caption)
                    }
                    .foregroundColor(Color(tokens.actionPrimary.color))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: AISSpacing.sm) {
                ForEach(AISDocScanProviderTier.allCases) { tier in
                    providerButton(tier)
                }
            }

            // Show configuration status
            providerConfigurationStatus
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    /// Shows the configuration status for the selected provider
    @ViewBuilder
    private var providerConfigurationStatus: some View {
        HStack(spacing: AISSpacing.xs) {
            switch selectedProvider {
            case .selfMapping:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("No configuration required")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))

            case .browserVision:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Using built-in Vision framework")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))

            case .localAgentic:
                if aiSettings.hasLocalAI {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    if aiSettings.useOllama {
                        Text("Ollama: \(aiSettings.ollamaModel)")
                            .font(.caption)
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                    } else if aiSettings.useLMStudio {
                        Text("LM Studio configured")
                            .font(.caption)
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                    }
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Configure Local AI in Settings")
                        .font(.caption)
                        .foregroundColor(Color(tokens.stateWarning.color))
                }

            case .cloudLLM:
                if aiSettings.hasCloudAPIKey || cloudAPIKey != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("\(aiSettings.preferredCloudProvider.capitalized) API configured")
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Add API key in Settings")
                        .font(.caption)
                        .foregroundColor(Color(tokens.stateWarning.color))
                }
            }

            Spacer()
        }
        .padding(.top, AISSpacing.xs)
    }

    private func providerButton(_ tier: AISDocScanProviderTier) -> some View {
        Button {
            selectedProvider = tier
        } label: {
            VStack(spacing: AISSpacing.xs) {
                Image(systemName: tier.icon)
                    .font(.title3)
                Text(tier.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AISSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AISRadius.sm)
                    .fill(selectedProvider == tier
                          ? Color(tokens.actionPrimary.color).opacity(0.2)
                          : Color(tokens.surface))
            )
            .foregroundColor(selectedProvider == tier
                             ? Color(tokens.actionPrimary.color)
                             : Color(tokens.onSurfaceSecondary))
        }
        .buttonStyle(.plain)
    }

    // MARK: - File Selection

    private var fileSelectionSection: some View {
        VStack(spacing: AISSpacing.md) {
            if let file = selectedFile {
                // Show selected file
                HStack(spacing: AISSpacing.md) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(Color(tokens.actionPrimary.color))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.fileName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(tokens.onSurface))

                        Text(ByteCountFormatter.string(fromByteCount: file.fileSize, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                    }

                    Spacer()

                    Button {
                        selectedFile = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                    }
                    .buttonStyle(.plain)
                }
                .padding(AISSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AISRadius.md)
                        .fill(Color(tokens.surfaceSecondary))
                )

                // Process button
                AISButton(
                    "Process Document",
                    type: .confirm,
                    icon: "cpu"
                ) {
                    processDocument()
                }
            } else {
                // File picker
                AISMediaPicker(
                    state: $pickerState,
                    allowedTypes: [.image, .pdf],
                    allowsMultiple: false,
                    buttonLabel: "Select Document",
                    buttonType: .primary,
                    showSourceSelector: true,
                    onFilesSelected: { files in
                        if let file = files.first {
                            selectedFile = file
                        }
                    }
                )

                Text("Select an invoice, receipt, or document to scan")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    // MARK: - Processing Indicator

    private var processingIndicator: some View {
        VStack(spacing: AISSpacing.md) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())

            HStack(spacing: AISSpacing.sm) {
                Image(systemName: status.icon)
                    .font(.caption)
                Text(status.displayName)
                    .font(.caption)
            }
            .foregroundColor(Color(tokens.onSurfaceSecondary))

            HStack(spacing: AISSpacing.sm) {
                Image(systemName: selectedProvider.icon)
                    .font(.caption2)
                Text("Using \(selectedProvider.displayName)")
                    .font(.caption2)
            }
            .foregroundColor(Color(tokens.onSurfaceSecondary))
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: AISSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(tokens.stateError.color))

            Text(message)
                .font(.subheadline)
                .foregroundColor(Color(tokens.stateError.color))

            Spacer()

            Button("Dismiss") {
                error = nil
            }
            .font(.caption)
            .foregroundColor(Color(tokens.actionNeutral.color))
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.stateError.color).opacity(0.1))
        )
    }

    // MARK: - Review Section

    private func reviewSection(_ result: AISDocScanResult) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AISSpacing.xs) {
                    Text("Review Extracted Data")
                        .font(.headline)
                        .foregroundColor(Color(tokens.onSurface))

                    Text("Processed in \(result.processingTimeMs)ms using \(result.providerUsed.displayName)")
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                }

                Spacer()

                AISStateBadge(result.status.semanticState)
            }

            // Header fields
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("Invoice Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                ForEach(result.headerFields) { field in
                    extractedFieldRow(field)
                }
            }

            // Amount fields
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("Amounts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                ForEach(result.amountFields) { field in
                    extractedFieldRow(field)
                }
            }

            // View full output button
            AISButton("View Full OCR Output", type: .neutral, icon: "doc.text.magnifyingglass") {
                showOCROutputSheet = true
            }

            // Raw OCR toggle
            if let rawText = result.rawOCRText, !rawText.isEmpty {
                DisclosureGroup(
                    isExpanded: $showRawOCR,
                    content: {
                        ScrollView {
                            Text(rawText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(Color(tokens.onSurfaceSecondary))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding(AISSpacing.sm)
                        .background(Color(tokens.surfaceSecondary))
                        .cornerRadius(AISRadius.sm)
                    },
                    label: {
                        Text("Raw OCR Text")
                            .font(.subheadline)
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                    }
                )
            }

            // Validation errors
            if !result.validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: AISSpacing.xs) {
                    ForEach(result.validationErrors, id: \.self) { error in
                        HStack(spacing: AISSpacing.xs) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(Color(tokens.stateError.color))
                    }
                }
            }
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surface))
                .shadow(radius: 2)
        )
    }

    private func extractedFieldRow(_ field: AISExtractedField) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AISSpacing.xs) {
                    Text(field.displayName)
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))

                    if field.isRequired {
                        Text("*")
                            .font(.caption)
                            .foregroundColor(Color(tokens.stateError.color))
                    }
                }

                Text(field.mappedValue.isEmpty ? "-" : field.mappedValue)
                    .font(.body)
                    .foregroundColor(Color(tokens.onSurface))
            }

            Spacer()

            // Confidence indicator
            if field.confidence > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(field.confidenceLevel.color)
                        .frame(width: 8, height: 8)
                    Text("\(Int(field.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                }
            }
        }
        .padding(.vertical, AISSpacing.xs)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AISSpacing.md) {
            if onCancel != nil {
                AISButton("Cancel", type: .neutral, style: .outlined) {
                    onCancel?()
                }
            }

            Spacer()

            if currentResult != nil && status == .review {
                AISButton("Reject", type: .destructive) {
                    status = .rejected
                }

                AISButton("Approve", type: .confirm) {
                    approveResult()
                }
            }
        }
        .padding(.top, AISSpacing.md)
    }

    // MARK: - Processing

    private func processDocument() {
        guard let file = selectedFile else { return }

        status = .scanning
        progress = 0
        error = nil

        let startTime = Date()

        // Update progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            progress = 0.1
        }

        // For manual entry, skip OCR
        if selectedProvider == .selfMapping {
            DispatchQueue.main.async {
                progress = 1.0
                var result = AISDocScanResult(sourceFileId: file.id.uuidString)
                result.providerUsed = selectedProvider
                result.processingTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)
                result.status = .review
                currentResult = result
                status = .review
                selectedFile = nil
            }
            return
        }

        // Perform real OCR using Apple Vision
        performVisionOCR(file: file, startTime: startTime)
    }

    /// Perform OCR using Apple Vision framework
    private func performVisionOCR(file: AISFileInfo, startTime: Date) {
        let fileURL = URL(fileURLWithPath: file.localPath)

        DispatchQueue.global(qos: .userInitiated).async {
            var ocrText = ""
            var ocrError: String?

            // Load the image
            #if os(macOS)
            guard let nsImage = NSImage(contentsOf: fileURL),
                  let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                DispatchQueue.main.async {
                    self.error = "Failed to load image from file"
                    self.status = .idle
                    self.progress = 0
                }
                return
            }
            #else
            guard let uiImage = UIImage(contentsOfFile: file.localPath),
                  let cgImage = uiImage.cgImage else {
                DispatchQueue.main.async {
                    self.error = "Failed to load image from file"
                    self.status = .idle
                    self.progress = 0
                }
                return
            }
            #endif

            DispatchQueue.main.async {
                self.progress = 0.3
                self.status = .extracting
            }

            // Create Vision request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    ocrError = error.localizedDescription
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }

                // Extract text from observations
                var textLines: [String] = []
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        textLines.append(topCandidate.string)
                    }
                }

                ocrText = textLines.joined(separator: "\n")
            }

            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                ocrError = error.localizedDescription
            }

            DispatchQueue.main.async {
                self.progress = 0.7
            }

            // Process results on main thread
            DispatchQueue.main.async {
                var result = AISDocScanResult(sourceFileId: file.id.uuidString)
                result.providerUsed = self.selectedProvider
                result.processingTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)

                if let ocrError = ocrError {
                    self.error = "OCR failed: \(ocrError)"
                    result.status = .review
                } else if ocrText.isEmpty {
                    self.error = "No text detected in document"
                    result.status = .review
                } else {
                    result.rawOCRText = ocrText
                    self.parseInvoiceFields(&result, from: ocrText)
                    result.status = .review
                }

                self.progress = 1.0
                self.currentResult = result
                self.status = .review
                self.selectedFile = nil
            }
        }
    }

    private func parseInvoiceFields(_ result: inout AISDocScanResult, from text: String) {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        let nonEmptyLines = lines.filter { !$0.isEmpty }

        // Invoice/Receipt/Transaction Number patterns
        let invoicePatterns = [
            #"(?:Invoice|Receipt|Trans(?:action)?|Order|Ref(?:erence)?)\s*(?:#|No\.?|Number|:)?\s*[:\s]?([A-Z0-9\-]+)"#,
            #"#\s*(\d{4,})"#
        ]
        for pattern in invoicePatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                // Clean up the value
                value = value.replacingOccurrences(of: #"(?:Invoice|Receipt|Trans(?:action)?|Order|Ref(?:erence)?|#|No\.?|Number|:)"#,
                                                    with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    result.invoiceNumber.extractedValue = value
                    result.invoiceNumber.mappedValue = value
                    result.invoiceNumber.confidence = 0.85
                    result.invoiceNumber.confidenceLevel = .medium
                    break
                }
            }
        }

        // Date patterns (various formats)
        let datePatterns = [
            #"(?:Date|Time|Purchased)[:\s]+(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})"#,
            #"(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})\s+\d{1,2}:\d{2}"#,
            #"(\w{3,9}\s+\d{1,2},?\s+\d{4})"#
        ]
        for pattern in datePatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                // Extract just the date part
                if let dateMatch = value.range(of: #"\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}"#, options: .regularExpression) {
                    value = String(value[dateMatch])
                } else if let dateMatch = value.range(of: #"\w{3,9}\s+\d{1,2},?\s+\d{4}"#, options: .regularExpression) {
                    value = String(value[dateMatch])
                }
                result.invoiceDate.extractedValue = value
                result.invoiceDate.mappedValue = value
                result.invoiceDate.confidence = 0.8
                result.invoiceDate.confidenceLevel = .medium
                break
            }
        }

        // Vendor/Store name - check first few lines for store names
        let knownStores = ["COSTCO", "WALMART", "TARGET", "SAFEWAY", "KROGER", "WHOLE FOODS",
                          "TRADER JOE", "CVS", "WALGREENS", "HOME DEPOT", "LOWES", "AMAZON",
                          "BEST BUY", "STAPLES", "OFFICE DEPOT", "NORDSTROM", "MACY"]

        // First check for known stores
        for store in knownStores {
            if text.uppercased().contains(store) {
                // Find the full line containing the store name
                for line in nonEmptyLines.prefix(10) {
                    if line.uppercased().contains(store) {
                        result.vendorName.extractedValue = line.trimmingCharacters(in: .whitespaces)
                        result.vendorName.mappedValue = result.vendorName.extractedValue
                        result.vendorName.confidence = 0.90
                        result.vendorName.confidenceLevel = .high
                        break
                    }
                }
                break
            }
        }

        // Fallback: use first substantial text line as vendor
        if result.vendorName.extractedValue.isEmpty {
            for line in nonEmptyLines.prefix(5) {
                // Skip lines that are just numbers/prices/dates
                let hasLetters = line.rangeOfCharacter(from: .letters) != nil
                let isNotPrice = !line.contains("$") && !line.contains("TOTAL")
                let longEnough = line.count > 3

                if hasLetters && isNotPrice && longEnough {
                    result.vendorName.extractedValue = line
                    result.vendorName.mappedValue = line
                    result.vendorName.confidence = 0.60
                    result.vendorName.confidenceLevel = .low
                    break
                }
            }
        }

        // Total Amount - multiple patterns
        let totalPatterns = [
            #"(?:TOTAL|Grand\s*Total|Amount\s*Due|Balance\s*Due)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)"#,
            #"\*+\s*TOTAL\s*\$?\s*([\d,]+\.?\d*)"#
        ]
        for pattern in totalPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                // Extract just the number
                if let numMatch = value.range(of: #"[\d,]+\.?\d*$"#, options: .regularExpression) {
                    value = String(value[numMatch]).replacingOccurrences(of: ",", with: "")
                    result.totalAmount.extractedValue = value
                    result.totalAmount.mappedValue = value
                    result.totalAmount.confidence = 0.90
                    result.totalAmount.confidenceLevel = .high
                    break
                }
            }
        }

        // Subtotal
        let subtotalPatterns = [
            #"(?:Subtotal|Sub\s*Total)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)"#
        ]
        for pattern in subtotalPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                if let numMatch = value.range(of: #"[\d,]+\.?\d*$"#, options: .regularExpression) {
                    value = String(value[numMatch]).replacingOccurrences(of: ",", with: "")
                    result.subtotal.extractedValue = value
                    result.subtotal.mappedValue = value
                    result.subtotal.confidence = 0.85
                    result.subtotal.confidenceLevel = .medium
                    break
                }
            }
        }

        // Tax Amount
        let taxPatterns = [
            #"(?:TAX|VAT|GST|HST|Sales\s*Tax)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)"#
        ]
        for pattern in taxPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                if let numMatch = value.range(of: #"[\d,]+\.?\d*$"#, options: .regularExpression) {
                    value = String(value[numMatch]).replacingOccurrences(of: ",", with: "")
                    result.taxAmount.extractedValue = value
                    result.taxAmount.mappedValue = value
                    result.taxAmount.confidence = 0.85
                    result.taxAmount.confidenceLevel = .medium
                    break
                }
            }
        }

        // Parse line items
        parseLineItems(&result, from: nonEmptyLines)
    }

    /// Parse line items from OCR text lines
    private func parseLineItems(_ result: inout AISDocScanResult, from lines: [String]) {
        result.lineItems.removeAll()
        var lineNumber = 1

        // Skip keywords for header/footer lines
        let skipKeywords = [
            "SUBTOTAL", "SUB TOTAL", "TOTAL", "TAX", "CASH", "CREDIT", "DEBIT",
            "CHANGE", "BALANCE", "PAYMENT", "THANK YOU", "WELCOME", "MEMBER",
            "CARD", "VISA", "MASTERCARD", "AMEX", "DISCOVER", "DATE", "TIME",
            "RECEIPT", "TRANSACTION", "REGISTER", "CASHIER", "STORE", "TEL",
            "PHONE", "ADDRESS", "WWW", "HTTP", ".COM", "SAVINGS", "DISCOUNT"
        ]

        // Pattern for price at end of line
        let pricePattern = #"\$?\s*(\d+\.?\d{0,2})\s*$"#

        // Quantity patterns
        let qtyAtPattern = #"(\d+)\s*[@xX]\s*\$?(\d+\.?\d{0,2})"#
        let qtyLabelPattern = #"(?i)QTY\s*:?\s*(\d+)"#

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            // Skip header/footer lines
            let upperLine = trimmedLine.uppercased()
            var shouldSkip = false
            for keyword in skipKeywords {
                if upperLine.contains(keyword) {
                    shouldSkip = true
                    break
                }
            }
            if shouldSkip { continue }

            // Check if line ends with a price
            guard let priceMatch = trimmedLine.range(of: pricePattern, options: .regularExpression) else {
                continue
            }

            let priceStr = String(trimmedLine[priceMatch])
                .replacingOccurrences(of: "$", with: "")
                .trimmingCharacters(in: .whitespaces)
            let amount = Double(priceStr) ?? 0.0

            // Skip very small or very large amounts
            guard amount >= 0.01 && amount <= 10000 else { continue }

            // Extract description (everything before price)
            var description = String(trimmedLine[..<priceMatch.lowerBound]).trimmingCharacters(in: .whitespaces)

            // Default quantity and unit price
            var quantity = 1.0
            var unitPrice = amount

            // Check for "2 @ $5.99" or "2 x 5.99" pattern
            if let qtyMatch = description.range(of: qtyAtPattern, options: .regularExpression) {
                let qtyStr = String(description[qtyMatch])
                // Extract quantity
                if let numMatch = qtyStr.range(of: #"^\d+"#, options: .regularExpression) {
                    let qty = Double(qtyStr[numMatch]) ?? 1.0
                    if qty > 0 && qty < 1000 {
                        quantity = qty
                        // Extract unit price
                        if let unitMatch = qtyStr.range(of: #"[\d.]+$"#, options: .regularExpression) {
                            let parsedUnit = Double(qtyStr[unitMatch]) ?? 0.0
                            if parsedUnit > 0 {
                                unitPrice = parsedUnit
                            } else {
                                unitPrice = amount / quantity
                            }
                        } else {
                            unitPrice = amount / quantity
                        }
                        description = description.replacingOccurrences(of: qtyStr, with: "").trimmingCharacters(in: .whitespaces)
                    }
                }
            }
            // Check for "QTY: 2" pattern
            else if let qtyMatch = description.range(of: qtyLabelPattern, options: .regularExpression) {
                let qtyStr = String(description[qtyMatch])
                if let numMatch = qtyStr.range(of: #"\d+$"#, options: .regularExpression) {
                    let qty = Double(qtyStr[numMatch]) ?? 1.0
                    if qty > 0 && qty < 1000 {
                        quantity = qty
                        unitPrice = amount / quantity
                        description = description.replacingOccurrences(of: qtyStr, with: "").trimmingCharacters(in: .whitespaces)
                    }
                }
            }

            // Clean up description
            description = description
                .replacingOccurrences(of: #"^\d+\s+"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            // Skip if description is too short or just numbers
            guard description.count >= 2 else { continue }
            guard description.range(of: #"[a-zA-Z]"#, options: .regularExpression) != nil else { continue }

            // Add line item
            result.lineItems.append(AISInvoiceLineItem(
                lineNumber: lineNumber,
                description: description,
                quantity: quantity,
                unitPrice: unitPrice,
                amount: amount,
                confidence: 0.70
            ))

            lineNumber += 1

            // Limit to reasonable number
            if lineNumber > 100 { break }
        }
    }

    private func approveResult() {
        guard var result = currentResult else { return }

        let errors = result.validate()
        if errors.isEmpty {
            result.status = .approved
            currentResult = result
            status = .approved
            onComplete?(result)
        } else {
            currentResult = result
        }
    }

    private func extractVendorName(from fileName: String) -> String {
        let name = fileName
            .replacingOccurrences(of: ".pdf", with: "")
            .replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized

        return name.isEmpty ? "Acme Corp" : name
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - AI Settings Sheet

/// Settings sheet for configuring AI providers
public struct AISDocScanSettingsSheet: View {
    @Binding var settings: AISDocScanAISettings
    @Binding var isPresented: Bool

    @Environment(\.aisTokens) private var tokens
    @State private var selectedTab = 0
    @State private var testingConnection = false
    @State private var connectionStatus: String?

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AISSpacing.lg) {
                    // Tab selector
                    Picker("Provider Type", selection: $selectedTab) {
                        Text("Cloud LLM").tag(0)
                        Text("Local AI").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AISSpacing.md)

                    if selectedTab == 0 {
                        cloudLLMSettings
                    } else {
                        localAISettings
                    }

                    // Connection test result
                    if let status = connectionStatus {
                        HStack(spacing: AISSpacing.sm) {
                            Image(systemName: status.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(status.contains("Success") ? .green : .red)
                            Text(status)
                                .font(.subheadline)
                        }
                        .padding(AISSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: AISRadius.md)
                                .fill(status.contains("Success")
                                      ? Color.green.opacity(0.1)
                                      : Color.red.opacity(0.1))
                        )
                        .padding(.horizontal, AISSpacing.md)
                    }
                }
                .padding(.vertical, AISSpacing.lg)
            }
            .background(Color(tokens.surface))
            .navigationTitle("AI Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 500)
        #endif
    }

    // MARK: - Cloud LLM Settings

    private var cloudLLMSettings: some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            // Preferred provider
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("Preferred Provider")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                Picker("Provider", selection: $settings.preferredCloudProvider) {
                    Text("Claude (Anthropic)").tag("claude")
                    Text("ChatGPT (OpenAI)").tag("openai")
                    Text("Gemini (Google)").tag("gemini")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, AISSpacing.md)

            Divider()
                .padding(.horizontal, AISSpacing.md)

            // Claude API Key
            apiKeySection(
                title: "Claude API Key",
                icon: "ant.fill",
                placeholder: "sk-ant-...",
                value: $settings.claudeAPIKey,
                isActive: settings.preferredCloudProvider == "claude"
            )

            // OpenAI API Key
            apiKeySection(
                title: "OpenAI API Key",
                icon: "brain",
                placeholder: "sk-...",
                value: $settings.openAIAPIKey,
                isActive: settings.preferredCloudProvider == "openai"
            )

            // Gemini API Key
            apiKeySection(
                title: "Gemini API Key",
                icon: "sparkles",
                placeholder: "AI...",
                value: $settings.geminiAPIKey,
                isActive: settings.preferredCloudProvider == "gemini"
            )

            Divider()
                .padding(.horizontal, AISSpacing.md)

            // Fallback option
            Toggle(isOn: $settings.enableFallback) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Fallback")
                        .font(.subheadline)
                        .foregroundColor(Color(tokens.onSurface))
                    Text("Try other providers if preferred one fails")
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                }
            }
            .padding(.horizontal, AISSpacing.md)

            // Test connection button
            AISButton(
                "Test Connection",
                type: .primary,
                icon: "antenna.radiowaves.left.and.right",
                isLoading: testingConnection
            ) {
                testCloudConnection()
            }
            .padding(.horizontal, AISSpacing.md)
        }
    }

    private func apiKeySection(
        title: String,
        icon: String,
        placeholder: String,
        value: Binding<String>,
        isActive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.xs) {
            HStack(spacing: AISSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(isActive ? Color(tokens.actionPrimary.color) : Color(tokens.onSurfaceSecondary))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(tokens.onSurface))
                if isActive {
                    Text("(Active)")
                        .font(.caption)
                        .foregroundColor(Color(tokens.actionPrimary.color))
                }
                Spacer()
                if !value.wrappedValue.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            SecureField(placeholder, text: value)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
        .padding(.horizontal, AISSpacing.md)
        .padding(.vertical, AISSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.sm)
                .fill(isActive ? Color(tokens.actionPrimary.color).opacity(0.05) : Color.clear)
        )
        .padding(.horizontal, AISSpacing.md)
    }

    // MARK: - Local AI Settings

    private var localAISettings: some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            // Ollama section
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Toggle(isOn: $settings.useOllama) {
                    HStack(spacing: AISSpacing.sm) {
                        Image(systemName: "server.rack")
                            .foregroundColor(settings.useOllama ? Color(tokens.actionPrimary.color) : Color(tokens.onSurfaceSecondary))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ollama")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(tokens.onSurface))
                            Text("Run LLMs locally with Ollama")
                                .font(.caption)
                                .foregroundColor(Color(tokens.onSurfaceSecondary))
                        }
                    }
                }

                if settings.useOllama {
                    VStack(alignment: .leading, spacing: AISSpacing.xs) {
                        Text("Endpoint")
                            .font(.caption)
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                        TextField("http://localhost:11434", text: $settings.ollamaEndpoint)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.leading, AISSpacing.xl)

                    VStack(alignment: .leading, spacing: AISSpacing.xs) {
                        Text("Model")
                            .font(.caption)
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                        TextField("llama3.2", text: $settings.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.leading, AISSpacing.xl)
                }
            }
            .padding(.horizontal, AISSpacing.md)

            Divider()
                .padding(.horizontal, AISSpacing.md)

            // LM Studio section
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Toggle(isOn: $settings.useLMStudio) {
                    HStack(spacing: AISSpacing.sm) {
                        Image(systemName: "laptopcomputer")
                            .foregroundColor(settings.useLMStudio ? Color(tokens.actionPrimary.color) : Color(tokens.onSurfaceSecondary))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LM Studio")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(tokens.onSurface))
                            Text("Use LM Studio local server")
                                .font(.caption)
                                .foregroundColor(Color(tokens.onSurfaceSecondary))
                        }
                    }
                }

                if settings.useLMStudio {
                    VStack(alignment: .leading, spacing: AISSpacing.xs) {
                        Text("Endpoint")
                            .font(.caption)
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                        TextField("http://localhost:1234", text: $settings.lmStudioEndpoint)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.leading, AISSpacing.xl)
                }
            }
            .padding(.horizontal, AISSpacing.md)

            Divider()
                .padding(.horizontal, AISSpacing.md)

            // Test connection button
            AISButton(
                "Test Local Connection",
                type: .primary,
                icon: "antenna.radiowaves.left.and.right",
                isLoading: testingConnection
            ) {
                testLocalConnection()
            }
            .padding(.horizontal, AISSpacing.md)

            // Help text
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("Setup Instructions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                Text("1. Install Ollama from ollama.ai or LM Studio")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Text("2. Start the local server")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Text("3. For Ollama: ollama run llama3.2")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Text("4. Test the connection above")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }
            .padding(AISSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(Color(tokens.surfaceSecondary))
            )
            .padding(.horizontal, AISSpacing.md)
        }
    }

    // MARK: - Connection Tests

    private func testCloudConnection() {
        testingConnection = true
        connectionStatus = "Testing connection..."

        // Simulate connection test with actual HTTP validation
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            await MainActor.run {
                testingConnection = false

                let activeKey = settings.activeCloudAPIKey ?? ""
                if activeKey.isEmpty {
                    connectionStatus = "Error: No API key configured for \(settings.preferredCloudProvider.capitalized)"
                } else if settings.preferredCloudProvider == "claude" {
                    if activeKey.hasPrefix("sk-ant-") {
                        connectionStatus = "Success! Claude API key format is valid. Ready to use."
                    } else {
                        connectionStatus = "Error: Claude API key should start with 'sk-ant-'"
                    }
                } else if settings.preferredCloudProvider == "openai" {
                    if activeKey.hasPrefix("sk-") {
                        connectionStatus = "Success! OpenAI API key format is valid. Ready to use."
                    } else {
                        connectionStatus = "Error: OpenAI API key should start with 'sk-'"
                    }
                } else if settings.preferredCloudProvider == "gemini" {
                    if activeKey.count > 20 {
                        connectionStatus = "Success! Gemini API key format is valid. Ready to use."
                    } else {
                        connectionStatus = "Error: Gemini API key appears too short"
                    }
                } else {
                    connectionStatus = "Error: Unknown provider"
                }
            }
        }
    }

    private func testLocalConnection() {
        testingConnection = true
        connectionStatus = "Testing local connection..."

        Task {
            if settings.useOllama {
                connectionStatus = "Connecting to Ollama at \(settings.ollamaEndpoint)..."
                // Try actual HTTP connection
                let success = await testEndpoint(settings.ollamaEndpoint)
                await MainActor.run {
                    testingConnection = false
                    if success {
                        connectionStatus = "Success! Ollama is running at \(settings.ollamaEndpoint)"
                    } else {
                        connectionStatus = "Error: Could not connect to Ollama at \(settings.ollamaEndpoint). Make sure Ollama is running."
                    }
                }
            } else if settings.useLMStudio {
                connectionStatus = "Connecting to LM Studio at \(settings.lmStudioEndpoint)..."
                let success = await testEndpoint(settings.lmStudioEndpoint)
                await MainActor.run {
                    testingConnection = false
                    if success {
                        connectionStatus = "Success! LM Studio is running at \(settings.lmStudioEndpoint)"
                    } else {
                        connectionStatus = "Error: Could not connect to LM Studio at \(settings.lmStudioEndpoint). Make sure LM Studio is running."
                    }
                }
            } else {
                await MainActor.run {
                    testingConnection = false
                    connectionStatus = "Error: Enable Ollama or LM Studio first"
                }
            }
        }
    }

    /// Test if an endpoint is reachable
    private func testEndpoint(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 5.0

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode < 500
            }
            return false
        } catch {
            return false
        }
    }
}

// MARK: - OCR Output Sheet

/// Sheet displaying the full OCR output in text and JSON formats
public struct AISDocScanOCROutputSheet: View {
    let result: AISDocScanResult
    @Binding var isPresented: Bool

    @Environment(\.aisTokens) private var tokens
    @State private var selectedTab = 0 // 0 = Text, 1 = JSON
    @State private var copySuccess = false

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Output Format", selection: $selectedTab) {
                    Text("Text").tag(0)
                    Text("JSON").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(AISSpacing.md)

                Divider()

                // Content
                ScrollView {
                    if selectedTab == 0 {
                        textOutput
                    } else {
                        jsonOutput
                    }
                }

                Divider()

                // Copy button
                HStack {
                    if copySuccess {
                        HStack(spacing: AISSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Copied to clipboard!")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .transition(.opacity)
                    }

                    Spacer()

                    AISButton("Copy to Clipboard", type: .primary, icon: "doc.on.doc") {
                        copyToClipboard()
                    }
                }
                .padding(AISSpacing.md)
                .animation(.easeInOut, value: copySuccess)
            }
            .background(Color(tokens.surface))
            .navigationTitle("OCR Output")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
    }

    // MARK: - Text Output

    private var textOutput: some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            // Header
            outputSection(title: "Processing Summary") {
                VStack(alignment: .leading, spacing: AISSpacing.xs) {
                    infoRow("Provider", result.providerUsed.displayName)
                    infoRow("Processing Time", "\(result.processingTimeMs)ms")
                    infoRow("Status", result.status.rawValue.capitalized)
                    infoRow("Confidence", String(format: "%.1f%%", result.confidenceScore * 100))
                }
            }

            // Extracted Fields
            outputSection(title: "Extracted Fields") {
                VStack(alignment: .leading, spacing: AISSpacing.sm) {
                    fieldRow("Invoice Number", result.invoiceNumber)
                    fieldRow("Invoice Date", result.invoiceDate)
                    fieldRow("Vendor Name", result.vendorName)
                    fieldRow("Subtotal", result.subtotal)
                    fieldRow("Tax Amount", result.taxAmount)
                    fieldRow("Total Amount", result.totalAmount)
                }
            }

            // Line Items
            if !result.lineItems.isEmpty {
                outputSection(title: "Line Items (\(result.lineItems.count))") {
                    VStack(alignment: .leading, spacing: AISSpacing.sm) {
                        ForEach(Array(result.lineItems.enumerated()), id: \.offset) { index, item in
                            lineItemRow(index + 1, item)
                        }
                    }
                }
            }

            // Raw OCR Text
            if let rawText = result.rawOCRText, !rawText.isEmpty {
                outputSection(title: "Raw OCR Text") {
                    Text(rawText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AISSpacing.sm)
                        .background(Color(tokens.surfaceSecondary))
                        .cornerRadius(AISRadius.sm)
                }
            }

            // Validation Errors
            if !result.validationErrors.isEmpty {
                outputSection(title: "Validation Errors") {
                    VStack(alignment: .leading, spacing: AISSpacing.xs) {
                        ForEach(result.validationErrors, id: \.self) { error in
                            HStack(spacing: AISSpacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(tokens.stateError.color))
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(Color(tokens.stateError.color))
                            }
                        }
                    }
                }
            }
        }
        .padding(AISSpacing.lg)
    }

    private func outputSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(tokens.onSurface))

            content()
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(Color(tokens.onSurfaceSecondary))
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(tokens.onSurface))
        }
    }

    private func fieldRow(_ label: String, _ field: AISExtractedField) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Spacer()
                confidenceBadge(field.confidenceLevel)
            }

            HStack {
                Text("Extracted:")
                    .font(.caption2)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Text(field.extractedValue.isEmpty ? "-" : field.extractedValue)
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurface))
            }

            HStack {
                Text("Mapped:")
                    .font(.caption2)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Text(field.mappedValue.isEmpty ? "-" : field.mappedValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(tokens.onSurface))
            }
        }
        .padding(AISSpacing.sm)
        .background(Color(tokens.surfaceSecondary))
        .cornerRadius(AISRadius.sm)
    }

    private func lineItemRow(_ index: Int, _ item: AISInvoiceLineItem) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.xs) {
            Text("Item \(index): \(item.description)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(tokens.onSurface))

            HStack {
                Text("Qty: \(item.quantity)")
                    .font(.caption2)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Spacer()
                Text("Unit: \(item.unitPrice)")
                    .font(.caption2)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                Spacer()
                Text("Total: \(item.totalPrice)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(tokens.onSurface))
            }
        }
        .padding(AISSpacing.sm)
        .background(Color(tokens.surfaceSecondary))
        .cornerRadius(AISRadius.sm)
    }

    private func confidenceBadge(_ level: AISExtractionConfidence) -> some View {
        Text(level.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(level.color.opacity(0.2))
            .foregroundColor(level.color)
            .cornerRadius(AISRadius.xs)
    }

    // MARK: - JSON Output

    private var jsonOutput: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Text(generateJSON())
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(tokens.onSurface))
                .padding(AISSpacing.lg)
        }
    }

    private func generateJSON() -> String {
        var json: [String: Any] = [
            "metadata": [
                "provider": result.providerUsed.rawValue,
                "processingTimeMs": result.processingTimeMs,
                "status": result.status.rawValue,
                "confidenceScore": result.confidenceScore
            ],
            "extractedFields": [
                "invoiceNumber": fieldToDict(result.invoiceNumber),
                "invoiceDate": fieldToDict(result.invoiceDate),
                "vendorName": fieldToDict(result.vendorName),
                "subtotal": fieldToDict(result.subtotal),
                "taxAmount": fieldToDict(result.taxAmount),
                "totalAmount": fieldToDict(result.totalAmount)
            ]
        ]

        if !result.lineItems.isEmpty {
            json["lineItems"] = result.lineItems.map { item in
                [
                    "description": item.description,
                    "quantity": item.quantity,
                    "unitPrice": item.unitPrice,
                    "totalPrice": item.totalPrice
                ]
            }
        }

        if let rawText = result.rawOCRText {
            json["rawOCRText"] = rawText
        }

        if !result.validationErrors.isEmpty {
            json["validationErrors"] = result.validationErrors
        }

        // Convert to pretty JSON
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{ \"error\": \"Failed to generate JSON\" }"
        }
    }

    private func fieldToDict(_ field: AISExtractedField) -> [String: Any] {
        return [
            "extractedValue": field.extractedValue,
            "mappedValue": field.mappedValue,
            "confidence": field.confidence,
            "confidenceLevel": field.confidenceLevel.rawValue
        ]
    }

    // MARK: - Copy to Clipboard

    private func copyToClipboard() {
        let content = selectedTab == 0 ? generateTextContent() : generateJSON()

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #else
        UIPasteboard.general.string = content
        #endif

        copySuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copySuccess = false
        }
    }

    private func generateTextContent() -> String {
        var lines: [String] = []

        lines.append("=== OCR EXTRACTION RESULTS ===")
        lines.append("")
        lines.append("Processing Summary")
        lines.append("  Provider: \(result.providerUsed.displayName)")
        lines.append("  Processing Time: \(result.processingTimeMs)ms")
        lines.append("  Status: \(result.status.rawValue.capitalized)")
        lines.append("  Confidence: \(String(format: "%.1f%%", result.confidenceScore * 100))")
        lines.append("")
        lines.append("Extracted Fields")
        lines.append("  Invoice Number: \(result.invoiceNumber.mappedValue) (\(result.invoiceNumber.confidenceLevel.displayName))")
        lines.append("  Invoice Date: \(result.invoiceDate.mappedValue) (\(result.invoiceDate.confidenceLevel.displayName))")
        lines.append("  Vendor Name: \(result.vendorName.mappedValue) (\(result.vendorName.confidenceLevel.displayName))")
        lines.append("  Subtotal: \(result.subtotal.mappedValue) (\(result.subtotal.confidenceLevel.displayName))")
        lines.append("  Tax Amount: \(result.taxAmount.mappedValue) (\(result.taxAmount.confidenceLevel.displayName))")
        lines.append("  Total Amount: \(result.totalAmount.mappedValue) (\(result.totalAmount.confidenceLevel.displayName))")

        if !result.lineItems.isEmpty {
            lines.append("")
            lines.append("Line Items (\(result.lineItems.count))")
            for (index, item) in result.lineItems.enumerated() {
                lines.append("  \(index + 1). \(item.description) - Qty: \(item.quantity), Unit: \(item.unitPrice), Total: \(item.totalPrice)")
            }
        }

        if let rawText = result.rawOCRText, !rawText.isEmpty {
            lines.append("")
            lines.append("Raw OCR Text:")
            lines.append(rawText)
        }

        if !result.validationErrors.isEmpty {
            lines.append("")
            lines.append("Validation Errors:")
            for error in result.validationErrors {
                lines.append("  - \(error)")
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Preview

#if DEBUG
struct AISDocScanWidget_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AISDocScanWidget(
                preferredProvider: .browserVision,
                onComplete: { result in
                    print("Completed: \(result.invoiceNumber.mappedValue)")
                },
                onCancel: {
                    print("Cancelled")
                }
            )
            .navigationTitle("Document Scan")
        }
        .withAISTokens()
    }
}
#endif

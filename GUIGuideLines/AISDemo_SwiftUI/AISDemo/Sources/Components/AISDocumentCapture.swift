// =============================================================================
// AISDocumentCapture.swift
// AIS Document Capture - Integrated Media Picker + Document Scanner
// =============================================================================
//
// PURPOSE:
// A standalone, reusable view that combines AISMediaPicker and AISDocScan
// into a single integrated document capture experience. This view provides
// a complete workflow for capturing documents via file selection, camera, or
// clipboard, then processing them with OCR and AI-powered field extraction.
//
// USAGE:
// ```swift
// AISDocumentCapture(
//     documentType: .invoice,
//     inputSources: [.files, .camera, .clipboard],
//     onDocumentCaptured: { result in
//         // Handle the captured and processed document
//         print("Captured: \(result.invoiceNumber.mappedValue)")
//     },
//     onCancel: { dismiss() }
// )
// ```
//
// FEATURES:
// - Unified document capture workflow
// - Multiple input sources (files, camera, clipboard)
// - AI-powered OCR with Apple Vision and field extraction
// - Editable extracted fields with confidence indicators
// - Validation and approval workflow
// - Customizable document types (Invoice, Receipt, PO, etc.)
//
// =============================================================================

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document Types

/// Supported document types for capture
enum AISDocumentType: String, CaseIterable, Identifiable {
    case invoice = "Invoice"
    case receipt = "Receipt"
    case purchaseOrder = "Purchase Order"
    case contract = "Contract"
    case general = "General Document"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .invoice: return "doc.text"
        case .receipt: return "receipt"
        case .purchaseOrder: return "cart"
        case .contract: return "doc.plaintext"
        case .general: return "doc"
        }
    }

    var description: String {
        switch self {
        case .invoice: return "Capture vendor invoices for AP processing"
        case .receipt: return "Capture expense receipts"
        case .purchaseOrder: return "Capture purchase orders"
        case .contract: return "Capture contract documents"
        case .general: return "Capture any document type"
        }
    }
}

// MARK: - Capture State

/// Workflow state for document capture
enum AISCaptureState {
    case selectSource
    case selectFile
    case processing
    case review
    case approved
    case rejected

    var displayName: String {
        switch self {
        case .selectSource: return "Select Source"
        case .selectFile: return "Ready"
        case .processing: return "Processing"
        case .review: return "Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

// MARK: - Document Capture View

/// Integrated document capture view combining media picker and doc scanner
struct AISDocumentCapture: View {
    /// The type of document being captured
    let documentType: AISDocumentType

    /// Available input sources
    let inputSources: [AISInputSource]

    /// Called when document is captured and approved
    var onDocumentCaptured: ((DocScanResult) -> Void)?

    /// Called when user cancels
    var onCancel: (() -> Void)?

    /// Preferred AI provider for OCR
    var preferredProvider: AIProviderTier = .appleVision

    /// Whether to show the source selector initially
    var showSourceSelector: Bool = true

    /// Custom title
    var title: String?

    /// Custom subtitle
    var subtitle: String?

    @StateObject private var scanService = DocScanService()
    @State private var captureState: AISCaptureState = .selectSource
    @State private var selectedSource: AISInputSource?
    @State private var selectedFile: AISFileInfo?
    @State private var showRawOCR = false

    @Environment(\.colorScheme) private var colorScheme

    init(
        documentType: AISDocumentType = .invoice,
        inputSources: [AISInputSource] = [.files, .camera, .clipboard],
        onDocumentCaptured: ((DocScanResult) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        preferredProvider: AIProviderTier = .appleVision,
        showSourceSelector: Bool = true,
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.documentType = documentType
        self.inputSources = inputSources
        self.onDocumentCaptured = onDocumentCaptured
        self.onCancel = onCancel
        self.preferredProvider = preferredProvider
        self.showSourceSelector = showSourceSelector
        self.title = title
        self.subtitle = subtitle

        if inputSources.count == 1 && !showSourceSelector {
            _selectedSource = State(initialValue: inputSources.first)
            _captureState = State(initialValue: .selectFile)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            Group {
                switch captureState {
                case .selectSource:
                    sourceSelector
                case .selectFile:
                    filePicker
                case .processing:
                    processingView
                case .review:
                    reviewView
                case .approved:
                    approvedView
                case .rejected:
                    rejectedView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer
            footerView
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            scanService.preferredProvider = preferredProvider
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: documentType.icon)
                        .foregroundColor(.accentColor)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? "Capture \(documentType.rawValue)")
                        .font(.headline)

                    Text(subtitle ?? documentType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            stateIndicator
        }
        .padding()
    }

    private var stateIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)

            Text(captureState.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var stateColor: Color {
        switch captureState {
        case .selectSource, .selectFile: return .blue
        case .processing, .review: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }

    // MARK: - Source Selector

    private var sourceSelector: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Choose Input Source")
                .font(.title2.bold())

            Text("Select how you want to capture the \(documentType.rawValue.lowercased())")
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                ForEach(inputSources, id: \.self) { source in
                    sourceCard(source)
                }
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding()
    }

    private func sourceCard(_ source: AISInputSource) -> some View {
        Button(action: {
            selectedSource = source
            captureState = .selectFile
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: source.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }

                Text(source.displayName)
                    .font(.headline)

                Text(source.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 140)
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - File Picker

    private var filePicker: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: documentType.icon)
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Select \(documentType.rawValue)")
                .font(.title2.bold())

            AISMediaPicker(
                allowedTypes: [.image, .pdf, .text],
                multiple: false,
                label: "Select Document",
                inputSources: selectedSource != nil ? [selectedSource!] : inputSources,
                showSourceSelector: false
            ) { files in
                if let file = files.first {
                    selectedFile = file
                    processFile(file)
                }
            }
            .frame(maxWidth: 400)

            // Provider selector
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Processing")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Provider", selection: $scanService.preferredProvider) {
                    ForEach(AIProviderTier.allCases, id: \.self) { tier in
                        HStack {
                            Image(systemName: tier.icon)
                            Text(tier.displayName)
                        }
                        .tag(tier)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            .frame(maxWidth: 400)

            Spacer()
        }
        .padding()
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(value: scanService.progress)
                .progressViewStyle(.linear)
                .frame(width: 300)

            Image(systemName: scanService.status == .scanning ? "doc.viewfinder" : "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse)

            Text(scanService.status.displayName)
                .font(.title3.bold())

            Text("Using \(scanService.activeProvider.displayName)")
                .foregroundColor(.secondary)

            if let file = selectedFile {
                Text(file.fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Review View

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // File info
                if let file = selectedFile, let result = scanService.currentResult {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.accentColor)

                        Text(file.fileName)
                            .font(.caption)

                        Spacer()

                        Text("\(result.processingTimeMs)ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }

                // Confidence bar
                if let result = scanService.currentResult {
                    confidenceBar(result.overallConfidence)

                    // Validation errors
                    if !result.validationErrors.isEmpty {
                        validationErrors(result.validationErrors)
                    }

                    // Header fields
                    sectionHeader("\(documentType.rawValue) Details", icon: "doc.text")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(result.allHeaderFields) { field in
                            EditableFieldView(field: field)
                        }
                    }

                    // Amount fields
                    sectionHeader("Amounts", icon: "dollarsign.circle")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(result.allAmountFields) { field in
                            EditableFieldView(field: field, prefix: "$")
                        }
                    }

                    // Raw OCR
                    if let rawText = result.rawOCRText, !rawText.isEmpty {
                        DisclosureGroup("Raw OCR Text", isExpanded: $showRawOCR) {
                            ScrollView {
                                Text(rawText)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 200)
                            .padding(10)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)

            Text(title)
                .font(.headline)
        }
        .padding(.top, 8)
    }

    private func confidenceBar(_ confidence: Double) -> some View {
        HStack {
            Text("Extraction Confidence")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(Int(confidence * 100))%")
                .font(.caption.bold())
                .foregroundColor(confidenceColor(confidence))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(confidenceColor(confidence))
                        .frame(width: geometry.size.width * confidence)
                }
            }
            .frame(width: 100, height: 6)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 { return .green }
        if confidence >= 0.7 { return .orange }
        return .red
    }

    private func validationErrors(_ errors: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(errors, id: \.self) { error in
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Approved View

    private var approvedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("\(documentType.rawValue) Captured")
                .font(.title2.bold())

            Text("Document has been processed successfully.")
                .foregroundColor(.secondary)

            Button("Capture Another") {
                reset()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Rejected View

    private var rejectedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("Document Rejected")
                .font(.title2.bold())

            Text("The document was not accepted.")
                .foregroundColor(.secondary)

            Button("Try Again") {
                reset()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            if captureState != .selectSource {
                Button("Back") {
                    goBack()
                }
                .buttonStyle(.bordered)
            } else {
                Button("Cancel") {
                    onCancel?()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if captureState == .review {
                Button("Reject") {
                    rejectDocument()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button("Approve") {
                    approveDocument()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func processFile(_ file: AISFileInfo) {
        captureState = .processing

        Task {
            _ = await scanService.processDocument(file)
            await MainActor.run {
                captureState = .review
            }
        }
    }

    private func approveDocument() {
        scanService.approveResult()

        if let result = scanService.currentResult,
           result.validationErrors.isEmpty {
            captureState = .approved
            onDocumentCaptured?(result)
        }
    }

    private func rejectDocument() {
        scanService.rejectResult()
        captureState = .rejected
    }

    private func goBack() {
        switch captureState {
        case .selectFile:
            captureState = .selectSource
            selectedSource = nil
        case .review:
            captureState = .selectFile
            scanService.reset()
        default:
            captureState = .selectSource
            selectedSource = nil
            scanService.reset()
        }
    }

    private func reset() {
        captureState = .selectSource
        selectedFile = nil
        selectedSource = nil
        scanService.reset()
    }
}

// MARK: - Editable Field View

private struct EditableFieldView: View {
    @ObservedObject var field: ExtractedField
    var prefix: String = ""

    @State private var isEditing = false
    @State private var editValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(field.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if field.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }

                Spacer()

                Circle()
                    .fill(confidenceColor)
                    .frame(width: 8, height: 8)
            }

            HStack {
                if !prefix.isEmpty {
                    Text(prefix)
                        .foregroundColor(.secondary)
                }

                if isEditing {
                    TextField("", text: $editValue)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            field.updateValue(editValue)
                            isEditing = false
                        }
                } else {
                    Text(field.mappedValue.isEmpty ? "-" : field.mappedValue)
                        .foregroundColor(field.mappedValue.isEmpty ? .secondary : .primary)
                }

                Spacer()

                Button(action: {
                    if isEditing {
                        field.updateValue(editValue)
                        isEditing = false
                    } else {
                        editValue = field.mappedValue
                        isEditing = true
                    }
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private var confidenceColor: Color {
        switch field.confidenceLevel {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        case .manual: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    AISDocumentCapture(
        documentType: .invoice,
        inputSources: [.files, .camera, .clipboard],
        onDocumentCaptured: { result in
            print("Captured: \(result.invoiceNumber.mappedValue)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
    .frame(width: 600, height: 700)
}

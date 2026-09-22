// =============================================================================
// DocScanAPView.swift
// AIS DocScan AP Module - Main SwiftUI View
// =============================================================================
//
// PURPOSE:
// Complete document scanning UI for Accounts Payable processing.
// Integrates AISMediaPicker for file selection and displays extraction results
// with editable fields for review before posting to accounting system.
//
// PIPELINE:
// AIS Media Picker → OCR → AI Router → Table Mapping → DB Update → File Save
//
// USAGE:
// ```swift
// DocScanAPView(
//     onComplete: { result in
//         // Post to accounting system
//         viewModel.createAPEntry(from: result)
//     },
//     onCancel: {
//         dismiss()
//     }
// )
// ```
//
// =============================================================================

import SwiftUI

// MARK: - Main DocScan AP View

/// Main view for document scanning and AP entry creation
public struct DocScanAPView: View {
    // MARK: - Properties

    @StateObject private var scanService = DocScanService()
    @State private var pickerState: AISFilePickerState = .idle
    @State private var selectedFile: AISFileInfo?
    @State private var showProviderSelector = false
    @State private var showRawOCR = false

    let onComplete: (DocScanResult) -> Void
    let onCancel: () -> Void

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Initialization

    public init(
        onComplete: @escaping (DocScanResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            Divider()

            // Content based on state
            ScrollView {
                VStack(spacing: AISSpacing.lg) {
                    switch scanService.status {
                    case .pending:
                        fileSelectionSection

                    case .scanning, .extracting:
                        processingSection

                    case .review, .approved:
                        reviewSection

                    case .rejected:
                        rejectedSection

                    case .error:
                        errorSection

                    case .posted:
                        postedSection
                    }
                }
                .padding(AISSpacing.lg)
            }

            Divider()

            // Footer actions
            footerBar
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Document Scanner")
                    .font(.headline)
                    .foregroundColor(tokens.onSurface)

                Text("AP Invoice Entry")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }

            Spacer()

            // Provider indicator
            HStack(spacing: AISSpacing.sm) {
                Image(systemName: scanService.activeProvider.iconName)
                    .foregroundColor(tokens.actionPrimary.color)

                Text(scanService.activeProvider.displayName)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
            .padding(.horizontal, AISSpacing.sm)
            .padding(.vertical, AISSpacing.xs)
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.sm)
        }
        .padding(AISSpacing.md)
    }

    // MARK: - File Selection Section

    private var fileSelectionSection: some View {
        VStack(spacing: AISSpacing.xl) {
            // Illustration/Icon
            VStack(spacing: AISSpacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 64))
                    .foregroundColor(tokens.actionPrimary.color)

                Text("Scan Invoice Document")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(tokens.onSurface)

                Text("Select an invoice image or PDF to extract vendor, amounts, and line items automatically.")
                    .font(.body)
                    .foregroundColor(tokens.onSurfaceSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AISSpacing.xl)
            }
            .padding(.top, AISSpacing.xl)

            // Media Picker
            AISMediaPicker(
                state: $pickerState,
                allowedTypes: [.image, .pdf],
                allowsMultiple: false,
                maxFileSize: 50_000_000, // 50MB max
                buttonLabel: "Select Invoice",
                buttonType: .primary
            ) { files in
                if let file = files.first {
                    selectedFile = file
                    processSelectedFile(file)
                }
            } onError: { error in
                scanService.error = error.localizedDescription
            }

            // Selected file preview
            if let file = selectedFile {
                AISFileInfoRow(file: file) {
                    selectedFile = nil
                    pickerState = .idle
                }
            }

            // Provider selection
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("AI Provider")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)

                Picker("Provider", selection: $scanService.preferredProvider) {
                    ForEach(AIProviderTier.allCases.filter { $0.isAvailable }) { tier in
                        Label(tier.displayName, systemImage: tier.iconName)
                            .tag(tier)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(AISSpacing.md)
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)

            Spacer(minLength: AISSpacing.xl)
        }
    }

    // MARK: - Processing Section

    private var processingSection: some View {
        VStack(spacing: AISSpacing.xl) {
            Spacer()

            VStack(spacing: AISSpacing.lg) {
                ProgressView(value: scanService.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 300)

                VStack(spacing: AISSpacing.sm) {
                    Image(systemName: scanService.status == .scanning ? "doc.text.magnifyingglass" : "cpu")
                        .font(.largeTitle)
                        .foregroundColor(tokens.actionPrimary.color)

                    Text(scanService.status.displayName)
                        .font(.headline)
                        .foregroundColor(tokens.onSurface)

                    Text("Using \(scanService.activeProvider.displayName)")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Review Section

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            // Status badge
            HStack {
                AISStateBadge(
                    label: scanService.status.displayName,
                    type: scanService.status == .approved ? .success : .warning,
                    icon: scanService.status.iconName
                )

                Spacer()

                if scanService.currentResult?.rawOCRText != nil {
                    Button {
                        showRawOCR.toggle()
                    } label: {
                        Label("Raw OCR", systemImage: "doc.text")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Confidence indicator
            if let result = scanService.currentResult {
                confidenceBar(confidence: result.overallConfidence)
            }

            // Validation errors
            if let result = scanService.currentResult, !result.validationErrors.isEmpty {
                validationErrorsView(errors: result.validationErrors)
            }

            // Header Fields Section
            SectionHeader(title: "Invoice Details", icon: "doc.text")
            headerFieldsGrid

            // Amounts Section
            SectionHeader(title: "Amounts", icon: "dollarsign.circle")
            amountFieldsGrid

            // Line Items Section
            if let result = scanService.currentResult, !result.lineItems.isEmpty {
                SectionHeader(title: "Line Items", icon: "list.bullet")
                lineItemsTable(items: result.lineItems)
            }

            // Raw OCR (collapsible)
            if showRawOCR, let rawText = scanService.currentResult?.rawOCRText {
                rawOCRSection(text: rawText)
            }
        }
    }

    // MARK: - Rejected Section

    private var rejectedSection: some View {
        VStack(spacing: AISSpacing.lg) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 64))
                .foregroundColor(tokens.stateError.color)

            Text("Document Rejected")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens.onSurface)

            Text("This invoice has been rejected and will not be posted.")
                .foregroundColor(tokens.onSurfaceSecondary)

            AISButton("Scan Another", type: .primary) {
                scanService.reset()
                selectedFile = nil
                pickerState = .idle
            }
        }
        .padding(AISSpacing.xl)
    }

    // MARK: - Error Section

    private var errorSection: some View {
        VStack(spacing: AISSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(tokens.stateError.color)

            Text("Processing Error")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens.onSurface)

            if let error = scanService.error {
                Text(error)
                    .foregroundColor(tokens.onSurfaceSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: AISSpacing.md) {
                AISButton("Try Again", type: .secondary) {
                    if let file = selectedFile {
                        processSelectedFile(file)
                    }
                }

                AISButton("Manual Entry", type: .primary) {
                    // Reset to review with empty result for manual entry
                    var result = DocScanResult(sourceFileId: selectedFile?.id ?? UUID(), providerUsed: .selfMapping)
                    result.status = .review
                    scanService.currentResult = result
                }
            }
        }
        .padding(AISSpacing.xl)
    }

    // MARK: - Posted Section

    private var postedSection: some View {
        VStack(spacing: AISSpacing.lg) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 64))
                .foregroundColor(tokens.actionConfirm.color)

            Text("Invoice Posted")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens.onSurface)

            Text("The AP entry has been created successfully.")
                .foregroundColor(tokens.onSurfaceSecondary)

            AISButton("Scan Another", type: .primary) {
                scanService.reset()
                selectedFile = nil
                pickerState = .idle
            }
        }
        .padding(AISSpacing.xl)
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack {
            AISButton("Cancel", type: .neutral) {
                onCancel()
            }

            Spacer()

            if scanService.status == .review || scanService.status == .approved {
                HStack(spacing: AISSpacing.md) {
                    AISButton("Reject", type: .destructive) {
                        scanService.rejectResult()
                    }

                    AISButton(scanService.status == .approved ? "Post" : "Approve", type: .confirm) {
                        if scanService.status == .approved {
                            if let result = scanService.currentResult {
                                onComplete(result)
                            }
                        } else {
                            scanService.approveResult()
                        }
                    }
                }
            }
        }
        .padding(AISSpacing.md)
    }

    // MARK: - Helper Views

    private var headerFieldsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AISSpacing.md),
            GridItem(.flexible(), spacing: AISSpacing.md)
        ], spacing: AISSpacing.md) {
            if let result = scanService.currentResult {
                EditableFieldRow(field: result.vendorName) { newValue in
                    scanService.currentResult?.vendorName.updateValue(newValue)
                }
                EditableFieldRow(field: result.invoiceNumber) { newValue in
                    scanService.currentResult?.invoiceNumber.updateValue(newValue)
                }
                EditableFieldRow(field: result.invoiceDate) { newValue in
                    scanService.currentResult?.invoiceDate.updateValue(newValue)
                }
                EditableFieldRow(field: result.dueDate) { newValue in
                    scanService.currentResult?.dueDate.updateValue(newValue)
                }
                EditableFieldRow(field: result.poNumber) { newValue in
                    scanService.currentResult?.poNumber.updateValue(newValue)
                }
                EditableFieldRow(field: result.vendorAddress) { newValue in
                    scanService.currentResult?.vendorAddress.updateValue(newValue)
                }
            }
        }
    }

    private var amountFieldsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AISSpacing.md),
            GridItem(.flexible(), spacing: AISSpacing.md),
            GridItem(.flexible(), spacing: AISSpacing.md)
        ], spacing: AISSpacing.md) {
            if let result = scanService.currentResult {
                EditableFieldRow(field: result.subtotal, prefix: "$") { newValue in
                    scanService.currentResult?.subtotal.updateValue(newValue)
                }
                EditableFieldRow(field: result.taxAmount, prefix: "$") { newValue in
                    scanService.currentResult?.taxAmount.updateValue(newValue)
                }
                EditableFieldRow(field: result.totalAmount, prefix: "$") { newValue in
                    scanService.currentResult?.totalAmount.updateValue(newValue)
                }
            }
        }
    }

    private func confidenceBar(confidence: Double) -> some View {
        HStack {
            Text("Extraction Confidence")
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)

            Spacer()

            Text("\(Int(confidence * 100))%")
                .font(.caption.bold())
                .foregroundColor(confidenceColor(confidence))

            ProgressView(value: confidence)
                .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor(confidence)))
                .frame(width: 100)
        }
        .padding(AISSpacing.sm)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.sm)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 { return tokens.actionConfirm.color }
        if confidence >= 0.7 { return tokens.stateWarning.color }
        return tokens.stateError.color
    }

    private func validationErrorsView(errors: [String]) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.xs) {
            ForEach(errors, id: \.self) { error in
                HStack(spacing: AISSpacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(tokens.stateError.color)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(tokens.stateError.color)
                }
            }
        }
        .padding(AISSpacing.sm)
        .background(tokens.stateError.color.opacity(0.1))
        .cornerRadius(AISRadius.sm)
    }

    private func lineItemsTable(items: [InvoiceLineItem]) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("#").frame(width: 30, alignment: .leading)
                Text("Description").frame(maxWidth: .infinity, alignment: .leading)
                Text("Qty").frame(width: 60, alignment: .trailing)
                Text("Price").frame(width: 80, alignment: .trailing)
                Text("Amount").frame(width: 80, alignment: .trailing)
            }
            .font(.caption.bold())
            .foregroundColor(tokens.onSurfaceSecondary)
            .padding(AISSpacing.sm)
            .background(tokens.surfaceSecondary)

            // Rows
            ForEach(items) { item in
                HStack {
                    Text("\(item.lineNumber)").frame(width: 30, alignment: .leading)
                    Text(item.description).frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(format: "%.0f", item.quantity)).frame(width: 60, alignment: .trailing)
                    Text(String(format: "$%.2f", item.unitPrice)).frame(width: 80, alignment: .trailing)
                    Text(String(format: "$%.2f", item.amount)).frame(width: 80, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(tokens.onSurface)
                .padding(AISSpacing.sm)

                Divider()
            }
        }
        .background(tokens.surface)
        .cornerRadius(AISRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .stroke(tokens.onSurface.opacity(0.1), lineWidth: 1)
        )
    }

    private func rawOCRSection(text: String) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("Raw OCR Text")
                .font(.caption.bold())
                .foregroundColor(tokens.onSurfaceSecondary)

            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(tokens.onSurface)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .padding(AISSpacing.sm)
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.sm)
        }
    }

    // MARK: - Actions

    private func processSelectedFile(_ file: AISFileInfo) {
        Task {
            do {
                _ = try await scanService.processDocument(fileInfo: file)
            } catch {
                scanService.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    @Environment(\.aisTokens) private var tokens

    var body: some View {
        HStack(spacing: AISSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(tokens.actionPrimary.color)
            Text(title)
                .font(.headline)
                .foregroundColor(tokens.onSurface)
        }
        .padding(.top, AISSpacing.md)
    }
}

// MARK: - Editable Field Row

struct EditableFieldRow: View {
    let field: ExtractedField
    var prefix: String = ""
    let onUpdate: (String) -> Void

    @State private var editValue: String = ""
    @State private var isEditing = false
    @Environment(\.aisTokens) private var tokens

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label with confidence indicator
            HStack {
                Text(field.displayName)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)

                if field.isRequired {
                    Text("*")
                        .foregroundColor(tokens.stateError.color)
                }

                Spacer()

                // Confidence indicator
                Circle()
                    .fill(confidenceColor)
                    .frame(width: 8, height: 8)
            }

            // Value field
            HStack {
                if !prefix.isEmpty {
                    Text(prefix)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }

                if isEditing {
                    TextField(field.displayName, text: $editValue, onCommit: {
                        onUpdate(editValue)
                        isEditing = false
                    })
                    .textFieldStyle(.plain)
                    .onAppear { editValue = field.mappedValue }
                } else {
                    Text(field.mappedValue.isEmpty ? "-" : field.mappedValue)
                        .foregroundColor(field.mappedValue.isEmpty ? tokens.onSurfaceSecondary : tokens.onSurface)
                }

                Spacer()

                // Edit button
                Button {
                    if isEditing {
                        onUpdate(editValue)
                    } else {
                        editValue = field.mappedValue
                    }
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "checkmark.circle" : "pencil.circle")
                        .foregroundColor(tokens.actionPrimary.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AISSpacing.sm)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.sm)
    }

    private var confidenceColor: Color {
        switch field.confidenceLevel {
        case .high: return tokens.actionConfirm.color
        case .medium: return tokens.stateWarning.color
        case .low: return tokens.stateError.color
        case .manual: return tokens.stateInfo.color
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DocScanAPView_Previews: PreviewProvider {
    static var previews: some View {
        DocScanAPView(
            onComplete: { result in
                print("Complete: \(result)")
            },
            onCancel: {
                print("Cancelled")
            }
        )
        .frame(width: 800, height: 600)
        .withAISTokens()
    }
}
#endif

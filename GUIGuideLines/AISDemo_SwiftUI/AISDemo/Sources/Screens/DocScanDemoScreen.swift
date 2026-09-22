// =============================================================================
// DocScanDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates AI-powered document scanning with OCR extraction for
// Accounts Payable processing.
//
// =============================================================================

import SwiftUI
import Vision
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Demo Provider Tier (for demo results display)
// Note: The reusable AISDocScanProviderTier is defined in AISDocScan.swift

/// Demo-specific provider tier for displaying sample results
private enum DemoProviderTier: Int, CaseIterable, Identifiable {
    case selfMapping = 0
    case browserVision = 1
    case localAgentic = 2
    case cloudLLM = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .selfMapping: return "Manual Entry"
        case .browserVision: return "Browser OCR"
        case .localAgentic: return "Local AI"
        case .cloudLLM: return "Cloud AI"
        }
    }

    var icon: String {
        switch self {
        case .selfMapping: return "person"
        case .browserVision: return "eye"
        case .localAgentic: return "cpu"
        case .cloudLLM: return "cloud"
        }
    }

    var description: String {
        switch self {
        case .selfMapping: return "Manual user entry - no AI processing"
        case .browserVision: return "Client-side OCR using Vision framework"
        case .localAgentic: return "On-device AI model (Core ML)"
        case .cloudLLM: return "Cloud LLM API (Claude, GPT, Gemini)"
        }
    }
}

// MARK: - Demo Line Item

private struct DemoLineItem: Identifiable {
    let id = UUID()
    let description: String
    let quantity: Double
    let unitPrice: Double
    let amount: Double
    let taxCode: String?
}

// MARK: - Demo Document Result

private struct DemoDocScanResult: Identifiable {
    let id: String
    let invoiceNumber: String
    let vendorName: String
    let vendorAddress: String
    let totalAmount: String
    let subtotal: String
    let taxAmount: String
    let invoiceDate: String
    let memberNumber: String
    let status: DemoDocScanStatus
    let providerUsed: DemoProviderTier
    let processingTimeMs: Int
    var rawOCRText: String? = nil
    var lineItems: [DemoLineItem] = []
    var paymentMethod: String = ""
    var transactionId: String = ""
}

private enum DemoDocScanStatus: String {
    case pending
    case review
    case approved

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .review: return "Review"
        case .approved: return "Approved"
        }
    }

    var badgeState: AISSemanticState {
        switch self {
        case .pending: return .pending
        case .review: return .warning
        case .approved: return .completed
        }
    }
}

// MARK: - Doc Scan Demo Screen

struct DocScanDemoScreen: View {
    @Environment(\.aisTokens) private var tokens
    @State private var capturedResults: [DemoDocScanResult] = []
    @State private var selectedProvider: DemoProviderTier = .browserVision
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    @State private var selectedFile: AISFileInfo?
    @State private var pickerState: AISFilePickerState = .idle
    @State private var showLiveDemo = false
    @State private var selectedResultForDetails: DemoDocScanResult?

    private let sampleResults: [DemoDocScanResult] = [
        DemoDocScanResult(
            id: "1",
            invoiceNumber: "INV-2024-001",
            vendorName: "Acme Corp",
            vendorAddress: "123 Business Street, New York, NY 10001",
            totalAmount: "1250.00",
            subtotal: "1250.00",
            taxAmount: "0.00",
            invoiceDate: "2024-03-15",
            memberNumber: "",
            status: .approved,
            providerUsed: .browserVision,
            processingTimeMs: 342,
            rawOCRText: """
            INVOICE
            ==========================================

            Invoice Number: INV-2024-001
            Invoice Date: 2024-03-15

            FROM:
            Acme Corp
            123 Business Street
            Suite 100
            New York, NY 10001

            BILL TO:
            Your Company Name
            456 Corporate Ave
            San Francisco, CA 94102

            ------------------------------------------
            ITEMS:
            ------------------------------------------
            Professional Services          $1,250.00

            ------------------------------------------
            SUBTOTAL:                       $1,250.00
            TAX (0%):                       $0.00
            ------------------------------------------
            TOTAL DUE:                      $1,250.00
            ==========================================

            Payment Terms: Net 30
            Due Date: 2024-04-15

            Thank you for your business!
            """,
            lineItems: [
                DemoLineItem(description: "Professional Services", quantity: 1, unitPrice: 1250.00, amount: 1250.00, taxCode: nil)
            ],
            paymentMethod: "",
            transactionId: ""
        ),
        DemoDocScanResult(
            id: "2",
            invoiceNumber: "INV-2024-002",
            vendorName: "TechSupply Inc",
            vendorAddress: "789 Tech Boulevard, Austin, TX 78701",
            totalAmount: "3875.50",
            subtotal: "3875.50",
            taxAmount: "0.00",
            invoiceDate: "2024-03-18",
            memberNumber: "",
            status: .review,
            providerUsed: .cloudLLM,
            processingTimeMs: 1250,
            rawOCRText: """
            INVOICE
            ==========================================

            Invoice Number: INV-2024-002
            Invoice Date: 2024-03-18

            FROM:
            TechSupply Inc
            789 Tech Boulevard
            Floor 5
            Austin, TX 78701

            BILL TO:
            Your Company Name
            456 Corporate Ave
            San Francisco, CA 94102

            ------------------------------------------
            ITEMS:
            ------------------------------------------
            Server Hardware                 $2,500.00
            Network Equipment                 $875.50
            Installation Services             $500.00

            ------------------------------------------
            SUBTOTAL:                       $3,875.50
            TAX (0%):                       $0.00
            ------------------------------------------
            TOTAL DUE:                      $3,875.50
            ==========================================

            Payment Terms: Net 45
            Due Date: 2024-05-02

            Thank you for your business!
            """,
            lineItems: [
                DemoLineItem(description: "Server Hardware", quantity: 1, unitPrice: 2500.00, amount: 2500.00, taxCode: nil),
                DemoLineItem(description: "Network Equipment", quantity: 1, unitPrice: 875.50, amount: 875.50, taxCode: nil),
                DemoLineItem(description: "Installation Services", quantity: 1, unitPrice: 500.00, amount: 500.00, taxCode: nil)
            ],
            paymentMethod: "",
            transactionId: ""
        ),
    ]

    private let features: [(icon: String, title: String, description: String)] = [
        ("cpu", "AI Router", "Tiered AI provider fallback chain"),
        ("eye", "OCR Extraction", "Automatic field recognition"),
        ("checkmark.circle", "Validation", "Built-in approval workflow"),
        ("doc.text", "Editable Fields", "Review and correct values"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                headerSection
                headerCard
                aboutSection
                featuresGrid
                demoButton

                if !capturedResults.isEmpty {
                    capturedResultsSection
                }

                usageExample
                providerTiersSection
                apiReferenceSection
            }
            .padding(AISSpacing.lg)
        }
        .background(Color(tokens.surface))
        .navigationTitle("Document Scan")
        .sheet(item: $selectedResultForDetails) { result in
            DemoOCROutputSheet(result: result)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.xs) {
            Text("Document Scan")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(tokens.onSurface))

            Text("AI-powered document scanning with OCR extraction for Accounts Payable processing.")
                .font(.body)
                .foregroundColor(Color(tokens.onSurfaceSecondary))
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: AISSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(Color(tokens.actionPrimary.color).opacity(0.2))
                    .frame(width: 72, height: 72)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(Color(tokens.actionPrimary.color))
            }

            VStack(alignment: .leading, spacing: AISSpacing.xs) {
                Text("AIS DocScan")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(tokens.onSurface))

                Text("AI-Powered Document Scanning")
                    .font(.subheadline)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }

            Spacer()
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("About DocScan")
                .font(.headline)
                .foregroundColor(Color(tokens.onSurface))

            Text("DocScan combines AISMediaPicker for file selection with AI-powered OCR extraction. It supports multiple AI providers in a tiered fallback chain, from client-side Vision OCR to cloud LLMs for intelligent field extraction.")
                .font(.body)
                .foregroundColor(Color(tokens.onSurfaceSecondary))
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surface))
        )
    }

    // MARK: - Features Grid

    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Features")
                .font(.headline)
                .foregroundColor(Color(tokens.onSurface))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AISSpacing.md) {
                ForEach(features.indices, id: \.self) { index in
                    featureCard(
                        icon: features[index].icon,
                        title: features[index].title,
                        description: features[index].description
                    )
                }
            }
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AISSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AISRadius.sm)
                    .fill(Color(tokens.actionPrimary.color).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(tokens.actionPrimary.color))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }

            Spacer()
        }
        .padding(AISSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.surface))
        )
    }

    // MARK: - Demo Button

    private var demoButton: some View {
        VStack(spacing: AISSpacing.md) {
            // Provider selector
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("AI Provider")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                HStack(spacing: AISSpacing.sm) {
                    ForEach(DemoProviderTier.allCases) { tier in
                        providerButton(tier)
                    }
                }
            }

            Divider()

            // File selection section
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
                .padding(AISSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AISRadius.md)
                        .fill(Color(tokens.surfaceSecondary))
                )
            }

            // Processing progress
            if isProcessing {
                VStack(spacing: AISSpacing.sm) {
                    ProgressView(value: processingProgress)
                        .progressViewStyle(LinearProgressViewStyle())

                    HStack {
                        Image(systemName: selectedProvider.icon)
                            .font(.caption)
                        Text("Processing with \(selectedProvider.displayName)...")
                            .font(.caption)
                    }
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
                }
            }

            // Action buttons
            HStack(spacing: AISSpacing.md) {
                // File picker
                AISMediaPicker(
                    state: $pickerState,
                    allowedTypes: [.image, .pdf],
                    allowsMultiple: false,
                    buttonLabel: selectedFile == nil ? "Select Document" : "Change",
                    buttonType: selectedFile == nil ? .primary : .secondary,
                    showSourceSelector: false,
                    onFilesSelected: { files in
                        if let file = files.first {
                            selectedFile = file
                        }
                    }
                )

                // Process button
                if selectedFile != nil {
                    AISButton(
                        "Process Document",
                        type: .confirm,
                        icon: "cpu",
                        isLoading: isProcessing
                    ) {
                        processDocument()
                    }
                    .disabled(isProcessing)
                }
            }

            // Simulate button (for demo without file)
            if selectedFile == nil {
                AISButton(
                    "Simulate with Sample Data",
                    type: .neutral,
                    style: .outlined,
                    action: simulateCapture
                )

                Text("Or simulate the DocScan workflow with sample data")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surface))
        )
    }

    private func providerButton(_ tier: DemoProviderTier) -> some View {
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
                          : Color(tokens.surfaceSecondary))
            )
            .foregroundColor(selectedProvider == tier
                             ? Color(tokens.actionPrimary.color)
                             : Color(tokens.onSurfaceSecondary))
        }
        .buttonStyle(.plain)
    }

    private func processDocument() {
        guard let file = selectedFile else { return }

        isProcessing = true
        processingProgress = 0

        let startTime = Date()

        // Update progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            processingProgress = 0.1
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
                    self.isProcessing = false
                    self.selectedFile = nil
                    print("Failed to load image from file: \(file.localPath)")
                }
                return
            }
            #else
            guard let uiImage = UIImage(contentsOfFile: file.localPath),
                  let cgImage = uiImage.cgImage else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.selectedFile = nil
                    print("Failed to load image from file: \(file.localPath)")
                }
                return
            }
            #endif

            DispatchQueue.main.async {
                self.processingProgress = 0.3
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

            DispatchQueue.main.async {
                self.processingProgress = 0.5
            }

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                ocrError = error.localizedDescription
            }

            DispatchQueue.main.async {
                self.processingProgress = 0.8
            }

            // Process results on main thread
            DispatchQueue.main.async {
                let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

                // Parse fields from OCR text
                let parsedFields = self.parseOCRFields(ocrText)

                var result = DemoDocScanResult(
                    id: file.id.uuidString,
                    invoiceNumber: parsedFields.invoiceNumber,
                    vendorName: parsedFields.vendorName,
                    vendorAddress: parsedFields.vendorAddress,
                    totalAmount: parsedFields.totalAmount,
                    subtotal: parsedFields.subtotal,
                    taxAmount: parsedFields.taxAmount,
                    invoiceDate: parsedFields.invoiceDate,
                    memberNumber: parsedFields.memberNumber,
                    status: .review,
                    providerUsed: self.selectedProvider,
                    processingTimeMs: processingTime,
                    rawOCRText: ocrText.isEmpty ? "No text detected" : ocrText,
                    lineItems: parsedFields.lineItems,
                    paymentMethod: parsedFields.paymentMethod,
                    transactionId: parsedFields.transactionId
                )

                self.processingProgress = 1.0
                self.capturedResults.insert(result, at: 0)
                self.isProcessing = false
                self.selectedFile = nil

                if let ocrError = ocrError {
                    print("OCR Error: \(ocrError)")
                }
            }
        }
    }

    /// Parsed OCR result with all extracted fields
    private struct ParsedOCRResult {
        var vendorName: String = ""
        var vendorAddress: String = ""
        var invoiceNumber: String = ""
        var totalAmount: String = ""
        var subtotal: String = ""
        var taxAmount: String = ""
        var invoiceDate: String = ""
        var memberNumber: String = ""
        var paymentMethod: String = ""
        var transactionId: String = ""
        var lineItems: [DemoLineItem] = []
    }

    /// Parse OCR text to extract invoice fields
    private func parseOCRFields(_ text: String) -> ParsedOCRResult {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        let nonEmptyLines = lines.filter { !$0.isEmpty }

        var result = ParsedOCRResult()

        // Known retail stores for high-confidence matching
        let knownStores = ["COSTCO", "WALMART", "TARGET", "SAFEWAY", "KROGER", "WHOLE FOODS",
                          "TRADER JOE", "CVS", "WALGREENS", "HOME DEPOT", "LOWES", "AMAZON",
                          "BEST BUY", "STAPLES", "OFFICE DEPOT", "NORDSTROM", "MACY"]

        // Find vendor name
        for store in knownStores {
            if text.uppercased().contains(store) {
                for line in nonEmptyLines.prefix(10) {
                    if line.uppercased().contains(store) {
                        result.vendorName = line.trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
                break
            }
        }

        // Fallback: first substantial line
        if result.vendorName.isEmpty {
            for line in nonEmptyLines.prefix(5) {
                let hasLetters = line.rangeOfCharacter(from: .letters) != nil
                let isNotPrice = !line.contains("$") && !line.uppercased().contains("TOTAL")
                if hasLetters && isNotPrice && line.count > 3 {
                    result.vendorName = line
                    break
                }
            }
        }

        // Vendor address - look for address patterns
        if let match = text.range(of: #"\d+\s+[\w\s]+(?:Ave|St|Rd|Blvd|Dr|Ln|Way|Ct)[,.\s]+[\w\s]+,?\s*[A-Z]{2}\s+\d{5}"#, options: [.regularExpression, .caseInsensitive]) {
            result.vendorAddress = String(text[match]).trimmingCharacters(in: .whitespaces)
        }

        // Member number (for Costco etc.)
        if let match = text.range(of: #"(?:Member|Mbr)\s*(?:#|No\.?|:)?\s*(\d{10,})"#, options: [.regularExpression, .caseInsensitive]) {
            var value = String(text[match])
            if let numMatch = value.range(of: #"\d{10,}"#, options: .regularExpression) {
                result.memberNumber = String(value[numMatch])
            }
        }

        // Invoice/Receipt number patterns
        let invoicePatterns = [
            #"(?:Invoice|Receipt|Trans(?:action)?|Order|Ref(?:erence)?)\s*(?:#|No\.?|Number|:)?\s*[:\s]?([A-Z0-9\-]+)"#,
            #"#\s*(\d{4,})"#
        ]
        for pattern in invoicePatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                value = value.replacingOccurrences(of: #"(?:Invoice|Receipt|Trans(?:action)?|Order|Ref(?:erence)?|#|No\.?|Number|:)"#,
                                                    with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    result.invoiceNumber = value
                    break
                }
            }
        }

        // Total amount patterns
        let totalPatterns = [
            #"(?:TOTAL|Grand\s*Total|Amount\s*Due|Balance\s*Due)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)"#,
            #"\*+\s*TOTAL\s*\$?\s*([\d,]+\.?\d*)"#
        ]
        for pattern in totalPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                if let numMatch = value.range(of: #"[\d,]+\.?\d*$"#, options: .regularExpression) {
                    value = String(value[numMatch]).replacingOccurrences(of: ",", with: "")
                    result.totalAmount = value
                    break
                }
            }
        }

        // Subtotal
        if let match = text.range(of: #"(?:Subtotal|Sub\s*Total)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)"#, options: [.regularExpression, .caseInsensitive]) {
            var value = String(text[match])
            if let numMatch = value.range(of: #"[\d,]+\.?\d*$"#, options: .regularExpression) {
                result.subtotal = String(value[numMatch]).replacingOccurrences(of: ",", with: "")
            }
        }

        // Tax amount
        if let match = text.range(of: #"(?:TAX|Sales\s*Tax|VAT)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)"#, options: [.regularExpression, .caseInsensitive]) {
            var value = String(text[match])
            if let numMatch = value.range(of: #"[\d,]+\.?\d*$"#, options: .regularExpression) {
                result.taxAmount = String(value[numMatch]).replacingOccurrences(of: ",", with: "")
            }
        }

        // Date patterns
        let datePatterns = [
            #"(?:Date|Time|Purchased)[:\s]+(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})"#,
            #"(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})\s+\d{1,2}:\d{2}"#,
            #"(\w{3,9}\s+\d{1,2},?\s+\d{4})"#
        ]
        for pattern in datePatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var value = String(text[match])
                if let dateMatch = value.range(of: #"\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}"#, options: .regularExpression) {
                    value = String(value[dateMatch])
                } else if let dateMatch = value.range(of: #"\w{3,9}\s+\d{1,2},?\s+\d{4}"#, options: .regularExpression) {
                    value = String(value[dateMatch])
                }
                result.invoiceDate = value
                break
            }
        }

        // Payment method
        let paymentPatterns = ["VISA", "MASTERCARD", "AMEX", "DISCOVER", "CASH", "DEBIT", "CREDIT"]
        for payment in paymentPatterns {
            if text.uppercased().contains(payment) {
                result.paymentMethod = payment.capitalized
                break
            }
        }

        // Transaction ID
        if let match = text.range(of: #"(?:Tran(?:saction)?\s*(?:ID|#|No)?|Auth(?:orization)?)\s*[:\s]?\s*(\d{6,})"#, options: [.regularExpression, .caseInsensitive]) {
            var value = String(text[match])
            if let numMatch = value.range(of: #"\d{6,}"#, options: .regularExpression) {
                result.transactionId = String(value[numMatch])
            }
        }

        // Parse line items
        result.lineItems = parseLineItems(from: nonEmptyLines)

        // Defaults if nothing found
        if result.vendorName.isEmpty { result.vendorName = "Unknown Vendor" }
        if result.invoiceNumber.isEmpty { result.invoiceNumber = "N/A" }
        if result.totalAmount.isEmpty { result.totalAmount = "0.00" }
        if result.invoiceDate.isEmpty { result.invoiceDate = formatDate(Date()) }

        return result
    }

    /// Parse line items from OCR text lines
    /// Supports Costco format: SKU + description on one line, price on next line
    private func parseLineItems(from lines: [String]) -> [DemoLineItem] {
        var items: [DemoLineItem] = []

        // Skip keywords for header/footer lines
        let skipKeywords = [
            "SUBTOTAL", "SUB TOTAL", "TOTAL", "TAX", "CASH", "CREDIT", "DEBIT",
            "CHANGE", "BALANCE", "PAYMENT", "THANK YOU", "WELCOME", "MEMBER",
            "CARD", "VISA", "MASTERCARD", "AMEX", "DISCOVER", "DATE", "TIME",
            "RECEIPT", "TRANSACTION", "REGISTER", "CASHIER", "STORE", "TEL",
            "PHONE", "ADDRESS", "WWW", "HTTP", ".COM", "SAVINGS", "DISCOUNT",
            "ITEMS SOLD", "AMOUNT", "WHSE", "TRM", "TRN", "OP#", "SEG#", "AID",
            "WHOLESALE", "APPROVAL", "REF", "ENTRY", "CHIP READ", "COSTCO"
        ]

        // Skip patterns for non-item lines (locations, card numbers, identifiers)
        let skipPatterns = [
            #"^[A-Za-z]+\s*#\s*\d+$"#,                    // "Eastvale #1317"
            #"^X{4,}"#,                                   // "XXXXXXXXXXXX8071" (masked card)
            #"^\*{4,}"#,                                  // "****1234" (masked card)
            #"^\d{1,2}/\d{1,2}/\d{2,4}"#,                 // Date lines
            #"^\d+\s+[A-Za-z]+\s+(Ave|St|Rd|Blvd|Dr)"#,   // Address lines
            #"^[A-Z]{2}\s+\d{5}"#,                        // State ZIP
            #"^Member\s"#,                                // Member info
            #"^\(\d{3}\)"#,                               // Phone numbers
            #"^\d{3}[-.\s]\d{3}[-.\s]\d{4}"#,             // Phone numbers
        ]

        var i = 0
        while i < lines.count {
            let trimmedLine = lines[i].trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else {
                i += 1
                continue
            }

            // Skip header/footer lines by keyword
            let upperLine = trimmedLine.uppercased()
            var shouldSkip = false
            for keyword in skipKeywords {
                if upperLine.contains(keyword) {
                    shouldSkip = true
                    break
                }
            }
            if shouldSkip {
                i += 1
                continue
            }

            // Skip by pattern
            for pattern in skipPatterns {
                if trimmedLine.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                    shouldSkip = true
                    break
                }
            }
            if shouldSkip {
                i += 1
                continue
            }

            // Costco format: SKU (6-7 digits) + description on one line, price on next line
            // Example: "1806222 KOHLER SINK" followed by "399.99 A"
            if let skuMatch = trimmedLine.range(of: #"^(\d{6,7})\s+(.+)$"#, options: .regularExpression) {
                let lineContent = String(trimmedLine[skuMatch])

                // Extract description after SKU
                if let descMatch = lineContent.range(of: #"^\d{6,7}\s+"#, options: .regularExpression) {
                    let description = String(lineContent[descMatch.upperBound...]).trimmingCharacters(in: .whitespaces)

                    // Look at next line for price
                    if i + 1 < lines.count {
                        let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)

                        // Price line: "399.99 A" or "399.99" or "-5.00 A" (negative for discounts)
                        if let priceMatch = nextLine.range(of: #"^-?\d+\.\d{2}\s*[A-Z]?$"#, options: .regularExpression) {
                            let priceStr = String(nextLine[priceMatch])

                            // Extract tax code if present
                            var taxCode: String? = nil
                            var priceValue = priceStr
                            if let taxMatch = priceStr.range(of: #"\s+([A-Z])$"#, options: .regularExpression) {
                                taxCode = String(priceStr[taxMatch]).trimmingCharacters(in: .whitespaces)
                                priceValue = String(priceStr[..<taxMatch.lowerBound])
                            }

                            if let amount = Double(priceValue.trimmingCharacters(in: .whitespaces)) {
                                // Skip negative amounts (discounts) - but could be kept if desired
                                if amount > 0 && amount <= 10000 && !description.isEmpty {
                                    items.append(DemoLineItem(
                                        description: description,
                                        quantity: 1.0,
                                        unitPrice: amount,
                                        amount: amount,
                                        taxCode: taxCode
                                    ))
                                    i += 2 // Skip both lines
                                    continue
                                }
                            }
                        }
                    }
                }
            }

            // Standard format: description + price on same line
            // Require price to have decimal point (###.##)
            if let priceMatch = trimmedLine.range(of: #"\$?\s*(\d+\.\d{2})\s*([A-Z])?\s*$"#, options: .regularExpression) {
                let priceStr = String(trimmedLine[priceMatch])
                    .replacingOccurrences(of: "$", with: "")
                    .trimmingCharacters(in: .whitespaces)

                // Extract just the numeric part
                var taxCode: String? = nil
                var numericPrice = priceStr
                if let taxMatch = priceStr.range(of: #"\s+([A-Z])$"#, options: .regularExpression) {
                    taxCode = String(priceStr[taxMatch]).trimmingCharacters(in: .whitespaces)
                    numericPrice = String(priceStr[..<taxMatch.lowerBound])
                }

                let amount = Double(numericPrice.trimmingCharacters(in: .whitespaces)) ?? 0.0

                // Skip very small or very large amounts
                guard amount >= 0.01 && amount <= 10000 else {
                    i += 1
                    continue
                }

                // Extract description (everything before price)
                var description = String(trimmedLine[..<priceMatch.lowerBound]).trimmingCharacters(in: .whitespaces)

                // Default quantity and unit price
                var quantity = 1.0
                var unitPrice = amount

                // Check for quantity patterns like "2 @ $5.99"
                if let qtyMatch = description.range(of: #"(\d+)\s*[@xX]\s*\$?(\d+\.\d{2})"#, options: .regularExpression) {
                    let qtyStr = String(description[qtyMatch])
                    if let numMatch = qtyStr.range(of: #"^\d+"#, options: .regularExpression) {
                        let qty = Double(qtyStr[numMatch]) ?? 1.0
                        if qty > 0 && qty < 1000 {
                            quantity = qty
                            if let unitMatch = qtyStr.range(of: #"[\d.]+$"#, options: .regularExpression) {
                                unitPrice = Double(qtyStr[unitMatch]) ?? (amount / quantity)
                            } else {
                                unitPrice = amount / quantity
                            }
                            description = description.replacingOccurrences(of: qtyStr, with: "").trimmingCharacters(in: .whitespaces)
                        }
                    }
                }

                // Clean up description - remove SKU numbers at start
                description = description
                    .replacingOccurrences(of: #"^\d{6,}\s+"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)

                // Skip if description is too short or just numbers/symbols
                guard description.count >= 2 else {
                    i += 1
                    continue
                }
                guard description.range(of: #"[a-zA-Z]{2,}"#, options: .regularExpression) != nil else {
                    i += 1
                    continue
                }

                items.append(DemoLineItem(
                    description: description,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    amount: amount,
                    taxCode: taxCode
                ))
            }

            i += 1

            // Limit to reasonable number
            if items.count >= 50 { break }
        }

        return items
    }

    private func extractVendorName(from fileName: String) -> String {
        // Simple extraction from filename
        let name = fileName
            .replacingOccurrences(of: ".pdf", with: "")
            .replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized

        return name.isEmpty ? "Unknown Vendor" : name
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func simulateCapture() {
        capturedResults.insert(contentsOf: sampleResults, at: 0)
    }

    // MARK: - Captured Results Section

    private var capturedResultsSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            HStack {
                Text("Captured Documents (\(capturedResults.count))")
                    .font(.headline)
                    .foregroundColor(Color(tokens.onSurface))

                Spacer()

                Button("Clear All") {
                    capturedResults.removeAll()
                }
                .font(.subheadline)
                .foregroundColor(Color(tokens.actionDestructive.color))
            }

            ForEach(capturedResults) { result in
                resultCard(result)
            }
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surface))
        )
    }

    private func resultCard(_ result: DemoDocScanResult) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            HStack {
                HStack(spacing: AISSpacing.xs) {
                    Image(systemName: "doc.text")
                        .foregroundColor(Color(tokens.actionPrimary.color))

                    Text("Invoice #\(result.invoiceNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(tokens.onSurface))
                }

                Spacer()

                AISStateBadge(result.status.badgeState, size: .small)
            }

            HStack(spacing: AISSpacing.lg) {
                Label(result.vendorName, systemImage: "building.2")
                Label("$\(result.totalAmount)", systemImage: "dollarsign")
                Label(result.invoiceDate, systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(Color(tokens.onSurfaceSecondary))

            HStack {
                HStack(spacing: AISSpacing.xs) {
                    Image(systemName: result.providerUsed.icon)
                        .font(.caption2)

                    Text("Processed with \(result.providerUsed.displayName) in \(result.processingTimeMs)ms")
                        .font(.caption2)
                }
                .foregroundColor(Color(tokens.onSurfaceSecondary))

                Spacer()

                Button {
                    selectedResultForDetails = result
                } label: {
                    HStack(spacing: AISSpacing.xs) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.caption)
                        Text("View Details")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(tokens.actionPrimary.color))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    // MARK: - Usage Example

    private var usageExample: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Usage Example")
                .font(.headline)
                .foregroundColor(Color(tokens.onSurface))

            Text("""
                import AISComponents

                AISDocScanWidget(
                    documentType: .invoice,
                    preferredProvider: .browserVision
                ) { result in
                    // Post to accounting system
                    viewModel.createAPEntry(result)
                } onCancel: {
                    dismiss()
                }
                """)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(tokens.onSurface))
                .padding(AISSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AISRadius.md)
                        .fill(Color(tokens.surfaceSecondary))
                )
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surface))
        )
    }

    // MARK: - Provider Tiers Section

    private var providerTiersSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("AI Provider Tiers")
                .font(.headline)
                .foregroundColor(Color(tokens.onSurface))

            ForEach(DemoProviderTier.allCases) { tier in
                providerTierRow(tier)
            }
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surface))
        )
    }

    private func providerTierRow(_ tier: DemoProviderTier) -> some View {
        HStack(spacing: AISSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AISRadius.sm)
                    .fill(Color(tokens.actionPrimary.color).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: tier.icon)
                    .foregroundColor(Color(tokens.actionPrimary.color))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Tier \(tier.rawValue): \(tier.displayName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                Text(tier.description)
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }

            Spacer()
        }
        .padding(AISSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    // MARK: - API Reference Section

    private var apiReferenceSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("API Reference")
                .font(.headline)
                .foregroundColor(Color(tokens.onSurface))

            VStack(spacing: 0) {
                apiReferenceHeader
                apiReferenceRow("documentType", "DocumentType", "Type of document (invoice, receipt, contract)")
                apiReferenceRow("preferredProvider", "DemoProviderTier", "Preferred AI provider for OCR/extraction")
                apiReferenceRow("onComplete", "(DocScanResult) -> Void", "Callback when document is captured and approved")
                apiReferenceRow("onCancel", "() -> Void", "Callback when user cancels the workflow")
                apiReferenceRow("extractLineItems", "Bool", "Whether to extract line items (default: true)")
            }
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(Color(tokens.surfaceSecondary))
            )
            .clipShape(RoundedRectangle(cornerRadius: AISRadius.md))
        }
        .padding(AISSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surface))
        )
    }

    private var apiReferenceHeader: some View {
        HStack {
            Text("Prop")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Type")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Description")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(Color(tokens.onSurface))
        .padding(.horizontal, AISSpacing.sm)
        .padding(.vertical, AISSpacing.xs)
        .background(Color(tokens.onSurface).opacity(0.1))
    }

    private func apiReferenceRow(_ prop: String, _ type: String, _ description: String) -> some View {
        HStack {
            Text(prop)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(type)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(description)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundColor(Color(tokens.onSurfaceSecondary))
        .padding(.horizontal, AISSpacing.sm)
        .padding(.vertical, AISSpacing.xs)
    }
}

// MARK: - Demo OCR Output Sheet

private struct DemoOCROutputSheet: View {
    @Environment(\.aisTokens) private var tokens
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0

    let result: DemoDocScanResult

    private var jsonOutput: String {
        let lineItemsJson = result.lineItems.map { item in
            """
                {
                  "description": "\(item.description)",
                  "quantity": \(item.quantity),
                  "unitPrice": \(item.unitPrice),
                  "amount": \(item.amount)\(item.taxCode != nil ? ",\n          \"taxCode\": \"\(item.taxCode!)\"" : "")
                }
            """
        }.joined(separator: ",\n")

        let totalAmount = Double(result.totalAmount.replacingOccurrences(of: ",", with: "")) ?? 0.0
        let subtotal = Double(result.subtotal.replacingOccurrences(of: ",", with: "")) ?? 0.0
        let taxAmount = Double(result.taxAmount.replacingOccurrences(of: ",", with: "")) ?? 0.0

        return """
        {
          "store": {
            "name": "\(result.vendorName)"\(result.vendorAddress.isEmpty ? "" : ",\n    \"address\": \"\(result.vendorAddress)\"")
          },\(result.memberNumber.isEmpty ? "" : "\n  \"memberNumber\": \"\(result.memberNumber)\",")
          "transaction": {
            "invoiceNumber": "\(result.invoiceNumber)",
            "date": "\(result.invoiceDate)"\(result.transactionId.isEmpty ? "" : ",\n    \"transactionId\": \"\(result.transactionId)\"")\(result.paymentMethod.isEmpty ? "" : ",\n    \"paymentMethod\": \"\(result.paymentMethod)\"")
          },
          "items": [
        \(lineItemsJson.isEmpty ? "    // No line items detected" : lineItemsJson)
          ],
          "totals": {
            "subtotal": \(subtotal),
            "tax": \(taxAmount),
            "total": \(totalAmount)
          },
          "extraction": {
            "provider": "\(result.providerUsed.displayName)",
            "processingTimeMs": \(result.processingTimeMs),
            "status": "\(result.status.rawValue)"
          }
        }
        """
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    tabButton("Text", index: 0)
                    tabButton("JSON", index: 1)
                }
                .padding(AISSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AISRadius.md)
                        .fill(Color(tokens.surfaceSecondary))
                )
                .padding(.horizontal, AISSpacing.lg)
                .padding(.top, AISSpacing.md)

                // Content
                ScrollView {
                    if selectedTab == 0 {
                        textContent
                    } else {
                        jsonContent
                    }
                }
                .padding(AISSpacing.lg)
            }
            .background(Color(tokens.surface))
            .navigationTitle("OCR Output")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }

    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedTab == index
                                 ? Color(tokens.actionPrimary.color)
                                 : Color(tokens.onSurfaceSecondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, AISSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AISRadius.sm)
                        .fill(selectedTab == index
                              ? Color(tokens.surface)
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text(result.rawOCRText ?? generateMockOCRText())
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(tokens.onSurface))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    private var jsonContent: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text(jsonOutput)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(tokens.onSurface))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    private func generateMockOCRText() -> String {
        """
        INVOICE
        ==========================================

        Invoice Number: \(result.invoiceNumber)
        Invoice Date: \(result.invoiceDate)

        FROM:
        \(result.vendorName)
        123 Business Street
        Suite 100
        New York, NY 10001

        BILL TO:
        Your Company Name
        456 Corporate Ave
        San Francisco, CA 94102

        ------------------------------------------
        ITEMS:
        ------------------------------------------
        Professional Services          $\(result.totalAmount)

        ------------------------------------------
        SUBTOTAL:                       $\(result.totalAmount)
        TAX (0%):                       $0.00
        ------------------------------------------
        TOTAL DUE:                      $\(result.totalAmount)
        ==========================================

        Payment Terms: Net 30
        Due Date: \(result.invoiceDate)

        Thank you for your business!
        """
    }

    private func copyToClipboard() {
        let content = selectedTab == 0
            ? (result.rawOCRText ?? generateMockOCRText())
            : jsonOutput

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #else
        UIPasteboard.general.string = content
        #endif
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DocScanDemoScreen()
            .environment(\.aisTokens, AISTokenSet.light)
    }
}

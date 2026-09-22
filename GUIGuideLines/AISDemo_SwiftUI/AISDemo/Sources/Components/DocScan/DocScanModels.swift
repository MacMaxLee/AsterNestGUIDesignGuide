// =============================================================================
// DocScanModels.swift
// AIS DocScan AP Module - Data Models
// =============================================================================
//
// PURPOSE:
// Defines data models for the DocScan AP (Accounts Payable) module including
// extracted field data, AI provider configuration, and mapping states.
//
// AI ROUTER PROVIDER CHAIN:
// Tier 0: Self mapping (manual user entry)
// Tier 1: Apple Intelligence / Vision (iOS/macOS on-device, free)
// Tier 2: Local Agentic AI (on-device model)
// Tier 3: LLM Fallback (Claude/ChatGPT/Gemini cloud API)
//
// =============================================================================

import Foundation

// MARK: - AI Provider Types

/// Represents the AI provider used for document extraction
public enum AIProviderTier: Int, CaseIterable, Codable, Identifiable {
    case selfMapping = 0   // Manual user entry
    case appleVision = 1   // Apple Intelligence / Vision (on-device)
    case localAgentic = 2  // Local AI model
    case cloudLLM = 3      // Cloud-based LLM (Claude, GPT, Gemini)

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .selfMapping: return "Manual Entry"
        case .appleVision: return "Apple Intelligence"
        case .localAgentic: return "Local AI"
        case .cloudLLM: return "Cloud AI"
        }
    }

    public var iconName: String {
        switch self {
        case .selfMapping: return "person.fill"
        case .appleVision: return "apple.logo"
        case .localAgentic: return "cpu"
        case .cloudLLM: return "cloud"
        }
    }

    public var description: String {
        switch self {
        case .selfMapping: return "User fills all fields manually"
        case .appleVision: return "On-device Apple Vision OCR"
        case .localAgentic: return "On-device AI model"
        case .cloudLLM: return "Cloud LLM (requires API key)"
        }
    }

    /// Whether this tier requires network connectivity
    public var requiresNetwork: Bool {
        self == .cloudLLM
    }

    /// Whether this tier is available on current platform
    public var isAvailable: Bool {
        switch self {
        case .selfMapping: return true
        case .appleVision:
            #if os(iOS) || os(macOS)
            if #available(iOS 16.0, macOS 13.0, *) {
                return true
            }
            #endif
            return false
        case .localAgentic: return true // Depends on model availability
        case .cloudLLM: return true
        }
    }
}

// MARK: - Extraction Confidence

/// Confidence level for extracted field values
public enum ExtractionConfidence: String, Codable {
    case high = "high"         // > 90% confidence
    case medium = "medium"     // 70-90% confidence
    case low = "low"           // < 70% confidence
    case manual = "manual"     // User-entered value

    public var color: String {
        switch self {
        case .high: return "actionConfirm"
        case .medium: return "stateWarning"
        case .low: return "stateError"
        case .manual: return "stateInfo"
        }
    }

    public var threshold: Double {
        switch self {
        case .high: return 0.9
        case .medium: return 0.7
        case .low: return 0.0
        case .manual: return 1.0
        }
    }
}

// MARK: - Extracted Field

/// Represents a single extracted field with value and confidence
public struct ExtractedField: Identifiable, Codable, Hashable {
    public let id: UUID
    public var fieldKey: String        // e.g., "vendor_name", "invoice_number"
    public var displayName: String     // e.g., "Vendor Name", "Invoice Number"
    public var extractedValue: String  // Raw OCR value
    public var mappedValue: String     // Normalized/cleaned value
    public var confidence: Double      // 0.0 - 1.0
    public var confidenceLevel: ExtractionConfidence
    public var isRequired: Bool
    public var isEdited: Bool          // User modified this field
    public var boundingBox: CGRect?    // Location in source document

    public init(
        id: UUID = UUID(),
        fieldKey: String,
        displayName: String,
        extractedValue: String = "",
        mappedValue: String = "",
        confidence: Double = 0.0,
        isRequired: Bool = false,
        isEdited: Bool = false,
        boundingBox: CGRect? = nil
    ) {
        self.id = id
        self.fieldKey = fieldKey
        self.displayName = displayName
        self.extractedValue = extractedValue
        self.mappedValue = mappedValue.isEmpty ? extractedValue : mappedValue
        self.confidence = confidence
        self.confidenceLevel = Self.calculateConfidenceLevel(confidence, isEdited: isEdited)
        self.isRequired = isRequired
        self.isEdited = isEdited
        self.boundingBox = boundingBox
    }

    private static func calculateConfidenceLevel(_ confidence: Double, isEdited: Bool) -> ExtractionConfidence {
        if isEdited { return .manual }
        if confidence >= 0.9 { return .high }
        if confidence >= 0.7 { return .medium }
        return .low
    }

    /// Update mapped value and mark as edited
    public mutating func updateValue(_ newValue: String) {
        mappedValue = newValue
        isEdited = true
        confidenceLevel = .manual
    }
}

// MARK: - Line Item

/// Represents a single line item on an invoice
public struct InvoiceLineItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var lineNumber: Int
    public var description: String
    public var quantity: Double
    public var unitPrice: Double
    public var amount: Double
    public var glAccountCode: String?      // General Ledger account
    public var costCenter: String?
    public var confidence: Double

    public init(
        id: UUID = UUID(),
        lineNumber: Int,
        description: String = "",
        quantity: Double = 1.0,
        unitPrice: Double = 0.0,
        amount: Double = 0.0,
        glAccountCode: String? = nil,
        costCenter: String? = nil,
        confidence: Double = 0.0
    ) {
        self.id = id
        self.lineNumber = lineNumber
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.amount = amount
        self.glAccountCode = glAccountCode
        self.costCenter = costCenter
        self.confidence = confidence
    }

    /// Computed amount from quantity and unit price
    public var calculatedAmount: Double {
        quantity * unitPrice
    }

    /// Check if calculated amount matches extracted amount
    public var amountMatches: Bool {
        abs(calculatedAmount - amount) < 0.01
    }
}

// MARK: - Document Scan Result

/// Complete result from document scanning and extraction
public struct DocScanResult: Identifiable, Codable {
    public let id: UUID
    public var sourceFileId: UUID              // Reference to AISFileInfo
    public var scanDate: Date
    public var providerUsed: AIProviderTier
    public var processingTimeMs: Int

    // Header fields
    public var vendorName: ExtractedField
    public var vendorAddress: ExtractedField
    public var invoiceNumber: ExtractedField
    public var invoiceDate: ExtractedField
    public var dueDate: ExtractedField
    public var poNumber: ExtractedField

    // Amounts
    public var subtotal: ExtractedField
    public var taxAmount: ExtractedField
    public var totalAmount: ExtractedField
    public var currency: ExtractedField

    // Line items
    public var lineItems: [InvoiceLineItem]

    // Processing state
    public var status: DocScanStatus
    public var validationErrors: [String]

    // Raw OCR text for debugging
    public var rawOCRText: String?

    public init(
        id: UUID = UUID(),
        sourceFileId: UUID,
        scanDate: Date = Date(),
        providerUsed: AIProviderTier = .selfMapping,
        processingTimeMs: Int = 0
    ) {
        self.id = id
        self.sourceFileId = sourceFileId
        self.scanDate = scanDate
        self.providerUsed = providerUsed
        self.processingTimeMs = processingTimeMs

        // Initialize header fields
        self.vendorName = ExtractedField(fieldKey: "vendor_name", displayName: "Vendor Name", isRequired: true)
        self.vendorAddress = ExtractedField(fieldKey: "vendor_address", displayName: "Vendor Address")
        self.invoiceNumber = ExtractedField(fieldKey: "invoice_number", displayName: "Invoice Number", isRequired: true)
        self.invoiceDate = ExtractedField(fieldKey: "invoice_date", displayName: "Invoice Date", isRequired: true)
        self.dueDate = ExtractedField(fieldKey: "due_date", displayName: "Due Date")
        self.poNumber = ExtractedField(fieldKey: "po_number", displayName: "PO Number")

        // Initialize amount fields
        self.subtotal = ExtractedField(fieldKey: "subtotal", displayName: "Subtotal")
        self.taxAmount = ExtractedField(fieldKey: "tax_amount", displayName: "Tax Amount")
        self.totalAmount = ExtractedField(fieldKey: "total_amount", displayName: "Total Amount", isRequired: true)
        self.currency = ExtractedField(fieldKey: "currency", displayName: "Currency", extractedValue: "USD", mappedValue: "USD")

        self.lineItems = []
        self.status = .pending
        self.validationErrors = []
    }

    /// All header fields as array for iteration
    public var allHeaderFields: [ExtractedField] {
        [vendorName, vendorAddress, invoiceNumber, invoiceDate, dueDate, poNumber]
    }

    /// All amount fields as array
    public var allAmountFields: [ExtractedField] {
        [subtotal, taxAmount, totalAmount, currency]
    }

    /// Check if amounts balance
    public var amountsBalance: Bool {
        let calculatedTotal = (Double(subtotal.mappedValue) ?? 0) + (Double(taxAmount.mappedValue) ?? 0)
        let declaredTotal = Double(totalAmount.mappedValue) ?? 0
        return abs(calculatedTotal - declaredTotal) < 0.01
    }

    /// Overall confidence score (average of all fields)
    public var overallConfidence: Double {
        let fields = allHeaderFields + allAmountFields
        let totalConfidence = fields.reduce(0.0) { $0 + $1.confidence }
        return fields.isEmpty ? 0 : totalConfidence / Double(fields.count)
    }

    /// Check if all required fields have values
    public var hasRequiredFields: Bool {
        let requiredFields = (allHeaderFields + allAmountFields).filter { $0.isRequired }
        return requiredFields.allSatisfy { !$0.mappedValue.isEmpty }
    }
}

// MARK: - Processing Status

/// Status of document scanning process
public enum DocScanStatus: String, Codable {
    case pending = "pending"           // Waiting to be processed
    case scanning = "scanning"         // OCR in progress
    case extracting = "extracting"     // AI extraction in progress
    case review = "review"             // Ready for user review
    case approved = "approved"         // User approved
    case posted = "posted"             // Posted to accounting system
    case rejected = "rejected"         // User rejected
    case error = "error"               // Processing error

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

    public var iconName: String {
        switch self {
        case .pending: return "clock"
        case .scanning: return "doc.text.magnifyingglass"
        case .extracting: return "cpu"
        case .review: return "eye"
        case .approved: return "checkmark.circle"
        case .posted: return "checkmark.seal"
        case .rejected: return "xmark.circle"
        case .error: return "exclamationmark.triangle"
        }
    }

    public var tokenKey: String {
        switch self {
        case .pending: return "stateInfo"
        case .scanning, .extracting: return "actionPrimary"
        case .review: return "stateWarning"
        case .approved, .posted: return "actionConfirm"
        case .rejected, .error: return "stateError"
        }
    }
}

// MARK: - API Request/Response Models

/// Request to process a document
public struct DocScanRequest: Codable {
    public let fileId: UUID
    public let preferredProvider: AIProviderTier
    public let extractLineItems: Bool
    public let language: String

    public init(
        fileId: UUID,
        preferredProvider: AIProviderTier = .appleVision,
        extractLineItems: Bool = true,
        language: String = "en"
    ) {
        self.fileId = fileId
        self.preferredProvider = preferredProvider
        self.extractLineItems = extractLineItems
        self.language = language
    }
}

/// Response from document processing
public struct DocScanResponse: Codable {
    public let success: Bool
    public let result: DocScanResult?
    public let error: String?
    public let providerUsed: AIProviderTier
    public let fallbackReason: String?  // If primary provider failed

    public init(
        success: Bool,
        result: DocScanResult? = nil,
        error: String? = nil,
        providerUsed: AIProviderTier,
        fallbackReason: String? = nil
    ) {
        self.success = success
        self.result = result
        self.error = error
        self.providerUsed = providerUsed
        self.fallbackReason = fallbackReason
    }
}

// MARK: - Vendor Mapping

/// Mapping from extracted vendor name to known vendor
public struct VendorMapping: Identifiable, Codable, Hashable {
    public let id: UUID
    public var extractedName: String     // What OCR found
    public var mappedVendorId: UUID?     // Known vendor in system
    public var mappedVendorName: String  // Display name of known vendor
    public var confidence: Double
    public var isConfirmed: Bool         // User confirmed this mapping

    public init(
        id: UUID = UUID(),
        extractedName: String,
        mappedVendorId: UUID? = nil,
        mappedVendorName: String = "",
        confidence: Double = 0.0,
        isConfirmed: Bool = false
    ) {
        self.id = id
        self.extractedName = extractedName
        self.mappedVendorId = mappedVendorId
        self.mappedVendorName = mappedVendorName
        self.confidence = confidence
        self.isConfirmed = isConfirmed
    }
}

// MARK: - GL Account Mapping

/// Mapping of line items to GL accounts
public struct GLAccountMapping: Identifiable, Codable, Hashable {
    public let id: UUID
    public var accountCode: String
    public var accountName: String
    public var keywords: [String]        // Keywords that suggest this account
    public var defaultCostCenter: String?

    public init(
        id: UUID = UUID(),
        accountCode: String,
        accountName: String,
        keywords: [String] = [],
        defaultCostCenter: String? = nil
    ) {
        self.id = id
        self.accountCode = accountCode
        self.accountName = accountName
        self.keywords = keywords
        self.defaultCostCenter = defaultCostCenter
    }
}

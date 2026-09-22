// =============================================================================
// DocScanService.swift
// AIS DocScan AP Module - AI Router Service
// =============================================================================
//
// PURPOSE:
// Provides the AI Router pattern for document scanning with automatic fallback
// through the provider chain: Apple Vision → Local AI → Cloud LLM → Manual
//
// ARCHITECTURE:
// - DocScanService: Main service coordinating extraction
// - AIProvider protocol: Common interface for all providers
// - Specific providers: AppleVisionProvider, LocalAgenticProvider, CloudLLMProvider
//
// =============================================================================

import Foundation
import SwiftUI
import PDFKit
#if os(macOS)
import AppKit
import Vision
#elseif os(iOS)
import UIKit
import Vision
#endif

// MARK: - AI Provider Protocol

/// Protocol for all AI extraction providers
public protocol AIExtractionProvider {
    var tier: AIProviderTier { get }
    var isAvailable: Bool { get }

    func extractFields(from imageData: Data, language: String) async throws -> DocScanResult
}

// MARK: - DocScan Service

/// Main service for document scanning with AI Router pattern
@MainActor
public class DocScanService: ObservableObject {
    // MARK: - Published State

    @Published public private(set) var currentResult: DocScanResult?
    @Published public private(set) var status: DocScanStatus = .pending
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var error: String?
    @Published public private(set) var activeProvider: AIProviderTier = .selfMapping

    // MARK: - Configuration

    public var preferredProvider: AIProviderTier = .appleVision
    public var cloudAPIKey: String?
    public var cloudProvider: CloudLLMType = .claude

    // MARK: - Providers

    private var providers: [AIExtractionProvider] = []

    // MARK: - Initialization

    public init() {
        setupProviders()
    }

    private func setupProviders() {
        // Add providers in order of preference (tier 1 to tier 3)
        #if os(iOS) || os(macOS)
        if #available(iOS 16.0, macOS 13.0, *) {
            providers.append(AppleVisionProvider())
        }
        #endif
        providers.append(LocalAgenticProvider())
        providers.append(CloudLLMProvider())
    }

    // MARK: - Main Processing Entry Point

    /// Process a document and extract AP fields (supports images, PDFs, and text files)
    /// - Parameters:
    ///   - fileInfo: The selected file info from AISMediaPicker
    ///   - extractLineItems: Whether to extract line items
    /// - Returns: DocScanResult with extracted fields
    public func processDocument(fileInfo: AISFileInfo, extractLineItems: Bool = true) async throws -> DocScanResult {
        status = .scanning
        progress = 0.1
        error = nil

        let fileURL = URL(fileURLWithPath: fileInfo.localPath)
        let fileExtension = fileURL.pathExtension.lowercased()

        progress = 0.2
        status = .extracting

        // Determine file type and extract text accordingly
        var extractedText: String = ""
        var result: DocScanResult?

        if isPlainTextFile(extension: fileExtension) {
            // Plain text files - read directly
            extractedText = try extractTextFromTextFile(fileURL: fileURL)
            activeProvider = .selfMapping

            result = DocScanResult(sourceFileId: fileInfo.id, providerUsed: .selfMapping)
            result?.rawOCRText = extractedText

            // Parse fields
            if #available(iOS 16.0, macOS 13.0, *) {
                let visionProvider = AppleVisionProvider()
                result = visionProvider.parseInvoiceFieldsPublic(from: extractedText, into: result!)
            }

            progress = 0.9
        } else if fileExtension == "pdf" {
            // PDF files - extract text using PDFKit
            extractedText = try extractTextFromPDF(fileURL: fileURL)
            activeProvider = .appleVision

            result = DocScanResult(sourceFileId: fileInfo.id, providerUsed: .appleVision)
            result?.rawOCRText = extractedText

            // Parse fields
            if #available(iOS 16.0, macOS 13.0, *) {
                let visionProvider = AppleVisionProvider()
                result = visionProvider.parseInvoiceFieldsPublic(from: extractedText, into: result!)
            }

            progress = 0.9
        } else {
            // Image files - use OCR providers
            guard let imageData = try? Data(contentsOf: fileURL) else {
                throw DocScanError.fileReadError(fileInfo.fileName)
            }

            // Try providers in order until one succeeds
            var lastError: Error?

            for provider in providers {
                guard provider.isAvailable else { continue }

                // Skip cloud provider if no API key
                if provider.tier == .cloudLLM && cloudAPIKey == nil {
                    continue
                }

                // Skip providers below preferred tier (unless fallback needed)
                if provider.tier.rawValue < preferredProvider.rawValue && result == nil {
                    continue
                }

                activeProvider = provider.tier
                progress = 0.3 + (Double(provider.tier.rawValue) * 0.1)

                do {
                    result = try await provider.extractFields(from: imageData, language: "en")
                    result?.sourceFileId = fileInfo.id
                    result?.providerUsed = provider.tier
                    break
                } catch {
                    lastError = error
                    // Continue to next provider (fallback)
                    continue
                }
            }

            if result == nil {
                // All providers failed, return empty result for manual entry
                var manualResult = DocScanResult(sourceFileId: fileInfo.id, providerUsed: .selfMapping)
                manualResult.status = .review
                self.currentResult = manualResult
                self.status = .review
                self.error = lastError?.localizedDescription ?? "Extraction failed, manual entry required"
                progress = 1.0
                return manualResult
            }
        }

        progress = 0.9

        if var result = result {
            result.status = .review
            self.currentResult = result
            self.status = .review
            progress = 1.0
            return result
        } else {
            // Return empty result for manual entry
            var manualResult = DocScanResult(sourceFileId: fileInfo.id, providerUsed: .selfMapping)
            manualResult.status = .review
            self.currentResult = manualResult
            self.status = .review
            progress = 1.0
            return manualResult
        }
    }

    // MARK: - File Type Helpers

    /// Check if the file is a plain text file
    private func isPlainTextFile(extension ext: String) -> Bool {
        let textExtensions = ["txt", "md", "json", "xml", "csv", "html", "htm"]
        return textExtensions.contains(ext)
    }

    /// Extract text directly from plain text files
    private func extractTextFromTextFile(fileURL: URL) throws -> String {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw DocScanError.fileReadError(fileURL.lastPathComponent)
        }
    }

    /// Extract text from PDF files using PDFKit
    private func extractTextFromPDF(fileURL: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: fileURL) else {
            throw DocScanError.fileReadError(fileURL.lastPathComponent)
        }

        var fullText = ""

        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }

        return fullText
    }

    /// Validate the current result before posting
    public func validateResult() -> [String] {
        guard let result = currentResult else {
            return ["No document scanned"]
        }

        var errors: [String] = []

        // Check required fields
        if result.vendorName.mappedValue.isEmpty {
            errors.append("Vendor name is required")
        }
        if result.invoiceNumber.mappedValue.isEmpty {
            errors.append("Invoice number is required")
        }
        if result.invoiceDate.mappedValue.isEmpty {
            errors.append("Invoice date is required")
        }
        if result.totalAmount.mappedValue.isEmpty {
            errors.append("Total amount is required")
        }

        // Validate amounts balance if both subtotal and tax provided
        if !result.subtotal.mappedValue.isEmpty && !result.taxAmount.mappedValue.isEmpty {
            if !result.amountsBalance {
                errors.append("Subtotal + Tax does not equal Total")
            }
        }

        return errors
    }

    /// Approve the current result for posting
    public func approveResult() {
        guard var result = currentResult else { return }
        result.status = .approved
        result.validationErrors = validateResult()
        currentResult = result
        status = result.validationErrors.isEmpty ? .approved : .review
    }

    /// Reject the current result
    public func rejectResult() {
        guard var result = currentResult else { return }
        result.status = .rejected
        currentResult = result
        status = .rejected
    }

    /// Reset to process a new document
    public func reset() {
        currentResult = nil
        status = .pending
        progress = 0.0
        error = nil
        activeProvider = .selfMapping
    }
}

// MARK: - DocScan Errors

public enum DocScanError: Error, LocalizedError {
    case fileReadError(String)
    case ocrFailed(String)
    case extractionFailed(String)
    case providerUnavailable(AIProviderTier)
    case networkError(String)
    case invalidAPIKey

    public var errorDescription: String? {
        switch self {
        case .fileReadError(let file): return "Unable to read file: \(file)"
        case .ocrFailed(let reason): return "OCR failed: \(reason)"
        case .extractionFailed(let reason): return "Extraction failed: \(reason)"
        case .providerUnavailable(let tier): return "\(tier.displayName) is not available"
        case .networkError(let reason): return "Network error: \(reason)"
        case .invalidAPIKey: return "Invalid or missing API key"
        }
    }
}

// MARK: - Cloud LLM Types

public enum CloudLLMType: String, CaseIterable, Codable {
    case claude = "claude"
    case chatgpt = "chatgpt"
    case gemini = "gemini"

    public var displayName: String {
        switch self {
        case .claude: return "Claude (Anthropic)"
        case .chatgpt: return "ChatGPT (OpenAI)"
        case .gemini: return "Gemini (Google)"
        }
    }

    public var apiEndpoint: String {
        switch self {
        case .claude: return "https://api.anthropic.com/v1/messages"
        case .chatgpt: return "https://api.openai.com/v1/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/models"
        }
    }
}

// MARK: - Apple Vision Provider

/// Tier 1: On-device Apple Vision OCR
@available(iOS 16.0, macOS 13.0, *)
public class AppleVisionProvider: AIExtractionProvider {
    public let tier: AIProviderTier = .appleVision

    public var isAvailable: Bool {
        return true // Vision framework available on iOS 16+ / macOS 13+
    }

    public func extractFields(from imageData: Data, language: String) async throws -> DocScanResult {
        let startTime = Date()

        // Create image from data
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw DocScanError.ocrFailed("Invalid image data")
        }
        #else
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            throw DocScanError.ocrFailed("Invalid image data")
        }
        #endif

        // Perform OCR
        let recognizedText = try await performOCR(on: cgImage)

        // Parse extracted text into fields
        var result = DocScanResult(sourceFileId: UUID(), providerUsed: .appleVision)
        result.rawOCRText = recognizedText

        // Parse fields using regex patterns
        result = parseInvoiceFields(from: recognizedText, into: result)

        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
        result.processingTimeMs = processingTime
        result.status = .review

        return result
    }

    private func performOCR(on cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: DocScanError.ocrFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: DocScanError.ocrFailed("No text found"))
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DocScanError.ocrFailed(error.localizedDescription))
            }
        }
    }

    /// Public method for parsing invoice fields from text
    public func parseInvoiceFieldsPublic(from text: String, into result: DocScanResult) -> DocScanResult {
        return parseInvoiceFields(from: text, into: result)
    }

    private func parseInvoiceFields(from text: String, into result: DocScanResult) -> DocScanResult {
        var result = result
        let lines = text.components(separatedBy: .newlines)

        // Invoice Number patterns
        let invoicePatterns = [
            "Invoice\\s*#?:?\\s*([A-Z0-9-]+)",
            "INV\\s*#?:?\\s*([A-Z0-9-]+)",
            "Invoice Number:?\\s*([A-Z0-9-]+)"
        ]
        if let match = findMatch(in: text, patterns: invoicePatterns) {
            result.invoiceNumber.extractedValue = match
            result.invoiceNumber.mappedValue = match
            result.invoiceNumber.confidence = 0.85
        }

        // Date patterns
        let datePatterns = [
            "Date:?\\s*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})",
            "Invoice Date:?\\s*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})",
            "(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"
        ]
        if let match = findMatch(in: text, patterns: datePatterns) {
            result.invoiceDate.extractedValue = match
            result.invoiceDate.mappedValue = match
            result.invoiceDate.confidence = 0.80
        }

        // Total Amount patterns
        let amountPatterns = [
            "Total:?\\s*\\$?([0-9,]+\\.?\\d{0,2})",
            "Amount Due:?\\s*\\$?([0-9,]+\\.?\\d{0,2})",
            "Grand Total:?\\s*\\$?([0-9,]+\\.?\\d{0,2})",
            "Balance Due:?\\s*\\$?([0-9,]+\\.?\\d{0,2})"
        ]
        if let match = findMatch(in: text, patterns: amountPatterns) {
            result.totalAmount.extractedValue = match
            result.totalAmount.mappedValue = match.replacingOccurrences(of: ",", with: "")
            result.totalAmount.confidence = 0.85
        }

        // Tax patterns
        let taxPatterns = [
            "Tax:?\\s*\\$?([0-9,]+\\.?\\d{0,2})",
            "Sales Tax:?\\s*\\$?([0-9,]+\\.?\\d{0,2})",
            "VAT:?\\s*\\$?([0-9,]+\\.?\\d{0,2})"
        ]
        if let match = findMatch(in: text, patterns: taxPatterns) {
            result.taxAmount.extractedValue = match
            result.taxAmount.mappedValue = match.replacingOccurrences(of: ",", with: "")
            result.taxAmount.confidence = 0.80
        }

        // Subtotal patterns
        let subtotalPatterns = [
            "Subtotal:?\\s*\\$?([0-9,]+\\.?\\d{0,2})",
            "Sub-total:?\\s*\\$?([0-9,]+\\.?\\d{0,2})"
        ]
        if let match = findMatch(in: text, patterns: subtotalPatterns) {
            result.subtotal.extractedValue = match
            result.subtotal.mappedValue = match.replacingOccurrences(of: ",", with: "")
            result.subtotal.confidence = 0.80
        }

        // Vendor name - usually first few lines
        if lines.count > 0 {
            let vendorCandidate = lines.prefix(3).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !vendorCandidate.isEmpty && vendorCandidate.count < 100 {
                result.vendorName.extractedValue = vendorCandidate
                result.vendorName.mappedValue = vendorCandidate
                result.vendorName.confidence = 0.60
            }
        }

        // PO Number patterns
        let poPatterns = [
            "PO\\s*#?:?\\s*([A-Z0-9-]+)",
            "Purchase Order:?\\s*([A-Z0-9-]+)",
            "P\\.O\\.\\s*#?:?\\s*([A-Z0-9-]+)"
        ]
        if let match = findMatch(in: text, patterns: poPatterns) {
            result.poNumber.extractedValue = match
            result.poNumber.mappedValue = match
            result.poNumber.confidence = 0.75
        }

        // Due Date patterns
        let dueDatePatterns = [
            "Due Date:?\\s*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})",
            "Payment Due:?\\s*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})",
            "Due:?\\s*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"
        ]
        if let match = findMatch(in: text, patterns: dueDatePatterns) {
            result.dueDate.extractedValue = match
            result.dueDate.mappedValue = match
            result.dueDate.confidence = 0.75
        }

        return result
    }

    private func findMatch(in text: String, patterns: [String]) -> String? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}

// MARK: - Local Agentic Provider

/// Tier 2: On-device local AI model
public class LocalAgenticProvider: AIExtractionProvider {
    public let tier: AIProviderTier = .localAgentic

    public var isAvailable: Bool {
        // In a real implementation, check if local model is loaded
        return false // Placeholder - would require CoreML model
    }

    public func extractFields(from imageData: Data, language: String) async throws -> DocScanResult {
        // Placeholder for local AI model integration
        throw DocScanError.providerUnavailable(.localAgentic)
    }
}

// MARK: - Cloud LLM Provider

/// Tier 3: Cloud-based LLM (Claude, ChatGPT, Gemini)
public class CloudLLMProvider: AIExtractionProvider {
    public let tier: AIProviderTier = .cloudLLM

    public var isAvailable: Bool {
        return true // Network available
    }

    public var apiKey: String?
    public var llmType: CloudLLMType = .claude

    public func extractFields(from imageData: Data, language: String) async throws -> DocScanResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw DocScanError.invalidAPIKey
        }

        // In a real implementation, this would:
        // 1. Encode image to base64
        // 2. Send to LLM API with extraction prompt
        // 3. Parse JSON response into DocScanResult

        // Placeholder - would make actual API call
        throw DocScanError.networkError("Cloud LLM integration not implemented in demo")
    }
}

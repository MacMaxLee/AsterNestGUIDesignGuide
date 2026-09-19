// =============================================================================
// AISMediaPicker.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Provides file and media selection capabilities with complete metadata
// extraction for database storage. This component bridges the gap between
// user file selection and structured data persistence.
//
// KEY REQUIREMENTS (AIS Conformance):
// 1. FILE METADATA: Extract complete file information for database storage
// 2. CHECKSUM VALIDATION: Compute MD5/SHA hash for file integrity verification
// 3. MIME TYPE DETECTION: Properly identify file types for handling
// 4. SECURE ACCESS: Handle sandbox security scoped resources correctly
// 5. ERROR HANDLING: Graceful failure with informative error states
//
// GENERIC TYPE PARAMETERS:
// - FileInfoType: Custom type conforming to AISFileInfoProtocol for flexibility
//
// USAGE:
// ```swift
// AISMediaPicker(
//     allowedTypes: [.image, .pdf, .plainText],
//     allowsMultiple: true,
//     onFilesSelected: { files in
//         // files: [AISFileInfo] with complete metadata
//         viewModel.attachFiles(files)
//     }
// )
// ```
//
// =============================================================================

import SwiftUI
import UniformTypeIdentifiers
import CryptoKit

// MARK: - File Info Protocol

/// Protocol defining the required metadata for file storage.
/// Implement this protocol to customize how file data is represented.
///
/// ## Required Properties
/// - `id`: Unique identifier for the file
/// - `fileName`: Original file name with extension
/// - `mimeType`: MIME type string (e.g., "image/png")
/// - `fileSize`: Size in bytes
/// - `checksum`: MD5 or SHA256 hash for integrity verification
/// - `localPath`: Full path to the file (for temporary access)
/// - `createdAt`: File creation timestamp
/// - `modifiedAt`: File modification timestamp
///
public protocol AISFileInfoProtocol: Identifiable, Hashable {
    var id: UUID { get }
    var fileName: String { get }
    var mimeType: String { get }
    var fileSize: Int64 { get }
    var checksum: String { get }
    var localPath: String { get }
    var createdAt: Date? { get }
    var modifiedAt: Date? { get }
}

// MARK: - Default File Info Implementation

/// Default implementation of AISFileInfoProtocol containing all
/// required metadata for database storage.
///
/// ## Properties
/// - Complete file metadata extracted from the file system
/// - MD5 checksum for integrity verification
/// - MIME type for proper file handling
///
/// ## Example
/// ```swift
/// let fileInfo = AISFileInfo(
///     fileName: "document.pdf",
///     mimeType: "application/pdf",
///     fileSize: 1024000,
///     checksum: "a1b2c3d4e5f6...",
///     localPath: "/path/to/file",
///     createdAt: Date(),
///     modifiedAt: Date()
/// )
/// ```
///
public struct AISFileInfo: AISFileInfoProtocol {
    public let id: UUID
    public let fileName: String
    public let mimeType: String
    public let fileSize: Int64
    public let checksum: String
    public let localPath: String
    public let createdAt: Date?
    public let modifiedAt: Date?

    /// Additional metadata as key-value pairs for extensibility
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        fileName: String,
        mimeType: String,
        fileSize: Int64,
        checksum: String,
        localPath: String,
        createdAt: Date? = nil,
        modifiedAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.fileName = fileName
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.checksum = checksum
        self.localPath = localPath
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.metadata = metadata
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AISFileInfo, rhs: AISFileInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - File Type Category

/// Categories of files that can be selected.
/// Maps to UTType for consistent type identification.
///
/// ## Usage
/// ```swift
/// let allowedTypes: [AISFileCategory] = [.image, .pdf, .video]
/// ```
///
public enum AISFileCategory: CaseIterable {
    /// Image files (PNG, JPEG, GIF, HEIC, etc.)
    case image

    /// Video files (MP4, MOV, AVI, etc.)
    case video

    /// Audio files (MP3, WAV, AAC, etc.)
    case audio

    /// PDF documents
    case pdf

    /// Plain text files
    case plainText

    /// Spreadsheet files (CSV, XLSX)
    case spreadsheet

    /// Any file type
    case any

    /// Returns the corresponding UTType for this category.
    /// Used for NSOpenPanel/UIDocumentPickerViewController filtering.
    public var utType: UTType {
        switch self {
        case .image: return .image
        case .video: return .movie
        case .audio: return .audio
        case .pdf: return .pdf
        case .plainText: return .plainText
        case .spreadsheet: return .commaSeparatedText
        case .any: return .item
        }
    }

    /// Human-readable display name for UI
    public var displayName: String {
        switch self {
        case .image: return "Images"
        case .video: return "Videos"
        case .audio: return "Audio"
        case .pdf: return "PDFs"
        case .plainText: return "Text Files"
        case .spreadsheet: return "Spreadsheets"
        case .any: return "All Files"
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "music.note"
        case .pdf: return "doc.text"
        case .plainText: return "doc.plaintext"
        case .spreadsheet: return "tablecells"
        case .any: return "doc"
        }
    }
}

// MARK: - File Picker State

/// Represents the current state of the file picker operation.
public enum AISFilePickerState {
    /// Ready to pick files
    case idle

    /// Currently showing the file picker
    case picking

    /// Processing selected files (computing checksums, etc.)
    case processing(progress: Double)

    /// Files successfully selected
    case completed([AISFileInfo])

    /// An error occurred
    case error(AISFilePickerError)
}

/// Errors that can occur during file picking.
public enum AISFilePickerError: Error, LocalizedError {
    /// User cancelled the file picker
    case cancelled

    /// Unable to access the file (permissions issue)
    case accessDenied(String)

    /// File is too large (exceeds maxFileSize)
    case fileTooLarge(String, Int64)

    /// Unable to read file contents
    case readError(String)

    /// Invalid file type
    case invalidType(String)

    /// Generic error with message
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "File selection was cancelled"
        case .accessDenied(let file):
            return "Cannot access file: \(file)"
        case .fileTooLarge(let file, let size):
            return "File '\(file)' is too large (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))"
        case .readError(let file):
            return "Unable to read file: \(file)"
        case .invalidType(let file):
            return "Invalid file type: \(file)"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Media Picker View

/// A SwiftUI view that provides file selection with complete metadata extraction.
///
/// ## Features
/// - Native file picker dialog (NSOpenPanel on macOS, UIDocumentPicker on iOS)
/// - Automatic MIME type detection
/// - MD5 checksum computation for file integrity
/// - File size and timestamp extraction
/// - Progress indication during processing
/// - Configurable file type filters
///
/// ## Example
/// ```swift
/// struct AttachmentView: View {
///     @State private var attachments: [AISFileInfo] = []
///     @State private var pickerState: AISFilePickerState = .idle
///
///     var body: some View {
///         VStack {
///             AISMediaPicker(
///                 state: $pickerState,
///                 allowedTypes: [.image, .pdf],
///                 allowsMultiple: true,
///                 maxFileSize: 10_000_000, // 10MB
///                 onFilesSelected: { files in
///                     attachments.append(contentsOf: files)
///                 }
///             )
///
///             // Display selected files
///             ForEach(attachments) { file in
///                 AISFileInfoRow(file: file)
///             }
///         }
///     }
/// }
/// ```
///
public struct AISMediaPicker: View {
    // MARK: - Properties

    /// Current state of the picker (binding for external monitoring)
    @Binding var state: AISFilePickerState

    /// Allowed file type categories
    let allowedTypes: [AISFileCategory]

    /// Whether multiple files can be selected
    let allowsMultiple: Bool

    /// Maximum file size in bytes (nil for no limit)
    let maxFileSize: Int64?

    /// Callback when files are successfully selected
    let onFilesSelected: ([AISFileInfo]) -> Void

    /// Callback when an error occurs
    let onError: ((AISFilePickerError) -> Void)?

    /// Custom button label
    let buttonLabel: String

    /// Button type for styling
    let buttonType: AISButtonType

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - State

    @State private var showFilePicker = false
    @State private var processingProgress: Double = 0

    // MARK: - Initialization

    /// Creates a media picker with the specified configuration.
    ///
    /// - Parameters:
    ///   - state: Binding to track picker state
    ///   - allowedTypes: Array of allowed file categories (default: [.any])
    ///   - allowsMultiple: Whether multiple selection is allowed (default: true)
    ///   - maxFileSize: Maximum file size in bytes (default: nil)
    ///   - buttonLabel: Custom button text (default: "Select Files")
    ///   - buttonType: Semantic button type (default: .primary)
    ///   - onFilesSelected: Callback with selected file infos
    ///   - onError: Optional error callback
    ///
    public init(
        state: Binding<AISFilePickerState> = .constant(.idle),
        allowedTypes: [AISFileCategory] = [.any],
        allowsMultiple: Bool = true,
        maxFileSize: Int64? = nil,
        buttonLabel: String = "Select Files",
        buttonType: AISButtonType = .primary,
        onFilesSelected: @escaping ([AISFileInfo]) -> Void,
        onError: ((AISFilePickerError) -> Void)? = nil
    ) {
        self._state = state
        self.allowedTypes = allowedTypes
        self.allowsMultiple = allowsMultiple
        self.maxFileSize = maxFileSize
        self.buttonLabel = buttonLabel
        self.buttonType = buttonType
        self.onFilesSelected = onFilesSelected
        self.onError = onError
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            // Picker button with state-aware content
            pickerButton

            // State indicator
            stateIndicator
        }
    }

    // MARK: - Picker Button

    @ViewBuilder
    private var pickerButton: some View {
        switch state {
        case .processing(let progress):
            // Show progress during processing
            HStack(spacing: AISSpacing.md) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
            .padding(.horizontal, AISSpacing.md)

        default:
            AISButton(
                buttonLabel,
                type: buttonType,
                icon: iconForTypes,
                isLoading: isPickerShowing
            ) {
                showFilePicker = true
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: allowedTypes.map(\.utType),
                allowsMultipleSelection: allowsMultiple,
                onCompletion: handleFileSelection
            )
        }
    }

    /// Returns appropriate icon based on allowed types
    private var iconForTypes: String {
        if allowedTypes.count == 1 {
            return allowedTypes.first?.iconName ?? "doc"
        }
        return "paperclip"
    }

    /// Whether file picker is currently showing
    private var isPickerShowing: Bool {
        if case .picking = state { return true }
        return false
    }

    // MARK: - State Indicator

    @ViewBuilder
    private var stateIndicator: some View {
        switch state {
        case .error(let error):
            HStack(spacing: AISSpacing.sm) {
                Image(systemName: tokens.stateError.iconName)
                    .foregroundColor(tokens.stateError.color)

                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(tokens.stateError.color)

                Spacer()

                Button("Dismiss") {
                    state = .idle
                }
                .font(.caption)
                .foregroundColor(tokens.actionNeutral.color)
            }
            .padding(AISSpacing.sm)
            .background(tokens.stateError.color.opacity(0.1))
            .cornerRadius(AISRadius.sm)

        case .completed(let files):
            if !files.isEmpty {
                HStack(spacing: AISSpacing.sm) {
                    Image(systemName: tokens.actionConfirm.iconName)
                        .foregroundColor(tokens.actionConfirm.color)

                    Text("\(files.count) file(s) selected")
                        .font(.caption)
                        .foregroundColor(tokens.actionConfirm.color)
                }
            }

        default:
            EmptyView()
        }
    }

    // MARK: - File Handling

    /// Handles the result of the file picker
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else {
                state = .error(.cancelled)
                onError?(.cancelled)
                return
            }

            // Process files asynchronously
            Task {
                await processFiles(urls)
            }

        case .failure(let error):
            let pickerError = AISFilePickerError.unknown(error.localizedDescription)
            state = .error(pickerError)
            onError?(pickerError)
        }
    }

    /// Processes selected files, extracting metadata and computing checksums
    @MainActor
    private func processFiles(_ urls: [URL]) async {
        state = .processing(progress: 0)

        var fileInfos: [AISFileInfo] = []
        var errors: [AISFilePickerError] = []

        for (index, url) in urls.enumerated() {
            // Update progress
            let progress = Double(index) / Double(urls.count)
            state = .processing(progress: progress)

            // Start accessing security-scoped resource
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let fileInfo = try await extractFileInfo(from: url)

                // Check file size limit
                if let maxSize = maxFileSize, fileInfo.fileSize > maxSize {
                    errors.append(.fileTooLarge(fileInfo.fileName, fileInfo.fileSize))
                    continue
                }

                fileInfos.append(fileInfo)
            } catch {
                if let pickerError = error as? AISFilePickerError {
                    errors.append(pickerError)
                } else {
                    errors.append(.readError(url.lastPathComponent))
                }
            }
        }

        // Complete processing
        state = .processing(progress: 1.0)

        // Report results
        if !fileInfos.isEmpty {
            state = .completed(fileInfos)
            onFilesSelected(fileInfos)
        } else if let firstError = errors.first {
            state = .error(firstError)
            onError?(firstError)
        } else {
            state = .idle
        }
    }

    /// Extracts complete metadata from a file URL
    private func extractFileInfo(from url: URL) async throws -> AISFileInfo {
        // Get file attributes
        let resourceValues = try url.resourceValues(forKeys: [
            .fileSizeKey,
            .contentTypeKey,
            .creationDateKey,
            .contentModificationDateKey
        ])

        // Read file data for checksum
        let fileData = try Data(contentsOf: url)

        // Compute MD5 checksum
        let checksum = computeMD5(data: fileData)

        // Determine MIME type
        let mimeType = resourceValues.contentType?.preferredMIMEType ?? "application/octet-stream"

        return AISFileInfo(
            fileName: url.lastPathComponent,
            mimeType: mimeType,
            fileSize: Int64(resourceValues.fileSize ?? 0),
            checksum: checksum,
            localPath: url.path,
            createdAt: resourceValues.creationDate,
            modifiedAt: resourceValues.contentModificationDate,
            metadata: [
                "extension": url.pathExtension,
                "isDirectory": "\(url.hasDirectoryPath)"
            ]
        )
    }

    /// Computes MD5 checksum for data
    private func computeMD5(data: Data) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - File Info Row View

/// A standard row view for displaying file information.
/// Use this to show selected files in a list.
///
/// ## Example
/// ```swift
/// List(selectedFiles) { file in
///     AISFileInfoRow(file: file, onRemove: {
///         selectedFiles.removeAll { $0.id == file.id }
///     })
/// }
/// ```
///
public struct AISFileInfoRow: View {
    let file: AISFileInfo
    let onRemove: (() -> Void)?

    @Environment(\.aisTokens) private var tokens

    public init(file: AISFileInfo, onRemove: (() -> Void)? = nil) {
        self.file = file
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: AISSpacing.md) {
            // File type icon
            Image(systemName: iconForMimeType)
                .font(.title2)
                .foregroundColor(tokens.actionPrimary.color)
                .frame(width: 40, height: 40)
                .background(tokens.surfaceSecondary)
                .cornerRadius(AISRadius.sm)

            // File details
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.body)
                    .foregroundColor(tokens.onSurface)
                    .lineLimit(1)

                HStack(spacing: AISSpacing.sm) {
                    Text(formattedFileSize)
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)

                    Text("•")
                        .foregroundColor(tokens.onSurfaceSecondary)

                    Text(file.mimeType)
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }
            }

            Spacer()

            // Remove button (if provided)
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(tokens.actionNeutral.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AISSpacing.sm)
        .background(tokens.surface)
        .cornerRadius(AISRadius.md)
    }

    /// Returns appropriate icon based on MIME type
    private var iconForMimeType: String {
        if file.mimeType.hasPrefix("image/") {
            return "photo"
        } else if file.mimeType.hasPrefix("video/") {
            return "video"
        } else if file.mimeType.hasPrefix("audio/") {
            return "music.note"
        } else if file.mimeType == "application/pdf" {
            return "doc.text"
        } else if file.mimeType.hasPrefix("text/") {
            return "doc.plaintext"
        } else {
            return "doc"
        }
    }

    /// Formats file size for display
    private var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: file.fileSize, countStyle: .file)
    }
}

// MARK: - File Info Detail View

/// A detailed view showing complete file metadata.
/// Useful for displaying file information before saving to database.
///
/// ## Example
/// ```swift
/// AISFileInfoDetailView(file: selectedFile)
/// ```
///
public struct AISFileInfoDetailView: View {
    let file: AISFileInfo

    @Environment(\.aisTokens) private var tokens

    public init(file: AISFileInfo) {
        self.file = file
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            // Header
            Text("File Details")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Divider()

            // Metadata rows
            Group {
                metadataRow(label: "File Name", value: file.fileName)
                metadataRow(label: "MIME Type", value: file.mimeType)
                metadataRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: file.fileSize, countStyle: .file))
                metadataRow(label: "MD5 Checksum", value: file.checksum, monospace: true)
                metadataRow(label: "Path", value: file.localPath, monospace: true)

                if let created = file.createdAt {
                    metadataRow(label: "Created", value: created.formatted(date: .abbreviated, time: .shortened))
                }

                if let modified = file.modifiedAt {
                    metadataRow(label: "Modified", value: modified.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .padding(AISSpacing.md)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }

    @ViewBuilder
    private func metadataRow(label: String, value: String, monospace: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)

            Text(value)
                .font(monospace ? .system(.body, design: .monospaced) : .body)
                .foregroundColor(tokens.onSurface)
                .textSelection(.enabled)
        }
        .padding(.vertical, AISSpacing.xs)
    }
}

// MARK: - Preview

#if DEBUG
struct AISMediaPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AISSpacing.xl) {
            // Basic picker
            AISMediaPicker(
                allowedTypes: [.image, .pdf],
                buttonLabel: "Attach Documents"
            ) { files in
                print("Selected: \(files)")
            }

            // Sample file info row
            AISFileInfoRow(
                file: AISFileInfo(
                    fileName: "document.pdf",
                    mimeType: "application/pdf",
                    fileSize: 1_234_567,
                    checksum: "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6",
                    localPath: "/Users/test/Documents/document.pdf",
                    createdAt: Date(),
                    modifiedAt: Date()
                ),
                onRemove: { print("Remove tapped") }
            )

            // Detail view
            AISFileInfoDetailView(
                file: AISFileInfo(
                    fileName: "photo.png",
                    mimeType: "image/png",
                    fileSize: 2_345_678,
                    checksum: "f1e2d3c4b5a6f7e8d9c0b1a2f3e4d5c6",
                    localPath: "/Users/test/Pictures/photo.png",
                    createdAt: Date().addingTimeInterval(-86400),
                    modifiedAt: Date()
                )
            )
        }
        .padding()
        .withAISTokens()
    }
}
#endif

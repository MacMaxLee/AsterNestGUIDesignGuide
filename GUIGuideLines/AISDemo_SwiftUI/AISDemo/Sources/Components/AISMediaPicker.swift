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
#if os(macOS)
import AppKit
import AVFoundation
#elseif os(iOS)
import UIKit
import AVFoundation
#endif

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

/// Input sources for file selection.
/// Defines how users can provide files to the picker.
public enum AISInputSource: CaseIterable, Identifiable {
    /// Select files from the file system
    case files

    /// Capture image from camera (iOS/macOS with camera)
    case camera

    /// Paste image from clipboard
    case clipboard

    public var id: String { displayName }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .files: return "Browse Files"
        case .camera: return "Camera"
        case .clipboard: return "Paste"
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .files: return "folder"
        case .camera: return "camera"
        case .clipboard: return "doc.on.clipboard"
        }
    }

    /// Check if this source is available on the current platform
    public var isAvailable: Bool {
        switch self {
        case .files:
            return true
        case .camera:
            #if os(iOS)
            return UIImagePickerController.isSourceTypeAvailable(.camera)
            #elseif os(macOS)
            return AVCaptureDevice.default(for: .video) != nil
            #else
            return false
            #endif
        case .clipboard:
            return true
        }
    }
}

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

    /// Allowed input sources (files, camera, clipboard)
    let inputSources: [AISInputSource]

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

    /// Show input source selector (when multiple sources available)
    let showSourceSelector: Bool

    /// Enable built-in review mode before confirming selection
    let enableReview: Bool

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - State

    @State private var showFilePicker = false
    @State private var showCamera = false
    @State private var showSourceMenu = false
    @State private var processingProgress: Double = 0
    @State private var clipboardHasImage = false

    // Review mode state
    @State private var pendingFiles: [AISFileInfo] = []
    @State private var showReviewPanel = false
    @State private var selectedFileForPreview: AISFileInfo?

    // MARK: - Initialization

    /// Creates a media picker with the specified configuration.
    ///
    /// - Parameters:
    ///   - state: Binding to track picker state
    ///   - allowedTypes: Array of allowed file categories (default: [.any])
    ///   - inputSources: Array of allowed input sources (default: [.files, .clipboard])
    ///   - allowsMultiple: Whether multiple selection is allowed (default: true)
    ///   - maxFileSize: Maximum file size in bytes (default: nil)
    ///   - buttonLabel: Custom button text (default: "Select Files")
    ///   - buttonType: Semantic button type (default: .primary)
    ///   - showSourceSelector: Show source selection UI (default: true)
    ///   - enableReview: Show review panel before confirming (default: false)
    ///   - onFilesSelected: Callback with selected file infos
    ///   - onError: Optional error callback
    ///
    public init(
        state: Binding<AISFilePickerState> = .constant(.idle),
        allowedTypes: [AISFileCategory] = [.any],
        inputSources: [AISInputSource] = [.files, .clipboard],
        allowsMultiple: Bool = true,
        maxFileSize: Int64? = nil,
        buttonLabel: String = "Select Files",
        buttonType: AISButtonType = .primary,
        showSourceSelector: Bool = true,
        enableReview: Bool = false,
        onFilesSelected: @escaping ([AISFileInfo]) -> Void,
        onError: ((AISFilePickerError) -> Void)? = nil
    ) {
        self._state = state
        self.allowedTypes = allowedTypes
        self.inputSources = inputSources
        self.allowsMultiple = allowsMultiple
        self.maxFileSize = maxFileSize
        self.buttonLabel = buttonLabel
        self.buttonType = buttonType
        self.showSourceSelector = showSourceSelector
        self.enableReview = enableReview
        self.onFilesSelected = onFilesSelected
        self.onError = onError
    }

    /// Available input sources based on configuration and platform
    private var availableSources: [AISInputSource] {
        inputSources.filter { $0.isAvailable }
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            // Review header (when files are pending)
            if enableReview && !pendingFiles.isEmpty {
                reviewHeader
            }

            // Source selector (if multiple sources available)
            if showSourceSelector && availableSources.count > 1 {
                sourceSelector
            }

            // Picker button with state-aware content
            pickerButton

            // Review panel (when enabled and files pending)
            if enableReview && showReviewPanel && !pendingFiles.isEmpty {
                reviewPanel
            }

            // Review action buttons
            if enableReview && !pendingFiles.isEmpty {
                reviewActionButtons
            }

            // State indicator (only when not in review mode or no pending files)
            if !enableReview || pendingFiles.isEmpty {
                stateIndicator
            }
        }
        .onAppear {
            checkClipboardContent()
        }
        .sheet(item: $selectedFileForPreview) { file in
            filePreviewSheet(file)
        }
        #if os(iOS)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: allowedTypes.map(\.utType),
            allowsMultipleSelection: allowsMultiple,
            onCompletion: handleFileSelection
        )
        .sheet(isPresented: $showCamera) {
            CameraCapture { image in
                Task {
                    await processImage(image, source: "camera")
                }
            }
        }
        #endif
    }

    // MARK: - Review Header

    private var reviewHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected Files")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                Text("\(pendingFiles.count) file(s) ready for review")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }

            Spacer()

            Button {
                withAnimation {
                    showReviewPanel.toggle()
                }
            } label: {
                Image(systemName: showReviewPanel ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }
            .buttonStyle(.plain)
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    // MARK: - Review Panel

    private var reviewPanel: some View {
        VStack(spacing: AISSpacing.sm) {
            ForEach(pendingFiles) { file in
                reviewFileRow(file)
            }
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    private func reviewFileRow(_ file: AISFileInfo) -> some View {
        HStack(spacing: AISSpacing.md) {
            // Thumbnail or icon
            filePreviewThumbnail(file)
                .frame(width: 50, height: 50)
                .cornerRadius(AISRadius.sm)
                .onTapGesture {
                    selectedFileForPreview = file
                }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(tokens.onSurface))
                    .lineLimit(1)

                HStack(spacing: AISSpacing.xs) {
                    Text(ByteCountFormatter.string(fromByteCount: file.fileSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))

                    Text("•")
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))

                    Text(file.mimeType)
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Preview button
            Button {
                selectedFileForPreview = file
            } label: {
                Image(systemName: "eye")
                    .font(.caption)
                    .foregroundColor(Color(tokens.actionPrimary.color))
            }
            .buttonStyle(.plain)

            // Remove button
            Button {
                withAnimation {
                    pendingFiles.removeAll { $0.id == file.id }
                    if pendingFiles.isEmpty {
                        showReviewPanel = false
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(tokens.stateError.color).opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(AISSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.sm)
                .fill(Color(tokens.surface))
        )
    }

    @ViewBuilder
    private func filePreviewThumbnail(_ file: AISFileInfo) -> some View {
        if file.mimeType.hasPrefix("image/") {
            AsyncImageThumbnail(file: file)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: AISRadius.sm)
                    .fill(Color(tokens.actionPrimary.color).opacity(0.1))

                Image(systemName: thumbnailIconForMimeType(file.mimeType))
                    .font(.title3)
                    .foregroundColor(Color(tokens.actionPrimary.color))
            }
        }
    }

    private func thumbnailIconForMimeType(_ mimeType: String) -> String {
        if mimeType.hasPrefix("image/") { return "photo" }
        if mimeType.hasPrefix("video/") { return "video" }
        if mimeType.hasPrefix("audio/") { return "music.note" }
        if mimeType == "application/pdf" { return "doc.text" }
        if mimeType.hasPrefix("text/") { return "doc.plaintext" }
        return "doc"
    }

    // MARK: - Review Action Buttons

    private var reviewActionButtons: some View {
        HStack(spacing: AISSpacing.md) {
            // Clear all button
            Button {
                withAnimation {
                    pendingFiles.removeAll()
                    showReviewPanel = false
                }
            } label: {
                HStack(spacing: AISSpacing.xs) {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text("Clear All")
                        .font(.subheadline)
                }
                .foregroundColor(Color(tokens.stateError.color))
            }
            .buttonStyle(.plain)

            Spacer()

            // Confirm button
            AISButton("Confirm (\(pendingFiles.count))", type: .confirm, icon: "checkmark") {
                onFilesSelected(pendingFiles)
                state = .completed(pendingFiles)
                withAnimation {
                    pendingFiles.removeAll()
                    showReviewPanel = false
                }
            }
        }
    }

    // MARK: - File Preview Sheet

    private func filePreviewSheet(_ file: AISFileInfo) -> some View {
        NavigationStack {
            ScrollView {
                AISFileInfoDetailView(file: file)
                    .padding(AISSpacing.lg)
            }
            .background(Color(tokens.surface))
            .navigationTitle("File Preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedFileForPreview = nil
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
    }

    // MARK: - Source Selector

    @ViewBuilder
    private var sourceSelector: some View {
        HStack(spacing: AISSpacing.sm) {
            ForEach(availableSources) { source in
                sourceButton(for: source)
            }
        }
    }

    @ViewBuilder
    private func sourceButton(for source: AISInputSource) -> some View {
        Button {
            handleSourceSelection(source)
        } label: {
            HStack(spacing: AISSpacing.xs) {
                Image(systemName: source.iconName)
                    .font(.caption)
                Text(source.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, AISSpacing.sm)
            .padding(.vertical, AISSpacing.xs)
            .background(tokens.surfaceSecondary)
            .foregroundColor(
                source == .clipboard && !clipboardHasImage && allowedTypes.contains(.image)
                    ? tokens.onSurfaceSecondary.opacity(0.5)
                    : tokens.onSurface
            )
            .cornerRadius(AISRadius.sm)
        }
        .buttonStyle(.plain)
        .disabled(source == .clipboard && !clipboardHasImage && allowedTypes.contains(.image))
    }

    private func handleSourceSelection(_ source: AISInputSource) {
        switch source {
        case .files:
            openFilePicker()
        case .camera:
            #if os(iOS)
            showCamera = true
            #elseif os(macOS)
            openMacCamera()
            #endif
        case .clipboard:
            pasteFromClipboard()
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
                openFilePicker()
            }
        }
    }

    // MARK: - Native File Picker

    /// Opens native file picker with proper Cancel button support
    private func openFilePicker() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = allowsMultiple
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = allowedTypes.map(\.utType)
        panel.message = "Select files to attach"
        panel.prompt = "Select"

        // Show the panel
        panel.begin { response in
            if response == .OK {
                let urls = panel.urls
                if urls.isEmpty {
                    self.state = .error(.cancelled)
                    self.onError?(.cancelled)
                } else {
                    Task {
                        await self.processFiles(urls)
                    }
                }
            } else {
                // User clicked Cancel
                self.state = .idle
            }
        }
        #else
        // On iOS, use the fileImporter modifier approach
        showFilePicker = true
        #endif
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
            if enableReview {
                // In review mode, add to pending files instead of calling callback
                withAnimation {
                    pendingFiles.append(contentsOf: fileInfos)
                    showReviewPanel = true
                }
                state = .idle
            } else {
                // Normal mode - directly call callback
                state = .completed(fileInfos)
                onFilesSelected(fileInfos)
            }
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

    // MARK: - Clipboard Handling

    /// Check if clipboard contains image content
    private func checkClipboardContent() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        clipboardHasImage = pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes)
            || pasteboard.canReadItem(withDataConformingToTypes: [UTType.fileURL.identifier])
        #elseif os(iOS)
        clipboardHasImage = UIPasteboard.general.hasImages || UIPasteboard.general.hasURLs
        #endif
    }

    /// Paste content from clipboard
    private func pasteFromClipboard() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general

        // Try to get image from clipboard
        if let image = NSImage(pasteboard: pasteboard) {
            Task {
                await processNSImage(image)
            }
            return
        }

        // Try to get file URLs from clipboard
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            Task {
                await processFiles(urls)
            }
            return
        }

        // Try to get text/PDF data
        if let data = pasteboard.data(forType: .pdf) {
            Task {
                await processPastedData(data, mimeType: "application/pdf", extension: "pdf")
            }
            return
        }

        if let string = pasteboard.string(forType: .string) {
            Task {
                await processPastedText(string)
            }
            return
        }

        state = .error(.unknown("No compatible content found in clipboard"))
        onError?(.unknown("No compatible content found in clipboard"))
        #elseif os(iOS)
        let pasteboard = UIPasteboard.general

        // Try to get image
        if let image = pasteboard.image {
            Task {
                await processImage(image, source: "clipboard")
            }
            return
        }

        // Try to get file URLs
        if let urls = pasteboard.urls {
            Task {
                await processFiles(urls)
            }
            return
        }

        // Try to get text
        if let string = pasteboard.string {
            Task {
                await processPastedText(string)
            }
            return
        }

        state = .error(.unknown("No compatible content found in clipboard"))
        onError?(.unknown("No compatible content found in clipboard"))
        #endif
    }

    #if os(macOS)
    /// Process NSImage from clipboard
    @MainActor
    private func processNSImage(_ image: NSImage) async {
        state = .processing(progress: 0.5)

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            state = .error(.readError("clipboard_image"))
            onError?(.readError("clipboard_image"))
            return
        }

        // Check file size
        if let maxSize = maxFileSize, Int64(pngData.count) > maxSize {
            state = .error(.fileTooLarge("clipboard_image.png", Int64(pngData.count)))
            onError?(.fileTooLarge("clipboard_image.png", Int64(pngData.count)))
            return
        }

        let checksum = computeMD5(data: pngData)
        let fileName = "clipboard_image_\(Date().timeIntervalSince1970).png"

        // Save to temp directory for path reference
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pngData.write(to: tempURL)

        let fileInfo = AISFileInfo(
            fileName: fileName,
            mimeType: "image/png",
            fileSize: Int64(pngData.count),
            checksum: checksum,
            localPath: tempURL.path,
            createdAt: Date(),
            modifiedAt: Date(),
            metadata: ["source": "clipboard"]
        )

        state = .completed([fileInfo])
        onFilesSelected([fileInfo])
    }

    /// Open macOS camera (if available)
    private func openMacCamera() {
        // macOS camera integration would require AVCaptureSession setup
        // For now, fallback to file picker
        state = .error(.unknown("Camera capture not yet implemented for macOS"))
        onError?(.unknown("Camera capture not yet implemented for macOS"))
    }
    #endif

    #if os(iOS)
    /// Process UIImage from camera or clipboard
    @MainActor
    private func processImage(_ image: UIImage, source: String) async {
        state = .processing(progress: 0.5)

        guard let pngData = image.pngData() else {
            state = .error(.readError("\(source)_image"))
            onError?(.readError("\(source)_image"))
            return
        }

        // Check file size
        if let maxSize = maxFileSize, Int64(pngData.count) > maxSize {
            state = .error(.fileTooLarge("\(source)_image.png", Int64(pngData.count)))
            onError?(.fileTooLarge("\(source)_image.png", Int64(pngData.count)))
            return
        }

        let checksum = computeMD5(data: pngData)
        let fileName = "\(source)_image_\(Date().timeIntervalSince1970).png"

        // Save to temp directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pngData.write(to: tempURL)

        let fileInfo = AISFileInfo(
            fileName: fileName,
            mimeType: "image/png",
            fileSize: Int64(pngData.count),
            checksum: checksum,
            localPath: tempURL.path,
            createdAt: Date(),
            modifiedAt: Date(),
            metadata: ["source": source]
        )

        state = .completed([fileInfo])
        onFilesSelected([fileInfo])
    }
    #endif

    /// Process pasted data (PDF, etc.)
    @MainActor
    private func processPastedData(_ data: Data, mimeType: String, extension ext: String) async {
        state = .processing(progress: 0.5)

        // Check file size
        if let maxSize = maxFileSize, Int64(data.count) > maxSize {
            state = .error(.fileTooLarge("pasted_file.\(ext)", Int64(data.count)))
            onError?(.fileTooLarge("pasted_file.\(ext)", Int64(data.count)))
            return
        }

        let checksum = computeMD5(data: data)
        let fileName = "pasted_\(Date().timeIntervalSince1970).\(ext)"

        // Save to temp directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)

        let fileInfo = AISFileInfo(
            fileName: fileName,
            mimeType: mimeType,
            fileSize: Int64(data.count),
            checksum: checksum,
            localPath: tempURL.path,
            createdAt: Date(),
            modifiedAt: Date(),
            metadata: ["source": "clipboard"]
        )

        state = .completed([fileInfo])
        onFilesSelected([fileInfo])
    }

    /// Process pasted text content
    @MainActor
    private func processPastedText(_ text: String) async {
        state = .processing(progress: 0.5)

        let data = Data(text.utf8)

        // Check file size
        if let maxSize = maxFileSize, Int64(data.count) > maxSize {
            state = .error(.fileTooLarge("pasted_text.txt", Int64(data.count)))
            onError?(.fileTooLarge("pasted_text.txt", Int64(data.count)))
            return
        }

        let checksum = computeMD5(data: data)
        let fileName = "pasted_text_\(Date().timeIntervalSince1970).txt"

        // Save to temp directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)

        let fileInfo = AISFileInfo(
            fileName: fileName,
            mimeType: "text/plain",
            fileSize: Int64(data.count),
            checksum: checksum,
            localPath: tempURL.path,
            createdAt: Date(),
            modifiedAt: Date(),
            metadata: ["source": "clipboard"]
        )

        state = .completed([fileInfo])
        onFilesSelected([fileInfo])
    }
}

// MARK: - Camera Capture View (iOS)

#if os(iOS)
import UIKit

struct CameraCapture: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif

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

/// A detailed view showing complete file metadata with preview support.
/// For images, displays a visual preview. For other files, shows an icon.
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
    @State private var previewImage: AISImageType?
    @State private var loadError: String?

    public init(file: AISFileInfo) {
        self.file = file
    }

    /// Check if file is an image type
    private var isImage: Bool {
        file.mimeType.hasPrefix("image/")
    }

    /// Check if file is a PDF
    private var isPDF: Bool {
        file.mimeType == "application/pdf"
    }

    /// SF Symbol for file type
    private var fileIcon: String {
        if isImage { return "photo" }
        if isPDF { return "doc.text" }
        if file.mimeType.hasPrefix("video/") { return "video" }
        if file.mimeType.hasPrefix("audio/") { return "music.note" }
        if file.mimeType.hasPrefix("text/") { return "doc.plaintext" }
        return "doc"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            // File Preview Section
            previewSection

            Divider()

            // Header
            Text("File Details")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

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
        .onAppear {
            loadPreview()
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        VStack(spacing: AISSpacing.sm) {
            if isImage {
                // Image preview
                if let image = previewImage {
                    #if os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .cornerRadius(AISRadius.md)
                        .shadow(radius: 2)
                    #else
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .cornerRadius(AISRadius.md)
                        .shadow(radius: 2)
                    #endif
                } else if let error = loadError {
                    // Error loading image
                    VStack(spacing: AISSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(tokens.stateWarning.color)
                        Text("Failed to load preview")
                            .font(.subheadline)
                            .foregroundColor(tokens.onSurfaceSecondary)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(tokens.surface)
                    .cornerRadius(AISRadius.md)
                } else {
                    // Loading state
                    VStack(spacing: AISSpacing.sm) {
                        ProgressView()
                        Text("Loading preview...")
                            .font(.caption)
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(tokens.surface)
                    .cornerRadius(AISRadius.md)
                }
            } else {
                // Non-image file icon preview
                VStack(spacing: AISSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AISRadius.lg)
                            .fill(tokens.actionPrimary.color.opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: fileIcon)
                            .font(.system(size: 48))
                            .foregroundColor(tokens.actionPrimary.color)
                    }

                    Text(file.fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(tokens.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .padding(AISSpacing.md)
            }
        }
    }

    // MARK: - Preview Loading

    private func loadPreview() {
        guard isImage else { return }

        // Load image from file path
        let url = URL(fileURLWithPath: file.localPath)

        // Start accessing security-scoped resource if needed
        let didStartAccess = url.startAccessingSecurityScopedResource()

        #if os(macOS)
        if let image = NSImage(contentsOf: url) {
            previewImage = image
        } else {
            loadError = "Unable to load image from path"
        }
        #else
        if let image = UIImage(contentsOfFile: file.localPath) {
            previewImage = image
        } else {
            loadError = "Unable to load image from path"
        }
        #endif

        if didStartAccess {
            url.stopAccessingSecurityScopedResource()
        }
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

// MARK: - Platform Image Type Alias

#if os(macOS)
typealias AISImageType = NSImage
#else
typealias AISImageType = UIImage
#endif

// MARK: - Media Picker With Review

/// A media picker with built-in review functionality.
/// Shows selected files in a review panel before final confirmation.
///
/// ## Features
/// - Built-in review panel showing all selected files
/// - Image preview for image files
/// - File metadata display
/// - Remove individual files before confirmation
/// - Clear all / Confirm buttons
///
/// ## Example
/// ```swift
/// AISMediaPickerWithReview(
///     allowedTypes: [.image, .pdf],
///     allowsMultiple: true,
///     onConfirm: { files in
///         viewModel.uploadFiles(files)
///     },
///     onCancel: {
///         dismiss()
///     }
/// )
/// ```
///
public struct AISMediaPickerWithReview: View {
    // MARK: - Properties

    let allowedTypes: [AISFileCategory]
    let allowsMultiple: Bool
    let maxFileSize: Int64?
    let showSourceSelector: Bool
    let onConfirm: ([AISFileInfo]) -> Void
    let onCancel: (() -> Void)?

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - State

    @State private var pickerState: AISFilePickerState = .idle
    @State private var selectedFiles: [AISFileInfo] = []
    @State private var showingReview = false
    @State private var selectedFileForPreview: AISFileInfo?

    // MARK: - Initialization

    public init(
        allowedTypes: [AISFileCategory] = [.any],
        allowsMultiple: Bool = true,
        maxFileSize: Int64? = nil,
        showSourceSelector: Bool = true,
        onConfirm: @escaping ([AISFileInfo]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.allowedTypes = allowedTypes
        self.allowsMultiple = allowsMultiple
        self.maxFileSize = maxFileSize
        self.showSourceSelector = showSourceSelector
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: AISSpacing.lg) {
            // Header with count
            if !selectedFiles.isEmpty {
                reviewHeader
            }

            // File picker
            AISMediaPicker(
                state: $pickerState,
                allowedTypes: allowedTypes,
                allowsMultiple: allowsMultiple,
                maxFileSize: maxFileSize,
                buttonLabel: selectedFiles.isEmpty ? "Select Files" : "Add More Files",
                buttonType: selectedFiles.isEmpty ? .primary : .neutral,
                showSourceSelector: showSourceSelector,
                onFilesSelected: { files in
                    withAnimation {
                        selectedFiles.append(contentsOf: files)
                        showingReview = true
                    }
                }
            )

            // Review panel
            if showingReview && !selectedFiles.isEmpty {
                reviewPanel
            }

            // Action buttons
            if !selectedFiles.isEmpty {
                actionButtons
            }
        }
        .sheet(item: $selectedFileForPreview) { file in
            filePreviewSheet(file)
        }
    }

    // MARK: - Review Header

    private var reviewHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected Files")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(tokens.onSurface))

                Text("\(selectedFiles.count) file(s) ready for review")
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }

            Spacer()

            // Toggle review panel
            Button {
                withAnimation {
                    showingReview.toggle()
                }
            } label: {
                Image(systemName: showingReview ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color(tokens.onSurfaceSecondary))
            }
            .buttonStyle(.plain)
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    // MARK: - Review Panel

    private var reviewPanel: some View {
        VStack(spacing: AISSpacing.sm) {
            ForEach(selectedFiles) { file in
                reviewFileRow(file)
            }
        }
        .padding(AISSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .fill(Color(tokens.surfaceSecondary))
        )
    }

    private func reviewFileRow(_ file: AISFileInfo) -> some View {
        HStack(spacing: AISSpacing.md) {
            // Thumbnail or icon
            filePreviewThumbnail(file)
                .frame(width: 50, height: 50)
                .cornerRadius(AISRadius.sm)
                .onTapGesture {
                    selectedFileForPreview = file
                }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(tokens.onSurface))
                    .lineLimit(1)

                HStack(spacing: AISSpacing.xs) {
                    Text(ByteCountFormatter.string(fromByteCount: file.fileSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))

                    Text("•")
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))

                    Text(file.mimeType)
                        .font(.caption)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Preview button
            Button {
                selectedFileForPreview = file
            } label: {
                Image(systemName: "eye")
                    .font(.caption)
                    .foregroundColor(Color(tokens.actionPrimary.color))
            }
            .buttonStyle(.plain)

            // Remove button
            Button {
                withAnimation {
                    selectedFiles.removeAll { $0.id == file.id }
                    if selectedFiles.isEmpty {
                        showingReview = false
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(tokens.stateError.color).opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(AISSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AISRadius.sm)
                .fill(Color(tokens.surface))
        )
    }

    @ViewBuilder
    private func filePreviewThumbnail(_ file: AISFileInfo) -> some View {
        if file.mimeType.hasPrefix("image/") {
            // Show image thumbnail
            AsyncImageThumbnail(file: file)
        } else {
            // Show file type icon
            ZStack {
                RoundedRectangle(cornerRadius: AISRadius.sm)
                    .fill(Color(tokens.actionPrimary.color).opacity(0.1))

                Image(systemName: iconForMimeType(file.mimeType))
                    .font(.title3)
                    .foregroundColor(Color(tokens.actionPrimary.color))
            }
        }
    }

    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.hasPrefix("image/") { return "photo" }
        if mimeType.hasPrefix("video/") { return "video" }
        if mimeType.hasPrefix("audio/") { return "music.note" }
        if mimeType == "application/pdf" { return "doc.text" }
        if mimeType.hasPrefix("text/") { return "doc.plaintext" }
        return "doc"
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AISSpacing.md) {
            // Clear all button
            AISButton("Clear All", type: .destructive, style: .outlined) {
                withAnimation {
                    selectedFiles.removeAll()
                    showingReview = false
                }
            }

            Spacer()

            // Cancel button (if provided)
            if onCancel != nil {
                AISButton("Cancel", type: .neutral) {
                    onCancel?()
                }
            }

            // Confirm button
            AISButton("Confirm (\(selectedFiles.count))", type: .confirm, icon: "checkmark") {
                onConfirm(selectedFiles)
            }
        }
    }

    // MARK: - Preview Sheet

    private func filePreviewSheet(_ file: AISFileInfo) -> some View {
        NavigationStack {
            ScrollView {
                AISFileInfoDetailView(file: file)
                    .padding(AISSpacing.lg)
            }
            .background(Color(tokens.surface))
            .navigationTitle("File Preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedFileForPreview = nil
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
    }
}

// MARK: - Async Image Thumbnail

/// Loads and displays image thumbnail asynchronously
private struct AsyncImageThumbnail: View {
    let file: AISFileInfo

    @State private var image: AISImageType?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = image {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                #endif
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
        }
        .clipped()
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let url = URL(fileURLWithPath: file.localPath)
        let didStartAccess = url.startAccessingSecurityScopedResource()

        DispatchQueue.global(qos: .userInitiated).async {
            #if os(macOS)
            let loadedImage = NSImage(contentsOf: url)
            #else
            let loadedImage = UIImage(contentsOfFile: file.localPath)
            #endif

            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false

                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
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

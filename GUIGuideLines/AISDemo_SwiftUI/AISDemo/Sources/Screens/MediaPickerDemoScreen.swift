// =============================================================================
// MediaPickerDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates the AISMediaPicker component with real file selection,
// metadata extraction, and display. Shows how to capture complete file
// information for database storage.
//
// =============================================================================

import SwiftUI

struct MediaPickerDemoScreen: View {
    // MARK: - State

    @State private var selectedFiles: [AISFileInfo] = []
    @State private var pickerState: AISFilePickerState = .idle
    @State private var selectedFileForDetail: AISFileInfo?
    @State private var showingDetail = false
    @State private var showingJSON = false

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // File Picker Types
                filePickerSection

                // Selected Files List
                selectedFilesSection

                // JSON Output (for database reference)
                if !selectedFiles.isEmpty {
                    jsonOutputSection
                }
            }
            .padding(AISSpacing.lg)
        }
        .navigationTitle("Media Picker")
        .sheet(isPresented: $showingDetail) {
            if let file = selectedFileForDetail {
                NavigationStack {
                    ScrollView {
                        AISFileInfoDetailView(file: file)
                            .padding()
                    }
                    .navigationTitle("File Details")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingDetail = false
                            }
                        }
                    }
                }
                .frame(minWidth: 400, minHeight: 300)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("AIS Media Picker")
                .font(.title2.bold())

            Text("Select files to extract complete metadata for database storage. The picker captures file path, size, MIME type, MD5 checksum, and timestamps.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private var filePickerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("File Selection", description: "Different file type filters")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AISSpacing.md) {
                // Images
                pickerCard(
                    title: "Images",
                    icon: "photo",
                    types: [.image]
                )

                // Documents
                pickerCard(
                    title: "PDFs",
                    icon: "doc.text",
                    types: [.pdf]
                )

                // Any Files
                pickerCard(
                    title: "Any File",
                    icon: "doc",
                    types: [.any]
                )
            }

            // Multiple file picker
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("Multiple File Selection").font(.subheadline.bold())

                AISMediaPicker(
                    state: $pickerState,
                    allowedTypes: [.image, .pdf, .plainText],
                    allowsMultiple: true,
                    maxFileSize: 50_000_000, // 50MB limit
                    buttonLabel: "Select Multiple Files",
                    buttonType: .primary,
                    onFilesSelected: { files in
                        selectedFiles.append(contentsOf: files)
                    },
                    onError: { error in
                        print("Error: \(error.localizedDescription)")
                    }
                )
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
        }
    }

    private var selectedFilesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            HStack {
                sectionHeader("Selected Files", description: "Tap a file to see details")

                Spacer()

                if !selectedFiles.isEmpty {
                    AISButton("Clear All", type: .neutral, style: .text, size: .small) {
                        selectedFiles.removeAll()
                    }
                }
            }

            if selectedFiles.isEmpty {
                emptyState
            } else {
                VStack(spacing: AISSpacing.sm) {
                    ForEach(selectedFiles) { file in
                        AISFileInfoRow(file: file) {
                            selectedFiles.removeAll { $0.id == file.id }
                        }
                        .onTapGesture {
                            selectedFileForDetail = file
                            showingDetail = true
                        }
                    }
                }
            }
        }
    }

    private var jsonOutputSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            HStack {
                sectionHeader("JSON Output", description: "Ready for database storage")

                Spacer()

                AISButton("Copy JSON", type: .secondary, style: .outlined, size: .small) {
                    copyJSONToClipboard()
                }
            }

            ScrollView(.horizontal, showsIndicators: true) {
                Text(jsonOutput)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(tokens.onSurface)
                    .textSelection(.enabled)
            }
            .padding(AISSpacing.md)
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
            .frame(maxHeight: 200)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AISSpacing.md) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(tokens.onSurfaceSecondary)

            Text("No files selected")
                .font(.headline)
                .foregroundColor(tokens.onSurfaceSecondary)

            Text("Use the pickers above to select files")
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AISSpacing.xl)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.xs) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private func pickerCard(title: String, icon: String, types: [AISFileCategory]) -> some View {
        VStack(spacing: AISSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(tokens.actionPrimary.color)

            Text(title)
                .font(.subheadline.bold())

            AISMediaPicker(
                allowedTypes: types,
                allowsMultiple: false,
                buttonLabel: "Select",
                buttonType: .secondary,
                onFilesSelected: { files in
                    selectedFiles.append(contentsOf: files)
                }
            )
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }

    // MARK: - Computed Properties

    private var jsonOutput: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let fileData = selectedFiles.map { file in
            [
                "id": file.id.uuidString,
                "fileName": file.fileName,
                "mimeType": file.mimeType,
                "fileSize": file.fileSize,
                "checksum": file.checksum,
                "localPath": file.localPath,
                "createdAt": file.createdAt?.ISO8601Format() ?? "null",
                "modifiedAt": file.modifiedAt?.ISO8601Format() ?? "null",
                "metadata": file.metadata
            ] as [String : Any]
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: fileData, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return "Error generating JSON: \(error.localizedDescription)"
        }
    }

    // MARK: - Actions

    private func copyJSONToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(jsonOutput, forType: .string)
        #else
        UIPasteboard.general.string = jsonOutput
        #endif
    }
}

// MARK: - Preview

#if DEBUG
struct MediaPickerDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MediaPickerDemoScreen()
        }
        .withAISTokens()
    }
}
#endif

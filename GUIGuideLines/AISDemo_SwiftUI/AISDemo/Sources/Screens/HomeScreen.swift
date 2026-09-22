// =============================================================================
// HomeScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Main navigation hub for the AIS Demo App. Provides access to all
// component demonstrations and serves as the app's landing page.
//
// =============================================================================

import SwiftUI

// MARK: - Demo Category

/// Categories of demos available in the app.
enum DemoCategory: String, CaseIterable, Identifiable {
    case buttons = "Buttons"
    case values = "Value Components"
    case dataGrid = "Data Grid"
    case gridLayout = "Grid Layout"
    case mediaPicker = "Media Picker"
    case docScan = "Document Scan"
    case aiSettings = "AI Settings"
    case errorHandling = "Error Handling"
    case stateBadges = "State Badges"
    case listDetail = "List-Detail Shell"

    var id: String { rawValue }

    /// SF Symbol icon for the category
    var icon: String {
        switch self {
        case .buttons: return "hand.tap"
        case .values: return "number"
        case .dataGrid: return "tablecells"
        case .gridLayout: return "square.grid.3x3"
        case .mediaPicker: return "photo.on.rectangle"
        case .docScan: return "doc.text.magnifyingglass"
        case .aiSettings: return "brain.head.profile"
        case .errorHandling: return "exclamationmark.triangle"
        case .stateBadges: return "flag"
        case .listDetail: return "rectangle.split.2x1"
        }
    }

    /// Description of the demo
    var description: String {
        switch self {
        case .buttons:
            return "Semantic buttons with types, styles, and states"
        case .values:
            return "Numeric display with required annotations (C-04)"
        case .dataGrid:
            return "Excel-like grid with sorting and filtering (C-35, C-36)"
        case .gridLayout:
            return "Responsive grid layouts: fixed, adaptive, masonry"
        case .mediaPicker:
            return "File selection with metadata extraction"
        case .docScan:
            return "AI-powered document scanning with OCR extraction"
        case .aiSettings:
            return "Configure AI provider API keys and settings"
        case .errorHandling:
            return "Error envelopes, banners, and inline errors"
        case .stateBadges:
            return "Visual state indicators and progress"
        case .listDetail:
            return "Master-detail pattern with state retention (C-05)"
        }
    }

    /// Destination view for navigation
    @ViewBuilder
    var destination: some View {
        switch self {
        case .buttons:
            ButtonDemoScreen()
        case .values:
            ValueComponentDemoScreen()
        case .dataGrid:
            DataGridDemoScreen()
        case .gridLayout:
            GridLayoutDemoScreen()
        case .mediaPicker:
            MediaPickerDemoScreen()
        case .docScan:
            DocScanDemoScreen()
        case .aiSettings:
            AISettingsDemoScreen()
        case .errorHandling:
            ErrorHandlingDemoScreen()
        case .stateBadges:
            StateBadgeDemoScreen()
        case .listDetail:
            ListDetailDemoScreen()
        }
    }
}

// MARK: - Home Screen

struct HomeScreen: View {
    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AISSpacing.xl) {
                    // Header
                    headerSection

                    // Demo Categories
                    categoriesSection

                    // About Section
                    aboutSection
                }
                .padding(AISSpacing.lg)
            }
            .navigationTitle("AIS Demo")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            HStack(spacing: AISSpacing.md) {
                // Logo placeholder
                RoundedRectangle(cornerRadius: AISRadius.lg)
                    .fill(tokens.actionPrimary.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("AIS")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Asternest Interface Standard")
                        .font(.title2.bold())
                    Text("SwiftUI Component Library")
                        .font(.subheadline)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }
            }

            Text("This demo app showcases all AIS-compliant UI components with their various configurations, states, and usage patterns.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
        .padding()
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.lg)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Component Demos")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AISSpacing.md) {
                ForEach(DemoCategory.allCases) { category in
                    NavigationLink(destination: category.destination) {
                        categoryCard(category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryCard(_ category: DemoCategory) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(tokens.actionPrimary.color)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }

            Text(category.rawValue)
                .font(.subheadline.bold())
                .foregroundColor(tokens.onSurface)

            Text(category.description)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(tokens.surface)
        .cornerRadius(AISRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .stroke(tokens.surfaceSecondary, lineWidth: 1)
        )
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("About AIS")
                .font(.headline)

            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                aboutRow(
                    icon: "paintpalette",
                    title: "Semantic Tokens",
                    description: "9 core tokens with color + icon pairing"
                )

                aboutRow(
                    icon: "checkmark.shield",
                    title: "Conformance Tests",
                    description: "C-01 to C-42 compliance checkpoints"
                )

                aboutRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    description: "Color is never the only signal (§2.3)"
                )

                aboutRow(
                    icon: "swift",
                    title: "Generic Types",
                    description: "Type-safe components with full generics"
                )
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)

            // Version info
            HStack {
                Text("AIS Version 1.0")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)

                Spacer()

                Text("SwiftUI Implementation")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
        }
    }

    private func aboutRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AISSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tokens.actionPrimary.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - List-Detail Demo Screen (Legacy - use ListDetailDemoScreen.swift instead)

/// Legacy demo screen - replaced by dedicated ListDetailDemoScreen.swift
private struct HomeScreen_ListDetailDemoView: View {
    // MARK: - Sample Data

    struct SampleItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let category: String
        let icon: String

        static var samples: [SampleItem] {
            [
                SampleItem(name: "Dashboard", category: "Overview", icon: "chart.bar"),
                SampleItem(name: "Users", category: "Management", icon: "person.2"),
                SampleItem(name: "Products", category: "Catalog", icon: "cube.box"),
                SampleItem(name: "Orders", category: "Sales", icon: "cart"),
                SampleItem(name: "Reports", category: "Analytics", icon: "doc.text.magnifyingglass"),
                SampleItem(name: "Settings", category: "Configuration", icon: "gear"),
            ]
        }
    }

    // MARK: - State

    @State private var items = SampleItem.samples
    @State private var selection: SampleItem?
    @State private var searchText = ""
    @State private var hasUnsavedChanges = false

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Filtered Items

    private var filteredItems: [SampleItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        AISListDetailShell(
            items: filteredItems,
            totalCount: items.count,
            selection: $selection,
            hasUnsavedChanges: hasUnsavedChanges,
            searchText: $searchText,
            emptyMessage: "No items available",
            noMatchesMessage: "No items match your search",
            onSaveChanges: {
                // Simulate save
                try? await Task.sleep(nanoseconds: 500_000_000)
                hasUnsavedChanges = false
            },
            onDiscardChanges: {
                hasUnsavedChanges = false
            },
            onClearFilters: {
                searchText = ""
            },
            onCreateNew: {
                let newItem = SampleItem(
                    name: "New Item",
                    category: "Custom",
                    icon: "star"
                )
                items.append(newItem)
                selection = newItem
            },
            rowContent: { item in
                // Row content
                AISListRow(
                    title: item.name,
                    subtitle: item.category,
                    leadingIcon: item.icon,
                    isSelected: selection?.id == item.id
                )
            },
            detailContent: { item in
                // Detail content
                detailView(for: item)
            }
        )
        .navigationTitle("List-Detail Demo")
    }

    // MARK: - Detail View

    private func detailView(for item: SampleItem) -> some View {
        VStack(spacing: AISSpacing.lg) {
            // Item icon
            Image(systemName: item.icon)
                .font(.system(size: 60))
                .foregroundColor(tokens.actionPrimary.color)

            // Item info
            VStack(spacing: AISSpacing.sm) {
                Text(item.name)
                    .font(.title)

                AISStateBadge(item.category, semanticState: .active, style: .pill)
            }

            Divider()

            // Demo controls
            VStack(spacing: AISSpacing.md) {
                Text("Demo Controls")
                    .font(.headline)

                Toggle("Has Unsaved Changes", isOn: $hasUnsavedChanges)

                Text("When enabled, switching selection will show a confirmation dialog (C-06)")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)

            // Conformance info
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("AIS Conformance")
                    .font(.headline)

                conformanceRow("C-05", description: "List state retention across edit cycles")
                conformanceRow("C-06", description: "Selection guard with unsaved changes")
                conformanceRow("C-07", description: "Dual empty states (no records vs no matches)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)

            Spacer()
        }
        .padding(AISSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func conformanceRow(_ code: String, description: String) -> some View {
        HStack(spacing: AISSpacing.sm) {
            Text(code)
                .font(.caption.bold().monospaced())
                .foregroundColor(tokens.actionPrimary.color)
                .padding(.horizontal, AISSpacing.xs)
                .padding(.vertical, 2)
                .background(tokens.actionPrimary.color.opacity(0.1))
                .cornerRadius(AISRadius.sm)

            Text(description)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }
}

// MARK: - DocScan Demo Screen (Legacy - use DocScanDemoScreen.swift instead)

// Local model for demo purposes (mirrors DocScanModels.swift structure)
struct LegacyDemoDocScanResult: Identifiable {
    let id = UUID()
    var invoiceNumber: String
    var vendorName: String
    var totalAmount: String
    var status: DemoDocScanStatus
    var providerUsed: DemoAIProvider
    var processingTimeMs: Int

    enum DemoDocScanStatus: String {
        case pending, review, approved
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .review: return "Review"
            case .approved: return "Approved"
            }
        }
        var iconName: String {
            switch self {
            case .pending: return "clock"
            case .review: return "eye"
            case .approved: return "checkmark.circle"
            }
        }
    }

    enum DemoAIProvider: String {
        case appleVision, localAI, cloudLLM
        var displayName: String {
            switch self {
            case .appleVision: return "Apple Vision"
            case .localAI: return "Local AI"
            case .cloudLLM: return "Cloud LLM"
            }
        }
        var iconName: String {
            switch self {
            case .appleVision: return "apple.logo"
            case .localAI: return "cpu"
            case .cloudLLM: return "cloud"
            }
        }
    }

    static var sampleResults: [LegacyDemoDocScanResult] {
        [
            LegacyDemoDocScanResult(
                invoiceNumber: "INV-2024-001",
                vendorName: "Acme Corp",
                totalAmount: "1,250.00",
                status: .approved,
                providerUsed: .appleVision,
                processingTimeMs: 342
            ),
            LegacyDemoDocScanResult(
                invoiceNumber: "INV-2024-002",
                vendorName: "TechSupply Inc",
                totalAmount: "3,875.50",
                status: .review,
                providerUsed: .cloudLLM,
                processingTimeMs: 1250
            )
        ]
    }
}

/// Legacy demo screen - replaced by dedicated DocScanDemoScreen.swift
private struct HomeScreen_DocScanDemoView: View {
    @Environment(\.aisTokens) private var tokens
    @State private var showDocScan = false
    @State private var capturedResults: [LegacyDemoDocScanResult] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // Description
                descriptionSection

                // Features
                featuresSection

                // Demo Button
                demoButtonSection

                // Captured Results
                if !capturedResults.isEmpty {
                    capturedResultsSection
                }

                // Code Example
                codeExampleSection
            }
            .padding(AISSpacing.lg)
        }
        .navigationTitle("Document Scan")
        .sheet(isPresented: $showDocScan) {
            docScanSheet
        }
    }

    private var headerSection: some View {
        HStack(spacing: AISSpacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(tokens.actionPrimary.color)

            VStack(alignment: .leading, spacing: AISSpacing.xs) {
                Text("AIS DocScan")
                    .font(.title2.bold())
                    .foregroundColor(tokens.onSurface)

                Text("AI-Powered Document Scanning")
                    .font(.subheadline)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
        }
        .padding(AISSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.lg)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("About DocScan")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("DocScan combines AISMediaPicker for file selection with AI-powered OCR extraction. It supports multiple AI providers in a tiered fallback chain, from on-device Apple Vision to cloud LLMs.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Features")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AISSpacing.md) {
                FeatureCard(
                    icon: "cpu",
                    title: "AI Router",
                    description: "Tiered AI provider fallback chain",
                    tokens: tokens
                )
                FeatureCard(
                    icon: "text.magnifyingglass",
                    title: "OCR Extraction",
                    description: "Automatic field recognition",
                    tokens: tokens
                )
                FeatureCard(
                    icon: "checkmark.circle",
                    title: "Validation",
                    description: "Built-in approval workflow",
                    tokens: tokens
                )
                FeatureCard(
                    icon: "pencil.circle",
                    title: "Editable Fields",
                    description: "Review and correct values",
                    tokens: tokens
                )
            }
        }
        .padding(AISSpacing.md)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }

    private var demoButtonSection: some View {
        VStack(spacing: AISSpacing.md) {
            AISButton("Simulate Document Scan", type: .primary) {
                // Add sample results for demo
                capturedResults.insert(contentsOf: LegacyDemoDocScanResult.sampleResults, at: 0)
            }

            Text("Simulates the DocScan workflow with sample data")
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var capturedResultsSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            HStack {
                Text("Captured Documents (\(capturedResults.count))")
                    .font(.headline)
                    .foregroundColor(tokens.onSurface)

                Spacer()

                Button("Clear All") {
                    capturedResults.removeAll()
                }
                .font(.caption)
                .foregroundColor(tokens.actionDestructive.color)
            }

            ForEach(capturedResults) { result in
                DemoCapturedResultCard(result: result, tokens: tokens)
            }
        }
    }

    private var codeExampleSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("Usage Example")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("""
            AISDocumentCapture(
                documentType: .invoice,
                preferredProvider: .appleVision,
                onDocumentCaptured: { result in
                    // Post to accounting system
                    viewModel.createAPEntry(from: result)
                },
                onCancel: {
                    dismiss()
                }
            )
            """)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(tokens.onSurface)
            .padding(AISSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
        }
    }

    private var docScanSheet: some View {
        NavigationStack {
            VStack(spacing: AISSpacing.xl) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 64))
                    .foregroundColor(tokens.actionPrimary.color)

                Text("Document Scanner")
                    .font(.title2.bold())
                    .foregroundColor(tokens.onSurface)

                Text("This is a placeholder for the full DocScan component. In a complete implementation, this would show the AISMediaPicker followed by OCR extraction and field review.")
                    .font(.body)
                    .foregroundColor(tokens.onSurfaceSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                AISButton("Simulate Capture", type: .primary) {
                    capturedResults.insert(LegacyDemoDocScanResult.sampleResults.first!, at: 0)
                    showDocScan = false
                }
            }
            .padding(AISSpacing.xl)
            .navigationTitle("Scan Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDocScan = false
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let tokens: AISTokenSet

    var body: some View {
        HStack(spacing: AISSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tokens.actionPrimary.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(tokens.onSurface)

                Text(description)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AISSpacing.sm)
        .background(tokens.surface)
        .cornerRadius(AISRadius.sm)
    }
}

// MARK: - Demo Captured Result Card

private struct DemoCapturedResultCard: View {
    let result: LegacyDemoDocScanResult
    let tokens: AISTokenSet

    var body: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(tokens.actionPrimary.color)

                Text(result.invoiceNumber.isEmpty
                    ? "Invoice #\(result.id.uuidString.prefix(8))"
                    : "Invoice #\(result.invoiceNumber)")
                    .font(.subheadline.bold())
                    .foregroundColor(tokens.onSurface)

                Spacer()

                AISStateBadge(
                    result.status.displayName,
                    semanticState: result.status == .approved ? .completed : .warning
                )
            }

            HStack(spacing: AISSpacing.lg) {
                if !result.vendorName.isEmpty {
                    Label(result.vendorName, systemImage: "building.2")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }

                if !result.totalAmount.isEmpty {
                    Label("$\(result.totalAmount)", systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }
            }

            HStack(spacing: AISSpacing.xs) {
                Image(systemName: result.providerUsed.iconName)
                    .font(.caption2)
                    .foregroundColor(tokens.onSurfaceSecondary)

                Text("Processed with \(result.providerUsed.displayName) in \(result.processingTimeMs)ms")
                    .font(.caption2)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
        }
        .padding(AISSpacing.md)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .withAISTokens()
    }
}

struct HomeScreen_DocScanDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeScreen_DocScanDemoView()
        }
        .withAISTokens()
    }
}
#endif

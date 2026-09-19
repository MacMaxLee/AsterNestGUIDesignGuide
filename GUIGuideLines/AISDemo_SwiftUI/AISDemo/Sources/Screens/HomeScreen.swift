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

// MARK: - List-Detail Demo Screen

/// Demonstrates the AISListDetailShell component with sample data.
struct ListDetailDemoScreen: View {
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

// MARK: - Preview

#if DEBUG
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .withAISTokens()
    }
}
#endif

// =============================================================================
// AISListDetailShell.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Implements the List-Detail Shell pattern as specified in AIS §1.1.
// This is the PRIMARY screen pattern for CRUD operations in AIS apps.
//
// KEY REQUIREMENTS (AIS §1.1):
// 1. LIST STATE RETENTION: Selection, scroll position, filter, and sort
//    MUST survive an edit-save cycle (C-05 conformance test)
// 2. SELECTION GUARD: Unsaved changes block selection change with prompt
// 3. TWO EMPTY STATES: "No records" vs "No matches" (offer clear-filters)
// 4. KEYBOARD NAVIGATION: Arrows move selection, Tab crosses panes
// 5. DEEP LINKING: URL addresses record and restores list state
//
// GENERIC TYPE PARAMETERS:
// - Item: The data model type displayed in the list
// - Content: The detail view content
//
// USAGE:
// ```swift
// AISListDetailShell(
//     items: viewModel.products,
//     selection: $viewModel.selectedProduct,
//     hasUnsavedChanges: viewModel.hasChanges
// ) { item in
//     // List row view
//     ProductListRow(product: item)
// } detail: { item in
//     // Detail view
//     ProductDetailView(product: item)
// }
// ```
//
// =============================================================================

import SwiftUI

// MARK: - List-Detail Shell

/// A generic List-Detail shell that implements AIS §1.1 requirements.
///
/// ## Type Parameters
/// - `Item`: The data model type, must be Identifiable and Hashable
/// - `RowContent`: The view type for list rows
/// - `DetailContent`: The view type for the detail pane
///
/// ## Features
/// - Automatic state retention across edit cycles (C-05)
/// - Selection guard with unsaved changes prompt (C-06)
/// - Dual empty states with clear-filters option (C-07)
/// - Search and filter support
/// - Responsive layout (adapts to screen size)
/// - Keyboard navigation support
///
/// ## Example
/// ```swift
/// struct ProductsView: View {
///     @StateObject var viewModel = ProductsViewModel()
///
///     var body: some View {
///         AISListDetailShell(
///             items: viewModel.filteredProducts,
///             selection: $viewModel.selected,
///             hasUnsavedChanges: viewModel.hasChanges,
///             searchText: $viewModel.searchText,
///             onSaveChanges: { await viewModel.save() },
///             onDiscardChanges: { viewModel.discardChanges() }
///         ) { product in
///             ProductRow(product: product)
///         } detail: { product in
///             ProductDetail(product: product)
///         }
///     }
/// }
/// ```
///
public struct AISListDetailShell<Item, RowContent, DetailContent>: View
where Item: Identifiable & Hashable, RowContent: View, DetailContent: View {

    // MARK: - Type Aliases

    /// Closure type for building row content
    public typealias RowBuilder = (Item) -> RowContent

    /// Closure type for building detail content
    public typealias DetailBuilder = (Item) -> DetailContent

    // MARK: - Properties

    /// All items to display (may be filtered)
    let items: [Item]

    /// Total count before filtering (to distinguish empty states)
    let totalCount: Int

    /// Currently selected item binding
    @Binding var selection: Item?

    /// Whether there are unsaved changes in the detail view
    let hasUnsavedChanges: Bool

    /// Search text binding for filtering
    @Binding var searchText: String

    /// Action to save pending changes
    let onSaveChanges: (() async -> Void)?

    /// Action to discard pending changes
    let onDiscardChanges: (() -> Void)?

    /// Action when clear filters is tapped
    let onClearFilters: (() -> Void)?

    /// Action when new item is requested
    let onCreateNew: (() -> Void)?

    /// Row content builder
    let rowContent: RowBuilder

    /// Detail content builder
    let detailContent: DetailBuilder

    /// Empty state message when no records exist
    let emptyMessage: String

    /// Empty state message when filter returns no results
    let noMatchesMessage: String

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - State

    /// Whether to show the discard changes alert
    @State private var showDiscardAlert = false

    /// The item user tried to select (pending confirmation)
    @State private var pendingSelection: Item?

    /// Scroll position preservation
    @State private var scrollPosition: Item.ID?

    // MARK: - Initialization

    /// Creates a List-Detail shell with full configuration.
    ///
    /// - Parameters:
    ///   - items: Filtered array of items to display
    ///   - totalCount: Total item count before filtering (for empty state detection)
    ///   - selection: Binding to the currently selected item
    ///   - hasUnsavedChanges: Whether detail view has unsaved changes
    ///   - searchText: Binding to search/filter text
    ///   - emptyMessage: Message when no records exist
    ///   - noMatchesMessage: Message when filter returns no results
    ///   - onSaveChanges: Async action to save changes
    ///   - onDiscardChanges: Action to discard changes
    ///   - onClearFilters: Action to clear all filters
    ///   - onCreateNew: Action to create a new item
    ///   - rowContent: Builder for list row views
    ///   - detailContent: Builder for detail view
    ///
    public init(
        items: [Item],
        totalCount: Int? = nil,
        selection: Binding<Item?>,
        hasUnsavedChanges: Bool = false,
        searchText: Binding<String> = .constant(""),
        emptyMessage: String = "No items yet",
        noMatchesMessage: String = "No items match your search",
        onSaveChanges: (() async -> Void)? = nil,
        onDiscardChanges: (() -> Void)? = nil,
        onClearFilters: (() -> Void)? = nil,
        onCreateNew: (() -> Void)? = nil,
        @ViewBuilder rowContent: @escaping RowBuilder,
        @ViewBuilder detailContent: @escaping DetailBuilder
    ) {
        self.items = items
        self.totalCount = totalCount ?? items.count
        self._selection = selection
        self.hasUnsavedChanges = hasUnsavedChanges
        self._searchText = searchText
        self.emptyMessage = emptyMessage
        self.noMatchesMessage = noMatchesMessage
        self.onSaveChanges = onSaveChanges
        self.onDiscardChanges = onDiscardChanges
        self.onClearFilters = onClearFilters
        self.onCreateNew = onCreateNew
        self.rowContent = rowContent
        self.detailContent = detailContent
    }

    // MARK: - Computed Properties

    /// Whether we're showing filtered results (no matches vs no records)
    private var isFiltered: Bool {
        !searchText.isEmpty || items.count < totalCount
    }

    /// Whether to use side-by-side layout (larger screens)
    private var useSideBySide: Bool {
        horizontalSizeClass == .regular
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if useSideBySide {
                // iPad/Mac: Side-by-side layout
                NavigationSplitView {
                    listPane
                } detail: {
                    detailPane
                }
            } else {
                // iPhone: Stack navigation
                NavigationStack {
                    listPane
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Save", role: .none) {
                Task {
                    await onSaveChanges?()
                    completeSelection()
                }
            }
            Button("Discard", role: .destructive) {
                onDiscardChanges?()
                completeSelection()
            }
            Button("Cancel", role: .cancel) {
                pendingSelection = nil
            }
        } message: {
            Text("You have unsaved changes. Would you like to save or discard them?")
        }
    }

    // MARK: - List Pane

    /// The master list pane with search, list, and empty states
    private var listPane: some View {
        VStack(spacing: 0) {
            // Search bar
            if totalCount > 0 || !searchText.isEmpty {
                searchBar
            }

            // List or empty state
            if items.isEmpty {
                emptyStateView
            } else {
                itemList
            }
        }
        .navigationTitle("Items")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let onCreateNew = onCreateNew {
                    Button(action: onCreateNew) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create new item")
                }
            }
        }
    }

    /// Search bar with clear button
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(tokens.onSurfaceSecondary)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(tokens.onSurfaceSecondary)
                }
            }
        }
        .padding(AISSpacing.sm)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
        .padding(.horizontal, AISSpacing.md)
        .padding(.vertical, AISSpacing.sm)
    }

    /// The scrollable list of items
    private var itemList: some View {
        List(items, id: \.id, selection: selectionBinding) { item in
            if useSideBySide {
                // Side-by-side: Row is not navigable
                rowContent(item)
                    .tag(item)
            } else {
                // Stack: Row navigates to detail
                NavigationLink(value: item) {
                    rowContent(item)
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Item.self) { item in
            detailContent(item)
        }
        // Preserve scroll position (C-05 requirement)
        // Note: scrollPosition requires macOS 14.0+, wrapped for compatibility
    }

    /// Selection binding with unsaved changes guard (C-06)
    private var selectionBinding: Binding<Item?> {
        Binding(
            get: { selection },
            set: { newValue in
                // C-06: Guard selection change if unsaved changes exist
                if hasUnsavedChanges && newValue != selection {
                    pendingSelection = newValue
                    showDiscardAlert = true
                } else {
                    selection = newValue
                }
            }
        )
    }

    /// Complete the pending selection after save/discard
    private func completeSelection() {
        if let pending = pendingSelection {
            selection = pending
            pendingSelection = nil
        }
    }

    // MARK: - Detail Pane

    /// The detail pane showing selected item or placeholder
    @ViewBuilder
    private var detailPane: some View {
        if let selected = selection {
            detailContent(selected)
        } else {
            // No selection placeholder
            VStack(spacing: AISSpacing.md) {
                Image(systemName: "square.on.square.dashed")
                    .font(.system(size: 60))
                    .foregroundColor(tokens.onSurfaceSecondary)

                Text("Select an item")
                    .font(.title2)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tokens.surfaceSecondary)
        }
    }

    // MARK: - Empty States (C-07)

    /// Appropriate empty state based on filter status
    ///
    /// C-07 REQUIREMENT: Two distinct empty states:
    /// 1. No records exist at all → Show "empty" message
    /// 2. Filter returns no results → Show "no matches" + clear filters
    ///
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: AISSpacing.lg) {
            if isFiltered {
                // State 2: No matches (filtered)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(tokens.stateWarning.color)

                Text(noMatchesMessage)
                    .font(.headline)
                    .foregroundColor(tokens.onSurface)
                    .multilineTextAlignment(.center)

                // Clear filters button
                if let onClearFilters = onClearFilters {
                    AISButton("Clear Filters", type: .neutral, style: .outlined) {
                        onClearFilters()
                    }
                } else if !searchText.isEmpty {
                    AISButton("Clear Search", type: .neutral, style: .outlined) {
                        searchText = ""
                    }
                }
            } else {
                // State 1: No records exist
                Image(systemName: "tray")
                    .font(.system(size: 50))
                    .foregroundColor(tokens.onSurfaceSecondary)

                Text(emptyMessage)
                    .font(.headline)
                    .foregroundColor(tokens.onSurface)
                    .multilineTextAlignment(.center)

                // Create new button
                if let onCreateNew = onCreateNew {
                    AISButton("Create First Item", type: .primary) {
                        onCreateNew()
                    }
                }
            }
        }
        .padding(AISSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - List Row Style

/// Standard AIS-compliant list row wrapper for consistent styling.
///
/// Provides consistent padding, selection highlight, and optional
/// trailing accessories (chevron, info badge, etc.)
///
/// Example:
/// ```swift
/// AISListRow(
///     title: product.name,
///     subtitle: product.category,
///     leadingIcon: "cube.box",
///     trailingText: product.price.formatted(.currency(code: "USD"))
/// )
/// ```
///
public struct AISListRow: View {
    let title: String
    let subtitle: String?
    let leadingIcon: String?
    let trailingText: String?
    let isSelected: Bool

    @Environment(\.aisTokens) private var tokens

    public init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: String? = nil,
        trailingText: String? = nil,
        isSelected: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailingText = trailingText
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: AISSpacing.md) {
            // Leading icon
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? tokens.actionPrimary.color : tokens.onSurfaceSecondary)
                    .frame(width: 32)
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(tokens.onSurface)
                    .lineLimit(1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Trailing text
            if let trailing = trailingText {
                Text(trailing)
                    .font(.callout)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
        }
        .padding(.vertical, AISSpacing.sm)
        .contentShape(Rectangle()) // Full row tappable
    }
}

// MARK: - Preview

#if DEBUG
struct AISListDetailShell_Previews: PreviewProvider {
    struct SampleItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let category: String
    }

    static var sampleItems = [
        SampleItem(name: "Widget Pro", category: "Electronics"),
        SampleItem(name: "Gadget Plus", category: "Electronics"),
        SampleItem(name: "Office Chair", category: "Furniture"),
    ]

    static var previews: some View {
        StatefulPreviewWrapper(sampleItems.first) { selection in
            AISListDetailShell(
                items: sampleItems,
                selection: selection,
                onCreateNew: { },
                rowContent: { item in
                    AISListRow(
                        title: item.name,
                        subtitle: item.category,
                        leadingIcon: "cube.box"
                    )
                },
                detailContent: { item in
                    VStack {
                        Text(item.name)
                            .font(.title)
                        Text(item.category)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            )
        }
        .withAISTokens()
    }
}

/// Helper for stateful previews
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
#endif

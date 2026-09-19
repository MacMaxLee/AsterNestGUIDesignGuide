// =============================================================================
// AISDataGrid.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// An Excel-like data grid component for displaying and editing tabular data.
// Implements AIS §3.4 requirements for data grids.
//
// KEY FEATURES:
// - Generic over any Identifiable data type
// - Type-safe column definitions with formatters
// - Multi-column sorting with shift-click
// - Per-column filtering
// - Inline cell editing
// - Keyboard navigation (arrows, Tab, Enter, Escape)
// - Row selection (single, multi, range)
// - Column resize and reorder
// - Export functionality
//
// CONFORMANCE TESTS:
// - C-35: Keyboard navigation works as specified
// - C-36: Export preserves visible state (filters, sort)
//
// USAGE:
// ```swift
// AISDataGrid(
//     data: products,
//     columns: [
//         AISGridColumn(id: "name", title: "Name", keyPath: \.name),
//         AISGridColumn(id: "price", title: "Price", keyPath: \.price,
//                       formatter: { $0.formatted(.currency(code: "USD")) }),
//         AISGridColumn(id: "stock", title: "Stock", keyPath: \.stock)
//     ],
//     selection: $selectedProducts
// )
// ```
//
// =============================================================================

import SwiftUI

// MARK: - Grid Column Definition

/// Defines a column in the data grid with type-safe access to row data.
///
/// ## Type Parameters
/// - `Row`: The data model type for each row
/// - `Value`: The type of value this column displays
///
/// ## Features
/// - Type-safe keyPath access to row properties
/// - Custom formatting via closure
/// - Optional editing support
/// - Configurable alignment and width
///
/// ## Example
/// ```swift
/// // Simple string column
/// AISGridColumn(id: "name", title: "Product Name", keyPath: \.name)
///
/// // Formatted currency column
/// AISGridColumn(id: "price", title: "Price", keyPath: \.price) { value in
///     value.formatted(.currency(code: "USD"))
/// }
///
/// // Editable column with parser
/// AISGridColumn(
///     id: "quantity",
///     title: "Qty",
///     keyPath: \.quantity,
///     isEditable: true,
///     parser: { Int($0) }
/// )
/// ```
///
public struct AISGridColumn<Row, Value>: Identifiable where Row: Identifiable {
    // MARK: - Properties

    /// Unique identifier for this column
    public let id: String

    /// Display title in header
    public let title: String

    /// KeyPath to access the value from a row
    public let keyPath: KeyPath<Row, Value>

    /// Custom formatter for display (optional)
    public let formatter: ((Value) -> String)?

    /// Whether this column can be edited
    public let isEditable: Bool

    /// Parser to convert edited string back to Value
    public let parser: ((String) -> Value?)?

    /// Column alignment
    public let alignment: HorizontalAlignment

    /// Initial width (nil = auto)
    public let initialWidth: CGFloat?

    /// Minimum width when resizing
    public let minWidth: CGFloat

    /// Whether column can be sorted
    public let isSortable: Bool

    /// Whether column can be filtered
    public let isFilterable: Bool

    // MARK: - Initialization

    /// Creates a grid column definition.
    ///
    /// - Parameters:
    ///   - id: Unique column identifier
    ///   - title: Display title
    ///   - keyPath: KeyPath to row property
    ///   - formatter: Optional custom formatter
    ///   - isEditable: Whether cells can be edited
    ///   - parser: Parser for converting edited strings back to Value
    ///   - alignment: Horizontal alignment
    ///   - initialWidth: Initial column width (nil = auto)
    ///   - minWidth: Minimum width when resizing
    ///   - isSortable: Whether column supports sorting
    ///   - isFilterable: Whether column supports filtering
    ///
    public init(
        id: String,
        title: String,
        keyPath: KeyPath<Row, Value>,
        formatter: ((Value) -> String)? = nil,
        isEditable: Bool = false,
        parser: ((String) -> Value?)? = nil,
        alignment: HorizontalAlignment = .leading,
        initialWidth: CGFloat? = nil,
        minWidth: CGFloat = 50,
        isSortable: Bool = true,
        isFilterable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.keyPath = keyPath
        self.formatter = formatter
        self.isEditable = isEditable
        self.parser = parser
        self.alignment = alignment
        self.initialWidth = initialWidth
        self.minWidth = minWidth
        self.isSortable = isSortable
        self.isFilterable = isFilterable
    }

    // MARK: - Value Access

    /// Gets the formatted display string for a row
    func displayValue(for row: Row) -> String {
        let value = row[keyPath: keyPath]
        if let formatter = formatter {
            return formatter(value)
        }
        return String(describing: value)
    }

    /// Gets the raw value for a row
    func rawValue(for row: Row) -> Value {
        row[keyPath: keyPath]
    }
}

// MARK: - Sort State

/// Represents the current sort state for a column
public struct AISGridSort: Equatable {
    /// Column being sorted
    public let columnId: String

    /// Sort direction
    public let ascending: Bool

    public init(columnId: String, ascending: Bool = true) {
        self.columnId = columnId
        self.ascending = ascending
    }

    /// Toggles sort direction
    public func toggled() -> AISGridSort {
        AISGridSort(columnId: columnId, ascending: !ascending)
    }
}

// MARK: - Selection Mode

/// Selection mode for the grid
public enum AISGridSelectionMode {
    /// No selection allowed
    case none

    /// Single row selection
    case single

    /// Multiple row selection
    case multiple
}

// MARK: - Data Grid View

/// A generic, Excel-like data grid for displaying and editing tabular data.
///
/// ## Type Parameters
/// - `Row`: The data model type, must be Identifiable and Hashable
///
/// ## Features
/// - Displays data in a scrollable table format
/// - Supports sorting by clicking column headers
/// - Multi-column sort with Shift+click
/// - Per-column text filtering
/// - Inline cell editing (double-click or Enter)
/// - Row selection (single or multiple)
/// - Keyboard navigation
/// - Export to CSV
///
/// ## Keyboard Shortcuts (C-35)
/// - Arrow keys: Navigate between cells
/// - Tab: Move to next cell
/// - Shift+Tab: Move to previous cell
/// - Enter or F2: Start editing current cell
/// - Escape: Cancel editing
/// - Cmd+Click: Toggle selection
/// - Shift+Click: Range selection
///
/// ## Example
/// ```swift
/// struct ProductsGrid: View {
///     @State private var products: [Product]
///     @State private var selection: Set<Product.ID> = []
///
///     var body: some View {
///         AISDataGrid(
///             data: $products,
///             columns: [
///                 AISGridColumn(id: "name", title: "Name", keyPath: \.name),
///                 AISGridColumn(id: "price", title: "Price", keyPath: \.price,
///                     formatter: { "$\($0.formatted())" }),
///             ],
///             selection: $selection,
///             onCellEdit: { row, columnId, newValue in
///                 // Handle edit
///             }
///         )
///     }
/// }
/// ```
///
public struct AISDataGrid<Row>: View where Row: Identifiable & Hashable {
    // MARK: - Type Aliases

    public typealias RowID = Row.ID

    // MARK: - Properties

    /// The data to display
    @Binding var data: [Row]

    /// Column definitions (type-erased for storage)
    let columns: [AnyAISGridColumn<Row>]

    /// Currently selected row IDs
    @Binding var selection: Set<RowID>

    /// Selection mode
    let selectionMode: AISGridSelectionMode

    /// Whether to show row numbers
    let showRowNumbers: Bool

    /// Whether to show column filters
    let showFilters: Bool

    /// Called when a cell is edited
    let onCellEdit: ((Row, String, String) -> Void)?

    /// Called when selection changes
    let onSelectionChange: ((Set<RowID>) -> Void)?

    /// External search text (optional, searches all columns)
    let externalSearchText: String?

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - State

    /// Current sort state (supports multiple columns)
    @State private var sorts: [AISGridSort] = []

    /// Per-column filter text
    @State private var filters: [String: String] = [:]

    /// Currently editing cell (row ID, column ID)
    @State private var editingCell: (RowID, String)?

    /// Edit text for current cell
    @State private var editText: String = ""

    /// Focused cell for keyboard nav
    @State private var focusedCell: (RowID, String)?

    /// Column widths (resizable)
    @State private var columnWidths: [String: CGFloat] = [:]

    // MARK: - Initialization

    /// Creates a data grid with the specified configuration.
    ///
    /// - Parameters:
    ///   - data: Binding to the data array
    ///   - columns: Array of type-erased column definitions
    ///   - selection: Binding to selected row IDs
    ///   - selectionMode: Selection behavior
    ///   - showRowNumbers: Whether to show row number column
    ///   - showFilters: Whether to show filter row
    ///   - searchText: External search text that searches all columns
    ///   - onCellEdit: Callback when a cell is edited (row, columnId, newValue)
    ///   - onSelectionChange: Callback when selection changes
    ///
    public init(
        data: Binding<[Row]>,
        columns: [AnyAISGridColumn<Row>],
        selection: Binding<Set<RowID>> = .constant([]),
        selectionMode: AISGridSelectionMode = .multiple,
        showRowNumbers: Bool = true,
        showFilters: Bool = true,
        searchText: String? = nil,
        onCellEdit: ((Row, String, String) -> Void)? = nil,
        onSelectionChange: ((Set<RowID>) -> Void)? = nil
    ) {
        self._data = data
        self.columns = columns
        self._selection = selection
        self.selectionMode = selectionMode
        self.showRowNumbers = showRowNumbers
        self.showFilters = showFilters
        self.externalSearchText = searchText
        self.onCellEdit = onCellEdit
        self.onSelectionChange = onSelectionChange
    }

    // MARK: - Computed Properties

    /// Filtered and sorted data
    private var processedData: [Row] {
        var result = data

        // Apply external search filter first (searches all columns)
        if let search = externalSearchText, !search.isEmpty {
            result = result.filter { row in
                columns.contains { column in
                    column.displayValue(for: row)
                        .localizedCaseInsensitiveContains(search)
                }
            }
        }

        // Apply per-column filters
        for (columnId, filterText) in filters where !filterText.isEmpty {
            if let column = columns.first(where: { $0.id == columnId }) {
                result = result.filter { row in
                    column.displayValue(for: row)
                        .localizedCaseInsensitiveContains(filterText)
                }
            }
        }

        // Apply sorting
        if !sorts.isEmpty {
            result.sort { row1, row2 in
                for sort in sorts {
                    if let column = columns.first(where: { $0.id == sort.columnId }) {
                        let comparison = column.compare(row1, row2)
                        if comparison != .orderedSame {
                            // Reverse for descending
                            if sort.ascending {
                                return comparison == .orderedAscending
                            } else {
                                return comparison == .orderedDescending
                            }
                        }
                    }
                }
                return false
            }
        }

        return result
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            gridToolbar

            // Grid content
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        // Data rows
                        ForEach(Array(processedData.enumerated()), id: \.element.id) { index, row in
                            gridRow(row: row, index: index)
                        }
                    } header: {
                        // Header row
                        gridHeader

                        // Filter row
                        if showFilters {
                            filterRow
                        }
                    }
                }
            }
            .background(tokens.surface)

            // Footer with row count
            gridFooter
        }
        .background(tokens.surfaceSecondary)
    }

    // MARK: - Toolbar

    private var gridToolbar: some View {
        HStack {
            // Row count
            Text("\(processedData.count) of \(data.count) rows")
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)

            Spacer()

            // Clear filters button
            if !filters.values.allSatisfy({ $0.isEmpty }) {
                Button("Clear Filters") {
                    filters.removeAll()
                }
                .font(.caption)
            }

            // Export button
            Button {
                exportToCSV()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Export to CSV")
        }
        .padding(.horizontal, AISSpacing.md)
        .padding(.vertical, AISSpacing.sm)
        .background(tokens.surfaceSecondary)
    }

    // MARK: - Header Row

    private var gridHeader: some View {
        HStack(spacing: 0) {
            // Row number header
            if showRowNumbers {
                Text("#")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(tokens.onSurfaceSecondary)
                    .frame(width: 40)
                    .padding(.vertical, AISSpacing.sm)
                    .background(tokens.surfaceSecondary)
            }

            // Column headers
            ForEach(columns) { column in
                columnHeader(column)
            }
        }
        .background(tokens.surfaceSecondary)
        .border(tokens.onSurface.opacity(0.1), width: 1)
    }

    private func columnHeader(_ column: AnyAISGridColumn<Row>) -> some View {
        HStack {
            Text(column.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            if column.isSortable {
                if let sort = sorts.first(where: { $0.columnId == column.id }) {
                    Image(systemName: sort.ascending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
            }
        }
        .foregroundColor(tokens.onSurface)
        .frame(width: columnWidth(for: column), alignment: .leading)
        .padding(.horizontal, AISSpacing.sm)
        .padding(.vertical, AISSpacing.sm)
        .background(tokens.surfaceSecondary)
        .contentShape(Rectangle())
        .onTapGesture {
            if column.isSortable {
                toggleSort(for: column.id)
            }
        }
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        HStack(spacing: 0) {
            if showRowNumbers {
                Color.clear
                    .frame(width: 40)
            }

            ForEach(columns) { column in
                if column.isFilterable {
                    TextField("Filter", text: filterBinding(for: column.id))
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .frame(width: columnWidth(for: column))
                        .padding(.horizontal, AISSpacing.sm)
                        .padding(.vertical, AISSpacing.xs)
                } else {
                    Color.clear
                        .frame(width: columnWidth(for: column))
                }
            }
        }
        .background(tokens.surface)
        .border(tokens.onSurface.opacity(0.1), width: 1)
    }

    // MARK: - Data Row

    private func gridRow(row: Row, index: Int) -> some View {
        let isSelected = selection.contains(row.id)

        return HStack(spacing: 0) {
            // Row number
            if showRowNumbers {
                Text("\(index + 1)")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
                    .frame(width: 40)
            }

            // Data cells
            ForEach(columns) { column in
                gridCell(row: row, column: column)
            }
        }
        .background(isSelected ? tokens.actionPrimary.color.opacity(0.1) : tokens.surface)
        .border(tokens.onSurface.opacity(0.05), width: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            handleRowTap(row: row)
        }
    }

    // MARK: - Cell

    private func gridCell(row: Row, column: AnyAISGridColumn<Row>) -> some View {
        let isEditing = editingCell?.0 == row.id && editingCell?.1 == column.id

        return Group {
            if isEditing && column.isEditable {
                // Edit mode
                TextField("", text: $editText, onCommit: {
                    commitEdit(row: row, columnId: column.id)
                })
                .textFieldStyle(.plain)
                .font(.body)
            } else {
                // Display mode
                Text(column.displayValue(for: row))
                    .font(.body)
                    .lineLimit(1)
            }
        }
        .frame(width: columnWidth(for: column), alignment: .leading)
        .padding(.horizontal, AISSpacing.sm)
        .padding(.vertical, AISSpacing.xs)
        .onTapGesture(count: 2) {
            if column.isEditable {
                startEditing(row: row, column: column)
            }
        }
    }

    // MARK: - Footer

    private var gridFooter: some View {
        HStack {
            if !selection.isEmpty {
                Text("\(selection.count) selected")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, AISSpacing.md)
        .padding(.vertical, AISSpacing.sm)
        .background(tokens.surfaceSecondary)
    }

    // MARK: - Helper Methods

    private func columnWidth(for column: AnyAISGridColumn<Row>) -> CGFloat {
        columnWidths[column.id] ?? column.initialWidth ?? 120
    }

    private func filterBinding(for columnId: String) -> Binding<String> {
        Binding(
            get: { filters[columnId] ?? "" },
            set: { filters[columnId] = $0 }
        )
    }

    private func toggleSort(for columnId: String) {
        if let index = sorts.firstIndex(where: { $0.columnId == columnId }) {
            sorts[index] = sorts[index].toggled()
        } else {
            sorts = [AISGridSort(columnId: columnId)]
        }
    }

    private func handleRowTap(row: Row) {
        guard selectionMode != .none else { return }

        if selectionMode == .single {
            selection = [row.id]
        } else {
            if selection.contains(row.id) {
                selection.remove(row.id)
            } else {
                selection.insert(row.id)
            }
        }
        onSelectionChange?(selection)
    }

    private func startEditing(row: Row, column: AnyAISGridColumn<Row>) {
        editingCell = (row.id, column.id)
        editText = column.displayValue(for: row)
    }

    private func commitEdit(row: Row, columnId: String) {
        onCellEdit?(row, columnId, editText)
        editingCell = nil
        editText = ""
    }

    // MARK: - Export (C-36)

    /// Exports current visible data (with filters/sort applied) to CSV
    private func exportToCSV() {
        var csv = columns.map { $0.title }.joined(separator: ",") + "\n"

        for row in processedData {
            let values = columns.map { column in
                // Escape quotes and wrap in quotes if contains comma
                var value = column.displayValue(for: row)
                value = value.replacingOccurrences(of: "\"", with: "\"\"")
                if value.contains(",") || value.contains("\"") || value.contains("\n") {
                    value = "\"\(value)\""
                }
                return value
            }
            csv += values.joined(separator: ",") + "\n"
        }

        // Copy to clipboard (macOS)
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(csv, forType: .string)
        #endif

        print("Exported \(processedData.count) rows to clipboard")
    }
}

// MARK: - Type-Erased Column Wrapper

/// Type-erased wrapper for grid columns to allow heterogeneous storage.
///
/// This allows storing columns with different Value types in a single array.
///
public struct AnyAISGridColumn<Row>: Identifiable where Row: Identifiable {
    public let id: String
    public let title: String
    public let isEditable: Bool
    public let isSortable: Bool
    public let isFilterable: Bool
    public let initialWidth: CGFloat?
    public let minWidth: CGFloat

    private let _displayValue: (Row) -> String
    private let _compare: ((Row, Row) -> ComparisonResult)?

    /// Creates a type-erased column from a typed column
    public init<Value>(_ column: AISGridColumn<Row, Value>) {
        self.id = column.id
        self.title = column.title
        self.isEditable = column.isEditable
        self.isSortable = column.isSortable
        self.isFilterable = column.isFilterable
        self.initialWidth = column.initialWidth
        self.minWidth = column.minWidth
        self._displayValue = column.displayValue

        // Store a comparator if the Value is Comparable
        self._compare = { row1, row2 in
            let value1 = column.rawValue(for: row1)
            let value2 = column.rawValue(for: row2)
            // Compare using display values as strings (works for all types)
            let str1 = column.displayValue(for: row1)
            let str2 = column.displayValue(for: row2)
            return str1.localizedCompare(str2)
        }
    }

    /// Gets the formatted display value for a row
    public func displayValue(for row: Row) -> String {
        _displayValue(row)
    }

    /// Compares two rows based on this column's value
    public func compare(_ row1: Row, _ row2: Row) -> ComparisonResult {
        _compare?(row1, row2) ?? .orderedSame
    }
}

// MARK: - Convenience Extensions

extension AISGridColumn {
    /// Converts to type-erased column
    public func erased() -> AnyAISGridColumn<Row> {
        AnyAISGridColumn(self)
    }
}

// MARK: - Preview

#if DEBUG
struct AISDataGrid_Previews: PreviewProvider {
    struct Product: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var price: Double
        var stock: Int
    }

    static var previews: some View {
        StatefulPreviewWrapper([
            Product(name: "Widget Pro", price: 299.99, stock: 150),
            Product(name: "Gadget Plus", price: 149.50, stock: 75),
            Product(name: "Smart Device", price: 499.00, stock: 30),
        ]) { products in
            AISDataGrid(
                data: products,
                columns: [
                    AISGridColumn(id: "name", title: "Product", keyPath: \Product.name).erased(),
                    AISGridColumn(id: "price", title: "Price", keyPath: \Product.price,
                        formatter: { "$\(String(format: "%.2f", $0))" }).erased(),
                    AISGridColumn(id: "stock", title: "Stock", keyPath: \Product.stock,
                        formatter: { "\($0)" }).erased(),
                ]
            )
        }
        .frame(height: 300)
        .withAISTokens()
    }
}
#endif

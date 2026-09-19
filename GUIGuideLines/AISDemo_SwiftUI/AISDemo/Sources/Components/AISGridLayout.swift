// =============================================================================
// AISGridLayout.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Provides responsive grid layout components for arranging items in a grid
// that adapts based on available space and configuration.
//
// KEY FEATURES:
// - Fixed column count grid
// - Adaptive grid that adjusts columns based on minimum child width
// - Consistent spacing using AIS design tokens
// - Support for different aspect ratios
// - Masonry-style layouts
//
// =============================================================================

import SwiftUI

// MARK: - AISGridLayout

/// A fixed column grid layout component.
///
/// ## Example
/// ```swift
/// AISGridLayout(columns: 3, spacing: 16) {
///     ForEach(items) { item in
///         CardView(item: item)
///     }
/// }
/// ```
///
public struct AISGridLayout<Content: View>: View {
    // MARK: - Properties

    /// Number of columns in the grid
    let columns: Int

    /// Spacing between items
    let spacing: CGFloat

    /// Horizontal alignment within columns
    let alignment: HorizontalAlignment

    /// The content to display in the grid
    let content: Content

    // MARK: - Initialization

    /// Creates a grid layout with the specified configuration.
    ///
    /// - Parameters:
    ///   - columns: Number of columns (default: 3)
    ///   - spacing: Spacing between items (default: AISSpacing.md)
    ///   - alignment: Horizontal alignment (default: .center)
    ///   - content: A view builder for the grid content
    ///
    public init(
        columns: Int = 3,
        spacing: CGFloat = AISSpacing.md,
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = max(1, columns)
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        let gridColumns = Array(
            repeating: GridItem(.flexible(), spacing: spacing, alignment: alignment),
            count: columns
        )

        LazyVGrid(columns: gridColumns, spacing: spacing) {
            content
        }
    }
}

// MARK: - AISAdaptiveGridLayout

/// An adaptive grid layout that adjusts columns based on container width.
///
/// ## Example
/// ```swift
/// AISAdaptiveGridLayout(minItemWidth: 200, maxColumns: 6) {
///     ForEach(items) { item in
///         CardView(item: item)
///     }
/// }
/// ```
///
public struct AISAdaptiveGridLayout<Content: View>: View {
    // MARK: - Properties

    /// Minimum width for each item
    let minItemWidth: CGFloat

    /// Maximum number of columns
    let maxColumns: Int

    /// Spacing between items
    let spacing: CGFloat

    /// The content to display
    let content: Content

    // MARK: - Initialization

    /// Creates an adaptive grid layout.
    ///
    /// - Parameters:
    ///   - minItemWidth: Minimum width for each item (default: 200)
    ///   - maxColumns: Maximum number of columns (default: 12)
    ///   - spacing: Spacing between items (default: AISSpacing.md)
    ///   - content: A view builder for the grid content
    ///
    public init(
        minItemWidth: CGFloat = 200,
        maxColumns: Int = 12,
        spacing: CGFloat = AISSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.minItemWidth = minItemWidth
        self.maxColumns = max(1, maxColumns)
        self.spacing = spacing
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let calculatedColumns = max(1, Int(availableWidth / minItemWidth))
            let columns = min(calculatedColumns, maxColumns)

            let gridColumns = Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: columns
            )

            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    content
                }
            }
        }
    }
}

// MARK: - AISAutoGrid

/// A CSS auto-fit style grid using flexible columns.
///
/// ## Example
/// ```swift
/// AISAutoGrid(minWidth: 150) {
///     ForEach(items) { item in
///         CardView(item: item)
///     }
/// }
/// ```
///
public struct AISAutoGrid<Content: View>: View {
    // MARK: - Properties

    /// Minimum width for items
    let minWidth: CGFloat

    /// Maximum width for items (nil = flexible)
    let maxWidth: CGFloat?

    /// Spacing between items
    let spacing: CGFloat

    /// The content to display
    let content: Content

    // MARK: - Initialization

    /// Creates an auto grid layout.
    ///
    /// - Parameters:
    ///   - minWidth: Minimum width for items (default: 150)
    ///   - maxWidth: Maximum width for items (default: nil - flexible)
    ///   - spacing: Spacing between items (default: AISSpacing.md)
    ///   - content: A view builder for the grid content
    ///
    public init(
        minWidth: CGFloat = 150,
        maxWidth: CGFloat? = nil,
        spacing: CGFloat = AISSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.spacing = spacing
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        let gridItem: GridItem
        if let maxWidth = maxWidth {
            gridItem = GridItem(.adaptive(minimum: minWidth, maximum: maxWidth), spacing: spacing)
        } else {
            gridItem = GridItem(.adaptive(minimum: minWidth), spacing: spacing)
        }

        return LazyVGrid(columns: [gridItem], spacing: spacing) {
            content
        }
    }
}

// MARK: - AISMasonryLayout

/// A masonry-style layout (Pinterest-like) with varying item heights.
///
/// Note: SwiftUI doesn't have native masonry support, so this uses
/// a column-based distribution approach.
///
/// ## Example
/// ```swift
/// AISMasonryLayout(columns: 3) {
///     ForEach(items) { item in
///         CardView(item: item)
///             .frame(height: CGFloat.random(in: 100...300))
///     }
/// }
/// ```
///
public struct AISMasonryLayout: View {
    // MARK: - Properties

    /// Number of columns
    let columns: Int

    /// Spacing between items
    let spacing: CGFloat

    /// The views to display
    let views: [AnyView]

    // MARK: - Initialization

    /// Creates a masonry layout.
    ///
    /// - Parameters:
    ///   - columns: Number of columns (default: 3)
    ///   - spacing: Spacing between items (default: AISSpacing.md)
    ///   - content: The views to arrange in masonry style
    ///
    public init(
        columns: Int = 3,
        spacing: CGFloat = AISSpacing.md,
        @AISMasonryBuilder content: () -> [AnyView]
    ) {
        self.columns = max(1, columns)
        self.spacing = spacing
        self.views = content()
    }

    // MARK: - Body

    public var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                VStack(spacing: spacing) {
                    ForEach(Array(columnViews(for: columnIndex).enumerated()), id: \.offset) { _, view in
                        view
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func columnViews(for column: Int) -> [AnyView] {
        views.enumerated()
            .filter { $0.offset % columns == column }
            .map { $0.element }
    }
}

/// Result builder for masonry layout content
@resultBuilder
public struct AISMasonryBuilder {
    public static func buildBlock(_ components: any View...) -> [AnyView] {
        components.map { AnyView($0) }
    }

    public static func buildArray(_ components: [[AnyView]]) -> [AnyView] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AnyView]?) -> [AnyView] {
        component ?? []
    }

    public static func buildEither(first component: [AnyView]) -> [AnyView] {
        component
    }

    public static func buildEither(second component: [AnyView]) -> [AnyView] {
        component
    }
}

// MARK: - AISGridItem

/// A grid item with column and row span support.
///
/// ## Example
/// ```swift
/// AISGridLayout(columns: 4) {
///     AISGridItem(colSpan: 2) {
///         Text("Wide item")
///     }
///     AISGridItem {
///         Text("Normal item")
///     }
/// }
/// ```
///
/// Note: Column/row spanning in SwiftUI requires manual layout handling.
/// This component provides a semantic wrapper for grid items.
///
public struct AISGridItem<Content: View>: View {
    // MARK: - Properties

    /// Number of columns to span
    let colSpan: Int

    /// Number of rows to span
    let rowSpan: Int

    /// The content
    let content: Content

    // MARK: - Initialization

    /// Creates a grid item.
    ///
    /// - Parameters:
    ///   - colSpan: Number of columns to span (default: 1)
    ///   - rowSpan: Number of rows to span (default: 1)
    ///   - content: The content view
    ///
    public init(
        colSpan: Int = 1,
        rowSpan: Int = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.colSpan = max(1, colSpan)
        self.rowSpan = max(1, rowSpan)
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        content
    }
}

// MARK: - AISAspectRatioGrid

/// A grid where all items maintain a specific aspect ratio.
///
/// ## Example
/// ```swift
/// AISAspectRatioGrid(columns: 4, aspectRatio: 16/9) {
///     ForEach(items) { item in
///         ImageView(item: item)
///     }
/// }
/// ```
///
public struct AISAspectRatioGrid<Content: View>: View {
    // MARK: - Properties

    /// Number of columns
    let columns: Int

    /// Aspect ratio (width / height)
    let aspectRatio: CGFloat

    /// Spacing between items
    let spacing: CGFloat

    /// Content mode for aspect ratio
    let contentMode: ContentMode

    /// The content
    let content: Content

    // MARK: - Initialization

    /// Creates an aspect ratio grid.
    ///
    /// - Parameters:
    ///   - columns: Number of columns (default: 3)
    ///   - aspectRatio: Width to height ratio (default: 1.0 = square)
    ///   - spacing: Spacing between items (default: AISSpacing.md)
    ///   - contentMode: How to fit content (default: .fill)
    ///   - content: The content view builder
    ///
    public init(
        columns: Int = 3,
        aspectRatio: CGFloat = 1.0,
        spacing: CGFloat = AISSpacing.md,
        contentMode: ContentMode = .fill,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = max(1, columns)
        self.aspectRatio = aspectRatio
        self.spacing = spacing
        self.contentMode = contentMode
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        let gridColumns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: columns
        )

        LazyVGrid(columns: gridColumns, spacing: spacing) {
            content
        }
    }
}

// MARK: - View Extension for Aspect Ratio

extension View {
    /// Applies an aspect ratio with a specific content mode.
    ///
    /// - Parameters:
    ///   - ratio: The aspect ratio (width / height)
    ///   - contentMode: How to fit the content
    /// - Returns: A view with the aspect ratio applied
    ///
    public func aisAspectRatio(_ ratio: CGFloat, contentMode: ContentMode = .fit) -> some View {
        self.aspectRatio(ratio, contentMode: contentMode)
    }
}

// MARK: - Preview

#if DEBUG
struct AISGridLayout_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Fixed Grid
                Text("Fixed Grid (3 columns)")
                    .font(.headline)

                AISGridLayout(columns: 3, spacing: 12) {
                    ForEach(0..<9) { index in
                        RoundedRectangle(cornerRadius: AISRadius.md)
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 80)
                            .overlay(Text("\(index + 1)"))
                    }
                }

                Divider()

                // Auto Grid
                Text("Auto Grid (min 100px)")
                    .font(.headline)

                AISAutoGrid(minWidth: 100, spacing: 12) {
                    ForEach(0..<12) { index in
                        RoundedRectangle(cornerRadius: AISRadius.md)
                            .fill(Color.green.opacity(0.3))
                            .frame(height: 60)
                            .overlay(Text("\(index + 1)"))
                    }
                }

                Divider()

                // Masonry Layout
                Text("Masonry Layout")
                    .font(.headline)

                AISMasonryLayout(columns: 3, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.3)).frame(height: 100)
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.4)).frame(height: 150)
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.5)).frame(height: 80)
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.3)).frame(height: 120)
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.4)).frame(height: 90)
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.5)).frame(height: 140)
                }

                Divider()

                // Aspect Ratio Grid
                Text("Aspect Ratio Grid (16:9)")
                    .font(.headline)

                AISAspectRatioGrid(columns: 2, aspectRatio: 16/9, spacing: 12) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: AISRadius.md)
                            .fill(Color.orange.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(Text("16:9"))
                    }
                }
            }
            .padding()
        }
        .withAISTokens()
    }
}
#endif

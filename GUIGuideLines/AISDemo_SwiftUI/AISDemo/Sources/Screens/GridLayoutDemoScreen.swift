// =============================================================================
// GridLayoutDemoScreen.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Demo
// =============================================================================

import SwiftUI

struct GridLayoutDemoScreen: View {
    @Environment(\.aisTokens) private var tokens
    @State private var selectedColumns = 3

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // Fixed Grid Demo
                fixedGridSection

                Divider()

                // Auto Grid Demo
                autoGridSection

                Divider()

                // Adaptive Grid Demo
                adaptiveGridSection

                Divider()

                // Aspect Ratio Grid Demo
                aspectRatioGridSection

                Divider()

                // Masonry Layout Demo
                masonrySection

                Divider()

                // Real World Example
                galleryExample
            }
            .padding()
        }
        .background(tokens.surfaceSecondary)
        .navigationTitle("Grid Layout")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("Grid Layout")
                .font(.largeTitle.bold())
                .foregroundColor(tokens.onSurface)

            Text("Responsive grid layout components for arranging items. Supports fixed columns, adaptive layouts, masonry grids, and aspect ratio preservation.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    // MARK: - Fixed Grid Section

    private var fixedGridSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Fixed Column Grid")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("Basic grid with configurable number of columns.")
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)

            // Column selector
            HStack(spacing: AISSpacing.md) {
                Text("Columns:")
                    .foregroundColor(tokens.onSurfaceSecondary)

                ForEach([2, 3, 4, 5], id: \.self) { count in
                    Button(action: { selectedColumns = count }) {
                        Text("\(count)")
                            .font(.body.weight(.medium))
                            .foregroundColor(selectedColumns == count ? tokens.actionPrimary.onColor : tokens.onSurface)
                            .padding(.horizontal, AISSpacing.md)
                            .padding(.vertical, AISSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AISRadius.sm)
                                    .fill(selectedColumns == count ? tokens.actionPrimary.color : tokens.surface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Grid
            AISGridLayout(columns: selectedColumns, spacing: AISSpacing.md) {
                ForEach(0..<8, id: \.self) { index in
                    DemoCard(title: "Item \(index + 1)")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(tokens.surface)
            )
        }
    }

    // MARK: - Auto Grid Section

    private var autoGridSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Auto Grid")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("Uses SwiftUI's adaptive grid. Items automatically fit based on minimum width (120px).")
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISAutoGrid(minWidth: 120, spacing: AISSpacing.md) {
                ForEach(0..<12, id: \.self) { index in
                    DemoCard(title: "\(index + 1)", compact: true)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(tokens.surface)
            )
        }
    }

    // MARK: - Adaptive Grid Section

    private var adaptiveGridSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Adaptive Grid")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("Adjusts columns based on container width. Minimum item width: 150px, max 4 columns.")
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISAdaptiveGridLayout(minItemWidth: 150, maxColumns: 4, spacing: AISSpacing.md) {
                ForEach(0..<8, id: \.self) { index in
                    DemoCard(title: "Card \(index + 1)")
                }
            }
            .frame(height: 300)
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(tokens.surface)
            )
        }
    }

    // MARK: - Aspect Ratio Grid Section

    private var aspectRatioGridSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Aspect Ratio Grid")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("All items maintain 16:9 aspect ratio.")
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISAspectRatioGrid(columns: 3, aspectRatio: 16/9, spacing: AISSpacing.md) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: AISRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: Double(index) / 6.0, saturation: 0.6, brightness: 0.8),
                                    Color(hue: Double(index) / 6.0 + 0.1, saturation: 0.5, brightness: 0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            Text("16:9")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(tokens.surface)
            )
        }
    }

    // MARK: - Masonry Section

    private var masonrySection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Masonry Layout")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("Pinterest-style layout with varying item heights.")
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISMasonryLayout(columns: 3, spacing: AISSpacing.md) {
                MasonryCard(height: 120, color: .blue)
                MasonryCard(height: 180, color: .purple)
                MasonryCard(height: 100, color: .green)
                MasonryCard(height: 150, color: .orange)
                MasonryCard(height: 90, color: .pink)
                MasonryCard(height: 200, color: .teal)
                MasonryCard(height: 110, color: .indigo)
                MasonryCard(height: 160, color: .cyan)
                MasonryCard(height: 130, color: .mint)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(tokens.surface)
            )
        }
    }

    // MARK: - Gallery Example

    private var galleryExample: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            Text("Real World: Image Gallery")
                .font(.headline)
                .foregroundColor(tokens.onSurface)

            Text("Example of a responsive photo gallery with hover effects.")
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISAutoGrid(minWidth: 180, spacing: AISSpacing.md) {
                ForEach(0..<6, id: \.self) { index in
                    GalleryCard(index: index)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .fill(tokens.surface)
            )
        }
    }
}

// MARK: - Demo Card

private struct DemoCard: View {
    @Environment(\.aisTokens) private var tokens
    let title: String
    var compact: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: AISRadius.md)
            .fill(tokens.surfaceSecondary)
            .frame(height: compact ? 60 : 80)
            .overlay(
                Text(title)
                    .font(compact ? .caption : .body)
                    .fontWeight(.medium)
                    .foregroundColor(tokens.onSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .stroke(tokens.onSurface.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Masonry Card

private struct MasonryCard: View {
    let height: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: AISRadius.md)
            .fill(color.opacity(0.3))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - Gallery Card

private struct GalleryCard: View {
    @Environment(\.aisTokens) private var tokens
    @State private var isHovered = false
    let index: Int

    var body: some View {
        VStack(spacing: 0) {
            // Image placeholder
            RoundedRectangle(cornerRadius: AISRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: Double(index) * 0.15, saturation: 0.3, brightness: 0.9),
                            Color(hue: Double(index) * 0.15 + 0.1, saturation: 0.2, brightness: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Photo \(index + 1)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(tokens.onSurface)

                Text("Gallery item")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AISSpacing.sm)
            .background(tokens.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: AISRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .stroke(tokens.onSurface.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#if DEBUG
struct GridLayoutDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GridLayoutDemoScreen()
        }
        .withAISTokens()
    }
}
#endif

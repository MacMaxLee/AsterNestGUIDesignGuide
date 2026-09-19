// =============================================================================
// StateBadgeDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates the AISStateBadge component with all semantic states,
// styles, sizes, and progress indicators.
//
// =============================================================================

import SwiftUI

struct StateBadgeDemoScreen: View {
    // MARK: - State

    @State private var currentProgress: AISSemanticState = .pending

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // All Semantic States
                semanticStatesSection

                // Badge Styles
                badgeStylesSection

                // Badge Sizes
                badgeSizesSection

                // Progress Indicator
                progressIndicatorSection

                // Real-World Examples
                realWorldSection
            }
            .padding(AISSpacing.lg)
        }
        .navigationTitle("State Badges")
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("AIS State Badges")
                .font(.title2.bold())

            Text("Visual indicators for record/item states. Each semantic state maps to appropriate colors and icons for consistent communication.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private var semanticStatesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Semantic States", description: "All available state types")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AISSpacing.md) {
                ForEach(AISSemanticState.allCases, id: \.self) { state in
                    VStack(spacing: AISSpacing.sm) {
                        AISStateBadge(state)
                        Text(state.label)
                            .font(.caption)
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tokens.surfaceSecondary)
                    .cornerRadius(AISRadius.md)
                }
            }
        }
    }

    private var badgeStylesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Badge Styles", description: "Different visual treatments")

            VStack(spacing: AISSpacing.md) {
                styleRow("Standard", style: .standard)
                styleRow("Pill", style: .pill)
                styleRow("Outlined", style: .outlined)
                styleRow("Compact", style: .compact)
                styleRow("Dot", style: .dot)
            }
        }
    }

    private var badgeSizesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Badge Sizes", description: "Size variants for different contexts")

            HStack(spacing: AISSpacing.xl) {
                VStack(spacing: AISSpacing.sm) {
                    Text("Small").font(.caption)
                    AISStateBadge(.active, size: .small)
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Medium").font(.caption)
                    AISStateBadge(.active, size: .medium)
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Large").font(.caption)
                    AISStateBadge(.active, size: .large)
                }
            }
        }
    }

    private var progressIndicatorSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("State Progress", description: "Multi-step progress tracking")

            // Interactive progress demo
            VStack(spacing: AISSpacing.md) {
                AISStateProgress(
                    states: [.draft, .pending, .active, .completed],
                    currentState: currentProgress
                )

                // Progress controls
                HStack(spacing: AISSpacing.sm) {
                    ForEach([AISSemanticState.draft, .pending, .active, .completed], id: \.self) { state in
                        AISButton(
                            state.label,
                            type: currentProgress == state ? .primary : .neutral,
                            style: currentProgress == state ? .filled : .outlined,
                            size: .small
                        ) {
                            withAnimation {
                                currentProgress = state
                            }
                        }
                    }
                }
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
        }
    }

    private var realWorldSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Real-World Examples", description: "Common usage patterns")

            // Order status example
            VStack(alignment: .leading, spacing: AISSpacing.md) {
                Text("Order List").font(.subheadline.bold())

                VStack(spacing: AISSpacing.sm) {
                    orderRow(id: "ORD-001", customer: "John Doe", state: .completed, amount: 125.00)
                    orderRow(id: "ORD-002", customer: "Jane Smith", state: .active, amount: 89.99)
                    orderRow(id: "ORD-003", customer: "Bob Wilson", state: .pending, amount: 299.00)
                    orderRow(id: "ORD-004", customer: "Alice Brown", state: .error, amount: 45.50)
                    orderRow(id: "ORD-005", customer: "Charlie Davis", state: .draft, amount: 0.00)
                }
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)

            // Task board example
            VStack(alignment: .leading, spacing: AISSpacing.md) {
                Text("Task Board with Badges").font(.subheadline.bold())

                HStack(alignment: .top, spacing: AISSpacing.md) {
                    taskColumn(title: "To Do", state: .draft, tasks: ["Design mockups", "Write specs"])
                    taskColumn(title: "In Progress", state: .active, tasks: ["API integration", "Unit tests"])
                    taskColumn(title: "Review", state: .pending, tasks: ["Code review"])
                    taskColumn(title: "Done", state: .completed, tasks: ["Setup project", "Database schema"])
                }
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)

            // State Legend
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("State Legend").font(.subheadline.bold())
                AISStateLegend(states: [.draft, .pending, .active, .completed, .error, .archived])
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
        }
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

    private func styleRow(_ title: String, style: AISStateBadgeStyle) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)

            HStack(spacing: AISSpacing.sm) {
                AISStateBadge(.active, style: style)
                AISStateBadge(.pending, style: style)
                AISStateBadge(.error, style: style)
            }

            Spacer()
        }
        .padding()
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }

    private func orderRow(
        id: String,
        customer: String,
        state: AISSemanticState,
        amount: Double
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(id)
                    .font(.subheadline.bold())
                Text(customer)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }

            Spacer()

            Text(String(format: "$%.2f", amount))
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISStateBadge(state, style: .pill, size: .small)
        }
        .padding(AISSpacing.sm)
        .background(tokens.surface)
        .cornerRadius(AISRadius.sm)
    }

    private func taskColumn(
        title: String,
        state: AISSemanticState,
        tasks: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                Spacer()
                AISStateBadge(state, style: .dot)
            }

            ForEach(tasks, id: \.self) { task in
                Text(task)
                    .font(.caption)
                    .padding(AISSpacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(tokens.surface)
                    .cornerRadius(AISRadius.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AISSpacing.sm)
        .background(tokens.surface.opacity(0.5))
        .cornerRadius(AISRadius.sm)
    }
}

// MARK: - Preview

#if DEBUG
struct StateBadgeDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StateBadgeDemoScreen()
        }
        .withAISTokens()
    }
}
#endif

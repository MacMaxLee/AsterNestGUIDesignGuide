// =============================================================================
// ValueComponentDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates the AISValueComponent with various numeric types, formats,
// and annotation requirements. Shows C-04 conformance for required annotations.
//
// =============================================================================

import SwiftUI

struct ValueComponentDemoScreen: View {
    // MARK: - State

    @State private var selectedExample = 0

    // Editable value states
    @State private var budgetAmount: Double = 50000.0
    @State private var percentageValue: Double = 75.0
    @State private var quantityValue: Double = 100.0

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Sample Data

    private let sampleValue: Double = 1234.56
    private let percentValue: Double = 0.75
    private let currencyValue: Double = 9999.99

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // Editable Input Section (NEW)
                editableInputSection

                // Value States Section
                valueStatesSection

                // Format Types Section
                formatTypesSection

                // Annotations Section
                annotationsSection

                // Comparison Section
                comparisonSection

                // Alignment Section
                alignmentSection

                // Real-World Examples
                realWorldSection
            }
            .padding(AISSpacing.lg)
        }
        .navigationTitle("Value Components")
    }

    // MARK: - Sections

    private var editableInputSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Editable Value Inputs", description: "AISValueInput allows users to enter and edit numeric values")

            VStack(spacing: AISSpacing.lg) {
                // Currency input
                AISValueInput(
                    value: $budgetAmount,
                    format: .currency(code: "USD"),
                    annotations: [
                        .period("FY 2024"),
                        .basis("Annual budget")
                    ],
                    label: "Budget Amount",
                    placeholder: "Enter budget amount",
                    onValueChange: { newValue in
                        print("Budget changed to: \(newValue)")
                    }
                )

                // Percentage input with validation
                AISValueInput(
                    value: $percentageValue,
                    format: .percentage,
                    annotations: [
                        .custom(label: "Range", value: "0-100%")
                    ],
                    label: "Completion Rate",
                    placeholder: "Enter percentage",
                    validation: { value in
                        if value < 0 { return "Value cannot be negative" }
                        if value > 100 { return "Value cannot exceed 100%" }
                        return nil
                    }
                )

                // Quantity with integer format
                AISValueInput(
                    value: $quantityValue,
                    format: .integer,
                    annotations: [
                        .unit("units"),
                        .source("Inventory system")
                    ],
                    label: "Stock Quantity",
                    placeholder: "Enter quantity"
                )

                // Display current values
                GroupBox("Current Values") {
                    VStack(alignment: .leading, spacing: AISSpacing.sm) {
                        HStack {
                            Text("Budget:")
                            Spacer()
                            Text(String(format: "$%.2f", budgetAmount))
                                .fontWeight(.medium)
                        }
                        HStack {
                            Text("Completion:")
                            Spacer()
                            Text(String(format: "%.0f%%", percentageValue))
                                .fontWeight(.medium)
                        }
                        HStack {
                            Text("Quantity:")
                            Spacer()
                            Text(String(format: "%.0f units", quantityValue))
                                .fontWeight(.medium)
                        }
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("AIS Value Components")
                .font(.title2.bold())

            Text("Numeric values must always include annotations per AIS C-04. This prevents misinterpretation of data by providing context.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private var valueStatesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Value States", description: "Available, unavailable, and loading states")

            HStack(spacing: AISSpacing.xl) {
                VStack(spacing: AISSpacing.sm) {
                    Text("Available").font(.caption)
                    AISValueComponent(
                        valueState: .available(sampleValue),
                        format: .decimal(places: 2),
                        annotations: [.unit("kg")]
                    )
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Unavailable").font(.caption)
                    AISValueComponent<Double>(
                        valueState: .unavailable,
                        format: .decimal(places: 2),
                        annotations: [.unit("kg")]
                    )
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Loading").font(.caption)
                    AISValueComponent<Double>(
                        valueState: .loading,
                        format: .decimal(places: 2),
                        annotations: [.unit("kg")]
                    )
                }
            }
        }
    }

    private var formatTypesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Format Types", description: "Different numeric formatting options")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AISSpacing.md) {
                formatExample("Integer", value: 12345, format: .integer)
                formatExample("Decimal (2)", value: 12345.678, format: .decimal(places: 2))
                formatExample("Currency", value: 1234.56, format: .currency(code: "USD"))
                formatExample("Percentage", value: 0.75, format: .percentage)
                formatExample("Scientific", value: 0.00000123, format: .scientific)
                formatExample("Compact", value: 1500000, format: .compact)
            }
        }
    }

    private var annotationsSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Required Annotations (C-04)", description: "Values MUST have context annotations")

            VStack(alignment: .leading, spacing: AISSpacing.md) {
                // Unit annotation
                annotationExample(
                    "Unit Annotation",
                    description: "Physical unit of measurement",
                    value: 25.5,
                    format: .decimal(places: 1),
                    annotations: [.unit("°C")]
                )

                // Label annotation
                annotationExample(
                    "Label Annotation",
                    description: "What the value represents",
                    value: 1234,
                    format: .integer,
                    annotations: [.label("Total Items")]
                )

                // Period annotation
                annotationExample(
                    "Period Annotation",
                    description: "Time period context",
                    value: 50000,
                    format: .currency(code: "USD"),
                    annotations: [.period("Q3 2024")]
                )

                // Source annotation
                annotationExample(
                    "Source Annotation",
                    description: "Where the data came from",
                    value: 87.5,
                    format: .percentage,
                    annotations: [.source("Survey Results")]
                )

                // Multiple annotations
                annotationExample(
                    "Multiple Annotations",
                    description: "Combining multiple context pieces",
                    value: 2500000,
                    format: .currency(code: "USD"),
                    annotations: [
                        .label("Revenue"),
                        .period("FY 2024"),
                        .source("Financial Report")
                    ]
                )
            }
        }
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Value Comparisons", description: "Showing change and trend indicators")

            HStack(spacing: AISSpacing.xl) {
                VStack(spacing: AISSpacing.sm) {
                    Text("Positive Change").font(.caption)
                    AISValueComponent(
                        valueState: .available(15.5),
                        format: .percentage,
                        annotations: [.label("Growth")],
                        comparison: .init(
                            previousValue: 12.0,
                            showPercentageChange: true,
                            showAbsoluteChange: false
                        )
                    )
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Negative Change").font(.caption)
                    AISValueComponent(
                        valueState: .available(8.2),
                        format: .percentage,
                        annotations: [.label("Rate")],
                        comparison: .init(
                            previousValue: 10.5,
                            showPercentageChange: true,
                            showAbsoluteChange: false
                        )
                    )
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("No Change").font(.caption)
                    AISValueComponent(
                        valueState: .available(50.0),
                        format: .integer,
                        annotations: [.unit("units")],
                        comparison: .init(
                            previousValue: 50.0,
                            showPercentageChange: true,
                            showAbsoluteChange: false
                        )
                    )
                }
            }
        }
    }

    private var alignmentSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Text Alignment", description: "Value alignment options")

            HStack(spacing: AISSpacing.xl) {
                VStack(spacing: AISSpacing.sm) {
                    Text("Leading").font(.caption)
                    AISValueComponent(
                        valueState: .available(1234.56),
                        format: .decimal(places: 2),
                        annotations: [.unit("km")],
                        alignment: .leading
                    )
                    .frame(width: 120)
                    .background(tokens.surfaceSecondary)
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Center").font(.caption)
                    AISValueComponent(
                        valueState: .available(1234.56),
                        format: .decimal(places: 2),
                        annotations: [.unit("km")],
                        alignment: .center
                    )
                    .frame(width: 120)
                    .background(tokens.surfaceSecondary)
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Trailing").font(.caption)
                    AISValueComponent(
                        valueState: .available(1234.56),
                        format: .decimal(places: 2),
                        annotations: [.unit("km")],
                        alignment: .trailing
                    )
                    .frame(width: 120)
                    .background(tokens.surfaceSecondary)
                }
            }
        }
    }

    private var realWorldSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Real-World Examples", description: "Common business use cases")

            // Dashboard KPI Card
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                Text("Dashboard KPI Card").font(.subheadline.bold())

                HStack(spacing: AISSpacing.lg) {
                    kpiCard(
                        title: "Total Revenue",
                        value: 2_500_000,
                        format: .currency(code: "USD"),
                        period: "Q3 2024",
                        previousValue: 2_200_000
                    )

                    kpiCard(
                        title: "Active Users",
                        value: 15_234,
                        format: .compact,
                        period: "This Month",
                        previousValue: 14_500
                    )

                    kpiCard(
                        title: "Conversion Rate",
                        value: 0.0325,
                        format: .percentage,
                        period: "Last 30 Days",
                        previousValue: 0.0310
                    )
                }
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

    private func formatExample(_ title: String, value: Double, format: AISValueFormat) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text(title)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISValueComponent(
                valueState: .available(value),
                format: format,
                annotations: [.label(title)]
            )
        }
        .padding()
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.sm)
    }

    private func annotationExample(
        _ title: String,
        description: String,
        value: Double,
        format: AISValueFormat,
        annotations: [AISValueAnnotation]
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }

            Spacer()

            AISValueComponent(
                valueState: .available(value),
                format: format,
                annotations: annotations
            )
        }
        .padding()
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.sm)
    }

    private func kpiCard(
        title: String,
        value: Double,
        format: AISValueFormat,
        period: String,
        previousValue: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text(title)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)

            AISValueComponent(
                valueState: .available(value),
                format: format,
                annotations: [.period(period)],
                size: .large,
                comparison: .init(
                    previousValue: previousValue,
                    showPercentageChange: true,
                    showAbsoluteChange: false
                )
            )
        }
        .padding()
        .background(tokens.surface)
        .cornerRadius(AISRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct ValueComponentDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ValueComponentDemoScreen()
        }
        .withAISTokens()
    }
}
#endif

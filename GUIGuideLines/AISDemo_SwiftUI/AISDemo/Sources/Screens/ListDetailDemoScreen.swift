// =============================================================================
// ListDetailDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates the AISListDetailShell component for master-detail patterns
// with state retention (C-05).
//
// =============================================================================

import SwiftUI

// MARK: - Demo Data

struct DemoItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let status: AISSemanticState
    let date: String
    let amount: Double
}

// MARK: - List Detail Demo Screen

struct ListDetailDemoScreen: View {
    @Environment(\.aisTokens) private var tokens
    @State private var selectedItem: DemoItem?
    @State private var searchText = ""

    private let demoItems: [DemoItem] = [
        DemoItem(id: "1", title: "Invoice #2024-001", subtitle: "Acme Corp", status: .completed, date: "Mar 15, 2024", amount: 1250.00),
        DemoItem(id: "2", title: "Invoice #2024-002", subtitle: "TechSupply Inc", status: .pending, date: "Mar 18, 2024", amount: 3875.50),
        DemoItem(id: "3", title: "Invoice #2024-003", subtitle: "Global Services", status: .warning, date: "Mar 20, 2024", amount: 750.25),
        DemoItem(id: "4", title: "Invoice #2024-004", subtitle: "Office Depot", status: .active, date: "Mar 22, 2024", amount: 425.00),
        DemoItem(id: "5", title: "Invoice #2024-005", subtitle: "Cloud Hosting Co", status: .draft, date: "Mar 25, 2024", amount: 2100.00),
        DemoItem(id: "6", title: "Invoice #2024-006", subtitle: "Marketing Agency", status: .completed, date: "Mar 28, 2024", amount: 5500.00),
        DemoItem(id: "7", title: "Invoice #2024-007", subtitle: "Legal Associates", status: .pending, date: "Mar 30, 2024", amount: 8750.00),
        DemoItem(id: "8", title: "Invoice #2024-008", subtitle: "Consulting Group", status: .error, date: "Apr 1, 2024", amount: 3200.00),
    ]

    private var filteredItems: [DemoItem] {
        if searchText.isEmpty {
            return demoItems
        }
        return demoItems.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            masterPane
        } detail: {
            detailPane
        }
        .navigationTitle("List-Detail Shell")
    }

    // MARK: - Master Pane

    private var masterPane: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(tokens.onSurfaceSecondary))

                TextField("Search invoices...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(tokens.onSurfaceSecondary))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AISSpacing.sm)
            .background(Color(tokens.surfaceSecondary))
            .cornerRadius(AISRadius.sm)
            .padding(AISSpacing.md)

            // List
            List(filteredItems, selection: $selectedItem) { item in
                itemRow(item)
                    .tag(item)
            }
            .listStyle(.plain)
        }
        .background(Color(tokens.surface))
    }

    private func itemRow(_ item: DemoItem) -> some View {
        HStack(spacing: AISSpacing.md) {
            VStack(alignment: .leading, spacing: AISSpacing.xs) {
                HStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(tokens.onSurface))

                    Spacer()

                    AISStateBadge(item.status, size: .small)
                }

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(Color(tokens.onSurfaceSecondary))

                HStack {
                    Text(item.date)
                        .font(.caption2)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))

                    Spacer()

                    Text(formatCurrency(item.amount))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(tokens.onSurface))
                }
            }
        }
        .padding(.vertical, AISSpacing.xs)
        .contentShape(Rectangle())
    }

    // MARK: - Detail Pane

    private var detailPane: some View {
        Group {
            if let item = selectedItem {
                itemDetailView(item)
            } else {
                emptyDetailView
            }
        }
        .background(Color(tokens.surface))
    }

    private var emptyDetailView: some View {
        VStack(spacing: AISSpacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(Color(tokens.onSurfaceSecondary).opacity(0.5))

            Text("Select an invoice")
                .font(.title2)
                .foregroundColor(Color(tokens.onSurfaceSecondary))

            Text("Choose an item from the list to view its details")
                .font(.body)
                .foregroundColor(Color(tokens.onSurfaceSecondary).opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func itemDetailView(_ item: DemoItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AISSpacing.sm) {
                    HStack {
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(tokens.onSurface))

                        Spacer()

                        AISStateBadge(item.status)
                    }

                    Text(item.subtitle)
                        .font(.headline)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                }

                Divider()

                // Details Section
                VStack(alignment: .leading, spacing: AISSpacing.md) {
                    Text("Invoice Details")
                        .font(.headline)
                        .foregroundColor(Color(tokens.onSurface))

                    detailRow("Invoice Number", item.title)
                    detailRow("Vendor", item.subtitle)
                    detailRow("Date", item.date)
                    detailRow("Amount", formatCurrency(item.amount))
                    detailRow("Status", item.status.label)
                }
                .padding(AISSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AISRadius.lg)
                        .fill(Color(tokens.surfaceSecondary))
                )

                // Actions Section
                VStack(alignment: .leading, spacing: AISSpacing.md) {
                    Text("Actions")
                        .font(.headline)
                        .foregroundColor(Color(tokens.onSurface))

                    HStack(spacing: AISSpacing.md) {
                        AISButton("Approve", type: .confirm) {}
                        AISButton("Reject", type: .destructive) {}
                        AISButton("Edit", type: .secondary) {}
                    }
                }

                // Notes Section
                VStack(alignment: .leading, spacing: AISSpacing.md) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(Color(tokens.onSurface))

                    Text("This is a demo invoice for the List-Detail Shell component. The component maintains state across selections, preserving scroll position and form state in the detail pane.")
                        .font(.body)
                        .foregroundColor(Color(tokens.onSurfaceSecondary))
                        .padding(AISSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AISRadius.md)
                                .fill(Color(tokens.surfaceSecondary))
                        )
                }

                Spacer()
            }
            .padding(AISSpacing.xl)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color(tokens.onSurfaceSecondary))
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(Color(tokens.onSurface))

            Spacer()
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ListDetailDemoScreen()
            .environment(\.aisTokens, AISTokenSet.light)
    }
}

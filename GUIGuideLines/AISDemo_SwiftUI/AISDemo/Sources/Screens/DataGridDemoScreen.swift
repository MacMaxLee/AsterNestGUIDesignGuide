// =============================================================================
// DataGridDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates the AISDataGrid component with sorting, filtering, selection,
// and inline editing capabilities. Shows C-35 and C-36 conformance.
//
// =============================================================================

import SwiftUI

// MARK: - Sample Data Model

struct Product: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var price: Double
    var quantity: Int
    var isActive: Bool
    var lastUpdated: Date

    static var samples: [Product] {
        [
            Product(id: UUID(), name: "Widget Pro", category: "Electronics", price: 29.99, quantity: 150, isActive: true, lastUpdated: Date()),
            Product(id: UUID(), name: "Gadget Plus", category: "Electronics", price: 49.99, quantity: 75, isActive: true, lastUpdated: Date().addingTimeInterval(-86400)),
            Product(id: UUID(), name: "Super Tool", category: "Tools", price: 19.99, quantity: 200, isActive: true, lastUpdated: Date().addingTimeInterval(-172800)),
            Product(id: UUID(), name: "Mega Device", category: "Electronics", price: 199.99, quantity: 25, isActive: false, lastUpdated: Date().addingTimeInterval(-259200)),
            Product(id: UUID(), name: "Basic Item", category: "Accessories", price: 9.99, quantity: 500, isActive: true, lastUpdated: Date().addingTimeInterval(-345600)),
            Product(id: UUID(), name: "Premium Kit", category: "Tools", price: 79.99, quantity: 50, isActive: true, lastUpdated: Date().addingTimeInterval(-432000)),
            Product(id: UUID(), name: "Starter Pack", category: "Accessories", price: 14.99, quantity: 300, isActive: true, lastUpdated: Date().addingTimeInterval(-518400)),
            Product(id: UUID(), name: "Pro Series", category: "Electronics", price: 299.99, quantity: 10, isActive: false, lastUpdated: Date().addingTimeInterval(-604800)),
        ]
    }
}

// MARK: - Demo Screen

struct DataGridDemoScreen: View {
    // MARK: - State

    @State private var products: [Product] = Product.samples
    @State private var selectedProducts: Set<Product.ID> = []
    @State private var searchText = ""
    @State private var showEditSheet = false
    @State private var editingProduct: Product?

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Columns Definition

    private var columns: [AnyAISGridColumn<Product>] {
        [
            AISGridColumn(
                id: "name",
                title: "Product Name",
                keyPath: \Product.name,
                initialWidth: 150
            ).erased(),

            AISGridColumn(
                id: "category",
                title: "Category",
                keyPath: \Product.category,
                initialWidth: 120
            ).erased(),

            AISGridColumn(
                id: "price",
                title: "Price",
                keyPath: \Product.price,
                formatter: { String(format: "$%.2f", $0) },
                alignment: .trailing,
                initialWidth: 100
            ).erased(),

            AISGridColumn(
                id: "quantity",
                title: "Qty",
                keyPath: \Product.quantity,
                formatter: { "\($0)" },
                alignment: .trailing,
                initialWidth: 80
            ).erased(),

            AISGridColumn(
                id: "status",
                title: "Status",
                keyPath: \Product.isActive,
                formatter: { $0 ? "Active" : "Inactive" },
                initialWidth: 100
            ).erased(),

            AISGridColumn(
                id: "updated",
                title: "Last Updated",
                keyPath: \Product.lastUpdated,
                formatter: { $0.formatted(date: .abbreviated, time: .omitted) },
                initialWidth: 120
            ).erased()
        ]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with search and actions
                headerBar

                Divider()

                // Data Grid
                AISDataGrid(
                    data: $products,
                    columns: columns,
                    selection: $selectedProducts,
                    selectionMode: .multiple,
                    showRowNumbers: true,
                    showFilters: true,
                    searchText: searchText,
                    onCellEdit: { product, columnId, newValue in
                        print("Cell edited: \(columnId) = \(newValue)")
                    },
                    onSelectionChange: { selection in
                        print("Selection changed: \(selection.count) items")
                    }
                )
            }

            // Modal overlay for editing
            if showEditSheet, let product = editingProduct {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showEditSheet = false
                        editingProduct = nil
                    }

                ProductEditSheet(
                    product: product,
                    onSave: { updated in
                        if let index = products.firstIndex(where: { $0.id == updated.id }) {
                            products[index] = updated
                        }
                        showEditSheet = false
                        editingProduct = nil
                    },
                    onCancel: {
                        showEditSheet = false
                        editingProduct = nil
                    }
                )
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 20)
            }
        }
        .navigationTitle("Data Grid")
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: AISSpacing.md) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(tokens.onSurfaceSecondary)
                TextField("Search products...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AISSpacing.sm)
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
            .frame(maxWidth: 300)

            Spacer()

            // Selection info
            if !selectedProducts.isEmpty {
                Text("\(selectedProducts.count) selected")
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)

                AISButton("Delete Selected", type: .destructive, size: .small) {
                    deleteSelected()
                }
            }

            // Add button
            AISButton("Add Product", type: .primary, size: .small) {
                addNewProduct()
            }
        }
        .padding(AISSpacing.md)
    }

    // MARK: - Actions

    private func deleteSelected() {
        products.removeAll { selectedProducts.contains($0.id) }
        selectedProducts.removeAll()
    }

    private func addNewProduct() {
        let newProduct = Product(
            id: UUID(),
            name: "New Product",
            category: "Uncategorized",
            price: 0.0,
            quantity: 0,
            isActive: true,
            lastUpdated: Date()
        )
        products.append(newProduct)
        editingProduct = newProduct
        showEditSheet = true
    }
}

// MARK: - Product Edit Sheet

struct ProductEditSheet: View {
    @State private var product: Product
    let onSave: (Product) -> Void
    let onCancel: () -> Void

    init(product: Product, onSave: @escaping (Product) -> Void, onCancel: @escaping () -> Void) {
        self._product = State(initialValue: product)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Edit Product")
                .font(.headline)
                .padding(.top, 16)

            // Form fields
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name").font(.caption).foregroundColor(.secondary)
                    TextField("Product name", text: $product.name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Category").font(.caption).foregroundColor(.secondary)
                    TextField("Category", text: $product.category)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Price").font(.caption).foregroundColor(.secondary)
                        TextField("Price", value: $product.price, format: .currency(code: "USD"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantity").font(.caption).foregroundColor(.secondary)
                        Stepper("\(product.quantity)", value: $product.quantity, in: 0...9999)
                    }
                }

                Toggle("Active", isOn: $product.isActive)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)

            Spacer()

            Divider()

            // Footer with Cancel and Save buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    var updatedProduct = product
                    updatedProduct.lastUpdated = Date()
                    onSave(updatedProduct)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 400, height: 350)
    }
}

// MARK: - Preview

#if DEBUG
struct DataGridDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DataGridDemoScreen()
        }
        .withAISTokens()
    }
}
#endif

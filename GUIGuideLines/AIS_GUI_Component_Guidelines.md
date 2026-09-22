# AIS GUI Component Guidelines

**Version 1.0 · Asternest Labs**
**Purpose:** Cross-platform component usage guide for screen designers and developers
**Platforms:** SwiftUI (macOS/iOS), Flutter (6 platforms), React/TypeScript (Web)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Theme and Token System](#2-theme-and-token-system)
3. [Component Reference](#3-component-reference)
   - [3.1 Buttons](#31-buttons)
   - [3.2 State Badges](#32-state-badges)
   - [3.3 Value Components](#33-value-components)
   - [3.4 Data Grid](#34-data-grid)
   - [3.5 Autocomplete](#35-autocomplete)
   - [3.6 Media Picker](#36-media-picker)
   - [3.7 Grid Layout](#37-grid-layout)
   - [3.8 DocScanAP (Document Scanner)](#38-docscanap-document-scanner)
4. [Data Binding Patterns](#4-data-binding-patterns)
5. [Screen Shell Patterns](#5-screen-shell-patterns)
6. [Accessibility Requirements](#6-accessibility-requirements)
7. [Adding New Components](#7-adding-new-components)

---

## 1. Overview

### 1.1 Purpose

This document provides practical guidance for using AIS GUI components when designing and building screens. Each component section includes:

- **Input/Output parameters** with types
- **Data binding patterns** for each platform
- **Code examples** with inline comments
- **Cross-platform equivalents**

### 1.2 Platform Libraries

| Platform | Library Location | Import Pattern |
|----------|------------------|----------------|
| SwiftUI | `AISDemo/Sources/Components/` | `import` individual files |
| Flutter | `ais_demo_app/lib/widgets/` | `import 'widgets/widgets.dart'` |
| React | `ais-react-components/src/components/` | `import { Component } from './components'` |

### 1.3 Quick Reference Card

| Component | SwiftUI | Flutter | React |
|-----------|---------|---------|-------|
| Theme Provider | `AISTheme` (EnvironmentObject) | `AisTheme` (ThemeExtension) | `AISProvider` (Context) |
| Button | `AISButton` | Theme + `ElevatedButton` | `AISButton` |
| State Badge | `AISStateBadge` | `AisStateBadge` | `AISStateBadge` |
| Money Value | `AISMoneyValue` | `AisMoneyValue` | `AISMoneyValue` |
| Data Grid | `AISDataGrid` | `AisDataGrid` | `AISDataGrid` |
| Autocomplete | `AISAutocomplete` | `AisAutocomplete<T>` | `AISAutocomplete<T>` |
| Media Picker | `AISMediaPicker` | `AisMediaPicker` | `AISMediaPicker` |
| Grid Layout | `AISGridLayout` | `AisGridLayout` | `AISGridLayout` |
| Doc Scanner | `DocScanAPView` | `DocScanAPWidget` | `<DocScanAP />` |

---

## 2. Theme and Token System

### 2.1 Semantic Tokens

All components use semantic tokens, never direct colors. The 9 core tokens:

| Token | Meaning | Use Case |
|-------|---------|----------|
| `actionPrimary` | Main forward action | Save, Submit, Continue |
| `actionConfirm` | Approval/acceptance | Approve, Accept, Confirm |
| `actionDestructive` | Irreversible/removing | Delete, Remove, Cancel subscription |
| `actionCaution` | Externally visible | Send, Publish, Post |
| `actionNeutral` | Non-committal | Cancel, Close, Back |
| `stateInfo` | Informational | Help text, tips |
| `stateWarning` | Needs attention | Expiring, low balance |
| `stateError` | Failed/invalid | Validation errors |
| `stateUnavailable` | Cannot compute | N/A, not applicable |

### 2.2 Theme Setup

#### SwiftUI
```swift
// AppRoot.swift
import SwiftUI

@main
struct MyApp: App {
    // Create theme as StateObject at app root
    @StateObject private var theme = AISTheme()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject theme into environment - all child views access it
                .environmentObject(theme)
        }
    }
}

// Accessing tokens in any view
struct MyView: View {
    @EnvironmentObject var theme: AISTheme

    var body: some View {
        Text("Hello")
            // Access semantic colors via theme.tokens
            .foregroundColor(theme.tokens.onSurface)
            .background(theme.tokens.surface)
    }
}
```

#### Flutter
```dart
// main.dart
import 'package:flutter/material.dart';
import 'theme/ais_theme.dart';
import 'theme/ais_tokens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // AisTheme provides light and dark theme data
      theme: AisTheme.light,          // Light theme
      darkTheme: AisTheme.dark,       // Dark theme
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MyScreen(),
    );
  }
}

// Accessing tokens in any widget
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Extension method provides typed access to tokens
    final tokens = context.aisTokens;

    return Container(
      color: tokens.surface,           // Background color
      child: Text(
        'Hello',
        style: TextStyle(
          color: tokens.onSurface,     // Text color
        ),
      ),
    );
  }
}
```

#### React
```tsx
// App.tsx
import { AISProvider } from './core/AISProvider';
import { useAISTokens } from './core/AISProvider';

function App() {
  const [darkMode, setDarkMode] = useState(false);

  return (
    // AISProvider wraps entire app, provides theme context
    <AISProvider darkMode={darkMode}>
      <MyScreen />
    </AISProvider>
  );
}

// Accessing tokens in any component
function MyScreen() {
  // Hook provides access to current theme tokens
  const tokens = useAISTokens();

  return (
    <div style={{
      backgroundColor: tokens.surface,
      color: tokens.onSurface
    }}>
      Hello
    </div>
  );
}
```

---

## 3. Component Reference

### 3.1 Buttons

Buttons use semantic intent tokens to convey meaning consistently.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `label` / `title` | String | Yes | Button text |
| `intent` | Enum | Yes | Semantic intent (primary, confirm, destructive, caution, neutral) |
| `icon` | Icon | No | Leading icon (required for some intents per AIS spec) |
| `isDisabled` | Bool | No | Disabled state |
| `isLoading` | Bool | No | Loading state with spinner |
| `onPress` / `action` | Callback | Yes | Click handler |

#### SwiftUI
```swift
// AISButton with different intents
struct ButtonExample: View {
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            // Primary action - main forward action
            AISButton("Save Changes", intent: .primary) {
                saveData()
            }

            // Destructive action - always requires confirmation icon
            AISButton("Delete Account", intent: .destructive, icon: "trash") {
                showDeleteConfirmation()
            }

            // With loading state - button shows spinner, disables interaction
            AISButton("Submit", intent: .confirm, isLoading: isLoading) {
                isLoading = true
                submitForm()
            }

            // Disabled state
            AISButton("Cannot Edit", intent: .primary, isDisabled: true) {
                // Won't be called
            }
        }
    }
}
```

#### Flutter
```dart
// Flutter uses theme-aware ElevatedButton with AIS styling
class ButtonExample extends StatefulWidget {
  @override
  State<ButtonExample> createState() => _ButtonExampleState();
}

class _ButtonExampleState extends State<ButtonExample> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      children: [
        // Primary action button
        ElevatedButton(
          // Use token colors for consistent theming
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.actionPrimary.color,
            foregroundColor: Colors.white,
          ),
          onPressed: () => saveData(),
          child: const Text('Save Changes'),
        ),

        // Destructive action with icon
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.actionDestructive.color,
            foregroundColor: Colors.white,
          ),
          // Icon is required for destructive actions
          icon: const Icon(Icons.delete),
          label: const Text('Delete Account'),
          onPressed: () => showDeleteConfirmation(),
        ),

        // Loading state button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.actionConfirm.color,
          ),
          // Disable while loading
          onPressed: _isLoading ? null : () {
            setState(() => _isLoading = true);
            submitForm();
          },
          child: _isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
```

#### React
```tsx
// AISButton component with TypeScript
function ButtonExample() {
  const [isLoading, setIsLoading] = useState(false);

  return (
    <div className="space-y-4">
      {/* Primary action */}
      <AISButton
        intent="primary"
        onClick={() => saveData()}
      >
        Save Changes
      </AISButton>

      {/* Destructive with required icon */}
      <AISButton
        intent="destructive"
        icon={<Trash size={18} />}  // Icon required for destructive
        onClick={() => showDeleteConfirmation()}
      >
        Delete Account
      </AISButton>

      {/* Loading state */}
      <AISButton
        intent="confirm"
        isLoading={isLoading}
        onClick={() => {
          setIsLoading(true);
          submitForm();
        }}
      >
        Submit
      </AISButton>

      {/* Disabled state */}
      <AISButton
        intent="primary"
        isDisabled={true}
      >
        Cannot Edit
      </AISButton>
    </div>
  );
}
```

---

### 3.2 State Badges

State badges indicate status using semantic tokens with required icons.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `state` | Enum | Yes | info, warning, error, unavailable |
| `text` / `label` | String | Yes | Badge text |
| `icon` | Icon | Auto | Auto-assigned per state (can override) |

#### SwiftUI
```swift
struct StateBadgeExample: View {
    var body: some View {
        VStack(spacing: 12) {
            // Info state - informational, non-blocking
            AISStateBadge(state: .info, text: "Draft")

            // Warning state - needs attention
            AISStateBadge(state: .warning, text: "Expires in 3 days")

            // Error state - failed or invalid
            AISStateBadge(state: .error, text: "Payment Failed")

            // Unavailable state - cannot compute, distinct from zero
            AISStateBadge(state: .unavailable, text: "N/A")
        }
    }
}
```

#### Flutter
```dart
class StateBadgeExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Each badge auto-includes appropriate icon per AIS spec
        AisStateBadge(state: AisState.info, text: 'Draft'),
        AisStateBadge(state: AisState.warning, text: 'Expires in 3 days'),
        AisStateBadge(state: AisState.error, text: 'Payment Failed'),
        // Unavailable is visually distinct from empty/zero
        AisStateBadge(state: AisState.unavailable, text: 'N/A'),
      ],
    );
  }
}
```

#### React
```tsx
function StateBadgeExample() {
  return (
    <div className="space-y-3">
      {/* Badges include icons automatically per state */}
      <AISStateBadge state="info" text="Draft" />
      <AISStateBadge state="warning" text="Expires in 3 days" />
      <AISStateBadge state="error" text="Payment Failed" />
      <AISStateBadge state="unavailable" text="N/A" />
    </div>
  );
}
```

---

### 3.3 Value Components

Value components enforce AIS §3.1 - no bare consequential values. Currency, period, and context are required.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Decimal | Yes | Numeric value (never floating point for money) |
| `currency` | String | Yes | ISO currency code (USD, EUR, etc.) |
| `annotation` | String | No | Additional context (period, basis, etc.) |
| `trend` | Enum | No | up, down, neutral - shows trend indicator |
| `redacted` | Bool | No | Shows redacted placeholder |

#### SwiftUI
```swift
struct ValueExample: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Basic monetary value - currency is REQUIRED
            AISMoneyValue(
                value: Decimal(1234.56),
                currency: "USD"
            )
            // Output: $1,234.56 USD

            // With annotation for context
            AISMoneyValue(
                value: Decimal(50000),
                currency: "USD",
                annotation: "Q3 2024 · Accrual"  // Period and basis
            )
            // Output: $50,000.00 USD
            //         Q3 2024 · Accrual

            // With trend indicator
            AISMoneyValue(
                value: Decimal(15.5),
                currency: "USD",
                trend: .up,           // Shows green up arrow
                annotation: "+12.3%"
            )

            // Redacted value - for sensitive data
            AISMoneyValue(
                value: Decimal(0),    // Value ignored when redacted
                currency: "USD",
                redacted: true
            )
            // Output: $••••••• USD
        }
    }
}
```

#### Flutter
```dart
class ValueExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Basic monetary value
        // Currency parameter is required - omitting causes compile error
        AisMoneyValue(
          value: Decimal.parse('1234.56'),  // Use Decimal, never double
          currency: 'USD',
        ),

        // With annotation showing period and basis
        AisMoneyValue(
          value: Decimal.parse('50000'),
          currency: 'USD',
          annotation: 'Q3 2024 · Accrual',
        ),

        // Trend indicator for comparisons
        AisMoneyValue(
          value: Decimal.parse('15.5'),
          currency: 'USD',
          trend: AisTrend.up,
          annotation: '+12.3%',
        ),

        // Redacted for privacy/permissions
        AisMoneyValue(
          value: Decimal.zero,
          currency: 'USD',
          redacted: true,
        ),
      ],
    );
  }
}
```

#### React
```tsx
function ValueExample() {
  return (
    <div className="text-right space-y-4">
      {/* Basic monetary value - currency required */}
      <AISMoneyValue
        value={1234.56}    // Internally uses precise decimal handling
        currency="USD"
      />

      {/* With annotation */}
      <AISMoneyValue
        value={50000}
        currency="USD"
        annotation="Q3 2024 · Accrual"
      />

      {/* Trend indicator */}
      <AISMoneyValue
        value={15.5}
        currency="USD"
        trend="up"
        annotation="+12.3%"
      />

      {/* Redacted */}
      <AISMoneyValue
        value={0}
        currency="USD"
        redacted={true}
      />
    </div>
  );
}
```

---

### 3.4 Data Grid

Excel-like data grid with sorting, filtering, pagination, and keyboard navigation.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `columns` | Array | Yes | Column definitions (key, title, type, width, sortable) |
| `data` / `rows` | Array | Yes | Row data objects |
| `onRowSelect` | Callback | No | Row selection handler |
| `onCellEdit` | Callback | No | Cell edit handler |
| `pageSize` | Int | No | Rows per page (default: 25) |
| `sortable` | Bool | No | Enable column sorting |
| `filterable` | Bool | No | Enable column filters |
| `selectionMode` | Enum | No | none, single, multiple |

#### Column Definition

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `key` / `id` | String | Yes | Data field key |
| `title` / `header` | String | Yes | Column header text |
| `type` | Enum | No | text, number, currency, date, boolean |
| `width` | Number | No | Column width |
| `sortable` | Bool | No | Column can be sorted |
| `editable` | Bool | No | Column cells are editable |

#### SwiftUI
```swift
struct DataGridExample: View {
    // Define columns with types for proper formatting
    let columns: [AISGridColumn] = [
        AISGridColumn(
            id: "name",
            title: "Customer Name",
            type: .text,
            width: 200,
            sortable: true
        ),
        AISGridColumn(
            id: "email",
            title: "Email",
            type: .text,
            width: 250
        ),
        AISGridColumn(
            id: "balance",
            title: "Balance",
            type: .currency,      // Currency type auto-formats
            width: 120,
            sortable: true
        ),
        AISGridColumn(
            id: "lastOrder",
            title: "Last Order",
            type: .date,          // Date type uses locale format
            width: 120
        ),
        AISGridColumn(
            id: "active",
            title: "Active",
            type: .boolean,       // Boolean shows checkbox
            width: 80
        ),
    ]

    // Sample data - matches column keys
    @State private var customers: [Customer] = [
        Customer(id: "1", name: "Acme Corp", email: "billing@acme.com",
                 balance: 15420.50, lastOrder: Date(), active: true),
        Customer(id: "2", name: "TechStart", email: "ap@techstart.io",
                 balance: 8750.00, lastOrder: Date(), active: true),
    ]

    @State private var selectedCustomer: Customer?
    @State private var currentPage = 1

    var body: some View {
        AISDataGrid(
            columns: columns,
            data: customers,
            // Selection binding - grid notifies on row select
            selectedItem: $selectedCustomer,
            selectionMode: .single,
            // Pagination
            currentPage: $currentPage,
            pageSize: 25,
            totalItems: customers.count,
            // Event handlers
            onSort: { columnId, direction in
                // Sort data by column
                sortCustomers(by: columnId, direction: direction)
            },
            onCellEdit: { rowId, columnId, newValue in
                // Update data on cell edit
                updateCustomer(rowId, field: columnId, value: newValue)
            }
        )
    }
}
```

#### Flutter
```dart
class DataGridExample extends StatefulWidget {
  @override
  State<DataGridExample> createState() => _DataGridExampleState();
}

class _DataGridExampleState extends State<DataGridExample> {
  // Column definitions
  final columns = [
    AisGridColumn(
      key: 'name',
      title: 'Customer Name',
      type: AisColumnType.text,
      width: 200,
      sortable: true,
    ),
    AisGridColumn(
      key: 'email',
      title: 'Email',
      type: AisColumnType.text,
      width: 250,
    ),
    AisGridColumn(
      key: 'balance',
      title: 'Balance',
      type: AisColumnType.currency,  // Auto-formats with currency symbol
      width: 120,
      sortable: true,
    ),
    AisGridColumn(
      key: 'lastOrder',
      title: 'Last Order',
      type: AisColumnType.date,
      width: 120,
    ),
    AisGridColumn(
      key: 'active',
      title: 'Active',
      type: AisColumnType.boolean,
      width: 80,
    ),
  ];

  // Data rows
  List<Map<String, dynamic>> customers = [
    {
      'id': '1',
      'name': 'Acme Corp',
      'email': 'billing@acme.com',
      'balance': 15420.50,
      'lastOrder': DateTime.now(),
      'active': true,
    },
    // ... more rows
  ];

  String? selectedId;
  int currentPage = 1;
  int pageSize = 25;

  @override
  Widget build(BuildContext context) {
    return AisDataGrid(
      columns: columns,
      rows: customers,
      // Selection
      selectedRowId: selectedId,
      selectionMode: AisSelectionMode.single,
      onRowSelected: (id) {
        setState(() => selectedId = id);
      },
      // Pagination - shows page controls at bottom
      currentPage: currentPage,
      pageSize: pageSize,
      totalRows: customers.length,
      onPageChanged: (page) {
        setState(() => currentPage = page);
      },
      onPageSizeChanged: (size) {
        setState(() {
          pageSize = size;
          currentPage = 1;  // Reset to first page
        });
      },
      // Sorting
      onSort: (columnKey, ascending) {
        setState(() {
          customers.sort((a, b) {
            final aVal = a[columnKey];
            final bVal = b[columnKey];
            return ascending
                ? Comparable.compare(aVal, bVal)
                : Comparable.compare(bVal, aVal);
          });
        });
      },
      // Cell editing
      onCellEdit: (rowId, columnKey, newValue) {
        setState(() {
          final row = customers.firstWhere((r) => r['id'] == rowId);
          row[columnKey] = newValue;
        });
      },
    );
  }
}
```

#### React
```tsx
interface Customer {
  id: string;
  name: string;
  email: string;
  balance: number;
  lastOrder: Date;
  active: boolean;
}

function DataGridExample() {
  // Column definitions with TypeScript types
  const columns: AISGridColumn[] = [
    {
      key: 'name',
      header: 'Customer Name',
      type: 'text',
      width: 200,
      sortable: true,
    },
    {
      key: 'email',
      header: 'Email',
      type: 'text',
      width: 250,
    },
    {
      key: 'balance',
      header: 'Balance',
      type: 'currency',
      width: 120,
      sortable: true,
    },
    {
      key: 'lastOrder',
      header: 'Last Order',
      type: 'date',
      width: 120,
    },
    {
      key: 'active',
      header: 'Active',
      type: 'boolean',
      width: 80,
    },
  ];

  const [customers, setCustomers] = useState<Customer[]>([
    {
      id: '1',
      name: 'Acme Corp',
      email: 'billing@acme.com',
      balance: 15420.50,
      lastOrder: new Date(),
      active: true,
    },
    // ... more rows
  ]);

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(25);

  return (
    <AISDataGrid
      columns={columns}
      data={customers}
      // Row key extractor
      rowKey={(row) => row.id}
      // Selection
      selectedRowId={selectedId}
      selectionMode="single"
      onRowSelect={(id) => setSelectedId(id)}
      // Pagination
      currentPage={currentPage}
      pageSize={pageSize}
      totalRows={customers.length}
      onPageChange={setCurrentPage}
      onPageSizeChange={(size) => {
        setPageSize(size);
        setCurrentPage(1);  // Reset on size change
      }}
      // Sorting callback
      onSort={(columnKey, direction) => {
        const sorted = [...customers].sort((a, b) => {
          const aVal = a[columnKey as keyof Customer];
          const bVal = b[columnKey as keyof Customer];
          const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
          return direction === 'asc' ? cmp : -cmp;
        });
        setCustomers(sorted);
      }}
      // Cell edit callback
      onCellEdit={(rowId, columnKey, newValue) => {
        setCustomers(prev => prev.map(row =>
          row.id === rowId ? { ...row, [columnKey]: newValue } : row
        ));
      }}
    />
  );
}
```

---

### 3.5 Autocomplete

Type-ahead search with keyboard navigation for efficient selection from large option sets.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` / `text` | String | Yes (binding) | Current input text |
| `suggestions` | Array<T> | Yes | Filtered suggestion list |
| `displayText` | (T) -> String | Yes | Extract display text from item |
| `secondaryText` | (T) -> String | No | Secondary text (subtitle) |
| `itemIcon` | (T) -> Icon | No | Icon for each suggestion |
| `onSelect` | (T) -> void | No | Selection callback |
| `selectedItem` | T? | No | Currently selected item |
| `placeholder` | String | No | Placeholder text |
| `isLoading` | Bool | No | Show loading indicator |
| `errorMessage` | String | No | Validation error message |
| `isDisabled` | Bool | No | Disabled state |
| `style` | Enum | No | standard, outlined, filled |

#### SwiftUI
```swift
struct AutocompleteExample: View {
    // Search text - bound to input field
    @State private var searchText = ""
    // Selected item - bound to selection
    @State private var selectedCountry: Country?
    // Loading state for async search
    @State private var isLoading = false

    // Sample data
    let countries = [
        Country(id: "us", name: "United States", code: "US", region: "North America"),
        Country(id: "uk", name: "United Kingdom", code: "GB", region: "Europe"),
        Country(id: "ca", name: "Canada", code: "CA", region: "North America"),
        // ... more countries
    ]

    // Computed filtered list - updates as user types
    var filteredCountries: [Country] {
        if searchText.isEmpty { return countries }
        return countries.filter { country in
            country.name.localizedCaseInsensitiveContains(searchText) ||
            country.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Country")
                .font(.subheadline)
                .foregroundColor(.secondary)

            AISAutocomplete(
                // Two-way binding for text input
                text: $searchText,
                // Two-way binding for selection
                selection: $selectedCountry,
                // Filtered suggestions
                suggestions: filteredCountries,
                // How to display each item
                displayText: { $0.name },
                // Secondary text appears below main text
                secondaryText: { "\($0.code) - \($0.region)" },
                // Icon for each item
                itemIcon: { _ in Image(systemName: "globe") },
                // Placeholder when empty
                placeholder: "Search countries...",
                // Loading state
                isLoading: isLoading,
                // Visual style
                style: .outlined
            )

            // Show selected item
            if let country = selectedCountry {
                Text("Selected: \(country.name) (\(country.code))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

#### Flutter
```dart
class AutocompleteExample extends StatefulWidget {
  @override
  State<AutocompleteExample> createState() => _AutocompleteExampleState();
}

class _AutocompleteExampleState extends State<AutocompleteExample> {
  // Controller for text input
  final _controller = TextEditingController();
  // Current filter text
  String _filterText = '';
  // Selected item
  Country? _selectedCountry;
  // Loading state
  bool _isLoading = false;

  // Sample data
  final _countries = [
    Country(id: 'us', name: 'United States', code: 'US', region: 'North America'),
    Country(id: 'uk', name: 'United Kingdom', code: 'GB', region: 'Europe'),
    Country(id: 'ca', name: 'Canada', code: 'CA', region: 'North America'),
  ];

  // Computed filtered list
  List<Country> get _filteredCountries {
    if (_filterText.isEmpty) return _countries;
    final search = _filterText.toLowerCase();
    return _countries.where((c) =>
      c.name.toLowerCase().contains(search) ||
      c.code.toLowerCase().contains(search)
    ).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.onSurface,
          ),
        ),
        const SizedBox(height: 4),

        // Generic autocomplete - type parameter is Country
        AisAutocomplete<Country>(
          controller: _controller,
          // Current filtered suggestions
          suggestions: _filteredCountries,
          // Extract display text from Country object
          displayText: (c) => c.name,
          // Optional secondary text
          secondaryText: (c) => '${c.code} - ${c.region}',
          // Icon for each suggestion
          itemIcon: (c) => Icons.public,
          // Placeholder
          placeholder: 'Search countries...',
          // Currently selected item (shows checkmark)
          selectedItem: _selectedCountry,
          // How to compare items for equality
          itemEquals: (a, b) => a.id == b.id,
          // Called when text changes - update filter
          onTextChanged: (value) {
            setState(() => _filterText = value);
          },
          // Called when user selects an item
          onSelected: (country) {
            setState(() => _selectedCountry = country);
          },
          // Visual style
          style: AisAutocompleteStyle.outlined,
          // Loading indicator
          isLoading: _isLoading,
        ),

        // Show selected
        if (_selectedCountry != null) ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${_selectedCountry!.name} (${_selectedCountry!.code})',
            style: TextStyle(
              fontSize: 12,
              color: tokens.onSurfaceSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// For simple string lists, use the convenience wrapper
class SimpleAutocompleteExample extends StatelessWidget {
  final _controller = TextEditingController();
  final _languages = ['JavaScript', 'TypeScript', 'Python', 'Java', 'Swift'];

  @override
  Widget build(BuildContext context) {
    return AisStringAutocomplete(
      controller: _controller,
      suggestions: _languages,
      placeholder: 'Select language...',
    );
  }
}
```

#### React
```tsx
interface Country {
  id: string;
  name: string;
  code: string;
  region: string;
}

function AutocompleteExample() {
  // Search text state
  const [searchText, setSearchText] = useState('');
  // Selected item state
  const [selectedCountry, setSelectedCountry] = useState<Country | null>(null);
  // Loading state
  const [isLoading, setIsLoading] = useState(false);

  // Sample data
  const countries: Country[] = [
    { id: 'us', name: 'United States', code: 'US', region: 'North America' },
    { id: 'uk', name: 'United Kingdom', code: 'GB', region: 'Europe' },
    { id: 'ca', name: 'Canada', code: 'CA', region: 'North America' },
  ];

  // Memoized filtered list - recalculates when searchText changes
  const filteredCountries = useMemo(() => {
    if (!searchText) return countries;
    const search = searchText.toLowerCase();
    return countries.filter(
      (c) =>
        c.name.toLowerCase().includes(search) ||
        c.code.toLowerCase().includes(search)
    );
  }, [searchText, countries]);

  return (
    <div className="space-y-2">
      <label className="text-sm font-medium">Country</label>

      {/* Generic autocomplete with type parameter */}
      <AISAutocomplete<Country>
        // Controlled input value
        value={searchText}
        onChange={setSearchText}
        // Filtered suggestions
        suggestions={filteredCountries}
        // Extract display text
        displayText={(c) => c.name}
        // Secondary text
        secondaryText={(c) => `${c.code} - ${c.region}`}
        // Icon component for each item
        itemIcon={() => <Globe size={18} />}
        // Placeholder
        placeholder="Search countries..."
        // Selection handler
        onSelect={setSelectedCountry}
        // Currently selected (shows checkmark)
        selectedItem={selectedCountry}
        // Key extractor for React list rendering
        itemKey={(c) => c.id}
        // Visual style
        style="outlined"
        // Loading state
        isLoading={isLoading}
        // Accessibility label
        label="Country"
      />

      {/* Show selected */}
      {selectedCountry && (
        <p className="text-sm text-gray-500">
          Selected: <strong>{selectedCountry.name}</strong> ({selectedCountry.code})
        </p>
      )}
    </div>
  );
}
```

---

### 3.6 Media Picker

File upload with drag-and-drop, type filtering, and status display.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `allowedTypes` | Array<MediaType> | No | Allowed file types (image, video, pdf, etc.) |
| `maxFileSize` | Int | No | Maximum file size in bytes |
| `maxFiles` | Int | No | Maximum number of files |
| `multiple` | Bool | No | Allow multiple selection |
| `onFilesSelected` | Callback | Yes | Files selected callback |
| `files` | Array | No | Current files for display |
| `onFileRemove` | Callback | No | File remove callback |

#### SwiftUI
```swift
struct MediaPickerExample: View {
    @State private var selectedFiles: [AISFileInfo] = []
    @State private var uploadProgress: [String: Double] = [:]

    var body: some View {
        VStack {
            AISMediaPicker(
                // Restrict to images and PDFs only
                allowedTypes: [.image, .pdf],
                // 10MB max
                maxFileSize: 10 * 1024 * 1024,
                // Allow up to 5 files
                maxFiles: 5,
                multiple: true,
                // Callback when files are selected
                onFilesSelected: { files in
                    selectedFiles.append(contentsOf: files)
                    // Start upload for each file
                    for file in files {
                        uploadFile(file)
                    }
                }
            )

            // Display selected files with status
            ForEach(selectedFiles) { file in
                AISFileInfoView(
                    file: file,
                    progress: uploadProgress[file.id],
                    onRemove: {
                        selectedFiles.removeAll { $0.id == file.id }
                    }
                )
            }
        }
    }
}
```

#### Flutter
```dart
class MediaPickerExample extends StatefulWidget {
  @override
  State<MediaPickerExample> createState() => _MediaPickerExampleState();
}

class _MediaPickerExampleState extends State<MediaPickerExample> {
  List<AisFileInfo> _selectedFiles = [];
  Map<String, double> _uploadProgress = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AisMediaPicker(
          // Restrict file types
          allowedTypes: [AisMediaType.image, AisMediaType.pdf],
          // 10MB limit
          maxFileSize: 10 * 1024 * 1024,
          // Max 5 files
          maxFiles: 5,
          multiple: true,
          // File selection callback
          onFilesSelected: (files) {
            setState(() {
              _selectedFiles.addAll(files);
            });
            // Start uploads
            for (final file in files) {
              _uploadFile(file);
            }
          },
        ),

        // Display files with progress
        ...(_selectedFiles.map((file) => AisFileInfoTile(
          file: file,
          progress: _uploadProgress[file.id],
          onRemove: () {
            setState(() {
              _selectedFiles.removeWhere((f) => f.id == file.id);
            });
          },
        ))),
      ],
    );
  }

  Future<void> _uploadFile(AisFileInfo file) async {
    // Simulated upload with progress updates
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        _uploadProgress[file.id] = i / 100;
      });
    }
  }
}
```

#### React
```tsx
function MediaPickerExample() {
  const [selectedFiles, setSelectedFiles] = useState<AISFileInfo[]>([]);
  const [uploadProgress, setUploadProgress] = useState<Record<string, number>>({});

  const handleFilesSelected = (files: AISFileInfo[]) => {
    setSelectedFiles(prev => [...prev, ...files]);
    // Start upload for each
    files.forEach(uploadFile);
  };

  const handleRemove = (fileId: string) => {
    setSelectedFiles(prev => prev.filter(f => f.id !== fileId));
  };

  return (
    <div className="space-y-4">
      <AISMediaPicker
        // Restrict to images and PDFs
        allowedTypes={['image', 'pdf']}
        // 10MB limit
        maxFileSize={10 * 1024 * 1024}
        // Max 5 files
        maxFiles={5}
        multiple={true}
        // Selection callback
        onFilesSelected={handleFilesSelected}
      />

      {/* Display files with progress */}
      {selectedFiles.map(file => (
        <AISFileInfoCard
          key={file.id}
          file={file}
          progress={uploadProgress[file.id]}
          onRemove={() => handleRemove(file.id)}
        />
      ))}
    </div>
  );
}
```

---

### 3.7 Grid Layout

Responsive grid for card-based displays with automatic column calculation.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `children` | Array<Widget> | Yes | Child elements to layout |
| `minChildWidth` | Number | No | Minimum width per child (default: 200) |
| `spacing` | Number | No | Gap between items |
| `columns` | Int | No | Fixed column count (overrides adaptive) |

#### SwiftUI
```swift
struct GridLayoutExample: View {
    let items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6"]

    var body: some View {
        // Adaptive grid - columns adjust to container width
        AISGridLayout(
            minChildWidth: 250,  // Each card at least 250pt wide
            spacing: 16          // 16pt gap between cards
        ) {
            ForEach(items, id: \.self) { item in
                CardView(title: item)
            }
        }
    }
}

// Fixed column variant
struct FixedGridExample: View {
    var body: some View {
        AISGridLayout(
            columns: 3,    // Always 3 columns
            spacing: 16
        ) {
            // ... children
        }
    }
}
```

#### Flutter
```dart
class GridLayoutExample extends StatelessWidget {
  final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5', 'Item 6'];

  @override
  Widget build(BuildContext context) {
    return AisGridLayout(
      // Minimum width per child - columns calculated automatically
      minChildWidth: 250,
      // Spacing between items
      spacing: 16,
      // Child widgets
      children: items.map((item) => CardWidget(title: item)).toList(),
    );
  }
}

// Fixed column variant
class FixedGridExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AisGridLayout(
      columns: 3,      // Override adaptive, always 3 columns
      spacing: 16,
      children: [...],
    );
  }
}
```

#### React
```tsx
function GridLayoutExample() {
  const items = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5', 'Item 6'];

  return (
    <AISGridLayout
      // Minimum child width - columns auto-calculated
      minChildWidth={250}
      // Gap between items
      spacing={16}
    >
      {items.map(item => (
        <Card key={item} title={item} />
      ))}
    </AISGridLayout>
  );
}

// Fixed columns
function FixedGridExample() {
  return (
    <AISGridLayout columns={3} spacing={16}>
      {/* children */}
    </AISGridLayout>
  );
}
```

---

### 3.8 Document Scanner (AISDocScan)

A composite component for scanning documents (invoices, receipts, bills) and extracting structured data using platform-appropriate OCR. Includes line item parsing and formatted output display.

#### Pipeline Overview

```
Media Picker → OCR → Field Extraction → Line Item Parsing → Review (Text/JSON) → Commit
```

#### Component Names

| Platform | Component | Location |
|----------|-----------|----------|
| SwiftUI | `AISDocScan` / `DocScanDemoScreen` | `AISDemo/Sources/Components/` |
| Flutter | `AisDocScan` / `AisDocumentCapture` | `ais_demo_app/lib/widgets/` |
| React | `AISDocScan` / `DocScanDemo` | `ais-react-components/src/components/` |

#### OCR Provider by Platform

| Platform | Provider | Notes |
|----------|----------|-------|
| SwiftUI (macOS/iOS) | Apple Vision (`VNRecognizeTextRequest`) | On-device, free, offline |
| Flutter (Desktop) | `flutter_ocr_native` | Uses native platform OCR |
| React (Web) | Tesseract.js | Browser-based OCR, requires npm package |

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `companyId` | String/Int64 | Yes | Company context for the scan |
| `documentType` | String | No | Document type (default: "ap_invoice") |
| `apiBaseUrl` | String/URL | Yes | Backend API base URL |
| `onCommitted` | Callback | Yes | Called when document is saved with ExtractedInvoice and ID |

#### AI Router Provider Chain

The component uses a configurable AI provider chain that falls through on failure or low confidence:

| Tier | Provider | Scope | Notes |
|---|---|---|---|
| 0 | **Self mapping** | Manual | User fills fields by hand; always available fallback |
| 1 | **Apple Intelligence / Vision** | iOS/macOS only | On-device, free, offline via `VNRecognizeTextRequest` |
| 2 | **Local Agentic AI** | All platforms | On-device model (MLX/Ollama/Gemini Nano) |
| 3 | **LLM Fallback (cloud)** | All platforms | Claude / ChatGPT / Gemini (user-selectable) |

#### Workflow Steps (UI Stepper)

1. **Capture** - AIS Media Picker for camera scan, photo library, file import, or drag-drop
2. **OCR** - On-device (Apple Vision/ML Kit) or server-side text recognition
3. **Extract** - AI Router processes raw text into structured data
4. **Review** - Config-driven form with confidence highlighting (amber < 0.6)
5. **Save** - Commit to database, link attachment to AP invoice

#### Data Contracts

**ScannedDocument** (output of AIS Media Picker):
```json
{
  "id": "int64",
  "source": "camera_scan | photo_library | file_import | drag_drop",
  "mimeType": "image/jpeg | image/png | application/pdf",
  "capturedAt": "ISO8601",
  "localUri": "string"
}
```

**ExtractedInvoice** (structured output from AI):
```json
{
  "documentId": "int64",
  "vendorNameRaw": "string",
  "vendorMatchId": "int64|null",
  "invoiceNumber": "string|null",
  "invoiceDate": "YYYY-MM-DD|null",
  "currency": "USD",
  "total": 0.00,
  "lineItems": [
    {
      "description": "string",
      "quantity": 0,
      "unitPrice": 0.00,
      "amount": 0.00,
      "suggestedGlAccountId": "int64|null",
      "confidence": 0.0
    }
  ],
  "extractionEngine": "apple_vision | local_agentic | claude | chatgpt | gemini | manual",
  "overallConfidence": 0.0,
  "requiresReview": true
}
```

#### SwiftUI
```swift
struct InvoiceScanScreen: View {
    @State private var showScanner = false

    var body: some View {
        VStack {
            Button("Scan Invoice") {
                showScanner = true
            }
            .sheet(isPresented: $showScanner) {
                // DocScanAPView handles the full workflow
                DocScanAPView(
                    companyId: currentCompanyId,
                    documentType: "ap_invoice",
                    apiBaseUrl: URL(string: "https://api.ledgernest.com")!,
                    onCommitted: { invoice, apInvoiceId in
                        // Handle successful scan and save
                        print("Invoice \(apInvoiceId) created from scan")
                        showScanner = false
                    }
                )
            }
        }
    }
}
```

#### Flutter
```dart
class InvoiceScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DocScanAPWidget(
        companyId: currentCompanyId,
        documentType: 'ap_invoice',
        apiBaseUrl: 'https://api.ledgernest.com',
        onCommitted: (ExtractedInvoice result, String apInvoiceId) {
          // Handle successful scan and save
          print('Invoice $apInvoiceId created from scan');
          Navigator.pop(context);
        },
      ),
    );
  }
}
```

#### React
```tsx
function InvoiceScanScreen() {
  const [showScanner, setShowScanner] = useState(false);

  return (
    <div>
      <button onClick={() => setShowScanner(true)}>
        Scan Invoice
      </button>

      {showScanner && (
        <DocScanAP
          companyId={currentCompanyId}
          documentType="ap_invoice"
          apiBaseUrl="https://api.ledgernest.com"
          onCommitted={(result) => {
            // Handle successful scan and save
            console.log(`Invoice ${result.apInvoiceId} created from scan`);
            setShowScanner(false);
          }}
        />
      )}
    </div>
  );
}
```

#### Line Item Parsing

The `parseLineItems` function extracts product line items from OCR text. Critical for accurate invoice processing.

**Skip Keywords** (lines containing these are excluded):
```
SUBTOTAL, TOTAL, TAX, CASH, CREDIT, DEBIT, CHANGE, BALANCE, PAYMENT,
THANK YOU, WELCOME, MEMBER, CARD, VISA, MASTERCARD, AMEX, DISCOVER,
DATE, TIME, RECEIPT, TRANSACTION, REGISTER, CASHIER, STORE, TEL, PHONE,
ADDRESS, WWW, HTTP, .COM, SAVINGS, DISCOUNT, ITEMS SOLD, AMOUNT, WHSE,
TRM, TRN, OP#, SEG#, AID, WHOLESALE, APPROVAL, REF, ENTRY, CHIP READ, COSTCO
```

**Skip Patterns** (regex patterns for non-item lines):
```
^[A-Za-z]+\s*#\s*\d+$      # Location identifiers: "Eastvale #1317"
^X{4,}                      # Masked card numbers: "XXXXXXXXXXXX8071"
^\*{4,}                     # Masked card: "****1234"
^\d{1,2}/\d{1,2}/\d{2,4}    # Date lines
^\d+\s+\w+\s+(Ave|St|Rd)    # Address lines
^AMOUNT:                    # Amount lines
```

**Costco Format Support:**
```
1806222 KOHLER SINK    <- SKU (6-7 digits) + Description
399.99 A               <- Price + Tax Code on next line
```

**Tax Code Validation:**
- Must be single uppercase letter (A-Z)
- OCR artifacts like "Ii" are rejected (not a single uppercase letter)
- If invalid, item is parsed without tax code

#### Review Output Display (Details Sheet)

After OCR processing, results are displayed in a modal/sheet with two tabs:

**Text Tab** - Formatted invoice text:
```
==========================================
INVOICE
==========================================

Invoice Number: INV-12345
Invoice Date: 07/14/2026

FROM:
COSTCO WHOLESALE #1317
5030 Hamner Ave
Eastvale, CA 91762

------------------------------------------
ITEMS:
------------------------------------------
KOHLER SINK                      1 x $  399.99 = $  399.99 A
DISPOSER                         1 x $  109.99 = $  109.99 A

------------------------------------------
SUBTOTAL:                       $509.98
TAX:                            $39.52
------------------------------------------
TOTAL DUE:                      $549.50
==========================================

Provider: Apple Vision
Processing Time: 245ms
```

**JSON Tab** - Structured output for API/database:
```json
{
  "store": {
    "name": "COSTCO WHOLESALE #1317",
    "address": "5030 Hamner Ave\nEastvale, CA 91762"
  },
  "transaction": {
    "invoiceNumber": "INV-12345",
    "date": "07/14/2026"
  },
  "items": [
    {
      "description": "KOHLER SINK",
      "quantity": 1,
      "unitPrice": 399.99,
      "amount": 399.99,
      "taxCode": "A"
    },
    {
      "description": "DISPOSER",
      "quantity": 1,
      "unitPrice": 109.99,
      "amount": 109.99,
      "taxCode": "A"
    }
  ],
  "totals": {
    "subtotal": 509.98,
    "tax": 39.52,
    "total": 549.50
  },
  "extraction": {
    "provider": "Apple Vision",
    "processingTimeMs": 245,
    "status": "review"
  }
}
```

**Required UI Elements:**
- Tab selector (Text / JSON)
- Copy to clipboard button
- Close button
- Selectable/copyable text content

#### SwiftUI Implementation

```swift
// Line item parsing function
func parseLineItems(from text: String) -> [DemoLineItem] {
    var items: [DemoLineItem] = []
    let lines = text.components(separatedBy: .newlines)

    let skipKeywords = ["SUBTOTAL", "TOTAL", "TAX", "AMOUNT", ...]
    let skipPatterns = [
        try! NSRegularExpression(pattern: "^[A-Za-z]+\\s*#\\s*\\d+$"),
        try! NSRegularExpression(pattern: "^X{4,}"),
        try! NSRegularExpression(pattern: "^AMOUNT:", options: .caseInsensitive),
    ]

    // Costco SKU pattern: 6-7 digit SKU followed by description
    let skuPattern = try! NSRegularExpression(pattern: "^(\\d{6,7})\\s+(.+)$")
    // Price line pattern with tax code validation
    let pricePattern = try! NSRegularExpression(pattern: "^-?(\\d+\\.\\d{2})\\s*([A-Z])?\\s*$")

    var i = 0
    while i < lines.count {
        let line = lines[i].trimmingCharacters(in: .whitespaces)

        // Skip empty lines and lines with skip keywords
        guard !line.isEmpty else { i += 1; continue }
        guard !skipKeywords.contains(where: { line.uppercased().contains($0) }) else { i += 1; continue }
        guard !skipPatterns.contains(where: { $0.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil }) else { i += 1; continue }

        // Costco format: SKU + description, then price on next line
        if let skuMatch = skuPattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
           i + 1 < lines.count {
            let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
            if let priceMatch = pricePattern.firstMatch(in: nextLine, range: NSRange(nextLine.startIndex..., in: nextLine)) {
                let description = String(line[Range(skuMatch.range(at: 2), in: line)!])
                let priceStr = String(nextLine[Range(priceMatch.range(at: 1), in: nextLine)!])
                let amount = Double(priceStr) ?? 0

                // Validate tax code - must be single uppercase letter
                var taxCode: String? = nil
                if priceMatch.range(at: 2).location != NSNotFound {
                    let code = String(nextLine[Range(priceMatch.range(at: 2), in: nextLine)!])
                    if code.count == 1 && code.uppercased() == code {
                        taxCode = code
                    }
                }

                items.append(DemoLineItem(
                    description: description,
                    quantity: 1,
                    unitPrice: amount,
                    amount: amount,
                    taxCode: taxCode
                ))
                i += 2
                continue
            }
        }
        i += 1
    }
    return items
}

// Details sheet with Text/JSON tabs
struct DemoOCROutputSheet: View {
    let result: DemoDocScanResult
    @State private var selectedTab = 0  // 0 = Text, 1 = JSON

    var body: some View {
        VStack {
            // Tab picker
            Picker("Output Format", selection: $selectedTab) {
                Text("Text").tag(0)
                Text("JSON").tag(1)
            }
            .pickerStyle(.segmented)

            // Content
            ScrollView {
                Text(selectedTab == 0 ? textOutput : jsonOutput)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }

            // Copy button
            Button("Copy to Clipboard") {
                NSPasteboard.general.setString(
                    selectedTab == 0 ? textOutput : jsonOutput,
                    forType: .string
                )
            }
        }
    }
}
```

#### Flutter Implementation

```dart
// Line item parsing
List<InvoiceLineItem> _parseLineItems(String text) {
  final items = <InvoiceLineItem>[];
  final lines = text.split('\n');

  final skipKeywords = ['SUBTOTAL', 'TOTAL', 'TAX', 'AMOUNT', ...];
  final skipPatterns = [
    RegExp(r'^[A-Za-z]+\s*#\s*\d+$'),
    RegExp(r'^X{4,}', caseSensitive: false),
    RegExp(r'^AMOUNT:', caseSensitive: false),
  ];

  final skuPattern = RegExp(r'^(\d{6,7})\s+(.+)$');
  final priceLinePattern = RegExp(r'^-?(\d+\.\d{2})(.*)$');

  // Helper to validate tax code
  bool isValidTaxCode(String? code) {
    if (code == null || code.isEmpty) return false;
    return RegExp(r'^[A-Z]$').hasMatch(code.trim());
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trim();
    if (line.isEmpty || skipKeywords.any((k) => line.toUpperCase().contains(k))) {
      i++; continue;
    }
    if (skipPatterns.any((p) => p.hasMatch(line))) {
      i++; continue;
    }

    // Costco format
    final skuMatch = skuPattern.firstMatch(line);
    if (skuMatch != null && i + 1 < lines.length) {
      final nextLine = lines[i + 1].trim();
      final priceMatch = priceLinePattern.firstMatch(nextLine);
      if (priceMatch != null) {
        final priceStr = priceMatch.group(1) ?? '0';
        final remainder = priceMatch.group(2)?.trim() ?? '';
        final amount = double.tryParse(priceStr) ?? 0.0;
        String? taxCode = isValidTaxCode(remainder) ? remainder : null;

        items.add(InvoiceLineItem(
          description: skuMatch.group(2)?.trim() ?? '',
          quantity: 1.0,
          unitPrice: amount,
          amount: amount,
          taxCode: taxCode,
        ));
        i += 2;
        continue;
      }
    }
    i++;
  }
  return items;
}

// Details sheet widget
class _DetailsSheet extends StatefulWidget {
  final DocScanResult doc;
  final AisTokens tokens;
  final ScrollController scrollController;

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  int _selectedTab = 0;  // 0 = Text, 1 = JSON

  String get _textOutput => '''==========================================
INVOICE
==========================================
Invoice Number: ${widget.doc.invoiceNumber.mappedValue}
...
''';

  String get _jsonOutput {
    final output = {
      'store': {'name': widget.doc.vendorName.mappedValue, ...},
      'items': widget.doc.lineItems.map((i) => {...}).toList(),
      ...
    };
    return const JsonEncoder.withIndent('  ').convert(output);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab selector
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: Text('Text', style: ...),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: Text('JSON', style: ...),
          ),
        ]),
        // Content
        Expanded(
          child: SelectableText(
            _selectedTab == 0 ? _textOutput : _jsonOutput,
            style: TextStyle(fontFamily: 'monospace'),
          ),
        ),
        // Copy button
        IconButton(
          icon: Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: _selectedTab == 0 ? _textOutput : _jsonOutput,
            ));
          },
        ),
      ],
    );
  }
}
```

#### React Implementation

```tsx
// Line item parsing
function parseLineItems(text: string): LineItem[] {
  const items: LineItem[] = [];
  const lines = text.split('\n');

  const skipKeywords = ['SUBTOTAL', 'TOTAL', 'TAX', 'AMOUNT', ...];
  const skipPatterns = [
    /^[A-Za-z]+\s*#\s*\d+$/,
    /^X{4,}/i,
    /^AMOUNT:/i,
  ];

  const skuPattern = /^(\d{6,7})\s+(.+)$/;

  // Helper to extract price and validate tax code
  const extractPriceAndTax = (text: string) => {
    const match = text.match(/^-?(\d+\.\d{2})(.*)$/);
    if (!match) return null;
    const price = parseFloat(match[1]);
    const remainder = match[2].trim();
    // Tax code must be single uppercase letter
    const taxCode = /^[A-Z]$/.test(remainder) ? remainder : undefined;
    return { price, taxCode };
  };

  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trim();
    if (!line || skipKeywords.some(k => line.toUpperCase().includes(k))) {
      i++; continue;
    }
    if (skipPatterns.some(p => p.test(line))) {
      i++; continue;
    }

    // Costco format
    const skuMatch = line.match(skuPattern);
    if (skuMatch && i + 1 < lines.length) {
      const nextLine = lines[i + 1].trim();
      const priceResult = extractPriceAndTax(nextLine);
      if (priceResult && priceResult.price > 0) {
        items.push({
          description: skuMatch[2].trim(),
          quantity: 1,
          unitPrice: priceResult.price,
          amount: priceResult.price,
          taxCode: priceResult.taxCode,
        });
        i += 2;
        continue;
      }
    }
    i++;
  }
  return items;
}

// OCR Output Modal
function OCROutputModal({ result, onClose }: Props) {
  const tokens = useAISTokens();
  const [activeTab, setActiveTab] = useState<'text' | 'json'>('text');

  const formattedText = generateFormattedText(result);
  const jsonOutput = generateJsonOutput(result);

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  return (
    <div className="modal">
      {/* Tab selector */}
      <div className="tabs">
        <button onClick={() => setActiveTab('text')}>Text</button>
        <button onClick={() => setActiveTab('json')}>JSON</button>
      </div>

      {/* Content */}
      <pre className="content">
        {activeTab === 'text' ? formattedText : jsonOutput}
      </pre>

      {/* Copy button */}
      <button onClick={() => copyToClipboard(
        activeTab === 'text' ? formattedText : jsonOutput
      )}>
        Copy to Clipboard
      </button>
    </div>
  );
}
```

#### AI Settings Component

Each platform provides an AI Settings component for configuring OCR providers:

| Platform | Component | Location |
|----------|-----------|----------|
| SwiftUI | `AISettingsDemoScreen` | `AISDemo/Sources/Screens/` |
| Flutter | `AISettingsScreen` | `ais_demo_app/lib/screens/` |
| React | `AISettingsDemo` | `ais-react-components/src/demo/demos/` |

**Features:**
- **Cloud LLM Selection:** Radio selection for Claude / ChatGPT / Gemini
- **API Key Input:** Secure text field for API key entry
- **Test Connection:** Button to verify API key validity with success/failure feedback
- **Local AI Toggle:** Enable/disable on-device AI processing
- **Provider Chain:** Visual display of fallback provider order

#### Confidence Highlighting

Fields with confidence < 0.6 are highlighted in amber (using `stateWarning` token) to indicate they require manual review. Fields with confidence >= 0.75 can be auto-approved if the mapping config allows.

---

## 4. Data Binding Patterns

### 4.1 One-Way vs Two-Way Binding

| Pattern | When to Use | SwiftUI | Flutter | React |
|---------|-------------|---------|---------|-------|
| One-way | Display only | `let value` | `final value` | `const value` |
| Two-way | Editable input | `@Binding` / `$var` | Controller + setState | `useState` + handler |
| Computed | Derived from other state | `var computed: T` | getter | `useMemo` |

### 4.2 SwiftUI Binding Patterns

```swift
struct BindingExample: View {
    // Source of truth - owned by this view
    @State private var searchText = ""
    @State private var selectedItem: Item?

    // Binding - passed down to child views
    // Child can read AND write
    var body: some View {
        VStack {
            // Pass binding with $ prefix
            SearchField(text: $searchText)

            // Pass binding for selection
            ItemList(
                items: filteredItems,
                selection: $selectedItem
            )
        }
    }

    // Computed property - derived from state
    var filteredItems: [Item] {
        items.filter { $0.name.contains(searchText) }
    }
}

// Child view receives Binding
struct SearchField: View {
    @Binding var text: String  // Can read and write parent's state

    var body: some View {
        TextField("Search", text: $text)
    }
}
```

### 4.3 Flutter Binding Patterns

```dart
class BindingExample extends StatefulWidget {
  @override
  State<BindingExample> createState() => _BindingExampleState();
}

class _BindingExampleState extends State<BindingExample> {
  // State owned by this widget
  String _searchText = '';
  Item? _selectedItem;

  // Controller for text input - manages TextField state
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to controller changes
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Computed getter
  List<Item> get filteredItems {
    return items.where((i) => i.name.contains(_searchText)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pass controller for two-way binding
        TextField(controller: _searchController),

        // Pass value and callback for "binding"
        ItemList(
          items: filteredItems,
          selectedItem: _selectedItem,
          onItemSelected: (item) {
            setState(() => _selectedItem = item);
          },
        ),
      ],
    );
  }
}
```

### 4.4 React Binding Patterns

```tsx
function BindingExample() {
  // State hooks
  const [searchText, setSearchText] = useState('');
  const [selectedItem, setSelectedItem] = useState<Item | null>(null);

  // Memoized computed value - recalculates when dependencies change
  const filteredItems = useMemo(() => {
    return items.filter(i => i.name.includes(searchText));
  }, [items, searchText]);

  return (
    <div>
      {/* Controlled input - value + onChange = two-way binding */}
      <input
        value={searchText}
        onChange={(e) => setSearchText(e.target.value)}
      />

      {/* Pass value and handler to child */}
      <ItemList
        items={filteredItems}
        selectedItem={selectedItem}
        onItemSelect={setSelectedItem}
      />
    </div>
  );
}
```

---

## 5. Screen Shell Patterns

### 5.1 List-Detail Shell

The primary screen pattern. Left: list with search/filter. Right: detail/edit form.

```
+---------------------+--------------------------------------+
| search / filter     |  record form                         |
|---------------------|                                      |
| o record 1          |  (optionally: header + child lines)  |
| * record 2   <--    |                                      |
| o record 3          |                                      |
+---------------------+--------------------------------------+
```

**Critical Rules:**
- List retains selection, scroll, filter after edit-save
- Unsaved changes block selection change
- Narrow viewports split into two routes

#### SwiftUI Implementation
```swift
struct ListDetailShell<Item: Identifiable, ListView: View, DetailView: View>: View {
    let items: [Item]
    @Binding var selection: Item?
    let hasUnsavedChanges: Bool
    let listView: (Item, Bool) -> ListView
    let detailView: (Item) -> DetailView

    @State private var showUnsavedAlert = false
    @State private var pendingSelection: Item?

    var body: some View {
        NavigationSplitView {
            // List pane
            List(items, selection: guardedSelection) { item in
                listView(item, selection?.id == item.id)
            }
        } detail: {
            // Detail pane
            if let selected = selection {
                detailView(selected)
            } else {
                Text("Select an item")
            }
        }
        .alert("Unsaved Changes", isPresented: $showUnsavedAlert) {
            Button("Discard") { commitPendingSelection() }
            Button("Cancel", role: .cancel) { }
        }
    }

    // Guard selection changes when unsaved changes exist
    var guardedSelection: Binding<Item?> {
        Binding(
            get: { selection },
            set: { newValue in
                if hasUnsavedChanges {
                    pendingSelection = newValue
                    showUnsavedAlert = true
                } else {
                    selection = newValue
                }
            }
        )
    }
}
```

### 5.2 Header-Detail with Invariant

For screens where child lines must satisfy an assertion (e.g., debits = credits).

**Critical Rules:**
- Invariant is required parameter
- Residual always visible
- Save blocked while residual != 0

```swift
struct HeaderDetailShell<Header, Line>: View {
    let header: Header
    let lines: [Line]
    let invariant: (Header, [Line]) -> Decimal  // Returns residual
    let invariantLabel: String

    var residual: Decimal {
        invariant(header, lines)
    }

    var body: some View {
        VStack {
            // Header section
            HeaderView(header: header)

            // Lines section
            LinesView(lines: lines)

            // ALWAYS visible residual
            HStack {
                Text(invariantLabel)
                Spacer()
                Text(residual.formatted())
                    .foregroundColor(residual == 0 ? .green : .red)
            }
            .padding()
            .background(residual == 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))

            // Save button - disabled when residual != 0
            Button("Save") { save() }
                .disabled(residual != 0)
        }
    }
}
```

---

## 6. Accessibility Requirements

All AIS components must meet WCAG 2.1 Level AA:

### 6.1 Required for All Components

| Requirement | Implementation |
|-------------|---------------|
| Keyboard accessible | All controls reachable via Tab, operable via Enter/Space |
| Focus visible | Clear focus indicator on interactive elements |
| Color not sole indicator | Icons paired with semantic colors |
| Labels | All controls have accessible labels |
| Contrast | 4.5:1 for text, 3:1 for UI components |

### 6.2 Platform-Specific Implementation

#### SwiftUI
```swift
Button("Save") { save() }
    .accessibilityLabel("Save changes")
    .accessibilityHint("Saves the current form data")
    .accessibilityAddTraits(.isButton)
```

#### Flutter
```dart
Semantics(
  label: 'Save changes',
  hint: 'Saves the current form data',
  button: true,
  child: ElevatedButton(
    onPressed: save,
    child: Text('Save'),
  ),
)
```

#### React
```tsx
<button
  onClick={save}
  aria-label="Save changes"
  aria-describedby="save-hint"
>
  Save
</button>
<span id="save-hint" className="sr-only">
  Saves the current form data
</span>
```

---

## 7. Adding New Components

When adding new components to the AIS library, follow these steps:

### 7.1 Design Phase

1. **Define the component purpose** - What problem does it solve?
2. **List parameters** - Input, output, bindings
3. **Define states** - Normal, loading, error, disabled, empty
4. **Identify semantic tokens** - Which AIS tokens apply?
5. **Document keyboard interaction** - How is it operated without mouse?
6. **Write accessibility requirements** - Labels, announcements, focus

### 7.2 Implementation Checklist

- [ ] Implement in all three platforms (SwiftUI, Flutter, React)
- [ ] Use semantic tokens, never direct colors
- [ ] Include required icons per token
- [ ] Support keyboard navigation
- [ ] Add accessibility labels
- [ ] Support dark mode
- [ ] Handle loading state
- [ ] Handle error state
- [ ] Handle empty state
- [ ] Handle disabled state
- [ ] Add to demo app
- [ ] Update this guidelines document
- [ ] Add conformance tests to AIS spec

### 7.3 Documentation Template

```markdown
### X.X ComponentName

Brief description of component purpose.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| param1 | Type | Yes/No | Description |

#### SwiftUI
\`\`\`swift
// Code example with comments
\`\`\`

#### Flutter
\`\`\`dart
// Code example with comments
\`\`\`

#### React
\`\`\`tsx
// Code example with comments
\`\`\`
```

---

## Appendix A: File Locations

### SwiftUI Components
```
AISDemo/Sources/
├── Components/
│   ├── AISButton.swift
│   ├── AISStateBadge.swift
│   ├── AISMoneyValue.swift
│   ├── AISDataGrid.swift
│   ├── AISAutocomplete.swift
│   ├── AISMediaPicker.swift
│   └── AISGridLayout.swift
└── Theme/
    └── AISTheme.swift
```

### Flutter Components
```
ais_demo_app/lib/
├── widgets/
│   ├── widgets.dart          # Barrel export
│   ├── ais_state_badge.dart
│   ├── ais_money_value.dart
│   ├── ais_data_grid.dart
│   ├── ais_autocomplete.dart
│   ├── ais_media_picker.dart
│   └── ais_grid_layout.dart
└── theme/
    ├── ais_theme.dart
    └── ais_tokens.dart
```

### React Components
```
ais-react-components/src/
├── components/
│   ├── index.ts              # Barrel export
│   ├── AISButton.tsx
│   ├── AISStateBadge.tsx
│   ├── AISMoneyValue.tsx
│   ├── AISDataGrid.tsx
│   ├── AISAutocomplete.tsx
│   ├── AISMediaPicker.tsx
│   └── AISGridLayout.tsx
└── core/
    └── AISProvider.tsx
```

---

## Appendix B: Cross-Reference to AIS Spec

| Component | AIS Section | Conformance Tests |
|-----------|-------------|-------------------|
| Theme/Tokens | §2 | C-01, C-02, C-03 |
| Buttons | §2.2, §2.3 | C-03 |
| State Badges | §2.2 | C-03 |
| Value Components | §3.1, §3.2 | C-04, C-19 |
| Data Grid | §3.3, §3.4 | C-35, C-36 |
| Pagination | §3.4 | C-43 to C-47 |
| Autocomplete | §3.6 | C-48 to C-50 |
| Media Picker | §3.7 | C-37 to C-41 |
| Grid Layout | §3.5 | C-42 |
| Document Scanner | §3.8 | C-51 to C-55 |

---

*AIS GUI Component Guidelines v1.0 · Asternest Labs*

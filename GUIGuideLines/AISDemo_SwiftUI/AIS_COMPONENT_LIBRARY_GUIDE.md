# AIS SwiftUI Component Library Guide

## Overview

The Asternest Interface Standard (AIS) v1.0 SwiftUI implementation is a semantic, accessible, and testable UI component library. The core philosophy is **semantic meaning over appearance** - components are chosen based on what they mean, not how they look.

---

## Quick Start

### 1. Apply AIS Tokens to Your App

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withAISTokens()  // Required for all AIS components
        }
    }
}
```

### 2. Access Tokens in Any View

```swift
struct MyView: View {
    @Environment(\.aisTokens) private var tokens

    var body: some View {
        Text("Hello")
            .foregroundColor(tokens.onSurface)
            .background(tokens.surface)
    }
}
```

---

## Design Tokens

### Spacing (8-point grid)
```swift
AISSpacing.xs   // 4pt
AISSpacing.sm   // 8pt
AISSpacing.md   // 16pt (base)
AISSpacing.lg   // 24pt
AISSpacing.xl   // 32pt
AISSpacing.xxl  // 48pt
```

### Corner Radius
```swift
AISRadius.sm    // 4pt
AISRadius.md    // 8pt
AISRadius.lg    // 12pt
AISRadius.xl    // 16pt
AISRadius.full  // 9999pt (pill shape)
```

### Semantic Colors (via tokens)
```swift
// Actions (user-initiated)
tokens.actionPrimary      // Brand-aligned primary actions
tokens.actionConfirm      // Affirmative actions (green)
tokens.actionCaution      // Reversible changes (orange)
tokens.actionDestructive  // Harmful actions (red)
tokens.actionNeutral      // Non-committal (gray)

// States (system-communicated)
tokens.stateError         // Something failed
tokens.stateWarning       // Needs attention
tokens.stateInfo          // Informational
tokens.stateUnavailable   // No data

// Surfaces
tokens.surface            // Primary background
tokens.surfaceSecondary   // Secondary background
tokens.onSurface          // Primary text
tokens.onSurfaceSecondary // Muted text
```

---

## Components

### AISButton

Semantic buttons with automatic styling based on action type.

#### Types
| Type | Use Case | Color |
|------|----------|-------|
| `.primary` | Main action on screen | Blue |
| `.confirm` | Affirmative completion | Green |
| `.caution` | Significant but reversible | Orange |
| `.destructive` | Harmful/irreversible (confirm first!) | Red |
| `.neutral` | Cancel, Close, Back | Gray |
| `.secondary` | Lower prominence alternatives | Subtle |

#### Styles
- `.filled` - Solid background (default)
- `.outlined` - Border only
- `.text` - Text only
- `.iconOnly` - Icon button

#### Sizes
- `.small` - Toolbars, compact UI
- `.medium` - Standard (default)
- `.large` - Prominent CTAs

#### Examples
```swift
// Primary action
AISButton("Save", type: .primary) {
    saveData()
}

// Destructive with custom icon
AISButton("Delete", type: .destructive, icon: "trash") {
    confirmDelete()
}

// Loading state
AISButton("Processing", type: .primary, isLoading: true) { }

// Full-width button
AISButton("Continue", type: .primary, fullWidth: true) {
    navigateNext()
}

// Outlined secondary
AISButton("Cancel", type: .neutral, style: .outlined) {
    dismiss()
}

// Icon-only button
AISButton.icon("plus", type: .primary, accessibilityLabel: "Add item") {
    addItem()
}
```

---

### AISStateBadge

Visual indicators for item lifecycle states. Always pairs color + icon for accessibility.

#### Semantic States
| State | Meaning | Color |
|-------|---------|-------|
| `.draft` | Work in progress | Gray |
| `.pending` | Awaiting action | Orange |
| `.active` | Currently live | Green |
| `.completed` | Successfully finished | Blue |
| `.archived` | Retained but inactive | Gray |
| `.error` | Error state | Red |
| `.warning` | Needs attention | Yellow |
| `.inactive` | Disabled | Gray |

#### Styles
- `.standard` - Icon + label + background
- `.compact` - Icon only (for dense lists)
- `.pill` - Capsule shape, filled
- `.outlined` - Border only
- `.dot` - Minimal circle

#### Examples
```swift
// Basic usage
AISStateBadge(.active)

// With custom label
AISStateBadge("Published", semanticState: .active, style: .pill)

// Compact for lists
AISStateBadge(.pending, style: .compact, size: .small)

// Multiple badges
AISStateBadgeGroup([.active, .pending], style: .pill)

// Progress through states
AISStateProgress(
    states: [.draft, .pending, .active, .completed],
    currentState: .pending
)
```

---

### AISValueComponent

Displays numeric values with **REQUIRED annotations** (C-04 conformance). You cannot create an uncontextualized value.

#### Value States
```swift
.available(value)  // We have data
.unavailable       // No data (NOT zero!)
.loading           // Still fetching
.error("message")  // Failed to get value
```

**Important:** `.available(0)` means "value is zero". `.unavailable` means "no data exists".

#### Formats
```swift
.currency(code: "USD")
.percentage
.decimal(places: 2)
.integer
.compact          // 1.2M, 3.4B
.scientific
```

#### Required Annotations
```swift
.label("Revenue")
.unit("kg")
.period("Q3 2024")
.source("Financial Report")
.basis("Excluding tax")
.currency("USD")
```

#### Examples
```swift
// Currency with period
AISValueComponent(
    value: 125430.50,
    format: .currency(code: "USD"),
    annotations: [
        .period("Q3 2024"),
        .basis("Gross revenue")
    ],
    label: "Revenue",
    size: .large
)

// Temperature with unit
AISValueComponent(
    value: 25.5,
    format: .decimal(places: 1),
    annotations: [.unit("°C")],
    label: "Temperature"
)

// Unavailable value (distinct from zero)
AISValueComponent<Double>(
    valueState: .unavailable,
    format: .currency(code: "USD"),
    annotations: [.period("Q3 2024")],
    label: "Revenue"
)

// With comparison
AISValueComponent(
    valueState: .available(15.5),
    format: .percentage,
    annotations: [.label("Growth")],
    comparison: .init(
        previousValue: 12.0,
        showPercentageChange: true
    )
)
```

#### Editable Input
```swift
@State private var amount: Double = 0

AISValueInput(
    value: $amount,
    format: .currency(code: "USD"),
    annotations: [.period("FY 2024")],
    label: "Budget Amount",
    placeholder: "Enter amount",
    validation: { value in
        if value < 0 { return "Cannot be negative" }
        return nil
    }
)
```

---

### AISErrorEnvelope

Wraps async operations with loading/success/error states.

#### Error Severity
- `.info` - Non-blocking informational
- `.warning` - Should be addressed
- `.error` - Operation failed
- `.critical` - System-level failure

#### Loading State
```swift
enum AISLoadingState<T> {
    case idle
    case loading
    case success(T)
    case failure(AISErrorInfo)
}
```

#### Examples
```swift
// Wrap async content
AISErrorEnvelope(
    state: viewModel.loadingState,
    onRetry: { viewModel.reload() }
) { data in
    ContentView(data: data)
}

// Standalone error view
AISErrorView(
    error: .networkError(onRetry: { reload() }),
    onRetry: { reload() }
)

// Inline form error
AISInlineError(message: "Email is required", severity: .error)

// Banner notification
AISErrorBanner(
    error: errorInfo,
    autoDismissAfter: 5.0,
    onDismiss: { showError = false }
)
```

#### Common Error Constructors
```swift
AISErrorInfo.networkError(onRetry: { }, onDismiss: { })
AISErrorInfo.loadError("Failed to load", onRetry: { })
AISErrorInfo.authError(onLogin: { })
AISErrorInfo.validationError("Invalid input", onDismiss: { })
```

---

### AISMediaPicker

File selection with complete metadata extraction.

#### File Categories
```swift
.image, .video, .audio, .pdf, .plainText, .spreadsheet, .any
```

#### File Info
Each selected file includes:
- `fileName`, `mimeType`, `fileSize`
- `checksum` (MD5 for integrity)
- `localPath`, `createdAt`, `modifiedAt`

#### Example
```swift
@State private var pickerState: AISFilePickerState = .idle

AISMediaPicker(
    state: $pickerState,
    allowedTypes: [.image, .pdf],
    allowsMultiple: true,
    maxFileSize: 10_000_000,  // 10MB
    buttonLabel: "Select Files",
    buttonType: .primary,
    onFilesSelected: { files in
        viewModel.attachFiles(files)
    }
)

// Display selected files
ForEach(selectedFiles) { file in
    AISFileInfoRow(
        file: file,
        onRemove: { remove(file) }
    )
}
```

---

### AISDataGrid

Excel-like data grid with sorting, filtering, and inline editing.

#### Keyboard Shortcuts (C-35)
- Arrow keys: Navigate cells
- Tab/Shift+Tab: Next/previous cell
- Enter/F2: Start editing
- Escape: Cancel editing
- Cmd+Click: Toggle selection
- Shift+Click: Range selection

#### Example
```swift
@State private var products: [Product]
@State private var selection: Set<Product.ID> = []

AISDataGrid(
    data: $products,
    columns: [
        AISGridColumn(
            id: "name",
            title: "Product Name",
            keyPath: \Product.name,
            initialWidth: 150
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
            isEditable: true,
            parser: { Int($0) }
        ).erased()
    ],
    selection: $selection,
    selectionMode: .multiple,
    showRowNumbers: true,
    showFilters: true,
    searchText: searchText,
    onCellEdit: { row, columnId, newValue in
        // Handle edit
    },
    onSelectionChange: { selection in
        // Handle selection
    }
)
```

---

### AISListDetailShell

Master-detail pattern for CRUD operations with state retention.

#### Conformance
- **C-05**: List state survives edit-save cycle
- **C-06**: Selection guard with unsaved changes
- **C-07**: Dual empty states (no records vs no matches)

#### Example
```swift
@State private var selection: Item?
@State private var searchText = ""

AISListDetailShell(
    items: filteredItems,
    totalCount: allItems.count,
    selection: $selection,
    hasUnsavedChanges: viewModel.hasChanges,
    searchText: $searchText,
    emptyMessage: "No items yet",
    noMatchesMessage: "No items match your search",
    onSaveChanges: { await viewModel.save() },
    onDiscardChanges: { viewModel.discardChanges() },
    onClearFilters: { searchText = "" },
    onCreateNew: { viewModel.createNew() },
    rowContent: { item in
        AISListRow(
            title: item.name,
            subtitle: item.category,
            leadingIcon: "doc",
            isSelected: selection?.id == item.id
        )
    },
    detailContent: { item in
        ItemDetailView(item: item)
    }
)
```

---

## Best Practices

### 1. Choose Semantic Types
```swift
// DO: Use semantic button type
AISButton("Delete", type: .destructive) { }

// DON'T: Style manually
Button("Delete") { }
    .foregroundColor(.red)
```

### 2. Always Annotate Values
```swift
// DO: Include context
AISValueComponent(
    value: 1234.56,
    format: .currency(code: "USD"),
    annotations: [.period("Q3 2024")]
)

// DON'T: Display raw numbers
Text("$1,234.56")
```

### 3. Handle All States
```swift
// DO: Use loading states
AISErrorEnvelope(state: viewModel.state) { data in
    ContentView(data: data)
}

// DON'T: Assume success
ContentView(data: viewModel.data!)
```

### 4. Confirm Destructive Actions
```swift
// DO: Always confirm
AISButton("Delete", type: .destructive) {
    showDeleteConfirmation = true
}

// DON'T: Delete immediately
AISButton("Delete", type: .destructive) {
    delete()  // No confirmation!
}
```

### 5. Use Consistent Spacing
```swift
// DO: Use spacing constants
VStack(spacing: AISSpacing.md) { }

// DON'T: Use arbitrary values
VStack(spacing: 17) { }
```

---

## Conformance Requirements

| Code | Requirement | Component |
|------|-------------|-----------|
| C-04 | Values require annotations | AISValueComponent |
| C-05 | List state retention | AISListDetailShell |
| C-06 | Selection guard | AISListDetailShell |
| C-07 | Dual empty states | AISListDetailShell |
| C-35 | Keyboard navigation | AISDataGrid |
| C-36 | Export preserves state | AISDataGrid |
| §2.3 | Color + icon pairing | All components |

---

## Component Selection Guide

| Need | Use |
|------|-----|
| Action button | `AISButton` |
| Status indicator | `AISStateBadge` |
| Numeric display | `AISValueComponent` |
| Numeric input | `AISValueInput` |
| Error handling | `AISErrorEnvelope` |
| File selection | `AISMediaPicker` |
| Tabular data | `AISDataGrid` |
| CRUD interface | `AISListDetailShell` |

---

## File Structure

```
AISDemo/Sources/
├── Core/
│   └── AISTokens.swift          # Design tokens, spacing, colors
├── Components/
│   ├── AISButton.swift          # Semantic buttons
│   ├── AISStateBadge.swift      # State indicators
│   ├── AISValueComponent.swift  # Numeric displays
│   ├── AISErrorEnvelope.swift   # Error handling
│   ├── AISMediaPicker.swift     # File selection
│   ├── AISDataGrid.swift        # Data tables
│   └── AISListDetailShell.swift # CRUD pattern
└── Screens/
    └── *DemoScreen.swift        # Usage examples
```

---

## Version

AIS v1.0 - SwiftUI Implementation

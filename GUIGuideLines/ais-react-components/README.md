# AIS React Components

**Asternest Interface Standard (AIS) v1.0 - React/TypeScript Implementation**

A semantic, accessible, and testable UI component library. The core philosophy is **semantic meaning over appearance** - components are chosen based on what they mean, not how they look.

## Quick Start

### Installation

```bash
npm install @asternest/ais-react-components
```

### Setup

Wrap your app with `AISProvider`:

```tsx
import { AISProvider } from '@asternest/ais-react-components';

function App() {
  return (
    <AISProvider>
      <YourApp />
    </AISProvider>
  );
}
```

### Basic Usage

```tsx
import { AISButton, AISStateBadge, useAISTokens } from '@asternest/ais-react-components';

function MyComponent() {
  const tokens = useAISTokens();

  return (
    <div style={{ color: tokens.onSurface }}>
      <AISButton actionType="primary">Save</AISButton>
      <AISButton actionType="destructive">Delete</AISButton>
      <AISStateBadge state="active" />
    </div>
  );
}
```

## Components

### AISButton

Semantic buttons with automatic styling based on action type.

```tsx
// Action types (MEANING, not appearance)
<AISButton actionType="primary">Save</AISButton>      // Main forward action
<AISButton actionType="confirm">Approve</AISButton>   // Approval, acceptance
<AISButton actionType="caution">Publish</AISButton>   // Consequential action
<AISButton actionType="destructive">Delete</AISButton> // Irreversible (confirm first!)
<AISButton actionType="neutral">Cancel</AISButton>    // Cancel, close, back

// Variants
<AISButton variant="filled">Filled</AISButton>
<AISButton variant="outlined">Outlined</AISButton>
<AISButton variant="text">Text</AISButton>

// Sizes
<AISButton size="small">Small</AISButton>
<AISButton size="medium">Medium</AISButton>
<AISButton size="large">Large</AISButton>

// States
<AISButton isLoading>Processing...</AISButton>
<AISButton disabled>Disabled</AISButton>
<AISButton fullWidth>Full Width</AISButton>
```

### AISStateBadge

Visual indicators for item lifecycle states. Always pairs color + icon for accessibility.

```tsx
// Semantic states
<AISStateBadge state="draft" />
<AISStateBadge state="pending" />
<AISStateBadge state="active" />
<AISStateBadge state="completed" />
<AISStateBadge state="error" />

// Styles
<AISStateBadge state="active" style="standard" />
<AISStateBadge state="active" style="pill" />
<AISStateBadge state="active" style="outlined" />
<AISStateBadge state="active" style="compact" />  // Icon only
<AISStateBadge state="active" style="dot" />      // Minimal

// Progress through states
<AISStateProgress
  states={['draft', 'pending', 'active', 'completed']}
  currentState="pending"
/>
```

### AISValueComponent

Displays numeric values with **REQUIRED** annotations (C-04 conformance).

**CRITICAL:** `available(0)` means "value is zero". `unavailable` means "no data exists".

```tsx
// Currency with annotations
<AISValueComponent
  valueState={{ type: 'available', value: 125430.50 }}
  format={{ type: 'currency', code: 'USD' }}
  annotations={[
    { type: 'period', text: 'Q3 2024' },
    { type: 'basis', text: 'Gross revenue' },
  ]}
  label="Revenue"
  size="large"
/>

// Unavailable value (NOT the same as zero!)
<AISValueComponent
  valueState={{ type: 'unavailable' }}
  format={{ type: 'currency', code: 'USD' }}
  annotations={[{ type: 'period', text: 'Q3 2024' }]}
  label="Revenue"
/>

// With comparison/trend
<AISValueComponent
  valueState={{ type: 'available', value: 15.5 }}
  format={{ type: 'percentage' }}
  annotations={[{ type: 'label', text: 'Growth' }]}
  comparison={{
    previousValue: 12.0,
    showPercentageChange: true,
  }}
/>
```

### AISErrorEnvelope

Wraps async operations with loading/error states.

```tsx
<AISErrorEnvelope
  state={loadingState}
  onRetry={() => refetch()}
>
  {(data) => <DataList items={data} />}
</AISErrorEnvelope>

// Inline errors
<AISInlineError message="Email is required" severity="error" />

// Error banners
<AISErrorBanner
  error={errorInfo}
  autoDismissAfter={5}
  onDismiss={() => setShowError(false)}
/>
```

### AISDataGrid

Excel-like data grid with sorting, filtering, selection, and inline editing.

```tsx
<AISDataGrid
  data={products}
  columns={[
    { id: 'name', title: 'Name', accessor: 'name', editable: true },
    { id: 'price', title: 'Price', accessor: 'price', formatter: (v) => `$${v}` },
    { id: 'status', title: 'Status', accessor: 'status' },
  ]}
  selectionMode="multiple"
  selection={selection}
  onSelectionChange={setSelection}
  showRowNumbers
  showFilters
  onCellEdit={handleCellEdit}
/>
```

**Keyboard shortcuts:**
- Arrow keys: Navigate cells
- Tab/Shift+Tab: Next/previous cell
- Enter/F2: Start editing
- Escape: Cancel editing

### AISListDetailShell

Master-detail pattern for CRUD operations with state retention.

```tsx
<AISListDetailShell
  items={filteredItems}
  totalCount={allItems.length}
  selection={selection}
  onSelectionChange={setSelection}
  hasUnsavedChanges={hasChanges}
  searchText={searchText}
  onSearchChange={setSearchText}
  emptyMessage="No items yet"
  noMatchesMessage="No items match your search"
  onSaveChanges={handleSave}
  onDiscardChanges={handleDiscard}
  onCreateNew={handleCreate}
  rowContent={(item, isSelected) => (
    <AISListRow
      title={item.name}
      subtitle={item.category}
      isSelected={isSelected}
    />
  )}
  detailContent={(item) => <ItemDetail item={item} />}
/>
```

## Design Tokens

### Spacing (8-point grid)

```tsx
import { AISSpacing } from '@asternest/ais-react-components';

AISSpacing.xs   // 4px
AISSpacing.sm   // 8px
AISSpacing.md   // 16px (base)
AISSpacing.lg   // 24px
AISSpacing.xl   // 32px
AISSpacing.xxl  // 48px
```

### Accessing Tokens

```tsx
import { useAISTokens } from '@asternest/ais-react-components';

function MyComponent() {
  const tokens = useAISTokens();

  return (
    <div style={{
      backgroundColor: tokens.surface,
      color: tokens.onSurface,
      borderColor: tokens.actionPrimary.color,
    }}>
      Content
    </div>
  );
}
```

### Dark Mode

```tsx
<AISProvider darkMode={true}>
  <App />
</AISProvider>
```

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

## Development

```bash
# Install dependencies
npm install

# Run demo app
npm run dev

# Build library
npm run build

# Run tests
npm test
```

## License

MIT - Asternest Labs

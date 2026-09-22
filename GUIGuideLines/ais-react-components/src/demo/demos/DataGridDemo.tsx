import { useState } from 'react';
import { AISDataGrid, type AISGridColumn } from '../../components/AISDataGrid';
import { AISStateBadge } from '../../components/AISStateBadge';
import { useAISTokens } from '../../core/AISProvider';
import type { AISBadgeState } from '../../core/tokens';

// Sample data model
interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  quantity: number;
  status: AISBadgeState;
  lastUpdated: Date;
}

// Generate 50 sample products to demonstrate pagination
const productNames = [
  'Widget Pro', 'Gadget Plus', 'Super Tool', 'Mega Device', 'Basic Item',
  'Premium Kit', 'Starter Pack', 'Pro Series', 'Economy Bundle', 'Deluxe Edition',
  'Smart Hub', 'Power Bank', 'Cable Set', 'Adapter Pro', 'Mini Speaker',
  'USB Drive', 'Mouse Pad', 'Keyboard', 'Monitor Stand', 'Desk Lamp',
  'Headphones', 'Webcam HD', 'Router Pro', 'Switch Box', 'Card Reader',
  'Phone Mount', 'Laptop Stand', 'Dock Station', 'Charger Fast', 'Battery Pack',
  'Screen Guard', 'Case Cover', 'Stylus Pen', 'Memory Card', 'SSD Drive',
  'Graphics Tab', 'Drawing Pad', 'Mic Stand', 'Pop Filter', 'Audio Mix',
  'Light Ring', 'Tripod Pro', 'Camera Bag', 'Lens Kit', 'Filter Set',
  'Gimbal Pro', 'Drone Mini', 'Action Cam', 'VR Headset', 'Game Pad',
];
const categories = ['Electronics', 'Tools', 'Accessories', 'Office', 'Gaming'];
const statuses: AISBadgeState[] = ['active', 'inactive', 'pending', 'draft'];

const sampleProducts: Product[] = productNames.map((name, i) => ({
  id: String(i + 1),
  name,
  category: categories[i % categories.length],
  price: 9.99 + (i * 7.5) % 400,
  quantity: 10 + (i * 17) % 500,
  status: statuses[i % statuses.length],
  lastUpdated: new Date(Date.now() - i * 86400000),
}));

export function DataGridDemo() {
  const tokens = useAISTokens();
  const [products, setProducts] = useState(sampleProducts);
  const [selection, setSelection] = useState<Set<string | number>>(new Set());
  const [searchText, setSearchText] = useState('');

  const columns: AISGridColumn<Product>[] = [
    {
      id: 'name',
      title: 'Product Name',
      accessor: 'name',
      width: 180,
      sortable: true,
      filterable: true,
      editable: true,
    },
    {
      id: 'category',
      title: 'Category',
      accessor: 'category',
      width: 120,
      sortable: true,
      filterable: true,
    },
    {
      id: 'price',
      title: 'Price',
      accessor: 'price',
      formatter: (value) => `$${(value as number).toFixed(2)}`,
      align: 'right',
      width: 100,
      sortable: true,
      editable: true,
      parser: (input) => parseFloat(input),
    },
    {
      id: 'quantity',
      title: 'Qty',
      accessor: 'quantity',
      formatter: (value) => String(value),
      align: 'right',
      width: 80,
      sortable: true,
      editable: true,
      parser: (input) => parseInt(input, 10),
    },
    {
      id: 'status',
      title: 'Status',
      accessor: 'status',
      formatter: (value) => (
        <AISStateBadge state={value as AISBadgeState} style="pill" size="small" />
      ),
      width: 120,
      sortable: true,
    },
    {
      id: 'lastUpdated',
      title: 'Last Updated',
      accessor: 'lastUpdated',
      formatter: (value) => (value as Date).toLocaleDateString(),
      width: 120,
      sortable: true,
    },
  ];

  const handleCellEdit = (row: Product, columnId: string, newValue: unknown) => {
    setProducts((prev) =>
      prev.map((p) =>
        p.id === row.id
          ? { ...p, [columnId]: newValue, lastUpdated: new Date() }
          : p
      )
    );
  };

  const handleDeleteSelected = () => {
    setProducts((prev) => prev.filter((p) => !selection.has(p.id)));
    setSelection(new Set());
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1
          className="text-3xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          AISDataGrid
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Excel-like data grid with sorting, filtering, selection, and inline editing.
          Follows AIS §3.3 and §3.4 (C-35, C-36 conformance).
        </p>
      </div>

      {/* Features */}
      <div
        className="p-4 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h3 className="font-semibold mb-2" style={{ color: tokens.onSurface }}>
          Features
        </h3>
        <ul className="text-sm space-y-1" style={{ color: tokens.onSurfaceSecondary }}>
          <li>• <strong>Click column headers</strong> to sort (multi-column with priority indicators)</li>
          <li>• <strong>Use filter inputs</strong> in header row for per-column filtering</li>
          <li>• <strong>Click rows</strong> to select (Cmd/Ctrl+Click for multi-select)</li>
          <li>• <strong>Double-click cells</strong> to edit (Name, Price, Qty columns are editable)</li>
          <li>• <strong>Keyboard navigation:</strong> Arrow keys, Tab, Enter/F2 to edit, Escape to cancel</li>
          <li>• <strong>Export CSV</strong> button exports current filtered/sorted view</li>
          <li>• <strong>Pagination</strong> with configurable page sizes (10, 25, 50, 100)</li>
        </ul>
      </div>

      {/* Search Bar */}
      <div className="flex items-center gap-4">
        <div className="flex-1 max-w-md">
          <input
            type="text"
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            placeholder="Global search..."
            className="w-full px-4 py-2 rounded-lg border"
            style={{
              backgroundColor: tokens.surface,
              borderColor: tokens.onSurfaceSecondary + '30',
              color: tokens.onSurface,
            }}
          />
        </div>

        {selection.size > 0 && (
          <button
            onClick={handleDeleteSelected}
            className="px-4 py-2 rounded-lg text-white"
            style={{ backgroundColor: tokens.actionDestructive.color }}
          >
            Delete {selection.size} selected
          </button>
        )}
      </div>

      {/* Data Grid */}
      <div
        className="rounded-lg overflow-hidden border"
        style={{ borderColor: tokens.onSurfaceSecondary + '20' }}
      >
        <AISDataGrid
          data={products}
          columns={columns}
          selectionMode="multiple"
          selection={selection}
          onSelectionChange={setSelection}
          showRowNumbers
          showFilters
          searchText={searchText}
          onCellEdit={handleCellEdit}
          maxHeight={500}
          pageable
          defaultPageSize={10}
        />
      </div>

      {/* Selection Info */}
      {selection.size > 0 && (
        <div
          className="p-4 rounded-lg"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          <h3 className="font-semibold mb-2" style={{ color: tokens.onSurface }}>
            Selected Items
          </h3>
          <div className="flex flex-wrap gap-2">
            {Array.from(selection).map((id) => {
              const product = products.find((p) => p.id === id);
              return product ? (
                <span
                  key={id}
                  className="px-2 py-1 rounded text-sm"
                  style={{
                    backgroundColor: tokens.actionPrimary.color + '20',
                    color: tokens.actionPrimary.color,
                  }}
                >
                  {product.name}
                </span>
              ) : null;
            })}
          </div>
        </div>
      )}
    </div>
  );
}

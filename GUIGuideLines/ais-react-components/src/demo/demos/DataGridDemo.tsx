import React, { useState } from 'react';
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

// Sample data
const sampleProducts: Product[] = [
  { id: '1', name: 'Widget Pro', category: 'Electronics', price: 29.99, quantity: 150, status: 'active', lastUpdated: new Date() },
  { id: '2', name: 'Gadget Plus', category: 'Electronics', price: 49.99, quantity: 75, status: 'active', lastUpdated: new Date(Date.now() - 86400000) },
  { id: '3', name: 'Super Tool', category: 'Tools', price: 19.99, quantity: 200, status: 'active', lastUpdated: new Date(Date.now() - 172800000) },
  { id: '4', name: 'Mega Device', category: 'Electronics', price: 199.99, quantity: 25, status: 'inactive', lastUpdated: new Date(Date.now() - 259200000) },
  { id: '5', name: 'Basic Item', category: 'Accessories', price: 9.99, quantity: 500, status: 'active', lastUpdated: new Date(Date.now() - 345600000) },
  { id: '6', name: 'Premium Kit', category: 'Tools', price: 79.99, quantity: 50, status: 'pending', lastUpdated: new Date(Date.now() - 432000000) },
  { id: '7', name: 'Starter Pack', category: 'Accessories', price: 14.99, quantity: 300, status: 'active', lastUpdated: new Date(Date.now() - 518400000) },
  { id: '8', name: 'Pro Series', category: 'Electronics', price: 299.99, quantity: 10, status: 'draft', lastUpdated: new Date(Date.now() - 604800000) },
  { id: '9', name: 'Economy Bundle', category: 'Accessories', price: 24.99, quantity: 180, status: 'active', lastUpdated: new Date(Date.now() - 691200000) },
  { id: '10', name: 'Deluxe Edition', category: 'Electronics', price: 449.99, quantity: 5, status: 'pending', lastUpdated: new Date(Date.now() - 777600000) },
];

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

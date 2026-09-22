/**
 * AISDataGrid Component
 *
 * Excel-like data grid with sorting, filtering, selection, and inline editing.
 * Follows AIS §3.3 and §3.4 requirements.
 *
 * KEY REQUIREMENTS (C-35, C-36):
 * - Keyboard navigation: Arrow keys, Tab, Enter/F2 for edit, Escape to cancel
 * - Multi-column sort with visible precedence
 * - Per-column typed filters
 * - Export reflects current view
 * - Cell values follow annotation rules
 */

import React, { useState, useMemo, useCallback, useRef, useEffect } from 'react';
import clsx from 'clsx';
import {
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
  Search,
  X,
  Download,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';
import { AISButton } from './AISButton';

// =============================================================================
// TYPES
// =============================================================================

export type SortDirection = 'asc' | 'desc' | null;

export interface AISGridColumn<T> {
  /** Unique column ID */
  id: string;
  /** Column header title */
  title: string;
  /** Key path or accessor function */
  accessor: keyof T | ((row: T) => unknown);
  /** Custom cell formatter */
  formatter?: (value: unknown, row: T) => React.ReactNode;
  /** Column width (px or 'auto') */
  width?: number | 'auto';
  /** Minimum width */
  minWidth?: number;
  /** Cell alignment */
  align?: 'left' | 'center' | 'right';
  /** Is column sortable? */
  sortable?: boolean;
  /** Is column filterable? */
  filterable?: boolean;
  /** Is cell editable? */
  editable?: boolean;
  /** Custom editor renderer */
  editor?: (value: unknown, onChange: (value: unknown) => void, onCommit: () => void, onCancel: () => void) => React.ReactNode;
  /** Parse input value back to data type */
  parser?: (input: string) => unknown;
}

export interface SortState {
  columnId: string;
  direction: SortDirection;
  priority: number;
}

export type SelectionMode = 'none' | 'single' | 'multiple';

export interface AISDataGridProps<T extends { id: string | number }> {
  /** Data array */
  data: T[];
  /** Column definitions */
  columns: AISGridColumn<T>[];
  /** Selection mode */
  selectionMode?: SelectionMode;
  /** Selected row IDs */
  selection?: Set<string | number>;
  /** Selection change handler */
  onSelectionChange?: (selection: Set<string | number>) => void;
  /** Show row numbers? */
  showRowNumbers?: boolean;
  /** Show filters row? */
  showFilters?: boolean;
  /** Global search text */
  searchText?: string;
  /** Cell edit handler */
  onCellEdit?: (row: T, columnId: string, newValue: unknown) => void;
  /** Custom className */
  className?: string;
  /** Max height (enables virtualization feel) */
  maxHeight?: number | string;
  /** Enable paging */
  pageable?: boolean;
  /** Page size options */
  pageSizeOptions?: number[];
  /** Default page size */
  defaultPageSize?: number;
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

function getValue<T>(row: T, accessor: keyof T | ((row: T) => unknown)): unknown {
  if (typeof accessor === 'function') {
    return accessor(row);
  }
  return row[accessor];
}

function compareValues(a: unknown, b: unknown, direction: SortDirection): number {
  if (a === b) return 0;
  if (a === null || a === undefined) return 1;
  if (b === null || b === undefined) return -1;

  let comparison = 0;
  if (typeof a === 'number' && typeof b === 'number') {
    comparison = a - b;
  } else if (typeof a === 'string' && typeof b === 'string') {
    comparison = a.localeCompare(b);
  } else if (a instanceof Date && b instanceof Date) {
    comparison = a.getTime() - b.getTime();
  } else {
    comparison = String(a).localeCompare(String(b));
  }

  return direction === 'desc' ? -comparison : comparison;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function AISDataGrid<T extends { id: string | number }>({
  data,
  columns,
  selectionMode = 'none',
  selection = new Set(),
  onSelectionChange,
  showRowNumbers = false,
  showFilters = false,
  searchText = '',
  onCellEdit,
  className,
  maxHeight = '600px',
  pageable = false,
  pageSizeOptions = [10, 25, 50, 100],
  defaultPageSize = 25,
}: AISDataGridProps<T>) {
  const tokens = useAISTokens();

  // State
  const [sortStates, setSortStates] = useState<SortState[]>([]);
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [editingCell, setEditingCell] = useState<{ rowId: string | number; columnId: string } | null>(null);
  const [editValue, setEditValue] = useState<string>('');
  const [focusedCell, setFocusedCell] = useState<{ row: number; col: number } | null>(null);
  const [currentPage, setCurrentPage] = useState(0);
  const [pageSize, setPageSize] = useState(defaultPageSize);

  const gridRef = useRef<HTMLDivElement>(null);

  // Reset focus when page changes to avoid stale row references
  useEffect(() => {
    setFocusedCell(null);
    setEditingCell(null);
    setEditValue('');
  }, [currentPage, pageSize]);

  // Filter and sort data
  const processedData = useMemo(() => {
    let result = [...data];

    // Apply global search
    if (searchText) {
      const lowerSearch = searchText.toLowerCase();
      result = result.filter((row) =>
        columns.some((col) => {
          const value = getValue(row, col.accessor);
          return String(value).toLowerCase().includes(lowerSearch);
        })
      );
    }

    // Apply column filters
    Object.entries(filters).forEach(([columnId, filterValue]) => {
      if (!filterValue) return;
      const column = columns.find((c) => c.id === columnId);
      if (!column) return;

      const lowerFilter = filterValue.toLowerCase();
      result = result.filter((row) => {
        const value = getValue(row, column.accessor);
        return String(value).toLowerCase().includes(lowerFilter);
      });
    });

    // Apply sorting
    if (sortStates.length > 0) {
      const sortedSortStates = [...sortStates].sort((a, b) => a.priority - b.priority);

      result.sort((a, b) => {
        for (const sortState of sortedSortStates) {
          const column = columns.find((c) => c.id === sortState.columnId);
          if (!column || !sortState.direction) continue;

          const valueA = getValue(a, column.accessor);
          const valueB = getValue(b, column.accessor);
          const comparison = compareValues(valueA, valueB, sortState.direction);

          if (comparison !== 0) return comparison;
        }
        return 0;
      });
    }

    return result;
  }, [data, columns, searchText, filters, sortStates]);

  // Paging calculations
  const totalPages = useMemo(() => {
    if (!pageable || pageSize <= 0) return 1;
    return Math.max(1, Math.ceil(processedData.length / pageSize));
  }, [pageable, pageSize, processedData.length]);

  const pagedData = useMemo(() => {
    if (!pageable) return processedData;
    const startIndex = currentPage * pageSize;
    const endIndex = Math.min(startIndex + pageSize, processedData.length);
    return processedData.slice(startIndex, endIndex);
  }, [pageable, currentPage, pageSize, processedData]);

  const displayRange = useMemo(() => {
    const total = processedData.length;
    if (!pageable) return { start: 1, end: total, total };
    const start = currentPage * pageSize + 1;
    const end = Math.min((currentPage + 1) * pageSize, total);
    return { start, end, total };
  }, [pageable, currentPage, pageSize, processedData.length]);

  // Handle column sort click
  const handleSort = useCallback((columnId: string) => {
    setSortStates((prev) => {
      const existing = prev.find((s) => s.columnId === columnId);

      if (!existing) {
        // Add new sort
        return [...prev, { columnId, direction: 'asc', priority: prev.length }];
      }

      if (existing.direction === 'asc') {
        // Switch to desc
        return prev.map((s) =>
          s.columnId === columnId ? { ...s, direction: 'desc' as const } : s
        );
      }

      // Remove sort
      const filtered = prev.filter((s) => s.columnId !== columnId);
      return filtered.map((s, i) => ({ ...s, priority: i }));
    });
  }, []);

  // Handle row selection
  const handleRowClick = useCallback(
    (rowId: string | number, event: React.MouseEvent) => {
      if (selectionMode === 'none' || !onSelectionChange) return;

      const newSelection = new Set(selection);

      if (selectionMode === 'multiple' && (event.ctrlKey || event.metaKey)) {
        if (newSelection.has(rowId)) {
          newSelection.delete(rowId);
        } else {
          newSelection.add(rowId);
        }
      } else if (selectionMode === 'multiple' && event.shiftKey) {
        // Shift-click for range selection would need more state
        newSelection.add(rowId);
      } else {
        newSelection.clear();
        newSelection.add(rowId);
      }

      onSelectionChange(newSelection);
    },
    [selectionMode, selection, onSelectionChange]
  );

  // Start editing cell
  const startEditing = useCallback(
    (rowId: string | number, columnId: string, currentValue: unknown) => {
      setEditingCell({ rowId, columnId });
      setEditValue(String(currentValue ?? ''));
    },
    []
  );

  // Commit edit
  const commitEdit = useCallback(() => {
    if (!editingCell || !onCellEdit) return;

    const row = data.find((r) => r.id === editingCell.rowId);
    const column = columns.find((c) => c.id === editingCell.columnId);

    if (row && column) {
      const parsedValue = column.parser ? column.parser(editValue) : editValue;
      onCellEdit(row, editingCell.columnId, parsedValue);
    }

    setEditingCell(null);
    setEditValue('');
  }, [editingCell, editValue, data, columns, onCellEdit]);

  // Cancel edit
  const cancelEdit = useCallback(() => {
    setEditingCell(null);
    setEditValue('');
  }, []);

  // Keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!focusedCell) return;

      const { row, col } = focusedCell;
      // Use pagedData for row navigation when paging is enabled
      const displayData = pageable ? pagedData : processedData;
      const maxRow = displayData.length - 1;
      const maxCol = columns.length - 1 + (showRowNumbers ? 1 : 0);

      switch (e.key) {
        case 'ArrowUp':
          if (row > 0) setFocusedCell({ row: row - 1, col });
          e.preventDefault();
          break;
        case 'ArrowDown':
          if (row < maxRow) setFocusedCell({ row: row + 1, col });
          e.preventDefault();
          break;
        case 'ArrowLeft':
          if (col > 0) setFocusedCell({ row, col: col - 1 });
          e.preventDefault();
          break;
        case 'ArrowRight':
          if (col < maxCol) setFocusedCell({ row, col: col + 1 });
          e.preventDefault();
          break;
        case 'Tab':
          if (e.shiftKey) {
            // Shift+Tab: move to previous cell
            if (col > 0) {
              setFocusedCell({ row, col: col - 1 });
            } else if (row > 0) {
              setFocusedCell({ row: row - 1, col: maxCol });
            }
          } else {
            // Tab: move to next cell
            if (col < maxCol) {
              setFocusedCell({ row, col: col + 1 });
            } else if (row < maxRow) {
              setFocusedCell({ row: row + 1, col: 0 });
            }
          }
          e.preventDefault();
          break;
        case 'Enter':
        case 'F2':
          if (!editingCell) {
            // Use displayData (pagedData when paging) for editing
            const dataRow = displayData[row];
            const columnIndex = showRowNumbers ? col - 1 : col;
            const column = columns[columnIndex];
            if (column?.editable && dataRow) {
              const value = getValue(dataRow, column.accessor);
              startEditing(dataRow.id, column.id, value);
            }
          } else {
            commitEdit();
          }
          e.preventDefault();
          break;
        case 'Escape':
          if (editingCell) {
            cancelEdit();
          }
          e.preventDefault();
          break;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [focusedCell, processedData, pagedData, pageable, columns, showRowNumbers, editingCell, startEditing, commitEdit, cancelEdit]);

  // Export to CSV
  const exportToCSV = useCallback(() => {
    const headers = columns.map((c) => c.title).join(',');
    const rows = processedData.map((row) =>
      columns
        .map((col) => {
          const value = getValue(row, col.accessor);
          return `"${String(value ?? '').replace(/"/g, '""')}"`;
        })
        .join(',')
    );
    const csv = [headers, ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'export.csv';
    a.click();
    URL.revokeObjectURL(url);
  }, [columns, processedData]);

  // Render sort indicator
  const renderSortIndicator = (columnId: string) => {
    const sortState = sortStates.find((s) => s.columnId === columnId);

    if (!sortState || !sortState.direction) {
      return <ChevronsUpDown size={14} className="opacity-30" />;
    }

    return (
      <span className="flex items-center gap-0.5">
        {sortState.direction === 'asc' ? (
          <ChevronUp size={14} />
        ) : (
          <ChevronDown size={14} />
        )}
        {sortStates.length > 1 && (
          <span className="text-xs">{sortState.priority + 1}</span>
        )}
      </span>
    );
  };

  return (
    <div className={clsx('flex flex-col', className)}>
      {/* Footer/Toolbar */}
      <div
        className="flex items-center justify-between px-4 py-2 border-b"
        style={{
          backgroundColor: tokens.surfaceSecondary,
          borderColor: tokens.onSurfaceSecondary + '20',
        }}
      >
        <div className="flex items-center gap-2 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          <span>{processedData.length} rows</span>
          {selection.size > 0 && <span>• {selection.size} selected</span>}
          {sortStates.length > 0 && <span>• Sorted by {sortStates.length} column(s)</span>}
          {Object.values(filters).some(Boolean) && <span>• Filtered</span>}
        </div>

        <AISButton actionType="secondary" variant="text" size="small" onClick={exportToCSV}>
          <Download size={14} className="mr-1" />
          Export CSV
        </AISButton>
      </div>

      {/* Grid */}
      <div
        ref={gridRef}
        className="overflow-auto"
        style={{ maxHeight }}
        tabIndex={0}
        onFocus={() => !focusedCell && setFocusedCell({ row: 0, col: 0 })}
      >
        <table
          className="w-full border-collapse"
          style={{ backgroundColor: tokens.surface }}
        >
          {/* Header */}
          <thead
            className="sticky top-0 z-10"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <tr>
              {showRowNumbers && (
                <th
                  className="px-3 py-2 text-left text-xs font-semibold border-b"
                  style={{
                    color: tokens.onSurfaceSecondary,
                    borderColor: tokens.onSurfaceSecondary + '20',
                    width: 50,
                  }}
                >
                  #
                </th>
              )}
              {columns.map((column) => (
                <th
                  key={column.id}
                  className={clsx(
                    'px-3 py-2 text-xs font-semibold border-b select-none',
                    column.sortable !== false && 'cursor-pointer hover:bg-opacity-80'
                  )}
                  style={{
                    color: tokens.onSurface,
                    borderColor: tokens.onSurfaceSecondary + '20',
                    textAlign: column.align || 'left',
                    width: column.width === 'auto' ? undefined : column.width,
                    minWidth: column.minWidth,
                  }}
                  onClick={() => column.sortable !== false && handleSort(column.id)}
                >
                  <div className="flex items-center gap-1">
                    <span>{column.title}</span>
                    {column.sortable !== false && renderSortIndicator(column.id)}
                  </div>
                </th>
              ))}
            </tr>

            {/* Filter row */}
            {showFilters && (
              <tr>
                {showRowNumbers && (
                  <th
                    className="px-3 py-1 border-b"
                    style={{ borderColor: tokens.onSurfaceSecondary + '20' }}
                  />
                )}
                {columns.map((column) => (
                  <th
                    key={`filter-${column.id}`}
                    className="px-2 py-1 border-b"
                    style={{ borderColor: tokens.onSurfaceSecondary + '20' }}
                  >
                    {column.filterable !== false && (
                      <div className="relative">
                        <Search
                          size={12}
                          className="absolute left-2 top-1/2 -translate-y-1/2"
                          style={{ color: tokens.onSurfaceSecondary }}
                        />
                        <input
                          type="text"
                          value={filters[column.id] || ''}
                          onChange={(e) =>
                            setFilters((prev) => ({
                              ...prev,
                              [column.id]: e.target.value,
                            }))
                          }
                          placeholder="Filter..."
                          className="w-full pl-7 pr-6 py-1 text-xs rounded border"
                          style={{
                            backgroundColor: tokens.surface,
                            borderColor: tokens.onSurfaceSecondary + '30',
                            color: tokens.onSurface,
                          }}
                        />
                        {filters[column.id] && (
                          <button
                            onClick={() =>
                              setFilters((prev) => ({ ...prev, [column.id]: '' }))
                            }
                            className="absolute right-2 top-1/2 -translate-y-1/2"
                            style={{ color: tokens.onSurfaceSecondary }}
                          >
                            <X size={12} />
                          </button>
                        )}
                      </div>
                    )}
                  </th>
                ))}
              </tr>
            )}
          </thead>

          {/* Body */}
          <tbody>
            {pagedData.map((row, rowIndex) => {
              const isSelected = selection.has(row.id);
              const actualRowIndex = pageable ? currentPage * pageSize + rowIndex : rowIndex;

              return (
                <tr
                  key={row.id}
                  onClick={(e) => handleRowClick(row.id, e)}
                  className={clsx(
                    'transition-colors',
                    selectionMode !== 'none' && 'cursor-pointer hover:bg-opacity-50'
                  )}
                  style={{
                    backgroundColor: isSelected
                      ? tokens.actionPrimary.color + '15'
                      : undefined,
                  }}
                >
                  {showRowNumbers && (
                    <td
                      className="px-3 py-2 text-xs border-b"
                      style={{
                        color: tokens.onSurfaceSecondary,
                        borderColor: tokens.onSurfaceSecondary + '10',
                      }}
                    >
                      {actualRowIndex + 1}
                    </td>
                  )}
                  {columns.map((column, colIndex) => {
                    const value = getValue(row, column.accessor);
                    const isEditing =
                      editingCell?.rowId === row.id &&
                      editingCell?.columnId === column.id;
                    const isFocused =
                      focusedCell?.row === rowIndex &&
                      focusedCell?.col === (showRowNumbers ? colIndex + 1 : colIndex);

                    return (
                      <td
                        key={column.id}
                        className={clsx(
                          'px-3 py-2 text-sm border-b',
                          isFocused && 'ring-2 ring-inset'
                        )}
                        style={{
                          color: tokens.onSurface,
                          borderColor: tokens.onSurfaceSecondary + '10',
                          textAlign: column.align || 'left',
                          '--tw-ring-color': tokens.actionPrimary.color,
                        } as React.CSSProperties}
                        onDoubleClick={() => {
                          if (column.editable) {
                            startEditing(row.id, column.id, value);
                          }
                        }}
                      >
                        {isEditing ? (
                          <input
                            type="text"
                            value={editValue}
                            onChange={(e) => setEditValue(e.target.value)}
                            onBlur={commitEdit}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') commitEdit();
                              if (e.key === 'Escape') cancelEdit();
                            }}
                            autoFocus
                            className="w-full px-1 py-0.5 rounded border"
                            style={{
                              backgroundColor: tokens.surface,
                              borderColor: tokens.actionPrimary.color,
                              color: tokens.onSurface,
                            }}
                          />
                        ) : column.formatter ? (
                          column.formatter(value, row)
                        ) : (
                          String(value ?? '')
                        )}
                      </td>
                    );
                  })}
                </tr>
              );
            })}
          </tbody>
        </table>

        {/* Empty state */}
        {pagedData.length === 0 && (
          <div
            className="flex flex-col items-center justify-center py-12"
            style={{ color: tokens.onSurfaceSecondary }}
          >
            <Search size={48} className="mb-4 opacity-30" />
            <p className="text-lg font-medium">No data found</p>
            <p className="text-sm">
              {searchText || Object.values(filters).some(Boolean)
                ? 'Try adjusting your filters'
                : 'No records to display'}
            </p>
          </div>
        )}
      </div>

      {/* Paging Controls */}
      {pageable && (
        <div
          className="flex items-center justify-between px-4 py-2 border-t"
          style={{
            backgroundColor: tokens.surfaceSecondary,
            borderColor: tokens.onSurfaceSecondary + '20',
          }}
        >
          {/* Page size selector */}
          <div className="flex items-center gap-2">
            <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
              Rows per page:
            </span>
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value));
                setCurrentPage(0);
              }}
              className="px-2 py-1 text-xs rounded border"
              style={{
                backgroundColor: tokens.surface,
                borderColor: tokens.onSurfaceSecondary + '30',
                color: tokens.onSurface,
              }}
            >
              {pageSizeOptions.map((size) => (
                <option key={size} value={size}>
                  {size}
                </option>
              ))}
            </select>
          </div>

          {/* Range display */}
          <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
            Showing {displayRange.start}-{displayRange.end} of {displayRange.total}
          </span>

          {/* Navigation buttons */}
          <div className="flex items-center gap-1">
            <button
              onClick={() => setCurrentPage(0)}
              disabled={currentPage === 0}
              className="p-1 rounded hover:bg-opacity-10 disabled:opacity-30 disabled:cursor-not-allowed"
              style={{ color: currentPage === 0 ? tokens.onSurfaceSecondary : tokens.actionPrimary.color }}
              title="First page"
            >
              <ChevronsLeft size={16} />
            </button>
            <button
              onClick={() => setCurrentPage((p) => Math.max(0, p - 1))}
              disabled={currentPage === 0}
              className="p-1 rounded hover:bg-opacity-10 disabled:opacity-30 disabled:cursor-not-allowed"
              style={{ color: currentPage === 0 ? tokens.onSurfaceSecondary : tokens.actionPrimary.color }}
              title="Previous page"
            >
              <ChevronLeft size={16} />
            </button>
            <span className="px-2 text-xs" style={{ color: tokens.onSurface }}>
              Page {currentPage + 1} of {totalPages}
            </span>
            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages - 1, p + 1))}
              disabled={currentPage >= totalPages - 1}
              className="p-1 rounded hover:bg-opacity-10 disabled:opacity-30 disabled:cursor-not-allowed"
              style={{ color: currentPage >= totalPages - 1 ? tokens.onSurfaceSecondary : tokens.actionPrimary.color }}
              title="Next page"
            >
              <ChevronRight size={16} />
            </button>
            <button
              onClick={() => setCurrentPage(totalPages - 1)}
              disabled={currentPage >= totalPages - 1}
              className="p-1 rounded hover:bg-opacity-10 disabled:opacity-30 disabled:cursor-not-allowed"
              style={{ color: currentPage >= totalPages - 1 ? tokens.onSurfaceSecondary : tokens.actionPrimary.color }}
              title="Last page"
            >
              <ChevronsRight size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default AISDataGrid;

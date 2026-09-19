/**
 * AISListDetailShell Component
 *
 * Master-detail pattern for CRUD operations with state retention.
 * Follows AIS §1.1 requirements.
 *
 * KEY CONFORMANCE REQUIREMENTS:
 * - C-05: List state survives edit-save cycle
 * - C-06: Selection guard with unsaved changes
 * - C-07: Dual empty states (no records vs no matches)
 */

import React, { useState, useCallback, useEffect, useRef } from 'react';
import clsx from 'clsx';
import {
  Search,
  X,
  Plus,
  AlertTriangle,
  FileText,
  Filter,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';
import { AISButton } from './AISButton';

// =============================================================================
// TYPES
// =============================================================================

export interface AISListDetailShellProps<T extends { id: string | number }> {
  /** All items (unfiltered) */
  items: T[];
  /** Total count before filtering */
  totalCount?: number;
  /** Currently selected item */
  selection: T | null;
  /** Selection change handler */
  onSelectionChange: (item: T | null) => void;
  /** Does user have unsaved changes? */
  hasUnsavedChanges?: boolean;
  /** Search text (controlled) */
  searchText?: string;
  /** Search text change handler */
  onSearchChange?: (text: string) => void;
  /** Empty state message when no records exist */
  emptyMessage?: string;
  /** Empty state message when no records match filter */
  noMatchesMessage?: string;
  /** Save changes callback (for guard dialog) */
  onSaveChanges?: () => Promise<void>;
  /** Discard changes callback (for guard dialog) */
  onDiscardChanges?: () => void;
  /** Clear filters callback */
  onClearFilters?: () => void;
  /** Create new record callback */
  onCreateNew?: () => void;
  /** Render a list row */
  rowContent: (item: T, isSelected: boolean) => React.ReactNode;
  /** Render the detail panel */
  detailContent: (item: T) => React.ReactNode;
  /** Render empty detail state */
  emptyDetailContent?: React.ReactNode;
  /** List width */
  listWidth?: number | string;
  /** Custom className */
  className?: string;
}

// =============================================================================
// GUARD DIALOG
// =============================================================================

interface GuardDialogProps {
  isOpen: boolean;
  onSave: () => void;
  onDiscard: () => void;
  onCancel: () => void;
  isSaving: boolean;
}

function GuardDialog({ isOpen, onSave, onDiscard, onCancel, isSaving }: GuardDialogProps) {
  const tokens = useAISTokens();

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center"
      style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}
    >
      <div
        className="rounded-lg shadow-xl p-6 max-w-md w-full mx-4"
        style={{ backgroundColor: tokens.surface }}
        role="alertdialog"
        aria-labelledby="guard-dialog-title"
        aria-describedby="guard-dialog-description"
      >
        <div className="flex items-start gap-4 mb-4">
          <div
            className="flex-shrink-0 p-2 rounded-full"
            style={{ backgroundColor: tokens.stateWarning.color + '20' }}
          >
            <AlertTriangle size={24} style={{ color: tokens.stateWarning.color }} />
          </div>
          <div>
            <h2
              id="guard-dialog-title"
              className="text-lg font-semibold"
              style={{ color: tokens.onSurface }}
            >
              Unsaved Changes
            </h2>
            <p
              id="guard-dialog-description"
              className="mt-1"
              style={{ color: tokens.onSurfaceSecondary }}
            >
              You have unsaved changes. Would you like to save them before
              switching records?
            </p>
          </div>
        </div>

        <div className="flex justify-end gap-2">
          <AISButton actionType="neutral" variant="outlined" onClick={onCancel}>
            Cancel
          </AISButton>
          <AISButton actionType="destructive" variant="outlined" onClick={onDiscard}>
            Discard
          </AISButton>
          <AISButton actionType="confirm" onClick={onSave} isLoading={isSaving}>
            Save Changes
          </AISButton>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// EMPTY STATE COMPONENTS
// =============================================================================

interface EmptyStateProps {
  type: 'no-records' | 'no-matches';
  message?: string;
  onCreateNew?: () => void;
  onClearFilters?: () => void;
}

function EmptyState({ type, message, onCreateNew, onClearFilters }: EmptyStateProps) {
  const tokens = useAISTokens();

  const defaultMessage =
    type === 'no-records'
      ? 'No records yet'
      : 'No records match your search';

  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      {type === 'no-records' ? (
        <FileText
          size={48}
          className="mb-4"
          style={{ color: tokens.onSurfaceSecondary, opacity: 0.5 }}
        />
      ) : (
        <Search
          size={48}
          className="mb-4"
          style={{ color: tokens.onSurfaceSecondary, opacity: 0.5 }}
        />
      )}

      <p
        className="text-lg font-medium mb-2"
        style={{ color: tokens.onSurfaceSecondary }}
      >
        {message || defaultMessage}
      </p>

      {type === 'no-records' && onCreateNew && (
        <AISButton actionType="primary" onClick={onCreateNew} className="mt-4">
          <Plus size={18} className="mr-1" />
          Create New
        </AISButton>
      )}

      {type === 'no-matches' && onClearFilters && (
        <AISButton actionType="secondary" variant="outlined" onClick={onClearFilters} className="mt-4">
          <Filter size={18} className="mr-1" />
          Clear Filters
        </AISButton>
      )}
    </div>
  );
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export function AISListDetailShell<T extends { id: string | number }>({
  items,
  totalCount,
  selection,
  onSelectionChange,
  hasUnsavedChanges = false,
  searchText = '',
  onSearchChange,
  emptyMessage,
  noMatchesMessage,
  onSaveChanges,
  onDiscardChanges,
  onClearFilters,
  onCreateNew,
  rowContent,
  detailContent,
  emptyDetailContent,
  listWidth = 320,
  className,
}: AISListDetailShellProps<T>) {
  const tokens = useAISTokens();

  // Guard dialog state
  const [showGuard, setShowGuard] = useState(false);
  const [pendingSelection, setPendingSelection] = useState<T | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  // Scroll position preservation (C-05)
  const listRef = useRef<HTMLDivElement>(null);
  const scrollPositionRef = useRef(0);

  // Save scroll position when selection changes
  useEffect(() => {
    if (listRef.current) {
      scrollPositionRef.current = listRef.current.scrollTop;
    }
  }, [selection]);

  // Restore scroll position after updates
  useEffect(() => {
    if (listRef.current && scrollPositionRef.current > 0) {
      listRef.current.scrollTop = scrollPositionRef.current;
    }
  });

  // Handle item selection with guard (C-06)
  const handleSelectItem = useCallback(
    (item: T) => {
      if (selection?.id === item.id) return;

      if (hasUnsavedChanges) {
        setPendingSelection(item);
        setShowGuard(true);
      } else {
        onSelectionChange(item);
      }
    },
    [selection, hasUnsavedChanges, onSelectionChange]
  );

  // Guard dialog handlers
  const handleGuardSave = useCallback(async () => {
    if (!onSaveChanges) return;

    setIsSaving(true);
    try {
      await onSaveChanges();
      if (pendingSelection) {
        onSelectionChange(pendingSelection);
      }
      setShowGuard(false);
      setPendingSelection(null);
    } catch {
      // Error handling would happen in onSaveChanges
    } finally {
      setIsSaving(false);
    }
  }, [onSaveChanges, pendingSelection, onSelectionChange]);

  const handleGuardDiscard = useCallback(() => {
    onDiscardChanges?.();
    if (pendingSelection) {
      onSelectionChange(pendingSelection);
    }
    setShowGuard(false);
    setPendingSelection(null);
  }, [onDiscardChanges, pendingSelection, onSelectionChange]);

  const handleGuardCancel = useCallback(() => {
    setShowGuard(false);
    setPendingSelection(null);
  }, []);

  // Determine empty state type (C-07)
  const actualTotalCount = totalCount ?? items.length;
  const hasNoRecords = actualTotalCount === 0 && !searchText;
  const hasNoMatches = items.length === 0 && (!!searchText || actualTotalCount > 0);

  return (
    <>
      <div
        className={clsx('flex h-full', className)}
        style={{ backgroundColor: tokens.surface }}
      >
        {/* List Panel */}
        <div
          className="flex flex-col border-r"
          style={{
            width: listWidth,
            minWidth: listWidth,
            borderColor: tokens.onSurfaceSecondary + '20',
          }}
        >
          {/* Search Header */}
          <div
            className="p-3 border-b"
            style={{
              backgroundColor: tokens.surfaceSecondary,
              borderColor: tokens.onSurfaceSecondary + '20',
            }}
          >
            <div className="relative">
              <Search
                size={16}
                className="absolute left-3 top-1/2 -translate-y-1/2"
                style={{ color: tokens.onSurfaceSecondary }}
              />
              <input
                type="text"
                value={searchText}
                onChange={(e) => onSearchChange?.(e.target.value)}
                placeholder="Search..."
                className="w-full pl-9 pr-8 py-2 rounded-lg border"
                style={{
                  backgroundColor: tokens.surface,
                  borderColor: tokens.onSurfaceSecondary + '30',
                  color: tokens.onSurface,
                }}
              />
              {searchText && (
                <button
                  onClick={() => onSearchChange?.('')}
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-1 rounded hover:bg-opacity-10"
                  style={{ color: tokens.onSurfaceSecondary }}
                  aria-label="Clear search"
                >
                  <X size={16} />
                </button>
              )}
            </div>

            {/* Create button */}
            {onCreateNew && (
              <AISButton
                actionType="primary"
                fullWidth
                onClick={onCreateNew}
                className="mt-3"
                size="small"
              >
                <Plus size={16} className="mr-1" />
                Create New
              </AISButton>
            )}
          </div>

          {/* List Content */}
          <div
            ref={listRef}
            className="flex-1 overflow-auto"
          >
            {hasNoRecords ? (
              <EmptyState
                type="no-records"
                message={emptyMessage}
                onCreateNew={onCreateNew}
              />
            ) : hasNoMatches ? (
              <EmptyState
                type="no-matches"
                message={noMatchesMessage}
                onClearFilters={onClearFilters}
              />
            ) : (
              <ul className="divide-y" style={{ divideColor: tokens.onSurfaceSecondary + '10' }}>
                {items.map((item) => {
                  const isSelected = selection?.id === item.id;

                  return (
                    <li key={item.id}>
                      <button
                        onClick={() => handleSelectItem(item)}
                        className={clsx(
                          'w-full text-left p-3 transition-colors',
                          'focus:outline-none focus:ring-2 focus:ring-inset'
                        )}
                        style={{
                          backgroundColor: isSelected
                            ? tokens.actionPrimary.color + '15'
                            : undefined,
                          '--tw-ring-color': tokens.actionPrimary.color,
                        } as React.CSSProperties}
                        aria-selected={isSelected}
                      >
                        {rowContent(item, isSelected)}
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>

          {/* List Footer */}
          <div
            className="px-3 py-2 text-xs border-t"
            style={{
              backgroundColor: tokens.surfaceSecondary,
              borderColor: tokens.onSurfaceSecondary + '20',
              color: tokens.onSurfaceSecondary,
            }}
          >
            {items.length} of {actualTotalCount} items
            {hasUnsavedChanges && (
              <span
                className="ml-2 px-1.5 py-0.5 rounded text-white"
                style={{ backgroundColor: tokens.stateWarning.color }}
              >
                Unsaved
              </span>
            )}
          </div>
        </div>

        {/* Detail Panel */}
        <div className="flex-1 overflow-auto">
          {selection ? (
            detailContent(selection)
          ) : (
            emptyDetailContent || (
              <div
                className="flex flex-col items-center justify-center h-full"
                style={{ color: tokens.onSurfaceSecondary }}
              >
                <FileText size={64} className="mb-4 opacity-30" />
                <p className="text-lg">Select an item to view details</p>
              </div>
            )
          )}
        </div>
      </div>

      {/* Guard Dialog */}
      <GuardDialog
        isOpen={showGuard}
        onSave={handleGuardSave}
        onDiscard={handleGuardDiscard}
        onCancel={handleGuardCancel}
        isSaving={isSaving}
      />
    </>
  );
}

// =============================================================================
// LIST ROW COMPONENT
// =============================================================================

export interface AISListRowProps {
  title: string;
  subtitle?: string;
  leadingIcon?: React.ReactNode;
  trailingContent?: React.ReactNode;
  isSelected?: boolean;
}

/**
 * Convenience component for consistent list row styling
 */
export function AISListRow({
  title,
  subtitle,
  leadingIcon,
  trailingContent,
  isSelected,
}: AISListRowProps) {
  const tokens = useAISTokens();

  return (
    <div className="flex items-center gap-3">
      {leadingIcon && (
        <div
          className="flex-shrink-0"
          style={{
            color: isSelected
              ? tokens.actionPrimary.color
              : tokens.onSurfaceSecondary,
          }}
        >
          {leadingIcon}
        </div>
      )}

      <div className="flex-1 min-w-0">
        <p
          className={clsx('truncate', isSelected && 'font-semibold')}
          style={{
            color: isSelected ? tokens.actionPrimary.color : tokens.onSurface,
          }}
        >
          {title}
        </p>
        {subtitle && (
          <p
            className="text-sm truncate"
            style={{ color: tokens.onSurfaceSecondary }}
          >
            {subtitle}
          </p>
        )}
      </div>

      {trailingContent && (
        <div className="flex-shrink-0">{trailingContent}</div>
      )}
    </div>
  );
}

export default AISListDetailShell;

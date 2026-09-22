/**
 * =============================================================================
 * AISAutocomplete.tsx
 * Asternest Interface Standard (AIS) v1.0 - React Implementation
 * =============================================================================
 *
 * PURPOSE:
 * A type-ahead autocomplete component with customizable suggestion filtering,
 * keyboard navigation, and selection handling. Follows AIS token conventions.
 *
 * FEATURES:
 * - Type-ahead filtering
 * - Keyboard navigation (up/down arrows, enter, escape)
 * - Custom suggestion rendering
 * - Clear button
 * - Loading state
 * - Error state
 * - Accessibility support
 */

import { useState, useRef, useEffect, useCallback, useMemo, KeyboardEvent, ChangeEvent } from 'react';
import { Search, X, Check, Loader2, AlertCircle } from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';

// =============================================================================
// Types
// =============================================================================

export type AISAutocompleteStyle = 'standard' | 'outlined' | 'filled';

export interface AISAutocompleteProps<T> {
  /** Current text value */
  value: string;
  /** Callback when text changes */
  onChange: (value: string) => void;
  /** List of suggestions to display */
  suggestions: T[];
  /** Function to get display text from an item */
  displayText: (item: T) => string;
  /** Optional function to get secondary text */
  secondaryText?: (item: T) => string;
  /** Optional function to get icon component for each item */
  itemIcon?: (item: T) => React.ReactNode;
  /** Placeholder text */
  placeholder?: string;
  /** Called when an item is selected */
  onSelect?: (item: T) => void;
  /** Visual style */
  style?: AISAutocompleteStyle;
  /** Maximum number of suggestions to show */
  maxSuggestions?: number;
  /** Whether the component is loading */
  isLoading?: boolean;
  /** Whether the component is disabled */
  isDisabled?: boolean;
  /** Error message to display */
  errorMessage?: string;
  /** Current selected item (for highlighting) */
  selectedItem?: T | null;
  /** Function to compare items for equality */
  itemKey?: (item: T) => string | number;
  /** Label for accessibility */
  label?: string;
  /** Additional CSS class name */
  className?: string;
}

// =============================================================================
// Component
// =============================================================================

export function AISAutocomplete<T>({
  value,
  onChange,
  suggestions,
  displayText,
  secondaryText,
  itemIcon,
  placeholder = 'Search...',
  onSelect,
  style = 'standard',
  maxSuggestions = 8,
  isLoading = false,
  isDisabled = false,
  errorMessage,
  selectedItem,
  itemKey,
  label,
  className = '',
}: AISAutocompleteProps<T>) {
  const tokens = useAISTokens();
  const [isOpen, setIsOpen] = useState(false);
  const [highlightedIndex, setHighlightedIndex] = useState(-1);
  const [isFocused, setIsFocused] = useState(false);

  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLUListElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Visible suggestions (limited)
  const visibleSuggestions = useMemo(
    () => suggestions.slice(0, maxSuggestions),
    [suggestions, maxSuggestions]
  );

  // Get item key for comparison
  const getItemKey = useCallback(
    (item: T, index: number): string | number => {
      if (itemKey) return itemKey(item);
      return index;
    },
    [itemKey]
  );

  // Check if item is selected
  const isItemSelected = useCallback(
    (item: T): boolean => {
      if (!selectedItem || !itemKey) return false;
      return itemKey(item) === itemKey(selectedItem);
    },
    [selectedItem, itemKey]
  );

  // Handle click outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setHighlightedIndex(-1);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Scroll highlighted item into view
  useEffect(() => {
    if (highlightedIndex >= 0 && listRef.current) {
      const highlightedElement = listRef.current.children[highlightedIndex] as HTMLElement;
      if (highlightedElement) {
        highlightedElement.scrollIntoView({ block: 'nearest' });
      }
    }
  }, [highlightedIndex]);

  // Handle input change
  const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    onChange(newValue);
    setIsOpen(true);
    setHighlightedIndex(-1);
  };

  // Handle item selection
  const handleSelect = (item: T) => {
    onChange(displayText(item));
    onSelect?.(item);
    setIsOpen(false);
    setHighlightedIndex(-1);
    inputRef.current?.blur();
  };

  // Handle keyboard navigation
  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (!isOpen && e.key === 'ArrowDown') {
      setIsOpen(true);
      return;
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setHighlightedIndex((prev) =>
          prev < visibleSuggestions.length - 1 ? prev + 1 : 0
        );
        break;
      case 'ArrowUp':
        e.preventDefault();
        setHighlightedIndex((prev) =>
          prev > 0 ? prev - 1 : visibleSuggestions.length - 1
        );
        break;
      case 'Enter':
        e.preventDefault();
        if (highlightedIndex >= 0 && highlightedIndex < visibleSuggestions.length) {
          handleSelect(visibleSuggestions[highlightedIndex]);
        }
        break;
      case 'Escape':
        e.preventDefault();
        setIsOpen(false);
        setHighlightedIndex(-1);
        inputRef.current?.blur();
        break;
    }
  };

  // Clear input
  const handleClear = () => {
    onChange('');
    setHighlightedIndex(-1);
    inputRef.current?.focus();
  };

  // Determine border color
  const borderColor = errorMessage
    ? tokens.actionDestructive.color
    : isFocused
    ? tokens.actionPrimary.color
    : tokens.onSurfaceSecondary + '50';

  // Determine background color
  const backgroundColor = style === 'filled' ? tokens.surfaceSecondary : tokens.surface;

  const showDropdown = isOpen && visibleSuggestions.length > 0 && value.length > 0;

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      {/* Label */}
      {label && (
        <label
          className="block text-sm font-medium mb-1"
          style={{ color: tokens.onSurface }}
        >
          {label}
        </label>
      )}

      {/* Input container */}
      <div
        className="flex items-center gap-2 px-3 py-2 rounded-lg transition-colors"
        style={{
          backgroundColor,
          border: `${style === 'outlined' || isFocused ? '1.5px' : '1px'} solid ${borderColor}`,
          opacity: isDisabled ? 0.6 : 1,
        }}
      >
        {/* Search icon */}
        <Search size={18} color={tokens.onSurfaceSecondary} />

        {/* Input */}
        <input
          ref={inputRef}
          type="text"
          value={value}
          onChange={handleInputChange}
          onFocus={() => {
            setIsFocused(true);
            setIsOpen(true);
          }}
          onBlur={() => setIsFocused(false)}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          disabled={isDisabled}
          className="flex-1 bg-transparent outline-none text-sm"
          style={{ color: tokens.onSurface }}
          aria-label={label || placeholder}
          aria-expanded={showDropdown}
          aria-haspopup="listbox"
          aria-autocomplete="list"
          role="combobox"
        />

        {/* Loading indicator */}
        {isLoading && (
          <Loader2 size={18} color={tokens.onSurfaceSecondary} className="animate-spin" />
        )}

        {/* Clear button */}
        {value && !isLoading && (
          <button
            type="button"
            onClick={handleClear}
            className="p-0.5 rounded hover:bg-black/5 transition-colors"
            aria-label="Clear"
          >
            <X size={16} color={tokens.onSurfaceSecondary} />
          </button>
        )}
      </div>

      {/* Dropdown */}
      {showDropdown && (
        <ul
          ref={listRef}
          className="absolute z-50 w-full mt-1 max-h-72 overflow-auto rounded-lg shadow-lg"
          style={{
            backgroundColor: tokens.surface,
            border: `1px solid ${tokens.onSurfaceSecondary}30`,
          }}
          role="listbox"
        >
          {visibleSuggestions.map((item, index) => {
            const isHighlighted = index === highlightedIndex;
            const isSelected = isItemSelected(item);

            return (
              <li
                key={getItemKey(item, index)}
                onClick={() => handleSelect(item)}
                onMouseEnter={() => setHighlightedIndex(index)}
                className="flex items-center gap-2 px-3 py-2 cursor-pointer transition-colors"
                style={{
                  backgroundColor: isHighlighted ? tokens.surfaceSecondary : 'transparent',
                }}
                role="option"
                aria-selected={isSelected}
              >
                {/* Optional icon */}
                {itemIcon && (
                  <span
                    className="flex-shrink-0"
                    style={{
                      color: isSelected
                        ? tokens.actionPrimary.color
                        : tokens.onSurfaceSecondary,
                    }}
                  >
                    {itemIcon(item)}
                  </span>
                )}

                {/* Text content */}
                <div className="flex-1 min-w-0">
                  <div
                    className="text-sm truncate"
                    style={{ color: tokens.onSurface }}
                  >
                    {displayText(item)}
                  </div>
                  {secondaryText && (
                    <div
                      className="text-xs truncate"
                      style={{ color: tokens.onSurfaceSecondary }}
                    >
                      {secondaryText(item)}
                    </div>
                  )}
                </div>

                {/* Selection indicator */}
                {isSelected && (
                  <Check
                    size={16}
                    color={tokens.actionPrimary.color}
                    className="flex-shrink-0"
                  />
                )}
              </li>
            );
          })}
        </ul>
      )}

      {/* Error message */}
      {errorMessage && (
        <div
          className="flex items-center gap-1 mt-1 text-xs"
          style={{ color: tokens.actionDestructive.color }}
        >
          <AlertCircle size={12} />
          <span>{errorMessage}</span>
        </div>
      )}
    </div>
  );
}

// =============================================================================
// String Autocomplete (convenience wrapper)
// =============================================================================

export interface AISStringAutocompleteProps {
  value: string;
  onChange: (value: string) => void;
  suggestions: string[];
  placeholder?: string;
  onSelect?: (item: string) => void;
  style?: AISAutocompleteStyle;
  isLoading?: boolean;
  isDisabled?: boolean;
  errorMessage?: string;
  label?: string;
  className?: string;
}

export function AISStringAutocomplete({
  suggestions,
  ...props
}: AISStringAutocompleteProps) {
  return (
    <AISAutocomplete<string>
      {...props}
      suggestions={suggestions}
      displayText={(s) => s}
      itemKey={(s) => s}
    />
  );
}

export default AISAutocomplete;

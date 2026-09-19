/**
 * AISGridLayout.tsx
 * Asternest Interface Standard (AIS) v1.0 - React/TypeScript Implementation
 *
 * PURPOSE:
 * Provides responsive grid layout components for arranging items in a grid
 * that adapts based on available space and configuration.
 *
 * KEY FEATURES:
 * - Fixed column count grid
 * - Adaptive grid that adjusts columns based on minimum child width
 * - Consistent spacing using AIS design tokens
 * - Support for different aspect ratios
 */

import React, { useRef, useState, useEffect } from 'react';
import clsx from 'clsx';
import { AISSpacing } from '../core/tokens';

// ============================================================================
// Types
// ============================================================================

export interface AISGridLayoutProps {
  /** Grid children */
  children: React.ReactNode;
  /** Number of columns (for fixed grid) */
  columns?: number;
  /** Gap between items in pixels */
  gap?: number;
  /** Child aspect ratio (width/height) */
  aspectRatio?: number;
  /** Padding around the grid */
  padding?: number | string;
  /** Whether grid should shrink-wrap its content */
  shrinkWrap?: boolean;
  /** CSS class name */
  className?: string;
  /** Inline styles */
  style?: React.CSSProperties;
}

export interface AISAdaptiveGridLayoutProps
  extends Omit<AISGridLayoutProps, 'columns'> {
  /** Minimum width for each child in pixels */
  minChildWidth?: number;
  /** Maximum number of columns */
  maxColumns?: number;
}

// ============================================================================
// AISGridLayout Component
// ============================================================================

/**
 * Fixed column grid layout component
 *
 * @example
 * ```tsx
 * <AISGridLayout columns={3} gap={16}>
 *   <Card>Item 1</Card>
 *   <Card>Item 2</Card>
 *   <Card>Item 3</Card>
 * </AISGridLayout>
 * ```
 */
export function AISGridLayout({
  children,
  columns = 3,
  gap = AISSpacing.md,
  aspectRatio,
  padding = 0,
  shrinkWrap = false,
  className,
  style,
}: AISGridLayoutProps) {
  const gridStyle: React.CSSProperties = {
    display: 'grid',
    gridTemplateColumns: `repeat(${columns}, 1fr)`,
    gap: `${gap}px`,
    padding: typeof padding === 'number' ? `${padding}px` : padding,
    ...style,
  };

  // If aspect ratio is provided, we need to wrap children
  const wrappedChildren = aspectRatio
    ? React.Children.map(children, (child, index) => (
        <div
          key={index}
          style={{
            position: 'relative',
            paddingBottom: `${(1 / aspectRatio) * 100}%`,
          }}
        >
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
            }}
          >
            {child}
          </div>
        </div>
      ))
    : children;

  return (
    <div className={clsx(shrinkWrap && 'w-fit', className)} style={gridStyle}>
      {wrappedChildren}
    </div>
  );
}

// ============================================================================
// AISAdaptiveGridLayout Component
// ============================================================================

/**
 * Adaptive grid layout that adjusts columns based on container width
 *
 * @example
 * ```tsx
 * <AISAdaptiveGridLayout minChildWidth={200} gap={16}>
 *   <Card>Item 1</Card>
 *   <Card>Item 2</Card>
 *   <Card>Item 3</Card>
 *   <Card>Item 4</Card>
 * </AISAdaptiveGridLayout>
 * ```
 */
export function AISAdaptiveGridLayout({
  children,
  minChildWidth = 200,
  maxColumns = 12,
  gap = AISSpacing.md,
  aspectRatio,
  padding = 0,
  className,
  style,
}: AISAdaptiveGridLayoutProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [columns, setColumns] = useState(3);

  useEffect(() => {
    const updateColumns = () => {
      if (!containerRef.current) return;

      const paddingValue =
        typeof padding === 'number'
          ? padding * 2
          : parseInt(padding.split(' ')[0] || '0', 10) * 2;

      const containerWidth =
        containerRef.current.offsetWidth - paddingValue;
      const calculatedColumns = Math.floor(containerWidth / minChildWidth);
      const clampedColumns = Math.max(1, Math.min(calculatedColumns, maxColumns));
      setColumns(clampedColumns);
    };

    updateColumns();

    const resizeObserver = new ResizeObserver(updateColumns);
    if (containerRef.current) {
      resizeObserver.observe(containerRef.current);
    }

    return () => {
      resizeObserver.disconnect();
    };
  }, [minChildWidth, maxColumns, padding]);

  const gridStyle: React.CSSProperties = {
    display: 'grid',
    gridTemplateColumns: `repeat(${columns}, 1fr)`,
    gap: `${gap}px`,
    padding: typeof padding === 'number' ? `${padding}px` : padding,
    ...style,
  };

  // If aspect ratio is provided, wrap children
  const wrappedChildren = aspectRatio
    ? React.Children.map(children, (child, index) => (
        <div
          key={index}
          style={{
            position: 'relative',
            paddingBottom: `${(1 / aspectRatio) * 100}%`,
          }}
        >
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
            }}
          >
            {child}
          </div>
        </div>
      ))
    : children;

  return (
    <div ref={containerRef} className={className} style={gridStyle}>
      {wrappedChildren}
    </div>
  );
}

// ============================================================================
// AISMasonryLayout Component
// ============================================================================

export interface AISMasonryLayoutProps {
  /** Grid children */
  children: React.ReactNode;
  /** Number of columns */
  columns?: number;
  /** Gap between items in pixels */
  gap?: number;
  /** CSS class name */
  className?: string;
  /** Inline styles */
  style?: React.CSSProperties;
}

/**
 * Masonry-style grid layout (Pinterest-like)
 * Items are arranged in columns with varying heights
 *
 * @example
 * ```tsx
 * <AISMasonryLayout columns={3} gap={16}>
 *   <Card style={{ height: 200 }}>Item 1</Card>
 *   <Card style={{ height: 300 }}>Item 2</Card>
 *   <Card style={{ height: 150 }}>Item 3</Card>
 * </AISMasonryLayout>
 * ```
 */
export function AISMasonryLayout({
  children,
  columns = 3,
  gap = AISSpacing.md,
  className,
  style,
}: AISMasonryLayoutProps) {
  // Distribute children across columns
  const childArray = React.Children.toArray(children);
  const columnArrays: React.ReactNode[][] = Array.from(
    { length: columns },
    () => []
  );

  childArray.forEach((child, index) => {
    columnArrays[index % columns].push(child);
  });

  return (
    <div
      className={className}
      style={{
        display: 'flex',
        gap: `${gap}px`,
        ...style,
      }}
    >
      {columnArrays.map((columnChildren, colIndex) => (
        <div
          key={colIndex}
          style={{
            flex: 1,
            display: 'flex',
            flexDirection: 'column',
            gap: `${gap}px`,
          }}
        >
          {columnChildren}
        </div>
      ))}
    </div>
  );
}

// ============================================================================
// AISGridItem Component
// ============================================================================

export interface AISGridItemProps {
  /** Item children */
  children: React.ReactNode;
  /** Column span */
  colSpan?: number;
  /** Row span */
  rowSpan?: number;
  /** CSS class name */
  className?: string;
  /** Inline styles */
  style?: React.CSSProperties;
}

/**
 * Grid item with column/row span support
 *
 * @example
 * ```tsx
 * <AISGridLayout columns={4}>
 *   <AISGridItem colSpan={2}>Wide item</AISGridItem>
 *   <AISGridItem>Normal item</AISGridItem>
 *   <AISGridItem rowSpan={2}>Tall item</AISGridItem>
 * </AISGridLayout>
 * ```
 */
export function AISGridItem({
  children,
  colSpan = 1,
  rowSpan = 1,
  className,
  style,
}: AISGridItemProps) {
  return (
    <div
      className={className}
      style={{
        gridColumn: `span ${colSpan}`,
        gridRow: `span ${rowSpan}`,
        ...style,
      }}
    >
      {children}
    </div>
  );
}

// ============================================================================
// AISAutoGrid Component (CSS-only auto-fit solution)
// ============================================================================

export interface AISAutoGridProps {
  /** Grid children */
  children: React.ReactNode;
  /** Minimum width for each child (CSS value like '200px' or '15rem') */
  minWidth?: string;
  /** Gap between items (CSS value) */
  gap?: string | number;
  /** Padding around the grid */
  padding?: string | number;
  /** CSS class name */
  className?: string;
  /** Inline styles */
  style?: React.CSSProperties;
}

/**
 * Auto-fit grid using CSS Grid's auto-fit feature
 * Pure CSS solution without JavaScript resize observers
 *
 * @example
 * ```tsx
 * <AISAutoGrid minWidth="250px" gap={16}>
 *   <Card>Item 1</Card>
 *   <Card>Item 2</Card>
 *   <Card>Item 3</Card>
 * </AISAutoGrid>
 * ```
 */
export function AISAutoGrid({
  children,
  minWidth = '200px',
  gap = AISSpacing.md,
  padding = 0,
  className,
  style,
}: AISAutoGridProps) {
  const gapValue = typeof gap === 'number' ? `${gap}px` : gap;
  const paddingValue = typeof padding === 'number' ? `${padding}px` : padding;

  return (
    <div
      className={className}
      style={{
        display: 'grid',
        gridTemplateColumns: `repeat(auto-fit, minmax(${minWidth}, 1fr))`,
        gap: gapValue,
        padding: paddingValue,
        ...style,
      }}
    >
      {children}
    </div>
  );
}

export default AISGridLayout;

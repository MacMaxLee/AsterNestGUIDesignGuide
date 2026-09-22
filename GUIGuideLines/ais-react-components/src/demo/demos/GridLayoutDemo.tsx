/**
 * GridLayoutDemo.tsx
 * Demo page for AISGridLayout components
 */

import { useState } from 'react';
import { useAISTokens } from '../../core/AISProvider';
import {
  AISGridLayout,
  AISAdaptiveGridLayout,
  AISMasonryLayout,
  AISGridItem,
  AISAutoGrid,
} from '../../components/AISGridLayout';

// Sample card component for demos
function DemoCard({
  children,
  height,
  color,
}: {
  children: React.ReactNode;
  height?: number | string;
  color?: string;
}) {
  const tokens = useAISTokens();

  return (
    <div
      className="rounded-lg p-4 flex items-center justify-center font-medium"
      style={{
        backgroundColor: color || tokens.surface,
        border: `1px solid ${tokens.onSurface}20`,
        height: height || 'auto',
        minHeight: height ? undefined : 100,
        color: tokens.onSurface,
      }}
    >
      {children}
    </div>
  );
}

function GridLayoutDemo() {
  const tokens = useAISTokens();
  const [columns, setColumns] = useState(3);

  return (
    <div className="p-6 space-y-8">
      <div>
        <h1
          className="text-2xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Grid Layout
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Responsive grid layout components for arranging items in flexible grids.
          Supports fixed columns, adaptive layouts, masonry grids, and more.
        </p>
      </div>

      {/* Fixed Grid */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Fixed Column Grid
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Basic grid with fixed number of columns.
        </p>

        <div className="flex items-center gap-4 mb-4">
          <span style={{ color: tokens.onSurfaceSecondary }}>Columns:</span>
          {[2, 3, 4, 5].map((n) => (
            <button
              key={n}
              onClick={() => setColumns(n)}
              className="px-3 py-1 rounded text-sm"
              style={{
                backgroundColor:
                  columns === n ? tokens.actionPrimary.color : tokens.surface,
                color:
                  columns === n
                    ? '#FFFFFF'
                    : tokens.onSurface,
              }}
            >
              {n}
            </button>
          ))}
        </div>

        <AISGridLayout columns={columns} gap={16}>
          {Array.from({ length: 8 }).map((_, i) => (
            <DemoCard key={i}>Item {i + 1}</DemoCard>
          ))}
        </AISGridLayout>
      </section>

      {/* Adaptive Grid */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Adaptive Grid
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Automatically adjusts columns based on container width (min 200px per item).
          Resize the window to see the grid adapt.
        </p>

        <AISAdaptiveGridLayout minChildWidth={200} gap={16} maxColumns={6}>
          {Array.from({ length: 12 }).map((_, i) => (
            <DemoCard key={i}>Card {i + 1}</DemoCard>
          ))}
        </AISAdaptiveGridLayout>
      </section>

      {/* Auto Grid (CSS-only) */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Auto Grid (CSS-only)
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Uses CSS Grid auto-fit for a pure CSS responsive solution.
        </p>

        <AISAutoGrid minWidth="180px" gap={16}>
          {Array.from({ length: 9 }).map((_, i) => (
            <DemoCard key={i}>Auto {i + 1}</DemoCard>
          ))}
        </AISAutoGrid>
      </section>

      {/* Grid with Aspect Ratio */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Grid with Aspect Ratio
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Fixed aspect ratio (16:9) for all grid items.
        </p>

        <AISGridLayout columns={4} gap={16} aspectRatio={16 / 9}>
          {Array.from({ length: 8 }).map((_, i) => (
            <DemoCard key={i}>16:9</DemoCard>
          ))}
        </AISGridLayout>
      </section>

      {/* Grid Items with Span */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Grid Items with Span
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Items can span multiple columns or rows.
        </p>

        <AISGridLayout columns={4} gap={16}>
          <AISGridItem colSpan={2}>
            <DemoCard>Span 2 cols</DemoCard>
          </AISGridItem>
          <AISGridItem>
            <DemoCard>Normal</DemoCard>
          </AISGridItem>
          <AISGridItem rowSpan={2}>
            <DemoCard height="100%">Span 2 rows</DemoCard>
          </AISGridItem>
          <AISGridItem>
            <DemoCard>Normal</DemoCard>
          </AISGridItem>
          <AISGridItem colSpan={2}>
            <DemoCard>Span 2 cols</DemoCard>
          </AISGridItem>
          <AISGridItem>
            <DemoCard>Normal</DemoCard>
          </AISGridItem>
          <AISGridItem colSpan={3}>
            <DemoCard>Span 3 cols</DemoCard>
          </AISGridItem>
        </AISGridLayout>
      </section>

      {/* Masonry Layout */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Masonry Layout
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Pinterest-style layout with varying item heights.
        </p>

        <AISMasonryLayout columns={4} gap={16}>
          {[120, 200, 150, 180, 100, 220, 160, 140, 190, 130, 170, 210].map(
            (height, i) => (
              <DemoCard key={i} height={height}>
                Item {i + 1}
              </DemoCard>
            )
          )}
        </AISMasonryLayout>
      </section>

      {/* Card Gallery Example */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Real World: Image Gallery
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Example of a responsive image gallery with hover effects.
        </p>

        <AISAdaptiveGridLayout minChildWidth={240} gap={16} aspectRatio={4 / 3}>
          {Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className="rounded-lg overflow-hidden cursor-pointer transition-transform hover:scale-105"
              style={{
                backgroundColor: tokens.surface,
                border: `1px solid ${tokens.onSurface}20`,
              }}
            >
              <div
                className="h-full flex flex-col"
                style={{ backgroundColor: `hsl(${i * 50}, 70%, 85%)` }}
              >
                <div className="flex-1 flex items-center justify-center">
                  <span className="text-4xl opacity-30">🖼️</span>
                </div>
                <div
                  className="p-3"
                  style={{ backgroundColor: tokens.surface }}
                >
                  <p
                    className="text-sm font-medium"
                    style={{ color: tokens.onSurface }}
                  >
                    Photo {i + 1}
                  </p>
                  <p
                    className="text-xs"
                    style={{ color: tokens.onSurfaceSecondary }}
                  >
                    Gallery item
                  </p>
                </div>
              </div>
            </div>
          ))}
        </AISAdaptiveGridLayout>
      </section>

      {/* API Reference */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          API Reference
        </h2>

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr
                style={{
                  borderBottom: `1px solid ${tokens.onSurface}20`,
                }}
              >
                <th className="text-left py-2 font-semibold">Component</th>
                <th className="text-left py-2 font-semibold">Key Props</th>
                <th className="text-left py-2 font-semibold">Description</th>
              </tr>
            </thead>
            <tbody style={{ color: tokens.onSurfaceSecondary }}>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">AISGridLayout</td>
                <td className="py-2 font-mono text-xs">columns, gap, aspectRatio</td>
                <td className="py-2">Fixed column grid layout</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">AISAdaptiveGridLayout</td>
                <td className="py-2 font-mono text-xs">minChildWidth, maxColumns</td>
                <td className="py-2">Adaptive grid using ResizeObserver</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">AISAutoGrid</td>
                <td className="py-2 font-mono text-xs">minWidth, gap</td>
                <td className="py-2">CSS-only auto-fit grid</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">AISMasonryLayout</td>
                <td className="py-2 font-mono text-xs">columns, gap</td>
                <td className="py-2">Pinterest-style masonry layout</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">AISGridItem</td>
                <td className="py-2 font-mono text-xs">colSpan, rowSpan</td>
                <td className="py-2">Grid item with column/row span</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

export default GridLayoutDemo;

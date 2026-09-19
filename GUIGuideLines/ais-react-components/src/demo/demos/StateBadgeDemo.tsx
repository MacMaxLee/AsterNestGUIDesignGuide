import React from 'react';
import {
  AISStateBadge,
  AISStateBadgeGroup,
  AISStateProgress,
} from '../../components/AISStateBadge';
import { useAISTokens } from '../../core/AISProvider';
import type { AISBadgeState } from '../../core/tokens';

export function StateBadgeDemo() {
  const tokens = useAISTokens();

  const allStates: AISBadgeState[] = [
    'draft',
    'pending',
    'active',
    'completed',
    'archived',
    'error',
    'warning',
    'inactive',
  ];

  return (
    <div className="space-y-12">
      {/* Header */}
      <div>
        <h1
          className="text-3xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          AISStateBadge
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Visual indicators for item lifecycle states.
          Always pairs color + icon for accessibility (AIS §2.3).
        </p>
      </div>

      {/* All States */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Semantic States
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Each state has a semantic meaning and consistent visual treatment.
        </p>

        <div className="flex flex-wrap gap-3">
          {allStates.map((state) => (
            <AISStateBadge key={state} state={state} />
          ))}
        </div>
      </section>

      {/* Styles */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Badge Styles
        </h2>

        <div className="space-y-6">
          <div>
            <h3 className="text-sm font-medium mb-3" style={{ color: tokens.onSurfaceSecondary }}>
              Standard (Default)
            </h3>
            <div className="flex flex-wrap gap-3">
              <AISStateBadge state="active" style="standard" />
              <AISStateBadge state="pending" style="standard" />
              <AISStateBadge state="error" style="standard" />
            </div>
          </div>

          <div>
            <h3 className="text-sm font-medium mb-3" style={{ color: tokens.onSurfaceSecondary }}>
              Pill
            </h3>
            <div className="flex flex-wrap gap-3">
              <AISStateBadge state="active" style="pill" />
              <AISStateBadge state="pending" style="pill" />
              <AISStateBadge state="error" style="pill" />
            </div>
          </div>

          <div>
            <h3 className="text-sm font-medium mb-3" style={{ color: tokens.onSurfaceSecondary }}>
              Outlined
            </h3>
            <div className="flex flex-wrap gap-3">
              <AISStateBadge state="active" style="outlined" />
              <AISStateBadge state="pending" style="outlined" />
              <AISStateBadge state="error" style="outlined" />
            </div>
          </div>

          <div>
            <h3 className="text-sm font-medium mb-3" style={{ color: tokens.onSurfaceSecondary }}>
              Compact (Icon Only)
            </h3>
            <div className="flex flex-wrap gap-3">
              {allStates.map((state) => (
                <AISStateBadge key={state} state={state} style="compact" />
              ))}
            </div>
          </div>

          <div>
            <h3 className="text-sm font-medium mb-3" style={{ color: tokens.onSurfaceSecondary }}>
              Dot (Minimal)
            </h3>
            <div className="flex flex-wrap gap-4">
              <AISStateBadge state="active" style="dot" />
              <AISStateBadge state="pending" style="dot" />
              <AISStateBadge state="error" style="dot" />
            </div>
          </div>
        </div>
      </section>

      {/* Sizes */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Sizes
        </h2>

        <div className="flex flex-wrap items-center gap-4">
          <AISStateBadge state="active" size="small" />
          <AISStateBadge state="active" size="medium" />
          <AISStateBadge state="active" size="large" />
        </div>
      </section>

      {/* Custom Labels */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Custom Labels
        </h2>

        <div className="flex flex-wrap gap-3">
          <AISStateBadge state="active" label="Published" style="pill" />
          <AISStateBadge state="pending" label="Awaiting Review" style="pill" />
          <AISStateBadge state="completed" label="Approved" style="pill" />
        </div>
      </section>

      {/* Badge Group */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Badge Group
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Display multiple state badges together.
        </p>

        <AISStateBadgeGroup
          states={['active', 'warning']}
          style="pill"
        />
      </section>

      {/* State Progress */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          State Progress
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Show progression through ordered states.
        </p>

        <div className="space-y-6">
          <div>
            <p className="text-sm mb-2" style={{ color: tokens.onSurfaceSecondary }}>
              Current: Draft
            </p>
            <AISStateProgress
              states={['draft', 'pending', 'active', 'completed']}
              currentState="draft"
            />
          </div>

          <div>
            <p className="text-sm mb-2" style={{ color: tokens.onSurfaceSecondary }}>
              Current: Pending
            </p>
            <AISStateProgress
              states={['draft', 'pending', 'active', 'completed']}
              currentState="pending"
            />
          </div>

          <div>
            <p className="text-sm mb-2" style={{ color: tokens.onSurfaceSecondary }}>
              Current: Completed
            </p>
            <AISStateProgress
              states={['draft', 'pending', 'active', 'completed']}
              currentState="completed"
            />
          </div>
        </div>
      </section>

      {/* Usage Example */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Usage in Context
        </h2>

        <div
          className="p-4 rounded-lg"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          <div className="space-y-3">
            {[
              { title: 'Project Alpha', status: 'active' as const },
              { title: 'Project Beta', status: 'pending' as const },
              { title: 'Project Gamma', status: 'completed' as const },
              { title: 'Project Delta', status: 'draft' as const },
            ].map((item) => (
              <div
                key={item.title}
                className="flex items-center justify-between p-3 rounded-lg"
                style={{ backgroundColor: tokens.surface }}
              >
                <span style={{ color: tokens.onSurface }}>{item.title}</span>
                <AISStateBadge state={item.status} style="pill" size="small" />
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}

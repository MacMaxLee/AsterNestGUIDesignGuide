/**
 * AISStateBadge Component
 *
 * Visual indicators for item lifecycle states.
 * Always pairs color + icon for accessibility (AIS §2.3).
 */

import React from 'react';
import clsx from 'clsx';
import {
  FileText,
  Clock,
  CheckCircle,
  CheckCircle2,
  Archive,
  AlertCircle,
  AlertTriangle,
  PauseCircle,
  type LucideIcon,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';
import type { AISBadgeState } from '../core/tokens';

// =============================================================================
// TYPES
// =============================================================================

export type AISBadgeStyle = 'standard' | 'compact' | 'pill' | 'outlined' | 'dot';
export type AISBadgeSize = 'small' | 'medium' | 'large';

export interface AISStateBadgeProps {
  /** Semantic state */
  state: AISBadgeState;
  /** Visual style */
  style?: AISBadgeStyle;
  /** Badge size */
  size?: AISBadgeSize;
  /** Custom label (overrides default state label) */
  label?: string;
  /** Additional CSS classes */
  className?: string;
}

// =============================================================================
// STATE CONFIGURATION
// =============================================================================

interface StateConfig {
  icon: LucideIcon;
  defaultLabel: string;
}

const stateConfigs: Record<AISBadgeState, StateConfig> = {
  draft: { icon: FileText, defaultLabel: 'Draft' },
  pending: { icon: Clock, defaultLabel: 'Pending' },
  active: { icon: CheckCircle, defaultLabel: 'Active' },
  completed: { icon: CheckCircle2, defaultLabel: 'Completed' },
  archived: { icon: Archive, defaultLabel: 'Archived' },
  error: { icon: AlertCircle, defaultLabel: 'Error' },
  warning: { icon: AlertTriangle, defaultLabel: 'Warning' },
  inactive: { icon: PauseCircle, defaultLabel: 'Inactive' },
};

// =============================================================================
// SIZE CLASSES
// =============================================================================

const sizeClasses: Record<AISBadgeSize, { text: string; icon: number; padding: string }> = {
  small: { text: 'text-xs', icon: 12, padding: 'px-1.5 py-0.5' },
  medium: { text: 'text-sm', icon: 14, padding: 'px-2 py-1' },
  large: { text: 'text-base', icon: 18, padding: 'px-3 py-1.5' },
};

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * AISStateBadge - State indicator following AIS v1.0
 *
 * @example
 * ```tsx
 * // Basic usage
 * <AISStateBadge state="active" />
 *
 * // Pill style with custom label
 * <AISStateBadge state="pending" style="pill" label="Awaiting Review" />
 *
 * // Compact (icon only)
 * <AISStateBadge state="error" style="compact" />
 * ```
 */
export function AISStateBadge({
  state,
  style = 'standard',
  size = 'medium',
  label,
  className,
}: AISStateBadgeProps) {
  const tokens = useAISTokens();
  const config = stateConfigs[state];
  const badgeToken = tokens.badgeStates[state];
  const sizeConfig = sizeClasses[size];
  const IconComponent = config.icon;
  const displayLabel = label || config.defaultLabel;

  // Get appropriate styles based on variant
  const getStyles = (): React.CSSProperties => {
    const color = badgeToken.color;

    switch (style) {
      case 'standard':
        return {
          backgroundColor: `${color}20`,
          color: color,
        };
      case 'compact':
        return {
          color: color,
        };
      case 'pill':
        return {
          backgroundColor: color,
          color: '#FFFFFF',
        };
      case 'outlined':
        return {
          backgroundColor: 'transparent',
          color: color,
          border: `1.5px solid ${color}`,
        };
      case 'dot':
        return {
          color: color,
        };
      default:
        return {};
    }
  };

  // Dot style - minimal circle indicator
  if (style === 'dot') {
    return (
      <span
        className={clsx('inline-flex items-center gap-1.5', sizeConfig.text, className)}
        role="status"
        aria-label={displayLabel}
      >
        <span
          className="rounded-full"
          style={{
            backgroundColor: badgeToken.color,
            width: sizeConfig.icon * 0.6,
            height: sizeConfig.icon * 0.6,
          }}
          aria-hidden="true"
        />
        <span style={{ color: tokens.onSurface }}>{displayLabel}</span>
      </span>
    );
  }

  // Compact style - icon only
  if (style === 'compact') {
    return (
      <span
        className={clsx('inline-flex items-center justify-center', className)}
        style={getStyles()}
        role="status"
        aria-label={displayLabel}
        title={displayLabel}
      >
        <IconComponent size={sizeConfig.icon} aria-hidden="true" />
      </span>
    );
  }

  return (
    <span
      className={clsx(
        'inline-flex items-center gap-1.5 font-medium',
        sizeConfig.text,
        sizeConfig.padding,
        style === 'pill' ? 'rounded-full' : 'rounded-md',
        className
      )}
      style={getStyles()}
      role="status"
      aria-label={displayLabel}
    >
      <IconComponent size={sizeConfig.icon} aria-hidden="true" />
      <span>{displayLabel}</span>
    </span>
  );
}

// =============================================================================
// BADGE GROUP
// =============================================================================

export interface AISStateBadgeGroupProps {
  /** Array of states to display */
  states: AISBadgeState[];
  /** Visual style for all badges */
  style?: AISBadgeStyle;
  /** Badge size */
  size?: AISBadgeSize;
  /** Additional CSS classes */
  className?: string;
}

/**
 * AISStateBadgeGroup - Display multiple state badges together
 *
 * @example
 * ```tsx
 * <AISStateBadgeGroup states={['active', 'pending']} style="pill" />
 * ```
 */
export function AISStateBadgeGroup({
  states,
  style = 'standard',
  size = 'medium',
  className,
}: AISStateBadgeGroupProps) {
  return (
    <div className={clsx('inline-flex items-center gap-2', className)}>
      {states.map((state, index) => (
        <AISStateBadge key={`${state}-${index}`} state={state} style={style} size={size} />
      ))}
    </div>
  );
}

// =============================================================================
// STATE PROGRESS
// =============================================================================

export interface AISStateProgressProps {
  /** Ordered array of states */
  states: AISBadgeState[];
  /** Current active state */
  currentState: AISBadgeState;
  /** Badge size */
  size?: AISBadgeSize;
  /** Additional CSS classes */
  className?: string;
}

/**
 * AISStateProgress - Show progression through states
 *
 * @example
 * ```tsx
 * <AISStateProgress
 *   states={['draft', 'pending', 'active', 'completed']}
 *   currentState="pending"
 * />
 * ```
 */
export function AISStateProgress({
  states,
  currentState,
  size = 'medium',
  className,
}: AISStateProgressProps) {
  const tokens = useAISTokens();
  const currentIndex = states.indexOf(currentState);
  const sizeConfig = sizeClasses[size];

  return (
    <div className={clsx('inline-flex items-center', className)}>
      {states.map((state, index) => {
        const config = stateConfigs[state];
        const badgeToken = tokens.badgeStates[state];
        const IconComponent = config.icon;
        const isPast = index < currentIndex;
        const isCurrent = index === currentIndex;
        const isFuture = index > currentIndex;

        return (
          <React.Fragment key={state}>
            {index > 0 && (
              <div
                className="h-0.5 w-8 mx-1"
                style={{
                  backgroundColor: isPast
                    ? tokens.badgeStates.completed.color
                    : tokens.onSurfaceSecondary + '40',
                }}
              />
            )}
            <div
              className={clsx(
                'inline-flex items-center justify-center rounded-full',
                isCurrent ? 'ring-2 ring-offset-2' : ''
              )}
              style={{
                width: sizeConfig.icon * 2,
                height: sizeConfig.icon * 2,
                backgroundColor: isFuture
                  ? tokens.surfaceSecondary
                  : isCurrent
                  ? badgeToken.color
                  : tokens.badgeStates.completed.color,
                color: isFuture ? tokens.onSurfaceSecondary : '#FFFFFF',
                '--tw-ring-color': isCurrent ? badgeToken.color : undefined,
              } as React.CSSProperties}
              title={config.defaultLabel}
              aria-current={isCurrent ? 'step' : undefined}
            >
              <IconComponent size={sizeConfig.icon} aria-hidden="true" />
            </div>
          </React.Fragment>
        );
      })}
    </div>
  );
}

export default AISStateBadge;

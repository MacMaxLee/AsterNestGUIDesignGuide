/**
 * AIS (Asternest Interface Standard) v1.0 Design Tokens
 *
 * This file defines the semantic design tokens as specified in AIS §2.
 * Tokens fix meaning, not appearance - each app customizes the palette.
 */

// =============================================================================
// SPACING TOKENS (8-point grid)
// =============================================================================

export const AISSpacing = {
  xs: 4,    // 4pt
  sm: 8,    // 8pt
  md: 16,   // 16pt (base)
  lg: 24,   // 24pt
  xl: 32,   // 32pt
  xxl: 48,  // 48pt
} as const;

export type AISSpacingKey = keyof typeof AISSpacing;

// =============================================================================
// RADIUS TOKENS
// =============================================================================

export const AISRadius = {
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  full: 9999,
} as const;

export type AISRadiusKey = keyof typeof AISRadius;

// =============================================================================
// SEMANTIC ACTION TYPES (AIS §2.2)
// =============================================================================

/**
 * Semantic button/action types as defined in AIS §2.2
 * These define MEANING, not appearance.
 */
export type AISActionType =
  | 'primary'      // Main forward action
  | 'confirm'      // Approval, authorization, acceptance
  | 'destructive'  // Irreversible or data-removing
  | 'caution'      // Consequential or externally visible
  | 'neutral'      // Non-committal — cancel, close, back
  | 'secondary';   // Lower prominence alternatives

// =============================================================================
// SEMANTIC STATE TYPES (AIS §2.2)
// =============================================================================

/**
 * Semantic state types as defined in AIS §2.2
 */
export type AISStateType =
  | 'info'         // Informational, non-blocking
  | 'warning'      // Needs attention, not yet an error
  | 'error'        // Failed or invalid
  | 'unavailable'; // Cannot be computed or does not apply

// =============================================================================
// ERROR SEVERITY (for error handling components)
// =============================================================================

export type AISErrorSeverity = 'info' | 'warning' | 'error' | 'critical';

// =============================================================================
// BADGE/STATUS STATES
// =============================================================================

export type AISBadgeState =
  | 'draft'      // Work in progress
  | 'pending'    // Awaiting action
  | 'active'     // Currently live
  | 'completed'  // Successfully finished
  | 'archived'   // Retained but inactive
  | 'error'      // Error state
  | 'warning'    // Needs attention
  | 'inactive';  // Disabled

// =============================================================================
// TOKEN INTERFACE
// =============================================================================

export interface AISToken {
  color: string;
  iconName: string;
  label: string;
}

// =============================================================================
// DEFAULT LIGHT THEME TOKENS
// =============================================================================

export const defaultLightTheme = {
  // Actions
  actionPrimary: {
    color: '#2563EB',
    iconName: 'arrow-right',
    label: 'Primary',
  },
  actionConfirm: {
    color: '#16A34A',
    iconName: 'check',
    label: 'Confirm',
  },
  actionDestructive: {
    color: '#DC2626',
    iconName: 'trash-2',
    label: 'Destructive',
  },
  actionCaution: {
    color: '#EA580C',
    iconName: 'alert-triangle',
    label: 'Caution',
  },
  actionNeutral: {
    color: '#6B7280',
    iconName: 'x',
    label: 'Neutral',
  },
  actionSecondary: {
    color: '#4B5563',
    iconName: 'minus',
    label: 'Secondary',
  },

  // States
  stateInfo: {
    color: '#2563EB',
    iconName: 'info',
    label: 'Info',
  },
  stateWarning: {
    color: '#F59E0B',
    iconName: 'alert-triangle',
    label: 'Warning',
  },
  stateError: {
    color: '#DC2626',
    iconName: 'alert-circle',
    label: 'Error',
  },
  stateUnavailable: {
    color: '#9CA3AF',
    iconName: 'minus-circle',
    label: 'Unavailable',
  },

  // Surfaces
  surface: '#FFFFFF',
  surfaceSecondary: '#F3F4F6',
  onSurface: '#111827',
  onSurfaceSecondary: '#6B7280',

  // Badge states
  badgeStates: {
    draft: { color: '#6B7280', iconName: 'file-text' },
    pending: { color: '#F59E0B', iconName: 'clock' },
    active: { color: '#16A34A', iconName: 'check-circle' },
    completed: { color: '#2563EB', iconName: 'check-circle-2' },
    archived: { color: '#9CA3AF', iconName: 'archive' },
    error: { color: '#DC2626', iconName: 'alert-circle' },
    warning: { color: '#F59E0B', iconName: 'alert-triangle' },
    inactive: { color: '#9CA3AF', iconName: 'pause-circle' },
  },
} as const;

// =============================================================================
// DEFAULT DARK THEME TOKENS
// =============================================================================

export const defaultDarkTheme = {
  // Actions (slightly lighter for dark backgrounds)
  actionPrimary: {
    color: '#3B82F6',
    iconName: 'arrow-right',
    label: 'Primary',
  },
  actionConfirm: {
    color: '#22C55E',
    iconName: 'check',
    label: 'Confirm',
  },
  actionDestructive: {
    color: '#EF4444',
    iconName: 'trash-2',
    label: 'Destructive',
  },
  actionCaution: {
    color: '#F97316',
    iconName: 'alert-triangle',
    label: 'Caution',
  },
  actionNeutral: {
    color: '#9CA3AF',
    iconName: 'x',
    label: 'Neutral',
  },
  actionSecondary: {
    color: '#D1D5DB',
    iconName: 'minus',
    label: 'Secondary',
  },

  // States
  stateInfo: {
    color: '#3B82F6',
    iconName: 'info',
    label: 'Info',
  },
  stateWarning: {
    color: '#FBBF24',
    iconName: 'alert-triangle',
    label: 'Warning',
  },
  stateError: {
    color: '#EF4444',
    iconName: 'alert-circle',
    label: 'Error',
  },
  stateUnavailable: {
    color: '#6B7280',
    iconName: 'minus-circle',
    label: 'Unavailable',
  },

  // Surfaces
  surface: '#1F2937',
  surfaceSecondary: '#111827',
  onSurface: '#F9FAFB',
  onSurfaceSecondary: '#9CA3AF',

  // Badge states
  badgeStates: {
    draft: { color: '#9CA3AF', iconName: 'file-text' },
    pending: { color: '#FBBF24', iconName: 'clock' },
    active: { color: '#22C55E', iconName: 'check-circle' },
    completed: { color: '#3B82F6', iconName: 'check-circle-2' },
    archived: { color: '#6B7280', iconName: 'archive' },
    error: { color: '#EF4444', iconName: 'alert-circle' },
    warning: { color: '#FBBF24', iconName: 'alert-triangle' },
    inactive: { color: '#6B7280', iconName: 'pause-circle' },
  },
} as const;

export type AISTheme = typeof defaultLightTheme;

/**
 * AIS Provider Component
 *
 * Provides AIS design tokens to all child components via React Context.
 * This is required for all AIS components to function properly.
 */

import React, { createContext, useContext, useMemo } from 'react';
import { AISTheme, defaultLightTheme, defaultDarkTheme } from './tokens';

// =============================================================================
// CONTEXT
// =============================================================================

interface AISContextValue {
  theme: AISTheme;
  isDarkMode: boolean;
}

const AISContext = createContext<AISContextValue | null>(null);

// =============================================================================
// HOOK
// =============================================================================

/**
 * Hook to access AIS design tokens.
 * Must be used within an AISProvider.
 */
export function useAISTokens(): AISTheme {
  const context = useContext(AISContext);
  if (!context) {
    throw new Error('useAISTokens must be used within an AISProvider');
  }
  return context.theme;
}

/**
 * Hook to check if dark mode is active.
 */
export function useAISDarkMode(): boolean {
  const context = useContext(AISContext);
  if (!context) {
    throw new Error('useAISDarkMode must be used within an AISProvider');
  }
  return context.isDarkMode;
}

// =============================================================================
// PROVIDER COMPONENT
// =============================================================================

interface AISProviderProps {
  children: React.ReactNode;
  /** Custom theme overrides */
  theme?: Partial<AISTheme>;
  /** Enable dark mode */
  darkMode?: boolean;
}

/**
 * AIS Provider - Wraps your app to provide AIS design tokens.
 *
 * @example
 * ```tsx
 * function App() {
 *   return (
 *     <AISProvider>
 *       <MyComponent />
 *     </AISProvider>
 *   );
 * }
 * ```
 */
export function AISProvider({
  children,
  theme: customTheme,
  darkMode = false,
}: AISProviderProps) {
  const baseTheme = darkMode ? defaultDarkTheme : defaultLightTheme;

  const theme = useMemo(() => ({
    ...baseTheme,
    ...customTheme,
  }), [baseTheme, customTheme]);

  const value = useMemo(() => ({
    theme,
    isDarkMode: darkMode,
  }), [theme, darkMode]);

  return (
    <AISContext.Provider value={value}>
      <div
        className="ais-root"
        style={{
          // CSS Custom Properties for AIS tokens
          '--ais-spacing-xs': '4px',
          '--ais-spacing-sm': '8px',
          '--ais-spacing-md': '16px',
          '--ais-spacing-lg': '24px',
          '--ais-spacing-xl': '32px',
          '--ais-spacing-xxl': '48px',

          '--ais-radius-sm': '4px',
          '--ais-radius-md': '8px',
          '--ais-radius-lg': '12px',
          '--ais-radius-xl': '16px',
          '--ais-radius-full': '9999px',

          '--ais-action-primary': theme.actionPrimary.color,
          '--ais-action-confirm': theme.actionConfirm.color,
          '--ais-action-destructive': theme.actionDestructive.color,
          '--ais-action-caution': theme.actionCaution.color,
          '--ais-action-neutral': theme.actionNeutral.color,
          '--ais-action-secondary': theme.actionSecondary.color,

          '--ais-state-info': theme.stateInfo.color,
          '--ais-state-warning': theme.stateWarning.color,
          '--ais-state-error': theme.stateError.color,
          '--ais-state-unavailable': theme.stateUnavailable.color,

          '--ais-surface': theme.surface,
          '--ais-surface-secondary': theme.surfaceSecondary,
          '--ais-on-surface': theme.onSurface,
          '--ais-on-surface-secondary': theme.onSurfaceSecondary,
        } as React.CSSProperties}
      >
        {children}
      </div>
    </AISContext.Provider>
  );
}

export default AISProvider;

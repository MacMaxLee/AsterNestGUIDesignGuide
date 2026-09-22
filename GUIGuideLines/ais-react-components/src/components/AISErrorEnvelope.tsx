/**
 * AISErrorEnvelope Component
 *
 * Standardized error handling and display following AIS error presentation guidelines.
 * Wraps operations that may fail and provides consistent error UI.
 *
 * KEY REQUIREMENTS:
 * 1. CONSISTENT ERROR DISPLAY: Same error format everywhere
 * 2. ERROR SEVERITY LEVELS: Different visual treatment for error types
 * 3. ACTIONABLE ERRORS: Provide retry/dismiss/report actions when appropriate
 * 4. ACCESSIBILITY: Error state must be announced to screen readers
 * 5. COPYABLE MESSAGES: All error messages must be selectable/copyable
 */

import React, { useState, useEffect } from 'react';
import clsx from 'clsx';
import {
  Info,
  AlertTriangle,
  AlertCircle,
  AlertOctagon,
  Loader2,
  X,
  Copy,
  Check,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';
import { AISButton } from './AISButton';
import type { AISErrorSeverity } from '../core/tokens';

// =============================================================================
// TYPES
// =============================================================================

export interface AISErrorAction {
  label: string;
  icon?: React.ReactNode;
  actionType?: 'primary' | 'confirm' | 'destructive' | 'caution' | 'neutral' | 'secondary';
  onClick: () => void;
}

export interface AISErrorInfo {
  title: string;
  message: string;
  severity: AISErrorSeverity;
  code?: string;
  technicalDetails?: string;
  actions?: AISErrorAction[];
}

export type AISLoadingState<T> =
  | { type: 'idle' }
  | { type: 'loading' }
  | { type: 'success'; data: T }
  | { type: 'failure'; error: AISErrorInfo };

// =============================================================================
// COMMON ERROR CONSTRUCTORS
// =============================================================================

export const AISErrors = {
  networkError: (onRetry?: () => void, onDismiss?: () => void): AISErrorInfo => ({
    title: 'Connection Failed',
    message: 'Unable to connect to the server. Please check your internet connection and try again.',
    severity: 'error',
    code: 'NET_001',
    actions: [
      ...(onRetry ? [{ label: 'Retry', actionType: 'primary' as const, onClick: onRetry }] : []),
      ...(onDismiss ? [{ label: 'Dismiss', actionType: 'neutral' as const, onClick: onDismiss }] : []),
    ],
  }),

  loadError: (message?: string, onRetry?: () => void): AISErrorInfo => ({
    title: 'Failed to Load',
    message: message || 'Unable to load the requested data. Please try again.',
    severity: 'error',
    code: 'LOAD_001',
    actions: onRetry ? [{ label: 'Retry', actionType: 'primary' as const, onClick: onRetry }] : [],
  }),

  authError: (onLogin?: () => void): AISErrorInfo => ({
    title: 'Session Expired',
    message: 'Your session has expired. Please log in again to continue.',
    severity: 'warning',
    code: 'AUTH_001',
    actions: onLogin ? [{ label: 'Log In', actionType: 'primary' as const, onClick: onLogin }] : [],
  }),

  validationError: (message: string, onDismiss?: () => void): AISErrorInfo => ({
    title: 'Validation Error',
    message,
    severity: 'warning',
    actions: onDismiss ? [{ label: 'Dismiss', actionType: 'neutral' as const, onClick: onDismiss }] : [],
  }),
};

// =============================================================================
// SEVERITY CONFIGURATION
// =============================================================================

interface SeverityConfig {
  icon: typeof Info;
  ariaRole: 'status' | 'alert';
}

const severityConfigs: Record<AISErrorSeverity, SeverityConfig> = {
  info: { icon: Info, ariaRole: 'status' },
  warning: { icon: AlertTriangle, ariaRole: 'alert' },
  error: { icon: AlertCircle, ariaRole: 'alert' },
  critical: { icon: AlertOctagon, ariaRole: 'alert' },
};

// =============================================================================
// ERROR VIEW COMPONENT
// =============================================================================

export interface AISErrorViewProps {
  error: AISErrorInfo;
  onRetry?: () => void;
  className?: string;
}

/**
 * AISErrorView - Standalone error display
 */
export function AISErrorView({ error, onRetry, className }: AISErrorViewProps) {
  const tokens = useAISTokens();
  const [showDetails, setShowDetails] = useState(false);
  const [copied, setCopied] = useState(false);

  const getSeverityToken = () => {
    switch (error.severity) {
      case 'info':
        return tokens.stateInfo;
      case 'warning':
        return tokens.stateWarning;
      case 'error':
        return tokens.stateError;
      case 'critical':
        return tokens.actionDestructive;
    }
  };

  const severityToken = getSeverityToken();
  const config = severityConfigs[error.severity];
  const IconComponent = config.icon;

  const handleCopy = async () => {
    const text = `${error.title}: ${error.message}${error.code ? ` (${error.code})` : ''}`;
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const actions = error.actions || (onRetry ? [{ label: 'Try Again', actionType: 'primary' as const, onClick: onRetry }] : []);

  return (
    <div
      className={clsx(
        'flex flex-col items-center justify-center p-8 text-center',
        className
      )}
      role={config.ariaRole}
      aria-live="polite"
    >
      {/* Icon */}
      <div
        className="mb-4"
        style={{ color: severityToken.color }}
      >
        <IconComponent size={48} aria-hidden="true" />
      </div>

      {/* Title */}
      <h3
        className="text-xl font-bold mb-2"
        style={{ color: tokens.onSurface }}
      >
        {error.title}
      </h3>

      {/* Message (copyable) */}
      <p
        className="max-w-md mb-4 select-all cursor-text"
        style={{ color: tokens.onSurfaceSecondary }}
      >
        {error.message}
      </p>

      {/* Error code */}
      {error.code && (
        <div className="flex items-center gap-2 mb-4">
          <code
            className="px-2 py-1 rounded text-sm font-mono select-all"
            style={{
              backgroundColor: tokens.surfaceSecondary,
              color: tokens.onSurfaceSecondary,
            }}
          >
            {error.code}
          </code>
          <button
            onClick={handleCopy}
            className="p-1 rounded hover:bg-opacity-10 transition-colors"
            style={{ color: tokens.onSurfaceSecondary }}
            aria-label="Copy error message"
            title="Copy error message"
          >
            {copied ? <Check size={16} /> : <Copy size={16} />}
          </button>
        </div>
      )}

      {/* Technical details (expandable) */}
      {error.technicalDetails && (
        <div className="w-full max-w-md mb-4">
          <button
            onClick={() => setShowDetails(!showDetails)}
            className="text-sm underline"
            style={{ color: tokens.onSurfaceSecondary }}
          >
            {showDetails ? 'Hide' : 'Show'} technical details
          </button>
          {showDetails && (
            <pre
              className="mt-2 p-3 rounded text-left text-xs font-mono overflow-auto select-all"
              style={{
                backgroundColor: tokens.surfaceSecondary,
                color: tokens.onSurfaceSecondary,
              }}
            >
              {error.technicalDetails}
            </pre>
          )}
        </div>
      )}

      {/* Actions */}
      {actions.length > 0 && (
        <div className="flex flex-wrap items-center justify-center gap-2">
          {actions.map((action, index) => (
            <AISButton
              key={index}
              actionType={action.actionType || 'primary'}
              onClick={action.onClick}
            >
              {action.label}
            </AISButton>
          ))}
        </div>
      )}
    </div>
  );
}

// =============================================================================
// INLINE ERROR COMPONENT
// =============================================================================

export interface AISInlineErrorProps {
  message: string;
  severity?: AISErrorSeverity;
  className?: string;
}

/**
 * AISInlineError - Compact error for form fields
 */
export function AISInlineError({
  message,
  severity = 'error',
  className,
}: AISInlineErrorProps) {
  const tokens = useAISTokens();

  const getSeverityToken = () => {
    switch (severity) {
      case 'info':
        return tokens.stateInfo;
      case 'warning':
        return tokens.stateWarning;
      case 'error':
        return tokens.stateError;
      case 'critical':
        return tokens.actionDestructive;
    }
  };

  const severityToken = getSeverityToken();
  const config = severityConfigs[severity];
  const IconComponent = config.icon;

  return (
    <div
      className={clsx('flex items-center gap-1.5 text-sm select-all', className)}
      style={{ color: severityToken.color }}
      role={config.ariaRole}
    >
      <IconComponent size={14} aria-hidden="true" />
      <span>{message}</span>
    </div>
  );
}

// =============================================================================
// ERROR BANNER COMPONENT
// =============================================================================

export interface AISErrorBannerProps {
  error: AISErrorInfo;
  onDismiss: () => void;
  autoDismissAfter?: number;
  className?: string;
}

/**
 * AISErrorBanner - Non-blocking notification banner
 */
export function AISErrorBanner({
  error,
  onDismiss,
  autoDismissAfter,
  className,
}: AISErrorBannerProps) {
  const tokens = useAISTokens();
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (autoDismissAfter) {
      const timer = setTimeout(onDismiss, autoDismissAfter * 1000);
      return () => clearTimeout(timer);
    }
  }, [autoDismissAfter, onDismiss]);

  const getSeverityToken = () => {
    switch (error.severity) {
      case 'info':
        return tokens.stateInfo;
      case 'warning':
        return tokens.stateWarning;
      case 'error':
        return tokens.stateError;
      case 'critical':
        return tokens.actionDestructive;
    }
  };

  const severityToken = getSeverityToken();
  const config = severityConfigs[error.severity];
  const IconComponent = config.icon;

  const handleCopy = async () => {
    const text = `${error.title}: ${error.message}`;
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      className={clsx(
        'flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg',
        className
      )}
      style={{ backgroundColor: severityToken.color }}
      role={config.ariaRole}
    >
      <IconComponent size={20} className="text-white flex-shrink-0" aria-hidden="true" />

      <div className="flex-1 min-w-0">
        <p className="font-semibold text-white text-sm">{error.title}</p>
        <p className="text-white text-opacity-90 text-sm truncate select-all">
          {error.message}
        </p>
      </div>

      <button
        onClick={handleCopy}
        className="p-1.5 rounded hover:bg-white hover:bg-opacity-20 transition-colors text-white"
        aria-label="Copy message"
        title="Copy message"
      >
        {copied ? <Check size={16} /> : <Copy size={16} />}
      </button>

      <button
        onClick={onDismiss}
        className="p-1.5 rounded hover:bg-white hover:bg-opacity-20 transition-colors text-white"
        aria-label="Dismiss"
      >
        <X size={16} />
      </button>
    </div>
  );
}

// =============================================================================
// ERROR ENVELOPE COMPONENT
// =============================================================================

export interface AISErrorEnvelopeProps<T> {
  /** Loading state to observe */
  state: AISLoadingState<T>;
  /** Default retry action */
  onRetry?: () => void;
  /** Content to display on success */
  children: (data: T) => React.ReactNode;
  /** Custom loading view */
  loadingView?: React.ReactNode;
  /** Custom idle view */
  idleView?: React.ReactNode;
  /** Additional class names */
  className?: string;
}

/**
 * AISErrorEnvelope - Wraps content with loading/error states
 *
 * @example
 * ```tsx
 * <AISErrorEnvelope
 *   state={loadingState}
 *   onRetry={() => refetch()}
 * >
 *   {(data) => <DataList items={data} />}
 * </AISErrorEnvelope>
 * ```
 */
export function AISErrorEnvelope<T>({
  state,
  onRetry,
  children,
  loadingView,
  idleView,
  className,
}: AISErrorEnvelopeProps<T>) {
  const tokens = useAISTokens();

  switch (state.type) {
    case 'idle':
      return idleView ? <>{idleView}</> : null;

    case 'loading':
      return (
        loadingView || (
          <div
            className={clsx(
              'flex flex-col items-center justify-center p-8',
              className
            )}
          >
            <Loader2
              className="animate-spin mb-4"
              size={40}
              style={{ color: tokens.actionPrimary.color }}
              aria-hidden="true"
            />
            <span style={{ color: tokens.onSurfaceSecondary }}>Loading...</span>
          </div>
        )
      );

    case 'failure':
      return (
        <AISErrorView
          error={state.error}
          onRetry={onRetry}
          className={className}
        />
      );

    case 'success':
      return <>{children(state.data)}</>;
  }
}

export default AISErrorEnvelope;

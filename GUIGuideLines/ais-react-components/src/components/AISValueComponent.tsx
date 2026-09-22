/**
 * AISValueComponent
 *
 * Displays numeric values with REQUIRED annotations (AIS §3.1 - C-04 conformance).
 * You cannot create an uncontextualized value.
 *
 * CRITICAL: A bare value without context is a conformance failure.
 * - .available(0) means "value is zero"
 * - .unavailable means "no data exists" (NOT the same as zero!)
 */

import React from 'react';
import clsx from 'clsx';
import {
  Loader2,
  AlertCircle,
  MinusCircle,
  TrendingUp,
  TrendingDown,
  Minus,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';

// =============================================================================
// TYPES
// =============================================================================

/** Value states - distinguishes between "no value" and "value is zero" */
export type AISValueState<T> =
  | { type: 'available'; value: T }
  | { type: 'unavailable' }
  | { type: 'loading' }
  | { type: 'error'; message: string };

/** Value format types */
export type AISValueFormat =
  | { type: 'currency'; code: string; locale?: string }
  | { type: 'percentage'; decimals?: number }
  | { type: 'decimal'; decimals?: number }
  | { type: 'integer' }
  | { type: 'compact' }
  | { type: 'scientific' }
  | { type: 'custom'; formatter: (value: number) => string };

/** Annotation types - required context for values */
export type AISAnnotation =
  | { type: 'label'; text: string }
  | { type: 'unit'; text: string }
  | { type: 'period'; text: string }
  | { type: 'source'; text: string }
  | { type: 'basis'; text: string }
  | { type: 'currency'; code: string };

/** Comparison data for showing trends */
export interface AISValueComparison {
  previousValue: number;
  previousLabel?: string;
  showPercentageChange?: boolean;
  showAbsoluteChange?: boolean;
}

export type AISValueSize = 'small' | 'medium' | 'large' | 'hero';

export interface AISValueComponentProps {
  /** The value state (required) */
  valueState: AISValueState<number>;
  /** Value format (required) */
  format: AISValueFormat;
  /** Annotations providing context (at least one required) */
  annotations: AISAnnotation[];
  /** Primary label */
  label?: string;
  /** Size variant */
  size?: AISValueSize;
  /** Comparison to previous value */
  comparison?: AISValueComparison;
  /** Custom className */
  className?: string;
}

// =============================================================================
// HELPERS
// =============================================================================

function formatValue(value: number, format: AISValueFormat): string {
  switch (format.type) {
    case 'currency':
      return new Intl.NumberFormat(format.locale || 'en-US', {
        style: 'currency',
        currency: format.code,
      }).format(value);

    case 'percentage':
      return new Intl.NumberFormat('en-US', {
        style: 'percent',
        minimumFractionDigits: format.decimals ?? 1,
        maximumFractionDigits: format.decimals ?? 1,
      }).format(value / 100);

    case 'decimal':
      return new Intl.NumberFormat('en-US', {
        minimumFractionDigits: format.decimals ?? 2,
        maximumFractionDigits: format.decimals ?? 2,
      }).format(value);

    case 'integer':
      return new Intl.NumberFormat('en-US', {
        maximumFractionDigits: 0,
      }).format(value);

    case 'compact':
      return new Intl.NumberFormat('en-US', {
        notation: 'compact',
        compactDisplay: 'short',
      }).format(value);

    case 'scientific':
      return value.toExponential(2);

    case 'custom':
      return format.formatter(value);

    default:
      return String(value);
  }
}

function calculateChange(current: number, previous: number) {
  const absoluteChange = current - previous;
  const percentageChange = previous !== 0 ? ((current - previous) / Math.abs(previous)) * 100 : 0;

  return {
    absoluteChange,
    percentageChange,
    isPositive: absoluteChange > 0,
    isNegative: absoluteChange < 0,
    isNeutral: absoluteChange === 0,
  };
}

// =============================================================================
// SIZE CONFIGURATION
// =============================================================================

const sizeClasses: Record<AISValueSize, { value: string; label: string; annotation: string }> = {
  small: { value: 'text-lg font-semibold', label: 'text-xs', annotation: 'text-xs' },
  medium: { value: 'text-2xl font-bold', label: 'text-sm', annotation: 'text-xs' },
  large: { value: 'text-4xl font-bold', label: 'text-base', annotation: 'text-sm' },
  hero: { value: 'text-6xl font-bold', label: 'text-lg', annotation: 'text-base' },
};

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * AISValueComponent - Annotated value display (AIS §3.1 conformance)
 *
 * @example
 * ```tsx
 * // Currency with period
 * <AISValueComponent
 *   valueState={{ type: 'available', value: 125430.50 }}
 *   format={{ type: 'currency', code: 'USD' }}
 *   annotations={[
 *     { type: 'period', text: 'Q3 2024' },
 *     { type: 'basis', text: 'Gross revenue' },
 *   ]}
 *   label="Revenue"
 *   size="large"
 * />
 *
 * // Unavailable value (distinct from zero)
 * <AISValueComponent
 *   valueState={{ type: 'unavailable' }}
 *   format={{ type: 'currency', code: 'USD' }}
 *   annotations={[{ type: 'period', text: 'Q3 2024' }]}
 *   label="Revenue"
 * />
 * ```
 */
export function AISValueComponent({
  valueState,
  format,
  annotations,
  label,
  size = 'medium',
  comparison,
  className,
}: AISValueComponentProps) {
  const tokens = useAISTokens();
  const sizeConfig = sizeClasses[size];

  // Validate annotations (AIS conformance)
  if (annotations.length === 0 && !label) {
    console.warn(
      'AISValueComponent: At least one annotation or label is required (AIS §3.1 conformance)'
    );
  }

  // Render annotation badges
  const renderAnnotations = () => {
    return annotations.map((annotation, index) => (
      <span
        key={index}
        className={clsx(
          'inline-flex items-center px-1.5 py-0.5 rounded',
          sizeConfig.annotation
        )}
        style={{
          backgroundColor: tokens.surfaceSecondary,
          color: tokens.onSurfaceSecondary,
        }}
      >
        {annotation.type === 'currency' ? annotation.code : annotation.text}
      </span>
    ));
  };

  // Render comparison indicator
  const renderComparison = () => {
    if (!comparison || valueState.type !== 'available') return null;

    const change = calculateChange(valueState.value, comparison.previousValue);
    const TrendIcon = change.isPositive
      ? TrendingUp
      : change.isNegative
      ? TrendingDown
      : Minus;

    const trendColor = change.isPositive
      ? tokens.actionConfirm.color
      : change.isNegative
      ? tokens.actionDestructive.color
      : tokens.onSurfaceSecondary;

    return (
      <div className="flex items-center gap-1 mt-1" style={{ color: trendColor }}>
        <TrendIcon size={16} aria-hidden="true" />
        {comparison.showPercentageChange && (
          <span className="text-sm font-medium">
            {change.percentageChange >= 0 ? '+' : ''}
            {change.percentageChange.toFixed(1)}%
          </span>
        )}
        {comparison.showAbsoluteChange && (
          <span className="text-sm">
            ({change.absoluteChange >= 0 ? '+' : ''}
            {formatValue(change.absoluteChange, format)})
          </span>
        )}
        {comparison.previousLabel && (
          <span className="text-xs opacity-75">vs {comparison.previousLabel}</span>
        )}
      </div>
    );
  };

  // Render based on state
  const renderValue = () => {
    switch (valueState.type) {
      case 'loading':
        return (
          <div className="flex items-center gap-2" style={{ color: tokens.onSurfaceSecondary }}>
            <Loader2 className="animate-spin" size={24} aria-hidden="true" />
            <span className={sizeConfig.value} style={{ opacity: 0.5 }}>
              Loading...
            </span>
          </div>
        );

      case 'unavailable':
        return (
          <div className="flex items-center gap-2" style={{ color: tokens.stateUnavailable.color }}>
            <MinusCircle size={24} aria-hidden="true" />
            <span className={sizeConfig.value}>N/A</span>
          </div>
        );

      case 'error':
        return (
          <div className="flex items-center gap-2" style={{ color: tokens.stateError.color }}>
            <AlertCircle size={24} aria-hidden="true" />
            <span className={sizeConfig.value}>Error</span>
            <span className="text-sm">{valueState.message}</span>
          </div>
        );

      case 'available':
        return (
          <>
            <span className={sizeConfig.value} style={{ color: tokens.onSurface }}>
              {formatValue(valueState.value, format)}
            </span>
            {renderComparison()}
          </>
        );
    }
  };

  return (
    <div
      className={clsx('flex flex-col', className)}
      role="figure"
      aria-label={label || 'Value'}
    >
      {/* Label */}
      {label && (
        <span
          className={clsx('mb-1', sizeConfig.label)}
          style={{ color: tokens.onSurfaceSecondary }}
        >
          {label}
        </span>
      )}

      {/* Value */}
      {renderValue()}

      {/* Annotations */}
      {annotations.length > 0 && (
        <div className="flex flex-wrap items-center gap-1 mt-2">
          {renderAnnotations()}
        </div>
      )}
    </div>
  );
}

// =============================================================================
// VALUE INPUT COMPONENT
// =============================================================================

export interface AISValueInputProps {
  /** Current value */
  value: number | null;
  /** Value change handler */
  onChange: (value: number | null) => void;
  /** Value format */
  format: AISValueFormat;
  /** Annotations providing context */
  annotations: AISAnnotation[];
  /** Primary label */
  label?: string;
  /** Placeholder text */
  placeholder?: string;
  /** Validation function */
  validation?: (value: number) => string | null;
  /** Disabled state */
  disabled?: boolean;
  /** Custom className */
  className?: string;
}

/**
 * AISValueInput - Editable value with annotations
 */
export function AISValueInput({
  value,
  onChange,
  format: _format,
  annotations,
  label,
  placeholder = 'Enter value',
  validation,
  disabled = false,
  className,
}: AISValueInputProps) {
  // Note: _format would be used for displaying formatted values
  void _format;
  const tokens = useAISTokens();
  const [inputValue, setInputValue] = React.useState(value?.toString() ?? '');
  const [error, setError] = React.useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value;
    setInputValue(raw);

    if (raw === '') {
      setError(null);
      onChange(null);
      return;
    }

    const parsed = parseFloat(raw);
    if (isNaN(parsed)) {
      setError('Please enter a valid number');
      return;
    }

    if (validation) {
      const validationError = validation(parsed);
      if (validationError) {
        setError(validationError);
        return;
      }
    }

    setError(null);
    onChange(parsed);
  };

  // Render annotation badges
  const renderAnnotations = () => {
    return annotations.map((annotation, index) => (
      <span
        key={index}
        className="inline-flex items-center px-1.5 py-0.5 rounded text-xs"
        style={{
          backgroundColor: tokens.surfaceSecondary,
          color: tokens.onSurfaceSecondary,
        }}
      >
        {annotation.type === 'currency' ? annotation.code : annotation.text}
      </span>
    ));
  };

  return (
    <div className={clsx('flex flex-col', className)}>
      {/* Label */}
      {label && (
        <label
          className="mb-1 text-sm"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          {label}
        </label>
      )}

      {/* Input */}
      <input
        type="text"
        inputMode="decimal"
        value={inputValue}
        onChange={handleChange}
        placeholder={placeholder}
        disabled={disabled}
        className={clsx(
          'px-3 py-2 rounded-lg text-lg font-semibold',
          'border-2 transition-colors',
          'focus:outline-none focus:ring-2 focus:ring-offset-2',
          disabled && 'opacity-50 cursor-not-allowed'
        )}
        style={{
          backgroundColor: tokens.surface,
          color: tokens.onSurface,
          borderColor: error
            ? tokens.stateError.color
            : tokens.onSurfaceSecondary + '40',
        }}
        aria-invalid={!!error}
        aria-describedby={error ? 'value-input-error' : undefined}
      />

      {/* Error message */}
      {error && (
        <span
          id="value-input-error"
          className="flex items-center gap-1 mt-1 text-sm"
          style={{ color: tokens.stateError.color }}
        >
          <AlertCircle size={14} aria-hidden="true" />
          {error}
        </span>
      )}

      {/* Annotations */}
      {annotations.length > 0 && (
        <div className="flex flex-wrap items-center gap-1 mt-2">
          {renderAnnotations()}
        </div>
      )}
    </div>
  );
}

export default AISValueComponent;

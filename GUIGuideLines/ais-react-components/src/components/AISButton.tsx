/**
 * AISButton Component
 *
 * Semantic buttons with automatic styling based on action type.
 * Follows AIS §2.2 - semantic tokens, never per-control color.
 *
 * KEY PRINCIPLES:
 * - Choose button type based on MEANING, not appearance
 * - Every action type pairs with an icon (AIS §2.3)
 * - Destructive actions should ALWAYS have confirmation
 */

import React, { forwardRef } from 'react';
import clsx from 'clsx';
import {
  ArrowRight,
  Check,
  Trash2,
  AlertTriangle,
  X,
  Minus,
  Loader2,
  type LucideIcon,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';
import type { AISActionType } from '../core/tokens';

// =============================================================================
// TYPES
// =============================================================================

export type AISButtonStyle = 'filled' | 'outlined' | 'text' | 'iconOnly';
export type AISButtonSize = 'small' | 'medium' | 'large';

export interface AISButtonProps
  extends Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, 'type'> {
  /** Semantic action type - determines color and default icon */
  actionType?: AISActionType;
  /** Visual style variant */
  variant?: AISButtonStyle;
  /** Button size */
  size?: AISButtonSize;
  /** Custom icon (overrides default) */
  icon?: LucideIcon;
  /** Show icon alongside text */
  showIcon?: boolean;
  /** Icon position */
  iconPosition?: 'left' | 'right';
  /** Loading state */
  isLoading?: boolean;
  /** Full width button */
  fullWidth?: boolean;
  /** Button label (children) */
  children?: React.ReactNode;
  /** HTML button type */
  htmlType?: 'button' | 'submit' | 'reset';
}

// =============================================================================
// ICON MAP
// =============================================================================

const actionTypeIcons: Record<AISActionType, LucideIcon> = {
  primary: ArrowRight,
  confirm: Check,
  destructive: Trash2,
  caution: AlertTriangle,
  neutral: X,
  secondary: Minus,
};

// =============================================================================
// SIZE CLASSES
// =============================================================================

const sizeClasses: Record<AISButtonSize, string> = {
  small: 'px-3 py-1.5 text-sm gap-1.5',
  medium: 'px-4 py-2 text-base gap-2',
  large: 'px-6 py-3 text-lg gap-2.5',
};

const iconSizes: Record<AISButtonSize, number> = {
  small: 14,
  medium: 18,
  large: 22,
};

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * AISButton - Semantic button component following AIS v1.0
 *
 * @example
 * ```tsx
 * // Primary action
 * <AISButton actionType="primary" onClick={handleSave}>
 *   Save
 * </AISButton>
 *
 * // Destructive with confirmation
 * <AISButton actionType="destructive" onClick={handleDelete}>
 *   Delete
 * </AISButton>
 *
 * // Loading state
 * <AISButton actionType="primary" isLoading>
 *   Processing...
 * </AISButton>
 * ```
 */
export const AISButton = forwardRef<HTMLButtonElement, AISButtonProps>(
  function AISButton(
    {
      actionType = 'primary',
      variant = 'filled',
      size = 'medium',
      icon,
      showIcon = true,
      iconPosition = 'left',
      isLoading = false,
      fullWidth = false,
      children,
      htmlType = 'button',
      className,
      disabled,
      ...props
    },
    ref
  ) {
    const tokens = useAISTokens();

    // Get the appropriate token for this action type
    const getActionToken = () => {
      switch (actionType) {
        case 'primary':
          return tokens.actionPrimary;
        case 'confirm':
          return tokens.actionConfirm;
        case 'destructive':
          return tokens.actionDestructive;
        case 'caution':
          return tokens.actionCaution;
        case 'neutral':
          return tokens.actionNeutral;
        case 'secondary':
          return tokens.actionSecondary;
        default:
          return tokens.actionPrimary;
      }
    };

    const token = getActionToken();
    const IconComponent = icon || actionTypeIcons[actionType];
    const iconSize = iconSizes[size];

    // Generate variant-specific styles
    const getVariantStyles = (): React.CSSProperties => {
      const baseStyles: React.CSSProperties = {};

      switch (variant) {
        case 'filled':
          return {
            ...baseStyles,
            backgroundColor: token.color,
            color: '#FFFFFF',
            border: 'none',
          };
        case 'outlined':
          return {
            ...baseStyles,
            backgroundColor: 'transparent',
            color: token.color,
            border: `2px solid ${token.color}`,
          };
        case 'text':
          return {
            ...baseStyles,
            backgroundColor: 'transparent',
            color: token.color,
            border: 'none',
          };
        case 'iconOnly':
          return {
            ...baseStyles,
            backgroundColor: 'transparent',
            color: token.color,
            border: 'none',
            padding: size === 'small' ? '6px' : size === 'large' ? '12px' : '8px',
          };
        default:
          return baseStyles;
      }
    };

    const renderIcon = () => {
      if (isLoading) {
        return (
          <Loader2
            size={iconSize}
            className="animate-spin"
            aria-hidden="true"
          />
        );
      }

      if (showIcon && IconComponent) {
        return <IconComponent size={iconSize} aria-hidden="true" />;
      }

      return null;
    };

    const isIconOnly = variant === 'iconOnly' || !children;

    return (
      <button
        ref={ref}
        type={htmlType}
        className={clsx(
          // Base styles
          'inline-flex items-center justify-center font-medium',
          'rounded-lg transition-all duration-200',
          'focus:outline-none focus:ring-2 focus:ring-offset-2',
          'disabled:opacity-50 disabled:cursor-not-allowed',

          // Hover effects
          variant === 'filled' && 'hover:brightness-110 active:brightness-95',
          variant === 'outlined' && 'hover:bg-opacity-10',
          variant === 'text' && 'hover:bg-opacity-10',

          // Size
          !isIconOnly && sizeClasses[size],

          // Full width
          fullWidth && 'w-full',

          // Custom classes
          className
        )}
        style={{
          ...getVariantStyles(),
          '--tw-ring-color': token.color,
        } as React.CSSProperties}
        disabled={disabled || isLoading}
        aria-busy={isLoading}
        {...props}
      >
        {iconPosition === 'left' && renderIcon()}
        {!isIconOnly && children}
        {iconPosition === 'right' && renderIcon()}
      </button>
    );
  }
);

// =============================================================================
// CONVENIENCE EXPORTS
// =============================================================================

/**
 * Icon-only button convenience component
 */
export interface AISIconButtonProps
  extends Omit<AISButtonProps, 'variant' | 'children'> {
  /** Accessibility label (required for icon-only buttons) */
  'aria-label': string;
}

export const AISIconButton = forwardRef<HTMLButtonElement, AISIconButtonProps>(
  function AISIconButton(props, ref) {
    return <AISButton ref={ref} {...props} variant="iconOnly" />;
  }
);

export default AISButton;

import React, { useState } from 'react';
import { AISButton, AISIconButton } from '../../components/AISButton';
import { useAISTokens } from '../../core/AISProvider';
import { Plus, Settings, Save, Trash2 } from 'lucide-react';

export function ButtonDemo() {
  const tokens = useAISTokens();
  const [isLoading, setIsLoading] = useState(false);

  const handleLoadingDemo = () => {
    setIsLoading(true);
    setTimeout(() => setIsLoading(false), 2000);
  };

  return (
    <div className="space-y-12">
      {/* Header */}
      <div>
        <h1
          className="text-3xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          AISButton
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Semantic buttons with automatic styling based on action type.
          Choose button type based on MEANING, not appearance.
        </p>
      </div>

      {/* Action Types */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Action Types
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Each action type has semantic meaning and determines the button's color.
        </p>

        <div className="flex flex-wrap gap-4">
          <AISButton actionType="primary">Primary</AISButton>
          <AISButton actionType="confirm">Confirm</AISButton>
          <AISButton actionType="caution">Caution</AISButton>
          <AISButton actionType="destructive">Destructive</AISButton>
          <AISButton actionType="neutral">Neutral</AISButton>
          <AISButton actionType="secondary">Secondary</AISButton>
        </div>

        <div
          className="mt-4 p-4 rounded-lg text-sm"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          <ul className="space-y-1" style={{ color: tokens.onSurfaceSecondary }}>
            <li><strong>Primary:</strong> Main forward action</li>
            <li><strong>Confirm:</strong> Approval, authorization, acceptance</li>
            <li><strong>Caution:</strong> Consequential or externally visible (sends, publishes)</li>
            <li><strong>Destructive:</strong> Irreversible or data-removing (always confirm!)</li>
            <li><strong>Neutral:</strong> Cancel, close, back</li>
            <li><strong>Secondary:</strong> Lower prominence alternatives</li>
          </ul>
        </div>
      </section>

      {/* Variants */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Variants
        </h2>

        <div className="space-y-4">
          <div>
            <h3 className="text-sm font-medium mb-2" style={{ color: tokens.onSurfaceSecondary }}>
              Filled (Default)
            </h3>
            <div className="flex flex-wrap gap-3">
              <AISButton actionType="primary" variant="filled">Filled</AISButton>
              <AISButton actionType="confirm" variant="filled">Filled</AISButton>
              <AISButton actionType="destructive" variant="filled">Filled</AISButton>
            </div>
          </div>

          <div>
            <h3 className="text-sm font-medium mb-2" style={{ color: tokens.onSurfaceSecondary }}>
              Outlined
            </h3>
            <div className="flex flex-wrap gap-3">
              <AISButton actionType="primary" variant="outlined">Outlined</AISButton>
              <AISButton actionType="confirm" variant="outlined">Outlined</AISButton>
              <AISButton actionType="destructive" variant="outlined">Outlined</AISButton>
            </div>
          </div>

          <div>
            <h3 className="text-sm font-medium mb-2" style={{ color: tokens.onSurfaceSecondary }}>
              Text
            </h3>
            <div className="flex flex-wrap gap-3">
              <AISButton actionType="primary" variant="text">Text</AISButton>
              <AISButton actionType="confirm" variant="text">Text</AISButton>
              <AISButton actionType="destructive" variant="text">Text</AISButton>
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
          <AISButton actionType="primary" size="small">Small</AISButton>
          <AISButton actionType="primary" size="medium">Medium</AISButton>
          <AISButton actionType="primary" size="large">Large</AISButton>
        </div>
      </section>

      {/* With Icons */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          With Icons
        </h2>

        <div className="flex flex-wrap gap-4">
          <AISButton actionType="primary" icon={Plus}>
            Add Item
          </AISButton>
          <AISButton actionType="confirm" icon={Save}>
            Save Changes
          </AISButton>
          <AISButton actionType="destructive" icon={Trash2}>
            Delete
          </AISButton>
          <AISButton actionType="secondary" icon={Settings} iconPosition="right">
            Settings
          </AISButton>
        </div>

        <div className="mt-4">
          <h3 className="text-sm font-medium mb-2" style={{ color: tokens.onSurfaceSecondary }}>
            Icon-only Buttons
          </h3>
          <div className="flex flex-wrap gap-3">
            <AISIconButton actionType="primary" icon={Plus} aria-label="Add item" />
            <AISIconButton actionType="confirm" icon={Save} aria-label="Save" />
            <AISIconButton actionType="destructive" icon={Trash2} aria-label="Delete" />
            <AISIconButton actionType="secondary" icon={Settings} aria-label="Settings" />
          </div>
        </div>
      </section>

      {/* States */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          States
        </h2>

        <div className="flex flex-wrap gap-4">
          <AISButton actionType="primary" disabled>
            Disabled
          </AISButton>
          <AISButton actionType="primary" isLoading={isLoading} onClick={handleLoadingDemo}>
            {isLoading ? 'Processing...' : 'Click for Loading'}
          </AISButton>
        </div>
      </section>

      {/* Full Width */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Full Width
        </h2>

        <div className="max-w-md space-y-2">
          <AISButton actionType="primary" fullWidth>
            Full Width Button
          </AISButton>
          <AISButton actionType="neutral" variant="outlined" fullWidth>
            Full Width Outlined
          </AISButton>
        </div>
      </section>
    </div>
  );
}

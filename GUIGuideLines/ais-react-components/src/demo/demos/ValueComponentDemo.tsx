import { useState } from 'react';
import {
  AISValueComponent,
  AISValueInput,
  type AISValueState,
} from '../../components/AISValueComponent';
import { useAISTokens } from '../../core/AISProvider';
import { AISButton } from '../../components/AISButton';

export function ValueComponentDemo() {
  const tokens = useAISTokens();
  const [inputValue, setInputValue] = useState<number | null>(1000);
  const [demoState, setDemoState] = useState<'available' | 'unavailable' | 'loading' | 'error'>('available');

  const getValueState = (): AISValueState<number> => {
    switch (demoState) {
      case 'available':
        return { type: 'available', value: 125430.50 };
      case 'unavailable':
        return { type: 'unavailable' };
      case 'loading':
        return { type: 'loading' };
      case 'error':
        return { type: 'error', message: 'Failed to fetch data' };
    }
  };

  return (
    <div className="space-y-12">
      {/* Header */}
      <div>
        <h1
          className="text-3xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          AISValueComponent
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Displays numeric values with REQUIRED annotations (AIS §3.1 - C-04 conformance).
          A bare value without context is a conformance failure.
        </p>
      </div>

      {/* Critical Distinction */}
      <section
        className="p-4 rounded-lg border-2"
        style={{
          backgroundColor: tokens.stateWarning.color + '10',
          borderColor: tokens.stateWarning.color,
        }}
      >
        <h3 className="font-bold mb-2" style={{ color: tokens.stateWarning.color }}>
          Critical: Zero vs Unavailable
        </h3>
        <div className="flex gap-8">
          <div>
            <p className="text-sm mb-2" style={{ color: tokens.onSurface }}>
              <code>.available(0)</code> = "Value is zero"
            </p>
            <AISValueComponent
              valueState={{ type: 'available', value: 0 }}
              format={{ type: 'currency', code: 'USD' }}
              annotations={[{ type: 'period', text: 'Q3 2024' }]}
              label="Revenue"
            />
          </div>
          <div>
            <p className="text-sm mb-2" style={{ color: tokens.onSurface }}>
              <code>.unavailable</code> = "No data exists"
            </p>
            <AISValueComponent
              valueState={{ type: 'unavailable' }}
              format={{ type: 'currency', code: 'USD' }}
              annotations={[{ type: 'period', text: 'Q3 2024' }]}
              label="Revenue"
            />
          </div>
        </div>
      </section>

      {/* Value States */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Value States
        </h2>

        <div className="flex gap-3 mb-4">
          <AISButton
            actionType={demoState === 'available' ? 'primary' : 'neutral'}
            variant={demoState === 'available' ? 'filled' : 'outlined'}
            size="small"
            onClick={() => setDemoState('available')}
          >
            Available
          </AISButton>
          <AISButton
            actionType={demoState === 'unavailable' ? 'primary' : 'neutral'}
            variant={demoState === 'unavailable' ? 'filled' : 'outlined'}
            size="small"
            onClick={() => setDemoState('unavailable')}
          >
            Unavailable
          </AISButton>
          <AISButton
            actionType={demoState === 'loading' ? 'primary' : 'neutral'}
            variant={demoState === 'loading' ? 'filled' : 'outlined'}
            size="small"
            onClick={() => setDemoState('loading')}
          >
            Loading
          </AISButton>
          <AISButton
            actionType={demoState === 'error' ? 'primary' : 'neutral'}
            variant={demoState === 'error' ? 'filled' : 'outlined'}
            size="small"
            onClick={() => setDemoState('error')}
          >
            Error
          </AISButton>
        </div>

        <div
          className="p-6 rounded-lg"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          <AISValueComponent
            valueState={getValueState()}
            format={{ type: 'currency', code: 'USD' }}
            annotations={[
              { type: 'period', text: 'Q3 2024' },
              { type: 'basis', text: 'Gross revenue' },
            ]}
            label="Revenue"
            size="large"
          />
        </div>
      </section>

      {/* Formats */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Value Formats
        </h2>

        <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 1234.56 }}
              format={{ type: 'currency', code: 'USD' }}
              annotations={[{ type: 'currency', code: 'USD' }]}
              label="Currency"
            />
          </div>

          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 75.5 }}
              format={{ type: 'percentage' }}
              annotations={[{ type: 'basis', text: 'of target' }]}
              label="Percentage"
            />
          </div>

          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 1234567 }}
              format={{ type: 'compact' }}
              annotations={[{ type: 'unit', text: 'users' }]}
              label="Compact"
            />
          </div>

          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 98.6 }}
              format={{ type: 'decimal', decimals: 1 }}
              annotations={[{ type: 'unit', text: '°F' }]}
              label="Decimal"
            />
          </div>

          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 42 }}
              format={{ type: 'integer' }}
              annotations={[{ type: 'label', text: 'items' }]}
              label="Integer"
            />
          </div>

          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 6.022e23 }}
              format={{ type: 'scientific' }}
              annotations={[{ type: 'unit', text: 'mol⁻¹' }]}
              label="Scientific"
            />
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

        <div className="flex flex-wrap gap-8">
          <AISValueComponent
            valueState={{ type: 'available', value: 1234 }}
            format={{ type: 'currency', code: 'USD' }}
            annotations={[{ type: 'period', text: '2024' }]}
            label="Small"
            size="small"
          />
          <AISValueComponent
            valueState={{ type: 'available', value: 1234 }}
            format={{ type: 'currency', code: 'USD' }}
            annotations={[{ type: 'period', text: '2024' }]}
            label="Medium"
            size="medium"
          />
          <AISValueComponent
            valueState={{ type: 'available', value: 1234 }}
            format={{ type: 'currency', code: 'USD' }}
            annotations={[{ type: 'period', text: '2024' }]}
            label="Large"
            size="large"
          />
          <AISValueComponent
            valueState={{ type: 'available', value: 1234 }}
            format={{ type: 'currency', code: 'USD' }}
            annotations={[{ type: 'period', text: '2024' }]}
            label="Hero"
            size="hero"
          />
        </div>
      </section>

      {/* With Comparison */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          With Comparison (Trends)
        </h2>

        <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 125430 }}
              format={{ type: 'currency', code: 'USD' }}
              annotations={[{ type: 'period', text: 'Q3 2024' }]}
              label="Revenue (Up)"
              comparison={{
                previousValue: 98500,
                showPercentageChange: true,
                previousLabel: 'Q2',
              }}
            />
          </div>

          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 82000 }}
              format={{ type: 'currency', code: 'USD' }}
              annotations={[{ type: 'period', text: 'Q3 2024' }]}
              label="Expenses (Down)"
              comparison={{
                previousValue: 95000,
                showPercentageChange: true,
                previousLabel: 'Q2',
              }}
            />
          </div>

          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <AISValueComponent
              valueState={{ type: 'available', value: 50000 }}
              format={{ type: 'currency', code: 'USD' }}
              annotations={[{ type: 'period', text: 'Q3 2024' }]}
              label="Budget (No Change)"
              comparison={{
                previousValue: 50000,
                showPercentageChange: true,
              }}
            />
          </div>
        </div>
      </section>

      {/* Value Input */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Value Input
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Editable value with annotations and validation.
        </p>

        <div className="max-w-md">
          <AISValueInput
            value={inputValue}
            onChange={setInputValue}
            format={{ type: 'currency', code: 'USD' }}
            annotations={[{ type: 'period', text: 'FY 2024' }]}
            label="Budget Amount"
            placeholder="Enter amount"
            validation={(value) => {
              if (value < 0) return 'Cannot be negative';
              if (value > 1000000) return 'Exceeds maximum budget';
              return null;
            }}
          />

          <p className="mt-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
            Current value: {inputValue !== null ? `$${inputValue}` : 'null'}
          </p>
        </div>
      </section>
    </div>
  );
}

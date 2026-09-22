import { useState } from 'react';
import {
  AISErrorEnvelope,
  AISErrorView,
  AISInlineError,
  AISErrorBanner,
  AISErrors,
  type AISLoadingState,
  type AISErrorInfo,
} from '../../components/AISErrorEnvelope';
import { useAISTokens } from '../../core/AISProvider';
import { AISButton } from '../../components/AISButton';
import type { AISErrorSeverity } from '../../core/tokens';

export function ErrorHandlingDemo() {
  const tokens = useAISTokens();
  const [loadingState, setLoadingState] = useState<AISLoadingState<string[]>>({ type: 'idle' });
  const [showBanner, setShowBanner] = useState(false);
  const [bannerError, setBannerError] = useState<AISErrorInfo | null>(null);

  const simulateLoad = () => {
    setLoadingState({ type: 'loading' });
    setTimeout(() => {
      if (Math.random() > 0.5) {
        setLoadingState({ type: 'success', data: ['Item 1', 'Item 2', 'Item 3'] });
      } else {
        setLoadingState({
          type: 'failure',
          error: AISErrors.networkError(
            () => simulateLoad(),
            () => setLoadingState({ type: 'idle' })
          ),
        });
      }
    }, 2000);
  };

  const showBannerWithSeverity = (severity: AISErrorSeverity) => {
    const errors: Record<AISErrorSeverity, AISErrorInfo> = {
      info: {
        title: 'Update Available',
        message: 'A new version of the app is available.',
        severity: 'info',
      },
      warning: {
        title: 'Connection Slow',
        message: 'Data may take longer to load.',
        severity: 'warning',
      },
      error: {
        title: 'Sync Failed',
        message: 'Unable to sync your changes. Will retry automatically.',
        severity: 'error',
      },
      critical: {
        title: 'Database Error',
        message: 'Please contact support for assistance.',
        severity: 'critical',
      },
    };
    setBannerError(errors[severity]);
    setShowBanner(true);
  };

  return (
    <div className="space-y-12 relative">
      {/* Header */}
      <div>
        <h1
          className="text-3xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          AISErrorEnvelope
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Consistent error display with appropriate severity levels, actionable recovery options,
          and accessibility support. All error messages are copyable.
        </p>
      </div>

      {/* Banner Overlay */}
      {showBanner && bannerError && (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 z-50 w-full max-w-lg animate-slide-in-from-top">
          <AISErrorBanner
            error={bannerError}
            autoDismissAfter={5}
            onDismiss={() => setShowBanner(false)}
          />
        </div>
      )}

      {/* Error Severities */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Error Severities
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Different visual treatment based on error severity.
        </p>

        <div className="grid grid-cols-2 gap-4">
          {(['info', 'warning', 'error', 'critical'] as const).map((severity) => {
            const labels = {
              info: { title: 'Info', desc: 'Non-blocking informational message' },
              warning: { title: 'Warning', desc: 'Should be addressed but not blocking' },
              error: { title: 'Error', desc: 'Operation failed, user action may help' },
              critical: { title: 'Critical', desc: 'System failure, may need support' },
            };
            const label = labels[severity];

            const severityColors = {
              info: tokens.stateInfo,
              warning: tokens.stateWarning,
              error: tokens.stateError,
              critical: tokens.actionDestructive,
            };
            const color = severityColors[severity];

            return (
              <div
                key={severity}
                className="p-4 rounded-lg border"
                style={{
                  backgroundColor: color.color + '10',
                  borderColor: color.color + '30',
                }}
              >
                <div className="flex items-center gap-2 mb-2">
                  <span
                    className="font-semibold"
                    style={{ color: color.color }}
                  >
                    {label.title}
                  </span>
                </div>
                <p
                  className="text-sm select-all"
                  style={{ color: tokens.onSurfaceSecondary }}
                >
                  {label.desc}
                </p>
              </div>
            );
          })}
        </div>
      </section>

      {/* Inline Errors */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Inline Errors
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Compact errors for form fields. All messages are selectable/copyable.
        </p>

        <div
          className="p-4 rounded-lg space-y-4"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          <div>
            <label className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
              Email
            </label>
            <input
              type="text"
              defaultValue="invalid-email"
              className="w-full px-3 py-2 rounded-lg border mt-1"
              style={{
                backgroundColor: tokens.surface,
                borderColor: tokens.stateError.color,
                color: tokens.onSurface,
              }}
            />
            <div className="mt-1">
              <AISInlineError message="Please enter a valid email address" severity="error" />
            </div>
          </div>

          <div>
            <label className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
              Password
            </label>
            <input
              type="password"
              defaultValue="weak"
              className="w-full px-3 py-2 rounded-lg border mt-1"
              style={{
                backgroundColor: tokens.surface,
                borderColor: tokens.stateWarning.color,
                color: tokens.onSurface,
              }}
            />
            <div className="mt-1">
              <AISInlineError message="Password should be at least 8 characters" severity="warning" />
            </div>
          </div>

          <div>
            <label className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
              Username
            </label>
            <input
              type="text"
              defaultValue="user123"
              className="w-full px-3 py-2 rounded-lg border mt-1"
              style={{
                backgroundColor: tokens.surface,
                borderColor: tokens.stateInfo.color,
                color: tokens.onSurface,
              }}
            />
            <div className="mt-1">
              <AISInlineError message="This username is available" severity="info" />
            </div>
          </div>
        </div>
      </section>

      {/* Error Envelope Demo */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Error Envelope
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Wraps content with loading/error states.
        </p>

        <div className="flex flex-wrap gap-2 mb-4">
          <AISButton
            actionType="neutral"
            variant="outlined"
            size="small"
            onClick={() => setLoadingState({ type: 'idle' })}
          >
            Idle
          </AISButton>
          <AISButton
            actionType="secondary"
            variant="outlined"
            size="small"
            onClick={() => setLoadingState({ type: 'loading' })}
          >
            Loading
          </AISButton>
          <AISButton
            actionType="confirm"
            variant="outlined"
            size="small"
            onClick={() => setLoadingState({ type: 'success', data: ['Item 1', 'Item 2', 'Item 3'] })}
          >
            Success
          </AISButton>
          <AISButton
            actionType="destructive"
            variant="outlined"
            size="small"
            onClick={() =>
              setLoadingState({
                type: 'failure',
                error: AISErrors.networkError(
                  () => simulateLoad(),
                  () => setLoadingState({ type: 'idle' })
                ),
              })
            }
          >
            Error
          </AISButton>
        </div>

        <div
          className="rounded-lg overflow-hidden"
          style={{
            backgroundColor: tokens.surfaceSecondary,
            minHeight: 200,
          }}
        >
          <AISErrorEnvelope
            state={loadingState}
            onRetry={simulateLoad}
          >
            {(items) => (
              <div className="p-4 space-y-2">
                {items.map((item, i) => (
                  <div
                    key={i}
                    className="flex items-center gap-2 p-3 rounded-lg"
                    style={{ backgroundColor: tokens.surface }}
                  >
                    <span
                      className="w-2 h-2 rounded-full"
                      style={{ backgroundColor: tokens.actionConfirm.color }}
                    />
                    <span style={{ color: tokens.onSurface }}>{item}</span>
                  </div>
                ))}
              </div>
            )}
          </AISErrorEnvelope>
        </div>
      </section>

      {/* Error Banners */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Error Banners
        </h2>
        <p className="mb-4 text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Non-blocking notifications. Click a button to show a banner.
          Auto-dismiss after 5 seconds. Copy button included.
        </p>

        <div className="flex flex-wrap gap-2">
          <AISButton
            actionType="secondary"
            size="small"
            onClick={() => showBannerWithSeverity('info')}
          >
            Info Banner
          </AISButton>
          <AISButton
            actionType="caution"
            size="small"
            onClick={() => showBannerWithSeverity('warning')}
          >
            Warning Banner
          </AISButton>
          <AISButton
            actionType="destructive"
            size="small"
            onClick={() => showBannerWithSeverity('error')}
          >
            Error Banner
          </AISButton>
        </div>
      </section>

      {/* Standalone Error View */}
      <section>
        <h2
          className="text-xl font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Standalone Error View
        </h2>

        <div
          className="rounded-lg overflow-hidden"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          <AISErrorView
            error={{
              title: 'Connection Failed',
              message: 'Unable to connect to the server. Please check your internet connection and try again.',
              severity: 'error',
              code: 'NET_001',
              technicalDetails: 'Error: ECONNREFUSED\nHost: api.example.com\nPort: 443',
              actions: [
                { label: 'Retry', actionType: 'primary', onClick: () => alert('Retry clicked') },
                { label: 'Report Issue', actionType: 'caution', onClick: () => alert('Report clicked') },
              ],
            }}
          />
        </div>
      </section>
    </div>
  );
}

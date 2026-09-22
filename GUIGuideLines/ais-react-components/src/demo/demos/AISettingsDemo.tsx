/**
 * AISettingsDemo.tsx
 * Demo page for AI Provider Settings Configuration
 */

import { useState } from 'react';
import { useAISTokens } from '../../core/AISProvider';
import { AISButton } from '../../components/AISButton';
import {
  Cloud,
  Monitor,
  Smartphone,
  Sparkles,
  MessageCircle,
  Diamond,
  Server,
  Laptop,
  Settings,
  Eye,
  Globe,
  RefreshCw,
  Save,
  RotateCcw,
  ChevronDown,
  ChevronUp,
  Check,
  Folder,
  Upload,
} from 'lucide-react';

// Types

enum CloudLLMProvider {
  Claude = 'claude',
  ChatGPT = 'chatgpt',
  Gemini = 'gemini',
}

enum LocalAIProvider {
  Ollama = 'ollama',
  LMStudio = 'lmstudio',
  Custom = 'custom',
}

interface CloudLLMConfig {
  provider: CloudLLMProvider;
  apiKey: string;
  endpoint: string;
  model: string;
  isEnabled: boolean;
  maxTokens: number;
  temperature: number;
}

interface LocalAIConfig {
  provider: LocalAIProvider;
  endpoint: string;
  model: string;
  isEnabled: boolean;
  maxTokens: number;
  contextLength: number;
}

interface OnDeviceConfig {
  useBrowserOCR: boolean;
  preferredLanguage: string;
}

type PreferredTier = 'onDevice' | 'local' | 'cloud';

// Provider configurations

const cloudProviderConfig: Record<CloudLLMProvider, {
  name: string;
  icon: typeof Sparkles;
  color: string;
  defaultEndpoint: string;
  defaultModel: string;
}> = {
  [CloudLLMProvider.Claude]: {
    name: 'Claude (Anthropic)',
    icon: Sparkles,
    color: '#D97706',
    defaultEndpoint: 'https://api.anthropic.com/v1/messages',
    defaultModel: 'claude-3-5-sonnet-20241022',
  },
  [CloudLLMProvider.ChatGPT]: {
    name: 'ChatGPT (OpenAI)',
    icon: MessageCircle,
    color: '#10B981',
    defaultEndpoint: 'https://api.openai.com/v1/chat/completions',
    defaultModel: 'gpt-4o',
  },
  [CloudLLMProvider.Gemini]: {
    name: 'Gemini (Google)',
    icon: Diamond,
    color: '#3B82F6',
    defaultEndpoint: 'https://generativelanguage.googleapis.com/v1beta/models',
    defaultModel: 'gemini-1.5-pro',
  },
};

const localProviderConfig: Record<LocalAIProvider, {
  name: string;
  icon: typeof Server;
  defaultEndpoint: string;
}> = {
  [LocalAIProvider.Ollama]: {
    name: 'Ollama',
    icon: Server,
    defaultEndpoint: 'http://localhost:11434/api/generate',
  },
  [LocalAIProvider.LMStudio]: {
    name: 'LM Studio',
    icon: Laptop,
    defaultEndpoint: 'http://localhost:1234/v1/chat/completions',
  },
  [LocalAIProvider.Custom]: {
    name: 'Custom Endpoint',
    icon: Settings,
    defaultEndpoint: '',
  },
};

const preferredTierConfig: Record<PreferredTier, {
  name: string;
  description: string;
  icon: typeof Smartphone;
}> = {
  onDevice: {
    name: 'On-Device First',
    description: 'Fastest, works offline (Tesseract.js OCR)',
    icon: Smartphone,
  },
  local: {
    name: 'Local AI First',
    description: 'Private, runs on your machine (Ollama / LM Studio)',
    icon: Monitor,
  },
  cloud: {
    name: 'Cloud AI First',
    description: 'Most accurate, requires internet (Claude / ChatGPT)',
    icon: Cloud,
  },
};

// Default settings

const createDefaultCloudProviders = (): CloudLLMConfig[] =>
  Object.values(CloudLLMProvider).map((provider) => ({
    provider,
    apiKey: '',
    endpoint: cloudProviderConfig[provider].defaultEndpoint,
    model: cloudProviderConfig[provider].defaultModel,
    isEnabled: false,
    maxTokens: 4096,
    temperature: 0.3,
  }));

const createDefaultLocalProviders = (): LocalAIConfig[] =>
  Object.values(LocalAIProvider).map((provider) => ({
    provider,
    endpoint: localProviderConfig[provider].defaultEndpoint,
    model: 'llama3.2',
    isEnabled: false,
    maxTokens: 4096,
    contextLength: 8192,
  }));

// Component

function AISettingsDemo() {
  const tokens = useAISTokens();

  // Settings state
  const [cloudProviders, setCloudProviders] = useState<CloudLLMConfig[]>(createDefaultCloudProviders());
  const [localProviders, setLocalProviders] = useState<LocalAIConfig[]>(createDefaultLocalProviders());
  const [onDeviceConfig, setOnDeviceConfig] = useState<OnDeviceConfig>({
    useBrowserOCR: true,
    preferredLanguage: 'en',
  });
  const [preferredTier, setPreferredTier] = useState<PreferredTier>('onDevice');
  const [enableFallback, setEnableFallback] = useState(true);

  // UI state
  const [activeTab, setActiveTab] = useState<'cloud' | 'local' | 'onDevice'>('cloud');
  const [expandedProviders, setExpandedProviders] = useState<Set<string>>(new Set());
  const [hasChanges, setHasChanges] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [testingProvider, setTestingProvider] = useState<string | null>(null);
  const [testResults, setTestResults] = useState<Record<string, 'success' | 'error' | null>>({});

  // Handlers

  const toggleProviderExpanded = (id: string) => {
    setExpandedProviders((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const updateCloudProvider = (provider: CloudLLMProvider, updates: Partial<CloudLLMConfig>) => {
    setCloudProviders((prev) =>
      prev.map((p) => (p.provider === provider ? { ...p, ...updates } : p))
    );
    setHasChanges(true);
  };

  const updateLocalProvider = (provider: LocalAIProvider, updates: Partial<LocalAIConfig>) => {
    setLocalProviders((prev) =>
      prev.map((p) => (p.provider === provider ? { ...p, ...updates } : p))
    );
    setHasChanges(true);
  };

  const saveSettings = () => {
    setHasChanges(false);
    setStatusMessage('Settings saved successfully');
    setTimeout(() => setStatusMessage(null), 3000);
  };

  const resetSettings = () => {
    setCloudProviders(createDefaultCloudProviders());
    setLocalProviders(createDefaultLocalProviders());
    setOnDeviceConfig({ useBrowserOCR: true, preferredLanguage: 'en' });
    setPreferredTier('onDevice');
    setEnableFallback(true);
    setHasChanges(false);
    setTestResults({});
    setStatusMessage('Settings reset to defaults');
    setTimeout(() => setStatusMessage(null), 3000);
  };

  const testCloudConnection = async (provider: CloudLLMProvider) => {
    const config = cloudProviders.find(p => p.provider === provider);
    if (!config || !config.apiKey) {
      setTestResults(prev => ({ ...prev, [provider]: 'error' }));
      setStatusMessage('API key is required to test connection');
      setTimeout(() => setStatusMessage(null), 3000);
      return;
    }

    setTestingProvider(provider);
    setTestResults(prev => ({ ...prev, [provider]: null }));

    try {
      // Simulate API test - in production this would actually call the API
      await new Promise(resolve => setTimeout(resolve, 1500));

      // For demo: consider it successful if API key is at least 10 chars
      if (config.apiKey.length >= 10) {
        setTestResults(prev => ({ ...prev, [provider]: 'success' }));
        setStatusMessage(`${cloudProviderConfig[provider].name} connection successful!`);
      } else {
        setTestResults(prev => ({ ...prev, [provider]: 'error' }));
        setStatusMessage(`${cloudProviderConfig[provider].name} connection failed: Invalid API key`);
      }
    } catch {
      setTestResults(prev => ({ ...prev, [provider]: 'error' }));
      setStatusMessage(`${cloudProviderConfig[provider].name} connection failed`);
    } finally {
      setTestingProvider(null);
      setTimeout(() => setStatusMessage(null), 3000);
    }
  };

  const testLocalConnection = async (provider: LocalAIProvider) => {
    const config = localProviders.find(p => p.provider === provider);
    if (!config || !config.endpoint) {
      setTestResults(prev => ({ ...prev, [provider]: 'error' }));
      setStatusMessage('Endpoint URL is required to test connection');
      setTimeout(() => setStatusMessage(null), 3000);
      return;
    }

    setTestingProvider(provider);
    setTestResults(prev => ({ ...prev, [provider]: null }));

    try {
      // Attempt to fetch the endpoint to check if it's reachable
      const response = await fetch(config.endpoint.replace('/api/generate', '/api/tags').replace('/v1/chat/completions', '/v1/models'), {
        method: 'GET',
        signal: AbortSignal.timeout(5000),
      });

      if (response.ok) {
        setTestResults(prev => ({ ...prev, [provider]: 'success' }));
        setStatusMessage(`${localProviderConfig[provider].name} connection successful!`);
      } else {
        setTestResults(prev => ({ ...prev, [provider]: 'error' }));
        setStatusMessage(`${localProviderConfig[provider].name} returned status ${response.status}`);
      }
    } catch {
      setTestResults(prev => ({ ...prev, [provider]: 'error' }));
      setStatusMessage(`${localProviderConfig[provider].name} connection failed - is the server running?`);
    } finally {
      setTestingProvider(null);
      setTimeout(() => setStatusMessage(null), 3000);
    }
  };

  // Render helpers

  const renderCloudProviderCard = (config: CloudLLMConfig) => {
    const providerInfo = cloudProviderConfig[config.provider];
    const Icon = providerInfo.icon;
    const isExpanded = expandedProviders.has(config.provider);

    return (
      <div
        key={config.provider}
        className="rounded-lg overflow-hidden"
        style={{ backgroundColor: tokens.surface, border: `1px solid ${tokens.onSurface}20` }}
      >
        {/* Header */}
        <div
          className="flex items-center justify-between p-4 cursor-pointer"
          onClick={() => toggleProviderExpanded(config.provider)}
        >
          <div className="flex items-center gap-3">
            <div
              className="p-2 rounded-lg"
              style={{ backgroundColor: providerInfo.color + '20' }}
            >
              <Icon size={24} style={{ color: providerInfo.color }} />
            </div>
            <div>
              <div className="font-semibold" style={{ color: tokens.onSurface }}>
                {providerInfo.name}
              </div>
              <div
                className="text-sm"
                style={{ color: config.isEnabled && config.apiKey ? tokens.actionConfirm.color : tokens.onSurfaceSecondary }}
              >
                {config.isEnabled && config.apiKey ? 'Configured' : 'Not configured'}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <label className="relative inline-flex items-center cursor-pointer" onClick={(e) => e.stopPropagation()}>
              <input
                type="checkbox"
                checked={config.isEnabled}
                onChange={(e) => updateCloudProvider(config.provider, { isEnabled: e.target.checked })}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
            {isExpanded ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
          </div>
        </div>

        {/* Expanded content */}
        {isExpanded && (
          <div className="px-4 pb-4 space-y-4" style={{ borderTop: `1px solid ${tokens.onSurface}10` }}>
            <div className="pt-4">
              <label className="block text-sm mb-1" style={{ color: tokens.onSurfaceSecondary }}>
                API Key
              </label>
              <input
                type="password"
                value={config.apiKey}
                onChange={(e) => updateCloudProvider(config.provider, { apiKey: e.target.value })}
                placeholder="Enter API key"
                className="w-full px-3 py-2 rounded-lg border"
                style={{ backgroundColor: tokens.surfaceSecondary, borderColor: tokens.onSurface + '20', color: tokens.onSurface }}
              />
            </div>

            <div>
              <label className="block text-sm mb-1" style={{ color: tokens.onSurfaceSecondary }}>
                Model
              </label>
              <input
                type="text"
                value={config.model}
                onChange={(e) => updateCloudProvider(config.provider, { model: e.target.value })}
                className="w-full px-3 py-2 rounded-lg border"
                style={{ backgroundColor: tokens.surfaceSecondary, borderColor: tokens.onSurface + '20', color: tokens.onSurface }}
              />
            </div>

            <div className="flex items-center justify-between">
              {/* Test result indicator */}
              {testResults[config.provider] && (
                <div
                  className="flex items-center gap-2 text-sm"
                  style={{
                    color: testResults[config.provider] === 'success'
                      ? tokens.actionConfirm.color
                      : tokens.actionDestructive.color
                  }}
                >
                  {testResults[config.provider] === 'success' ? (
                    <>
                      <Check size={16} />
                      <span>Connected</span>
                    </>
                  ) : (
                    <span>Connection failed</span>
                  )}
                </div>
              )}
              <button
                onClick={() => testCloudConnection(config.provider)}
                disabled={testingProvider === config.provider}
                className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm ml-auto"
                style={{
                  backgroundColor: tokens.surfaceSecondary,
                  color: tokens.onSurface,
                  opacity: testingProvider === config.provider ? 0.6 : 1,
                }}
              >
                {testingProvider === config.provider ? (
                  <>
                    <RefreshCw size={14} className="animate-spin" />
                    Testing...
                  </>
                ) : (
                  'Test Connection'
                )}
              </button>
            </div>
          </div>
        )}
      </div>
    );
  };

  const renderLocalProviderCard = (config: LocalAIConfig) => {
    const providerInfo = localProviderConfig[config.provider];
    const Icon = providerInfo.icon;
    const isExpanded = expandedProviders.has(config.provider);

    return (
      <div
        key={config.provider}
        className="rounded-lg overflow-hidden"
        style={{ backgroundColor: tokens.surface, border: `1px solid ${tokens.onSurface}20` }}
      >
        {/* Header */}
        <div
          className="flex items-center justify-between p-4 cursor-pointer"
          onClick={() => toggleProviderExpanded(config.provider)}
        >
          <div className="flex items-center gap-3">
            <div
              className="p-2 rounded-lg"
              style={{ backgroundColor: tokens.actionPrimary.color + '20' }}
            >
              <Icon size={24} style={{ color: tokens.actionPrimary.color }} />
            </div>
            <div>
              <div className="font-semibold" style={{ color: tokens.onSurface }}>
                {providerInfo.name}
              </div>
              <div
                className="text-sm"
                style={{ color: config.isEnabled ? tokens.actionConfirm.color : tokens.onSurfaceSecondary }}
              >
                {config.isEnabled ? 'Enabled' : 'Disabled'}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <label className="relative inline-flex items-center cursor-pointer" onClick={(e) => e.stopPropagation()}>
              <input
                type="checkbox"
                checked={config.isEnabled}
                onChange={(e) => updateLocalProvider(config.provider, { isEnabled: e.target.checked })}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
            {isExpanded ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
          </div>
        </div>

        {/* Expanded content */}
        {isExpanded && (
          <div className="px-4 pb-4 space-y-4" style={{ borderTop: `1px solid ${tokens.onSurface}10` }}>
            <div className="pt-4">
              <label className="block text-sm mb-1" style={{ color: tokens.onSurfaceSecondary }}>
                API Endpoint
              </label>
              <input
                type="text"
                value={config.endpoint}
                onChange={(e) => updateLocalProvider(config.provider, { endpoint: e.target.value })}
                placeholder="http://localhost:11434"
                className="w-full px-3 py-2 rounded-lg border"
                style={{ backgroundColor: tokens.surfaceSecondary, borderColor: tokens.onSurface + '20', color: tokens.onSurface }}
              />
            </div>

            <div>
              <label className="block text-sm mb-1" style={{ color: tokens.onSurfaceSecondary }}>
                Model Name
              </label>
              <input
                type="text"
                value={config.model}
                onChange={(e) => updateLocalProvider(config.provider, { model: e.target.value })}
                placeholder="llama3.2"
                className="w-full px-3 py-2 rounded-lg border"
                style={{ backgroundColor: tokens.surfaceSecondary, borderColor: tokens.onSurface + '20', color: tokens.onSurface }}
              />
            </div>

            <div className="flex items-center justify-between">
              {/* Test result indicator */}
              {testResults[config.provider] && (
                <div
                  className="flex items-center gap-2 text-sm"
                  style={{
                    color: testResults[config.provider] === 'success'
                      ? tokens.actionConfirm.color
                      : tokens.actionDestructive.color
                  }}
                >
                  {testResults[config.provider] === 'success' ? (
                    <>
                      <Check size={16} />
                      <span>Connected</span>
                    </>
                  ) : (
                    <span>Connection failed</span>
                  )}
                </div>
              )}
              <button
                onClick={() => testLocalConnection(config.provider)}
                disabled={testingProvider === config.provider}
                className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm ml-auto"
                style={{
                  backgroundColor: tokens.surfaceSecondary,
                  color: tokens.onSurface,
                  opacity: testingProvider === config.provider ? 0.6 : 1,
                }}
              >
                {testingProvider === config.provider ? (
                  <>
                    <RefreshCw size={14} className="animate-spin" />
                    Testing...
                  </>
                ) : (
                  'Test Connection'
                )}
              </button>
            </div>
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="p-6 space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold mb-2" style={{ color: tokens.onSurface }}>
          AI Settings
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Configure AI provider API keys, endpoints, and processing preferences.
        </p>
      </div>

      {/* Status message */}
      {statusMessage && (
        <div
          className="p-3 rounded-lg text-center"
          style={{
            backgroundColor: statusMessage.includes('success') ? tokens.actionConfirm.color + '20' : tokens.stateInfo.color + '20',
            color: statusMessage.includes('success') ? tokens.actionConfirm.color : tokens.stateInfo.color,
          }}
        >
          {statusMessage}
        </div>
      )}

      {/* Header Card */}
      <section
        className="p-6 rounded-lg flex items-center justify-between"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <div className="flex items-center gap-4">
          <div
            className="p-4 rounded-lg"
            style={{ backgroundColor: tokens.actionPrimary.color + '20' }}
          >
            <Settings size={40} style={{ color: tokens.actionPrimary.color }} />
          </div>
          <div>
            <h2 className="text-xl font-bold" style={{ color: tokens.onSurface }}>
              AI Provider Settings
            </h2>
            <p style={{ color: tokens.onSurfaceSecondary }}>
              Configure API keys and AI service endpoints
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {hasChanges && (
            <AISButton actionType="confirm" onClick={saveSettings}>
              <Save size={16} className="mr-2" />
              Save
            </AISButton>
          )}
          <AISButton actionType="neutral" variant="outlined" onClick={resetSettings}>
            <RotateCcw size={16} className="mr-2" />
            Reset
          </AISButton>
        </div>
      </section>

      {/* Tab selector */}
      <div className="flex rounded-lg overflow-hidden" style={{ backgroundColor: tokens.surfaceSecondary }}>
        {(['cloud', 'local', 'onDevice'] as const).map((tab) => {
          const icons = { cloud: Cloud, local: Monitor, onDevice: Smartphone };
          const labels = { cloud: 'Cloud AI', local: 'Local AI', onDevice: 'On-Device' };
          const Icon = icons[tab];
          return (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className="flex-1 flex items-center justify-center gap-2 py-3 px-4 transition-colors"
              style={{
                backgroundColor: activeTab === tab ? tokens.actionPrimary.color : 'transparent',
                color: activeTab === tab ? '#FFFFFF' : tokens.onSurface,
              }}
            >
              <Icon size={18} />
              <span className="font-medium">{labels[tab]}</span>
            </button>
          );
        })}
      </div>

      {/* Tab content */}
      {activeTab === 'cloud' && (
        <div className="space-y-6">
          {/* Section header */}
          <div className="flex items-center gap-3">
            <Cloud size={20} style={{ color: tokens.actionPrimary.color }} />
            <div>
              <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
                Cloud LLM Providers
              </h3>
              <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                Configure API keys for cloud-based AI services
              </p>
            </div>
          </div>

          {/* Provider cards */}
          <div className="space-y-4">
            {cloudProviders.map(renderCloudProviderCard)}
          </div>

          {/* Preferred tier selector */}
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <RefreshCw size={20} style={{ color: tokens.actionPrimary.color }} />
              <div>
                <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
                  Preferred Processing Tier
                </h3>
                <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                  Choose which AI tier to use first
                </p>
              </div>
            </div>

            <div className="space-y-2">
              {(Object.keys(preferredTierConfig) as PreferredTier[]).map((tier) => {
                const config = preferredTierConfig[tier];
                const Icon = config.icon;
                return (
                  <button
                    key={tier}
                    onClick={() => { setPreferredTier(tier); setHasChanges(true); }}
                    className="w-full flex items-center gap-4 p-4 rounded-lg text-left transition-colors"
                    style={{
                      backgroundColor: preferredTier === tier ? tokens.actionPrimary.color + '15' : tokens.surface,
                      border: `1px solid ${preferredTier === tier ? tokens.actionPrimary.color : tokens.onSurface + '20'}`,
                    }}
                  >
                    {preferredTier === tier ? (
                      <Check size={20} style={{ color: tokens.actionPrimary.color }} />
                    ) : (
                      <div className="w-5 h-5 rounded-full border-2" style={{ borderColor: tokens.onSurfaceSecondary }} />
                    )}
                    <Icon size={20} style={{ color: tokens.actionPrimary.color }} />
                    <div>
                      <div className="font-medium" style={{ color: tokens.onSurface }}>
                        {config.name}
                      </div>
                      <div className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                        {config.description}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {activeTab === 'local' && (
        <div className="space-y-6">
          {/* Section header */}
          <div className="flex items-center gap-3">
            <Monitor size={20} style={{ color: tokens.actionPrimary.color }} />
            <div>
              <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
                Local AI Providers
              </h3>
              <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                Configure locally-hosted AI models (Ollama, LM Studio)
              </p>
            </div>
          </div>

          {/* Info banner */}
          <div
            className="flex items-start gap-3 p-4 rounded-lg"
            style={{ backgroundColor: tokens.stateInfo.color + '15' }}
          >
            <Eye size={20} style={{ color: tokens.stateInfo.color }} />
            <p className="text-sm" style={{ color: tokens.onSurface }}>
              Local AI runs on your machine for privacy and offline use.
              Ensure your local AI server is running before testing.
            </p>
          </div>

          {/* Provider cards */}
          <div className="space-y-4">
            {localProviders.map(renderLocalProviderCard)}
          </div>
        </div>
      )}

      {activeTab === 'onDevice' && (
        <div className="space-y-6">
          {/* Section header */}
          <div className="flex items-center gap-3">
            <Smartphone size={20} style={{ color: tokens.actionPrimary.color }} />
            <div>
              <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
                On-Device AI
              </h3>
              <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                Configure built-in OCR and vision capabilities
              </p>
            </div>
          </div>

          {/* Browser OCR toggle */}
          <div
            className="flex items-center justify-between p-4 rounded-lg"
            style={{ backgroundColor: tokens.surface, border: `1px solid ${tokens.onSurface}20` }}
          >
            <div className="flex items-center gap-3">
              <div
                className="p-2 rounded-lg"
                style={{ backgroundColor: tokens.actionPrimary.color + '20' }}
              >
                <Eye size={24} style={{ color: tokens.actionPrimary.color }} />
              </div>
              <div>
                <div className="font-semibold" style={{ color: tokens.onSurface }}>
                  Browser OCR (Tesseract.js)
                </div>
                <div className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                  Client-side text recognition using Tesseract.js
                </div>
              </div>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={onDeviceConfig.useBrowserOCR}
                onChange={(e) => { setOnDeviceConfig({ ...onDeviceConfig, useBrowserOCR: e.target.checked }); setHasChanges(true); }}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>

          {/* Language selector */}
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <Globe size={20} style={{ color: tokens.actionPrimary.color }} />
              <div>
                <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
                  Language
                </h3>
                <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                  Preferred language for OCR recognition
                </p>
              </div>
            </div>

            <select
              value={onDeviceConfig.preferredLanguage}
              onChange={(e) => { setOnDeviceConfig({ ...onDeviceConfig, preferredLanguage: e.target.value }); setHasChanges(true); }}
              className="w-full px-4 py-3 rounded-lg border"
              style={{ backgroundColor: tokens.surface, borderColor: tokens.onSurface + '20', color: tokens.onSurface }}
            >
              <option value="en">English</option>
              <option value="zh">Chinese</option>
              <option value="ja">Japanese</option>
              <option value="ko">Korean</option>
              <option value="es">Spanish</option>
              <option value="fr">French</option>
              <option value="de">German</option>
            </select>
          </div>

          {/* Fallback settings */}
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <RefreshCw size={20} style={{ color: tokens.actionPrimary.color }} />
              <div>
                <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
                  Fallback Behavior
                </h3>
                <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                  How to handle extraction failures
                </p>
              </div>
            </div>

            <div
              className="flex items-center justify-between p-4 rounded-lg"
              style={{ backgroundColor: tokens.surface, border: `1px solid ${tokens.onSurface}20` }}
            >
              <div>
                <div className="font-semibold" style={{ color: tokens.onSurface }}>
                  Enable Automatic Fallback
                </div>
                <div className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                  Automatically try next provider if current one fails
                </div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={enableFallback}
                  onChange={(e) => { setEnableFallback(e.target.checked); setHasChanges(true); }}
                  className="sr-only peer"
                />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
              </label>
            </div>
          </div>
        </div>
      )}

      {/* Footer */}
      <section
        className="p-4 rounded-lg flex items-center justify-between"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <div className="flex items-center gap-2" style={{ color: tokens.onSurfaceSecondary }}>
          <Folder size={16} />
          <code className="text-xs">localStorage://ais-ai-settings</code>
        </div>
        <button
          className="flex items-center gap-2 px-3 py-1.5 rounded text-sm"
          style={{ color: tokens.onSurface }}
        >
          <Upload size={14} />
          Export/Import
        </button>
      </section>
    </div>
  );
}

export default AISettingsDemo;

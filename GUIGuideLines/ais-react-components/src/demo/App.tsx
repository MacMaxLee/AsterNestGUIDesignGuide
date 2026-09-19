import React, { useState } from 'react';
import { AISProvider } from '../core/AISProvider';
import { ButtonDemo } from './demos/ButtonDemo';
import { StateBadgeDemo } from './demos/StateBadgeDemo';
import { ValueComponentDemo } from './demos/ValueComponentDemo';
import { ErrorHandlingDemo } from './demos/ErrorHandlingDemo';
import { DataGridDemo } from './demos/DataGridDemo';
import {
  Palette,
  BadgeCheck,
  Hash,
  AlertCircle,
  Table,
  Moon,
  Sun,
} from 'lucide-react';

type DemoSection =
  | 'buttons'
  | 'badges'
  | 'values'
  | 'errors'
  | 'grid';

interface NavItemProps {
  id: DemoSection;
  label: string;
  icon: React.ReactNode;
  isActive: boolean;
  onClick: () => void;
}

function NavItem({ label, icon, isActive, onClick }: NavItemProps) {
  return (
    <button
      onClick={onClick}
      className={`
        w-full flex items-center gap-3 px-4 py-3 text-left rounded-lg
        transition-colors
        ${isActive
          ? 'bg-blue-500 text-white'
          : 'text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800'
        }
      `}
    >
      {icon}
      <span className="font-medium">{label}</span>
    </button>
  );
}

export function App() {
  const [activeSection, setActiveSection] = useState<DemoSection>('buttons');
  const [darkMode, setDarkMode] = useState(false);

  const navItems: { id: DemoSection; label: string; icon: React.ReactNode }[] = [
    { id: 'buttons', label: 'Buttons', icon: <Palette size={20} /> },
    { id: 'badges', label: 'State Badges', icon: <BadgeCheck size={20} /> },
    { id: 'values', label: 'Value Components', icon: <Hash size={20} /> },
    { id: 'errors', label: 'Error Handling', icon: <AlertCircle size={20} /> },
    { id: 'grid', label: 'Data Grid', icon: <Table size={20} /> },
  ];

  const renderContent = () => {
    switch (activeSection) {
      case 'buttons':
        return <ButtonDemo />;
      case 'badges':
        return <StateBadgeDemo />;
      case 'values':
        return <ValueComponentDemo />;
      case 'errors':
        return <ErrorHandlingDemo />;
      case 'grid':
        return <DataGridDemo />;
      default:
        return <ButtonDemo />;
    }
  };

  return (
    <AISProvider darkMode={darkMode}>
      <div className={`min-h-screen ${darkMode ? 'bg-gray-900' : 'bg-gray-50'}`}>
        <div className="flex">
          {/* Sidebar */}
          <aside
            className={`
              w-64 h-screen sticky top-0 p-4 border-r
              ${darkMode ? 'bg-gray-900 border-gray-700' : 'bg-white border-gray-200'}
            `}
          >
            <div className="mb-8">
              <h1
                className={`text-xl font-bold ${darkMode ? 'text-white' : 'text-gray-900'}`}
              >
                AIS Components
              </h1>
              <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                React/TypeScript v1.0
              </p>
            </div>

            <nav className="space-y-1">
              {navItems.map((item) => (
                <NavItem
                  key={item.id}
                  {...item}
                  isActive={activeSection === item.id}
                  onClick={() => setActiveSection(item.id)}
                />
              ))}
            </nav>

            <div className="absolute bottom-4 left-4 right-4">
              <button
                onClick={() => setDarkMode(!darkMode)}
                className={`
                  w-full flex items-center justify-center gap-2 px-4 py-2
                  rounded-lg border transition-colors
                  ${darkMode
                    ? 'border-gray-700 text-gray-300 hover:bg-gray-800'
                    : 'border-gray-200 text-gray-600 hover:bg-gray-100'
                  }
                `}
              >
                {darkMode ? <Sun size={18} /> : <Moon size={18} />}
                {darkMode ? 'Light Mode' : 'Dark Mode'}
              </button>
            </div>
          </aside>

          {/* Main Content */}
          <main className="flex-1 p-8">
            <div className="max-w-5xl mx-auto">
              {renderContent()}
            </div>
          </main>
        </div>
      </div>
    </AISProvider>
  );
}

export default App;

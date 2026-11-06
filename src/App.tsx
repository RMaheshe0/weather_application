import React, { useState } from 'react';
import {
  Smartphone,
  Code2,
  Columns,
  Download,
  Sparkles,
  ExternalLink,
  CloudSun,
  Github,
  CheckCircle2,
  Info,
} from 'lucide-react';
import { AndroidSimulator } from './components/AndroidSimulator';
import { CodeStudio } from './components/CodeStudio';
import JSZip from 'jszip';
import { FLUTTER_PROJECT_FILES } from './data/flutterProjectFiles';

export default function App() {
  const [layoutMode, setLayoutMode] = useState<'split' | 'phone' | 'code'>('split');
  const [isDownloading, setIsDownloading] = useState(false);

  const handleDownloadAll = async () => {
    setIsDownloading(true);
    try {
      const zip = new JSZip();
      const rootFolder = zip.folder('skypulse_weather') || zip;
      FLUTTER_PROJECT_FILES.forEach((f) => {
        rootFolder.file(f.path, f.code);
      });
      const blob = await zip.generateAsync({ type: 'blob' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = 'skypulse_weather_flutter.zip';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } catch (e) {
      console.error(e);
    } finally {
      setIsDownloading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans">
      {/* Top App Header */}
      <header className="bg-slate-900/90 backdrop-blur-md border-b border-slate-800 sticky top-0 z-50 px-4 sm:px-6 py-3 flex flex-wrap items-center justify-between gap-3 shadow-md">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-amber-500 via-orange-500 to-blue-600 flex items-center justify-center shadow-lg shadow-orange-500/20">
            <CloudSun size={24} className="text-white" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <h1 className="font-extrabold text-lg text-white tracking-tight">SkyPulse Weather</h1>
              <span className="text-[10px] font-bold bg-amber-400/20 text-amber-300 border border-amber-400/30 px-2 py-0.5 rounded-full">
                Flutter 3.35+
              </span>
              <span className="text-[10px] font-bold bg-blue-500/20 text-blue-300 border border-blue-500/30 px-2 py-0.5 rounded-full hidden sm:inline-block">
                Material 3
              </span>
            </div>
            <p className="text-xs text-slate-400">
              Complete Android Weather Forecast Application with Live Data & Exportable Codebase
            </p>
          </div>
        </div>

        {/* View Mode Switcher & Quick Download */}
        <div className="flex items-center space-x-2.5">
          {/* Mode Switcher */}
          <div className="flex bg-slate-950 border border-slate-800 p-1 rounded-xl text-xs font-semibold">
            <button
              onClick={() => setLayoutMode('split')}
              className={`flex items-center space-x-1 px-3 py-1.5 rounded-lg transition ${
                layoutMode === 'split' ? 'bg-blue-600 text-white shadow' : 'text-slate-400 hover:text-white'
              }`}
              title="Split View: Live Android App + Code Studio"
            >
              <Columns size={14} />
              <span className="hidden md:inline">Split View</span>
            </button>
            <button
              onClick={() => setLayoutMode('phone')}
              className={`flex items-center space-x-1 px-3 py-1.5 rounded-lg transition ${
                layoutMode === 'phone' ? 'bg-blue-600 text-white shadow' : 'text-slate-400 hover:text-white'
              }`}
              title="Android Phone Simulator"
            >
              <Smartphone size={14} />
              <span>Android App</span>
            </button>
            <button
              onClick={() => setLayoutMode('code')}
              className={`flex items-center space-x-1 px-3 py-1.5 rounded-lg transition ${
                layoutMode === 'code' ? 'bg-blue-600 text-white shadow' : 'text-slate-400 hover:text-white'
              }`}
              title="Flutter Code Studio"
            >
              <Code2 size={14} />
              <span>Code Studio</span>
            </button>
          </div>

          {/* Download Zip */}
          <button
            onClick={handleDownloadAll}
            disabled={isDownloading}
            className="flex items-center space-x-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-slate-950 font-bold px-3.5 py-1.5 rounded-xl text-xs shadow-lg shadow-orange-500/20 transition active:scale-95 disabled:opacity-50"
          >
            <Download size={14} className={isDownloading ? 'animate-bounce' : ''} />
            <span className="hidden sm:inline">{isDownloading ? 'Packaging...' : 'Download .ZIP'}</span>
          </button>
        </div>
      </header>

      {/* Main Workspace Layout */}
      <main className="flex-1 p-3 sm:p-5 flex flex-col overflow-hidden max-w-[1700px] w-full mx-auto">
        {layoutMode === 'split' && (
          <div className="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-5 items-start h-full">
            {/* Left: Android Simulator Column */}
            <div className="lg:col-span-5 flex flex-col items-center justify-center p-2">
              <div className="w-full flex items-center justify-between mb-2 px-3 text-xs text-slate-400">
                <span className="flex items-center space-x-1.5 text-slate-300 font-semibold">
                  <Smartphone size={15} className="text-amber-400" />
                  <span>Interactive Android Material 3 Preview</span>
                </span>
                <span className="text-[11px] text-emerald-400 flex items-center space-x-1">
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  <span>Live Weather API Active</span>
                </span>
              </div>
              <AndroidSimulator initialCity="London" />
            </div>

            {/* Right: Flutter Code Studio Column */}
            <div className="lg:col-span-7 h-[780px] flex flex-col">
              <CodeStudio />
            </div>
          </div>
        )}

        {layoutMode === 'phone' && (
          <div className="flex-1 flex flex-col items-center justify-center py-4">
            <div className="mb-3 text-center">
              <h2 className="text-sm font-bold text-white flex items-center justify-center space-x-1.5">
                <Smartphone size={16} className="text-amber-400" />
                <span>SkyPulse Android Flutter App Simulation</span>
              </h2>
              <p className="text-xs text-slate-400">
                Test real-time city search, GPS positioning, 24h & 7-day forecast, and favorites.
              </p>
            </div>
            <AndroidSimulator initialCity="London" />
          </div>
        )}

        {layoutMode === 'code' && (
          <div className="flex-1 h-[calc(100vh-100px)]">
            <CodeStudio />
          </div>
        )}
      </main>

      {/* Bottom Technical Bar */}
      <footer className="bg-slate-900 border-t border-slate-800 px-6 py-2.5 text-xs text-slate-400 flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center space-x-3">
          <span className="text-slate-300 font-medium">Architecture:</span>
          <span>Provider + ChangeNotifier</span>
          <span>•</span>
          <span>Material 3</span>
          <span>•</span>
          <span>fl_chart</span>
          <span>•</span>
          <span>Dual Weather API (OpenWeatherMap + Zero-key Fallback)</span>
        </div>
        <div className="flex items-center space-x-2 text-[11px] text-slate-500">
          <span>All 26 Flutter source files ready in /flutter_project</span>
        </div>
      </footer>
    </div>
  );
}

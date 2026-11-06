import React, { useState } from 'react';
import JSZip from 'jszip';
import {
  FileCode,
  Folder,
  Download,
  Copy,
  Check,
  Search,
  Terminal,
  BookOpen,
  Layers,
  Sparkles,
  ExternalLink,
  ChevronRight,
  ShieldCheck,
  Cpu,
} from 'lucide-react';
import { FLUTTER_PROJECT_FILES, ProjectFile } from '../data/flutterProjectFiles';

export const CodeStudio: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'code' | 'guide' | 'apk' | 'test'>('code');
  const [selectedFile, setSelectedFile] = useState<ProjectFile>(FLUTTER_PROJECT_FILES[0]);
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isCopied, setIsCopied] = useState(false);
  const [isDownloadingZip, setIsDownloadingZip] = useState(false);

  // Filtered files
  const filteredFiles = FLUTTER_PROJECT_FILES.filter((file) => {
    const matchesCategory = categoryFilter === 'all' || file.category === categoryFilter;
    const matchesSearch =
      file.path.toLowerCase().includes(searchQuery.toLowerCase()) ||
      file.description.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const handleCopyCode = () => {
    if (!selectedFile) return;
    navigator.clipboard.writeText(selectedFile.code);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  const handleDownloadZip = async () => {
    setIsDownloadingZip(true);
    try {
      const zip = new JSZip();
      const rootFolder = zip.folder('skypulse_weather') || zip;

      // Add each project file to the zip
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
    } catch (err) {
      console.error('Failed to create zip', err);
    } finally {
      setIsDownloadingZip(false);
    }
  };

  const categories = [
    { id: 'all', label: 'All Files' },
    { id: 'screen', label: 'Screens' },
    { id: 'widget', label: 'Widgets' },
    { id: 'provider', label: 'Provider' },
    { id: 'service', label: 'Services' },
    { id: 'model', label: 'Models' },
    { id: 'util', label: 'Utils' },
    { id: 'test', label: 'Tests' },
    { id: 'config', label: 'Config' },
  ];

  return (
    <div className="flex flex-col h-full bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl text-slate-100">
      {/* Top Header Bar */}
      <div className="flex flex-wrap items-center justify-between px-5 py-3.5 bg-slate-950/80 border-b border-slate-800 gap-3">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-gradient-to-tr from-cyan-500 to-blue-600 rounded-xl shadow">
            <Layers size={20} className="text-white" />
          </div>
          <div>
            <h2 className="font-bold text-base text-white flex items-center space-x-2">
              <span>Flutter Project Studio</span>
              <span className="text-[10px] bg-cyan-500/20 text-cyan-400 font-semibold px-2 py-0.5 rounded-full border border-cyan-500/30">
                Flutter 3.35+ • Null Safe
              </span>
            </h2>
            <p className="text-xs text-slate-400">Complete, production-ready Android codebase</p>
          </div>
        </div>

        {/* Tab Switcher & Download Button */}
        <div className="flex items-center space-x-2">
          <div className="flex bg-slate-900 border border-slate-800 p-1 rounded-xl text-xs font-semibold">
            <button
              onClick={() => setActiveTab('code')}
              className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-lg transition ${
                activeTab === 'code' ? 'bg-cyan-500 text-slate-950 shadow' : 'text-slate-400 hover:text-white'
              }`}
            >
              <FileCode size={14} />
              <span>Source Files</span>
            </button>
            <button
              onClick={() => setActiveTab('guide')}
              className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-lg transition ${
                activeTab === 'guide' ? 'bg-cyan-500 text-slate-950 shadow' : 'text-slate-400 hover:text-white'
              }`}
            >
              <Terminal size={14} />
              <span>Run Guide</span>
            </button>
            <button
              onClick={() => setActiveTab('apk')}
              className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-lg transition ${
                activeTab === 'apk' ? 'bg-cyan-500 text-slate-950 shadow' : 'text-slate-400 hover:text-white'
              }`}
            >
              <Cpu size={14} />
              <span>Release APK</span>
            </button>
            <button
              onClick={() => setActiveTab('test')}
              className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-lg transition ${
                activeTab === 'test' ? 'bg-cyan-500 text-slate-950 shadow' : 'text-slate-400 hover:text-white'
              }`}
            >
              <ShieldCheck size={14} />
              <span>Tests</span>
            </button>
          </div>

          <button
            onClick={handleDownloadZip}
            disabled={isDownloadingZip}
            className="flex items-center space-x-2 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-slate-950 font-bold px-3.5 py-1.5 rounded-xl text-xs shadow-lg transition active:scale-95 disabled:opacity-50"
          >
            <Download size={14} className={isDownloadingZip ? 'animate-bounce' : ''} />
            <span>{isDownloadingZip ? 'Zipping...' : 'Download Project .ZIP'}</span>
          </button>
        </div>
      </div>

      {/* Main Studio Viewport */}
      {activeTab === 'code' && (
        <div className="flex-1 flex flex-col md:flex-row overflow-hidden">
          {/* Left: File Explorer Sidebar */}
          <div className="w-full md:w-80 bg-slate-950/50 border-r border-slate-800 flex flex-col h-64 md:h-full">
            {/* Search Files */}
            <div className="p-3 border-b border-slate-800">
              <div className="flex items-center bg-slate-900 border border-slate-800 rounded-xl px-2.5 py-1.5 text-xs text-slate-300 focus-within:border-cyan-500 transition">
                <Search size={14} className="text-slate-500 mr-2 shrink-0" />
                <input
                  type="text"
                  placeholder="Filter files..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="bg-transparent w-full focus:outline-none placeholder-slate-500 text-xs"
                />
              </div>

              {/* Category Filters */}
              <div className="flex flex-wrap gap-1 mt-2.5">
                {categories.map((c) => (
                  <button
                    key={c.id}
                    onClick={() => setCategoryFilter(c.id)}
                    className={`text-[10px] px-2 py-0.5 rounded-md font-medium transition ${
                      categoryFilter === c.id
                        ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/40'
                        : 'text-slate-400 hover:bg-slate-800'
                    }`}
                  >
                    {c.label}
                  </button>
                ))}
              </div>
            </div>

            {/* File List */}
            <div className="flex-1 overflow-y-auto p-2 space-y-1">
              {filteredFiles.map((f, idx) => {
                const isSelected = selectedFile?.path === f.path;
                return (
                  <div
                    key={idx}
                    onClick={() => setSelectedFile(f)}
                    className={`flex items-start space-x-2.5 p-2 rounded-xl cursor-pointer text-xs transition ${
                      isSelected
                        ? 'bg-cyan-950/60 text-cyan-300 border border-cyan-500/30'
                        : 'text-slate-300 hover:bg-slate-800/60'
                    }`}
                  >
                    <FileCode
                      size={15}
                      className={`mt-0.5 shrink-0 ${isSelected ? 'text-cyan-400' : 'text-slate-500'}`}
                    />
                    <div className="flex-1 overflow-hidden">
                      <p className="font-semibold truncate">{f.name}</p>
                      <p className="text-[10px] text-slate-400 truncate">{f.path}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Right: Code Viewer */}
          <div className="flex-1 flex flex-col h-full bg-slate-900/60 overflow-hidden">
            {selectedFile ? (
              <>
                {/* Code Viewer Header */}
                <div className="flex items-center justify-between px-5 py-2.5 bg-slate-950/40 border-b border-slate-800">
                  <div className="flex items-center space-x-2 overflow-hidden">
                    <span className="text-xs font-mono font-semibold text-cyan-400 truncate">
                      {selectedFile.path}
                    </span>
                    <span className="text-[10px] px-2 py-0.5 rounded-md bg-slate-800 text-slate-400 font-mono">
                      {selectedFile.code.split('\n').length} lines
                    </span>
                  </div>

                  <button
                    onClick={handleCopyCode}
                    className="flex items-center space-x-1 px-3 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs text-slate-200 transition active:scale-95 border border-slate-700"
                  >
                    {isCopied ? <Check size={14} className="text-emerald-400" /> : <Copy size={14} />}
                    <span>{isCopied ? 'Copied!' : 'Copy Code'}</span>
                  </button>
                </div>

                {/* File description banner */}
                <div className="px-5 py-2 bg-slate-900/40 border-b border-slate-800/80 text-[11px] text-slate-400 flex items-center space-x-2">
                  <Sparkles size={13} className="text-cyan-400 shrink-0" />
                  <span>{selectedFile.description}</span>
                </div>

                {/* Code Lines Display */}
                <div className="flex-1 overflow-auto p-4 font-mono text-xs leading-relaxed bg-[#0d1117] text-slate-200 select-text">
                  <pre className="overflow-x-auto">
                    <code>
                      {selectedFile.code.split('\n').map((line, i) => (
                        <div key={i} className="table-row hover:bg-slate-800/30">
                          <span className="table-cell text-right pr-4 text-slate-600 select-none text-[11px] w-10">
                            {i + 1}
                          </span>
                          <span className="table-cell whitespace-pre">{line || ' '}</span>
                        </div>
                      ))}
                    </code>
                  </pre>
                </div>
              </>
            ) : (
              <div className="flex-1 flex items-center justify-center text-slate-500 text-sm">
                Select a file on the left to inspect its code.
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB: RUN GUIDE */}
      {activeTab === 'guide' && (
        <div className="flex-1 p-6 overflow-y-auto space-y-6 text-xs max-w-4xl mx-auto">
          <div className="bg-slate-950/70 border border-slate-800 rounded-2xl p-5 space-y-3">
            <h3 className="text-sm font-bold text-cyan-400 flex items-center space-x-2">
              <Terminal size={16} />
              <span>How to Run on Android Emulator or Physical Device</span>
            </h3>
            <p className="text-slate-300">
              SkyPulse is structured to run directly on any Android device with Flutter 3.35+ or newer.
            </p>

            <div className="space-y-3 mt-4">
              <div className="space-y-1">
                <p className="font-semibold text-slate-200">1. Download or Unzip the project</p>
                <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-cyan-300">
                  cd skypulse_weather
                </div>
              </div>

              <div className="space-y-1">
                <p className="font-semibold text-slate-200">2. Install all Flutter dependencies</p>
                <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-cyan-300">
                  flutter pub get
                </div>
              </div>

              <div className="space-y-1">
                <p className="font-semibold text-slate-200">3. Connect an Android phone or launch an Android emulator</p>
                <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-cyan-300">
                  flutter devices
                </div>
              </div>

              <div className="space-y-1">
                <p className="font-semibold text-slate-200">4. Run the app in debug or release mode</p>
                <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-cyan-300">
                  flutter run
                </div>
                <p className="text-[11px] text-slate-400">
                  Optional: Pass your OpenWeatherMap API key via compile-time define:
                </p>
                <div className="bg-[#0b0f19] p-2.5 rounded-xl border border-slate-800 font-mono text-emerald-400 text-[11px]">
                  flutter run --dart-define=OWM_KEY=YOUR_OPENWEATHERMAP_API_KEY
                </div>
              </div>
            </div>
          </div>

          <div className="bg-slate-950/70 border border-slate-800 rounded-2xl p-5 space-y-3">
            <h3 className="text-sm font-bold text-amber-400 flex items-center space-x-2">
              <Sparkles size={16} />
              <span>Dual Weather API Engine (Zero-Configuration Reliability)</span>
            </h3>
            <p className="text-slate-300 leading-relaxed">
              To guarantee that the app functions immediately on any Android phone without throwing 401 Unauthorized errors, SkyPulse includes a <strong>hybrid meteorological failover</strong>:
            </p>
            <ul className="list-disc list-inside space-y-1.5 text-slate-400">
              <li>
                <strong>Built-in Live Engine (Default)</strong>: Connects to the open-access WMO-standard live meteorological service with global geocoding, 24-hour hourly, and 7-day forecast.
              </li>
              <li>
                <strong>OpenWeatherMap Integration</strong>: If you provide an OpenWeatherMap API key (either via Settings UI or compile flag), SkyPulse automatically switches to OpenWeatherMap 2.5 API!
              </li>
            </ul>
          </div>
        </div>
      )}

      {/* TAB: RELEASE APK GUIDE */}
      {activeTab === 'apk' && (
        <div className="flex-1 p-6 overflow-y-auto space-y-6 text-xs max-w-4xl mx-auto">
          <div className="bg-slate-950/70 border border-slate-800 rounded-2xl p-5 space-y-4">
            <h3 className="text-sm font-bold text-emerald-400 flex items-center space-x-2">
              <Cpu size={16} />
              <span>Building a Standalone Release APK</span>
            </h3>
            <p className="text-slate-300 leading-relaxed">
              Follow these commands to generate an optimized Android installation package (.APK) that can be transferred and installed on physical Android devices.
            </p>

            <div className="space-y-3">
              <div className="space-y-1">
                <p className="font-semibold text-slate-200">Standard Fat APK (All Architectures)</p>
                <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-emerald-400">
                  flutter build apk --release
                </div>
                <p className="text-[11px] text-slate-400">
                  Output file: <code className="text-slate-200">build/app/outputs/flutter-apk/app-release.apk</code>
                </p>
              </div>

              <div className="space-y-1">
                <p className="font-semibold text-slate-200">Split-per-ABI APK (Significantly smaller download size)</p>
                <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-emerald-400">
                  flutter build apk --split-per-abi --release
                </div>
                <p className="text-[11px] text-slate-400">
                  Generates <code className="text-slate-200">app-arm64-v8a-release.apk</code> and <code className="text-slate-200">app-armeabi-v7a-release.apk</code>.
                </p>
              </div>

              <div className="space-y-1">
                <p className="font-semibold text-slate-200">Google Play Store App Bundle (.AAB)</p>
                <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-emerald-400">
                  flutter build appbundle --release
                </div>
                <p className="text-[11px] text-slate-400">
                  Output file: <code className="text-slate-200">build/app/outputs/bundle/release/app-release.aab</code>
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB: TESTS GUIDE */}
      {activeTab === 'test' && (
        <div className="flex-1 p-6 overflow-y-auto space-y-6 text-xs max-w-4xl mx-auto">
          <div className="bg-slate-950/70 border border-slate-800 rounded-2xl p-5 space-y-4">
            <h3 className="text-sm font-bold text-purple-400 flex items-center space-x-2">
              <ShieldCheck size={16} />
              <span>Automated Flutter Widget Tests</span>
            </h3>
            <p className="text-slate-300">
              SkyPulse includes automated Flutter widget tests in <code className="text-cyan-400">test/widget_test.dart</code> to verify:
            </p>
            <ul className="list-disc list-inside space-y-1 text-slate-400">
              <li>Correct rendering of city name, condition, and formatted temperature in <strong>CurrentWeatherCard</strong>.</li>
              <li>Validation of min/max temperature displays.</li>
              <li>Verification of humidity, pressure, visibility, and wind metrics in <strong>WeatherDetailsCard</strong>.</li>
            </ul>

            <div className="space-y-2 mt-4">
              <p className="font-semibold text-slate-200">Run the widget test suite:</p>
              <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-purple-300">
                flutter test
              </div>
              <p className="text-[11px] text-slate-400">Or execute the specific test file:</p>
              <div className="bg-[#0b0f19] p-3 rounded-xl border border-slate-800 font-mono text-purple-300">
                flutter test test/widget_test.dart
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

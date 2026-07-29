import { Component, lazy, Suspense } from 'react';
import SimPlayer from '../components/SimPlayer';
import { SIM_SCRIPTS } from '../data/simScripts';

class ErrorBoundary extends Component {
  constructor(props) { super(props); this.state = { error: null }; }
  static getDerivedStateFromError(error) { return { error }; }
  render() {
    if (this.state.error) {
      return (
        <div className="uk-term">
          <div className="uk-term-body" style={{ color: '#f85149' }}>
            <div className="uk-line uk-red">Component error: {this.state.error.message}</div>
            <button className="uk-btn uk-btn-ghost uk-btn-sm" style={{ marginTop: 10 }} onClick={() => this.setState({ error: null })}>
              ↻ Retry
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

const REAL_COMPONENTS = {
  PasswordGen: lazy(() => import('./real/PasswordGen')),
  UuidGen: lazy(() => import('./real/UuidGen')),
  HashTools: lazy(() => import('./real/HashTools')),
  TimeConvert: lazy(() => import('./real/TimeConvert')),
  RegexLab: lazy(() => import('./real/RegexLab')),
  JsonExplorer: lazy(() => import('./real/JsonExplorer')),
  CsvToolkit: lazy(() => import('./real/CsvToolkit')),
  YamlToolkit: lazy(() => import('./real/YamlToolkit')),
  QrTool: lazy(() => import('./real/QrTool')),
  LicenseHelper: lazy(() => import('./real/LicenseHelper')),
  TodoManager: lazy(() => import('./real/TodoManager')),
  SecretScan: lazy(() => import('./real/SecretScan')),
  MarkdownToc: lazy(() => import('./real/MarkdownToc')),
  PomodoroTimer: lazy(() => import('./real/PomodoroTimer')),
  Weather: lazy(() => import('./real/Weather')),
  IpInfo: lazy(() => import('./real/IpInfo')),
  DnsProbe: lazy(() => import('./real/DnsProbe')),
  LinkChecker: lazy(() => import('./real/LinkChecker')),
  ApiTester: lazy(() => import('./real/ApiTester')),
  HttpBench: lazy(() => import('./real/HttpBench')),
  CronManager: lazy(() => import('./real/CronManager')),
  CheatSheet: lazy(() => import('./real/CheatSheet')),
  EnvManager: lazy(() => import('./real/EnvManager')),
};

export default function ToolPlayer({ tool }) {
  if (tool.kind === 'real') {
    const Comp = REAL_COMPONENTS[tool.component];
    if (!Comp) return <div style={{ color: '#f85149' }}>Missing component: {tool.component}</div>;
    return (
      <ErrorBoundary key={tool.id}>
        <Suspense fallback={<div style={{ color: '#7d8590', padding: 24 }}>Loading…</div>}>
          <Comp />
        </Suspense>
      </ErrorBoundary>
    );
  }

  const scenarios = SIM_SCRIPTS[tool.id];
  if (!scenarios) return <div style={{ color: '#f85149' }}>Missing simulation script: {tool.id}</div>;

  return <SimPlayer key={tool.id} title={`${tool.cmd} — ${tool.name}`} subtitle={`_${tool.id}.sh`} scenarios={scenarios} />;
}

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
  PasswordGen: lazy(() => import('../tools/real/PasswordGen')),
  UuidGen: lazy(() => import('../tools/real/UuidGen')),
  HashTools: lazy(() => import('../tools/real/HashTools')),
  TimeConvert: lazy(() => import('../tools/real/TimeConvert')),
  RegexLab: lazy(() => import('../tools/real/RegexLab')),
  JsonExplorer: lazy(() => import('../tools/real/JsonExplorer')),
  CsvToolkit: lazy(() => import('../tools/real/CsvToolkit')),
  YamlToolkit: lazy(() => import('../tools/real/YamlToolkit')),
  QrTool: lazy(() => import('../tools/real/QrTool')),
  LicenseHelper: lazy(() => import('../tools/real/LicenseHelper')),
  TodoManager: lazy(() => import('../tools/real/TodoManager')),
  SecretScan: lazy(() => import('../tools/real/SecretScan')),
  MarkdownToc: lazy(() => import('../tools/real/MarkdownToc')),
  PomodoroTimer: lazy(() => import('../tools/real/PomodoroTimer')),
  Weather: lazy(() => import('../tools/real/Weather')),
  IpInfo: lazy(() => import('../tools/real/IpInfo')),
  DnsProbe: lazy(() => import('../tools/real/DnsProbe')),
  LinkChecker: lazy(() => import('../tools/real/LinkChecker')),
  ApiTester: lazy(() => import('../tools/real/ApiTester')),
  HttpBench: lazy(() => import('../tools/real/HttpBench')),
  CronManager: lazy(() => import('../tools/real/CronManager')),
  CheatSheet: lazy(() => import('../tools/real/CheatSheet')),
  EnvManager: lazy(() => import('../tools/real/EnvManager')),
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

  const script = SIM_SCRIPTS[tool.id];
  if (!script) return <div style={{ color: '#f85149' }}>Missing simulation script: {tool.id}</div>;

  return <SimPlayer key={tool.id} title={`${tool.cmd} — ${tool.name}`} subtitle={`_${tool.id}.sh`} script={script} />;
}

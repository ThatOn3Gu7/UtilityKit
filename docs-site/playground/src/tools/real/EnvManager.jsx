import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';

function parseEnv(text) {
  const vars = {};
  text.split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const idx = trimmed.indexOf('=');
    if (idx <= 0) return;
    const key = trimmed.slice(0, idx).trim();
    let val = trimmed.slice(idx + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    vars[key] = val;
  });
  return vars;
}

export default function EnvManager() {
  const [envText, setEnvText] = useState('DATABASE_URL=postgres://localhost:5432/mydb\nAPI_KEY=sk_live_abc123\nDEBUG=false\nPORT=3000');
  const [exampleText, setExampleText] = useState('DATABASE_URL=\nAPI_KEY=\nDEBUG=true\nREDIS_URL=');
  const [mode, setMode] = useState('edit');

  const envVars = useMemo(() => parseEnv(envText), [envText]);
  const exampleVars = useMemo(() => parseEnv(exampleText), [exampleText]);

  const comparison = useMemo(() => {
    if (mode !== 'compare') return null;
    const allKeys = new Set([...Object.keys(envVars), ...Object.keys(exampleVars)]);
    const rows = [];
    allKeys.forEach((key) => {
      const inEnv = key in envVars;
      const inExample = key in exampleVars;
      if (inEnv && inExample) rows.push({ key, status: 'present', envVal: envVars[key], exampleVal: exampleVars[key] });
      else if (!inEnv && inExample) rows.push({ key, status: 'missing', envVal: '', exampleVal: exampleVars[key] });
      else rows.push({ key, status: 'extra', envVal: envVars[key], exampleVal: '' });
    });
    return rows.sort((a, b) => a.key.localeCompare(b.key));
  }, [mode, envVars, exampleVars]);

  return (
    <TerminalShell
      title="env — Env Manager"
      subtitle="_env_manager.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Parsed client-side — no data is sent anywhere."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Mode</label>
          <select className="uk-select" value={mode} onChange={(e) => setMode(e.target.value)}>
            <option value="edit">Edit .env</option>
            <option value="compare">Compare with .env.example</option>
          </select>
        </div>
      </div>

      {mode === 'edit' ? (
        <>
          <div className="uk-field">
            <label>.env content</label>
            <textarea className="uk-textarea" style={{ minHeight: 150 }} value={envText} onChange={(e) => setEnvText(e.target.value)} />
          </div>
          <div className="uk-out-box">
            <div className="uk-dim" style={{ fontSize: 11, marginBottom: 6 }}>Parsed variables ({Object.keys(envVars).length}):</div>
            {Object.entries(envVars).map(([k, v]) => (
              <div key={k} className="uk-line" style={{ fontSize: 12, padding: '1px 0' }}>
                <span className="uk-cyan">{k}</span><span className="uk-dim">=</span>{v ? <span>{v}</span> : <span className="uk-dim" style={{ fontStyle: 'italic' }}>(empty)</span>}
              </div>
            ))}
          </div>
        </>
      ) : (
        <>
          <div className="uk-row">
            <div className="uk-field" style={{ flex: 1 }}>
              <label>.env</label>
              <textarea className="uk-textarea" style={{ minHeight: 120 }} value={envText} onChange={(e) => setEnvText(e.target.value)} />
            </div>
            <div className="uk-field" style={{ flex: 1 }}>
              <label>.env.example</label>
              <textarea className="uk-textarea" style={{ minHeight: 120 }} value={exampleText} onChange={(e) => setExampleText(e.target.value)} />
            </div>
          </div>
          <div className="uk-out-box">
            {comparison && comparison.length === 0 && <div className="uk-dim">Both files are empty.</div>}
            {comparison && comparison.map((row) => (
              <div key={row.key} className="uk-line" style={{ display: 'flex', gap: 8, padding: '3px 0', fontSize: 12 }}>
                {row.status === 'present' && <span className="uk-line" style={{ color: '#3fb950' }}>✔</span>}
                {row.status === 'missing' && <span className="uk-red">✖</span>}
                {row.status === 'extra' && <span className="uk-yellow">⚠</span>}
                <span className="uk-cyan" style={{ minWidth: 120 }}>{row.key}</span>
                {row.status === 'missing' && <span className="uk-red">missing from .env</span>}
                {row.status === 'extra' && <span className="uk-yellow">extra in .env</span>}
                {row.status === 'present' && row.envVal !== row.exampleVal && (
                  <span className="uk-yellow" style={{ fontSize: 11 }}>
                    {row.envVal || <span className="uk-dim">(empty)</span>} → {row.exampleVal || <span className="uk-dim">(empty)</span>}
                  </span>
                )}
              </div>
            ))}
          </div>
        </>
      )}
    </TerminalShell>
  );
}

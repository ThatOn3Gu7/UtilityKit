import { useState, useMemo } from 'react';
import * as yaml from 'js-yaml';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

export default function YamlToolkit() {
  const [raw, setRaw] = useState('database:\n  host: localhost\n  port: 5432\nfeatures:\n  - auth\n  - billing\n');
  const [mode, setMode] = useState('lint');

  const { parsed, error } = useMemo(() => {
    try {
      return { parsed: yaml.load(raw), error: null };
    } catch (e) {
      return { parsed: null, error: e.message };
    }
  }, [raw]);

  const output = useMemo(() => {
    if (error) return null;
    if (mode === 'tojson') return JSON.stringify(parsed, null, 2);
    if (mode === 'keys') return parsed && typeof parsed === 'object' ? Object.keys(parsed).join('\n') : '(not a mapping)';
    if (mode === 'pretty') return yaml.dump(parsed, { indent: 2 });
    return null;
  }, [mode, parsed, error]);

  return (
    <TerminalShell
      title="yaml — YAML Toolkit"
      subtitle="_yaml_toolkit.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Parsed with js-yaml in-browser — equivalent to the CLI's python3+PyYAML fallback path."
    >
      <div className="uk-field">
        <label>YAML input</label>
        <textarea className="uk-textarea" style={{ minHeight: 130 }} value={raw} onChange={(e) => setRaw(e.target.value)} />
      </div>

      <div className="uk-row">
        <div className="uk-field">
          <label>Action</label>
          <select className="uk-select" value={mode} onChange={(e) => setMode(e.target.value)}>
            <option value="lint">lint</option>
            <option value="tojson">tojson</option>
            <option value="keys">keys</option>
            <option value="pretty">pretty</option>
          </select>
        </div>
      </div>

      <div className="uk-out-box">
        {error ? (
          <div className="uk-red">Invalid YAML: {error}</div>
        ) : mode === 'lint' ? (
          <div className="uk-line" style={{ color: '#3fb950' }}>✔ Valid YAML</div>
        ) : (
          <>
            <CopyButton text={output || ''} />
            <pre className="uk-line uk-cyan" style={{ margin: 0, fontSize: 12.5, paddingRight: 60 }}>
              {output}
            </pre>
          </>
        )}
      </div>
    </TerminalShell>
  );
}

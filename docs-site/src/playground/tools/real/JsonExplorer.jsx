import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

function getPath(obj, path) {
  if (!path) return obj;
  const parts = path.split('.').filter(Boolean);
  let cur = obj;
  for (const p of parts) {
    if (cur == null) return undefined;
    cur = Array.isArray(cur) && /^\d+$/.test(p) ? cur[Number(p)] : cur[p];
  }
  return cur;
}

export default function JsonExplorer() {
  const [raw, setRaw] = useState('{\n  "users": [\n    { "name": "ada", "email": "ada@example.com" }\n  ],\n  "ok": true\n}');
  const [path, setPath] = useState('users.0.name');

  const { parsed, error } = useMemo(() => {
    try {
      return { parsed: JSON.parse(raw), error: null };
    } catch (e) {
      return { parsed: null, error: e.message };
    }
  }, [raw]);

  const extracted = useMemo(() => {
    if (!parsed) return undefined;
    try {
      return getPath(parsed, path);
    } catch {
      return undefined;
    }
  }, [parsed, path]);

  const keys = parsed && typeof parsed === 'object' ? Object.keys(parsed) : [];
  const pretty = parsed ? JSON.stringify(parsed, null, 2) : '';
  const extractedStr = extracted === undefined ? '(path not found)' : typeof extracted === 'object' ? JSON.stringify(extracted, null, 2) : String(extracted);

  return (
    <TerminalShell
      title="json — JSON Explorer"
      subtitle="_json_explorer.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Parsed and traversed with JSON.parse — same dot-path semantics as the CLI."
    >
      <div className="uk-field">
        <label>JSON input</label>
        <textarea className="uk-textarea" style={{ minHeight: 110, fontSize: 12.5 }} value={raw} onChange={(e) => setRaw(e.target.value)} />
      </div>

      {error ? (
        <div className="uk-out-box uk-red">[ERR] Invalid JSON input: {error}</div>
      ) : (
        <>
          <div className="uk-row">
            <div className="uk-field" style={{ flex: 2 }}>
              <label>Dot path</label>
              <input className="uk-input" value={path} onChange={(e) => setPath(e.target.value)} />
            </div>
          </div>

          <div className="uk-out-box">
            <CopyButton text={extractedStr} />
            <div className="uk-dim" style={{ fontSize: 11, marginBottom: 4 }}>
              Extracted: {path || '(root)'}
            </div>
            <pre className="uk-line uk-cyan" style={{ margin: 0, fontSize: 12.5, paddingRight: 60 }}>
              {extractedStr}
            </pre>
          </div>

          <div className="uk-dim" style={{ fontSize: 11, marginTop: 12, marginBottom: 4 }}>
            Top-level keys: {keys.length ? keys.join(', ') : '(not an object)'}
          </div>
          <details>
            <summary className="uk-dim" style={{ fontSize: 11, cursor: 'pointer' }}>
              Pretty-printed full document
            </summary>
            <pre className="uk-line" style={{ fontSize: 11.5, marginTop: 6 }}>{pretty}</pre>
          </details>
        </>
      )}
    </TerminalShell>
  );
}

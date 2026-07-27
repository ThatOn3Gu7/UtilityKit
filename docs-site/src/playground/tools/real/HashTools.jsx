import { useState, useCallback, useRef } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

const ALGOS = { 'SHA-256': 'SHA-256', 'SHA-1': 'SHA-1', 'SHA-384': 'SHA-384', 'SHA-512': 'SHA-512' };

async function hashBuffer(buf, algo) {
  const digest = await crypto.subtle.digest(algo, buf);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

export default function HashTools() {
  const [text, setText] = useState('The quick brown fox jumps over the lazy dog');
  const [algo, setAlgo] = useState('SHA-256');
  const [fileName, setFileName] = useState('');
  const [results, setResults] = useState([]);
  const [busy, setBusy] = useState(false);
  const fileRef = useRef(null);

  const hashText = useCallback(async () => {
    setBusy(true);
    const buf = new TextEncoder().encode(text);
    const digest = await hashBuffer(buf, algo);
    setResults((r) => [{ id: Math.random(), label: 'stdin', algo, digest }, ...r].slice(0, 8));
    setBusy(false);
  }, [text, algo]);

  const hashFile = useCallback(
    async (file) => {
      setBusy(true);
      setFileName(file.name);
      const buf = await file.arrayBuffer();
      const digest = await hashBuffer(buf, algo);
      setResults((r) => [{ id: Math.random(), label: file.name, algo, digest }, ...r].slice(0, 8));
      setBusy(false);
    },
    [algo]
  );

  return (
    <TerminalShell
      title="hash — Hash Tools"
      subtitle="_hash_tools.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Hashed locally with the Web Crypto API — files never leave your browser."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 2 }}>
          <label>Algorithm</label>
          <select className="uk-select" value={algo} onChange={(e) => setAlgo(e.target.value)}>
            {Object.keys(ALGOS).map((a) => (
              <option key={a} value={a}>
                {a}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="uk-field">
        <label>Text to hash</label>
        <textarea className="uk-textarea" value={text} onChange={(e) => setText(e.target.value)} />
      </div>

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <button className="uk-btn" onClick={hashText} disabled={busy}>
          ⚙ Hash text
        </button>
        <button className="uk-btn uk-btn-ghost" onClick={() => fileRef.current?.click()} disabled={busy}>
          📄 Hash file…
        </button>
        <input
          ref={fileRef}
          type="file"
          style={{ display: 'none' }}
          onChange={(e) => e.target.files[0] && hashFile(e.target.files[0])}
        />
      </div>

      {results.length > 0 && (
        <div className="uk-out-box">
          {results.map((r) => (
            <div key={r.id} style={{ marginBottom: 8, position: 'relative', paddingRight: 60 }}>
              <div className="uk-dim" style={{ fontSize: 11 }}>
                {r.algo} &nbsp;{r.label}
              </div>
              <div className="uk-line uk-cyan" style={{ fontSize: 12, wordBreak: 'break-all' }}>
                {r.digest}
              </div>
              <div style={{ position: 'absolute', top: 0, right: 0 }}>
                <CopyButton text={r.digest} className="uk-copy-btn" />
              </div>
            </div>
          ))}
        </div>
      )}
    </TerminalShell>
  );
}

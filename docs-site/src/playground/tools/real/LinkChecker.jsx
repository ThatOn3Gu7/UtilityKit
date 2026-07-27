import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';

function extractUrls(text) {
  const urlRe = /https?:\/\/[^\s'"<>)\]]+/g;
  const matches = text.match(urlRe);
  return matches ? [...new Set(matches)] : [];
}

async function checkUrl(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8000);
  const start = performance.now();
  try {
    const res = await fetch(url, { method: 'HEAD', signal: controller.signal, mode: 'no-cors' });
    const elapsed = Math.round(performance.now() - start);
    clearTimeout(timer);
    return { url, ok: true, status: res.status, statusText: res.statusText || '', ms: elapsed };
  } catch (e) {
    clearTimeout(timer);
    // Try GET as fallback for servers that reject HEAD
    try {
      const controller2 = new AbortController();
      const timer2 = setTimeout(() => controller2.abort(), 8000);
      const start2 = performance.now();
      const res2 = await fetch(url, { signal: controller2.signal, mode: 'no-cors' });
      const elapsed = Math.round(performance.now() - start2);
      clearTimeout(timer2);
      return { url, ok: true, status: res2.status, statusText: res2.statusText || '', ms: elapsed };
    } catch {
      return { url, ok: false, error: e.message.includes('abort') ? 'timeout' : e.message };
    }
  }
}

export default function LinkChecker() {
  const [text, setText] = useState('# Docs\n\nSee [Getting Started](../getting-started) and visit https://example.com.');
  const [results, setResults] = useState([]);
  const [busy, setBusy] = useState(false);

  const checkAll = useCallback(async () => {
    const urls = extractUrls(text);
    if (urls.length === 0) return;
    setBusy(true);
    setResults(urls.map((u) => ({ url: u, ok: null, status: 'pending', ms: null })));
    for (let i = 0; i < urls.length; i++) {
      const res = await checkUrl(urls[i]);
      setResults((r) => r.map((item, j) => (j === i ? { url: res.url, ok: res.ok, status: res.ok ? res.status : 'ERR', ms: res.ms, error: res.error } : item)));
    }
    setBusy(false);
  }, [text]);

  return (
    <TerminalShell
      title="links — Link Checker"
      subtitle="_link_checker.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Checks each URL via HEAD (GET fallback). External domains may block cross-origin HEAD — results are best-effort."
    >
      <div className="uk-field">
        <label>Markdown or text with URLs</label>
        <textarea className="uk-textarea" style={{ minHeight: 110 }} value={text} onChange={(e) => setText(e.target.value)} />
      </div>
      <button className="uk-btn" onClick={checkAll} disabled={busy}>
        {busy ? '⟳ Checking…' : '🔗 Check URLs'}
      </button>
      <div className="uk-dim" style={{ fontSize: 11, marginTop: 4 }}>
        {extractUrls(text).length} URL(s) found
      </div>

      {results.length > 0 && (
        <div className="uk-out-box">
          {results.map((r, i) => (
            <div key={i} className="uk-line" style={{ display: 'flex', gap: 8, padding: '2px 0', alignItems: 'center' }}>
              {r.ok === null ? (
                <span className="uk-dim">⟳</span>
              ) : r.ok ? (
                <span className="uk-line" style={{ color: '#3fb950' }}>✔</span>
              ) : (
                <span className="uk-red">✖</span>
              )}
              <span className="uk-cyan" style={{ flex: 1, fontSize: 12, wordBreak: 'break-all' }}>{r.url}</span>
              {r.ok !== null && (
                <span className="uk-dim" style={{ fontSize: 10, whiteSpace: 'nowrap' }}>
                  {r.ok ? `${r.status} ${r.ms}ms` : r.error === 'timeout' ? 'timeout' : r.error || 'ERR'}
                </span>
              )}
            </div>
          ))}
        </div>
      )}
    </TerminalShell>
  );
}

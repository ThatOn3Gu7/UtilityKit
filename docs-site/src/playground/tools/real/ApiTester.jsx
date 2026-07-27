import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

const METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];

export default function ApiTester() {
  const [method, setMethod] = useState('GET');
  const [url, setUrl] = useState('https://jsonplaceholder.typicode.com/todos/1');
  const [headers, setHeaders] = useState('Content-Type: application/json');
  const [body, setBody] = useState('');
  const [status, setStatus] = useState('idle');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const send = useCallback(async () => {
    if (!url.trim()) return;
    setStatus('loading');
    setError(null);
    setResult(null);
    try {
      const parsedHeaders = {};
      if (headers.trim()) {
        headers.split('\n').forEach((line) => {
          const idx = line.indexOf(':');
          if (idx > 0) parsedHeaders[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
        });
      }
      const start = performance.now();
      const res = await fetch(url, {
        method,
        headers: parsedHeaders,
        body: method === 'GET' || method === 'HEAD' ? undefined : body || undefined,
      });
      const elapsed = Math.round(performance.now() - start);
      const contentType = res.headers.get('content-type') || '';
      let responseBody;
      if (contentType.includes('application/json')) {
        responseBody = JSON.stringify(await res.json(), null, 2);
      } else {
        responseBody = await res.text();
      }
      const responseHeaders = {};
      res.headers.forEach((v, k) => { responseHeaders[k] = v; });
      setResult({
        status: res.status,
        statusText: res.statusText,
        ms: elapsed,
        body: responseBody,
        contentType,
        headers: responseHeaders,
      });
      setStatus('done');
    } catch (e) {
      setError(e.message);
      setStatus('error');
    }
  }, [method, url, headers, body]);

  return (
    <TerminalShell
      title="api — API Tester"
      subtitle="_api_tester.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Requests are sent directly from your browser (CORS permitting). Use a CORS proxy for cross-origin APIs."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Method</label>
          <select className="uk-select" value={method} onChange={(e) => setMethod(e.target.value)}>
            {METHODS.map((m) => <option key={m} value={m}>{m}</option>)}
          </select>
        </div>
        <div className="uk-field" style={{ flex: 3 }}>
          <label>URL</label>
          <input className="uk-input" value={url} onChange={(e) => setUrl(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && send()} />
        </div>
      </div>
      <div className="uk-field">
        <label>Headers (one per line, Format: Key: Value)</label>
        <textarea className="uk-textarea" style={{ minHeight: 50 }} value={headers} onChange={(e) => setHeaders(e.target.value)} />
      </div>
      {method !== 'GET' && method !== 'HEAD' && (
        <div className="uk-field">
          <label>Request body</label>
          <textarea className="uk-textarea" style={{ minHeight: 60 }} value={body} onChange={(e) => setBody(e.target.value)} />
        </div>
      )}
      <button className="uk-btn" onClick={send} disabled={status === 'loading'}>
        {status === 'loading' ? '⟳ Sending…' : '⚡ Send'}
      </button>

      <div className="uk-out-box">
        {status === 'loading' && <div className="uk-dim">Sending request…</div>}
        {status === 'error' && <div className="uk-red">✖ {error}</div>}
        {result && (
          <>
            <div className="uk-line" style={{ marginBottom: 6 }}>
              <span className={result.status < 400 ? 'uk-line' : 'uk-red'} style={{ fontWeight: 600 }}>
                {result.status} {result.statusText}
              </span>
              <span className="uk-dim"> &middot; {result.ms}ms &middot; {result.contentType}</span>
            </div>
            <div style={{ position: 'relative' }}>
              <CopyButton text={result.body} />
              <pre className="uk-line uk-cyan" style={{ margin: 0, fontSize: 12, paddingRight: 60, maxHeight: 240, overflowY: 'auto' }}>
                {result.body}
              </pre>
            </div>
            <details>
              <summary className="uk-dim" style={{ fontSize: 11, cursor: 'pointer', marginTop: 6 }}>
                Response headers
              </summary>
              <pre className="uk-dim" style={{ fontSize: 10.5, margin: '4px 0 0' }}>
                {JSON.stringify(result.headers, null, 2)}
              </pre>
            </details>
          </>
        )}
        {status === 'idle' && <div className="uk-dim">Enter a URL and press Send.</div>}
      </div>
    </TerminalShell>
  );
}

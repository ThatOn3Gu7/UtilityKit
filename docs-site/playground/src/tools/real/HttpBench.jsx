import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';

const DEFAULT_URL = 'https://jsonplaceholder.typicode.com/todos/1';

async function benchUrl(url, count, concurrency) {
  const times = [];
  let success = 0;
  let fail = 0;

  const runOne = async () => {
    const start = performance.now();
    try {
      const res = await fetch(url, { method: 'GET' });
      const elapsed = performance.now() - start;
      if (res.ok) { success++; times.push(elapsed); }
      else fail++;
    } catch {
      fail++;
    }
  };

  const batches = [];
  for (let i = 0; i < count; i += concurrency) {
    const batch = [];
    for (let j = i; j < Math.min(i + concurrency, count); j++) {
      batch.push(runOne());
    }
    batches.push(Promise.all(batch));
  }
  for (const batch of batches) await batch;

  if (times.length === 0) return { success: 0, fail, rps: 0, p50: 0, p75: 0, p95: 0, p99: 0, avg: 0 };
  times.sort((a, b) => a - b);
  const total = times.reduce((a, b) => a + b, 0);
  const rps = success / (total / 1000);
  return {
    success,
    fail,
    rps: Math.round(rps),
    p50: Math.round(times[Math.floor(times.length * 0.5)]),
    p75: Math.round(times[Math.floor(times.length * 0.75)]),
    p95: Math.round(times[Math.floor(times.length * 0.95)]),
    p99: Math.round(times[Math.floor(times.length * 0.99)]),
    avg: Math.round(total / times.length),
  };
}

export default function HttpBench() {
  const [url, setUrl] = useState(DEFAULT_URL);
  const [count, setCount] = useState(10);
  const [conc, setConc] = useState(3);
  const [status, setStatus] = useState('idle');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [progress, setProgress] = useState(0);

  const run = useCallback(async () => {
    if (!url.trim()) return;
    setStatus('loading');
    setError(null);
    setResult(null);
    setProgress(0);
    try {
      const res = await benchUrl(url.trim(), count, conc);
      setResult(res);
      setStatus('done');
      setProgress(100);
    } catch (e) {
      setError(e.message);
      setStatus('error');
    }
  }, [url, count, conc]);

  const ROWS = result ? [
    ['Completed', result.success],
    ['Failed', result.fail],
    ['Avg', `${result.avg} ms`],
    ['p50', `${result.p50} ms`],
    ['p75', `${result.p75} ms`],
    ['p95', `${result.p95} ms`],
    ['p99', `${result.p99} ms`],
    ['RPS', `${result.rps} req/s`],
  ] : [];

  return (
    <TerminalShell
      title="bench — HTTP Bench"
      subtitle="_http_bench.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Requests are sent from your browser — CORS, network latency, and browser throttling affect results."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 3 }}>
          <label>URL</label>
          <input className="uk-input" value={url} onChange={(e) => setUrl(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && run()} />
        </div>
        <div className="uk-field">
          <label>Requests</label>
          <input className="uk-input" type="number" min={1} max={100} value={count} onChange={(e) => setCount(Number(e.target.value) || 1)} />
        </div>
        <div className="uk-field">
          <label>Concurrency</label>
          <input className="uk-input" type="number" min={1} max={20} value={conc} onChange={(e) => setConc(Number(e.target.value) || 1)} />
        </div>
      </div>
      <button className="uk-btn" onClick={run} disabled={status === 'loading'}>
        {status === 'loading' ? `⟳ Running ${count} requests…` : '⚡ Run benchmark'}
      </button>

      <div className="uk-out-box">
        {status === 'loading' && <div className="uk-dim">Sending {count} requests to {url}…</div>}
        {status === 'error' && <div className="uk-red">✖ {error}</div>}
        {result && (
          <>
            {ROWS.map(([k, v]) => (
              <div key={k} className="uk-line" style={{ display: 'flex', gap: 12, padding: '2px 0' }}>
                <span className="uk-dim" style={{ minWidth: 100 }}>{k}</span>
                <span className="uk-cyan">{v}</span>
              </div>
            ))}
            <div className="uk-bar-track" style={{ marginTop: 10 }}>
              <div className="uk-bar-fill" style={{ width: '100%' }} />
            </div>
          </>
        )}
        {status === 'idle' && <div className="uk-dim">Set URL, request count, concurrency, and press Run.</div>}
      </div>
    </TerminalShell>
  );
}

import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';

const RESOLVERS = {
  cloudflare: { label: 'Cloudflare', url: 'https://cloudflare-dns.com/dns-query' },
  google: { label: 'Google', url: 'https://dns.google/resolve' },
  quad9: { label: 'Quad9', url: 'https://dns.quad9.net/dns-query' },
};

async function doQuery(domain, type, resolver) {
  const url = `${resolver.url}?name=${encodeURIComponent(domain)}&type=${type}`;
  const res = await fetch(url, { headers: { Accept: 'application/dns-json' } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function recordColor(rtype) {
  if (rtype === 'A' || rtype === 'AAAA') return '#3fb950';
  if (rtype === 'MX' || rtype === 'CNAME' || rtype === 'NS') return '#39c5cf';
  if (rtype === 'TXT') return '#d29922';
  return '#e6edf3';
}

const RECORD_TYPES = ['A', 'AAAA', 'MX', 'CNAME', 'NS', 'TXT', 'SOA'];

export default function DnsProbe() {
  const [domain, setDomain] = useState('example.com');
  const [rtype, setRtype] = useState('A');
  const [resolver, setResolver] = useState('cloudflare');
  const [status, setStatus] = useState('idle');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const query = useCallback(async () => {
    if (!domain.trim()) return;
    setStatus('loading');
    setError(null);
    setResult(null);
    try {
      const data = await doQuery(domain.trim(), rtype, RESOLVERS[resolver]);
      if (data.Status === 3) throw new Error('NXDOMAIN — domain does not exist');
      if (data.Status !== 0) throw new Error(`DNS status: ${data.Status}`);
      setResult(data);
      setStatus('done');
    } catch (e) {
      setError(e.message);
      setStatus('error');
    }
  }, [domain, rtype, resolver]);

  return (
    <TerminalShell
      title="dns — DNS Probe"
      subtitle="_dns_probe.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Queries are made via DNS-over-HTTPS to the selected resolver — your ISP won't see these lookups."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 2 }}>
          <label>Domain</label>
          <input className="uk-input" value={domain} onChange={(e) => setDomain(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && query()} />
        </div>
        <div className="uk-field">
          <label>Record type</label>
          <select className="uk-select" value={rtype} onChange={(e) => setRtype(e.target.value)}>
            {RECORD_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </div>
        <div className="uk-field">
          <label>Resolver</label>
          <select className="uk-select" value={resolver} onChange={(e) => setResolver(e.target.value)}>
            {Object.entries(RESOLVERS).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
          </select>
        </div>
      </div>
      <button className="uk-btn" onClick={query} disabled={status === 'loading'}>
        {status === 'loading' ? '⟳ Querying…' : '🔍 Query'}
      </button>

      <div className="uk-out-box">
        {status === 'loading' && <div className="uk-dim">Querying {resolver} for {domain} {rtype}…</div>}
        {status === 'error' && <div className="uk-red">✖ {error}</div>}
        {result && (
          <>
            {result.Answer && result.Answer.length > 0 ? (
              result.Answer.map((r, i) => (
                <div key={i} className="uk-line" style={{ display: 'flex', gap: 12, padding: '1px 0' }}>
                  <span className="uk-dim" style={{ minWidth: 40 }}>{r.type}</span>
                  <span className="uk-cyan" style={{ color: recordColor(r.type) }}>{r.data}</span>
                  <span className="uk-dim" style={{ fontSize: 10, marginLeft: 'auto' }}>TTL {r.TTL}</span>
                </div>
              ))
            ) : (
              <div className="uk-dim">No {rtype} records found for {domain}.</div>
            )}
            <div className="uk-dim" style={{ marginTop: 8, fontSize: 11 }}>
              Resolver: {RESOLVERS[resolver].label} · queried {domain} for {rtype}
            </div>
          </>
        )}
        {status === 'idle' && <div className="uk-dim">Enter a domain and record type to query.</div>}
      </div>
    </TerminalShell>
  );
}

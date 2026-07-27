import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';

async function lookupIP(ip) {
  const url = ip
    ? `https://ipapi.co/${encodeURIComponent(ip)}/json/`
    : 'https://ipapi.co/json/';
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

export default function IpInfo() {
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState('idle');
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  const lookup = useCallback(async () => {
    setStatus('loading');
    setError(null);
    setData(null);
    try {
      const result = await lookupIP(query.trim() || undefined);
      if (result.error) throw new Error(result.reason || result.error);
      setData(result);
      setStatus('done');
    } catch (e) {
      setError(e.message);
      setStatus('error');
    }
  }, [query]);

  const ROWS = data ? [
    ['IP', data.ip],
    ['Version', data.version],
    ['Network', `${data.network || '—'}`],
    ['City', data.city],
    ['Region', data.region],
    ['Country', `${data.country_name} (${data.country_code})`],
    ['Postal', data.postal || '—'],
    ['Lat / Lon', `${data.latitude}, ${data.longitude}`],
    ['Timezone', data.timezone],
    ['Org', data.org || '—'],
    ['ASN', data.asn || '—'],
  ] : [];

  return (
    <TerminalShell
      title="ipinfo — IP Info"
      subtitle="_ip_info.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Powered by ipapi.co. Your public IP is fetched to determine location — leave blank to look up your own IP."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 2 }}>
          <label>IP address (leave blank for your own)</label>
          <input className="uk-input" value={query} placeholder="8.8.8.8" onChange={(e) => setQuery(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && lookup()} />
        </div>
      </div>
      <button className="uk-btn" onClick={lookup} disabled={status === 'loading'}>
        {status === 'loading' ? '⟳ Looking up…' : '🔍 Look up'}
      </button>

      <div className="uk-out-box">
        {status === 'loading' && <div className="uk-dim">Looking up IP information…</div>}
        {status === 'error' && <div className="uk-red">✖ {error}</div>}
        {data && ROWS.map(([k, v]) => (
          <div key={k} className="uk-line" style={{ display: 'flex', gap: 12, padding: '1px 0' }}>
            <span className="uk-dim" style={{ minWidth: 80 }}>{k}</span>
            <span className="uk-cyan">{v}</span>
          </div>
        ))}
        {status === 'idle' && <div className="uk-dim">Enter an IP or leave blank to see your own IP info.</div>}
      </div>
    </TerminalShell>
  );
}

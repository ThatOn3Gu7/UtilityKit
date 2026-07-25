import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

function fmtAll(date) {
  if (isNaN(date.getTime())) return null;
  return {
    epoch: Math.floor(date.getTime() / 1000),
    iso: date.toISOString(),
    rfc3339: date.toISOString().replace('Z', '+00:00'),
    rfc2822: date.toUTCString(),
    human: date.toLocaleString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit', timeZoneName: 'short' }),
  };
}

export default function TimeConvert() {
  const [mode, setMode] = useState('now');
  const [epochInput, setEpochInput] = useState(() => String(Math.floor(Date.now() / 1000)));
  const [parseInput, setParseInput] = useState('2024-01-15T10:30:00Z');
  const [tick, setTick] = useState(0);

  const nowDate = useMemo(() => new Date(), [tick]);

  const epochDate = useMemo(() => {
    const n = Number(epochInput);
    return Number.isFinite(n) ? new Date(n * 1000) : new Date(NaN);
  }, [epochInput]);

  const parsedDate = useMemo(() => new Date(parseInput), [parseInput]);

  const active = mode === 'now' ? nowDate : mode === 'epoch' ? epochDate : parsedDate;
  const formatted = fmtAll(active);

  const rows = formatted
    ? [
        ['Epoch', formatted.epoch],
        ['ISO 8601', formatted.iso],
        ['RFC 3339', formatted.rfc3339],
        ['RFC 2822', formatted.rfc2822],
        ['Human', formatted.human],
      ]
    : null;

  return (
    <TerminalShell
      title="time — Time Convert"
      subtitle="_time_convert.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Uses your browser's Date engine — matches system UTC handling."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Mode</label>
          <select className="uk-select" value={mode} onChange={(e) => { setMode(e.target.value); setTick((t) => t + 1); }}>
            <option value="now">now</option>
            <option value="epoch">epoch → formats</option>
            <option value="parse">parse timestamp</option>
          </select>
        </div>
        {mode === 'epoch' && (
          <div className="uk-field" style={{ flex: 2 }}>
            <label>Epoch (seconds)</label>
            <input className="uk-input" value={epochInput} onChange={(e) => setEpochInput(e.target.value)} />
          </div>
        )}
        {mode === 'parse' && (
          <div className="uk-field" style={{ flex: 2 }}>
            <label>Timestamp string</label>
            <input className="uk-input" value={parseInput} onChange={(e) => setParseInput(e.target.value)} />
          </div>
        )}
      </div>

      <div className="uk-out-box">
        {!rows ? (
          <div className="uk-red">Could not parse this timestamp.</div>
        ) : (
          <>
            <CopyButton text={rows.map(([k, v]) => `${k}: ${v}`).join('\n')} />
            <div style={{ paddingRight: 70 }}>
              {rows.map(([k, v]) => (
                <div key={k} className="uk-line" style={{ display: 'flex', gap: 12 }}>
                  <span className="uk-dim" style={{ minWidth: 90, display: 'inline-block' }}>
                    {k}
                  </span>
                  <span className="uk-cyan">{v}</span>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </TerminalShell>
  );
}

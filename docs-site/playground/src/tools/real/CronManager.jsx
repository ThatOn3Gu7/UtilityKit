import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';

function parseField(field, min, max) {
  if (field === '*') return 'every';
  if (field.includes('/')) {
    const [, step] = field.split('/');
    return `every ${step} (${min}-${max})`;
  }
  if (field.includes(',')) {
    return field;
  }
  if (field.includes('-')) {
    return field;
  }
  return field;
}

function describeCron(expr) {
  const parts = expr.trim().split(/\s+/);
  if (parts.length < 5) return { error: 'Cron expression must have at least 5 fields (min hour dom mon dow)' };
  const [min, hour, dom, mon, dow] = parts;
  const desc = [];
  const minDesc = parseField(min, 0, 59);
  const hourDesc = parseField(hour, 0, 23);
  const domDesc = parseField(dom, 1, 31);
  const monDesc = parseField(mon, 1, 12);
  const dowDesc = parseField(dow, 0, 7);

  if (min === '*' && hour === '*') desc.push('Every minute');
  else if (min === '*' && hour !== '*') desc.push(`Every minute of ${hourDesc}`);
  else if (min !== '*' && hour === '*') desc.push(`At minute ${minDesc} of every hour`);
  else desc.push(`At ${hourDesc}:${min.padStart(2, '0')}`);

  if (dom !== '*') desc.push(`on day ${domDesc}`);
  if (mon !== '*') desc.push(`in month ${monDesc}`);
  if (dow !== '*') desc.push(`and on ${dowDesc}`);

  return { description: desc.join(' '), fields: { min, hour, dom, mon, dow } };
}

function getNextRuns(expr, count = 5) {
  const parts = expr.trim().split(/\s+/);
  if (parts.length < 5) return [];
  const [minF, hourF, domF, monF, dowF] = parts;

  const parseRange = (f, min, max) => {
    if (f === '*') return Array.from({ length: max - min + 1 }, (_, i) => i + min);
    const values = new Set();
    f.split(',').forEach((part) => {
      if (part.includes('/')) {
        const [range, step] = part.split('/');
        const [rmin, rmax] = range === '*' ? [min, max] : range.split('-').map(Number);
        for (let i = rmin; i <= rmax; i += Number(step)) values.add(i);
      } else if (part.includes('-')) {
        const [a, b] = part.split('-').map(Number);
        for (let i = a; i <= b; i++) values.add(i);
      } else if (part === '*') {
        for (let i = min; i <= max; i++) values.add(i);
      } else {
        values.add(Number(part));
      }
    });
    return [...values].filter((v) => v >= min && v <= max);
  };

  const validMins = parseRange(minF, 0, 59);
  const validHours = parseRange(hourF, 0, 23);
  const validDays = parseRange(domF, 1, 31);
  const validMonths = parseRange(monF, 1, 12);
  const validDows = parseRange(dowF, 0, 6);

  const now = new Date();
  const runs = [];
  let cur = new Date(now);

  for (let attempt = 0; attempt < 100000 && runs.length < count; attempt++) {
    const y = cur.getFullYear();
    const m = cur.getMonth() + 1;

    if (!validMonths.includes(m)) {
      cur = new Date(y, m, 1);
      continue;
    }

    const d = cur.getDate();
    if (!validDays.includes(d)) {
      cur = new Date(y, m - 1, d + 1, 0, 0, 0);
      continue;
    }

    const dow = cur.getDay();
    if (!validDows.includes(dow)) {
      cur = new Date(cur.getTime() + 86400000);
      continue;
    }

    const h = cur.getHours();
    if (!validHours.includes(h)) {
      cur = new Date(y, m - 1, d, h + 1, 0, 0);
      continue;
    }

    const min = cur.getMinutes();
    if (!validMins.includes(min)) {
      cur = new Date(y, m - 1, d, h, min + 1, 0);
      continue;
    }

    if (cur > now) runs.push(new Date(cur));
    cur = new Date(cur.getTime() + 60000);
  }

  return runs;
}

export default function CronManager() {
  const [expr, setExpr] = useState('*/15 * * * *');
  const [count, setCount] = useState(5);

  const parsed = useMemo(() => describeCron(expr), [expr]);
  const runs = useMemo(() => {
    if (parsed.error) return [];
    return getNextRuns(expr, count);
  }, [expr, count, parsed.error]);

  return (
    <TerminalShell
      title="cron — Cron Manager"
      subtitle="_cron_manager.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Cron expression parser runs client-side — shows next scheduled fire times."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 2 }}>
          <label>Cron expression (min hour dom mon dow)</label>
          <input className="uk-input" value={expr} placeholder="*/15 * * * *" onChange={(e) => setExpr(e.target.value)} />
        </div>
        <div className="uk-field">
          <label>Next runs</label>
          <input className="uk-input" type="number" min={1} max={20} value={count} onChange={(e) => setCount(Number(e.target.value) || 1)} />
        </div>
      </div>

      <div className="uk-out-box">
        {parsed.error ? (
          <div className="uk-red">{parsed.error}</div>
        ) : (
          <>
            <div className="uk-line" style={{ marginBottom: 8 }}>
              <span className="uk-dim">Schedule: </span>
              <span className="uk-cyan">{parsed.description}</span>
            </div>
            <div className="uk-line uk-dim" style={{ fontSize: 11, marginBottom: 8 }}>
              {parsed.fields.min} {parsed.fields.hour} {parsed.fields.dom} {parsed.fields.mon} {parsed.fields.dow}
            </div>
            {runs.length > 0 && (
              <>
                <div className="uk-dim" style={{ fontSize: 11, marginBottom: 4 }}>Next {Math.min(count, runs.length)} run(s):</div>
                {runs.map((d, i) => (
                  <div key={i} className="uk-line uk-cyan" style={{ fontSize: 12 }}>
                    {d.toLocaleString('en-US', { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                  </div>
                ))}
              </>
            )}
          </>
        )}
      </div>
    </TerminalShell>
  );
}

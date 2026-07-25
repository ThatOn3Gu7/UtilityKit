import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';

export default function RegexLab() {
  const [pattern, setPattern] = useState('(\\w+)@(\\w+\\.\\w+)');
  const [flags, setFlags] = useState('g');
  const [text, setText] = useState('Contact: ada@example.com or grace@utilitykit.dev');

  const { matches, error } = useMemo(() => {
    try {
      const re = new RegExp(pattern, flags);
      const out = [];
      if (flags.includes('g')) {
        let m;
        while ((m = re.exec(text)) !== null) {
          out.push(m);
          if (m[0] === '') re.lastIndex++;
        }
      } else {
        const m = re.exec(text);
        if (m) out.push(m);
      }
      return { matches: out, error: null };
    } catch (e) {
      return { matches: [], error: e.message };
    }
  }, [pattern, flags, text]);

  const highlighted = useMemo(() => {
    if (error || matches.length === 0) return null;
    const parts = [];
    let last = 0;
    matches.forEach((m, i) => {
      if (m.index > last) parts.push({ text: text.slice(last, m.index), hit: false });
      parts.push({ text: m[0], hit: true, i });
      last = m.index + m[0].length;
    });
    if (last < text.length) parts.push({ text: text.slice(last), hit: false });
    return parts;
  }, [matches, text, error]);

  return (
    <TerminalShell
      title="regex — Regex Lab"
      subtitle="_regex_lab.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Uses the browser's native RegExp engine (ECMA syntax, close to PCRE for common patterns)."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 3 }}>
          <label>Pattern</label>
          <input className="uk-input" value={pattern} onChange={(e) => setPattern(e.target.value)} />
        </div>
        <div className="uk-field">
          <label>Flags</label>
          <input className="uk-input" value={flags} onChange={(e) => setFlags(e.target.value.replace(/[^gimsuy]/g, ''))} />
        </div>
      </div>

      <div className="uk-field">
        <label>Sample text</label>
        <textarea className="uk-textarea" value={text} onChange={(e) => setText(e.target.value)} />
      </div>

      <div className="uk-out-box">
        {error ? (
          <div className="uk-red">Regex error: {error}</div>
        ) : (
          <>
            <div className="uk-line" style={{ marginBottom: 10 }}>
              {highlighted?.map((p, i) =>
                p.hit ? (
                  <span key={i} style={{ background: 'rgba(63,185,80,0.25)', color: '#3fb950', borderRadius: 3, padding: '1px 2px' }}>
                    {p.text}
                  </span>
                ) : (
                  <span key={i}>{p.text}</span>
                )
              )}
            </div>
            <div className="uk-dim" style={{ fontSize: 11, marginBottom: 6 }}>
              {matches.length} match{matches.length !== 1 ? 'es' : ''}
            </div>
            {matches.map((m, i) => (
              <div key={i} className="uk-line uk-cyan" style={{ fontSize: 12 }}>
                [{i + 1}] span {m.index}-{m.index + m[0].length}: "{m[0]}"
                {m.length > 1 && (
                  <span className="uk-dim">
                    {' '}
                    captures={JSON.stringify(m.slice(1))}
                  </span>
                )}
              </div>
            ))}
          </>
        )}
      </div>
    </TerminalShell>
  );
}

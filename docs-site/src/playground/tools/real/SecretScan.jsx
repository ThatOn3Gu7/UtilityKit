import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';

const RULES = [
  ['aws-access-key', /AKIA[0-9A-Z]{16}/g],
  ['github-token', /gh[pousr]_[A-Za-z0-9]{36,255}/g],
  ['slack-token', /xox[abpsr]-[A-Za-z0-9-]{10,}/g],
  ['google-api-key', /AIza[0-9A-Za-z_-]{35}/g],
  ['stripe-key', /(sk|pk|rk)_(live|test)_[A-Za-z0-9]{20,}/g],
  ['jwt', /eyJ[A-Za-z0-9_-]{5,}\.eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}/g],
  ['private-key-block', /-----BEGIN (RSA|EC|DSA|OPENSSH|PGP|ENCRYPTED)? ?PRIVATE KEY( BLOCK)?-----/g],
];

function redact(s) {
  return s.length > 12 ? `${s.slice(0, 4)}${'*'.repeat(s.length - 8)}${s.slice(-4)}` : s;
}

function scan(text) {
  const findings = [];
  const lines = text.split('\n');
  lines.forEach((line, i) => {
    for (const [name, re] of RULES) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(line)) !== null) {
        findings.push({ rule: name, line: i + 1, match: m[0] });
        if (m[0] === '') re.lastIndex++;
      }
    }
  });
  return findings;
}

export default function SecretScan() {
  const [text, setText] = useState('aws_key = "AKIAIOSFODNN7EXAMPLE"\napi_token = "safe_placeholder_value"\n');
  const findings = useMemo(() => scan(text), [text]);

  return (
    <TerminalShell
      title="secret — Secret Scan"
      subtitle="_secret_scan.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Regex-only pass, run locally. Entropy detection needs the CLI's Python backend."
    >
      <div className="uk-field">
        <label>Text to scan (paste a config/env snippet)</label>
        <textarea className="uk-textarea" style={{ minHeight: 120 }} value={text} onChange={(e) => setText(e.target.value)} />
      </div>

      <div className="uk-out-box">
        {findings.length === 0 ? (
          <div style={{ color: '#3fb950' }}>✔ no findings</div>
        ) : (
          <>
            <div className="uk-red" style={{ marginBottom: 8 }}>
              ✖ {findings.length} finding(s)
            </div>
            {findings.map((f, i) => (
              <div key={i} className="uk-line" style={{ marginBottom: 6 }}>
                <span className="uk-dim">line {f.line}:</span> <span className="uk-yellow">{f.rule}</span>{' '}
                <span className="uk-cyan">{redact(f.match)}</span>
              </div>
            ))}
          </>
        )}
      </div>
    </TerminalShell>
  );
}

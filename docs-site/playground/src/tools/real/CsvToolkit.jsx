import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';

function parseCsv(text) {
  return text
    .trim()
    .split('\n')
    .map((line) => line.split(',').map((c) => c.trim()));
}

export default function CsvToolkit() {
  const [raw, setRaw] = useState('name,role,years\nada,developer,5\nlinus,maintainer,12\ngrace,architect,20');
  const [headCount, setHeadCount] = useState(5);

  const rows = useMemo(() => parseCsv(raw), [raw]);
  const header = rows[0] || [];
  const data = rows.slice(1);
  const preview = data.slice(0, headCount);

  return (
    <TerminalShell
      title="csv — CSV Toolkit"
      subtitle="_csv_toolkit.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Parsed client-side. For quoted/embedded-comma CSVs, use the CLI's Python backend."
    >
      <div className="uk-field">
        <label>CSV input</label>
        <textarea className="uk-textarea" style={{ minHeight: 110 }} value={raw} onChange={(e) => setRaw(e.target.value)} />
      </div>

      <div className="uk-field" style={{ maxWidth: 140 }}>
        <label>Preview rows</label>
        <input className="uk-input" type="number" min={1} max={data.length || 1} value={headCount} onChange={(e) => setHeadCount(Number(e.target.value) || 1)} />
      </div>

      <div className="uk-out-box" style={{ overflowX: 'auto' }}>
        <table style={{ borderCollapse: 'collapse', width: '100%', fontSize: 12.5 }}>
          <thead>
            <tr>
              {header.map((h, i) => (
                <th key={i} style={{ textAlign: 'left', padding: '4px 10px', color: '#3fb950', borderBottom: '1px solid #21262d' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {preview.map((row, ri) => (
              <tr key={ri}>
                {row.map((cell, ci) => (
                  <td key={ci} style={{ padding: '4px 10px', color: '#e6edf3', borderBottom: '1px solid #161b22' }}>
                    {cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
        <div className="uk-dim" style={{ marginTop: 8, fontSize: 11 }}>
          Total data rows: {data.length}
        </div>
      </div>
    </TerminalShell>
  );
}

import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9 _-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function extractToc(md) {
  const lines = md.split('\n');
  const items = [];
  let inCode = false;
  for (const line of lines) {
    if (line.trim().startsWith('```')) {
      inCode = !inCode;
      continue;
    }
    if (inCode) continue;
    const m = line.match(/^(#{1,6})\s+(.+)/);
    if (m) {
      items.push({ level: m[1].length, title: m[2].trim(), anchor: slugify(m[2].trim()) });
    }
  }
  return items;
}

export default function MarkdownToc() {
  const [md, setMd] = useState('# UtilityKit\n\n## Features\n\nText here.\n\n## Usage\n\n### Quick Start\n\nMore text.\n\n## Contributing\n');

  const items = useMemo(() => extractToc(md), [md]);
  const tocText = items.map((i) => `${'  '.repeat(i.level - 1)}- [${i.title}](#${i.anchor})`).join('\n');

  return (
    <TerminalShell
      title="toc — Markdown TOC"
      subtitle="_markdown_toc.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Same anchor-slug rules as GitHub Markdown, computed client-side."
    >
      <div className="uk-field">
        <label>Markdown input</label>
        <textarea className="uk-textarea" style={{ minHeight: 150, fontSize: 12.5 }} value={md} onChange={(e) => setMd(e.target.value)} />
      </div>

      <div className="uk-out-box">
        {items.length === 0 ? (
          <div className="uk-dim">No headings found; TOC would be empty.</div>
        ) : (
          <>
            <CopyButton text={tocText} />
            <div className="uk-dim" style={{ fontSize: 11, marginBottom: 6 }}>
              Generated TOC ({items.length} entries)
            </div>
            <pre className="uk-line uk-cyan" style={{ margin: 0, fontSize: 12.5, paddingRight: 60 }}>{tocText}</pre>
          </>
        )}
      </div>
    </TerminalShell>
  );
}

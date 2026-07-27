import { useState, useEffect } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

const STORAGE_KEY = 'uk-playground-cheats';

function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw);
  } catch { /* ignore */ }
  return [
    { id: 1, title: 'docker-logs', snippet: 'docker logs -f app', tag: 'docker' },
    { id: 2, title: 'docker-clean', snippet: 'docker system prune -a --volumes', tag: 'docker' },
    { id: 3, title: 'git-undo', snippet: 'git reset --soft HEAD~1', tag: 'git' },
  ];
}

export default function CheatSheet() {
  const [items, setItems] = useState(load);
  const [title, setTitle] = useState('');
  const [snippet, setSnippet] = useState('');
  const [tag, setTag] = useState('');
  const [search, setSearch] = useState('');

  useEffect(() => {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(items)); } catch { /* ignore */ }
  }, [items]);

  const add = () => {
    if (!title.trim() || !snippet.trim()) return;
    setItems((t) => [...t, { id: Date.now(), title: title.trim(), snippet: snippet.trim(), tag: tag.trim() }]);
    setTitle('');
    setSnippet('');
    setTag('');
  };

  const remove = (id) => setItems((t) => t.filter((item) => item.id !== id));

  const filtered = search.trim()
    ? items.filter((i) =>
        i.title.toLowerCase().includes(search.toLowerCase()) ||
        i.snippet.toLowerCase().includes(search.toLowerCase()) ||
        i.tag.toLowerCase().includes(search.toLowerCase())
      )
    : items;

  return (
    <TerminalShell
      title="cheat — Cheat Sheet"
      subtitle="_cheat_sheet.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Stored in your browser's localStorage — snippets persist across sessions."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 1 }}>
          <label>Title</label>
          <input className="uk-input" value={title} placeholder="docker-logs" onChange={(e) => setTitle(e.target.value)} />
        </div>
        <div className="uk-field">
          <label>Tag</label>
          <input className="uk-input" value={tag} placeholder="docker" onChange={(e) => setTag(e.target.value)} />
        </div>
      </div>
      <div className="uk-field">
        <label>Snippet</label>
        <textarea className="uk-textarea" value={snippet} placeholder="docker logs -f app" onChange={(e) => setSnippet(e.target.value)} />
      </div>
      <button className="uk-btn" onClick={add}>+ Add snippet</button>

      <div className="uk-field" style={{ marginTop: 12 }}>
        <label>Search</label>
        <input className="uk-input" value={search} placeholder="Search by title, snippet, or tag…" onChange={(e) => setSearch(e.target.value)} />
      </div>

      <div className="uk-out-box">
        {filtered.length === 0 && <div className="uk-dim">No snippets found.</div>}
        {filtered.map((item) => (
          <div key={item.id} style={{ marginBottom: 8, position: 'relative', paddingRight: 50 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span className="uk-line" style={{ fontWeight: 600 }}>{item.title}</span>
              <button className="uk-btn uk-btn-ghost uk-btn-sm" onClick={() => remove(item.id)}>✕</button>
            </div>
            <pre className="uk-line uk-cyan" style={{ fontSize: 12, margin: '2px 0' }}>{item.snippet}</pre>
            {item.tag && <span className="uk-yellow" style={{ fontSize: 10 }}>#{item.tag}</span>}
            <CopyButton text={item.snippet} />
          </div>
        ))}
      </div>
    </TerminalShell>
  );
}

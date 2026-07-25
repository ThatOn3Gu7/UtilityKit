import { useState, useEffect } from 'react';
import TerminalShell from '../../components/TerminalShell';

const STORAGE_KEY = 'uk-playground-todos';

function load() {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    return raw
      ? JSON.parse(raw)
      : [
          { id: 1, status: 'open', text: 'Review UtilityKit PR', tag: 'utilitykit' },
          { id: 2, status: 'done', text: 'Set up docs playground', tag: 'docs' },
        ];
  } catch {
    return [];
  }
}

export default function TodoManager() {
  const [todos, setTodos] = useState(load);
  const [text, setText] = useState('');
  const [tag, setTag] = useState('');

  useEffect(() => {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(todos));
    } catch {
      /* ignore quota errors */
    }
  }, [todos]);

  const add = () => {
    if (!text.trim()) return;
    setTodos((t) => [...t, { id: Date.now(), status: 'open', text: text.trim(), tag: tag.trim() }]);
    setText('');
    setTag('');
  };
  const toggle = (id) => setTodos((t) => t.map((item) => (item.id === id ? { ...item, status: item.status === 'open' ? 'done' : 'open' } : item)));
  const remove = (id) => setTodos((t) => t.filter((item) => item.id !== id));

  return (
    <TerminalShell
      title="todo — Todo Manager"
      subtitle="_todo_manager.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Stored in your browser's session storage for this tab only — nothing is uploaded."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 2 }}>
          <label>Task</label>
          <input className="uk-input" value={text} placeholder="Fix the docs deploy pipeline" onChange={(e) => setText(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && add()} />
        </div>
        <div className="uk-field">
          <label>Tag</label>
          <input className="uk-input" value={tag} placeholder="infra" onChange={(e) => setTag(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && add()} />
        </div>
      </div>
      <button className="uk-btn" onClick={add}>
        + Add
      </button>

      <div className="uk-out-box">
        {todos.length === 0 && <div className="uk-dim">No tasks yet.</div>}
        {todos.map((t, i) => (
          <div key={t.id} className="uk-line" style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 0' }}>
            <span className="uk-dim" style={{ width: 18 }}>{i + 1}</span>
            <input type="checkbox" checked={t.status === 'done'} onChange={() => toggle(t.id)} style={{ accentColor: '#3fb950' }} />
            <span style={{ flex: 1, textDecoration: t.status === 'done' ? 'line-through' : 'none', color: t.status === 'done' ? '#7d8590' : '#e6edf3' }}>
              {t.text}
            </span>
            {t.tag && <span className="uk-yellow" style={{ fontSize: 11 }}>#{t.tag}</span>}
            <button className="uk-btn uk-btn-ghost uk-btn-sm" onClick={() => remove(t.id)}>
              ✕
            </button>
          </div>
        ))}
      </div>
    </TerminalShell>
  );
}

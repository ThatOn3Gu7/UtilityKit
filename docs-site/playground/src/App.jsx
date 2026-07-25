import { useState, useMemo, useEffect } from 'react';
import './App.css';
import { TOOLS, CATEGORIES } from './data/registry';
import ToolPlayer from './tools/ToolPlayer';
import Header from './components/Header';

export default function App() {
  const [query, setQuery] = useState('');
  const [cat, setCat] = useState('all');
  const [active, setActive] = useState(null);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return TOOLS.filter((t) => {
      const matchCat = cat === 'all' || t.cat === cat;
      const matchQ = !q || t.name.toLowerCase().includes(q) || t.cmd.toLowerCase().includes(q) || t.desc.toLowerCase().includes(q);
      return matchCat && matchQ;
    });
  }, [query, cat]);

  const realCount = TOOLS.filter((t) => t.kind === 'real').length;

  useEffect(() => {
    const onKey = (e) => e.key === 'Escape' && setActive(null);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  return (
    <>
      <Header />
      <div className="pg-shell">
        <div className="pg-hero">
        <div className="pg-eyebrow">Interactive Playground</div>
        <h1 className="pg-title">
          Try every <span className="hl">UtilityKit</span> tool right here.
        </h1>
        <p className="pg-sub">
          {realCount} tools run for real, in your browser — generate passwords, hash files, test regexes, build QR codes.
          The rest play back a scripted terminal preview so you can see the shape of every tool before installing it.
        </p>
      </div>

      <div className="pg-controls">
        <div className="pg-search">
          <input
            type="search"
            placeholder="Search tools, commands, descriptions…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            spellCheck={false}
          />
        </div>
        <div className="pg-filters">
          <button className={`pg-filter-btn ${cat === 'all' ? 'active' : ''}`} onClick={() => setCat('all')}>
            All ({TOOLS.length})
          </button>
          {Object.entries(CATEGORIES).map(([key, meta]) => (
            <button
              key={key}
              className={`pg-filter-btn ${cat === key ? 'active' : ''}`}
              style={{ '--fc': meta.color }}
              onClick={() => setCat(key)}
            >
              {meta.label}
            </button>
          ))}
        </div>
      </div>

      <div className="pg-count">
        {filtered.length === TOOLS.length ? `Showing all ${TOOLS.length} tools` : `Showing ${filtered.length} of ${TOOLS.length} tools`}
      </div>

      {filtered.length === 0 ? (
        <div className="pg-empty">No tools match your search.</div>
      ) : (
        <div className="pg-grid">
          {filtered.map((tool) => {
            const catMeta = CATEGORIES[tool.cat];
            return (
              <button key={tool.id} className="pg-card" style={{ '--cc': catMeta.color }} onClick={() => setActive(tool)}>
                <div className="pg-card-top">
                  <span className="pg-card-name">{tool.name}</span>
                  <span className="pg-card-cmd">{tool.cmd}</span>
                </div>
                <div className="pg-card-desc">{tool.desc}</div>
                <div className="pg-card-foot">
                  <span className={tool.kind === 'real' ? 'pg-badge-live' : 'pg-badge-sim'}>
                    {tool.kind === 'real' ? 'Try it live' : 'Preview'}
                  </span>
                  <span className="pg-card-arrow">→</span>
                </div>
              </button>
            );
          })}
        </div>
      )}

      {active && (
        <div className="pg-modal-overlay" onClick={() => setActive(null)}>
          <div className="pg-modal" onClick={(e) => e.stopPropagation()}>
            <div className="pg-modal-head">
              <div>
                <p className="pg-modal-desc" style={{ marginBottom: 2, color: '#f3f4f6', fontWeight: 600, fontSize: 16 }}>
                  {active.name}
                </p>
                <p className="pg-modal-desc">{active.desc}</p>
              </div>
              <button className="pg-modal-close" onClick={() => setActive(null)} aria-label="Close">
                ✕
              </button>
            </div>
            <ToolPlayer tool={active} />
          </div>
        </div>
      )}
    </div>
    </>
  );
}

import { useState, useMemo, useEffect } from 'react';
import { useTheme } from '@/components/ThemeProvider';
import { TOOLS, CATEGORIES } from '@/playground/data/registry';
import ToolPlayer from '@/playground/tools/ToolPlayer';
import '@/playground/playground.css';
import '@/playground/components/terminal-shell.css';

type ToolEntry = (typeof TOOLS)[number];

export default function PlaygroundPage() {
  const { resolved } = useTheme();
  const [query, setQuery] = useState('');
  const [cat, setCat] = useState('all');
  const [active, setActive] = useState<ToolEntry | null>(null);

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
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setActive(null);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  useEffect(() => {
    if (active) {
      const prev = document.body.style.overflow;
      document.body.style.overflow = 'hidden';
      return () => { document.body.style.overflow = prev; };
    }
  }, [active]);

  return (
    <div className="pg-shell" data-theme={resolved}>
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
          {(Object.entries(CATEGORIES) as [string, { label: string; color: string }][]).map(([key, meta]) => (
            <button
              key={key}
              className={`pg-filter-btn ${cat === key ? 'active' : ''}`}
              style={{ '--fc': meta.color } as React.CSSProperties}
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

      <div className="pg-legend">
        <span className="pg-legend-item">🟢 Try It Live = runs in your browser.</span>
        <span className="pg-legend-item">🟡 Preview = recorded terminal walkthrough.</span>
      </div>

      {filtered.length === 0 ? (
        <div className="pg-empty">No tools match your search.</div>
      ) : (
        <div className="pg-grid">
          {filtered.map((tool) => {
            const catMeta = CATEGORIES[tool.cat as keyof typeof CATEGORIES];
            return (
              <button key={tool.id} className={`pg-card ${tool.kind === 'real' ? 'pg-card-live' : 'pg-card-sim'}`} style={{ '--cc': catMeta.color } as React.CSSProperties} onClick={() => setActive(tool)}>
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
  );
}

import { useEffect, useRef, useState } from 'react';
import TerminalShell from './TerminalShell';

const D = "uk-dim";
const C = "uk-cyan";
const Y = "uk-yellow";
const R = "uk-red";

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

export default function SimPlayer({ title, subtitle, scenarios, footer }) {
  const scenarioIds = Object.keys(scenarios);
  const [activeId, setActiveId] = useState(scenarioIds[0]);
  const script = scenarios[activeId]?.steps ?? [];
  const [rendered, setRendered] = useState([]);
  const [running, setRunning] = useState(false);
  const [progress, setProgress] = useState(null);
  const bodyRef = useRef(null);
  const tokenRef = useRef(0);

  const scrollDown = () => {
    requestAnimationFrame(() => {
      if (bodyRef.current) bodyRef.current.scrollTop = bodyRef.current.scrollHeight;
    });
  };

  const play = async (steps) => {
    const myToken = ++tokenRef.current;
    setRendered([]);
    setProgress(null);
    setRunning(true);

    const stillCurrent = () => tokenRef.current === myToken;

    for (const step of steps) {
      if (!stillCurrent()) return;

      if (step.type === 'type') {
        let acc = '';
        setRendered((r) => [...r, { id: Math.random(), cls: step.cls || 'uk-prompt', text: '', typing: true }]);
        for (let i = 0; i < step.text.length; i++) {
          if (!stillCurrent()) return;
          acc += step.text[i];
          setRendered((r) => {
            const copy = [...r];
            copy[copy.length - 1] = { ...copy[copy.length - 1], text: acc };
            return copy;
          });
          scrollDown();
          await sleep(14 + Math.random() * 18);
        }
        setRendered((r) => {
          const copy = [...r];
          copy[copy.length - 1] = { ...copy[copy.length - 1], typing: false };
          return copy;
        });
        await sleep(150);
      } else if (step.type === 'line') {
        await sleep(step.delay ?? 220);
        if (!stillCurrent()) return;
        setRendered((r) => [...r, { id: Math.random(), cls: step.cls || '', text: step.text }]);
        scrollDown();
      } else if (step.type === 'lines') {
        for (const item of step.items) {
          if (!stillCurrent()) return;
          await sleep(step.stagger ?? 90);
          setRendered((r) => [...r, { id: Math.random(), cls: item.cls || '', text: item.text }]);
          scrollDown();
        }
      } else if (step.type === 'progress') {
        const total = step.ms ?? 1200;
        const start = performance.now();
        setProgress({ label: step.label, pct: 0 });
        await new Promise((resolve) => {
          const tick = (now) => {
            if (!stillCurrent()) return resolve();
            const pct = Math.min(100, ((now - start) / total) * 100);
            setProgress({ label: step.label, pct });
            if (pct >= 100) resolve();
            else requestAnimationFrame(tick);
          };
          requestAnimationFrame(tick);
        });
        if (!stillCurrent()) return;
        setProgress(null);
      } else if (step.type === 'pause') {
        await sleep(step.ms ?? 300);
      }
    }
    if (stillCurrent()) setRunning(false);
  };

  useEffect(() => {
    play(script);
    return () => { tokenRef.current++; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeId, script]);

  const switchScenario = (id) => {
    if (running) return;
    setActiveId(id);
  };

  const active = scenarios[activeId] ?? scenarios[scenarioIds[0]];
  const scenarioEntries = scenarioIds.map((id) => [id, scenarios[id]]);

  return (
    <TerminalShell
      title={title}
      subtitle={subtitle}
      badge={{ label: 'Simulated', kind: 'sim' }}
      footer={
        footer ?? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
              {scenarioEntries.map(([id, s]) => (
                <button
                  key={id}
                  className={`uk-scenario-btn ${id === activeId ? 'active' : ''}`}
                  onClick={() => switchScenario(id)}
                  disabled={running}
                  title={s.desc ?? ''}
                >
                  {s.icon ?? '▶'} {s.label}
                </button>
              ))}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span className="uk-dim" style={{ fontSize: 10.5 }}>{active.desc ?? 'Cosmetic preview — output is scripted.'}</span>
              <button className="uk-btn uk-btn-ghost uk-btn-sm" onClick={() => play(script)} disabled={running}>
                {running ? 'Playing…' : '↻ Replay'}
              </button>
            </div>
          </div>
        )
      }
    >
      <div ref={bodyRef} style={{ maxHeight: 340, overflowY: 'auto' }}>
        {rendered.map((r) => (
          <div key={r.id} className={`uk-line ${r.cls}`}>
            {r.text}
            {r.typing && <span className="uk-cursor" />}
          </div>
        ))}
        {progress && (
          <div style={{ marginTop: 10 }}>
            <div className="uk-dim" style={{ marginBottom: 5, fontSize: 12 }}>
              {progress.label}
            </div>
            <div className="uk-bar-track">
              <div className="uk-bar-fill" style={{ width: `${progress.pct}%` }} />
            </div>
          </div>
        )}
        {!running && !progress && rendered.length > 0 && (
          <div className="uk-line">
            <span className="uk-prompt">❯</span> <span className="uk-cursor" />
          </div>
        )}
      </div>
    </TerminalShell>
  );
}

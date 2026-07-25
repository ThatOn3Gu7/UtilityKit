import { useState, useEffect, useRef, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';

function beep() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = 880;
    gain.gain.setValueAtTime(0.15, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4);
    osc.start();
    osc.stop(ctx.currentTime + 0.4);
  } catch {
    /* audio not available */
  }
}

export default function PomodoroTimer() {
  const [work, setWork] = useState(25);
  const [brk, setBrk] = useState(5);
  const [cycles, setCycles] = useState(4);
  const [running, setRunning] = useState(false);
  const [phase, setPhase] = useState('work');
  const [cycle, setCycle] = useState(1);
  const [remaining, setRemaining] = useState(work * 60);
  const intervalRef = useRef(null);
  const phaseRef = useRef(phase);
  const cycleRef = useRef(cycle);
  const cyclesRef = useRef(cycles);
  const workRef = useRef(work);
  const brkRef = useRef(brk);
  useEffect(() => { phaseRef.current = phase; }, [phase]);
  useEffect(() => { cycleRef.current = cycle; }, [cycle]);
  useEffect(() => { cyclesRef.current = cycles; }, [cycles]);
  useEffect(() => { workRef.current = work; }, [work]);
  useEffect(() => { brkRef.current = brk; }, [brk]);

  const totalForPhase = (phase === 'work' ? work : brk) * 60;

  const reset = useCallback(() => {
    clearInterval(intervalRef.current);
    setRunning(false);
    setPhase('work');
    setCycle(1);
    setRemaining(work * 60);
  }, [work]);

  useEffect(() => {
    if (!running) return;
    intervalRef.current = setInterval(() => {
      setRemaining((r) => {
        if (r <= 1) {
          beep();
          const curPhase = phaseRef.current;
          const curCycle = cycleRef.current;
          if (curPhase === 'work') {
            if (curCycle >= cyclesRef.current) {
              clearInterval(intervalRef.current);
              setRunning(false);
              return 0;
            }
            setPhase('break');
            return brkRef.current * 60;
          } else {
            setPhase('work');
            setCycle((c) => c + 1);
            return workRef.current * 60;
          }
        }
        return r - 1;
      });
    }, 1000);
    return () => clearInterval(intervalRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [running]);

  const mm = String(Math.floor(remaining / 60)).padStart(2, '0');
  const ss = String(remaining % 60).padStart(2, '0');
  const pct = totalForPhase ? ((totalForPhase - remaining) / totalForPhase) * 100 : 0;

  return (
    <TerminalShell
      title="pomodoro — Focus Timer"
      subtitle="_pomodoro.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="A real countdown runs in your browser tab, with an audio chime at each transition."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Work (min)</label>
          <input className="uk-input" type="number" min={1} max={90} value={work} disabled={running} onChange={(e) => { const v = Number(e.target.value) || 25; setWork(v); if (!running && phase === 'work') setRemaining(v * 60); }} />
        </div>
        <div className="uk-field">
          <label>Break (min)</label>
          <input className="uk-input" type="number" min={1} max={30} value={brk} disabled={running} onChange={(e) => setBrk(Number(e.target.value) || 5)} />
        </div>
        <div className="uk-field">
          <label>Cycles</label>
          <input className="uk-input" type="number" min={1} max={12} value={cycles} disabled={running} onChange={(e) => setCycles(Number(e.target.value) || 4)} />
        </div>
      </div>

      <div className="uk-out-box" style={{ textAlign: 'center', padding: '22px 16px' }}>
        <div className="uk-dim" style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}>
          {phase === 'work' ? '◆ Work focus' : '☕ Break time'} &nbsp;·&nbsp; cycle {cycle}/{cycles}
        </div>
        <div style={{ fontSize: 42, fontWeight: 700, color: phase === 'work' ? '#3fb950' : '#39c5cf', letterSpacing: '0.02em' }}>
          {mm}:{ss}
        </div>
        <div className="uk-bar-track" style={{ marginTop: 14 }}>
          <div className="uk-bar-fill" style={{ width: `${pct}%` }} />
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        <button className="uk-btn" onClick={() => setRunning((r) => !r)}>
          {running ? '⏸ Pause' : '▶ Start'}
        </button>
        <button className="uk-btn uk-btn-ghost" onClick={reset}>
          ↻ Reset
        </button>
      </div>
    </TerminalShell>
  );
}

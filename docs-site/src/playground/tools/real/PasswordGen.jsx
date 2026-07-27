import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

const WORDLIST = [
  'amber', 'anchor', 'aurora', 'bamboo', 'beacon', 'cedar', 'comet', 'copper', 'cosmos', 'delta',
  'ember', 'falcon', 'fern', 'glacier', 'harbor', 'ivy', 'lantern', 'marble', 'meadow', 'meteor',
  'neon', 'orchard', 'pebble', 'phoenix', 'pine', 'prism', 'quartz', 'river', 'shadow', 'signal',
  'solar', 'sparrow', 'summit', 'thunder', 'velvet', 'willow', 'zenith',
];
const STRING_CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+=-';

function randInt(max) {
  const arr = new Uint32Array(1);
  const limit = 0x100000000 - (0x100000000 % max);
  let v;
  do { crypto.getRandomValues(arr); v = arr[0]; } while (v >= limit);
  return v % max;
}

function genPassphrase(words, sep) {
  return Array.from({ length: words }, () => WORDLIST[randInt(WORDLIST.length)]).join(sep);
}
function genString(len) {
  return Array.from({ length: len }, () => STRING_CHARSET[randInt(STRING_CHARSET.length)]).join('');
}
function entropyWords(n) {
  return (n * Math.log2(WORDLIST.length)).toFixed(2);
}
function entropyString(n) {
  return (n * Math.log2(STRING_CHARSET.length)).toFixed(2);
}

export default function PasswordGen() {
  const [mode, setMode] = useState('passphrase');
  const [words, setWords] = useState(4);
  const [sep, setSep] = useState('-');
  const [len, setLen] = useState(20);
  const [result, setResult] = useState(() => genPassphrase(4, '-'));

  const regenerate = useCallback(() => {
    setResult(mode === 'passphrase' ? genPassphrase(words, sep) : genString(len));
  }, [mode, words, sep, len]);

  const entropy = mode === 'passphrase' ? entropyWords(words) : entropyString(len);

  return (
    <TerminalShell
      title="pass — Password Generator"
      subtitle="_password_gen.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Runs entirely in your browser via crypto.getRandomValues — nothing is sent anywhere."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Mode</label>
          <select className="uk-select" value={mode} onChange={(e) => setMode(e.target.value)}>
            <option value="passphrase">passphrase</option>
            <option value="string">string</option>
          </select>
        </div>
        {mode === 'passphrase' ? (
          <>
            <div className="uk-field">
              <label>Words</label>
              <input
                className="uk-input"
                type="number"
                min={3}
                max={10}
                value={words}
                onChange={(e) => setWords(Number(e.target.value) || 4)}
              />
            </div>
            <div className="uk-field">
              <label>Separator</label>
              <input className="uk-input" value={sep} maxLength={3} onChange={(e) => setSep(e.target.value)} />
            </div>
          </>
        ) : (
          <div className="uk-field">
            <label>Length</label>
            <input
              className="uk-input"
              type="number"
              min={8}
              max={64}
              value={len}
              onChange={(e) => setLen(Number(e.target.value) || 20)}
            />
          </div>
        )}
      </div>

      <button className="uk-btn" onClick={regenerate}>
        ⚙ Generate
      </button>

      <div className="uk-out-box">
        <CopyButton text={result} />
        <div className="uk-line uk-bold" style={{ color: '#3fb950', fontSize: 15, paddingRight: 70 }}>
          {result}
        </div>
        <div className="uk-line uk-dim" style={{ marginTop: 8, fontSize: 11.5 }}>
          ◆ Entropy: <span className="uk-yellow">~{entropy} bits</span> &nbsp;·&nbsp; mode: {mode}
        </div>
      </div>
    </TerminalShell>
  );
}

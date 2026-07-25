import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

const CROCKFORD = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const SHORT_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

function randBytes(n) {
  const b = new Uint8Array(n);
  crypto.getRandomValues(b);
  return b;
}
function toHex(bytes) {
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
}

function uuid4() {
  return crypto.randomUUID();
}
function uuid7() {
  const ts = BigInt(Date.now());
  const tsHex = ts.toString(16).padStart(12, '0');
  const randHex = toHex(randBytes(10));
  let hex = tsHex + randHex;
  hex = hex.slice(0, 12) + '7' + hex.slice(13, 16) + '8' + hex.slice(17);
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
function ulid() {
  let ts = Date.now();
  let tsStr = '';
  for (let i = 0; i < 10; i++) {
    tsStr = CROCKFORD[ts % 32] + tsStr;
    ts = Math.floor(ts / 32);
  }
  const rand = randBytes(10);
  let randStr = '';
  let bits = 0n;
  for (const b of rand) bits = (bits << 8n) | BigInt(b);
  for (let i = 0; i < 16; i++) {
    randStr = CROCKFORD[Number(bits & 31n)] + randStr;
    bits >>= 5n;
  }
  return tsStr + randStr;
}
function shortId(len = 8, alphabet = SHORT_ALPHABET) {
  const b = randBytes(len);
  const limit = 256 - (256 % alphabet.length);
  const out = [];
  for (const v of b) {
    if (v < limit) out.push(alphabet[v % alphabet.length]);
  }
  while (out.length < len) {
    const fill = randBytes(1)[0];
    if (fill < limit) out.push(alphabet[fill % alphabet.length]);
  }
  return out.join('').slice(0, len);
}
function hexId(len = 32) {
  return toHex(randBytes(Math.ceil(len / 2))).slice(0, len);
}

const GENERATORS = {
  uuid4: () => uuid4(),
  uuid7: () => uuid7(),
  ulid: () => ulid(),
  short: () => shortId(8),
  hex: () => hexId(32),
};

export default function UuidGen() {
  const [type, setType] = useState('uuid4');
  const [count, setCount] = useState(5);
  const [items, setItems] = useState(() => Array.from({ length: 5 }, GENERATORS.uuid4));

  const regenerate = useCallback(() => {
    const gen = GENERATORS[type];
    setItems(Array.from({ length: Math.max(1, Math.min(50, count)) }, gen));
  }, [type, count]);

  const joined = items.join('\n');

  return (
    <TerminalShell
      title="uuid — UUID / ULID / NanoID Gen"
      subtitle="_uuid_gen.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Generated with crypto.getRandomValues — cryptographically random, computed locally."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Type</label>
          <select className="uk-select" value={type} onChange={(e) => setType(e.target.value)}>
            <option value="uuid4">uuid4</option>
            <option value="uuid7">uuid7 (time-ordered)</option>
            <option value="ulid">ulid</option>
            <option value="short">short (8 char)</option>
            <option value="hex">hex (32 char)</option>
          </select>
        </div>
        <div className="uk-field">
          <label>Count</label>
          <input
            className="uk-input"
            type="number"
            min={1}
            max={50}
            value={count}
            onChange={(e) => setCount(Number(e.target.value) || 1)}
          />
        </div>
      </div>
      <button className="uk-btn" onClick={regenerate}>
        ⚙ Generate
      </button>

      <div className="uk-out-box">
        <CopyButton text={joined} />
        <div style={{ paddingRight: 70 }}>
          {items.map((id, i) => (
            <div key={i} className="uk-line uk-cyan">
              {id}
            </div>
          ))}
        </div>
      </div>
    </TerminalShell>
  );
}

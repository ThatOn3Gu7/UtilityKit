import { useState, useEffect, useRef } from 'react';
import QRCode from 'qrcode';
import TerminalShell from '../../components/TerminalShell';

function buildWifiPayload(ssid, psk, enc, hidden) {
  const esc = (s) => s.replace(/([\\;,:"])/g, '\\$1');
  let out = `WIFI:T:${enc};S:${esc(ssid)};`;
  if (enc !== 'nopass') out += `P:${esc(psk)};`;
  if (hidden) out += 'H:true;';
  return out + ';';
}

export default function QrTool() {
  const [mode, setMode] = useState('text');
  const [text, setText] = useState('https://github.com/Thaton3gu7/UtilityKit');
  const [ssid, setSsid] = useState('HomeNet');
  const [psk, setPsk] = useState('hunter2');
  const [enc, setEnc] = useState('WPA');
  const canvasRef = useRef(null);
  const [error, setError] = useState(null);

  const payload = mode === 'text' ? text : buildWifiPayload(ssid, psk, enc, false);

  useEffect(() => {
    if (!canvasRef.current || !payload) return;
    QRCode.toCanvas(canvasRef.current, payload, { width: 220, margin: 2, color: { dark: '#e6edf3', light: '#0d1117' } }, (err) => {
      setError(err ? err.message : null);
    });
  }, [payload]);

  return (
    <TerminalShell
      title="qr — QR Tool"
      subtitle="_qr_tool.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Encoded locally with the qrcode JS library — no image or data leaves your browser."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Mode</label>
          <select className="uk-select" value={mode} onChange={(e) => setMode(e.target.value)}>
            <option value="text">text / URL</option>
            <option value="wifi">wifi</option>
          </select>
        </div>
      </div>

      {mode === 'text' ? (
        <div className="uk-field">
          <label>Text or URL</label>
          <input className="uk-input" value={text} onChange={(e) => setText(e.target.value)} />
        </div>
      ) : (
        <>
          <div className="uk-row">
            <div className="uk-field">
              <label>SSID</label>
              <input className="uk-input" value={ssid} onChange={(e) => setSsid(e.target.value)} />
            </div>
            <div className="uk-field">
              <label>Encryption</label>
              <select className="uk-select" value={enc} onChange={(e) => setEnc(e.target.value)}>
                <option value="WPA">WPA</option>
                <option value="WEP">WEP</option>
                <option value="nopass">nopass</option>
              </select>
            </div>
          </div>
          {enc !== 'nopass' && (
            <div className="uk-field">
              <label>Passphrase</label>
              <input className="uk-input" value={psk} onChange={(e) => setPsk(e.target.value)} />
            </div>
          )}
        </>
      )}

      <div className="uk-out-box" style={{ display: 'flex', justifyContent: 'center', padding: 16 }}>
        {error ? <div className="uk-red">{error}</div> : <canvas ref={canvasRef} />}
      </div>
    </TerminalShell>
  );
}

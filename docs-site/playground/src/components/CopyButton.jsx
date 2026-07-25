import { useState } from 'react';

export default function CopyButton({ text, className = '' }) {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <button className={`uk-btn uk-btn-ghost uk-btn-sm uk-copy-btn ${className}`} onClick={copy} disabled={!text}>
      {copied ? '✓ Copied' : 'Copy'}
    </button>
  );
}

import { useState, useEffect, useCallback } from 'react';

const STORAGE_KEY = 'uk-theme';

function getSystemTheme() {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function readStored() {
  try {
    const v = localStorage.getItem(STORAGE_KEY);
    if (v === 'light' || v === 'dark') return v;
    if (v === 'system') return getSystemTheme();
  } catch {}
  return getSystemTheme();
}

function apply(resolved) {
  const root = document.documentElement;
  if (resolved === 'light') {
    root.classList.remove('dark');
    root.setAttribute('data-theme', 'light');
  } else {
    root.classList.add('dark');
    root.removeAttribute('data-theme');
  }
}

export default function useTheme() {
  const [resolved, setResolved] = useState(() => readStored());

  useEffect(() => {
    apply(resolved);
  }, [resolved]);

  const toggle = useCallback(() => {
    setResolved((prev) => {
      const next = prev === 'dark' ? 'light' : 'dark';
      try { localStorage.setItem(STORAGE_KEY, next); } catch {}
      return next;
    });
  }, []);

  const setMode = useCallback((mode) => {
    const next = mode === 'system' ? getSystemTheme() : mode;
    setResolved(next);
    try { localStorage.setItem(STORAGE_KEY, mode); } catch {}
  }, []);

  return { resolved, toggle, setMode };
}

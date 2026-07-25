import { useState, useEffect } from 'react';
import { Terminal, Menu, X, Sun, Moon, ExternalLink, Wrench, Sparkle, BookOpen, Gamepad2 } from 'lucide-react';
import useTheme from '../hooks/useTheme';

const NAV = [
  { label: 'Tools', href: '../tools', icon: Wrench },
  { label: 'Getting Started', href: '../docs/getting-started', icon: Sparkle },
  { label: 'Architecture', href: '../docs/architecture', icon: BookOpen },
];

export default function Header() {
  const { resolved, toggle } = useTheme();
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <header
      className="pg-header"
      data-scrolled={scrolled}
    >
      <div className="pg-header-inner">
        <a href="../" className="pg-header-logo">
          <span className="pg-header-icon">
            <Terminal size={18} strokeWidth={2.5} />
          </span>
          <div className="pg-header-title">
            <span className="pg-header-name">UtilityKit</span>
            <span className="pg-header-sub">65 tools · one dashboard</span>
          </div>
        </a>

        <nav className="pg-header-nav">
          {NAV.map(({ label, href, icon: Icon }) => (
            <a key={href} href={href} className="pg-header-link">
              <Icon size={13} strokeWidth={1.8} />
              {label}
            </a>
          ))}
        </nav>

        <div className="pg-header-actions">
          <a href="../" className="pg-header-pg-btn">
            <Gamepad2 size={14} strokeWidth={1.8} />
            <span>Docs</span>
          </a>

          <button
            onClick={toggle}
            className="pg-header-theme"
            aria-label="Toggle theme"
          >
            {resolved === 'dark' ? <Sun size={15} /> : <Moon size={15} />}
          </button>

          <button
            onClick={() => setOpen(!open)}
            className="pg-header-hamburger"
            aria-label="Menu"
          >
            {open ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>
      </div>

      {open && (
        <div className="pg-header-mobile">
          {NAV.map(({ label, href, icon: Icon }) => (
            <a key={href} href={href} className="pg-header-mlink" onClick={() => setOpen(false)}>
              <Icon size={15} strokeWidth={1.8} />
              {label}
              <ExternalLink size={12} className="pg-header-ext" />
            </a>
          ))}
          <a href="../" className="pg-header-mlink" onClick={() => setOpen(false)}>
            <Gamepad2 size={15} strokeWidth={1.8} />
            Docs Home
            <ExternalLink size={12} className="pg-header-ext" />
          </a>
        </div>
      )}
    </header>
  );
}

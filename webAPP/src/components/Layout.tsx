import { useState, useEffect } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  MagnifyingGlass,
  List,
  X,
  GithubLogo,
  ArrowUpRight,
  ArrowRight,
  Terminal,
  BookOpen,
  Wrench,
  Sparkle,
} from "@phosphor-icons/react";
import { TOOLS } from "@/data/tools";
import { ThemeToggle } from "./ThemeToggle";

function SearchModal({ onClose }: { onClose: () => void }) {
  const [query, setQuery] = useState("");
  const [activeIdx, setActiveIdx] = useState(0);
  const navigate = useNavigate();

  const results = query.trim().length > 0
    ? TOOLS.filter((t) => {
        const q = query.toLowerCase();
        return (
          t.name.toLowerCase().includes(q) ||
          t.command.toLowerCase().includes(q) ||
          t.description.toLowerCase().includes(q)
        );
      }).slice(0, 8)
    : TOOLS.slice(0, 6);

  useEffect(() => { setActiveIdx(0); }, [query]);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
      if (e.key === "ArrowDown") { e.preventDefault(); setActiveIdx((i) => Math.min(i + 1, results.length - 1)); }
      if (e.key === "ArrowUp") { e.preventDefault(); setActiveIdx((i) => Math.max(i - 1, 0)); }
      if (e.key === "Enter" && results[activeIdx]) {
        navigate(`/tools/${results[activeIdx].command}`);
        onClose();
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [onClose, results, activeIdx, navigate]);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.18 }}
      className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh] px-4"
      style={{ background: "color-mix(in oklab, var(--bg-inset) 60%, transparent)", backdropFilter: "blur(6px)" }}
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: -16, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: -8, scale: 0.98 }}
        transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }}
        className="w-full max-w-2xl rounded-2xl overflow-hidden glass-strong"
        style={{
          border: "1px solid var(--border-strong)",
          boxShadow: "var(--shadow-lg)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 px-4 py-3.5 border-b" style={{ borderColor: "var(--border)" }}>
          <MagnifyingGlass size={18} style={{ color: "var(--text-muted)" }} />
          <input
            autoFocus
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search 63 tools…"
            className="flex-1 bg-transparent outline-none text-sm"
            style={{ color: "var(--text)" }}
          />
          <kbd
            className="text-[10px] font-mono px-1.5 py-0.5 rounded"
            style={{
              color: "var(--text-subtle)",
              border: "1px solid var(--border)",
              background: "var(--bg-subtle)",
            }}
          >
            ESC
          </kbd>
        </div>

        <div className="py-2 max-h-[55vh] overflow-y-auto">
          {results.length > 0 ? (
            <>
              {query.trim().length === 0 && (
                <div
                  className="px-4 py-1.5 text-[10px] font-semibold uppercase tracking-wider"
                  style={{ color: "var(--text-faint)" }}
                >
                  Popular tools
                </div>
              )}
              <ul>
                {results.map((tool, i) => (
                  <li key={tool.command}>
                    <button
                      onMouseEnter={() => setActiveIdx(i)}
                      onClick={() => { navigate(`/tools/${tool.command}`); onClose(); }}
                      className="w-full text-left px-4 py-2.5 flex items-center gap-3 transition-colors"
                      style={{
                        background: i === activeIdx ? "var(--accent-subtle)" : "transparent",
                      }}
                    >
                      <span
                        className="w-8 h-8 rounded-md flex items-center justify-center text-sm font-mono shrink-0"
                        style={{
                          background: "var(--bg-subtle)",
                          color: "var(--accent)",
                          border: "1px solid var(--border)",
                        }}
                      >
                        {tool.icon}
                      </span>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium truncate" style={{ color: "var(--text)" }}>
                            {tool.name}
                          </span>
                          <code
                            className="text-[10px] font-mono px-1.5 py-0.5 rounded shrink-0"
                            style={{
                              background: "var(--accent-subtle)",
                              color: "var(--accent)",
                            }}
                          >
                            {tool.command}
                          </code>
                        </div>
                        <p
                          className="text-xs truncate mt-0.5"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {tool.description}
                        </p>
                      </div>
                      {i === activeIdx && (
                        <ArrowRight size={13} style={{ color: "var(--accent)" }} />
                      )}
                    </button>
                  </li>
                ))}
              </ul>
            </>
          ) : (
            <div className="px-4 py-10 text-center" style={{ color: "var(--text-subtle)" }}>
              <div className="text-sm">No tools found for "{query}"</div>
              <div className="text-xs mt-1" style={{ color: "var(--text-faint)" }}>
                Try a different keyword or command.
              </div>
            </div>
          )}
        </div>

        <div
          className="px-4 py-2 border-t flex items-center justify-between text-[10px] font-mono"
          style={{ borderColor: "var(--border)", color: "var(--text-faint)" }}
        >
          <div className="flex items-center gap-3">
            <span>↑↓ navigate</span>
            <span>↵ open</span>
            <span>esc close</span>
          </div>
          <span>{results.length} results</span>
        </div>
      </motion.div>
    </motion.div>
  );
}

const NAV_LINKS = [
  { label: "Tools", href: "/tools", icon: <Wrench size={14} weight="duotone" /> },
  { label: "Getting Started", href: "/docs/getting-started", icon: <Sparkle size={14} weight="duotone" /> },
  { label: "Architecture", href: "/docs/architecture", icon: <BookOpen size={14} weight="duotone" /> },
];

export function Layout({ children }: { children: React.ReactNode }) {
  const [searchOpen, setSearchOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setSearchOpen(true);
      }
      if (e.key === "/" && !searchOpen) {
        const tag = (e.target as HTMLElement)?.tagName;
        if (tag !== "INPUT" && tag !== "TEXTAREA") {
          e.preventDefault();
          setSearchOpen(true);
        }
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [searchOpen]);

  useEffect(() => { setMobileMenuOpen(false); }, [location.pathname]);
  useEffect(() => { window.scrollTo({ top: 0, behavior: "instant" as ScrollBehavior }); }, [location.pathname]);

  return (
    <div
      className="min-h-screen flex flex-col relative"
      style={{ color: "var(--text)" }}
    >
      {/* HEADER */}
      <motion.header
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
        className="sticky top-0 z-40 transition-all duration-200"
        style={{
          background: scrolled ? "color-mix(in oklab, var(--bg) 78%, transparent)" : "transparent",
          borderBottom: `1px solid ${scrolled ? "var(--border)" : "transparent"}`,
          backdropFilter: scrolled ? "saturate(180%) blur(14px)" : "none",
          WebkitBackdropFilter: scrolled ? "saturate(180%) blur(14px)" : "none",
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className={`flex items-center justify-between transition-all ${scrolled ? "py-3" : "py-4"}`}>
            {/* Logo */}
            <Link to="/" className="flex items-center gap-2.5 group">
              <motion.div
                whileHover={{ rotate: [-2, 6, -2, 0], transition: { duration: 0.5 } }}
                className="relative w-9 h-9 rounded-lg flex items-center justify-center font-bold text-sm"
                style={{
                  background: "linear-gradient(135deg, var(--accent) 0%, color-mix(in oklab, var(--accent) 60%, #3b82f6) 100%)",
                  color: "var(--accent-fg)",
                  boxShadow: "var(--shadow-glow)",
                }}
              >
                <Terminal size={18} weight="fill" />
                <span
                  className="absolute -inset-0.5 rounded-lg pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity"
                  style={{
                    background: "linear-gradient(135deg, var(--accent) 0%, #3b82f6 100%)",
                    filter: "blur(10px)",
                    zIndex: -1,
                  }}
                />
              </motion.div>
              <div className="flex flex-col leading-none">
                <span className="font-semibold tracking-tight text-[15px]" style={{ color: "var(--text)" }}>
                  UtilityKit
                </span>
                <span
                  className="text-[10px] font-mono mt-0.5 hidden sm:block"
                  style={{ color: "var(--text-faint)" }}
                >
                  63 tools · one dashboard
                </span>
              </div>
            </Link>

            {/* Desktop nav */}
            <nav className="hidden md:flex items-center gap-1">
              {NAV_LINKS.map((link) => {
                const active = location.pathname.startsWith(link.href.split("?")[0]);
                return (
                  <Link
                    key={link.href}
                    to={link.href}
                    className="relative px-3 py-1.5 text-sm rounded-lg flex items-center gap-1.5 transition-colors"
                    style={{
                      color: active ? "var(--text)" : "var(--text-muted)",
                    }}
                  >
                    {active && (
                      <motion.span
                        layoutId="nav-pill"
                        className="absolute inset-0 rounded-lg"
                        style={{ background: "var(--bg-subtle)", border: "1px solid var(--border)" }}
                        transition={{ type: "spring", stiffness: 380, damping: 30 }}
                      />
                    )}
                    <span className="relative flex items-center gap-1.5">
                      {link.icon}
                      {link.label}
                    </span>
                  </Link>
                );
              })}
            </nav>

            {/* Right side */}
            <div className="flex items-center gap-2">
              {/* Search button */}
              <button
                onClick={() => setSearchOpen(true)}
                className="hidden sm:flex items-center gap-2 pl-2.5 pr-1.5 py-1.5 rounded-lg text-sm transition-colors hover:border-[var(--border-hover)]"
                style={{
                  border: "1px solid var(--border)",
                  background: "var(--bg-elevated)",
                  color: "var(--text-muted)",
                }}
              >
                <MagnifyingGlass size={13} />
                <span className="text-xs">Search…</span>
                <kbd
                  className="text-[10px] font-mono px-1.5 py-0.5 rounded"
                  style={{
                    background: "var(--bg-subtle)",
                    color: "var(--text-subtle)",
                    border: "1px solid var(--border)",
                  }}
                >
                  ⌘K
                </kbd>
              </button>

              <button
                onClick={() => setSearchOpen(true)}
                className="sm:hidden w-9 h-9 rounded-lg flex items-center justify-center border"
                style={{
                  borderColor: "var(--border)",
                  background: "var(--bg-elevated)",
                  color: "var(--text-muted)",
                }}
                aria-label="Search"
              >
                <MagnifyingGlass size={16} />
              </button>

              <ThemeToggle />

              <a
                href="https://github.com/Thaton3gu7/UtilityKit"
                target="_blank"
                rel="noopener noreferrer"
                className="hidden sm:flex w-9 h-9 rounded-lg items-center justify-center border transition-colors"
                style={{
                  borderColor: "var(--border)",
                  background: "var(--bg-elevated)",
                  color: "var(--text-muted)",
                }}
                aria-label="GitHub"
              >
                <GithubLogo size={16} weight="duotone" />
              </a>

              <button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                className="md:hidden w-9 h-9 rounded-lg flex items-center justify-center border"
                style={{
                  borderColor: "var(--border)",
                  background: "var(--bg-elevated)",
                  color: "var(--text-muted)",
                }}
                aria-label="Menu"
              >
                {mobileMenuOpen ? <X size={16} /> : <List size={16} />}
              </button>
            </div>
          </div>

          {/* Mobile menu */}
          <AnimatePresence>
            {mobileMenuOpen && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: "auto", opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
                className="md:hidden overflow-hidden"
              >
                <div
                  className="py-3 border-t flex flex-col gap-1"
                  style={{ borderColor: "var(--border)" }}
                >
                  {NAV_LINKS.map((link) => {
                    const active = location.pathname.startsWith(link.href.split("?")[0]);
                    return (
                      <Link
                        key={link.href}
                        to={link.href}
                        className="px-3 py-2.5 rounded-lg text-sm flex items-center gap-2 transition-colors"
                        style={{
                          background: active ? "var(--bg-subtle)" : "transparent",
                          color: active ? "var(--text)" : "var(--text-muted)",
                        }}
                      >
                        {link.icon}
                        {link.label}
                      </Link>
                    );
                  })}
                  <a
                    href="https://github.com/Thaton3gu7/UtilityKit"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-3 py-2.5 rounded-lg text-sm flex items-center gap-2"
                    style={{ color: "var(--text-muted)" }}
                  >
                    <GithubLogo size={14} weight="duotone" /> GitHub
                    <ArrowUpRight size={12} className="ml-auto opacity-60" />
                  </a>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.header>

      {/* MAIN */}
      <main className="flex-1 relative z-10">{children}</main>

      {/* FOOTER */}
      <footer className="mt-24 border-t relative z-10" style={{ borderColor: "var(--border)" }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-14">
          <div className="grid grid-cols-2 md:grid-cols-5 gap-8">
            <div className="col-span-2">
              <div className="flex items-center gap-2.5 mb-4">
                <div
                  className="w-8 h-8 rounded-lg flex items-center justify-center"
                  style={{
                    background: "linear-gradient(135deg, var(--accent) 0%, color-mix(in oklab, var(--accent) 60%, #3b82f6) 100%)",
                    color: "var(--accent-fg)",
                  }}
                >
                  <Terminal size={16} weight="fill" />
                </div>
                <span className="font-semibold" style={{ color: "var(--text)" }}>UtilityKit</span>
              </div>
              <p className="text-sm max-w-sm leading-relaxed" style={{ color: "var(--text-muted)" }}>
                63 self-contained Bash tools unified under a single dashboard.
                <span className="font-serif italic"> Cross-platform. No root. No build step.</span>
              </p>
              <div className="flex items-center gap-2 mt-4 flex-wrap">
                {["MIT", "Bash 5+", "Linux · macOS · Termux"].map((tag) => (
                  <span
                    key={tag}
                    className="text-[10px] font-mono px-2 py-0.5 rounded-full"
                    style={{
                      background: "var(--accent-subtle)",
                      color: "var(--accent)",
                      border: "1px solid color-mix(in oklab, var(--accent) 20%, transparent)",
                    }}
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>
            <FooterCol title="Docs" links={[
              { label: "Getting Started", to: "/docs/getting-started" },
              { label: "Architecture", to: "/docs/architecture" },
              { label: "All Tools", to: "/tools" },
            ]} />
            <FooterCol title="Categories" links={[
              { label: "Core Suite", to: "/tools?category=core-suite" },
              { label: "Developer", to: "/tools?category=developer-tools" },
              { label: "System", to: "/tools?category=system-network" },
              { label: "Security", to: "/tools?category=files-security" },
            ]} />
            <FooterCol title="Project" links={[
              { label: "GitHub", href: "https://github.com/Thaton3gu7/UtilityKit", external: true },
              { label: "License", href: "https://github.com/Thaton3gu7/UtilityKit/blob/main/LICENSE", external: true },
              { label: "Contribute", href: "https://github.com/Thaton3gu7/UtilityKit/blob/main/CONTRIBUTING.md", external: true },
            ]} />
          </div>

          <div
            className="mt-10 pt-6 border-t flex flex-col sm:flex-row justify-between items-center gap-3"
            style={{ borderColor: "var(--border)" }}
          >
            <p className="text-xs" style={{ color: "var(--text-faint)" }}>
              © 2025 UtilityKit Contributors · MIT
            </p>
            <div className="flex items-center gap-1.5 text-xs font-mono" style={{ color: "var(--text-faint)" }}>
              <span
                className="w-1.5 h-1.5 rounded-full inline-block"
                style={{ background: "var(--accent)", boxShadow: "0 0 8px var(--accent)" }}
              />
              PASS 7/7 · 63 tools · 3 platforms
            </div>
          </div>
        </div>
      </footer>

      <AnimatePresence>
        {searchOpen && <SearchModal onClose={() => setSearchOpen(false)} />}
      </AnimatePresence>
    </div>
  );
}

function FooterCol({ title, links }: {
  title: string;
  links: { label: string; to?: string; href?: string; external?: boolean }[];
}) {
  return (
    <div>
      <h4 className="text-[10px] font-semibold uppercase tracking-wider mb-3" style={{ color: "var(--text-subtle)" }}>
        {title}
      </h4>
      <ul className="space-y-2.5">
        {links.map((l) => (
          <li key={l.label}>
            {l.to ? (
              <Link
                to={l.to}
                className="text-sm transition-colors hover:underline underline-offset-4"
                style={{ color: "var(--text-muted)" }}
              >
                {l.label}
              </Link>
            ) : (
              <a
                href={l.href}
                target={l.external ? "_blank" : undefined}
                rel={l.external ? "noopener noreferrer" : undefined}
                className="text-sm transition-colors hover:underline underline-offset-4 inline-flex items-center gap-1"
                style={{ color: "var(--text-muted)" }}
              >
                {l.label}
                {l.external && <ArrowUpRight size={10} className="opacity-60" />}
              </a>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}


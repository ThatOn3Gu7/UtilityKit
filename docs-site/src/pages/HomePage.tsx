import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { motion, useReducedMotion } from "framer-motion";
import {
  ArrowRight,
  ArrowUpRight,
  GithubLogo,
  Terminal,
  Package,
  Cpu,
  Shield,
  Sparkle,
  Lightning,
  Wrench,
  SealCheck,
  ArrowsClockwise,
  CursorText,
  Key,
  Pulse,
  BracketsCurly,
  MagnifyingGlass,
  CheckCircle,
  Rocket,
  Cube,
  ShieldCheck,
  Timer,
} from "@phosphor-icons/react";
import { TabbedCodeBlock } from "@/components/CodeBlock";

const TERMINAL_TOOLS = [
  { icon: <ArrowsClockwise size={14} weight="duotone" />, name: "Apply Changes", cmd: "apply", desc: "Directory sync with backup & verify" },
  { icon: <CursorText size={14} weight="duotone" />, name: "Batch Rename", cmd: "rename", desc: "Recursive file rename with rollback" },
  { icon: <Key size={14} weight="duotone" />, name: "Password Gen", cmd: "pass", desc: "Passphrases & random strings" },
  { icon: <Pulse size={14} weight="duotone" />, name: "Port Inspector", cmd: "port", desc: "Who owns this TCP port?" },
  { icon: <BracketsCurly size={14} weight="duotone" />, name: "JSON Explorer", cmd: "json", desc: "Pretty-print, extract, summarize" },
  { icon: <MagnifyingGlass size={14} weight="duotone" />, name: "Project Search", cmd: "search", desc: "rg → grep → find fallback chain" },
];

const C = {
  bg: "#0d1117",
  bgElevated: "#161b22",
  border: "rgba(255,255,255,0.09)",
  text: "#e6edf3",
  textMuted: "#8b949e",
  textFaint: "#6e7681",
  textDim: "#4b5563",
  accent: "#7ee787",
  accentGlow: "rgba(126,231,135,0.15)",
  accentBg: "rgba(126,231,135,0.10)",
  dotRed: "#ff5f56",
  dotYellow: "#ffbd2e",
  dotGreen: "#27c93f",
};

function TerminalMockup() {
  const [activeLine, setActiveLine] = useState(0);
  const [cursor, setCursor] = useState(true);
  const reduce = useReducedMotion();

  useEffect(() => {
    if (reduce) return;
    const c = setInterval(() => setCursor((v) => !v), 530);
    return () => clearInterval(c);
  }, [reduce]);

  useEffect(() => {
    if (reduce) return;
    const l = setInterval(() => setActiveLine((v) => (v + 1) % TERMINAL_TOOLS.length), 1800);
    return () => clearInterval(l);
  }, [reduce]);

  return (
    <div className="relative w-full max-w-xl mx-auto">
      <div
        className="absolute -inset-6 rounded-3xl pointer-events-none"
        style={{
          background: `radial-gradient(ellipse at center, ${C.accentGlow} 0%, transparent 65%)`,
          filter: "blur(12px)",
        }}
      />
      <motion.div
        initial={{ opacity: 0, y: 20, rotateX: -8 }}
        animate={{ opacity: 1, y: 0, rotateX: 0 }}
        transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1], delay: 0.1 }}
        className="relative rounded-2xl overflow-hidden font-mono"
        style={{
          background: C.bg,
          border: `1px solid ${C.border}`,
          boxShadow: `0 25px 50px -12px rgba(0,0,0,0.5), 0 0 60px -20px ${C.accentGlow}`,
          transformPerspective: 1000,
        }}
      >
        {/* Titlebar */}
        <div
          className="flex items-center gap-2 px-4 py-3 border-b"
          style={{ borderColor: "rgba(255,255,255,0.06)", background: "rgba(255,255,255,0.02)" }}
        >
          <div className="w-3 h-3 rounded-full" style={{ background: C.dotRed }} />
          <div className="w-3 h-3 rounded-full" style={{ background: C.dotYellow }} />
          <div className="w-3 h-3 rounded-full" style={{ background: C.dotGreen }} />
          <span className="ml-3 text-xs" style={{ color: C.textMuted }}>
            bash — UtilityKit
          </span>
          <span 
            className="ml-auto text-[10px] px-1.5 py-0.5 rounded" 
            style={{ color: C.accent, background: "rgba(126,231,135,0.08)" }}
          >
            live
          </span>
        </div>

        {/* Body */}
        <div className="px-5 py-5 text-sm leading-relaxed" style={{ color: C.text }}>
          {/* Command line */}
          <div className="flex items-center gap-1.5 mb-4">
            <span style={{ color: C.accent }}>~</span>
            <span style={{ color: C.textMuted }}>$</span>
            <span style={{ color: C.text }}>bash main.sh</span>
            <span
              className="inline-block w-2 h-4 ml-0.5"
              style={{
                background: cursor ? C.accent : "transparent",
                verticalAlign: "middle",
              }}
            />
          </div>

          {/* ASCII Header Box */}
          <pre
            className="mb-4 text-sm leading-snug"
            style={{ color: C.accent, fontFamily: "inherit", margin: 0 }}
          >
{`╔══════════════════════════════════╗
║        UtilityKit Dashboard            ║
║      65 tools · bash main.sh           ║
╚══════════════════════════════════╝`}
          </pre>

          {/* Tool List */}
          <div className="space-y-0.5 mb-4">
            {TERMINAL_TOOLS.map((tool, i) => (
              <motion.div
                key={tool.cmd}
                animate={{
                  background: i === activeLine ? C.accentBg : "transparent",
                }}
                transition={{ duration: 0.25 }}
                className="flex items-center gap-2 px-2 py-1 rounded"
                style={{
                  borderLeft: `2px solid ${i === activeLine ? C.accent : "transparent"}`,
                }}
              >
                <span 
                  className="text-xs text-center flex-shrink-0"
                  style={{ color: i === activeLine ? C.accent : C.textDim, width: 16 }}
                >
                  {i === activeLine ? "▶" : " "}
                </span>
                <span 
                  className="flex items-center justify-center flex-shrink-0"
                  style={{ color: i === activeLine ? C.text : C.textMuted, width: 20 }}
                >
                  {tool.icon}
                </span>
                <span
                  className="text-xs flex-shrink-0 whitespace-nowrap overflow-hidden text-ellipsis"
                  style={{ color: i === activeLine ? C.text : C.textMuted, width: 120 }}
                  title={tool.name}
                >
                  {tool.name}
                </span>
                <span className="text-xs truncate" style={{ color: C.textFaint }}>
                  {tool.desc}
                </span>
              </motion.div>
            ))}
            <div className="flex items-center gap-2 px-2 py-1">
              <span style={{ width: 16 }} />
              <span style={{ width: 20 }} />
              <span className="text-xs" style={{ color: C.textDim, width: 120 }}>
                · · 59 more
              </span>
              <span className="text-xs" style={{ color: C.textDim }}>
                tools
              </span>
            </div>
          </div>

          {/* Bottom hint bar */}
          <div
            className="text-xs px-3 py-2.5 rounded-md flex items-center gap-5 flex-wrap"
            style={{ background: "rgba(255,255,255,0.03)", color: C.textMuted }}
          >
            <span className="inline-flex items-center gap-1.5">
              <span style={{ color: C.accent }}>Use ▲▼ or j/k</span>
              <span>: scroll</span>
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span style={{ color: C.accent }}>↵</span>
              <span>run</span>
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span style={{ color: C.accent }}>q</span>
              <span>: quit</span>
            </span>
          </div>
        </div>
      </motion.div>
    </div>
  );
}


const STATS = [
  { value: "65", label: "tools", icon: <Package size={16} weight="duotone" /> },
  { value: "3", label: "platforms", icon: <Cpu size={16} weight="duotone" /> },
  { value: "MIT", label: "license", icon: <Shield size={16} weight="duotone" /> },
  { value: "7/7", label: "tests passing", icon: <SealCheck size={16} weight="duotone" /> },
];

const FEATURES = [
  {
    icon: <Sparkle size={20} weight="duotone" />,
    tag: "UX",
    title: "Guided interactive wizards",
    description: "Every tool runs as an arrow-key wizard through the dashboard. Enter to execute, q to quit. No flags required to get started.",
    color: "#10b981",
  },
  {
    icon: <Cpu size={20} weight="duotone" />,
    tag: "Cross-platform",
    title: "Runs everywhere Bash runs",
    description: "Tested on Linux, macOS, and Termux (Android). No root required anywhere. Respects NO_COLOR=1 and NO_UNICODE=1 for CI logs and old terms.",
    color: "#3b82f6",
  },
  {
    icon: <Cube size={20} weight="duotone" />,
    tag: "Architecture",
    title: "Composable shared library",
    description: "All 65 tools share lib/uk_common.sh for color output, prompts, icons, and platform detection — one behavior surface, everywhere.",
    color: "#a855f7",
  },
  {
    icon: <Lightning size={20} weight="duotone" />,
    tag: "Extensible",
    title: "Drop-in plugin system",
    description: "cacheclean's 17-plugin registry shows the pattern: drop a new plugin in and it's discovered immediately. Zero config changes.",
    color: "#f59e0b",
  },
];

const INSTALL_TABS = [
  {
    label: "Homebrew",
    code: `# macOS / Linux — the repo doubles as a tap
brew tap thaton3gu7/utilitykit https://github.com/ThatOn3Gu7/UtilityKit.git
brew install utilitykit
utility`,
  },
  {
    label: "Termux",
    code: `# Grab the .deb from the latest release — no clone needed
curl -fLO https://github.com/ThatOn3Gu7/UtilityKit/releases/latest/download/utilitykit_all.deb
pkg install ./utilitykit_all.deb
utility`,
  },
  {
    label: "Interactive",
    code: `# Clone and launch the interactive dashboard
git clone https://github.com/Thaton3gu7/UtilityKit.git
cd UtilityKit
bash main.sh`,
  },
  {
    label: "Direct CLI",
    code: `# Skip the menu — call tools directly
bash main.sh env --dir . --compare
bash main.sh port 3000
bash main.sh pass --mode passphrase --words 6
bash main.sh json package.json --summary
bash main.sh toc README.md --apply --check-links`,
  },
  {
    label: "System install",
    code: `# From a checkout: system-wide launcher — call from anywhere
bash setup.sh --no-menu
utility help
utility port 3000
utility pass --mode passphrase --words 6`,
  },
];

const CATEGORIES = [
  { name: "Core Suite", count: 6, slug: "core-suite", icon: <Package size={20} weight="duotone" />, color: "#10b981" },
  { name: "Developer", count: 19, slug: "developer-tools", icon: <Terminal size={20} weight="duotone" />, color: "#3b82f6" },
  { name: "System & Network", count: 14, slug: "system-network", icon: <Cpu size={20} weight="duotone" />, color: "#a855f7" },
  { name: "Files & Security", count: 11, slug: "files-security", icon: <ShieldCheck size={20} weight="duotone" />, color: "#f43f5e" },
  { name: "Productivity", count: 13, slug: "productivity", icon: <Timer size={20} weight="duotone" />, color: "#f59e0b" },
];

function AnimatedIn({ children, delay = 0 }: { children: React.ReactNode; delay?: number }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.6, delay, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}

export function HomePage() {
  return (
    <div className="relative">
      {/* HERO */}
      <section className="relative pt-16 pb-20 sm:pt-24 sm:pb-28 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-[1.05fr_1fr] gap-12 lg:gap-16 items-center">
            {/* Left */}
            <div className="min-w-0">
              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, ease: "easeOut" }}
                className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs mb-6"
                style={{
                  border: "1px solid color-mix(in oklab, var(--accent) 30%, transparent)",
                  background: "var(--accent-subtle)",
                  color: "var(--accent)",
                }}
              >
                <span className="relative flex h-1.5 w-1.5">
                  <span
                    className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-60"
                    style={{ background: "var(--accent)" }}
                  />
                  <span className="relative inline-flex rounded-full h-1.5 w-1.5" style={{ background: "var(--accent)" }} />
                </span>
                <span className="font-mono">v5.10.0 · 65 tools · MIT · Bash 5+</span>
              </motion.div>

              <motion.h1
                initial={{ opacity: 0, y: 18 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.05, ease: [0.22, 1, 0.36, 1] }}
                className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-[1.05] mb-5"
                style={{ color: "var(--text)" }}
              >
                Sixty-five terminal tools,{" "}
                <span className="relative inline-block">
                  <span className="text-gradient-accent font-serif italic">one dashboard.</span>
                  <motion.svg
                    initial={{ pathLength: 0, opacity: 0 }}
                    animate={{ pathLength: 1, opacity: 1 }}
                    transition={{ duration: 1, delay: 0.8, ease: "easeInOut" }}
                    viewBox="0 0 300 12"
                    className="absolute left-0 -bottom-2 w-full h-3 pointer-events-none"
                    aria-hidden="true"
                  >
                    <motion.path
                      d="M2 8 Q 80 2, 150 6 T 298 5"
                      fill="none"
                      stroke="var(--accent)"
                      strokeWidth="2"
                      strokeLinecap="round"
                    />
                  </motion.svg>
                </span>
              </motion.h1>

              <motion.p
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.15 }}
                className="text-lg leading-relaxed mb-8 max-w-xl"
                style={{ color: "var(--text-muted)" }}
              >
                A modular Bash toolkit for Linux, macOS, and Termux. Every tool runs standalone or navigates from a single arrow-key menu.{" "}
                <span className="font-serif italic" style={{ color: "var(--text)" }}>
                  No build step. No root. No dependencies.
                </span>
              </motion.p>

              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.25 }}
                className="flex flex-wrap gap-3"
              >
                <Link
                  to="/docs/getting-started"
                  className="group inline-flex items-center gap-2 px-5 py-3 rounded-lg font-medium text-sm transition-all hover:-translate-y-0.5"
                  style={{
                    background: "var(--accent)",
                    color: "var(--accent-fg)",
                    boxShadow: "var(--shadow-glow)",
                  }}
                >
                  <Rocket size={15} weight="fill" />
                  Get Started
                  <ArrowRight size={14} weight="bold" className="transition-transform group-hover:translate-x-0.5" />
                </Link>
                <Link
                  to="/tools"
                  className="inline-flex items-center gap-2 px-5 py-3 rounded-lg font-medium text-sm transition-all hover:-translate-y-0.5"
                  style={{
                    background: "var(--bg-elevated)",
                    color: "var(--text)",
                    border: "1px solid var(--border)",
                  }}
                >
                  <Wrench size={15} weight="duotone" />
                  Browse tools
                </Link>
                <a
                  href="https://github.com/Thaton3gu7/UtilityKit"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-5 py-3 rounded-lg font-medium text-sm transition-all hover:-translate-y-0.5"
                  style={{
                    background: "transparent",
                    color: "var(--text-muted)",
                    border: "1px solid var(--border)",
                  }}
                >
                  <GithubLogo size={15} weight="duotone" />
                  Star
                  <ArrowUpRight size={12} className="opacity-60" />
                </a>
              </motion.div>

              {/* Quick command hint */}
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.6, delay: 0.4 }}
                className="mt-10 flex items-center gap-3"
              >
                <div
                  className="flex items-center gap-2 px-3 py-2 rounded-lg font-mono text-xs"
                  style={{
                    background: "var(--bg-inset)",
                    border: "1px solid var(--border)",
                    color: "var(--text-muted)",
                  }}
                >
                  <span style={{ color: "var(--accent)" }}>$</span>
                  <span>curl -fsSL /support coming soon/</span>
                </div>
                <span className="text-xs" style={{ color: "var(--text-faint)" }}>
                  or just clone the repo
                </span>
              </motion.div>
            </div>

            {/* Right */}
            <div className="relative min-w-0">
              <TerminalMockup />
            </div>
          </div>
        </div>
      </section>

      {/* STATS STRIP */}
      <section
        className="border-y relative"
        style={{
          borderColor: "var(--border)",
          background: "color-mix(in oklab, var(--bg-elevated) 60%, transparent)",
          backdropFilter: "blur(4px)",
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 sm:grid-cols-4 divide-x" style={{ borderColor: "var(--border)" }}>
            {STATS.map((s, i) => (
              <motion.div
                key={s.label}
                initial={{ opacity: 0, y: 12 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: i * 0.06 }}
                className="py-8 px-6 text-center flex flex-col items-center gap-1.5"
                style={{ borderColor: "var(--border)" }}
              >
                <span style={{ color: "var(--accent)" }}>{s.icon}</span>
                <div className="text-3xl font-bold font-mono" style={{ color: "var(--text)" }}>
                  {s.value}
                </div>
                <div
                  className="text-[10px] uppercase tracking-widest font-mono"
                  style={{ color: "var(--text-subtle)" }}
                >
                  {s.label}
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* INSTALL */}
      <section className="py-20 sm:py-28">
        <div className="max-w-3xl mx-auto px-4 sm:px-6">
          <AnimatedIn>
            <div className="text-center mb-12">
              <div
                className="inline-block text-[10px] font-mono uppercase tracking-widest mb-3 px-2 py-0.5 rounded"
                style={{ color: "var(--accent)", background: "var(--accent-subtle)" }}
              >
                INSTALL
              </div>
              <h2 className="text-3xl sm:text-4xl font-bold mb-4" style={{ color: "var(--text)" }}>
                Up and running{" "}
                <span className="font-serif italic text-gradient-accent">in seconds</span>
              </h2>
              <p className="text-base" style={{ color: "var(--text-muted)" }}>
                brew install, pkg install, or clone and go — no build step, no dependencies beyond Bash 5+.
              </p>
            </div>
          </AnimatedIn>
          <AnimatedIn delay={0.1}>
            <TabbedCodeBlock tabs={INSTALL_TABS} />
          </AnimatedIn>
        </div>
      </section>

      {/* FEATURES */}
      <section className="py-16 sm:py-24 border-t" style={{ borderColor: "var(--border)" }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <AnimatedIn>
            <div className="max-w-2xl mb-14">
              <div
                className="inline-block text-[10px] font-mono uppercase tracking-widest mb-3 px-2 py-0.5 rounded"
                style={{ color: "var(--accent)", background: "var(--accent-subtle)" }}
              >
                PRINCIPLES
              </div>
              <h2 className="text-3xl sm:text-4xl font-bold mb-4" style={{ color: "var(--text)" }}>
                Built for the terminal,{" "}
                <span className="font-serif italic">not around it</span>
              </h2>
              <p className="text-base leading-relaxed" style={{ color: "var(--text-muted)" }}>
                Every design decision favors reliability and composability over surface-level polish. The shell is a first-class runtime.
              </p>
            </div>
          </AnimatedIn>

          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {FEATURES.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-40px" }}
                transition={{ duration: 0.5, delay: i * 0.08, ease: [0.22, 1, 0.36, 1] }}
                whileHover={{ y: -4 }}
                className="group relative rounded-2xl p-6 overflow-hidden"
                style={{
                  background: "var(--bg-elevated)",
                  border: "1px solid var(--border)",
                }}
              >
                <div
                  className="absolute inset-x-0 top-0 h-px opacity-0 group-hover:opacity-100 transition-opacity"
                  style={{
                    background: `linear-gradient(90deg, transparent, ${f.color}, transparent)`,
                  }}
                />
                <div
                  className="w-11 h-11 rounded-xl flex items-center justify-center mb-5"
                  style={{
                    background: `color-mix(in oklab, ${f.color} 12%, transparent)`,
                    color: f.color,
                    border: `1px solid color-mix(in oklab, ${f.color} 20%, transparent)`,
                  }}
                >
                  {f.icon}
                </div>
                <div
                  className="text-[10px] uppercase tracking-widest font-mono mb-2"
                  style={{ color: f.color }}
                >
                  {f.tag}
                </div>
                <h3 className="font-semibold text-base mb-2 leading-snug" style={{ color: "var(--text)" }}>
                  {f.title}
                </h3>
                <p className="text-sm leading-relaxed" style={{ color: "var(--text-muted)" }}>
                  {f.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CATEGORIES */}
      <section className="py-20 sm:py-28 border-t" style={{ borderColor: "var(--border)" }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <AnimatedIn>
            <div className="flex flex-col sm:flex-row items-start sm:items-end justify-between gap-6 mb-12">
              <div>
                <div
                  className="inline-block text-[10px] font-mono uppercase tracking-widest mb-3 px-2 py-0.5 rounded"
                  style={{ color: "var(--accent)", background: "var(--accent-subtle)" }}
                >
                  CATALOG
                </div>
                <h2 className="text-3xl sm:text-4xl font-bold mb-3" style={{ color: "var(--text)" }}>
                  Explore the toolkit
                </h2>
                <p className="text-base" style={{ color: "var(--text-muted)" }}>
                  65 tools across 5 categories. Search, filter, and dive in.
                </p>
              </div>
              <Link
                to="/tools"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium transition-all whitespace-nowrap"
                style={{
                  background: "var(--bg-elevated)",
                  color: "var(--text)",
                  border: "1px solid var(--border)",
                }}
              >
                View all 65 tools
                <ArrowRight size={13} />
              </Link>
            </div>
          </AnimatedIn>

          <div className="grid sm:grid-cols-2 lg:grid-cols-5 gap-4">
            {CATEGORIES.map((cat, i) => (
              <motion.div
                key={cat.slug}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-40px" }}
                transition={{ duration: 0.5, delay: i * 0.06, ease: [0.22, 1, 0.36, 1] }}
              >
                <Link
                  to={`/tools?category=${cat.slug}`}
                  className="group relative flex flex-col gap-3 p-5 rounded-2xl transition-all hover:-translate-y-1 h-full overflow-hidden"
                  style={{
                    background: "var(--bg-elevated)",
                    border: "1px solid var(--border)",
                  }}
                >
                  <div
                    className="absolute -right-6 -bottom-6 w-24 h-24 rounded-full opacity-10 group-hover:opacity-30 transition-opacity blur-xl"
                    style={{ background: cat.color }}
                  />
                  <div
                    className="relative w-11 h-11 rounded-xl flex items-center justify-center"
                    style={{
                      background: `color-mix(in oklab, ${cat.color} 12%, transparent)`,
                      color: cat.color,
                      border: `1px solid color-mix(in oklab, ${cat.color} 20%, transparent)`,
                    }}
                  >
                    {cat.icon}
                  </div>
                  <div className="relative">
                    <div className="font-medium mb-0.5 transition-colors" style={{ color: "var(--text)" }}>
                      {cat.name}
                    </div>
                    <div className="text-xs font-mono" style={{ color: "var(--text-subtle)" }}>
                      {cat.count} tools
                    </div>
                  </div>
                  <ArrowRight
                    size={14}
                    className="absolute top-5 right-5 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all"
                    style={{ color: cat.color }}
                  />
                </Link>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* DOCTOR CTA */}
      <section className="py-20 border-t" style={{ borderColor: "var(--border)" }}>
        <div className="max-w-4xl mx-auto px-4 sm:px-6">
          <AnimatedIn>
            <div
              className="relative rounded-3xl p-8 sm:p-12 text-center overflow-hidden"
              style={{
                background: "var(--bg-elevated)",
                border: "1px solid var(--border)",
              }}
            >
              <div
                className="absolute inset-0 pointer-events-none opacity-40"
                style={{
                  background: "radial-gradient(ellipse at 50% 0%, var(--accent-glow) 0%, transparent 60%)",
                }}
              />
              <div className="relative">
                <div
                  className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs mb-5"
                  style={{
                    background: "var(--accent-subtle)",
                    color: "var(--accent)",
                    border: "1px solid color-mix(in oklab, var(--accent) 25%, transparent)",
                  }}
                >
                  <CheckCircle size={13} weight="fill" />
                  <span className="font-mono">PASS 7/7 · integrity checker</span>
                </div>
                <h2 className="text-2xl sm:text-3xl font-bold mb-4" style={{ color: "var(--text)" }}>
                  <span className="font-serif italic">Trust,</span> but verify.
                </h2>
                <p className="text-base leading-relaxed max-w-xl mx-auto mb-6" style={{ color: "var(--text-muted)" }}>
                  <code
                    className="font-mono text-sm px-2 py-0.5 rounded"
                    style={{ background: "var(--bg-inset)", color: "var(--accent)" }}
                  >
                    bash main.sh doctor
                  </code>{" "}
                  audits every tool's registry entry, dispatch route, and{" "}
                  <code
                    className="font-mono text-sm px-2 py-0.5 rounded"
                    style={{ background: "var(--bg-inset)", color: "var(--accent)" }}
                  >
                    --help
                  </code>{" "}
                  output in one pass. If it fails, we ship no release.
                </p>
                <Link
                  to="/docs/architecture"
                  className="inline-flex items-center gap-2 text-sm font-medium hover:underline underline-offset-4"
                  style={{ color: "var(--accent)" }}
                >
                  Read the architecture
                  <ArrowRight size={13} />
                </Link>
              </div>
            </div>
          </AnimatedIn>
        </div>
      </section>
    </div>
  );
}

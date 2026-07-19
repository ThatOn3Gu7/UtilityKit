import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import {
  CaretRight,
  ArrowLeft,
  ArrowRight,
  Palette,
  ChatCircle,
  Terminal,
  Compass,
  Check,
  Cube,
} from "@phosphor-icons/react";
import { CodeBlock } from "@/components/CodeBlock";

function Box({
  label,
  sublabel,
  variant = "accent",
  mono = false,
}: {
  label: string;
  sublabel?: string;
  variant?: "accent" | "info" | "neutral";
  mono?: boolean;
}) {
  const s = {
    accent: {
      border: "color-mix(in oklab, var(--accent) 30%, transparent)",
      bg: "var(--accent-subtle)",
      text: "var(--accent)",
    },
    info: {
      border: "color-mix(in oklab, #60a5fa 30%, transparent)",
      bg: "color-mix(in oklab, #60a5fa 10%, transparent)",
      text: "#60a5fa",
    },
    neutral: {
      border: "var(--border)",
      bg: "var(--bg-elevated)",
      text: "var(--text)",
    },
  }[variant];

  return (
    <div
      className="px-4 py-3 rounded-lg text-center"
      style={{ background: s.bg, border: `1px solid ${s.border}` }}
    >
      <div
        className="text-sm font-semibold"
        style={{ color: s.text, fontFamily: mono ? "var(--font-mono)" : "inherit" }}
      >
        {label}
      </div>
      {sublabel && (
        <div className="text-xs mt-0.5" style={{ color: "var(--text-subtle)" }}>
          {sublabel}
        </div>
      )}
    </div>
  );
}

function Arrow({ vertical = false }: { vertical?: boolean }) {
  return (
    <div className={`flex items-center justify-center ${vertical ? "my-1" : "mx-2"}`}>
      {vertical ? (
        <svg width="14" height="20" viewBox="0 0 14 20" fill="none">
          <line x1="7" y1="0" x2="7" y2="14" stroke="var(--border-strong)" strokeWidth="1.5" />
          <path d="M3 10l4 8 4-8" stroke="var(--border-strong)" strokeWidth="1.5" fill="none" strokeLinejoin="round" />
        </svg>
      ) : (
        <svg width="20" height="14" viewBox="0 0 20 14" fill="none">
          <line x1="0" y1="7" x2="14" y2="7" stroke="var(--border-strong)" strokeWidth="1.5" />
          <path d="M10 3l8 4-8 4" stroke="var(--border-strong)" strokeWidth="1.5" fill="none" strokeLinejoin="round" />
        </svg>
      )}
    </div>
  );
}

const TOC = [
  { id: "module-pattern", label: "Self-contained modules" },
  { id: "diagram", label: "System diagram" },
  { id: "router", label: "The router" },
  { id: "shared-library", label: "Shared library" },
  { id: "doctor", label: "Integrity checking" },
  { id: "extending", label: "Extending" },
];

const LIB_ITEMS = [
  {
    icon: <Palette size={18} weight="duotone" />,
    title: "Color output",
    desc: "ANSI helpers for success, warning, error, dim text — gated behind NO_COLOR=1.",
  },
  {
    icon: <ChatCircle size={18} weight="duotone" />,
    title: "Interactive prompts",
    desc: "Reusable yes/no, select, and input prompt functions with consistent styling.",
  },
  {
    icon: <Terminal size={18} weight="duotone" />,
    title: "Icons & glyphs",
    desc: "Unicode icon set with NO_UNICODE=1 fallbacks to plain ASCII equivalents.",
  },
  {
    icon: <Compass size={18} weight="duotone" />,
    title: "Platform detection",
    desc: "uk_os() returns linux, macos, or termux — for platform-specific branching.",
  },
];

const EXTEND_STEPS = [
  {
    n: "1",
    title: "Create the module directory",
    code: "mkdir -p modules/_mytool && touch modules/_mytool/_mytool.sh",
  },
  {
    n: "2",
    title: "Implement with the guard pattern",
    code: `#!/usr/bin/env bash
source "\${TOOLKIT_ROOT}/lib/uk_common.sh"

mytool_main() {
  echo "$(uk_green '✓') mytool running"
}

if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
  mytool_main "$@"
fi`,
  },
  {
    n: "3",
    title: "Register in main.sh",
    code: `# Add to the REGISTRY array in main.sh:
"mytool:modules/_mytool/_mytool.sh:mytool_main"`,
  },
];

function Kbd({ children }: { children: React.ReactNode }) {
  return (
    <code
      className="font-mono text-xs px-1.5 py-0.5 rounded"
      style={{ background: "var(--accent-subtle)", color: "var(--accent)" }}
    >
      {children}
    </code>
  );
}

export function ArchitecturePage() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <div className="flex gap-10">
        <div className="flex-1 min-w-0 max-w-3xl">
          <motion.nav
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.35 }}
            className="flex items-center gap-1.5 text-xs mb-8"
            style={{ color: "var(--text-subtle)" }}
          >
            <Link to="/" className="hover:text-[color:var(--text)] transition-colors">Docs</Link>
            <CaretRight size={11} />
            <span style={{ color: "var(--text)" }}>Architecture</span>
          </motion.nav>

          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
            className="mb-14"
          >
            <div
              className="inline-flex items-center gap-2 text-[10px] font-mono uppercase tracking-widest mb-3 px-2 py-0.5 rounded"
              style={{ color: "var(--accent)", background: "var(--accent-subtle)" }}
            >
              <Cube size={11} weight="fill" /> DOCS · DESIGN
            </div>
            <h1 className="text-4xl sm:text-5xl font-bold tracking-tight mb-4" style={{ color: "var(--text)" }}>
              <span className="font-serif italic">The </span>
              <span className="text-gradient-accent">architecture</span>
            </h1>
            <p className="text-base leading-relaxed max-w-xl" style={{ color: "var(--text-muted)" }}>
              Three core patterns keep modules independent, the router thin, and shared behavior centralized. Understanding them makes extending the toolkit straightforward.
            </p>
          </motion.div>

          {/* 1 */}
          <section id="module-pattern" className="mb-14 scroll-mt-24">
            <SectionH>1. Self-contained modules</SectionH>
            <p className="text-sm leading-relaxed mb-5" style={{ color: "var(--text-muted)" }}>
              Every tool lives under <Kbd>modules/</Kbd> following a strict naming convention: the directory is <Kbd>_&lt;tool&gt;</Kbd>, the script is <Kbd>_&lt;tool&gt;.sh</Kbd>. Each module ships with its own <Kbd>_&lt;tool&gt;_README.md</Kbd>.
            </p>

            <div
              className="rounded-xl p-5 mb-5"
              style={{ background: "var(--bg-elevated)", border: "1px solid var(--border)" }}
            >
              <div
                className="text-[10px] font-mono uppercase tracking-widest mb-3"
                style={{ color: "var(--text-subtle)" }}
              >
                Directory layout
              </div>
              <pre className="text-xs font-mono leading-relaxed" style={{ color: "var(--text)" }}>
{`UtilityKit/
├── main.sh              `}<span style={{ color: "var(--text-subtle)" }}>← central router</span>{`
├── setup.sh             `}<span style={{ color: "var(--text-subtle)" }}>← system-wide installer</span>{`
├── lib/
│   └── uk_common.sh     `}<span style={{ color: "var(--text-subtle)" }}>← shared library</span>{`
└── modules/
    ├── _pass/
    │   ├── _pass.sh          `}<span style={{ color: "var(--accent)" }}>← tool entry point</span>{`
    │   └── _pass_README.md
    ├── _port/
    │   ├── _port.sh
    │   └── _port_README.md
    └── _json/
        ├── _json.sh
        └── _json_README.md`}
              </pre>
            </div>

            <p className="text-sm leading-relaxed mb-4" style={{ color: "var(--text-muted)" }}>
              Each script uses a Bash guard pattern at its entry point. This means the script can be safely <Kbd>source</Kbd>d by the router without executing — side effects only happen when it's run directly or its entry function is called.
            </p>

            <CodeBlock
              label="guard pattern — _pass.sh"
              code={`#!/usr/bin/env bash
# Tool entry function — called by main.sh router or directly
pass_main() {
  # ... tool implementation
}

# Guard: only execute when run directly (not when sourced)
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
  pass_main "$@"
fi`}
            />

            <p className="text-sm leading-relaxed mt-4" style={{ color: "var(--text-muted)" }}>
              This guard means <Kbd>bash modules/_pass/_pass.sh --help</Kbd> works standalone, while <Kbd>bash main.sh pass --help</Kbd> also works via the router — two paths, one implementation.
            </p>
          </section>

          {/* diagram */}
          <section id="diagram" className="mb-14 scroll-mt-24">
            <SectionH>System diagram</SectionH>
            <div
              className="rounded-xl p-6"
              style={{ background: "var(--bg-elevated)", border: "1px solid var(--border)" }}
            >
              <div className="grid grid-cols-3 gap-3 mb-2">
                <Box label="bash main.sh" sublabel="interactive dashboard" variant="info" mono />
                <Box label="bash main.sh <cmd>" sublabel="direct CLI" variant="info" mono />
                <Box label="utility <cmd>" sublabel="system launcher" variant="info" mono />
              </div>

              <div className="flex justify-center my-1"><Arrow vertical /></div>

              <div className="mb-1">
                <Box label="main.sh" sublabel="Central router — parses command, lazy-loads module" variant="accent" mono />
              </div>

              <div className="flex items-center gap-2 my-2">
                <div className="flex-1 h-px" style={{ background: "var(--border)" }} />
                <div className="text-xs font-mono" style={{ color: "var(--text-subtle)" }}>sources</div>
                <div className="flex-1 h-px" style={{ background: "var(--border)" }} />
              </div>

              <div className="mb-3">
                <Box label="lib/uk_common.sh" sublabel="Colors · Icons · Prompts · Platform detection (Linux/macOS/Termux)" variant="neutral" mono />
              </div>

              <div className="flex justify-center my-1"><Arrow vertical /></div>

              <div className="grid grid-cols-3 gap-2 mb-1">
                <Box label="modules/_pass/" sublabel="_pass.sh · README" variant="neutral" mono />
                <Box label="modules/_port/" sublabel="_port.sh · README" variant="neutral" mono />
                <Box label="modules/_json/" sublabel="…and 60 more" variant="neutral" />
              </div>

              <div className="text-center text-xs mt-4" style={{ color: "var(--text-subtle)" }}>
                Each module is self-contained — safe to run standalone or via the router.
              </div>
            </div>
          </section>

          {/* 2 */}
          <section id="router" className="mb-14 scroll-mt-24">
            <SectionH>2. The lazy-loading router</SectionH>
            <p className="text-sm leading-relaxed mb-5" style={{ color: "var(--text-muted)" }}>
              <Kbd>main.sh</Kbd> is the central dispatch layer. With no args it renders the interactive dashboard. With a command name, it resolves that command to the correct module, sources it once (lazy-load), and calls the module's entry function.
            </p>

            <p className="text-sm leading-relaxed mb-4" style={{ color: "var(--text-muted)" }}>
              The router holds a registry — a mapping of command names to module paths and entry functions. This registry is what <Kbd>bash main.sh doctor</Kbd> validates.
            </p>

            <CodeBlock
              label="router pattern — main.sh (conceptual)"
              code={`#!/usr/bin/env bash
# Simplified router logic

REGISTRY=(
  "pass:modules/_pass/_pass.sh:pass_main"
  "port:modules/_port/_port.sh:port_main"
  "json:modules/_json/_json.sh:json_main"
  # ... 60 more entries
)

dispatch() {
  local cmd="$1"; shift
  for entry in "\${REGISTRY[@]}"; do
    IFS=: read -r name path func <<< "$entry"
    if [[ "$name" == "$cmd" ]]; then
      source "$TOOLKIT_ROOT/$path"   # lazy-load
      "$func" "$@"                    # dispatch
      return
    fi
  done
  echo "Unknown command: $cmd" >&2; exit 1
}

[[ $# -eq 0 ]] && show_dashboard || dispatch "$@"`}
            />
          </section>

          {/* 3 */}
          <section id="shared-library" className="mb-14 scroll-mt-24">
            <SectionH>3. The shared library</SectionH>
            <p className="text-sm leading-relaxed mb-5" style={{ color: "var(--text-muted)" }}>
              <Kbd>lib/uk_common.sh</Kbd> is sourced by every module. It provides:
            </p>

            <div className="grid sm:grid-cols-2 gap-3 mb-5">
              {LIB_ITEMS.map((item) => (
                <div
                  key={item.title}
                  className="flex gap-3 p-4 rounded-xl"
                  style={{ background: "var(--bg-elevated)", border: "1px solid var(--border)" }}
                >
                  <span className="shrink-0" style={{ color: "var(--accent)" }}>{item.icon}</span>
                  <div>
                    <div className="text-sm font-semibold mb-1" style={{ color: "var(--text)" }}>
                      {item.title}
                    </div>
                    <p className="text-xs leading-relaxed" style={{ color: "var(--text-muted)" }}>
                      {item.desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <CodeBlock
              label="uk_common.sh — conceptual excerpt"
              code={`#!/usr/bin/env bash
# Platform detection
uk_os() {
  if [[ -n "\${TERMUX_VERSION:-}" ]]; then echo termux
  elif [[ "\$(uname)" == Darwin ]];    then echo macos
  else                                      echo linux
  fi
}

# Color helpers (NO_COLOR=1 respected)
uk_green()  { [[ -z "\${NO_COLOR:-}" ]] && printf '\\033[0;32m%s\\033[0m' "$*" || printf '%s' "$*"; }
uk_red()    { [[ -z "\${NO_COLOR:-}" ]] && printf '\\033[0;31m%s\\033[0m' "$*" || printf '%s' "$*"; }

# Icon helper (NO_UNICODE=1 respected)
uk_icon() {
  local unicode="$1" ascii="$2"
  [[ -n "\${NO_UNICODE:-}" ]] && printf '%s' "$ascii" || printf '%s' "$unicode"
}`}
            />
          </section>

          {/* doctor */}
          <section id="doctor" className="mb-14 scroll-mt-24">
            <SectionH>Integrity checking: doctor</SectionH>
            <p className="text-sm leading-relaxed mb-4" style={{ color: "var(--text-muted)" }}>
              The <Kbd>doctor</Kbd> subcommand is UtilityKit's self-test harness. It iterates the full registry and for each entry verifies:
            </p>
            <ul className="space-y-2.5 mb-5">
              {[
                "The registry entry is well-formed (name, path, entry function all present)",
                "The module file exists at the declared path",
                "The entry function is defined after the module is sourced",
                "--help output is non-empty and exits cleanly",
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-2.5 text-sm" style={{ color: "var(--text-muted)" }}>
                  <span
                    className="w-4 h-4 rounded-full flex items-center justify-center shrink-0 mt-0.5"
                    style={{ background: "var(--accent-subtle)", color: "var(--accent)" }}
                  >
                    <Check size={10} weight="bold" />
                  </span>
                  {item}
                </li>
              ))}
            </ul>
            <CodeBlock
              label="run integrity check"
              code={`bash main.sh doctor
# Expected output:
# [PASS] apply     → modules/_apply/_apply.sh
# [PASS] rename    → modules/_rename/_rename.sh
# ...
# [PASS] ytdl      → modules/_ytdl/_ytdl.sh
# ──────────────────────────────────
# Results: PASS=65 FAIL=0`}
            />
          </section>

          {/* extend */}
          <section id="extending" className="mb-10 scroll-mt-24">
            <SectionH>Extending the toolkit</SectionH>
            <p className="text-sm leading-relaxed mb-4" style={{ color: "var(--text-muted)" }}>
              Adding a new tool follows a three-step pattern:
            </p>
            <ol className="space-y-4 mb-5">
              {EXTEND_STEPS.map((step) => (
                <li key={step.n}>
                  <div className="flex items-center gap-2 mb-2">
                    <span
                      className="w-7 h-7 rounded-md flex items-center justify-center text-xs font-bold font-mono shrink-0"
                      style={{
                        background: "var(--accent-subtle)",
                        color: "var(--accent)",
                        border: "1px solid color-mix(in oklab, var(--accent) 25%, transparent)",
                      }}
                    >
                      {step.n}
                    </span>
                    <span className="text-sm font-medium" style={{ color: "var(--text)" }}>
                      {step.title}
                    </span>
                  </div>
                  <CodeBlock code={step.code} language="bash" />
                </li>
              ))}
            </ol>
            <p className="text-sm leading-relaxed" style={{ color: "var(--text-muted)" }}>
              Run <Kbd>bash main.sh doctor</Kbd> after adding a tool to confirm the entry passes all integrity checks.
            </p>
          </section>

          <div
            className="border-t pt-6 flex justify-between gap-4"
            style={{ borderColor: "var(--border)" }}
          >
            <Link
              to="/docs/getting-started"
              className="flex items-center gap-2 text-sm transition-colors"
              style={{ color: "var(--text-muted)" }}
            >
              <ArrowLeft size={13} /> Getting Started
            </Link>
            <Link
              to="/tools"
              className="flex items-center gap-2 text-sm transition-colors"
              style={{ color: "var(--text-muted)" }}
            >
              Tool Reference <ArrowRight size={13} />
            </Link>
          </div>
        </div>

        <aside className="hidden xl:block w-48 shrink-0">
          <div className="sticky top-24">
            <div
              className="text-[10px] font-semibold uppercase tracking-widest mb-3 px-2 font-mono"
              style={{ color: "var(--text-subtle)" }}
            >
              On this page
            </div>
            {TOC.map((item) => (
              <a
                key={item.id}
                href={`#${item.id}`}
                className="block px-3 py-1.5 text-xs rounded-md transition-colors"
                style={{ color: "var(--text-muted)" }}
                onClick={(e) => {
                  e.preventDefault();
                  document.getElementById(item.id)?.scrollIntoView({ behavior: "smooth" });
                }}
              >
                {item.label}
              </a>
            ))}
          </div>
        </aside>
      </div>
    </div>
  );
}

function SectionH({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="text-xl font-semibold mb-4 flex items-center gap-2.5" style={{ color: "var(--text)" }}>
      <span className="w-1 h-5 rounded-full inline-block" style={{ background: "var(--accent)" }} />
      {children}
    </h2>
  );
}

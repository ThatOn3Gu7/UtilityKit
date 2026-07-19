import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import {
  CaretRight,
  Info,
  Package,
  Cube,
  ArrowRight,
  Rocket,
  Warning,
  CheckCircle,
} from "@phosphor-icons/react";
import { CodeBlock } from "@/components/CodeBlock";

const STEP_COMMANDS = [
  {
    step: "01",
    title: "Clone the repository",
    description:
      "Clone UtilityKit anywhere. No package manager, no build step — just Bash 5+.",
    code: `git clone https://github.com/Thaton3gu7/UtilityKit.git
cd UtilityKit`,
    note: null,
  },
  {
    step: "02",
    title: "Run the interactive dashboard",
    description:
      "Launch the arrow-key dashboard to browse all 65 tools. Or install a system-wide launcher so you can call it from anywhere.",
    code: `# Interactive dashboard (▲/▼ or j/k, ↵ to run, q to quit)
bash main.sh

# Or install a system-wide launcher (default name: utility)
bash setup.sh --no-menu
utility help`,
    note: "setup.sh places the launcher in ~/.local/bin. Make sure that's on your PATH.",
  },
  {
    step: "03",
    title: "Try a direct CLI command",
    description:
      "Every tool works directly from main.sh — no menu required. Useful for scripting and automation.",
    code: `# Find which process owns port 3000
bash main.sh port 3000

# Generate a 6-word passphrase
bash main.sh pass --mode passphrase --words 6

# Compare .env against .env.example
bash main.sh env --dir . --compare

# Pretty-print a JSON file
bash main.sh json package.json --summary`,
    note: null,
  },
  {
    step: "04",
    title: "Explore the tool reference",
    description:
      "Browse all 65 tools with live search and category filters. Each tool has its own docs page with options, examples, and related tools.",
    code: `# Run the built-in integrity checker
bash main.sh doctor

# Show help for any tool without the menu
bash main.sh pass --help
bash main.sh port --help`,
    note: "bash main.sh doctor verifies every tool's registry entry, dispatch route, and --help output in one pass.",
  },
];

const ENV_VARS = [
  {
    name: "NO_COLOR",
    value: "1",
    description:
      "Disables all ANSI color output across every tool. Useful for CI logs, piped output, or terminals that don't support colors.",
    example: "NO_COLOR=1 bash main.sh pass --mode passphrase",
  },
  {
    name: "NO_UNICODE",
    value: "1",
    description:
      "Falls back from Unicode box-drawing characters and icons to plain ASCII alternatives. Useful on older terminals or over slow SSH.",
    example: "NO_UNICODE=1 bash main.sh port 3000",
  },
];

const REQUIREMENTS = [
  { req: "Bash 5+", note: "Check with bash --version. macOS ships Bash 3 — install Bash 5 via Homebrew." },
  { req: "Git", note: "Required to clone the repository. Most systems have it." },
  { req: "No root", note: "All tools and the setup.sh installer run entirely in user space." },
  { req: "Python 3 (opt.)", note: "Powers json, csv, yaml, toc, and links tools for their Python-backed features." },
  { req: "jq (opt.)", note: "Used by api, github, and other tools for JSON formatting. Falls back gracefully." },
];

const TOC = [
  { id: "requirements", label: "Requirements" },
  { id: "installation", label: "Installation" },
  { id: "environment", label: "Environment variables" },
  { id: "verify", label: "Verify installation" },
  { id: "next", label: "Next steps" },
];

export function GettingStartedPage() {
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
            <span style={{ color: "var(--text)" }}>Getting Started</span>
          </motion.nav>

          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
            className="mb-12"
          >
            <div
              className="inline-flex items-center gap-2 text-[10px] font-mono uppercase tracking-widest mb-3 px-2 py-0.5 rounded"
              style={{ color: "var(--accent)", background: "var(--accent-subtle)" }}
            >
              <Rocket size={11} weight="fill" /> DOCS · SETUP
            </div>
            <h1 className="text-4xl sm:text-5xl font-bold tracking-tight mb-4" style={{ color: "var(--text)" }}>
              Getting <span className="font-serif italic text-gradient-accent">Started</span>
            </h1>
            <p className="text-base leading-relaxed max-w-xl" style={{ color: "var(--text-muted)" }}>
              UtilityKit runs on Linux, macOS, and Termux. The only requirement is Bash 5+.{" "}
              <span className="font-serif italic" style={{ color: "var(--text)" }}>
                No build step. No npm install. No configuration.
              </span>
            </p>
          </motion.div>

          {/* Requirements */}
          <section id="requirements" className="mb-14 scroll-mt-24">
            <SectionH>Requirements</SectionH>
            <div
              className="rounded-xl overflow-hidden"
              style={{ background: "var(--bg-elevated)", border: "1px solid var(--border)" }}
            >
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    <th className="px-4 py-3 text-left text-[10px] font-mono font-semibold uppercase tracking-widest w-48" style={{ color: "var(--text-subtle)" }}>Requirement</th>
                    <th className="px-4 py-3 text-left text-[10px] font-mono font-semibold uppercase tracking-widest" style={{ color: "var(--text-subtle)" }}>Notes</th>
                  </tr>
                </thead>
                <tbody>
                  {REQUIREMENTS.map((row, i, arr) => (
                    <tr key={row.req} style={{ borderBottom: i < arr.length - 1 ? "1px solid var(--border)" : "none" }}>
                      <td className="px-4 py-3 align-top">
                        <code className="text-xs font-mono px-1.5 py-0.5 rounded" style={{ background: "var(--accent-subtle)", color: "var(--accent)" }}>
                          {row.req}
                        </code>
                      </td>
                      <td className="px-4 py-3 text-xs leading-relaxed" style={{ color: "var(--text-muted)" }}>
                        {row.note}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          {/* Installation */}
          <section id="installation" className="mb-14 scroll-mt-24">
            <SectionH>Installation</SectionH>
            <div className="space-y-8">
              {STEP_COMMANDS.map((s, idx) => (
                <motion.div
                  key={s.step}
                  initial={{ opacity: 0, y: 16 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: "-60px" }}
                  transition={{ duration: 0.45, delay: idx * 0.05, ease: [0.22, 1, 0.36, 1] }}
                  className="flex gap-5"
                >
                  <div className="flex flex-col items-center shrink-0">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center text-xs font-bold font-mono shrink-0"
                      style={{
                        background: "var(--accent-subtle)",
                        border: "1px solid color-mix(in oklab, var(--accent) 25%, transparent)",
                        color: "var(--accent)",
                      }}
                    >
                      {s.step}
                    </div>
                    {idx < STEP_COMMANDS.length - 1 && (
                      <div
                        className="w-px flex-1 mt-2"
                        style={{
                          background: "linear-gradient(to bottom, color-mix(in oklab, var(--accent) 30%, transparent), transparent)",
                          minHeight: "20px",
                        }}
                      />
                    )}
                  </div>
                  <div className="flex-1 min-w-0 pb-4">
                    <h3 className="text-base font-semibold mb-2" style={{ color: "var(--text)" }}>
                      {s.title}
                    </h3>
                    <p className="text-sm leading-relaxed mb-3" style={{ color: "var(--text-muted)" }}>
                      {s.description}
                    </p>
                    <CodeBlock code={s.code} language="bash" />
                    {s.note && (
                      <p
                        className="text-xs mt-3 flex items-start gap-2 px-3 py-2 rounded-lg"
                        style={{
                          background: "var(--bg-inset)",
                          border: "1px solid var(--border)",
                          color: "var(--text-muted)",
                        }}
                      >
                        <Info size={13} weight="duotone" className="shrink-0 mt-0.5" style={{ color: "var(--accent)" }} />
                        {s.note}
                      </p>
                    )}
                  </div>
                </motion.div>
              ))}
            </div>
          </section>

          {/* Environment */}
          <section id="environment" className="mb-14 scroll-mt-24">
            <SectionH>Environment variables</SectionH>
            <p className="text-sm leading-relaxed mb-6" style={{ color: "var(--text-muted)" }}>
              All 65 tools respect these two variables. Set them in your shell profile or prefix any command.
            </p>
            <div className="space-y-4">
              {ENV_VARS.map((v) => (
                <div
                  key={v.name}
                  className="rounded-xl p-5"
                  style={{ background: "var(--bg-elevated)", border: "1px solid var(--border)" }}
                >
                  <div className="flex items-center gap-2 mb-2">
                    <Warning size={14} weight="duotone" style={{ color: "#f59e0b" }} />
                    <code className="font-mono text-sm" style={{ color: "#f59e0b" }}>
                      {v.name}={v.value}
                    </code>
                  </div>
                  <p className="text-sm leading-relaxed mb-3" style={{ color: "var(--text-muted)" }}>
                    {v.description}
                  </p>
                  <CodeBlock code={v.example} language="bash" />
                </div>
              ))}
            </div>
          </section>

          {/* Verify */}
          <section id="verify" className="mb-14 scroll-mt-24">
            <SectionH>Verify your installation</SectionH>
            <p className="text-sm leading-relaxed mb-4" style={{ color: "var(--text-muted)" }}>
              Run the built-in doctor to confirm all 65 tools are correctly registered and their dispatch routes work end-to-end.
            </p>
            <CodeBlock code={`bash main.sh doctor`} label="integrity check" />
            <p
              className="text-xs mt-3 flex items-start gap-2 px-3 py-2 rounded-lg"
              style={{
                background: "var(--bg-inset)",
                border: "1px solid var(--border)",
                color: "var(--text-muted)",
              }}
            >
              <CheckCircle size={13} weight="duotone" className="shrink-0 mt-0.5" style={{ color: "var(--accent)" }} />
              doctor checks: registry entries, module file existence, entry function names, and --help output for every registered tool.
            </p>
          </section>

          {/* Next */}
          <section id="next" className="mb-8 scroll-mt-24">
            <SectionH>Next steps</SectionH>
            <div className="grid sm:grid-cols-2 gap-4">
              <Link
                to="/tools"
                className="group flex flex-col gap-2 p-5 rounded-2xl transition-all hover:-translate-y-0.5"
                style={{ background: "var(--bg-elevated)", border: "1px solid var(--border)" }}
              >
                <div className="flex items-center gap-2">
                  <Package size={16} weight="duotone" style={{ color: "var(--accent)" }} />
                  <span className="font-semibold text-sm" style={{ color: "var(--text)" }}>Browse all 65 tools</span>
                </div>
                <p className="text-xs" style={{ color: "var(--text-muted)" }}>
                  Search, filter by category, and explore every tool's documentation.
                </p>
                <ArrowRight size={12} className="mt-1 opacity-60 group-hover:translate-x-1 transition-transform" style={{ color: "var(--accent)" }} />
              </Link>
              <Link
                to="/docs/architecture"
                className="group flex flex-col gap-2 p-5 rounded-2xl transition-all hover:-translate-y-0.5"
                style={{ background: "var(--bg-elevated)", border: "1px solid var(--border)" }}
              >
                <div className="flex items-center gap-2">
                  <Cube size={16} weight="duotone" style={{ color: "var(--accent)" }} />
                  <span className="font-semibold text-sm" style={{ color: "var(--text)" }}>Understand the architecture</span>
                </div>
                <p className="text-xs" style={{ color: "var(--text-muted)" }}>
                  How the router, shared library, and guard pattern work together.
                </p>
                <ArrowRight size={12} className="mt-1 opacity-60 group-hover:translate-x-1 transition-transform" style={{ color: "var(--accent)" }} />
              </Link>
            </div>
          </section>
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

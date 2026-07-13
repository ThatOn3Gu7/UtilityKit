import { forwardRef, useEffect, useRef, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import {
  Copy,
  Check,
  ArrowLeft,
  ArrowRight,
  CaretRight,
  Terminal,
  Warning,
  Package,
  Cpu,
  ShieldCheck,
  Timer,
  MagnifyingGlass,
} from "@phosphor-icons/react";
import { TOOLS_BY_COMMAND, TOOLS, type Category } from "@/data/tools";
import { CodeBlock } from "@/components/CodeBlock";

const CATEGORY_COLOR: Record<Category, { color: string; icon: React.ReactNode }> = {
  "Core Suite": { color: "#10b981", icon: <Package size={12} weight="duotone" /> },
  "Developer Tools": { color: "#3b82f6", icon: <Terminal size={12} weight="duotone" /> },
  "System & Network": { color: "#a855f7", icon: <Cpu size={12} weight="duotone" /> },
  "Files & Security": { color: "#f43f5e", icon: <ShieldCheck size={12} weight="duotone" /> },
  Productivity: { color: "#f59e0b", icon: <Timer size={12} weight="duotone" /> },
};

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const ta = document.createElement("textarea");
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  return (
    <button
      onClick={handleCopy}
      className="inline-flex items-center gap-1.5 text-xs px-2.5 py-1 rounded-md transition-all"
      style={{
        color: copied ? "var(--accent)" : "var(--text-muted)",
        background: copied ? "var(--accent-subtle)" : "transparent",
      }}
    >
      {copied ? (
        <>
          <Check size={12} weight="bold" /> Copied
        </>
      ) : (
        <>
          <Copy size={12} weight="duotone" /> Copy
        </>
      )}
    </button>
  );
}

function TableOfContents({ sections, activeSection }: { sections: { id: string; label: string }[]; activeSection: string }) {
  return (
    <nav className="space-y-0.5">
      <div
        className="text-[10px] font-semibold uppercase tracking-widest mb-3 px-2 font-mono"
        style={{ color: "var(--text-subtle)" }}
      >
        On this page
      </div>
      {sections.map((s) => {
        const active = activeSection === s.id;
        return (
          <a
            key={s.id}
            href={`#${s.id}`}
            className="block px-3 py-1.5 text-xs rounded-md transition-all relative"
            style={{
              color: active ? "var(--accent)" : "var(--text-muted)",
              background: active ? "var(--accent-subtle)" : "transparent",
            }}
            onClick={(e) => {
              e.preventDefault();
              document.getElementById(s.id)?.scrollIntoView({ behavior: "smooth" });
            }}
          >
            {active && (
              <motion.span
                layoutId="toc-marker"
                className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-4 rounded-r"
                style={{ background: "var(--accent)" }}
              />
            )}
            <span className="ml-1">{s.label}</span>
          </a>
        );
      })}
    </nav>
  );
}

const TOC_SECTIONS = [
  { id: "overview", label: "Overview" },
  { id: "usage", label: "Usage" },
  { id: "options", label: "Options" },
  { id: "examples", label: "Examples" },
  { id: "related", label: "Related tools" },
];

export function ToolDetailPage() {
  const { command } = useParams<{ command: string }>();
  const [activeSection, setActiveSection] = useState("overview");
  const sectionRefs = useRef<Record<string, HTMLElement | null>>({});

  const tool = command ? TOOLS_BY_COMMAND[command] : undefined;

  useEffect(() => {
    if (!tool) return;
    window.scrollTo(0, 0);
  }, [tool?.command]);

  useEffect(() => {
    if (!tool) return;
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) setActiveSection(entry.target.id);
        });
      },
      { rootMargin: "-20% 0% -60% 0%", threshold: 0 }
    );
    TOC_SECTIONS.forEach(({ id }) => {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, [tool]);

  if (!tool) {
    return (
      <div className="max-w-xl mx-auto px-4 sm:px-6 py-24 text-center">
        <div
          className="w-16 h-16 mx-auto mb-5 rounded-2xl flex items-center justify-center"
          style={{
            background: "var(--bg-elevated)",
            border: "1px solid var(--border)",
            color: "var(--text-subtle)",
          }}
        >
          <MagnifyingGlass size={24} weight="duotone" />
        </div>
        <h1 className="text-2xl font-bold mb-3" style={{ color: "var(--text)" }}>Tool not found</h1>
        <p className="mb-6 text-sm" style={{ color: "var(--text-muted)" }}>
          No tool with command{" "}
          <code
            className="font-mono px-1.5 py-0.5 rounded"
            style={{ background: "var(--bg-inset)", color: "var(--accent)" }}
          >
            {command}
          </code>{" "}
          exists in the registry.
        </p>
        <Link
          to="/tools"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border transition-all"
          style={{
            borderColor: "var(--border)",
            background: "var(--bg-elevated)",
            color: "var(--text)",
          }}
        >
          <ArrowLeft size={13} /> Back to all tools
        </Link>
      </div>
    );
  }

  const catMeta = CATEGORY_COLOR[tool.category];

  const relatedTools = tool.related.map((cmd) => TOOLS_BY_COMMAND[cmd]).filter(Boolean).slice(0, 3);
  const allRelated =
    relatedTools.length >= 2
      ? relatedTools
      : [
          ...relatedTools,
          ...TOOLS.filter(
            (t) =>
              t.category === tool.category &&
              t.command !== tool.command &&
              !tool.related.includes(t.command)
          ).slice(0, 3 - relatedTools.length),
        ].slice(0, 3);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <div className="flex gap-10">
        <div className="flex-1 min-w-0 max-w-3xl">
          {/* Breadcrumb */}
          <motion.nav
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.35 }}
            className="flex items-center gap-1.5 text-xs mb-8"
            style={{ color: "var(--text-subtle)" }}
          >
            <Link to="/" className="hover:text-[color:var(--text)] transition-colors">Docs</Link>
            <CaretRight size={11} />
            <Link to="/tools" className="hover:text-[color:var(--text)] transition-colors">Tools</Link>
            <CaretRight size={11} />
            <span style={{ color: "var(--text)" }}>{tool.name}</span>
          </motion.nav>

          <section id="overview" ref={(el) => { sectionRefs.current["overview"] = el; }}>
            <motion.div
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
              className="flex items-start gap-4 mb-6"
            >
              <div
                className="w-14 h-14 rounded-2xl flex items-center justify-center text-xl shrink-0 font-mono"
                style={{
                  background: `color-mix(in oklab, ${catMeta.color} 10%, transparent)`,
                  border: `1px solid color-mix(in oklab, ${catMeta.color} 25%, transparent)`,
                  color: catMeta.color,
                }}
              >
                {tool.icon}
              </div>
              <div>
                <div className="flex items-center gap-2 flex-wrap mb-1.5">
                  <h1 className="text-3xl font-bold" style={{ color: "var(--text)" }}>{tool.name}</h1>
                  <span
                    className="text-[10px] px-2 py-0.5 rounded-full font-mono uppercase tracking-wider inline-flex items-center gap-1"
                    style={{
                      background: `color-mix(in oklab, ${catMeta.color} 10%, transparent)`,
                      color: catMeta.color,
                      border: `1px solid color-mix(in oklab, ${catMeta.color} 20%, transparent)`,
                    }}
                  >
                    {catMeta.icon}
                    {tool.category}
                  </span>
                </div>
                <p className="leading-relaxed" style={{ color: "var(--text-muted)" }}>
                  {tool.description}
                </p>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.1 }}
              className="flex items-center gap-3 px-4 py-3 rounded-xl mb-10"
              style={{
                background: "var(--bg-inset)",
                border: "1px solid var(--border)",
              }}
            >
              <Terminal size={15} weight="duotone" style={{ color: "var(--accent)" }} />
              <code className="font-mono text-sm flex-1 truncate">
                <span style={{ color: "var(--text-subtle)" }}>$ </span>
                <span style={{ color: "var(--accent)" }}>bash main.sh </span>
                <span style={{ color: "var(--text)" }}>{tool.command}</span>
                <span style={{ color: "var(--text-subtle)" }}> [OPTIONS]</span>
              </code>
              <CopyButton text={`bash main.sh ${tool.command}`} />
            </motion.div>
          </section>

          <SectionHeader id="usage" ref={(el) => { sectionRefs.current["usage"] = el; }}>
            Usage
          </SectionHeader>
          <div className="mb-12">
            <CodeBlock
              code={`# Run through the hub (recommended)
bash main.sh ${tool.command} [OPTIONS]

# Run standalone
bash modules/_${tool.command}/_${tool.command}.sh [OPTIONS]

# If system-wide launcher is installed
utility ${tool.command} [OPTIONS]

# Show full flag reference
bash main.sh ${tool.command} --help`}
              language="bash"
              label={`${tool.command} — usage`}
            />
          </div>

          <SectionHeader id="options" ref={(el) => { sectionRefs.current["options"] = el; }}>
            Options
          </SectionHeader>
          <div className="mb-6">
            <div
              className="rounded-xl overflow-hidden"
              style={{
                background: "var(--bg-elevated)",
                border: "1px solid var(--border)",
              }}
            >
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    <th
                      className="px-4 py-3 text-left text-[10px] font-mono font-semibold uppercase tracking-widest w-56"
                      style={{ color: "var(--text-subtle)" }}
                    >
                      Flag
                    </th>
                    <th
                      className="px-4 py-3 text-left text-[10px] font-mono font-semibold uppercase tracking-widest"
                      style={{ color: "var(--text-subtle)" }}
                    >
                      Description
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {tool.options.map((opt, i) => (
                    <tr
                      key={i}
                      style={{
                        borderBottom: i < tool.options.length - 1 ? "1px solid var(--border)" : "none",
                      }}
                    >
                      <td className="px-4 py-3 align-top">
                        <code
                          className="text-xs font-mono px-1.5 py-0.5 rounded"
                          style={{
                            background: "color-mix(in oklab, #3b82f6 12%, transparent)",
                            color: "#60a5fa",
                          }}
                        >
                          {opt.flag}
                        </code>
                      </td>
                      <td
                        className="px-4 py-3 text-xs leading-relaxed align-top"
                        style={{ color: "var(--text-muted)" }}
                      >
                        {opt.description}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div
                className="px-4 py-3 border-t text-xs"
                style={{ borderColor: "var(--border)", color: "var(--text-subtle)" }}
              >
                Full flag reference:{" "}
                <code className="font-mono" style={{ color: "var(--text-muted)" }}>
                  bash main.sh {tool.command} --help
                </code>
              </div>
            </div>

            <div
              className="mt-4 px-4 py-3 rounded-lg text-xs flex items-start gap-2"
              style={{
                background: "var(--bg-inset)",
                border: "1px solid var(--border)",
                color: "var(--text-muted)",
              }}
            >
              <Warning size={14} weight="duotone" style={{ color: "var(--accent)", flexShrink: 0, marginTop: 2 }} />
              <div>
                <span className="font-semibold" style={{ color: "var(--text)" }}>Env vars: </span>
                <code
                  className="font-mono px-1 py-0.5 rounded"
                  style={{ background: "var(--bg-subtle)", color: "#f59e0b" }}
                >
                  NO_COLOR=1
                </code>{" "}
                strips ANSI,{" "}
                <code
                  className="font-mono px-1 py-0.5 rounded"
                  style={{ background: "var(--bg-subtle)", color: "#f59e0b" }}
                >
                  NO_UNICODE=1
                </code>{" "}
                falls back to plain ASCII. Both respected globally.
              </div>
            </div>
          </div>

          <SectionHeader id="examples" ref={(el) => { sectionRefs.current["examples"] = el; }}>
            Examples
          </SectionHeader>
          <div className="space-y-5 mb-12">
            {tool.examples.map((ex, i) => (
              <div key={i}>
                <div
                  className="text-xs mb-2 font-medium flex items-center gap-2"
                  style={{ color: "var(--text-muted)" }}
                >
                  <span
                    className="w-5 h-5 rounded-md flex items-center justify-center text-[10px] font-mono"
                    style={{
                      background: "var(--accent-subtle)",
                      color: "var(--accent)",
                    }}
                  >
                    {i + 1}
                  </span>
                  {ex.label}
                </div>
                <CodeBlock code={ex.code} label={`example ${i + 1}`} />
              </div>
            ))}
          </div>

          {allRelated.length > 0 && (
            <>
              <SectionHeader id="related" ref={(el) => { sectionRefs.current["related"] = el; }}>
                Related tools
              </SectionHeader>
              <div className="grid sm:grid-cols-3 gap-3 mb-10">
                {allRelated.map((related) => {
                  const rMeta = CATEGORY_COLOR[related.category];
                  return (
                    <Link
                      key={related.command}
                      to={`/tools/${related.command}`}
                      className="group flex flex-col gap-2 p-4 rounded-xl transition-all hover:-translate-y-0.5"
                      style={{
                        background: "var(--bg-elevated)",
                        border: "1px solid var(--border)",
                      }}
                    >
                      <div className="flex items-center gap-2">
                        <span
                          className="w-8 h-8 rounded-lg flex items-center justify-center text-sm font-mono"
                          style={{
                            background: `color-mix(in oklab, ${rMeta.color} 10%, transparent)`,
                            color: rMeta.color,
                            border: `1px solid color-mix(in oklab, ${rMeta.color} 20%, transparent)`,
                          }}
                        >
                          {related.icon}
                        </span>
                        <span
                          className="text-sm font-medium transition-colors"
                          style={{ color: "var(--text)" }}
                        >
                          {related.name}
                        </span>
                      </div>
                      <p className="text-xs leading-relaxed line-clamp-2" style={{ color: "var(--text-muted)" }}>
                        {related.description}
                      </p>
                      <code className="text-xs font-mono" style={{ color: "var(--text-subtle)" }}>
                        {related.command}
                      </code>
                    </Link>
                  );
                })}
              </div>
            </>
          )}

          <div
            className="border-t pt-6 flex justify-between gap-4"
            style={{ borderColor: "var(--border)" }}
          >
            <Link
              to="/tools"
              className="flex items-center gap-2 text-sm transition-colors"
              style={{ color: "var(--text-muted)" }}
            >
              <ArrowLeft size={13} /> All tools
            </Link>
            <Link
              to="/docs/getting-started"
              className="flex items-center gap-2 text-sm transition-colors"
              style={{ color: "var(--text-muted)" }}
            >
              Getting Started <ArrowRight size={13} />
            </Link>
          </div>
        </div>

        <aside className="hidden xl:block w-48 shrink-0">
          <div className="sticky top-24">
            <TableOfContents sections={TOC_SECTIONS} activeSection={activeSection} />
          </div>
        </aside>
      </div>
    </div>
  );
}

const SectionHeader = forwardRef<HTMLHeadingElement, { id: string; children: React.ReactNode }>(
  ({ id, children }, ref) => (
    <h2
      id={id}
      ref={ref}
      className="text-xl font-semibold mb-4 flex items-center gap-2.5 scroll-mt-24"
      style={{ color: "var(--text)" }}
    >
      <span
        className="w-1 h-5 rounded-full inline-block"
        style={{ background: "var(--accent)" }}
      />
      {children}
    </h2>
  )
);
SectionHeader.displayName = "SectionHeader";

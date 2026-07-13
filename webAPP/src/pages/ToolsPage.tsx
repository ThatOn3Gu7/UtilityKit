import { useState, useMemo, useRef } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  MagnifyingGlass,
  X,
  ArrowRight,
  Funnel,
  Package,
  Terminal,
  Cpu,
  ShieldCheck,
  Timer,
  ListChecks,
} from "@phosphor-icons/react";
import { TOOLS, CATEGORIES, CATEGORY_SLUGS, SLUG_TO_CATEGORY, type Category, type Tool } from "@/data/tools";

const CATEGORY_META: Record<Category, { icon: React.ReactNode; color: string }> = {
  "Core Suite": { icon: <Package size={14} weight="duotone" />, color: "#10b981" },
  "Developer Tools": { icon: <Terminal size={14} weight="duotone" />, color: "#3b82f6" },
  "System & Network": { icon: <Cpu size={14} weight="duotone" />, color: "#a855f7" },
  "Files & Security": { icon: <ShieldCheck size={14} weight="duotone" />, color: "#f43f5e" },
  Productivity: { icon: <Timer size={14} weight="duotone" />, color: "#f59e0b" },
};

function highlight(text: string, query: string): React.ReactNode {
  if (!query.trim()) return text;
  const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`, "gi");
  const parts = text.split(regex);
  return (
    <>
      {parts.map((part, i) =>
        regex.test(part) ? <mark key={i}>{part}</mark> : <span key={i}>{part}</span>
      )}
    </>
  );
}

function ToolCard({ tool, query, index }: { tool: Tool; query: string; index: number }) {
  const meta = CATEGORY_META[tool.category];
  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.35, delay: Math.min(index * 0.015, 0.3), ease: [0.22, 1, 0.36, 1] }}
    >
      <Link
        to={`/tools/${tool.command}`}
        className="group relative flex flex-col gap-3 p-5 rounded-2xl transition-all h-full overflow-hidden hover:-translate-y-1"
        style={{
          background: "var(--bg-elevated)",
          border: "1px solid var(--border)",
        }}
      >
        <div
          className="absolute -right-8 -top-8 w-20 h-20 rounded-full blur-2xl opacity-0 group-hover:opacity-40 transition-opacity"
          style={{ background: meta.color }}
        />
        <div className="relative flex items-start justify-between gap-2">
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center text-base shrink-0 font-mono"
            style={{
              background: `color-mix(in oklab, ${meta.color} 10%, transparent)`,
              color: meta.color,
              border: `1px solid color-mix(in oklab, ${meta.color} 20%, transparent)`,
            }}
          >
            {tool.icon}
          </div>
          <span
            className="text-[10px] px-2 py-0.5 rounded-full shrink-0 font-mono uppercase tracking-wider inline-flex items-center gap-1"
            style={{
              background: `color-mix(in oklab, ${meta.color} 10%, transparent)`,
              color: meta.color,
              border: `1px solid color-mix(in oklab, ${meta.color} 15%, transparent)`,
            }}
          >
            {meta.icon}
            {tool.category.split(" ")[0]}
          </span>
        </div>

        <div className="relative">
          <div className="flex items-center gap-2 mb-1.5 flex-wrap">
            <h3 className="font-semibold text-sm" style={{ color: "var(--text)" }}>
              {highlight(tool.name, query)}
            </h3>
            <code
              className="text-[11px] font-mono px-1.5 py-0.5 rounded"
              style={{
                background: "var(--bg-inset)",
                color: "var(--text-muted)",
                border: "1px solid var(--border)",
              }}
            >
              {highlight(tool.command, query)}
            </code>
          </div>
          <p className="text-xs leading-relaxed line-clamp-3" style={{ color: "var(--text-muted)" }}>
            {highlight(tool.description, query)}
          </p>
        </div>

        <div
          className="relative flex items-center gap-1 text-xs mt-auto transition-colors"
          style={{ color: "var(--text-subtle)" }}
        >
          <span className="group-hover:text-[color:var(--accent)] transition-colors">View docs</span>
          <ArrowRight
            size={11}
            className="transition-transform group-hover:translate-x-1 group-hover:text-[color:var(--accent)]"
          />
        </div>
      </Link>
    </motion.div>
  );
}

function CategoryBtn({ label, count, active, color, icon, onClick }: {
  label: string;
  count: number;
  active: boolean;
  color?: string;
  icon?: React.ReactNode;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center justify-between gap-2 px-3 py-2 rounded-lg text-sm transition-all text-left"
      style={{
        background: active ? "var(--accent-subtle)" : "transparent",
        color: active ? "var(--accent)" : "var(--text-muted)",
        border: `1px solid ${active ? "color-mix(in oklab, var(--accent) 30%, transparent)" : "transparent"}`,
      }}
    >
      <span className="flex items-center gap-2 truncate">
        <span style={{ color: active ? "var(--accent)" : color || "var(--text-subtle)" }}>{icon}</span>
        <span className="font-medium">{label}</span>
      </span>
      <span
        className="text-[10px] font-mono px-1.5 py-0.5 rounded shrink-0"
        style={{
          background: active ? "color-mix(in oklab, var(--accent) 20%, transparent)" : "var(--bg-subtle)",
          color: active ? "var(--accent)" : "var(--text-subtle)",
        }}
      >
        {count}
      </span>
    </button>
  );
}

export function ToolsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [mobileFilterOpen, setMobileFilterOpen] = useState(false);
  const searchRef = useRef<HTMLInputElement>(null);

  const categorySlug = searchParams.get("category") || "all";
  const query = searchParams.get("q") || "";

  const activeCategory: Category | null = SLUG_TO_CATEGORY[categorySlug] ?? null;

  const setCategory = (slug: string) => {
    const next = new URLSearchParams(searchParams);
    if (slug === "all") next.delete("category");
    else next.set("category", slug);
    setSearchParams(next);
    setMobileFilterOpen(false);
  };

  const setQuery = (q: string) => {
    const next = new URLSearchParams(searchParams);
    if (q) next.set("q", q);
    else next.delete("q");
    setSearchParams(next);
  };

  const clearFilters = () => {
    setSearchParams({});
    searchRef.current?.focus();
  };

  const filtered = useMemo(() => {
    let result = TOOLS;
    if (activeCategory) result = result.filter((t) => t.category === activeCategory);
    if (query.trim()) {
      const q = query.toLowerCase();
      result = result.filter(
        (t) =>
          t.name.toLowerCase().includes(q) ||
          t.command.toLowerCase().includes(q) ||
          t.description.toLowerCase().includes(q) ||
          t.category.toLowerCase().includes(q)
      );
    }
    return result;
  }, [activeCategory, query]);

  const categoryCounts = useMemo(
    () => Object.fromEntries(CATEGORIES.map((cat) => [cat, TOOLS.filter((t) => t.category === cat).length])),
    []
  );
  const filteredCounts = useMemo(
    () => Object.fromEntries(CATEGORIES.map((cat) => [cat, filtered.filter((t) => t.category === cat).length])),
    [filtered]
  );

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      {/* Page header */}
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-10"
      >
        <div
          className="inline-block text-[10px] font-mono uppercase tracking-widest mb-3 px-2 py-0.5 rounded"
          style={{ color: "var(--accent)", background: "var(--accent-subtle)" }}
        >
          REFERENCE
        </div>
        <h1 className="text-4xl sm:text-5xl font-bold tracking-tight mb-3" style={{ color: "var(--text)" }}>
          <span style={{ color: "var(--text)" }}>All </span>
          <span className="font-mono text-gradient-accent">{TOOLS.length}</span>
          <span style={{ color: "var(--text)" }}> tools</span>
        </h1>
        <p className="text-base max-w-xl" style={{ color: "var(--text-muted)" }}>
          Search by name, command, or description. Every card links to a full documentation page with options and examples.
        </p>
      </motion.div>

      {/* Search */}
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.1 }}
        className="mb-6 relative"
      >
        <div className="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: "var(--text-subtle)" }}>
          <MagnifyingGlass size={16} />
        </div>
        <input
          ref={searchRef}
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search by name, command, or description…"
          className="w-full pl-11 pr-11 py-3.5 rounded-xl outline-none text-sm transition-colors"
          style={{
            background: "var(--bg-elevated)",
            color: "var(--text)",
            border: "1px solid var(--border)",
          }}
        />
        {query && (
          <button
            onClick={() => setQuery("")}
            className="absolute right-3.5 top-1/2 -translate-y-1/2 w-6 h-6 rounded flex items-center justify-center transition-colors"
            style={{ color: "var(--text-subtle)" }}
            aria-label="Clear search"
          >
            <X size={14} />
          </button>
        )}
      </motion.div>

      {/* Mobile filter */}
      <button
        onClick={() => setMobileFilterOpen(!mobileFilterOpen)}
        className="lg:hidden flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm mb-4 border"
        style={{
          borderColor: "var(--border)",
          background: "var(--bg-elevated)",
          color: "var(--text-muted)",
        }}
      >
        <Funnel size={14} weight="duotone" />
        Filter by category
        {activeCategory && (
          <span
            className="ml-1 px-1.5 py-0.5 rounded text-xs"
            style={{ background: "var(--accent-subtle)", color: "var(--accent)" }}
          >
            {activeCategory}
          </span>
        )}
      </button>

      <div className="flex gap-6">
        {/* Sidebar */}
        <aside className={`${mobileFilterOpen ? "block" : "hidden"} lg:block w-full lg:w-60 shrink-0`}>
          <div
            className="lg:sticky lg:top-24 rounded-2xl overflow-hidden"
            style={{
              background: "var(--bg-elevated)",
              border: "1px solid var(--border)",
            }}
          >
            <div
              className="px-4 py-3 border-b flex items-center gap-2"
              style={{ borderColor: "var(--border)" }}
            >
              <ListChecks size={14} style={{ color: "var(--accent)" }} />
              <span
                className="text-[10px] font-mono uppercase tracking-widest"
                style={{ color: "var(--text-subtle)" }}
              >
                Categories
              </span>
            </div>
            <div className="p-2 space-y-0.5">
              <CategoryBtn
                label="All tools"
                count={TOOLS.length}
                active={categorySlug === "all"}
                icon={<Package size={14} weight="duotone" />}
                onClick={() => setCategory("all")}
              />
              {CATEGORIES.map((cat) => (
                <CategoryBtn
                  key={cat}
                  label={cat}
                  count={query ? filteredCounts[cat] : categoryCounts[cat]}
                  active={activeCategory === cat}
                  color={CATEGORY_META[cat].color}
                  icon={CATEGORY_META[cat].icon}
                  onClick={() => setCategory(CATEGORY_SLUGS[cat])}
                />
              ))}
            </div>

            {(activeCategory || query) && (
              <div className="p-2 border-t" style={{ borderColor: "var(--border)" }}>
                <button
                  onClick={clearFilters}
                  className="w-full text-center text-xs py-2 rounded-md transition-colors hover:bg-[var(--bg-subtle)]"
                  style={{ color: "var(--text-muted)" }}
                >
                  Clear all filters
                </button>
              </div>
            )}
          </div>
        </aside>

        {/* Main */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between mb-5">
            <div className="text-sm" style={{ color: "var(--text-muted)" }}>
              {filtered.length === TOOLS.length ? (
                <span>
                  All <span className="font-mono font-medium" style={{ color: "var(--text)" }}>{TOOLS.length}</span> tools
                </span>
              ) : (
                <span>
                  <span className="font-mono font-medium" style={{ color: "var(--text)" }}>{filtered.length}</span>
                  <span> of {TOOLS.length}</span>
                  {activeCategory && (
                    <> in <span style={{ color: "var(--accent)" }}>{activeCategory}</span></>
                  )}
                  {query && (
                    <> matching <span style={{ color: "var(--accent)" }}>"{query}"</span></>
                  )}
                </span>
              )}
            </div>
          </div>

          {filtered.length > 0 ? (
            <motion.div layout className="grid sm:grid-cols-2 xl:grid-cols-3 gap-4">
              <AnimatePresence mode="popLayout">
                {filtered.map((tool, i) => (
                  <ToolCard key={tool.command} tool={tool} query={query} index={i} />
                ))}
              </AnimatePresence>
            </motion.div>
          ) : (
            <div className="flex flex-col items-center justify-center py-24 text-center">
              <div
                className="w-16 h-16 rounded-2xl flex items-center justify-center mb-5"
                style={{
                  background: "var(--bg-elevated)",
                  border: "1px solid var(--border)",
                  color: "var(--text-subtle)",
                }}
              >
                <MagnifyingGlass size={24} weight="duotone" />
              </div>
              <h3 className="text-lg font-semibold mb-2" style={{ color: "var(--text)" }}>
                No tools found
              </h3>
              <p className="text-sm mb-6 max-w-xs" style={{ color: "var(--text-muted)" }}>
                Nothing matched{query && <> "<strong style={{ color: "var(--text)" }}>{query}</strong>"</>}
                {activeCategory && <> in {activeCategory}</>}. Try a different keyword.
              </p>
              <button
                onClick={clearFilters}
                className="px-4 py-2 rounded-lg text-sm font-medium transition-all border"
                style={{
                  borderColor: "var(--border)",
                  background: "var(--bg-elevated)",
                  color: "var(--text)",
                }}
              >
                Clear filters
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

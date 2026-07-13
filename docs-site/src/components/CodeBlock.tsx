import { useState } from "react";
import { motion } from "framer-motion";
import { Copy, Check } from "@phosphor-icons/react";

interface CodeBlockProps {
  code: string;
  language?: string;
  label?: string;
  className?: string;
}

const SYNTAX = {
  comment: "var(--syntax-comment)",
  cmd: "var(--syntax-cmd)",
  flag: "var(--syntax-flag)",
  str: "var(--syntax-str)",
  num: "var(--syntax-num)",
  text: "var(--terminal-text)",
};

function highlight(line: string): React.ReactNode {
  if (line.trim().startsWith("#")) {
    return <span style={{ color: SYNTAX.comment }}>{line}</span>;
  }
  const tokens: React.ReactNode[] = [];
  let rest = line;
  if (rest.startsWith("$ ")) {
    tokens.push(<span key="prompt" style={{ color: SYNTAX.comment }}>$ </span>);
    rest = rest.slice(2);
  }
  const cmdMatch = rest.match(/^(bash|git|utility|NO_COLOR|NO_UNICODE|cd|source|export)\b/);
  if (cmdMatch) {
    tokens.push(<span key="cmd" style={{ color: SYNTAX.cmd, fontWeight: 500 }}>{cmdMatch[0]}</span>);
    rest = rest.slice(cmdMatch[0].length);
  } else {
    const wordMatch = rest.match(/^(\S+)/);
    if (wordMatch) {
      tokens.push(<span key="word0" style={{ color: SYNTAX.cmd }}>{wordMatch[0]}</span>);
      rest = rest.slice(wordMatch[0].length);
    }
  }
  const remaining = rest
    .replace(/(--?\w[\w-]*)/g, "<FLAG>$1</FLAG>")
    .replace(/'([^']*)'/g, "<STR>'$1'</STR>")
    .replace(/"([^"]*)"/g, '<STR>"$1"</STR>');
  const parts = remaining.split(/(<FLAG>.*?<\/FLAG>|<STR>.*?<\/STR>)/);
  parts.forEach((part, i) => {
    if (part.startsWith("<FLAG>")) {
      tokens.push(<span key={i} style={{ color: SYNTAX.flag }}>{part.replace(/<\/?FLAG>/g, "")}</span>);
    } else if (part.startsWith("<STR>")) {
      tokens.push(<span key={i} style={{ color: SYNTAX.str }}>{part.replace(/<\/?STR>/g, "")}</span>);
    } else if (part) {
      tokens.push(<span key={i} style={{ color: SYNTAX.text }}>{part}</span>);
    }
  });
  return <>{tokens}</>;
}

async function copyText(text: string) {
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
}

function CopyIcon({ copied }: { copied: boolean }) {
  return (
    <motion.span
      key={copied ? "y" : "n"}
      initial={{ opacity: 0, scale: 0.7 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.15 }}
      className="flex items-center gap-1.5"
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
    </motion.span>
  );
}

export function CodeBlock({ code, language = "bash", label, className = "" }: CodeBlockProps) {
  const [copied, setCopied] = useState(false);
  const lines = code.split("\n");

  const handleCopy = async () => {
    await copyText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      className={`rounded-xl overflow-hidden ${className}`}
      style={{
        background: "var(--terminal-bg)",
        border: "1px solid var(--border)",
        boxShadow: "var(--shadow-md)",
      }}
    >
      <div
        className="flex items-center justify-between px-4 py-2.5 border-b"
        style={{ borderColor: "rgba(255,255,255,0.06)", background: "rgba(255,255,255,0.02)" }}
      >
        <div className="flex items-center gap-2.5">
          <div className="flex gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ff5f56" }} />
            <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ffbd2e" }} />
            <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#27c93f" }} />
          </div>
          <span className="text-xs font-mono ml-1" style={{ color: "#8b949e" }}>
            {label || language}
          </span>
        </div>
        <button
          onClick={handleCopy}
          className="text-xs px-2 py-1 rounded transition-colors"
          style={{
            color: copied ? "var(--accent)" : "#8b949e",
            background: copied ? "rgba(16,185,129,0.1)" : "transparent",
          }}
          aria-label="Copy"
        >
          <CopyIcon copied={copied} />
        </button>
      </div>
      <div className="overflow-x-auto">
        <pre className="px-4 py-4 text-[13px] font-mono leading-relaxed">
          {lines.map((line, i) => (
            <div key={i}>
              {highlight(line)}
              {i < lines.length - 1 ? "\n" : ""}
            </div>
          ))}
        </pre>
      </div>
    </div>
  );
}

interface TabbedCodeBlockProps {
  tabs: { label: string; code: string; language?: string }[];
}

export function TabbedCodeBlock({ tabs }: TabbedCodeBlockProps) {
  const [activeTab, setActiveTab] = useState(0);
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await copyText(tabs[activeTab].code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const lines = tabs[activeTab].code.split("\n");

  return (
    <div
      className="rounded-xl overflow-hidden"
      style={{
        background: "var(--terminal-bg)",
        border: "1px solid var(--border)",
        boxShadow: "var(--shadow-md)",
      }}
    >
      <div
        className="flex items-center justify-between border-b"
        style={{ borderColor: "rgba(255,255,255,0.06)", background: "rgba(255,255,255,0.02)" }}
      >
        <div className="flex overflow-x-auto">
          {tabs.map((tab, i) => (
            <button
              key={i}
              onClick={() => setActiveTab(i)}
              className="relative px-4 py-2.5 text-xs font-medium transition-colors whitespace-nowrap"
              style={{
                color: activeTab === i ? "var(--accent)" : "#8b949e",
              }}
            >
              {tab.label}
              {activeTab === i && (
                <motion.span
                  layoutId="code-tab-underline"
                  className="absolute bottom-0 left-3 right-3 h-0.5"
                  style={{ background: "var(--accent)" }}
                  transition={{ type: "spring", stiffness: 380, damping: 30 }}
                />
              )}
            </button>
          ))}
        </div>
        <button
          onClick={handleCopy}
          className="text-xs px-3 py-1.5 mr-2 rounded transition-colors shrink-0"
          style={{
            color: copied ? "var(--accent)" : "#8b949e",
            background: copied ? "rgba(16,185,129,0.1)" : "transparent",
          }}
        >
          <CopyIcon copied={copied} />
        </button>
      </div>
      <div className="overflow-x-auto">
        <pre className="px-4 py-4 text-[13px] font-mono leading-relaxed">
          {lines.map((line, i) => (
            <div key={i}>
              {highlight(line)}
              {i < lines.length - 1 ? "\n" : ""}
            </div>
          ))}
        </pre>
      </div>
    </div>
  );
}

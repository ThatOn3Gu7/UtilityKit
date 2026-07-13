import { motion, AnimatePresence } from "framer-motion";
import { Sun, Moon, Monitor } from "@phosphor-icons/react";
import { useTheme, type ThemeMode } from "./ThemeProvider";

const icons: Record<ThemeMode, React.ReactNode> = {
  light: <Sun size={16} weight="duotone" />,
  dark: <Moon size={16} weight="duotone" />,
  system: <Monitor size={16} weight="duotone" />,
};

const labels: Record<ThemeMode, string> = {
  light: "Light",
  dark: "Dark",
  system: "System",
};

export function ThemeToggle() {
  const { mode, cycle } = useTheme();

  return (
    <motion.button
      onClick={cycle}
      whileTap={{ scale: 0.92 }}
      whileHover={{ scale: 1.04 }}
      className="relative w-9 h-9 rounded-lg flex items-center justify-center overflow-hidden border transition-colors"
      style={{
        borderColor: "var(--border)",
        background: "var(--bg-elevated)",
        color: "var(--text-muted)",
      }}
      aria-label={`Theme: ${labels[mode]}. Click to cycle.`}
      title={`Theme: ${labels[mode]}`}
    >
      <AnimatePresence mode="wait" initial={false}>
        <motion.span
          key={mode}
          initial={{ y: 12, opacity: 0, rotate: -30 }}
          animate={{ y: 0, opacity: 1, rotate: 0 }}
          exit={{ y: -12, opacity: 0, rotate: 30 }}
          transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
          className="flex items-center justify-center"
        >
          {icons[mode]}
        </motion.span>
      </AnimatePresence>
    </motion.button>
  );
}

export function ThemeSegmented() {
  const { mode, setMode } = useTheme();
  const modes: ThemeMode[] = ["light", "system", "dark"];

  return (
    <div
      className="inline-flex items-center gap-0.5 p-1 rounded-lg border"
      style={{ borderColor: "var(--border)", background: "var(--bg-elevated)" }}
      role="radiogroup"
      aria-label="Theme"
    >
      {modes.map((m) => (
        <button
          key={m}
          onClick={() => setMode(m)}
          role="radio"
          aria-checked={mode === m}
          className="relative px-2.5 py-1 rounded-md text-xs font-medium transition-colors flex items-center gap-1.5"
          style={{
            color: mode === m ? "var(--text)" : "var(--text-subtle)",
          }}
        >
          {mode === m && (
            <motion.span
              layoutId="theme-pill"
              className="absolute inset-0 rounded-md"
              style={{ background: "var(--bg-subtle)", border: "1px solid var(--border)" }}
              transition={{ type: "spring", stiffness: 380, damping: 30 }}
            />
          )}
          <span className="relative flex items-center gap-1.5">
            {icons[m]}
            <span className="hidden sm:inline">{labels[m]}</span>
          </span>
        </button>
      ))}
    </div>
  );
}

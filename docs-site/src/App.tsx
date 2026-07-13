import { HashRouter, Routes, Route, Navigate, Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft, House } from "@phosphor-icons/react";
import { Layout } from "@/components/Layout";
import { ThemeProvider } from "@/components/ThemeProvider";
import { BackgroundCanvas } from "@/components/BackgroundCanvas";
import { HomePage } from "@/pages/HomePage";
import { ToolsPage } from "@/pages/ToolsPage";
import { ToolDetailPage } from "@/pages/ToolDetailPage";
import { GettingStartedPage } from "@/pages/GettingStartedPage";
import { ArchitecturePage } from "@/pages/ArchitecturePage";

export default function App() {
  return (
    <ThemeProvider>
      <BackgroundCanvas />
      <HashRouter>
        <Layout>
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/tools" element={<ToolsPage />} />
            <Route path="/tools/:command" element={<ToolDetailPage />} />
            <Route path="/docs/getting-started" element={<GettingStartedPage />} />
            <Route path="/docs/architecture" element={<ArchitecturePage />} />
            <Route path="/docs" element={<Navigate to="/docs/getting-started" replace />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Layout>
      </HashRouter>
    </ThemeProvider>
  );
}

function NotFound() {
  return (
    <div className="max-w-xl mx-auto px-4 sm:px-6 py-24 text-center relative">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
      >
        <div
          className="w-20 h-20 rounded-2xl flex items-center justify-center mb-8 mx-auto font-mono text-3xl"
          style={{
            background: "var(--bg-elevated)",
            border: "1px solid var(--border)",
            color: "var(--accent)",
            boxShadow: "var(--shadow-lg)",
          }}
        >
          404
        </div>
        <h1 className="text-3xl font-bold mb-3" style={{ color: "var(--text)" }}>
          Off the map
        </h1>
        <p className="text-sm mb-8" style={{ color: "var(--text-muted)" }}>
          This route isn't in the registry. Maybe you meant one of these?
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            to="/"
            className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-lg text-sm font-medium transition-all border hover:-translate-y-0.5"
            style={{
              borderColor: "var(--border)",
              background: "var(--bg-elevated)",
              color: "var(--text)",
            }}
          >
            <House size={14} weight="duotone" /> Home
          </Link>
          <Link
            to="/tools"
            className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-lg text-sm font-medium transition-all hover:-translate-y-0.5"
            style={{
              background: "var(--accent)",
              color: "var(--accent-fg)",
              boxShadow: "var(--shadow-glow)",
            }}
          >
            <ArrowLeft size={14} weight="bold" /> Browse tools
          </Link>
        </div>
      </motion.div>
    </div>
  );
}

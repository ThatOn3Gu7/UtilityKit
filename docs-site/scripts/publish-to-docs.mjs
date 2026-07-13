#!/usr/bin/env node
// publish-to-docs.mjs — Copy the built single-file bundle from
// docs-site/dist/index.html to the repository-level docs/index.html so that
// GitHub Pages (configured to serve /docs on the master branch) picks it up.
import { copyFileSync, existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const siteRoot = resolve(here, "..");
const repoRoot = resolve(siteRoot, "..");
const distFile = join(siteRoot, "dist", "index.html");
const docsDir = join(repoRoot, "docs");
const target = join(docsDir, "index.html");
const nojekyll = join(docsDir, ".nojekyll");

if (!existsSync(distFile)) {
  console.error(`[publish-to-docs] Missing ${distFile} — run \`npm run build\` first.`);
  process.exit(1);
}

if (!existsSync(docsDir)) {
  mkdirSync(docsDir, { recursive: true });
}

copyFileSync(distFile, target);

// Prevent Jekyll from interfering with the single-file bundle on GitHub Pages.
if (!existsSync(nojekyll)) writeFileSync(nojekyll, "");

const size = statSync(target).size;
const bytes = (size / 1024).toFixed(1);
const preview = readFileSync(target, "utf8").slice(0, 200).replace(/\s+/g, " ");
console.log(`[publish-to-docs] wrote ${target} (${bytes} kB)`);
console.log(`[publish-to-docs] head: ${preview}...`);

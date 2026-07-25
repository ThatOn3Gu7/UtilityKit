# UtilityKit Playground

Interactive tool catalog for the docs site. Every one of the 63 tools gets a card;
clicking one opens a terminal-styled player.

- **Live tools** (14): run for real in the browser (password gen, UUID/ULID gen,
  hashing via Web Crypto, regex tester, JSON/CSV/YAML tools, QR encoder, license
  generator, markdown TOC, pomodoro timer, todo list, secret scan).
- **Simulated tools** (49): scripted terminal playback — cosmetic only, no real
  logic, for tools that need filesystem/network/process access a browser can't
  provide (git, docker, ssh, disk, etc).

## Structure

```
src/
  data/registry.js       # every tool: id, cmd, name, desc, category, kind (real|sim)
  data/simScripts.js      # scripted output for every 'sim' tool
  components/              # TerminalShell (chrome), SimPlayer (playback engine), CopyButton
  tools/ToolPlayer.jsx     # dispatches a tool to its real component or SimPlayer
  tools/real/*.jsx         # actual working implementations
```

## Adding a new real tool

1. Build `src/tools/real/MyTool.jsx` using `TerminalShell` + `CopyButton` for consistent chrome.
2. Register it in `ToolPlayer.jsx`'s `REAL_COMPONENTS` map.
3. Flip its entry in `registry.js` from `kind: 'sim'` to `kind: 'real', component: 'MyTool'`.

## Dev

```bash
npm install
npm run dev       # http://localhost:5173
npm run build     # outputs to dist/
```

Drop `dist/` into your docs site, or mount this app under a route like `/playground`.

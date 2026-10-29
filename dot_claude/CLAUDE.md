# User profile

- Moises (moisesc@resorsi.com), IT/Product at Resorsi.
- Works across: Plane (pm.onpaice.com, tickets), GitHub (repos), Zoho CRM, Notion, Slack, EmailBison, DocuSeal.
- Stack: pnpm/bun/bunx, TypeScript, Astro, shadcn/ui, Payload CMS, SQLite, chezmoi for dotfiles.
- Sprint cadence: weekly. Uses `resorsi-tickets:sprint-kickoff`, `resorsi-tickets:my-sprint`, `resorsi-tickets:vics-scorecard`.

# Tone

- Write in plain English, full sentences.

## Explaining changes
After a code change, explain it in plain English for someone who didn't watch the work:
1. What changed, described as behavior ("the form now rejects empty emails"), not function names.
2. Why this approach, and what else was considered, if anything.
3. What I need to do or check next, if anything.
Define technical terms the first time they appear. 3–6 sentences. Skip this for typos and formatting.

## Challenge my decisions
- If my request or plan has a real problem (a simpler option exists, it risks production data or security, or it contradicts the code or a ticket), say so before starting, in 1–2 sentences, with what you checked.
- If you disagree, say what you'd do instead and why. One recommendation, not a menu.
- Don't change your position just because I push back. Change it when I give a new fact or argument, and say which one.
- Don't disagree for its own sake, and skip "great idea" / "you're right" openers. When my call is fine, just do it.
- Reversible choice: flag the concern, then go with my call. Irreversible or risky (prod DB, pushing to main, sharing a secret): stop and wait for my answer.

# Outward-facing content (Slack, GitHub PRs/issues/comments, email, PDFs, client docs)

- Always apply the `stop-slop` skill to any text leaving the machine — no need to be asked.
- Always show a draft and wait for approval before sending/posting anything external (Slack message, GitHub PR/issue/comment, email, DocuSeal). Local file edits and commits on branches don't need drafts.

# Workflow defaults

- Verification before completion: run typecheck/tests, paste output, then claim done.
- Prefer editing existing files over creating new ones.
- Don't write new docs/markdown unless asked.
- TDD when implementing features (per superpowers); skip for one-line bugfixes.
- For multi-step work: write a plan first, execute via `superpowers:executing-plans`.
- Don't ask clarifying questions for reversible local choices — state the assumption and proceed. Reserve questions for destructive actions and external sends.
- For long-running subagents, report what each agent is doing when spawning it and summarize its result when it finishes.
- Before starting a dev server, check if the project already runs on a port (`ss -ltnp`, then match the process cwd). If it does, reuse that URL — never start a second instance on another port. Need a restart (env/config change)? Ask first.
- n8n: read workflows with `n8n_get_workflow` mode `structure` first, then `filtered` with `nodeNames` for the nodes you need; `full` only when editing the whole graph. Executions: `mode: "preview"`/`"error"` before `full`.
- Waiting on deploys/CI/servers: `gh run watch --exit-status`, a backgrounded `until` loop, or the Monitor tool — not repeated `sleep N` calls.
- Bulk Gmail cleanup (more than ~20 threads): don't trash one thread per call. Propose a Gmail filter or a search query I can bulk-select in the Gmail UI.

# Performance and perceived speed

Speed is a feature. Anything user-facing should load fast and feel instant. Treat these as defaults when building or changing code, not as a reason to rewrite working code unasked.

## Build defaults
- Ship less JavaScript. Astro: static HTML first, islands only where interactivity is needed, laziest hydration that works (`client:visible` / `client:idle` over `client:load`). React/Next: server components by default, `"use client"` only at the leaves.
- React/Next: use React Compiler. If a project doesn't have it on, enable it (`reactCompiler: true` in `next.config`, or `babel-plugin-react-compiler` for Vite) and turn on the compiler lint rules from `eslint-plugin-react-hooks`. Don't write `useMemo`, `useCallback` or `React.memo` by hand; the compiler handles memoization. If a component gets skipped by the compiler, fix the rule violation instead of opting it out with `"use no memo"`.
- No request waterfalls: run independent fetches in parallel (`Promise.all`, parallel loaders). Fetch only the fields you render; paginate lists.
- Database: index columns used in filters, sorts and joins; avoid N+1 queries. Payload: set `depth` and `select` explicitly. SQLite: WAL mode.
- Cache what doesn't change per request (static generation, HTTP cache headers, memoized server calls), and say what invalidates it.
- Images: right size, AVIF/WebP, explicit width/height, lazy below the fold, `fetchpriority="high"` on the LCP image. Fonts: self-hosted, `font-display: swap`, preload only the above-the-fold one.
- Prefer platform features and small deps over heavy libraries. Before adding a dependency, check its bundle size and mention it if it's over ~20 KB gzipped.
- Code-split routes and heavy components (editors, charts, maps) with dynamic imports.

## UX that feels fast
- Every interaction gets visible feedback within 100 ms: pressed/pending states on buttons, optimistic updates for actions that almost always succeed (with rollback and an error message on failure).
- Skeletons shaped like the final content instead of spinners. Reserve space so nothing shifts when data arrives.
- Prefetch likely next pages (on hover or viewport). Use view transitions for navigation where supported.
- Search: filter local data instantly, debounce server queries (~250 ms), stream or progressively render long results.
- Load sections independently; one slow widget never blocks the whole page.
- Animations 150–250 ms, transform/opacity only, respect `prefers-reduced-motion`.

## Guardrails
- Don't trade correctness or readability for micro-optimizations. Measure before adding complexity (cache layers, memoization, web workers) and say what you measured.
- When a change touches page load or a hot path, report before/after numbers: bundle size, Core Web Vitals (targets: LCP < 2.5 s, INP < 200 ms, CLS < 0.1), or query time. Use the `web-perf` / `vercel-react-best-practices` skills and chrome-devtools performance traces where relevant.
- If you notice an existing slow spot outside the task, flag it in one line instead of fixing it unasked.

# Tooling preferences

- Typecheck: the project's `typecheck` script if it has one, else `pnpm tsc --noEmit`. dualhook, platform and whatsapp-ai-bot alias `tsc` to TypeScript 7 (tsgo); keep `typescript` itself on 5/6 for eslint/next/astro. Global `tsgo --noEmit` for ad-hoc checks. Astro projects: `astro check` (tsgo can't read .astro).
- Package mgmt: pnpm primary, bun for new things.
- GitHub (Resorsi-LLC org) via `gh`.
- For tickets: Plane (pm.onpaice.com) via `resorsi-tickets` plugin — `RES` project internal, `SAP` for Saphira. Always check duplicates before creating. (GitLab `resorsi-devs/tickets` retired 2026-08.)
- Dotfiles: chezmoi. Use `chezmoi diff` to inspect, `chezmoi apply` to deploy.
- If the task needs an MCP server that's disabled, disconnected or failing auth, stop and ask me to turn it on or fix it. Name the server and why it's needed. Don't work around it with raw API calls, scraped credentials or browser automation.

# Things to NOT do

- Don't use `git add -A` / `git add .` — stage files explicitly.
- Don't `--no-verify` on commits.
- Don't add error handling for impossible states.
- Don't add comments explaining WHAT — only non-obvious WHY.
- Don't widen permission patterns to arbitrary code execution.

# External references

- Sprint tickets: Plane (pm.onpaice.com) — `RES` + client projects
- Scorecard: Notion (current quarter page, weekly rows)
- CRM: Zoho — leads/contacts/deals modules, COQL for reads
- Cold outreach: EmailBison (fede + gbv accounts)
- Contracts: DocuSeal

# Design direction — Marcello portfolio polish

Evidence sources: UI/UX Pro Max (`Motion-Driven`, `Modern Dark Cinema`), Awwwards skill loop (direction before code). **Awwwards MCP tools are not mounted in this agent runtime**; no live `search_sites` / `create_design_brief` evidence. Claims below are **proposed** from those skills + the site’s existing brand.

## Preserve (observed brand)
- Palette: `#0b0d10` base, Swift orange `#fa7343`, Xcode blue `#4da3ff`, green `#63d38a`
- Type: Space Grotesk / Sora / JetBrains Mono
- Motif: editor chrome (file tabs, dots, JSON skills)

## Direction (proposed)
1. **Breath** — Soften or hide the background grid on small screens so type leads.
2. **One primary action** — Hero keeps one solid CTA (work) + one secondary (pricing); contact stays in nav.
3. **Motion with meaning** — Staggered section reveals and press/hover via `transform`/`opacity` only, `cubic-bezier(0.16,1,0.3,1)`, 200–400ms, `prefers-reduced-motion` respected.
4. **Atmosphere** — One quiet ambient accent wash (orange already present); avoid neon/cyberpunk drift.
5. **Pricing studio** — Keep interactive tabs; reduce chrome density on mobile (already partial).

## Out of scope this pass
- New font family, light mode, 3D/WebGL, full redesign of projects grid.

# DESIGN.md — Marcello Guida

## Brief (Phase 0)

- **Subject:** Marcello Guida — iOS developer & designer, Naples / Fisciano.
- **Audience:** recruiters, studios, clients looking for native apps and serious web craft.
- **Job of the site:** get hired / booked; show shipped apps and a clear listino.
- **Language:** IT + EN (existing toggle).
- **Assets:** profile photo, project covers (Echoes, Polly, SyncPoint, World of Fables), live project microsites.
- **Stack (reason):** stay on **Vite + React 19** — existing portfolio, GitHub Pages `docs/` deploy, bilingual pricing and SEO already wired. Port engine pieces (GSAP + Lenis), not Next/Astro.

### Assumptions (explicit)

- Open to new projects (badge / availability) remains true.
- Swift Student Challenge 2026 winner claim stays as provided by the owner.
- Pricing listino content stays; only presentation and motion change.
- Case “pages” for apps remain the existing project microsites under `/echoes/`, `/syncpoint/`, etc.

## Concept (Phase 1)

Three concepts scored Originality / Fit / Feasibility / Portability (lower portability better):

| | A. Silence → Signal | B. Gulf light | C. Build train |
|---|---|---|---|
| Territory | Material of winning work (Echoes / accessibility) | Place (Naples) | Process (ship) |
| Idea | The site rehearses finding a voice: hush, then one clear signal when work appears | Scroll cools Naples dawn into evening gulf light | Each project is a build that boards a shipping train |
| Anchor | Echoes + craft of interactions people feel | Lives and studies in Campania | Academy → WWDC → App Store path |
| Signature | Work index: hover floods a soft voice-field; caption bar rises with the project’s one-line intent; global `--signal` rises on scroll | Full-page color scrub | Numbered builds advance on scrub |
| O/F/Fe/P | 4 / 5 / 4 / 2 | 3 / 4 / 4 / 3 | 3 / 4 / 3 / 4 |

**Pick A.** Strongest fit to Marcello’s own work and voice; complete rule system for type, motion, idle, and 404. Steal from B for the footer: a small Naples coordinate strip.

### Concept Card

```
Idea:        The portfolio rehearses finding a voice — quiet fields, then one clear signal.
Metaphor:    A room going from hush to speech (Echoes).
Signature:   Work index with voice-field hover + rising caption bar; scroll drives --signal.
Emotion:     Attentive calm that suddenly feels clear.
Motion verb: rise like a voice
Screenshot:  Dark field, one project name lit, floating preview, caption strip typing intent.
```

**Genericness test:** Dropped Xcode window chrome as identity, equal feature cards, purple glow, cream/terracotta. Kept mono only for signal meters and rates. Changed hero from “code editor + accent word” to brand-led poster with full-bleed photo plane.

## Art direction (Phase 2)

### Palette

| Role | Hex | Note |
|---|---|---|
| ground | `#07080a` | Near-black hush |
| ink | `#f2f1ec` | Warm paper white (not cream editorial stack) |
| muted | `#8b909a` | AA on ground |
| line | `rgba(242,241,236,0.12)` | Hairlines |
| accent | `#e8ff6a` | Signal — acid chartreuse (voice, not Swift orange template) |
| curtain | `#050505` | Loader / transition |

Signal level (`--signal` 0→1) raises accent opacity and lifts ink slightly. Naples steal: footer meta uses muted gulf text, not a second accent.

### Type

- **Display:** Syne (Google) — wide, art-school, poster scale. Tracking −0.04em at display sizes.
- **Text / UI:** Manrope (Google) — clean humanist grotesk for body and nav.
- **Mono (data only):** IBM Plex Mono — signal %, rates, indexes.

Fluid scale: display `clamp(2.8rem, 9vw, 7.5rem)`; body 17px / 1.55.

### Grid & rhythm

- 12 columns, max 1240px, gutter `clamp(16px, 3vw, 32px)`.
- Alignment: left edge hard; display type optically hung −0.02em.
- Section rhythm alternates: sparse hero → compact about strip → tall work index → dense pricing studio → calm contact.

### Shape

- Radius rule: **2px** everywhere (almost sharp; signal is light, not soft UI).

### Motion language

- Ease family: expo.out / power3.out (`rise like a voice`).
- Hover 0.35s; text reveal 1.1s stagger 70ms; loader ≤ 2.2s.
- Idle: slow vertical drift of the voice-field gradient (`--signal` breathing ±0.03) paused off-screen and under `prefers-reduced-motion`.

### Composition plan (ASCII)

**Hero:** full-bleed photo plane | brand name huge left | one line | two CTAs | signal meter corner  
**About:** asymmetric 5/7 — facts column + greeting  
**Experience:** vertical timeline, no cards  
**Skills:** dense mono index, not icon grid  
**Work:** full-width index list + floating preview (signature)  
**Pricing:** keep studio interaction; restyle to signal tokens  
**Contact:** quiet field + rising underline links  
**404:** empty stage, “nessun segnale / no signal”

### Idle decision

Concept breathes via voice-field idle; if reduced motion, still page with static signal mark (written decision).

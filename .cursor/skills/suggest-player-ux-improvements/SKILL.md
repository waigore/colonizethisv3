---
name: suggest-player-ux-improvements
description: |-
  Scouts one player-facing UX domain (decision support, reports/feedback, playflow shortcuts,
  declutter/progressive disclosure, or self-explanatory clarity), checks whether needed game
  data already exists, and proposes exactly one clearly scoped improvement in chat—player-first,
  engineer-second—ready to decompose into one issue or a small dependency-aware issue set.
  Read-only; does not edit the repo or file GitHub issues.

  Use when the user asks for UI/UX streamlining ideas, player experience improvements, missing
  reports or feedback, playflow shortcuts, decision-support gaps, dense/cluttered panels,
  progressive disclosure, copy/labels that require the manual, or a focused UX opportunity
  from the player's seat.
---

# Suggest player UX improvements (ColonizeThis)

Read-only, chat only, **one domain**, **one improvement** (1–3 dependent issues max). Player first, engineer second. If the user asks to implement or file, stop and use that skill. [improve-ux-agent](../improve-ux-agent/SKILL.md) files autonomously and skips clarifications.

Conventions: [shared.md](../shared.md). Lenses: [references/player-lenses.md](references/player-lenses.md). Domain → SPEC/manual map: [references/sources.md](references/sources.md). **Every run:** read `SPEC/ui/ux-design-decisions.md` (`rejected` = hard non-goal; **P1** free-capacity reminders only).

## Workflow

### 1. Capture

Hinted domain/journey, lens preference, constraints, must-nots. If ambiguous **and** heuristics cannot lock a domain, ask **one** short clarification (interactive by design).

### 2. UX design decisions

`rejected` → do not recommend (or a rename). If the user named that topic, cite `UXD-NNN` and pick a different improvement. `accepted` including **P1**: remind unused capacity only when **using** it is free.

### 3. Lock one domain

| Domain id | Player intent | Typical IDs |
|-----------|---------------|-------------|
| `turn-shell` | End turn; what just happened | `GAME10001`, `DLG60001`, `DLG50001`, `OVL70001` |
| `map-province` | Act from map/tile/province | `MAP10001`, `MAP20001` |
| `civilian-work` | Explore, prospect, build, assign | `UNIT10001`, `UNIT40001` |
| `military-land` | Armies, invade, train land | `UNIT20001`, `UNIT50001`, `DLG20001` |
| `naval` | Fleets, missions, train ships | `UNIT30001`, `UNIT60001`, `DLG30001`, `DLG40001` |
| `economy-production` | Labour, stockpiles, production | `GAME20001`, `PROD20001` |
| `trade` | World market | `GAME60001` |
| `diplomacy` | Relations, treaties, aid | `GAME30001`, `GAME30002`, `DIPL20001` |
| `research` | Tech slots and funding | `GAME40001` |
| `victory-progress` | How close to win | victory overlay, HUD |

Heuristics (stop at first win): user-named → high-frequency multi-hop in `docs/manual/16-appendix-actions.md` → decision without data at commit → post-resolution blindness → incomplete sibling shortcuts → idle/readiness under **P1** → dense default surface → manual-dependent labels → default `turn-shell` (excluding rejected shell checklists).

Lock in writing (domain, in/out of scope, why). If two domains tie, prefer the smaller surface **or** ask the user to choose.

### 4–6. Player model, UI inventory, journeys

Within the lock: matching manual chapters + GDD; 2–4 “effective play” bullets (do not invent rules). Inventory in-scope screens (entry, decisions, primary vs secondary data, feedback, shortcuts, density, clarity). Walk lenses; 3–8 journey rows tagged `decision|shortcut|report|feedback|declutter|clarity`. Manual is the analyst answer key, not the product fix.

### 7. Data availability (required)

Available in model / via existing UI API / Derivable / Resolver-only / Missing. Search models, domain logic, turn-event SPECs, `app/lib/features/game/` providers. Prefer Available/Derivable; else expose-existing-data slice or SPEC+UI paired set.

### 8. De-duplicate

Re-check `ux-design-decisions.md`. Skim open issues if `gh` works. Same improvement already open → cite it and pick the next-best gap in **this** domain.

### 9. Pick one

Highest player impact, issue-ready, decomposable, feasible, reuse existing chrome. Declutter must name always-visible vs on-request. Clarity: default-visible facts pass the no-manual check.

Reject: `rejected` UXDs, P1-violating nags, visual polish, ctdev, multi-domain epics, laundry lists, more numbers with no hierarchy, “read the manual” as the fix.

At most two runner-up titles (one line each). Do not list rejected decisions as runner-ups.

### 10. Chat brief (mandatory)

```markdown
## Domain lock
- **Domain:** …
- **In scope / out of scope / why:** …

## Player recommendation (the one improvement)
### Title
<imperative, ≤~80 chars>
### Player problem
…
### Player outcome
…
### Current path
- Intent / steps today (IDs, hops) / missing or painful
### Proposed experience
- **Default (always visible):** …
- **On request:** … how the player opens them
- **Clarity:** …
### Why this advances their cause
…
### Non-goals
- …

## Evidence
- UX design decisions: <P1 / UXD-NNN / none>
- Manual / GDD / UI specs / code

## Data availability
| Need | Status | Where / notes |
|------|--------|----------------|
| … | Available / Derivable / Resolver-only / Missing | … |

## Engineer direction
### Summary
…
### Suggested issue decomposition
- **Issue A** — … *(depends on: —)* Draft ACs: Given … When … Then …
### SPEC impact
- none | UI | program | GDD | manual — paths
### Touch points
- screens, bus/providers, models; follow-up skills `plan-feature` / `create-github-issue` → `implement-github-issue` → `document-app-ui` / `update-game-manual` as needed
### Risks
- …

## Runner-ups (not this run)
- …

## Next step for the user
Chat-only complete. Ask to **plan-feature** / **file an issue** for “<Title>”, or run this skill again on another domain.
```

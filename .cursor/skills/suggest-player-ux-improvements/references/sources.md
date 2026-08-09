# Domain → sources map

Pointers for `suggest-player-ux-improvements`. Always re-read current files; this map is a starting index, not a substitute for SPEC.

## Global entry points

| Resource | Path |
|----------|------|
| **UX design decisions (required every run)** | `SPEC/ui/ux-design-decisions.md` — **P1** free-vs-costly capacity; `rejected` UXD rows = hard non-goals |
| Screen registry | `SPEC/ui/screen-registry.md` |
| Screen IDs in code | `app/lib/config/ui_screen_ids.dart` |
| Actions appendix (decree → UI entry → result phase) | `docs/manual/16-appendix-actions.md` |
| Turn loop (player) | `docs/manual/14-passage-of-turns.md` |
| UI wiring / bus | `SPEC/program/app-ui-wiring.md`, `SPEC/program/app-event-bus.md` |
| Mobile constraints | `SPEC/ui/mobile-adaptation.md` |

## Domain map

| Domain id | Manual | GDD (start here) | UI surfaces (registry titles) |
|-----------|--------|------------------|-------------------------------|
| `turn-shell` | `14-passage-of-turns.md` | `turn-time-mapping.md`, victory hooks in `victory.md` | Game screen, Next turn confirmation, Turn news, Player turn event feed, Pause menu |
| `map-province` | `03-the-lay-of-the-land.md`, `04-charting-the-unknown.md` | `world-model.md`, `fog-and-exploration.md`, `map-topology.md`, `tile-map-and-generation.md` | Empire overview / map, Province sea-zone overlay, Game side menu |
| `civilian-work` | `04`, `05-people-and-prosperity.md`, `06-bounty-of-the-earth.md` | `civilian-units.md`, `extraction-and-improvements.md`, `workers-and-population.md` | Civilian units panel, Train civilians, province overlay shortcuts |
| `military-land` | `11-raising-the-banners.md`, `12-art-of-war.md` | `military-units.md`, `military-armies.md`, `combat.md`, `quick-battle.md`, `siege-mechanics.md` | Military units panel, Train military, Move army, combat/quick battle surfaces |
| `naval` | `13-mastery-of-the-seas.md` | `ships-and-naval.md` | Naval units panel, Train naval, Move fleet, Transfer home fleet |
| `economy-production` | `05`, `06`, `07-engines-of-industry.md` | `stockpiles-and-production.md`, `production-recipes.md`, `commodity-catalog.md`, `workers-and-population.md` | Production screen, commodity breakdown dialog |
| `trade` | `08-commerce-and-the-world-market.md` | `world-market.md`, `world-market-first-right-of-refusal.md` | Trade screen |
| `diplomacy` | `10-diplomacy.md` | `diplomacy.md`, `factions.md`, tech-tree diplomacy bits | Diplomacy screen/detail, grant/subsidy, overture/call-to-arms/intervention overlays |
| `research` | `09-pursuit-of-knowledge.md` | `research-state.md`, `tech-tree*.md` | Technology screen |
| `victory-progress` | `15-road-to-victory.md` | `victory.md` | Victory overlay; any HUD/progress surfaces |

## Data availability search tips

| Question | Where to look |
|----------|----------------|
| Is the field on the save/world model? | `packages/colonizethis_models/`, `SPEC/game/world-model.md` |
| Is validation already producing a reason string? | Order validators under `packages/colonizethis_logic/`, order suggestion SPEC |
| Does turn resolution already emit an event the UI could show? | `SPEC/program/turn-resolution*.md`, turn news / event feed specs and builders |
| Does another screen already compute it? | Sibling feature under `app/lib/features/game/` |
| Would exposing it change rules? | If yes → GDD/SPEC impact, not “UI-only” |
| Is there already a **details / breakdown** pattern to reuse? | e.g. `PROD20001` commodity breakdown, tabbed province overlay sections, train dialogs vs full panels |
| What plain language should the UI convey? | Matching `docs/manual/` chapter Purpose / How it is done — as **meaning**, not as a player-required reading step |

## Density / clarity hotspots (start here when heuristics 7–8 fire)

These surfaces often pack many facts; audit primary vs secondary carefully:

- `MAP20001` province/sea overlay (many tabs/sections)
- `GAME20001` / `PROD20001` production and commodity breakdown
- `GAME60001` trade market + deal book
- Unit panels (`UNIT*`) with status, location, costs, actions
- Diplomacy detail (`GAME30002`) and multi-action rows

## Out of scope for this skill’s recommendations

- Anything listed under a **`rejected`** decision in `SPEC/ui/ux-design-decisions.md` (currently includes **UXD-001**: end-turn unused research capacity warnings)
- Pre-commit nags for **costly** unused capacity that violate **P1** (remind only when using the capacity is free—e.g. spies; not research funding)
- `SYS*` debug surfaces
- ctdev-only tools (`SPEC/program/ctdev-app.md`)
- Pure asset/style work (`colonizethis-ui-design.mdc`, pixel catalog)

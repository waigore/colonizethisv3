# Domain → sources map

Starting index for `suggest-player-ux-improvements`. Re-read current files. Product non-goals: `SPEC/ui/ux-design-decisions.md`.

## Global

| Resource | Path |
|----------|------|
| UX design decisions | `SPEC/ui/ux-design-decisions.md` |
| Screen registry / IDs | `SPEC/ui/screen-registry.md`, `app/lib/config/ui_screen_ids.dart` |
| Actions appendix | `docs/manual/16-appendix-actions.md` |
| Turn loop | `docs/manual/14-passage-of-turns.md` |
| UI wiring / bus | `SPEC/program/app-ui-wiring.md`, `SPEC/program/app-event-bus.md` |
| Mobile | `SPEC/ui/mobile-adaptation.md` |

## Domain map

| Domain id | Manual | GDD (start here) | UI surfaces |
|-----------|--------|------------------|-------------|
| `turn-shell` | `14-passage-of-turns.md` | `turn-time-mapping.md`, `victory.md` | Game screen, Next turn confirmation, Turn news, event feed, Pause menu |
| `map-province` | `03-the-lay-of-the-land.md`, `04-charting-the-unknown.md` | `world-model.md`, `fog-and-exploration.md`, `map-topology.md`, `tile-map-and-generation.md` | Empire map, Province overlay, Game side menu |
| `civilian-work` | `04`, `05-people-and-prosperity.md`, `06-bounty-of-the-earth.md` | `civilian-units.md`, `extraction-and-improvements.md`, `workers-and-population.md` | Civilian units, Train civilians, overlay shortcuts |
| `military-land` | `11-raising-the-banners.md`, `12-art-of-war.md` | `military-units.md`, `military-armies.md`, `combat.md`, `quick-battle.md`, `siege-mechanics.md` | Military units, Train military, Move army, combat |
| `naval` | `13-mastery-of-the-seas.md` | `ships-and-naval.md` | Naval units, Train naval, Move fleet, Transfer home fleet |
| `economy-production` | `05`, `06`, `07-engines-of-industry.md` | `stockpiles-and-production.md`, `production-recipes.md`, `commodity-catalog.md` | Production, commodity breakdown |
| `trade` | `08-commerce-and-the-world-market.md` | `world-market.md`, `world-market-first-right-of-refusal.md` | Trade screen |
| `diplomacy` | `10-diplomacy.md` | `diplomacy.md`, `factions.md` | Diplomacy screen/detail, grant/subsidy, overture overlays |
| `research` | `09-pursuit-of-knowledge.md` | `research-state.md`, `tech-tree*.md` | Technology screen |
| `victory-progress` | `15-road-to-victory.md` | `victory.md` | Victory overlay; HUD/progress |

## Where to look for data

| Question | Where |
|----------|--------|
| Field on save/world? | `packages/colonizethis_models/`, `SPEC/game/world-model.md` |
| Validation reason string? | `packages/colonizethis_logic/` validators, order-suggestion SPEC |
| Turn event the UI could show? | `SPEC/program/turn-resolution*.md`, turn news / event feed |
| Already computed on another screen? | `app/lib/features/game/` |
| Would exposing it change rules? | If yes → GDD/SPEC impact |
| Existing details pattern? | `PROD20001`, tabbed province overlay, train dialogs |
| Plain language? | Matching `docs/manual/` Purpose / How it is done — as **meaning**, not required reading |

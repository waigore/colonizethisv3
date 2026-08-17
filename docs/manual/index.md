# ColonizeThis — Player Game Manual

Welcome, my liege. This handbook is your national adviser: it immerses you in the age of discovery, guides you patiently toward imperial glory, and catalogs every decree you may issue in play.

The manual is **player-facing documentation**. Game Design Documents under `SPEC/game/`, technical specs under `SPEC/program/`, UI specs under `SPEC/ui/`, and AI specs under `SPEC/ai/` remain the sole sources of truth for behavior. If this manual and a SPEC disagree, the manual is wrong and must be corrected.

## How to use this manual

1. Start with **A Young Monarch's Primer** for the premise, victory at a glance, and the game screen.
2. Follow chapters in order for a campaign-shaped tour, or jump via the table of contents to a system you need.
3. Use the **Appendix: The Royal Decrees** as a quick-reference for every order and immediate action.
4. Screen surfaces are cited by stable **8-character screen IDs** (e.g. `GAME20001`) so renames in the UI do not break references. See `SPEC/ui/screen-registry.md`.
5. Surfaces marked **`[DRAFT]`** (per `STYLE_GUIDE.md`) are not yet playable as described; omit them from operable how-to steps. The chapters below cite only active player surfaces; remaining registry drafts are debug/observe tools and stay out of this handbook.

## Tone

Body prose is everyday modern English a **12th-grade reader** can follow. UI-engineering words and genre jargon are banned. The framing is a **vizier advising a young monarch**: patient, empathetic, encouraging. Archaic 16th–17th century flourishes (“Hark, my liege…”) appear only in exhortation, warning, or instruction **callouts** — not in ordinary how-to steps.

Full tone, reading level, chapter template, Sources footers, and draft-marking rules: [`STYLE_GUIDE.md`](STYLE_GUIDE.md).

## Table of contents

| # | Chapter | File |
|---|---------|------|
| 1 | A Young Monarch's Primer | [`01-primer.md`](01-primer.md) |
| 2 | Founding Your Reign | [`02-founding-your-reign.md`](02-founding-your-reign.md) |
| 3 | The Lay of the Land | [`03-the-lay-of-the-land.md`](03-the-lay-of-the-land.md) |
| 4 | Charting the Unknown | [`04-charting-the-unknown.md`](04-charting-the-unknown.md) |
| 5 | People and Prosperity | [`05-people-and-prosperity.md`](05-people-and-prosperity.md) |
| 6 | Bounty of the Earth | [`06-bounty-of-the-earth.md`](06-bounty-of-the-earth.md) |
| 7 | The Engines of Industry | [`07-engines-of-industry.md`](07-engines-of-industry.md) |
| 8 | Commerce and the World Market | [`08-commerce-and-the-world-market.md`](08-commerce-and-the-world-market.md) |
| 9 | The Pursuit of Knowledge | [`09-pursuit-of-knowledge.md`](09-pursuit-of-knowledge.md) |
| 10 | Diplomacy and Courtly Affairs | [`10-diplomacy.md`](10-diplomacy.md) |
| 11 | Raising the Banners | [`11-raising-the-banners.md`](11-raising-the-banners.md) |
| 12 | The Art of War | [`12-art-of-war.md`](12-art-of-war.md) |
| 13 | Mastery of the Seas | [`13-mastery-of-the-seas.md`](13-mastery-of-the-seas.md) |
| 14 | The Passage of Turns | [`14-passage-of-turns.md`](14-passage-of-turns.md) |
| 15 | The Road to Victory | [`15-road-to-victory.md`](15-road-to-victory.md) |
| 16 | Appendix: The Royal Decrees | [`16-appendix-actions.md`](16-appendix-actions.md) |

### Coverage map (authoring)

| # | Must document (low-level) | Primary sources |
|---|---------------------------|-----------------|
| 1 | Premise (1500–1850, Old & New Worlds, Great Powers / Minor Nations / Tribes); victory at a glance; turn rhythm; orientation tour of game screen, empire buttons, side menu, map | `SPEC/game/victory.md`, `SPEC/game/turn-time-mapping.md`, `SPEC/game/factions.md`; `SPEC/ui/game-screen.md`, `SPEC/ui/empire-buttons.md`, `SPEC/ui/game-side-menu.md`, `SPEC/ui/map-widget.md`, `SPEC/ui/empire-overview.md`, `SPEC/ui/screen-registry.md`, `SPEC/ui/tile-context-radial.md`, `SPEC/ui/tile-more-actions-dialog.md`; `SPEC/ai/ai-personalities.md` |
| 2 | Main menu → Quick Start (default campaign) or New Game → leader selection; human/AI GP slots; leader bonuses; advanced starts; capital auto-choice; game-start intro overlay | `SPEC/game/game-setup.md`, `SPEC/game/factions.md`, `SPEC/game/leader-bonuses.md`, `SPEC/game/advanced-starts.md`, `SPEC/game/capital-choice-phase.md`, `SPEC/game/naming.md`; `SPEC/ui/main-menu.md`, `SPEC/ui/new-game-leader-selection-dialog.md`, `SPEC/ui/game-initializing.md`, `SPEC/ui/game-start-intro-overlay.md` |
| 3 | Reading the map; provinces and sea zones; terrain and resources; capital and connectivity; province overlay and town/port icons; province identity as the UI names places; tile action ring | `SPEC/game/world-model.md`, `SPEC/game/map-topology.md`, `SPEC/game/tile-map-and-generation.md`, `SPEC/game/resource-terrain-region-rules.md`, `SPEC/game/capital-and-connectivity.md`; `SPEC/ui/map-widget.md`, `SPEC/ui/empire-overview.md`, `SPEC/ui/province-sea-zone-detail-overlay.md`, `SPEC/ui/tile-context-radial.md`, `SPEC/ui/tile-more-actions-dialog.md`, `SPEC/ui/layered-terrain-rendering.md`, `SPEC/ui/town-port-icons.md` |
| 4 | Fog levels; Explorer work (`explore`, `prospect`); fleets into new sea zones; tribe first contact; where discoveries are reported | `SPEC/game/fog-and-exploration.md`; `SPEC/ui/tribe-first-contact-overlay.md`, `SPEC/ui/player-turn-event-feed.md`, map rendering specs |
| 5 | Population and worker tiers; Recruit/Train; disband; civilian roster via civilians panel and train dialog | `SPEC/game/workers-and-population.md`, `SPEC/game/civilian-units.md`; `SPEC/ui/civilian-units-panel.md`, `SPEC/ui/train-civilians-dialog.md` |
| 6 | Civilian work targets; costs; one work order per unit per turn; exclusivity; cancel in-progress work; extraction caps | `SPEC/game/extraction-and-improvements.md`, `SPEC/game/tech-and-extraction-cap.md`, `SPEC/program/orders.md` § WorkOrder; related UI |
| 7 | Shared warehouse; recipes; Production screen, Breakdown, Industry Counsel; sellable Available headroom | `SPEC/game/stockpiles-and-production.md`, `SPEC/game/production-recipes.md`, `SPEC/game/commodity-catalog.md`, `SPEC/game/workers-and-population.md`, `SPEC/game/tech-tree-new-world.md`; `SPEC/ui/production-panel.md`, `SPEC/ui/production-commodity-breakdown-dialog.md`, `SPEC/ui/counsel-panel.md`, `SPEC/ui/empire-buttons.md`; `SPEC/program/industry-counsel-ranking.md` |
| 8 | Bids and offers; caps; first right of refusal; Phase 13 results; operable Trade screen (Market + Deal Book) | `SPEC/game/world-market.md`, `SPEC/game/world-market-first-right-of-refusal.md`, `SPEC/program/orders.md` § TradeOrder; `SPEC/ui/trade-screen.md` |
| 9 | Research slots and funding; prerequisites; Tree category colours/icons; University slot bonus | `SPEC/game/tech-tree.md` (+ subtrees), `SPEC/game/research-state.md`, `SPEC/program/orders.md` § ResearchOrder; `SPEC/ui/technology-panel.md`, `SPEC/ui/tech-tree-widget.md` |
| 10 | Printed diplomacy decrees; overtures; Join Empire; grants/subsidies; Relative power; Intelligence Council | `SPEC/game/diplomacy.md`, `SPEC/game/victory.md`, `SPEC/program/orders.md` § DiplomaticOrder; diplomacy UI; `SPEC/ai/diplomacy-planner.md`, `SPEC/ai/dialogue-and-mood.md`, `SPEC/ai/hidden-agendas.md`, `SPEC/ai/ai-dossier.md` |
| 11 | Military roster; training; armies and generals; Move Army dialog; Home Army constraint | `SPEC/game/military-units.md`, `SPEC/game/military-armies.md`, `SPEC/game/military-generals.md`, `SPEC/program/orders.md`; military UI |
| 12 | Attacking; combat mode choice; quick battle; siege; reading outcomes | `SPEC/game/combat.md`, `SPEC/game/quick-battle.md`, `SPEC/game/siege-mechanics.md`; combat UI |
| 13 | Ships; fleets; missions; home fleet constraint; naval combat | `SPEC/game/ships-and-naval.md`, `SPEC/program/orders.md`; naval UI |
| 14 | Ending the turn; next-turn confirmation; resolution timing (player-facing); turn news; player turn event feed; save/load; pause; settings | `SPEC/game/turn-time-mapping.md`, `SPEC/program/turn-resolution-phases.md`; related UI |
| 15 | Military victory (31+ OW provinces); calendar cap; power-score declared winner; infinite mode; victory overlay; endgame counsel | `SPEC/game/victory.md`, `SPEC/game/turn-time-mapping.md`, `SPEC/game/diplomacy.md`; `SPEC/ui/victory-overlay.md`; AI growth/personality specs |
| 16 | Exhaustive action table: every order type/subtype and immediate action with UI entry, validation, phase, chapter link | `SPEC/program/orders.md`, `SPEC/program/order-engine.md`, `SPEC/program/turn-resolution-phase-details.md` |

## Chapter status

| File | Status |
|------|--------|
| `01-primer.md` | Present (S4) |
| `02-founding-your-reign.md` | Present (S4) |
| `03-the-lay-of-the-land.md` | Present (S4) |
| `04-charting-the-unknown.md` | Present (S5) |
| `05-people-and-prosperity.md` | Present (S5) |
| `06-bounty-of-the-earth.md` | Present (S5) |
| `07-engines-of-industry.md` | Present (S6) |
| `08-commerce-and-the-world-market.md` | Present (S6) |
| `09-pursuit-of-knowledge.md` | Present (S6) |
| `10-diplomacy.md` | Present (S7) |
| `11-raising-the-banners.md` | Present (S7) |
| `12-art-of-war.md` | Present (S7) |
| `13-mastery-of-the-seas.md` | Present (S7) |
| `14-passage-of-turns.md` | Present (S8) |
| `15-road-to-victory.md` | Present (S8) |
| `16-appendix-actions.md` | Present (S9) |
| S10 completeness audit | Done (player-manual screen IDs active; draft convention retained for future / non-manual surfaces) |

## Related process artifacts

- Style guide and chapter template: [`STYLE_GUIDE.md`](STYLE_GUIDE.md)
- Cursor rule: `.cursor/rules/colonizethis-game-manual.mdc`
- Updater skill: `.cursor/skills/update-game-manual/SKILL.md`
- Review skill: `.cursor/skills/review-game-manual-agent/SKILL.md`

# Charting the Unknown

## Purpose

Fog hides opportunity and danger alike. Your Explorers and fleets push back ignorance: provinces become walkable and workable, minerals appear under the ground, and Tribes announce themselves when your eyes first fall on their land. This chapter teaches visibility, exploration and prospecting work, naval revelation of coasts, and where discoveries are reported after the turn.

## How it is done

### Visibility levels

Each tile you care about sits in one of three intel states for your court (ordered from least to most useful):

| Level | What you know |
|-------|----------------|
| **Unknown** | No usable intel; you cannot explore or prospect there yet. New World land and sea start here for Great Powers. |
| **Fogged** | Terrain and non-prospect resources; last-known improvements of others. Old World provinces you do not own start fogged. |
| **Fully visible** | Full local detail except minerals that still need prospecting. **Your own provinces stay fully visible** and never decay. |

Political ownership on the map remains authoritative even when a province is fogged — fog hides detail, not who holds the claim.

**Setup defaults:** Old World fogged (owned tiles fully visible); New World unknown. Sea zones adjacent to coasts you **fully own** become fully visible at setup and again each end of turn.

### Bootstrap prospecting (advanced start)

**turns50** and **turns100** presets run a **setup-only** prospecting pass on **owned** provinces before the first Orders phase — separate from Explorer **prospect** work below. Setup marks a tier fraction of prospect-required minerals in your combined owned pool (50% OW-only at 50-turn; 75% OW+NW after 100-turn colonization). Minor OW minerals receive the same fraction and are recorded in buyer Great Power prospected sets.

That bootstrap step is **not** NW flood-fill **reveal** and **not** in-game Explorer labor. Chapter 2 **Founding Your Reign** documents tier fractions, OW vs NW scope, and the prospect-before-development bootstrap order.

### Explorer work: explore and prospect

Use `UNIT10001` **Civilian units panel** (or tile shortcuts on `MAP20001` **Province / sea-zone detail overlay**) with an **Explorer**:

1. Select the Explorer and choose **explore** or **prospect** (or the overlay’s Explore / Prospect shortcuts when eligible).
2. For **explore**, pick a land tile in a province that is **partially revealed**: at least one land tile fogged or fully visible **and** at least one land tile still unknown. The work is **free**. Duration scales with province size: up to **three** turns (`ceil(3 × tilesInProvince / maxTilesInRegion)`). On completion in **Build/work**, every tile in that province becomes fully visible **for you**.
3. For **prospect**, pick a **mineral-eligible** tile (swamp, hills, mountain, or desert) that is at least fogged. The work is **free** and lasts **one** turn; the tile joins your prospected set only when work **completes**. Prospect-required minerals (iron, copper, tin, coal, silver, gold, gems, diamonds) stay hidden until then. Terrain-known commodities (grain, meat, wool, horses, timber, sugar cane, tobacco, cotton, furs, spices) do not need prospecting.
4. Exploring or prospecting in **Minor Nation** or **Tribe** provinces requires a **Consulate or higher** with that owner. Without it, open Political on `MAP20001` and choose **Establish Consulate**. Confirm the stated cost and effect to stage the diplomatic decree; **Cancel** withdraws it while pending. If disabled, the control explains the missing technology, treasury, peace, or other diplomatic condition. On a narrow screen, the gated Tile shortcut points you to Political.

Assignment happens in the **Orders** phase; progress and completion apply in **Build/work** after you confirm the turn.

### Fleets into new sea zones

1. On `UNIT30001` **Naval units panel**, open **Move** for a fleet that is allowed to sail (not the home fleet).
2. In `DLG30001` **Move fleet dialog**, choose an adjacent sea zone or an owned port destination.
3. When the fleet **enters** a sea zone in **Movement**, coastal land tiles around that zone and the zone’s water become fully visible for you. At end of turn, a distant sea zone may re-fog if you lack an owned adjacent coast **and** have no fleet **at sea** there (ships in port do not hold the fog open).

Land **Move** orders also need fogged or fully visible tiles at source and destination — pure unknown provinces are not marchable targets.

### Tribe first contact and discovery reports

- When your court first gains **non-unknown land** visibility into a **Tribe-owned** province, `OVL80001` **Tribe first contact herald** may block the screen with the tribe and capital names. A peaceful relation is established for that contact; each tribe heralds once per game session for you.
- After turn resolution, `DLG50001` **Turn news dialog** summarizes discoveries (including province-discovered lines) for turns after the first.
- On the map chrome, the news toggle opens `OVL70001` **Player turn event feed** — a compact, human-scoped scroll of outcomes that replaces its entries each resolved turn. Use it alongside turn news and the fog itself (Chapter 14).

## Counsel

**Counsel.** Hark, my liege: an Explorer’s first gift is not treasure — it is the right to walk, work, and judge a province without guessing.

**Tip.** Prospect minerals before you spend Builders on improvement levels you cannot yet extract.

**Warning.** Sea-only sight of a Tribe province does not trigger first contact; you need land intel. Consulates open Minor and Tribe interiors to explore and prospect — diplomacy is the latch on the New World door.

## The other courts

Rival courts race the same fog. AI civilian planners score Explorer **explore** and **prospect** work highly when feedstock minerals are needed, and colonial phases favor training and replacing Explorers (`SPEC/ai/civilian-work-planner.md`, `SPEC/ai/civilian-build-planner.md`). Growth-stage logic pressures prospected-and-improved feedstock before heavy infrastructure (`SPEC/ai/growth-stage-planner.md`). Explorer-leaning personalities push extraction and colonies harder than cautious peers (`SPEC/ai/ai-personalities.md`).

## Consequences

- Leaving New World fog untouched delays colonial extraction and purchase targets.
- Skipping prospect on mineral tiles wastes Builder turns on improvements that cannot yield.
- Fleets that never leave port fail to hold distant sea visibility open.
- Missing Consulate gates strand Explorers at Minor/Tribe borders while rivals dig in.

## Acceptance criteria for this chapter

- [ ] Documents unknown / fogged / fully visible and own-province never-decay rule.
- [ ] Documents bootstrap prospecting on advanced starts vs in-game Explorer `prospect` (cross-ref Ch. 2).
- [ ] Documents Explorer `explore` (partial-reveal gate, free, ≤3 turns, province reveal on complete) and `prospect` (eligible terrain, free, 1 turn, completion-only).
- [ ] Documents Consulate gate for Minor/Tribe explore/prospect.
- [ ] Documents fleet enter → coastal/sea reveal and end-of-turn re-fog conditions.
- [ ] Documents `OVL80001` first contact and discovery reporting via `DLG50001`; documents operable `OVL70001` Player turn event feed (news toggle).
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/advanced-starts.md`
- `SPEC/game/fog-and-exploration.md`
- `SPEC/game/civilian-units.md`
- `SPEC/game/ships-and-naval.md`
- `SPEC/game/diplomacy.md`
- `SPEC/program/orders.md`
- `SPEC/program/fog-and-exploration-resolution.md`
- `SPEC/program/naval-movement-resolution.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/program/turn-news-digest.md`
- `SPEC/ui/map-widget.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/civilian-units-panel.md`
- `SPEC/ui/move-fleet-dialog.md`
- `SPEC/ui/naval-units-panel.md`
- `SPEC/ui/tribe-first-contact-overlay.md`
- `SPEC/ui/turn-news-dialog.md`
- `SPEC/ui/player-turn-event-feed.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/civilian-work-planner.md`
- `SPEC/ai/civilian-build-planner.md`
- `SPEC/ai/growth-stage-planner.md`
- `SPEC/ai/economy-planner.md`
- `SPEC/ai/ai-personalities.md`

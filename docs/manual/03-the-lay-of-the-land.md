# The Lay of the Land

## Purpose

Your decrees land on **provinces**, **sea zones**, and **tiles**. Reading the map correctly — what you own, what is adjacent, what terrain can yield, and whether a place is bound to your capital — is the difference between a thriving extraction network and a pretty but stranded empire. This chapter teaches the geography the UI shows you and why province identity is written the way it is.

## How it is done

### Two regions, one throne

- **Old World** and **New World** each have their own tile map and topology graph. Land armies move on **province–province** edges within a region; fleets move on **sea–sea** paths and touch coasts on **province–sea** edges.
- Regions connect **only** through **warp zones** (paired sea zones). Overseas connectivity for ports and colonies follows sea paths **plus** those warp links — there is no land bridge between worlds.
- Switch regions with the region tabs / minimap controls on `MAP10001` (see Chapter 1 orientation).

### Reading provinces and sea zones

1. On `GAME10001` / `MAP10001`, select a land province or sea zone.
2. `MAP20001` **Province / sea-zone detail overlay** shows the place’s display name, ownership, and local details (economic and military cues as implemented there).
3. Town and port icons on the map mark development and seaboard access (`SPEC/ui/town-port-icons.md`). Layered terrain rendering paints the tile art beneath political ownership (`SPEC/ui/layered-terrain-rendering.md`).
4. Political ownership glyphs and GP tinting (when present on the game) help you see who holds which province at a glance.

### Terrain, resources, and what is hidden

Tiles carry **terrain** and optional **resources**. Extraction only happens where ownership, improvements, connectivity, and tech caps allow (Chapters 6–7). Region rules matter:

- Some commodities are **Old World only** (e.g. grain, meat, wool, horses), some **New World only** (e.g. sugar cane, tobacco, cotton, furs, spices, precious metals/gems), some **both** (e.g. timber, iron, copper, tin, coal).
- **Prospect-required** minerals (iron, copper, tin, coal, silver, gold, gems, diamonds) stay hidden until an Explorer **prospects** the tile. Other resources are knowable from terrain once the tile is revealed. Fog and exploration are Chapter 4.

### Capital and connectivity

- Your **capital province** and **capital tile** are fixed at setup (Chapter 2). Great Power capital provinces start at high town development.
- **Connectivity** from the capital (roads/rails and town rules) decides which owned tiles contribute to your extraction network. Land-locked holdings without a path to the capital do not feed the stockpile the way connected tiles do.
- Ports on seaboards matter for overseas links; capital setup places capital ports and initial roads so your first coast is usable.

### Why province identity matters in the UI

Every province and sea zone is identified as **`regionId|localId`** (never a bare local id alone). The overlay and orders use that full identity so Old World `P3` and New World `P3` never collide. When a dialog lists a destination or a report names a province, read the **region** as part of the name of the place — it is not decorative.

## Counsel

**Counsel.** Hark, my liege: a province painted in your colour is not yet a harvest — ask whether the roads and ports still bind it to your capital.

**Tip.** When two places share a short local label, trust the region prefix in the overlay title before you march or build.

**Warning.** Warp zones are the only bridge between worlds. Fleets and overseas connectivity fail for reasons that look like “empty ocean” when the warp path is missing or blocked.

## The other courts

AI courts value capital-connected extraction and contested border provinces when planning civilian work and wars (`SPEC/ai/civilian-work-planner.md`, `SPEC/ai/growth-stage-planner.md`). Expect rivals to push roads, ports, and claims along the same topology edges you see — they are not playing a different map.

## Consequences

- Misreading adjacency wastes move orders and leaves armies unable to reach the province you meant.
- Building improvements on disconnected tiles spends treasury for little extraction.
- Ignoring New World vs Old World resource tables sends explorers and colonists to barren expectations.
- Confusing local ids across regions creates “wrong province” mistakes in army and work targeting.

## Acceptance criteria for this chapter

- [ ] Explains OW/NW separate graphs, P–P / P–S / S–S edges, and warp-only cross-region links.
- [ ] Documents map selection → `MAP20001` overlay and points to town/port and terrain rendering specs.
- [ ] Summarizes region resource rules and prospect-required minerals (detail deferred to Ch. 4/6 as appropriate).
- [ ] Explains capital connectivity’s effect on extraction usefulness.
- [ ] Explains prefixed province identity (`regionId|localId`) as the UI naming contract.
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/world-model.md`
- `SPEC/game/world-model-identity.md`
- `SPEC/game/map-topology.md`
- `SPEC/game/tile-map-and-generation.md`
- `SPEC/game/resource-terrain-region-rules.md`
- `SPEC/game/capital-and-connectivity.md`
- `SPEC/ui/map-widget.md`
- `SPEC/ui/empire-overview.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/layered-terrain-rendering.md`
- `SPEC/ui/town-port-icons.md`
- `SPEC/ui/game-screen.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/civilian-work-planner.md`
- `SPEC/ai/growth-stage-planner.md`

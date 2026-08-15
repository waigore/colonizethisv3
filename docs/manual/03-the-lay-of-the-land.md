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
2. `MAP20001` **Province / sea-zone detail overlay** shows the place’s display name, ownership, and local details. On the **Tile** section, action-critical rows (coordinates, resource, prospected, improvement, transport level, civilians) stay on the default surface; road captions, port status, capital-link teaching, and per-tile extraction live under **Tile details** (tap the transport line or the named control). A **stranded** tile that cannot extract still shows one default capital-link warning when full production would be greater than zero. When a Minor or Tribe province bars exploration for lack of a Consulate, its Political section also offers the focused **Establish Consulate** shortcut; unavailable attempts explain what your court still lacks. On a hostile coastal province at war with you, the Naval section can start **Blockade** or **Beachhead** when a sea-going fleet is at sea beside that coast (Chapter 13).
3. Town and port icons on the map mark development and seaboard access (`SPEC/ui/town-port-icons.md`). When a province has a **fort** (wood, stone, or modern), a smaller **fort glyph** appears offset near the town icon on `MAP10001` — your own forts always show when the town tile is revealed; foreign forts appear only when you have full military intelligence for that province (the same gate as invasion fort lines on `DLG20001`). Your **armies** appear as a regiment icon in the **bottom-right** of that same town tile, so you can still tap the town, fort, or a civilian on the cell. A stack badge appears when more than one of your armies shares the town (the Home Army counts, even with no regiments yet). Tap the army icon to move a field army, or to open the military roster when only the Home Army is there — you do not need `MAP20001` first (Chapter 11). Expect those town sites to sit on **plains** terrain at setup — setup prefers plains among eligible candidates and converts the chosen town tile to plains (clearing any surface resource) when no natural plains exists. Layered terrain rendering paints the tile art beneath political ownership (`SPEC/ui/layered-terrain-rendering.md`).
4. Political ownership glyphs and GP tinting (when present on the game) help you see who holds which province at a glance.

### Hovering a tile: place, owner, and sight

On `MAP10001`, rest the pointer on a tile (without tapping) to read a compact panel: the **place name**, **who holds it** (`Owner:` or Unclaimed; sea tiles say they are a sea zone), and **how much your court can see** — Fully visible, Fogged — terrain only, or Unknown — no intel yet. Warp sea adds a line that the water is the passage to the other world. The panel vanishes when the pointer leaves. While you are picking a work tile, only the selection prompt remains. On a touch device, tap the tile and read **Sight** on `MAP20001` Political (the first tab). Ownership on this readout stays true even on black unknown land; it does not name hidden terrain or resources.

### Terrain, resources, and what is hidden

Tiles carry **terrain** and optional **resources**. Extraction only happens where ownership, improvements, connectivity, and tech caps allow (Chapters 6–7). Region rules matter:

- Some commodities are **Old World only** (e.g. grain, meat, wool, horses), some **New World only** (e.g. sugar cane, tobacco, cotton, furs, spices, precious metals/gems), some **both** (e.g. timber, iron, copper, tin, coal).
- **Prospect-required** minerals (iron, copper, tin, coal, silver, gold, gems, diamonds) stay hidden until an Explorer **prospects** the tile. Other resources are knowable from terrain once the tile is revealed. Fog and exploration are Chapter 4.

Open **Map display options** (gear, `MAP10001`) to name what is painted: **Show resources** (commodity icons and extraction discs), **Show improvements** (`I{n}` labels), and **Show roads and rails**. Turning improvements off also turns roads off and greys that switch until improvements are on again. The stacked-layers button cycles four presets (terrain only → resources → resources and improvements → all three) and jumps to terrain only from any other combination. Those choices persist when you save.

### Capital and connectivity

- Your **capital province** and **capital tile** are fixed at setup (Chapter 2). Great Power capital provinces start at high town development. The capital tile is on **plains** — preferred among Class A/B/C candidates when possible, or converted to plains after selection if the winning site was another terrain (any resource on that tile is cleared).
- Every province has exactly one **town** tile: the capital tile in a capital province, or a separate town site elsewhere. Neutral (ownerless) provinces receive a town tile under the same **plains-first** rule and convert-if-needed behavior. On `MAP10001`, town and port icons mark those sites on the plains beneath them.
- **Connectivity** from the capital (roads/rails and town rules) decides which owned tiles contribute to your extraction network. Land-locked holdings without a path to the capital do not feed the stockpile the way connected tiles do.
- Ports on seaboards matter for overseas links; capital setup places capital ports and initial roads so your first coast is usable. An overseas port tile chosen as a town site follows the same convert-to-plains rule when it is not already plains.

### Extraction discs on `MAP10001`

When resource icons are visible on the empire map (`MAP10001`) — **Show resources** is on in Map display options — small coloured **extraction discs** may appear beside the icon on your owned improved tiles:

- **Gold discs** — yield that reaches your capital / stockpile this turn.
- **Brown discs** — improved yield that does **not** reach the stockpile (no capital link, or a road / port / town path cap).

A compact **extraction-disc legend** sits above the bottom-left map tools whenever resource icons are on and you are viewing as a player (normal play or player observe) — including on turn 1 before any discs are painted. Tap the legend for a short panel that restates both colours and counsel to restore roads, towns, or ports toward the capital. The legend hides in **terrain only** and in **global observe**.

A disconnected improved tile with a visible resource icon shows **all brown** discs (no gold) — not silence. That is your cue that the improvement looks productive but extraction is stranded until you restore capital link toward your capital.

**Owned land without discs** (empty plains, towns, roads, zero-yield tiles) can still be cut off. With **Highlight land not bound to the capital** on in **Map display options** (default **ON**), those stranded owned tiles show a muted diagonal hatch on `MAP10001` so you can plan roads and ports at a glance without tapping every tile. Connected owned land stays unmarked. Turn the highlight off in the same dialog if you prefer a cleaner map; the choice is saved with your campaign.

### Why province identity matters in the UI

Every province and sea zone is identified as **`regionId|localId`** (never a bare local id alone). The overlay and orders use that full identity so Old World `P3` and New World `P3` never collide. When a dialog lists a destination or a report names a province, read the **region** as part of the name of the place — it is not decorative.

## Counsel

**Counsel.** Hark, my liege: a province painted in your colour is not yet a harvest — ask whether the roads and ports still bind it to your capital. The hatch and the brown discs both whisper the same warning: the network is broken.

**Tip.** When two places share a short local label, trust the region prefix in the overlay title before you march or build.

**Warning.** Warp zones are the only bridge between worlds. Fleets and overseas connectivity fail for reasons that look like “empty ocean” when the warp path is missing or blocked.

## The other courts

AI courts value capital-connected extraction and contested border provinces when planning civilian work and wars (`SPEC/ai/civilian-work-planner.md`, `SPEC/ai/growth-stage-planner.md`). Expect rivals to push roads, ports, and claims along the same topology edges you see — they are not playing a different map.

## Consequences

- Misreading adjacency wastes move orders and leaves armies unable to reach the province you meant.
- Building improvements on disconnected tiles spends treasury for little extraction.
- An improved tile may show a resource icon and brown extraction discs even when nothing reaches your stockpile — read gold vs brown on `MAP10001` before you assume the tile is paying its way.
- Ignoring New World vs Old World resource tables sends explorers and colonists to barren expectations.
- A capital or town tile converted to plains at setup may no longer show the resource that generation placed there — the settlement spine takes priority over that surface deposit.
- Confusing local ids across regions creates “wrong province” mistakes in army and work targeting.

## Acceptance criteria for this chapter

- [ ] Explains OW/NW separate graphs, P–P / P–S / S–S edges, and warp-only cross-region links.
- [ ] Documents map selection → `MAP20001` overlay and points to town/port and terrain rendering specs.
- [ ] Summarizes region resource rules and prospect-required minerals (detail deferred to Ch. 4/6 as appropriate).
- [ ] Explains capital connectivity’s effect on extraction usefulness.
- [ ] Documents plains placement for capitals and per-province town tiles (including neutral provinces; prefer plains, convert-if-needed).
- [ ] Explains gold vs brown extraction discs on `MAP10001`, the on-map legend, and ties brown discs on disconnected improved tiles to capital connectivity.
- [ ] Documents human army stack markers on town tiles (`MAP10001`) and that tapping the army icon starts Move or the military roster without opening `MAP20001`.
- [ ] Documents the default-on map highlight for owned land not bound to the capital (Map display options).
- [ ] Explains named Map display options for resources, improvements, and roads, and the stacked-layers cycle as a shortcut.
- [ ] Explains prefixed province identity (`regionId|localId`) as the UI naming contract.
- [ ] Documents MAP10001 hover place/owner/sight readout and MAP20001 Political Sight.
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/world-model.md`
- `SPEC/game/world-model-identity.md`
- `SPEC/game/map-topology.md`
- `SPEC/game/tile-map-and-generation.md`
- `SPEC/game/resource-terrain-region-rules.md`
- `SPEC/game/capital-and-connectivity.md`
- `SPEC/game/capital-choice-phase.md`
- `SPEC/ui/map-widget.md`
- `SPEC/ui/empire-overview.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/layered-terrain-rendering.md`
- `SPEC/ui/town-port-icons.md`
- `SPEC/ui/game-screen.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/civilian-work-planner.md`
- `SPEC/ai/growth-stage-planner.md`

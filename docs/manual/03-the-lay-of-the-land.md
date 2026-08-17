# The Lay of the Land

## Purpose

You have inherited a **Great Power** — a playable nation. On each turn you issue **decrees** (actions you choose). Those decrees land on **provinces** (named pieces of land), **sea zones** (named stretches of water), and **tiles** (one square on the map). There are two maps: the **Old World** and the **New World**. Read the map so you know what you own, what sits next door, what the land can give you, and whether a place still feeds your capital. That is the difference between a harvest that arrives and land that only looks like yours.

## How it is done

### Two maps, one throne

- **Old World** and **New World** each have their own land and water. Armies march only into a neighbouring province on the **same** map. Fleets sail from sea to sea and can touch a coast. The two maps meet **only** at **warp** sea (paired sea zones). Ports and colonies reach home by sea paths **plus** those warp links — there is no land bridge.
- Warp sea is the water with the yellow glow (and the extra hover line). That is the only bridge between the two maps.
- Switch maps with the **Old World** / **New World** tabs on `MAP10001` **Empire overview / map area**. The small map in the bottom-right only moves the camera on the map you are already viewing. That same tab row also shows how many Old World provinces you hold out of 31 (Chapter 15).

### Reading provinces and sea zones

1. On `GAME10001` **Game screen** / `MAP10001` **Empire overview / map area**, tap a land province or sea zone.
2. `MAP20001` **Province sea-zone overlay** opens. The header reads **Province** or **Sea zone**. Political lists **Name**, **Owner**, **Sight**, **Region**, and whether the place is a capital.
3. On **Tile**, these rows stay visible: coordinates, **Terrain**, the town or capital line when this square is the town or capital (`The town of …` / `…, the capital of …`), resource, **Prospected**, **Improvement**, **Road / railroad** transport level, and civilians.
4. Tap the transport line or **Tile details** to read road captions, **Port: None** / **Port: Present**, whether the tile still links to the capital, and **Extraction from this tile** when some of the yield reaches home. A tile that cannot extract still shows one default warning **Capital link: Not connected — will not extract** when it would otherwise produce.
5. When a **Minor Nation** or **Tribe** (peoples you do not play) province bars exploration for lack of a Consulate, Political also offers **Establish Consulate**. Unavailable attempts explain what your court still lacks.
6. On a hostile coastal province at war with you, Naval can start **Blockade** or **Beachhead** when a sea-going fleet is at sea beside that coast (Chapter 13).
7. You can also right-click a tile (or press and hold on a touch screen) to open `MAP30001`, a small ring of nearby actions, without opening that panel first. The ring can show **Explore**, **Prospect**, and **Build improvement** when those shortcuts are on the tile (they may be greyed with a reason). **More** always includes **Province details**. On a tight screen the ring is skipped and `MAP30002` **More tile actions** opens instead.
8. Town and port icons on the map mark development and access to the sea. When a province has a **fort** (wood, stone, or modern), a smaller **fort icon** sits near the town icon on `MAP10001`. Your own forts always show when the town tile is revealed. Foreign forts appear only when you have full military intelligence for that province, and they stay hidden if the town tile is still unrevealed.
9. Your **armies** appear as a regiment icon in the **bottom-right** of that same town tile, so you can still tap the town, fort, or a civilian on the cell. A number appears when more than one of your armies shares the town (the Home Army counts, even with no regiments yet). Tap the army icon to move a field army, to detach a marching force from a non-empty Home Army, or to open the military roster when the Home Army is empty — you do not need `MAP20001` first (Chapter 11).
10. Turn on **Show province ownership** in **Map display options** if you want Great Power land tinted in that nation’s colour. Ownership icons and that tint are map tools, not a separate screen. The land art sits under any ownership colour so you can still read plains, hills, and forests.

### Hovering a tile: place, owner, and sight

On `MAP10001` **Empire overview / map area**, rest the pointer on a tile (without tapping) to read a compact panel: the **place name**, **who holds it** (`Owner:` or Unclaimed; sea tiles say they are a sea zone), and **how much your court can see** — Fully visible, Fogged — terrain only, or Unknown — no intel yet. Warp sea adds a line that the water is the passage to the other world. The panel vanishes when the pointer leaves. While you are picking a work tile, only the selection prompt remains. On a touch device, tap the tile and read **Sight** on `MAP20001` **Province sea-zone overlay** Political (the first tab). Ownership on this readout stays true even on black unknown land; it does not name hidden terrain or resources.

After a turn resolves, when turn news closes (or after **View Final State** on victory), `MAP10001` may pulse a few last-turn fights, captures, finished works, or discoveries so you see where the realm changed; Chapter 14 covers skip and the full feed.

### Terrain, resources, and what is hidden

Tiles carry **terrain** and optional **resources**. Goods only reach your stockpile where you own the land, have improved it, still have a path home, and your court can take that yield (Chapters 6–7). Map rules matter:

- Some commodities are **Old World only** (e.g. grain, meat, wool, horses), some **New World only** (e.g. sugar cane, tobacco, cotton, furs, spices, precious metals/gems), some **both** (e.g. timber, iron, copper, tin, coal).
- **Prospect-required** minerals (iron, copper, tin, coal, silver, gold, gems, diamonds) stay hidden until an Explorer **prospects** the tile. Other resources are knowable from terrain once the tile is revealed. Fog and exploration are Chapter 4.

Open **Map display options** (gear, `MAP10001`) to name what is painted: **Show resources** (commodity icons and gold and brown discs), **Show improvements** (`1 of 1` / `1 of 2` marks on your improved tiles), and **Show roads and rails**. Turning improvements off also turns roads off and greys that switch until improvements are on again. A shortcut button at the bottom-left of the map cycles four presets (terrain only → resources → resources and improvements → all three) and jumps to terrain only from any other mix. Its tooltip names the current combination. Those choices persist when you save.

### Capital and the path home

- Your **capital province** and **capital tile** are fixed at setup (Chapter 2). Great Power capital provinces start at town development **4 of 4**. The capital tile ends as **plains**. Setup prefers a coast tile that does not touch another province, then converts that tile to plains if it was not already plains (any resource there is cleared). It does not skip a better coast site just because inland plains look nicer.
- Every province has exactly one **town** tile: the capital tile in a capital province, or a separate town site elsewhere. Neutral (ownerless) provinces receive a town tile too. Town tiles prefer plains among allowed sites, then convert to plains if needed (clearing any surface resource). On `MAP10001`, town and port icons mark those sites on the plains beneath them.
- Roads, rails, ports, and towns decide which owned tiles send goods to your capital. Inland land with no path home does not feed the stockpile the way linked tiles do.
- Ports on the coast matter for overseas links; capital setup places capital ports and initial roads so your first coast is usable. An overseas port tile chosen as a town site follows the same convert-to-plains rule when it is not already plains.

### Gold and brown discs on `MAP10001`

When resource icons are visible on `MAP10001` **Empire overview / map area** — **Show resources** is on in **Map display options** — small coloured **gold and brown discs** may appear beside the icon on your owned improved tiles:

- **Gold discs** — **Reaches capital**: yield that reaches your capital / stockpile this turn.
- **Brown discs** — **Blocked — will not extract**: improved yield that does **not** reach the stockpile (no path home, or a road / port / town path limit).

A compact **colour key** sits above the bottom-left map tools when you are playing (or watching one court), including on turn 1 before any discs are painted. The key names **Reaches capital** and **Blocked — will not extract**. Tap the key for a short panel that restates both colours and counsel to restore roads, towns, or ports toward the capital.

The colour key hides when the map shows **terrain only**, and when you are watching the whole world as a spectator (no one court’s map). Two map rules do not yet agree on the rest: one says the key appears whenever the map is not **terrain only**; another says it appears when resource icons are on. Until those rules match, expect the key whenever you can see resource icons. It may also appear in other mixes that are not **terrain only**.

A disconnected improved tile with a visible resource icon shows **all brown** discs (no gold) — not silence. That is your cue that the improvement looks productive but nothing reaches home until you restore the path toward your capital.

### Improvement marks on `MAP10001`

When **Show improvements** is on, owned revealed tiles that already have an improvement show a compact **1 of 1** or **1 of 2** in the tile’s top-left corner. Muted **1 of 1** means this court cannot raise that tile further right now (early grain farms often sit there). A brighter **1 of 2** means a Builder can still improve it. Foreign improved tiles, and your own improved tiles whose resource is still hidden, show the level only (`2`), without this court’s limit. Unimproved tiles stay unmarked on the map; they appear on `MAP20001` **Province sea-zone overlay** under Economic as tiles you can still improve, not as a `0 of 1` on the map.

A compact **improvement key** sits above the bottom-left map tools whenever **Show improvements** is on and you are playing (or watching one court). Tap the improvement key to read that **1 of 1** / **1 of 2** is the tile’s level versus what this court can take now, and that muted means at the current limit. The colour key and the improvement key hide when the map shows **terrain only**, when **Show improvements** is off (improvement key), and when you are watching the whole world as a spectator (no one court’s map).

**Owned land without discs** (empty plains, towns, roads, zero-yield tiles) can still be cut off. With **Highlight land not bound to the capital** on in **Map display options** (default **ON**), those stranded owned tiles show a muted diagonal hatch on `MAP10001` so you can plan roads and ports at a glance without tapping every tile. Connected owned land stays unmarked. Turn the highlight off in the same dialog if you prefer a cleaner map; the choice is saved with your campaign.

### Why place names matter on the map

Two maps can share similar place names. Read the **Name** and **Region** rows on `MAP20001` **Province sea-zone overlay**, and check whether the **Old World** or **New World** tab is selected, before you march or build. Map labels use those same display names. Do not treat a short name as enough on its own.

## Counsel

**Counsel.** Hark, my liege: a province painted in your colour is not yet a harvest — ask whether the roads and ports still bind it to your capital. The hatch and the brown discs both whisper the same warning: the path home is broken.

**Tip.** When two places share a similar name, read **Name** and **Region** on `MAP20001` **Province sea-zone overlay**, and check which map tab is selected, before you march or build.

**Warning.** Warp sea is the only bridge between worlds. Fleets and overseas ports can fail for reasons that look like empty ocean when the warp path is missing or blocked.

## The other courts

Rival courts also prefer land that still links to their capital when they assign civilian work, and they push roads, ports, and claims along the same neighbouring provinces and sea paths you see. They are not playing a different map.

## Consequences

- Misreading who sits next door wastes marches and leaves armies short of the province you meant.
- Building improvements on land with no path home spends treasury for little harvest.
- An improved tile may show a resource icon and brown discs even when nothing reaches your stockpile — read gold vs brown on `MAP10001` before you assume the tile is paying its way.
- Ignoring New World vs Old World resource tables sends explorers and colonists to barren expectations.
- A capital or town tile converted to plains at setup may no longer show the resource that the land first showed — the settlement takes priority over that surface deposit.
- Mixing up two places that share a short name on different maps sends armies and workers to the wrong land.

## Acceptance criteria for this chapter

- [ ] Explains that Old World and New World are separate maps; armies march only to a neighbouring province on the same map; fleets sail sea to sea and can touch a coast; the maps meet only at warp sea (yellow glow).
- [ ] Documents map selection → `MAP20001` **Province sea-zone overlay** (header **Province** or **Sea zone**) and points to town/port icons and land art under ownership colour.
- [ ] Documents `MAP30001` right-click / press-and-hold tile acts (including greyed shortcuts) and `MAP30002` **More tile actions** **Province details** (ring skipped on a tight screen).
- [ ] Summarizes Old World / New World resource rules and prospect-required minerals (detail deferred to Ch. 4/6 as appropriate).
- [ ] Explains how roads, rails, ports, and towns decide which owned tiles send goods to the capital.
- [ ] Documents plains placement for capitals and per-province town tiles (including neutral provinces; capital ends as plains; towns prefer plains among allowed sites, then convert).
- [ ] Explains gold vs brown discs on `MAP10001`, the on-map colour key (**Reaches capital** / **Blocked — will not extract**), and ties brown discs on disconnected improved tiles to the path home.
- [ ] Documents army icons on town tiles (`MAP10001`) and that tapping the army icon starts Move or the military roster without opening `MAP20001`.
- [ ] Documents the default-on map highlight for owned land not bound to the capital (Map display options).
- [ ] Explains named Map display options for resources, improvements, and roads, and the bottom-left shortcut that cycles four presets.
- [ ] Explains **1 of 1** / **1 of 2** improvement marks, muted-at-limit, and the on-map improvement key.
- [ ] Explains display names plus **Name** / **Region** rows and the active Old World / New World tab so two maps do not collide.
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
- `SPEC/ui/tile-context-radial.md`
- `SPEC/ui/tile-more-actions-dialog.md`
- `SPEC/ui/components/tile-radial-catalog.md`
- `SPEC/ui/layered-terrain-rendering.md`
- `SPEC/ui/town-port-icons.md`
- `SPEC/ui/game-screen.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/civilian-work-planner.md`
- `SPEC/ai/growth-stage-planner.md`

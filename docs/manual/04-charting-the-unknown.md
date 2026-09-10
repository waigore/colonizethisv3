# Charting the Unknown

## Purpose

Fog hides both danger and opportunity. An **Explorer** is a civilian who pushes back fog and finds buried minerals. A **province** is a named piece of land. A **Great Power** is a playable nation. **Old World** and **New World** are the two maps. A **Tribe** is a New World people. A **decree** is an action you choose on your turn. Send Explorers and fleets so you can walk a province, work it, and see what lies under the ground. When a Tribe’s land first comes into view, their court announces itself. After you confirm **Next turn**, the game shows what was found.

## How it is done

### Visibility levels

Each **tile** (one square of land or water) you care about is in one of three **Sight** levels (least useful first):

| Level | What you know |
|-------|----------------|
| **Unknown — no intel yet** | You cannot explore or prospect there yet. New World land and sea start here for Great Powers. |
| **Fogged — terrain only** | Terrain and goods that do not need prospecting; last-known buildings of others. Old World provinces you do not own start here. |
| **Fully visible** | Full local detail except minerals that still need prospecting. **Your own provinces stay Fully visible** and never fade. |

Who owns the land on the map stays true even when a province is fogged. Fog hides detail, not the claim.

On `MAP10001` **Empire overview / map area**, rest on a tile (without tapping) to read a compact panel: **Place**, **Owner:** with the holder’s name or `Unclaimed` (water shows a **Sea zone** line instead of an owner), and **Sight** as one of those three phrases. On the yellow-glow water that is the passage between the two maps, that panel adds a line that the water is the passage to the other world. On an unrevealed tile, that panel still shows who holds it. It must not name terrain, a resource, or a building. While you are choosing where an Explorer will work, that panel hides; only the choose-a-tile message remains. Tap the tile to open `MAP20001` **Province sea-zone overlay**. Its **Political** section repeats a **Sight** row for the selected tile. On a phone or tablet with no pointer, use that **Sight** row.

**Setup defaults:** Old World starts fogged (owned tiles Fully visible). New World starts unknown. Sea next to coasts in provinces you own becomes **Fully visible** at setup and again at the end of each turn.

Land you do not own can lose detail. If none of your Explorers stay in another nation’s province at the end of the turn, tiles that were **Fully visible** become **Fogged — terrain only**. A **Spy** (a hidden agent) who leaves does **not** drop sight at once: a 5-turn timer keeps that land **Fully visible** until it expires. Tiles that were already **Unknown** or **Fogged** stay as they are. Provinces you own stay **Fully visible** and never fade this way.

### Minerals already known on a later start

If you begin at **50 Turns In (1598)** or **100 Turns In (1698)**, some minerals on land you already own are already known before you take your first actions. That is not the New World coast you see from setup, and it is not Explorer **Prospect** work during play. Chapter 2 **Founding Your Reign** names the printed fractions, Old World vs New World scope, and the prospect-before-development order. Each **Minor Nation** (a smaller Old World court you do not play) already knows a share of minerals in its **own** Old World provinces. Separately, Great Powers may already have bought some minor-nation tiles. Those two facts are not the same thing.

### Explorer work: explore and prospect

You explore and prospect **your** land, **unclaimed** land, and (with a **Consulate** — a foothold with that court or a Tribe that lets you explore and prospect their land) **Minor Nation** or **Tribe** land. You do **not** explore or prospect a rival Great Power’s provinces. An **Embassy** is a further foothold with that court (Chapter 10).

**From the civilian list**

1. Open `UNIT10001` **Civilian units panel**.
2. On an Explorer whose status is **Idle** (printed `Status: Idle`) with no pending work, tap **Assign**, then **Explore** or **Prospect**, then tap a legal tile on the map.
3. Province shortcuts: **Assign** commits the already chosen tile with no second menu.

**From the province panel**

1. On `MAP20001` **Province sea-zone overlay**, open **Tile**.
2. Tap **Explore with explorer** or **Prospect with explorer**. Those shortcuts open the same civilian panel showing only your Explorers.
3. Tap **Assign** to commit that work to the selected tile (no second menu).
4. If you own **no Explorers**, **Explore with explorer** and **Prospect with explorer** stay visible but greyed out. **Train Explorer** appears beside them, enabled. A short line says the new Explorer appears at your capital after **Next turn**, and that this tap does not assign Explore or Prospect on this tile. Tap **Train Explorer** to open `UNIT40001` **Train civilians dialog** (printed title **Train Civilians**). You still set how many to hire with the +/− controls there; this tap does not assign **Explore** or **Prospect** on this tile. Map **Train Explorer** opens that dialog with no Explorer row pre-selected. If a Consulate is also missing on Minor Nation or Tribe land, **Train Explorer** is hidden and the greyed shortcut still points you to **Establish Consulate**. The same **Train Explorer** wording appears on `MAP30001` **Tile context radial** (right-click or press-and-hold) and on `MAP30002` **More tile actions**. `MAP20001` still has older sentences that grey **Explore** / **Prospect** when you have no Explorer beside the enabled **Train Explorer** rule — those two sentences on that panel do not yet agree; until they match, treat the ring and **More** **Train Explorer** labels as the map shortcut, and do not treat a grey Explore on `MAP20001` as the last word.

**Explore**

1. Pick a land tile in a province that is **partly seen**: at least one land tile Fogged or Fully visible **and** at least one land tile still Unknown. The work is **free**. Before you **Assign**, enabled **Explore** shows `After this work: this whole province becomes fully visible · Takes N turn(s)` (or **Takes 1 turn**). Cost stays absent (free).
2. Larger provinces take longer, up to **three** turns. Time is compared to the biggest province on the same map, so a small province finishes sooner than a large one.
3. When that work **finishes**, after you confirm **Next turn**, every tile in that province becomes **Fully visible** for you.

**Prospect**

1. Pick a swamp, hills, mountain, or desert tile that is at least Fogged. Tiles that already show a good you can see from the land (grain, meat, wool, horses, timber, sugar cane, tobacco, cotton, furs, spices) cannot be prospected, even on those terrains. Hills with wool cannot be prospected.
2. The work is **free** and lasts **one** turn. Before you **Assign**, enabled **Prospect** shows `After this work: any mineral on this tile becomes known · Takes N turn(s)` (or **Takes 1 turn**). The line does not name a hidden good and does not promise that a deposit is there. The mineral is known to you only when that work **finishes**, after you confirm **Next turn**. Prospect-required minerals (iron, copper, tin, coal, silver, gold, gems, diamonds) stay hidden until then. After **Next turn**, `OVL70001` **Player turn event feed** shows `{province} work completed! Prospect found {displayName}` or `{province} work completed! Prospect found no mineral`. Last-turn highlight captions on `MAP10001` use the same survey line. Rival courts’ surveys do not appear on your feed.

**Consulate on Minor Nation or Tribe land**

Exploring or prospecting in a **Minor Nation** or **Tribe** province needs a Consulate with that owner. Without it, **Explore with explorer** and **Prospect with explorer** stay **visible but greyed out**. Their hint reads **Establish a consulate before exploring or prospecting**. On a narrow screen, that disabled hint points you to **Political** **Establish Consulate**. The civilian-unit rules say Consulate or higher. The diplomacy rules say **Diplomatic Expertise** (the Embassy technology) also gates Embassy and foreign civilian work for Minor Nations and Tribes. This handbook does not pick which rule wins; the printed hint is the Consulate line above.

Open **Political** on `MAP20001` **Province sea-zone overlay**. Tap **Establish Consulate**, read the stated cost and effect, and confirm to issue the decree. While you have not yet confirmed **Next turn**, the control reads **Cancel** and tap withdraws it. If the control is greyed out, its hint names the missing treasury, peace, or other condition.

### Fleets into new sea zones

1. Open `UNIT30001` **Naval units panel**.
2. Open **Move** for a fleet that is allowed to sail. The **Home Fleet** stays at the capital and has no **Move**.
3. In `DLG30001` **Move fleet dialog**:
   - A fleet **in port** may only undock into an adjacent sea zone. The dialog shows **Sea zones** only.
   - A fleet **at sea** may pick an adjacent sea zone under **Sea zones**, or an owned dock. A capital dock is labelled **(capital — joins Home Fleet)**.
4. After you confirm **Next turn**, when that fleet **enters** a sea zone, the water there and the coastal land tiles that **touch that water** become **Fully visible** for you. **Inland** land in the same province stays **Unknown** until an Explorer finishes **Explore**. That is why Explorer work is still needed after a fleet arrives.

At the end of the turn, a distant sea zone’s **water** becomes **Fogged — terrain only** only when you own no adjacent coast **and** have no fleet **at sea** there (ships **in port** do not count). Tiles that are still **Unknown** stay **Unknown**. There is no fourth sight level.

Land **Move** also needs Fogged or Fully visible tiles at the start and the end. You cannot send an army into a province that is still fully Unknown.

### Tribe first contact and discovery reports

- When you first see **Tribe** land that is Fogged or Fully visible, `OVL80001` **Tribe first contact herald** fills the screen once. The title is **First Contact**. The text names the tribe and the capital. Tap **Continue** to go on. Seeing only the sea next to that land does not create the relation or the herald. Each tribe heralds once per game for you this session.
- After you confirm **Next turn** and that turn finishes (including the first turn you play from turn 0), `DLG50001` **Turn news dialog** can open. It is a **world** newspaper, not only your fog: a **Province discovered** line appears when **any** Great Power first sees that province, and province names **may appear before your map shows them**. If nothing major happened, it reads **No major events last turn.** (that empty line is omitted when **Your court** is present). A muted **Your court:** block can list at most three short clauses, with tappable **open Events** (opens `OVL70001`; ordinary **Close** does not). When spies report, the footer reads **Your spies report N items — open Intelligence** (Chapter 10). For **your** outcomes, use the feed below. After you close turn news — or after **View Final State** on `OVL20001` **Victory overlay** if that overlay is up — `MAP10001` may briefly highlight the tiles where **your** Explorer finished **Explore** / **Prospect** or where **you** gained new sight, so you can see those places without hunting the map. A finished **Prospect** caption names the mineral found or that the tile has none, matching the feed line.
- The news list starts **hidden**. On the left of the top map row, **Old World** and **New World** switch maps. On the right, treasury, cargo, then the newspaper icon. The newspaper icon opens `OVL70001` **Player turn event feed** — a short list of **your** outcomes that is **replaced** each time a turn finishes. A badge on the icon shows how many lines are in the list. Use it beside turn news and the fog itself (Chapter 14).

## Counsel

**Counsel.** Hark, my liege: an Explorer’s first gift is not treasure — it is the right to walk, work, and judge a province without guessing.

**Tip.** Prospect minerals before you spend **Builders** (civilians who improve tiles) on improvement levels you cannot yet extract.

**Warning.** Sea-only sight of a Tribe province does not trigger first contact; you need land intel. Consulates open Minor and Tribe interiors to explore and prospect — diplomacy is the latch on the New World door.

## The other courts

Rival courts send Explorers into the same fog. When they need ore for workshops and ships, they prospect before they build. Courts that favor exploration push mines and colonies harder than cautious peers; a chosen **leader** changes how bold or cautious they are, not how you win.

## Consequences

- Leaving New World fog untouched delays colonies, mines, and land you might buy.
- Skipping **Prospect** on ore tiles wastes Builder turns on mines that cannot produce yet.
- Fleets that never leave port fail to hold distant sea visibility open.
- Without a Consulate, Explorers wait at Minor Nation and Tribe borders while rivals prospect inside.

## Acceptance criteria for this chapter

- [ ] Documents unknown / fogged / fully visible (printed sight phrases), own-province never-decay, and other-land decay (Explorer absence can drop Fully visible to Fogged; a Spy who leaves keeps Fully visible for 5 turns).
- [ ] Documents MAP10001 hover **Place**, **Owner**, and **Sight** lines and MAP20001 Political Sight row (touch uses that row).
- [ ] Documents minerals already known on a later start vs in-game Explorer prospect (cross-ref Ch. 2; Minor Nation knowledge vs bought tiles kept separate).
- [ ] Documents Explorer work from `UNIT10001` **Assign** (`Status: Idle`) and `MAP20001` **Explore with explorer** / **Prospect with explorer**; `MAP30001` / `MAP30002` **Train Explorer**; enabled Explore/Prospect gists `After this work: this whole province becomes fully visible · Takes N turn(s)` and `After this work: any mineral on this tile becomes known · Takes N turn(s)`; partial-reveal explore, free, ≤3 turns vs largest province on the same map; prospect eligibility plus terrain-known exclusion; after Next turn the Events feed quotes `{province} work completed! Prospect found {displayName}` / `Prospect found no mineral`; Consulate printed hints recorded without picking a winner between Consulate-or-higher and Diplomatic Expertise; no rival Great Power land.
- [ ] Documents fleet enter → coastal-ring and water Fully visible, inland still Unknown, and distant-sea Fogged conditions (unknown unchanged).
- [ ] Documents `OVL80001` **First Contact** / **Continue**; `DLG50001` as world news after a resolved turn, including **Your court:** / **open Events** and **Your spies report N items — open Intelligence**; `OVL70001` hidden-by-default, newspaper-icon toggle, replace-not-append; playback may start after **View Final State** on `OVL20001`.
- [ ] Documents `MAP30001` **Tile context radial** and `MAP30002` **More tile actions** as **Train Explorer** entry points, and that enabled Explore/Prospect there show the same gists.
- [ ] Sources match the chapter coverage map (fog, Explorer work, fleets into new seas, first contact, where discoveries are reported) with one bullet per path.

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
- `SPEC/ui/player-turn-event-feed.md`
- `SPEC/ui/map-widget.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/tile-context-radial.md`
- `SPEC/ui/tile-more-actions-dialog.md`
- `SPEC/ui/train-civilians-dialog.md`
- `SPEC/ui/civilian-units-panel.md`
- `SPEC/ui/move-fleet-dialog.md`
- `SPEC/ui/naval-units-panel.md`
- `SPEC/ui/tribe-first-contact-overlay.md`
- `SPEC/ui/turn-news-dialog.md`
- `SPEC/ui/intelligence-council.md`
- `SPEC/ui/new-game-leader-selection-dialog.md`
- `SPEC/ui/victory-overlay.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/civilian-work-planner.md`
- `SPEC/ai/civilian-build-planner.md`
- `SPEC/ai/economy-planner.md`
- `SPEC/ai/ai-personalities.md`

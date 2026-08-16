# Charting the Unknown

## Purpose

Fog hides both danger and opportunity. An **Explorer** is a civilian who pushes back fog and finds buried minerals. A **province** is a named piece of land. A **Great Power** is a playable nation. **Old World** and **New World** are the two maps. A **Tribe** is a New World people. A **decree** is an action you choose on your turn. Send Explorers and fleets so you can walk a province, work it, and see what lies under the ground. When a Tribe’s land first comes into view, their court announces itself. After you confirm **Next turn**, the game shows what was found.

## How it is done

### Visibility levels

Each tile you care about is in one of three **sight** levels (least useful first):

| Level | What you know |
|-------|----------------|
| **Unknown — no intel yet** | You cannot explore or prospect there yet. New World land and sea start here for Great Powers. |
| **Fogged — terrain only** | Terrain and goods that do not need prospecting; last-known buildings of others. Old World provinces you do not own start here. |
| **Fully visible** | Full local detail except minerals that still need prospecting. **Your own provinces stay Fully visible** and never fade. |

Who owns the land on the map stays true even when a province is fogged. Fog hides detail, not the claim.

On **Empire overview / map area**, rest on a tile (without tapping) to read a compact panel: **Place**, **Owner:** with the holder’s name or `Unclaimed` (water shows a **Sea zone** line instead of an owner), and **Sight** as one of those three phrases. Warp water adds a line that the water is the passage to the other world. On an unrevealed tile, that panel still shows who holds it. It must not name terrain, a resource, or a building. While you are choosing where an Explorer will work, that panel hides; only the selection prompt remains. Tap the tile to open **Province sea-zone overlay**. Its **Political** section repeats a **Sight** row for the selected tile. On a phone or tablet with no pointer, use that **Sight** row.

**Setup defaults:** Old World starts fogged (owned tiles Fully visible). New World starts unknown. Sea next to coasts you **fully own** becomes Fully visible at setup and again at the end of each turn.

Land you do not own can lose detail. If none of your Explorers (or Spies — hidden agents) stay in another nation’s province, tiles that were **Fully visible** become **Fogged — terrain only**. Tiles that were already **Unknown** or **Fogged** stay as they are. Provinces you own stay **Fully visible** and never fade this way.

### Bootstrap prospecting (advanced start)

Choosing **50 Turns In (1598)** or **100 Turns In (1698)** runs a **setup-only** mineral pass on land you already own, before you take your first actions. That pass is **not** the New World coast-reveal you get from setup, and it is **not** Explorer **prospect** work during play. Chapter 2 **Founding Your Reign** names the printed fractions, Old World vs New World scope, and the prospect-before-development order. Each Minor Nation already knows a share of minerals in its **own** Old World provinces. Separately, Great Powers may already have bought some minor-nation tiles. Those two facts are not the same thing.

### Explorer work: explore and prospect

You explore and prospect **your** land, **unclaimed** land, and (with a Consulate) **Minor Nation** or **Tribe** land. You do **not** explore or prospect a rival Great Power’s provinces.

**From the civilian list**

1. Open **Civilian units panel**.
2. On an idle Explorer, tap **Assign**, then **Explore** or **Prospect**.
3. Tap a legal tile on the map.

**From the province panel**

1. On **Province sea-zone overlay**, open **Tile**.
2. Tap **Explore with explorer** or **Prospect with explorer**. Those shortcuts open the same civilian panel already filtered to Explorers.
3. Tap **Assign** to commit that work to the selected tile (no second menu).

**Explore**

1. Pick a land tile in a province that is **partly seen**: at least one land tile Fogged or Fully visible **and** at least one land tile still Unknown. The work is **free**.
2. Larger provinces take longer, up to **three** turns. Time is compared to the biggest province on the same map, so a small province finishes sooner than a large one.
3. When that work **finishes**, after you confirm **Next turn**, every tile in that province becomes **Fully visible** for you.

**Prospect**

1. Pick a swamp, hills, mountain, or desert tile that is at least Fogged. Tiles that already show a good you can see from the land (grain, meat, wool, horses, timber, sugar cane, tobacco, cotton, furs, spices) cannot be prospected, even on those terrains. Hills with wool cannot be prospected.
2. The work is **free** and lasts **one** turn. The mineral is known to you only when that work **finishes**, after you confirm **Next turn**. Prospect-required minerals (iron, copper, tin, coal, silver, gold, gems, diamonds) stay hidden until then.

**Consulate on Minor Nation or Tribe land**

Exploring or prospecting in a **Minor Nation** or **Tribe** province needs a **Consulate or higher** with that owner. Without it, **Explore with explorer** and **Prospect with explorer** stay **visible but greyed out**. Their hint reads **Establish a consulate before exploring or prospecting**. On a narrow screen, that disabled hint points you to **Political** **Establish Consulate**.

Open **Political** on **Province sea-zone overlay**. Tap **Establish Consulate**, read the stated cost and effect, and confirm to queue the decree; **Cancel** withdraws it while it is still pending. If the control is greyed out, its hint names the missing treasury, peace, or other condition. Diplomatic Expertise is the **Embassy** technology, not a Consulate requirement.

### Fleets into new sea zones

1. Open **Naval units panel**.
2. Open **Move** for a fleet that is allowed to sail (the **Home Fleet** has no **Move**).
3. In **Move fleet dialog**:
 - A fleet **in port** may only undock into an adjacent sea zone. The dialog shows **Sea zones** only.
 - A fleet **at sea** may pick an adjacent sea zone under **Sea zones**, or an owned dock. A capital dock is labelled **(capital — joins Home Fleet)**.
4. After you confirm **Next turn**, when that fleet **enters** a sea zone, the water there and the coastal land tiles that **touch that water** become **Fully visible** for you. **Inland** land in the same province stays **Unknown** until an Explorer finishes **Explore**. That is why Explorer work is still needed after a fleet arrives.

At the end of the turn, a distant sea zone’s **water** becomes **Fogged — terrain only** only when you own no adjacent coast **and** have no fleet **at sea** there (ships **in port** do not count). Tiles that are still **Unknown** stay **Unknown**. There is no fourth sight level.

Land **Move** also needs Fogged or Fully visible tiles at the start and the end. You cannot send an army into a province that is still fully Unknown.

### Tribe first contact and discovery reports

- When you first see **Tribe** land that is Fogged or Fully visible, **Tribe first contact herald** **blocks** the game once. The title is **First Contact**. The text names the tribe and the capital. Tap **Continue** to go on. Seeing only the sea next to that land does not create the relation or the herald. Each tribe heralds once per game for you this session.
- After you confirm **Next turn** and that turn finishes (including the first turn you play from turn 0), **Turn news dialog** can open. It is a **world** newspaper, not only your fog: a **Province discovered** line appears when **any** Great Power first sees that province, and province names **may appear before your map shows them**. If nothing major happened, it reads **No major events last turn.** For **your** outcomes, use the feed below.
- The news list starts **hidden**. On the map’s tab row (treasury, cargo, then the newspaper button), the news button opens **Player turn event feed** — a short list of **your** outcomes that is **replaced** each time a turn finishes. A badge on the button shows how many lines are in the list. Use it beside turn news and the fog itself (Chapter 14).

## Counsel

**Counsel.** Hark, my liege: an Explorer’s first gift is not treasure — it is the right to walk, work, and judge a province without guessing.

**Tip.** Prospect minerals before you spend Builders on improvement levels you cannot yet extract.

**Warning.** Sea-only sight of a Tribe province does not trigger first contact; you need land intel. Consulates open Minor and Tribe interiors to explore and prospect — diplomacy is the latch on the New World door.

## The other courts

Rival courts send Explorers into the same fog. When they need ore for workshops and ships, they prospect before they build. Courts that favor exploration push mines and colonies harder than cautious peers; a chosen **leader** changes how bold or cautious they are, not how you win.

## Consequences

- Leaving New World fog untouched delays colonies, mines, and land you might buy.
- Skipping **Prospect** on ore tiles wastes Builder turns on mines that cannot produce yet.
- Fleets that never leave port fail to hold distant sea visibility open.
- Without a Consulate, Explorers wait at Minor Nation and Tribe borders while rivals prospect inside.

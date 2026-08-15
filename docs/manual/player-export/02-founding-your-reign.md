# Founding Your Reign

## Purpose

Before the first Orders phase, you choose your court: which Great Power you are, who leads it, which rivals sit beside you, and whether the campaign begins at dawn (turn 0) or mid-century. Setup paints the world, auto-chooses capitals, and presents a short intro — then the map is yours. Getting this screen right shapes bonuses, AI temperaments, and how much infrastructure already exists when you take the throne.

## How it is done

### Main menu → Quick Start

1. The app shell is **Shell screen**; from it you reach **Main menu (CtMainMenu)**.
2. Tap **Quick Start** (above **New Game**). You play **England** at turn 0, with a **random** map and five AI courts. You do not open leader selection.
3. You may see a short **Game initializing** screen before the map appears. It shows coarse progress. There is no form to fill; wait until it finishes. This is the same wait as after **Start** on New Game.
4. You then reach **Game screen**. The first time you enter this new campaign, **Game start intro** may appear; dismiss it to play.

### Main menu → New Game

1. The app shell is **Shell screen**; from it you reach **Main menu (CtMainMenu)**. Tap **New Game**.
2. The menu opens **New game leader selection**. Nothing in the campaign changes until you confirm **Start**.
3. Configure slots, options, and seed as below, then **Start**. Cancel returns you to the menu without creating a game.
4. Setup runs (world generation, ownership, capitals, naming, optional advanced-start bootstrap). While waiting, **Game initializing** shows coarse progress (creating maps, building the world, saving). You may see a short 'please wait' screen before the map appears — there is no form to fill; wait until it finishes.
5. You then reach **Game screen**. The first time you enter this new campaign, **Game start intro** may appear; dismiss it to play. The app remembers that dismissal for this campaign so the intro does not loop every resume.

### Leader selection (**New game leader selection**) — step by step

Default product flow uses **six Great Power slots**. Slot **0** is the **human** slot; slots **1–5** are **AI** (the dialog does not currently expose flipping human/AI indices — that default matches setup config).

For each slot:

1. Choose the **nation** (Great Power id). Nations must be unique across slots; duplicates disable Start and highlight offending dropdowns.
2. Choose a **leader** variant for that nation. Leaders are fixed for the whole campaign (no mid-game change).
3. For **AI slots only**, optionally choose an **AI Profile**: `Normal` or a blessed profile name. Blessed profiles tune personality parameters for that GP; missing/unknown profiles fall back to normal AI at runtime.

Global options on the same dialog (when enabled by config):

- **Infinite mode** toggle — bypasses the calendar campaign halt (see Chapter 1 / 15).
- **Terrain variation** slider — affects generation knobs passed into setup.
- **Map seed** — non-zero uses that seed; zero/missing derives from time at generation.
- **Advanced start** dropdown — interactive only when the locked full-init profile is active; otherwise shown disabled. Presets: **none** (turn 0), **turns50** (~1598), **turns100** (~1698). Advanced starts bootstrap tech, economy, and (at higher tier) New World presence per .

**Start** stays disabled while any slot is empty, duplicated, or has an invalid leader variant.

### Leader bonuses (what you are choosing)

Leaders grant **land combat** modifiers only (not naval, not economy/research):

| Leader pattern | Land combat effect |
|----------------|--------------------|
| Napoleon (key/substring) | +25% melee strength |
| Frederick (key/substring) | +15% melee strength |
| Reserve / unknown | No bonus |

Both auto-resolve and quick battle apply the same lookup for attacker and defender sides.

### Capital auto-choice (what the game does for you)

After provinces are assigned, each Great Power receives an **auto-chosen capital**: a **sea-bound** province plus capital tile, with capital ports and initial roads placed per capital rules. **Current product:** there is **no** in-game UI to confirm or override that choice after setup. Minor Nations and Tribes get capitals at setup without player choice. Province and capital **names** come from the naming ruleset.

Setup places each capital tile on **plains** when the selection rules allow it — within each candidate class, plains tiles are preferred before other terrain. If the winning site is not plains (including when no plains exists among eligible candidates), setup **converts that selected tile to plains** and clears any resource or extraction improvement on it. The same plains preference and convert-if-needed rule applies to every province **town** tile (including neutral provinces without an owner): towns anchor on arable ground so roads and early extraction can grow from a predictable spine.

### Advanced start bootstrap (prospecting and development)

When you pick **turns50** or **turns100** on the locked profile, setup runs a mid-century bootstrap after world generation — tech, treasury, civilians, fleets, diplomacy, and (at 100-turn) New World colonization — before your first Orders phase.

**Bootstrap prospecting** is a dedicated setup pass that runs **after** any 100-turn NW colonization assigns ownership and **before** the improvements-and-roads pass:

1. For each Great Power, setup collects **prospect-required mineral tiles** in provinces you **own** at that moment into **one combined pool** per GP (not separate per region).
2. Setup marks a **tier fraction** of that pool as already prospected in your `playerProspectedTiles` record:
 - **turns50:** at least **50%** of prospect-required minerals in your combined **Old World owned** pool.
 - **turns100:** at least **75%** in your combined **Old World + New World owned** pool (NW minerals count only after colonization assigns those provinces to you).
3. **Minor nations** receive the same tier fraction on minerals in their **OW-owned** provinces; those entries are recorded in buyer Great Powers' prospected sets (round-robin assignment).
4. **Development** (improvement level 1 and roads on developable tiles) runs **after** prospecting so prospected minerals are eligible alongside grain, timber, wool, and other non-mineral resources.

**What this is not:**

- **NW reveal** (contiguous flood-fill visibility from the warp entry) is separate — seeing New World coasts does **not** prospect minerals for you.
- Bootstrap prospecting is **not** Explorer **prospect** work during play. Minerals you already know on owned tiles at turn 50 or 100 may have been marked at setup, not by an Explorer you trained. Chapter 4 **Charting the Unknown** covers in-game explore and prospect orders.

### Naming and identity

Places you will see in the UI are named during setup, but their **identity** remains region-scoped (`regionId|localId`). Chapter 3 explains why that matters when the overlay titles a province.

## Counsel

**Counsel.** Hark, my liege: pick a leader for the wars you expect, not for vanity — the bonus never feeds your stockpile.

**Counsel.** Hark, my liege: capitals and towns are rooted on **plains** — arable ground where grain, roads, and your first extraction spine can take hold. A fortress on barren rock is a crown without a harvest.

**Tip.** If you want a longer campaign past 1800, enable Infinite mode here; you cannot flip it mid-reign.

**Warning.** Advanced starts assume the locked full-init profile. On atypical configs the control is inert — do not assume mid-game infrastructure appeared if Start ran with advanced start disabled.

**Tip.** Do not confuse New World **visibility** with mineral **prospecting** on advanced starts — flood-fill reveal opens the map; bootstrap prospecting marks owned minerals before Builders improve them.

## The other courts

AI Great Powers receive leaders and optional blessed profiles from the same dialog. Their planners still obey the same order and diplomacy rules; profiles bias temperament and priorities , not alternate victory conditions. Fully-AI observer games are a setup tool path (empty human slot set) — the standard New Game flow keeps you as slot 0.

## Consequences

- A strong combat leader shortens some land wars and does nothing for fleets or factories.
- Advanced start compresses early exploration and tech catch-up; rivals begin closer to mid-game posture.
- Bootstrap prospecting on advanced starts means some owned minerals are already known when you take the throne — that knowledge came from setup, not from Explorer turns you issued.
- Auto-chosen capitals fix your first ports and road spine — connectivity strategy starts from that seed, not from a blank map.
- Capitals and province towns sit on **plains** tiles at setup; a converted site may have lost a surface resource that once sat on that tile.

# Founding Your Reign

## Purpose

Before the first Orders phase, you choose your court: which Great Power you are, who leads it, which rivals sit beside you, and whether the campaign begins at dawn (turn 0) or mid-century. Setup paints the world, auto-chooses capitals, and presents a short intro — then the map is yours. Getting this screen right shapes bonuses, AI temperaments, and how much infrastructure already exists when you take the throne.

## How it is done

### Main menu → New Game

1. On `SHEL10002` **Main menu**, tap **New Game**.
2. The shell opens `DLG10001` **New game leader selection** (does not mutate the live game until you confirm Start).
3. Configure slots, options, and seed as below, then **Start**. Cancel returns you to the menu without creating a game.
4. Setup runs (world generation, ownership, capitals, naming, optional advanced-start bootstrap). While waiting you may see **[DRAFT]** `SHEL30001` **Game initializing** — do not treat it as an interactive form.
5. Navigation lands on `GAME10001`. On first entry for that game id, `OVL10001` **Game start intro** may appear; dismiss it to play. The app remembers dismissal per game id so it does not loop every resume.

### Leader selection (`DLG10001`) — step by step

Default product flow uses **six Great Power slots**. Slot **0** is the **human** slot; slots **1–5** are **AI** (the dialog does not currently expose flipping human/AI indices — that default matches setup config).

For each slot:

1. Choose the **nation** (Great Power id). Nations must be unique across slots; duplicates disable Start and highlight offending dropdowns.
2. Choose a **leader** variant for that nation. Leaders are fixed for the whole campaign (no mid-game change).
3. For **AI slots only**, optionally choose an **AI Profile**: `Normal` or a blessed profile name. Blessed profiles tune personality parameters for that GP; missing/unknown profiles fall back to normal AI at runtime.

Global options on the same dialog (when enabled by config):

- **Infinite mode** toggle — bypasses the calendar campaign halt (see Chapter 1 / 15).
- **Terrain variation** slider — affects generation knobs passed into setup.
- **Map seed** — non-zero uses that seed; zero/missing derives from time at generation.
- **Advanced start** dropdown — interactive only when the locked full-init profile is active; otherwise shown disabled. Presets: **none** (turn 0), **turns50** (~1598), **turns100** (~1698). Advanced starts bootstrap tech, economy, and (at higher tier) New World presence per `SPEC/game/advanced-starts.md`.

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

### Naming and identity

Places you will see in the UI are named during setup, but their **identity** remains region-scoped (`regionId|localId`). Chapter 3 explains why that matters when the overlay titles a province.

## Counsel

**Counsel.** Hark, my liege: pick a leader for the wars you expect, not for vanity — the bonus never feeds your stockpile.

**Tip.** If you want a longer campaign past 1800, enable Infinite mode here; you cannot flip it mid-reign.

**Warning.** Advanced starts assume the locked full-init profile. On atypical configs the control is inert — do not assume mid-game infrastructure appeared if Start ran with advanced start disabled.

## The other courts

AI Great Powers receive leaders and optional blessed profiles from the same dialog. Their planners still obey the same order and diplomacy rules; profiles bias temperament and priorities (`SPEC/ai/ai-personalities.md`, `SPEC/ai/ai-profile-overrides.md`), not alternate victory conditions. Fully-AI observer games are a setup tool path (empty human slot set) — the standard New Game flow keeps you as slot 0.

## Consequences

- A strong combat leader shortens some land wars and does nothing for fleets or factories.
- Advanced start compresses early exploration and tech catch-up; rivals begin closer to mid-game posture.
- Auto-chosen capitals fix your first ports and road spine — connectivity strategy starts from that seed, not from a blank map.

## Acceptance criteria for this chapter

- [ ] Documents Main menu `SHEL10002` → New Game → `DLG10001` → setup → `GAME10001` / `OVL10001`.
- [ ] Explains human slot 0 vs AI slots, nation uniqueness, leader pick, AI profiles.
- [ ] Covers leader combat bonuses (Napoleon / Frederick / none).
- [ ] Covers advanced start presets and when the control is disabled.
- [ ] States capital is auto-chosen (sea-bound) with no post-setup override UI.
- [ ] Marks `SHEL30001` with `**[DRAFT]**` if mentioned.
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/game-setup.md`
- `SPEC/game/factions.md`
- `SPEC/game/leader-bonuses.md`
- `SPEC/game/advanced-starts.md`
- `SPEC/game/capital-choice-phase.md`
- `SPEC/game/naming.md`
- `SPEC/ui/main-menu.md`
- `SPEC/ui/new-game-leader-selection-dialog.md`
- `SPEC/ui/game-initializing.md`
- `SPEC/ui/game-start-intro-overlay.md`
- `SPEC/ui/game-screen.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/ai-personalities.md`
- `SPEC/ai/ai-profile-overrides.md`

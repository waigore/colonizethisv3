# Tribe First Contact Overlay

**Screen ID:** `OVL80001` — stable; do not reassign.
**SPEC/ui** — Blocking herald when the human GP first discovers a Tribe. Implementation: `app/lib/features/game/dialogue/tribe_first_contact_overlay.dart`.
**Widgetbook:** `Tribe First Contact Overlay` → `app/lib/widgetbook/catalog.dart`. Yarn: `tribe_first_contact` in `assets/dialogue/tribe_first_contact.yarn`. Pattern: [`game-start-intro-overlay.md`](game-start-intro-overlay.md).

---

## Trigger conditions

- **Entry:** `GameScreen` wraps content with `TribeFirstContactOverlay` when the human GP gains a new persisted GP–Tribe first-contact relation (`applyGpTribeFirstContactRelations`) and the herald for that `(gameId, tribeId)` pair has not been shown this session (`tribeFirstContactHeraldsShownProvider`).
- **Ordering:** Renders after the game-start intro (`OVL10001`) dismisses and before pending diplomacy overlays (`OVL30001`+). Multiple tribes enqueue FIFO on `tribeFirstContactHeraldQueueProvider`.
- **Sync:** `TribeFirstContactSyncListener` on `GameScreen` calls `syncGpTribeFirstContact` whenever `currentGameProvider` updates.

---

## Layout / behavior

Same chrome contract as `OVL10001`: `CtFullScreenDialogueShell` + centered `CtDialogShell`, title `tribeFirstContactOverlay_title` (`First Contact`), `CtBrassDivider`, Yarn body. Scrim uses `EditorialMonoclePalette.dialogScrim`. The Yarn body is rendered by the shared `CtDialogueLineChoiceBody` ([`ct-dialogue-view.md`](ct-dialogue-view.md) § Combined line+choice presentation), so when the `-> Continue` choice step is presented the scout narrative (with the interpolated tribe and capital names) remains visible above the confirmation control rather than appearing as an option-only step (Refs #3628).

Yarn node `tribe_first_contact` receives variables `tribeName` (Tribe `displayName`) and `capitalName` (capital province `displayName`, or local id fallback), bound via Jenny's `$`-prefixed names (`setVariable(r'$tribeName', …)`) so the asset's `{$tribeName}` / `{$capitalName}` interpolation resolves without a Jenny `NameError` (#3463). Dismissal invokes `onDismissed` once; host marks herald shown and dequeues. If the Yarn asset fails to load or run, the overlay surfaces a dismissible error using its own overlay-specific copy (`tribeFirstContactOverlay_loadError`, "Could not load first-contact dialogue: …") — not the reused intro copy (`game_intro_loadError`) of `OVL10001` — whose Continue control restores the playable game screen (never an indefinitely blocking spinner).

---

## Acceptance criteria

- **AC-4 (herald):** Given the human GP holds non-`unknown` tile visibility into a province owned by a Tribe (`discoveredTribeIdsForFirstContact`), when `syncGpTribeFirstContact` creates the persisted `AT_PEACE` / score-50 relation, then `TribeFirstContactOverlay` blocks the game screen once with interpolated Yarn text naming the tribe (`{$tribeName}`) and capital (`{$capitalName}`); dismissing does not repeat for the same `(gameId, tribeId)` in the session.
- **AC-3/AC-5 (relation):** Given contact detection, when sync runs, then `Game.diplomacyRelations` contains the GP–Tribe pair at `AT_PEACE`, score 50, Neutral — logic tests in `gp_tribe_first_contact_test.dart`.
- **AC-7 (no premature herald):** Given a new game where the GP has zero non-`unknown` New World tiles, when `syncGpTribeFirstContact` runs, then no herald appears and no GP–Tribe relation is persisted solely from sea-reachable colonial intel.
- **AC-8 (no dialogue deadlock):** Given the Yarn asset fails to load or run, when the player taps Continue, then the game screen becomes playable and the herald does not re-block input.
- **AC-9 (overlay-specific load-error copy):** Given the Yarn asset fails to load or run, when the error surface renders, then it shows the overlay-specific `tribeFirstContactOverlay_loadError` text ("Could not load first-contact dialogue: …") and never the intro overlay's `game_intro_loadError` ("Could not load intro dialogue: …") copy.
- **AC-10 (combined line+choice — #3628):** Given the `tribe_first_contact` Yarn node (a line followed by `-> Continue`), when the choice step is presented, then the scout narrative text — including the interpolated `{$tribeName}` and `{$capitalName}` — and the `Continue` `CtNinePatchButton` render together in one `CtDialogShell` body; the option does not appear without the narrative text above it.

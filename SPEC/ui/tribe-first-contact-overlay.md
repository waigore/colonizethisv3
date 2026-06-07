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

Same chrome contract as `OVL10001`: `CtFullScreenDialogueShell` + centered `CtDialogShell`, title `tribeFirstContactOverlay_title` (`First Contact`), `CtBrassDivider`, Yarn body. Scrim uses `EditorialMonoclePalette.dialogScrim`.

Yarn node `tribe_first_contact` receives variables `tribeName` (Tribe `displayName`) and `capitalName` (capital province `displayName`, or local id fallback). Dismissal invokes `onDismissed` once; host marks herald shown and dequeues.

---

## Acceptance criteria

- **AC-4 (herald):** Given first GP–Tribe contact is detected (tile visibility or colonial intel per `knownDiplomaticTargetFactionIds`), when `syncGpTribeFirstContact` creates the persisted `AT_PEACE` / score-50 relation, then `TribeFirstContactOverlay` blocks the game screen once with Yarn text naming the tribe and capital; dismissing does not repeat for the same `(gameId, tribeId)` in the session.
- **AC-3/AC-5 (relation):** Given contact detection, when sync runs, then `Game.diplomacyRelations` contains the GP–Tribe pair at `AT_PEACE`, score 50, Neutral — logic tests in `gp_tribe_first_contact_test.dart`.

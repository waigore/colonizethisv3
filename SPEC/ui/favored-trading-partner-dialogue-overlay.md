# Favored Trading Partner Dialogue Overlay

**Screen ID:** `OVL90001` — stable; do not reassign.
**SPEC/ui** — Blocking overlay when turn resolution returns pending Favored Trading Partner offers the human must Accept or Reject. No Yarn intro. Presentation: [`dialogue-presentation.md`](dialogue-presentation.md). Provider: [`pending-diplomacy-state.md`](pending-diplomacy-state.md). Host: [`game-screen.md`](game-screen.md). Chrome: [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md).
**Widgetbook:** `Favored Trading Partner Dialogue Overlay` → `widgetbook_host/lib/catalogs/catalog.dart`.
**Implementation:** `app/lib/features/game/widgets/dialogue/ftp_dialogue_overlay.dart`.

---

## Widget contract

`FtpDialogueOverlay` is a `StatefulWidget`. It wraps `child` with `CtFullScreenDialogueShell` plus centered dialog chrome.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `game` | `Game` | yes | Resolves `proposerGpId` to display names (`playerById`; raw id if missing). |
| `pending` | `List<FtpOffer>` | yes | One row per offer; order preserved on submit. |
| `onDecisions` | `void Function(List<FtpDecision>)` | yes | Called once on **Submit**; host calls `resumeFtpDecisions`. |
| `child` | `Widget` | yes | Map shell kept mounted. |

Internal: `_accept: List<bool?>` (null undecided). **Submit** disabled until every entry is non-null (`dialogueTristateAllDecided`).

---

## Trigger conditions

- **Entry:** `GameScreenOverlayStack` when `pendingDiplomacyProvider` is `PendingDiplomacyFtp` with a non-empty `offers` list. Empty list or other pending kinds do not mount this overlay.
- **Event:** `GameService` emits `FtpRequiredEvent` when resolution returns `TurnResolutionPendingFtp`.
- **Dismissal:** **Submit** only. No close control. Back does not dismiss.

---

## Layout / wireframe

```text
CtFullScreenDialogueShell
  Column
    Text(game_ftp_title)           -- accent title
    Text(game_ftp_intro)           -- muted italic
    CtBrassDivider
    ListView (shrinkWrap)
      per offer: FtpDialogueOfferRow
        Text(offerer display name) -- accent
        DialogueTristateDecisionRow (Accept / Reject)
        Accept Effect lines (muted bodySmall)
        Reject Effect line (muted bodySmall)
    Align(end) CtNinePatchButton(Submit)
```

Accept Effect lines and the Reject line come from `favoredTradingPartnerAcceptEffectLines` / `favoredTradingPartnerRejectEffectLine` in `colonizethis_diplomacy` (same first-order meaning as GAME30001 confirm; no hidden ≥ 65; no raw ids).

---

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| `pendingDiplomacyProvider` | `PendingDiplomacyFtp` non-empty | Wrap map in `FtpDialogueOverlay`. |
| Same provider | empty `offers` | Do not mount overlay. |

### User actions

| Control | When enabled | Emits / calls |
|---------|--------------|----------------|
| Accept toggle | always while overlay shown | Sets row `true` (or `null` if already on). |
| Reject toggle | always while overlay shown | Sets row `false` (or `null` if already on). |
| Submit | every row non-null | `onDecisions` with one `FtpDecision` per offer, same order (`accepted` from the row). |

---

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `OVL90001` | one offer | one `FtpOffer` | one row |
| `OVL90001` | two offers | two `FtpOffer`s | two rows; Submit gated until both decided |

---

## Components

- `CtFullScreenDialogueShell`, `CtBrassDivider`, `CtNinePatchButton`, `DialogueTristateDecisionRow`.

---

## Widgetbook

Folder `Favored Trading Partner Dialogue Overlay`. Use cases: **Default — one pending offer**; **Two pending offers**.

---

## Acceptance criteria

- Given `PendingDiplomacyFtp` with one `FtpOffer` whose proposer display name is Spain, when the overlay builds, then the UI layer shows Spain, Accept/Reject, matching first-order Effect lines (Favored Trading Partners, same-rank fills, prices do not change, does not beat First right of refusal), and Submit disabled until a choice is set.
- Given two pending offers, when Submit is tapped before both rows are decided, then `onDecisions` is not called.
- Given two pending offers with Accept then Reject chosen, when Submit is tapped, then `onDecisions` receives two `FtpDecision`s in list order with `accepted` true then false.
- Given `PendingDiplomacyFtp` with an empty offer list, when `GameScreenOverlayStack` builds, then no `FtpDialogueOverlay` is mounted.

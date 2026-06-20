# Call to Arms Dialogue Overlay

**Screen ID:** `OVL40001` — stable; do not reassign.
**SPEC/ui** — Modal blocking overlay shown when turn resolution returns one or more pending **call to arms** decisions that a human-controlled faction must accept (Join) or refuse for each of its allies before the turn can advance. The overlay has **no Yarn intro phase**: it presents the per-call list immediately. Modal presentation rules: [`dialogue-presentation.md`](dialogue-presentation.md). Source provider: [`pending-diplomacy-state.md`](pending-diplomacy-state.md). Host screen / wrap order: [`game-screen.md`](game-screen.md) § States and variants. Pixel-art chrome: [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md).

**Mockup:** [mockups/OVL40001-call-to-arms-overlay.html](mockups/OVL40001-call-to-arms-overlay.html)
---

## Widget contract

`CallToArmsDialogueOverlay` is a `StatefulWidget` (`app/lib/features/game/dialogue/call_to_arms_dialogue_overlay.dart`). It wraps an arbitrary `child` and, while the call-to-arms flow is open, paints a dim scrim plus a centered `CtDialogShell` on top of that child.

| Constructor parameter | Type | Required | Description |
|-----------------------|------|----------|-------------|
| `game` | `Game` | yes | Active game state, used to resolve `defenderGpId` and `aggressorGpId` to display names via `game.playerById(...).displayName` (falls back to the raw id if no player matches). |
| `pending` | `List<CallToArmsPending>` | yes | One or more pending call-to-arms decisions targeting the human-controlled faction's ally. The list length defines the number of Join/Refuse rows rendered and the initial size of the per-call `_join` toggle list. |
| `onDecisions` | `void Function(List<CallToArmsDecision>)` | yes | Invoked exactly once when the player taps **Submit**, with one `CallToArmsDecision` per input `CallToArmsPending`, preserving order. Consumers forward decisions to `service.resumeCallToArmsDecisions(...)`. |
| `child` | `Widget` | yes | The underlying screen content; remains mounted while the overlay is presented so host route state is preserved across the decision flow. |

Internal state ownership:

- Maintains `_join: List<bool?>` (default `null` for every entry — i.e. undecided) — one entry per pending call — toggled by the row-level Join and Refuse `CtToggleSwitch` controls. Tapping the off Join toggle sets the entry to `true`; tapping the off Refuse toggle sets it to `false`; tapping a currently-on toggle reverts the entry to `null` (undecided). Per issue #2867 R25 the Submit button stays disabled until **every** entry is non-null.
- Does **not** own a `CtDialogueView`, `DialogueRunner`, or any Yarn asset. There is no intro phase; the overlay renders the decision list as soon as it is mounted.

---

## Trigger conditions

- **Entry:** Rendered by `GameScreen` when `pendingDiplomacyProvider` exposes `PendingCallToArms(pending)` (see [`pending-diplomacy-state.md`](pending-diplomacy-state.md) and [`game-screen.md`](game-screen.md)). The notifier is replaced wholesale on each turn-resolution result, so a single overlay instance handles all calls for one resume cycle.
- **Asset load:** None. The overlay has no Yarn integration, no Jenny `DialogueRunner`, and does not call `rootBundle.loadString`. No failure path needs an error affordance.
- **Dismissal:** Exclusively driven by the player tapping **Submit**. The overlay does not provide a per-call dismiss or close button; the player must resolve every row before submitting — Submit is **disabled** while any `_join[i]` is still `null` (issue #2867 R25) and becomes enabled only after the player has tapped Join or Refuse for every pending call.

---

## Layout / wireframe

```text
+-----------------------------------------------------------+
| Stack                                                     |
|   widget.child                                            |
|   Material(color: EditorialMonoclePalette.dialogScrim)    |
|     Center                                                |
|       CtDialogShell(maxWidth: 520, maxHeight: 500)        |
|         Padding(all: 20)                                  |
|           Column(mainAxisSize: min)                       |
|             Text(game_callToArms_title)  -- accent title  |
|             Text(game_callToArms_intro)  -- muted italic  |
|             CtBrassDivider                                |
|             ListView.builder (shrinkWrap, no scroll)      |
|               Column(crossAxisAlignment: stretch)         |
|                 Text.rich(game_callToArms_prompt)         |
|                   -- defender name span: accent w600      |
|                   -- remaining war context: muted         |
|                 Wrap(alignment: end, spacing: 12)         |
|                   _LabeledToggle(Join)   -- CtToggleSwitch |
|                   _LabeledToggle(Refuse) -- CtToggleSwitch |
|             Align(centerRight)                            |
|               CtNinePatchButton(game_callToArms_submit)   |
+-----------------------------------------------------------+
```

Each row's prompt is the localized `game_callToArms_prompt(defenderName, aggressorName)` rendered as a single `Text.rich`. The calling faction name — the resolved `defenderGpId` display name (`game.playerById(...).displayName`, raw id on lookup failure) — paints in `EditorialMonoclePalette.accent` with `FontWeight.w600` (issue #2867 R24 "faction name in `--accent`"); the surrounding war context paints in `EditorialMonoclePalette.muted`. Names are resolved from `game.playerById(...)` — if the lookup fails the raw id is shown so the row never collapses to an empty string. If the resolved faction name is not a substring of the localized prompt (defensive — e.g. a future localization variant), the whole sentence falls back to `--muted`.

Per-call rows stack the prompt above an end-aligned `Wrap` of the Join + Refuse toggles (no per-row `Row` with `Expanded(prompt) + controls`). At narrow viewports the two toggles can flow onto a second run rather than overflowing horizontally, and the prompt text always has the full dialog content column width to wrap onto multiple lines (issue #2870 S8 / S10 narrow-viewport contract — see [mobile-adaptation.md](mobile-adaptation.md) § 7).

### Editorial-monocle chrome (issue #2867 R24)

Scrim is `Material(color: EditorialMonoclePalette.dialogScrim)` (canonical `--dialog-scrim` token; no `Colors.black54`). Title (`game_callToArms_title`) renders with `EditorialMonoclePalette.accent`, `FontWeight.w600`, and `letterSpacing == 0.05 * resolvedTitleFontSize` (0.05em tracks any text-scale override). Intro line (`game_callToArms_intro`) renders with `EditorialMonoclePalette.muted` color and `FontStyle.italic`. A single `CtBrassDivider` sits between the intro line and the call-row list.

Per-call Join / Refuse affordances render as two mutually exclusive `CtToggleSwitch` controls (issue #2867 R24), visually mirroring the overture overlay's Accept / Reject toggles ([`overture-dialogue-overlay.md`](overture-dialogue-overlay.md) R22): the Join toggle uses the `EditorialMonoclePalette.success` glow when active and the Refuse toggle uses the `EditorialMonoclePalette.danger` glow when active. Each toggle is paired with a colored body label (`--success` for Join, `--danger` for Refuse) inside a single tap target. The toggles are tristate-aware — tapping an off toggle commits the row to that decision (turning the other side off); tapping a currently-on toggle reverts the row to undecided (`null`) so the R25 Submit gate can re-engage. The Submit `CtNinePatchButton` and the emitted `CallToArmsDecision` contract are unchanged.

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Decision list | Overlay is mounted with `pending.length >= 1` | One Join/Refuse `CtToggleSwitch` row per `pending[i]`; every entry starts undecided (`_join[i] == null`). Tapping the off Join toggle sets `_join[i] = true`, tapping the off Refuse toggle sets `_join[i] = false`, and tapping a currently-on toggle reverts `_join[i] = null`. Submit is **disabled** while any entry is still `null` (issue #2867 R25); when every entry is non-null, Submit becomes enabled and a tap calls `onDecisions(...)` with one `CallToArmsDecision` per pending using the resolved `_join!` value. |
| Empty decision list | Overlay is mounted with `pending.length == 0` | The shell still renders the title / intro labels and a Submit button; Submit is enabled (there is no row to gate on) and tapping it invokes `onDecisions` with an empty list so the host can clear the pending provider. |

There are no loading, transient, or error variants; absence of a Yarn dependency is what differentiates this overlay from [`overture-dialogue-overlay.md`](overture-dialogue-overlay.md) and [`game-start-intro-overlay.md`](game-start-intro-overlay.md).

---

## Navigation and bus

- The overlay does **not** read or emit `AppEventBus` events directly.
- All navigation side effects flow through the `onDecisions` callback. The host (`GameScreen`) is responsible for forwarding the resulting `List<CallToArmsDecision>` to `service.resumeCallToArmsDecisions(...)` and for clearing the pending-diplomacy provider on the resulting `TurnResolutionResult` per [`pending-diplomacy-state.md`](pending-diplomacy-state.md).
- The overlay does not interact with `Navigator` for any reason: no `pushNamed`, no `pop`, no `popUntil`. The host route remains mounted; only the scrim is removed when the host clears the pending state on a successful resume.

---

## Components

- `CtFullScreenDialogueShell` ([`components/ct-full-screen-dialogue-shell.md`](components/ct-full-screen-dialogue-shell.md)) — canonical scrim + centered `CtDialogShell` scaffold reused by every blocking dialogue overlay; pins the `EditorialMonoclePalette.dialogScrim` token so individual overlays do not redeclare it (Refs #2914 S2 / S9).
- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`) — frame.
- `CtBrassDivider` (`app/lib/widgets/ct_brass_divider.dart`) — ornamental separator between the intro line and the call-row list (issue #2867 R24 dark chrome).
- `CtToggleSwitch` (`app/lib/widgets/ct_toggle_switch.dart`) — per-row Join (`--success` glow) and Refuse (`--danger` glow) two-state toggles (issue #2867 R24).
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`) — Submit button (no Material buttons in dialogue chrome).
- `EditorialMonoclePalette` (`app/lib/config/editorial_monocle_palette.dart`) tokens: `dialogScrim` (Material scrim color), `accent` (title + faction-name color), `muted` (intro + prompt color), `success` (active Join glow / label), `danger` (active Refuse glow / label).
- Localized strings via `appL10n(context)`: `game_callToArms_title`, `game_callToArms_intro`, `game_callToArms_prompt(defender, aggressor)`, `game_callToArms_join`, `game_callToArms_refuse`, and `game_callToArms_submit`.

---

## Side effects (logging)

- The overlay does not log directly; all logging is delegated to underlying widgets and the host orchestrator.

---

## Acceptance Criteria (Given–When–Then)

- Given a `CallToArmsDialogueOverlay` is mounted with exactly one pending call where `defenderGpId == 'gp_portugal'` and `aggressorGpId == 'gp_spain'` and a `Game` whose `playerById` returns players with display names `Portugal` and `Spain`,
  When the widget tree settles,
  Then the overlay renders one row inside a `CtDialogShell` whose prompt is the localized `game_callToArms_prompt('Portugal', 'Spain')`, with a Join `CtToggleSwitch`, a Refuse `CtToggleSwitch`, and a Submit `CtNinePatchButton` visible.

- Given the overlay is mounted with `n >= 1` pending calls and every `_join[i]` defaults to `null`,
  When the widget tree settles before any Join / Refuse tap,
  Then the Submit `CtNinePatchButton` reports `enabled == false` so the player cannot submit decisions that have not been made (issue #2867 R25).

- Given the overlay is mounted with two pending calls and every `_join[i]` is still `null`,
  When the user taps Join on the first row but leaves the second row undecided,
  Then the Submit `CtNinePatchButton` remains `enabled == false` and `onDecisions` has not been invoked (issue #2867 R25 negative case).

- Given the overlay is mounted with two pending calls,
  When the user taps Refuse on the first row and Join on the second row,
  Then the Submit `CtNinePatchButton` becomes `enabled == true`, tapping Submit invokes `onDecisions` exactly once with `decisions[0].accepted == false` and `decisions[1].accepted == true`, and the list order matches `pending` exactly.

- Given the overlay is mounted with `n` pending calls and every row has been resolved via Join / Refuse tap,
  When the user taps Submit once,
  Then `onDecisions` is invoked exactly once with a `List<CallToArmsDecision>` of length `n`, and each entry's `allyGpId` / `defenderGpId` / `aggressorGpId` exactly match the corresponding `pending[i]`.

- Given the overlay is constructed with an empty `pending` list,
  When the widget tree settles,
  Then the shell renders only the title / intro labels and the Submit button (no rows), and tapping Submit invokes `onDecisions` with an empty list.

- Given the overlay is mounted with one pending call whose `defenderGpId` does not correspond to any player in `game.players`,
  When the widget tree settles,
  Then the prompt row displays the raw `defenderGpId` string in the slot reserved for the defender name (no crash, no empty placeholder).

- Given the overlay is mounted in the `editorialMonocle` theme with at least one pending call,
  When the rendered widget tree is inspected,
  Then (a) the `Text` for `game_callToArms_title` resolves `color == EditorialMonoclePalette.accent`, `fontWeight == FontWeight.w600`, and `letterSpacing == 0.05 * style.fontSize`; (b) the `Text` for `game_callToArms_intro` resolves `color == EditorialMonoclePalette.muted` and `fontStyle == FontStyle.italic`; (c) exactly one `CtBrassDivider` is present, painted **below** the intro `Text` and **above** the call-row `ListView`; and (d) the overlay scrim `Material` has `color == EditorialMonoclePalette.dialogScrim` (no `Colors.black54`).

- Given the overlay is mounted in the `editorialMonocle` theme with at least one pending call,
  When the rendered widget tree is inspected,
  Then each call row exposes exactly one Join `CtToggleSwitch` (keyed `callToArmsJoinToggle_<i>`) configured with `onGlowColor == EditorialMonoclePalette.success` and one Refuse `CtToggleSwitch` (keyed `callToArmsRefuseToggle_<i>`) configured with `onGlowColor == EditorialMonoclePalette.danger`, and the prompt `Text.rich` (keyed `callToArmsPrompt`) contains a child span whose text equals the resolved defender display name and whose `style.color == EditorialMonoclePalette.accent`.

- Given the overlay is mounted with one pending call and the row is undecided (`_join[0] == null`),
  When the user taps the Join toggle and then taps the Join toggle a second time,
  Then after the first tap the Join toggle reports `value == true` and Submit is `enabled == true`, and after the second tap the row reverts to undecided (`_join[0] == null`), the Join toggle reports `value == false`, and Submit returns to `enabled == false` (issue #2867 R24 tristate / R25 gate re-engages).

- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when the overlay is mounted with one or two pending calls against the three-GP `Game` fixture (`gp_player` / `gp_portugal` / `gp_spain`), then `WidgetTester.takeException()` returns `null`, the `Call to arms` title renders, every pending row mounts a Join + Refuse `CtToggleSwitch` pair (with their `Join` / `Refuse` labels) end-aligned via the per-row `Wrap`, and the trailing `Submit` `CtNinePatchButton` renders (the per-call `Column(Text + Text + Wrap(Join + Refuse))` from § Layout / wireframe must wrap within the ~288 dp `CtDialogShell` content column without horizontal overflow per [mobile-adaptation.md](mobile-adaptation.md) § 7).

---

## Widgetbook

Catalog directory: `Call to Arms Dialogue Overlay` (registered in `app/lib/widgetbook/catalog.dart` via `callToArmsDialogueOverlayDirectories` in `catalog_part4.dart`). Required use cases:

1. **Default — two pending calls** — wraps a localized `widgetbook_gameShell` child in `CallToArmsDialogueOverlay` with a small in-memory `Game` and two `CallToArmsPending` entries from different aggressor / defender combinations. The story exercises Join/Refuse toggles and the Submit button across two rows.

The story analyzes cleanly with no hardcoded UI strings: title, intro, prompt, Join, Refuse, and Submit labels are sourced from `appL10n(context)`.

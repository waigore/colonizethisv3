# Game Start Intro Overlay

**SPEC/ui** — Modal blocking overlay shown the **first time** a player enters a freshly created game (or one whose intro has not yet been dismissed for the active session). Plays the archaic-language `game_start_intro` Yarn node via [`CtDialogueView`](ct-dialogue-view.md). Lifecycle / Yarn first-emission contract: [`dialogue-management.md`](../ai/dialogue-management.md) § First dialogue emission point. Modal presentation rules: [`dialogue-presentation.md`](dialogue-presentation.md). Host screen / wrap order: [`game-screen.md`](game-screen.md) § States and variants. Pixel-art chrome: [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md). Asset constant: `kDialogueGameIntroAsset` in `app/lib/config/app_constants.dart`.

---

## Widget contract

`GameStartIntroOverlay` is a `StatefulWidget` (`app/lib/features/game/dialogue/game_start_intro_overlay.dart`). It wraps an arbitrary `child` and, while the intro dialogue is running, paints a dim scrim plus a centered `CtDialogShell` on top of that child.

| Constructor parameter | Type | Required | Description |
|-----------------------|------|----------|-------------|
| `onDismissed` | `VoidCallback` | yes | Invoked exactly once after the Yarn node finishes successfully **or** after the player taps Continue on the error affordance. Consumers use this to mark the game id shown via `gameIdsWithIntroShownProvider` (per [`game-screen.md`](game-screen.md)). |
| `child` | `Widget` | yes | The underlying screen content; remains mounted at all times so the host route's state is preserved when the overlay dismisses. |
| `logger` | `CtLogger?` | no | Optional logger override; defaults to `packageLogger('dialogue')`. |
| `assetBundle` | `AssetBundle?` | no | Test seam for loading `kDialogueGameIntroAsset`; defaults to `rootBundle` so production code reads the bundled Yarn file. |

Internal state ownership:

- Owns one `CtDialogueView` and one `jenny.DialogueRunner`.
- Reads the Yarn source from `kDialogueGameIntroAsset` (`assets/dialogue/game_intro.yarn`) and parses it into a `YarnProject`.
- Hard-codes the intro node id `game_start_intro`; throws a `StateError` (caught and surfaced as `_loadError`) when the node is missing from the parsed asset.

---

## Trigger conditions

- **Entry:** Wrapped around `GameScreen`'s content when `currentGameProvider != null` and `gameIdsWithIntroShownProvider` does **not** contain `game.id` (see [`game-screen.md`](game-screen.md) § States and variants — *Intro overlay*).
- **Asset load:** During `initState`, the widget starts an async `_loadAndRun()` flow that (1) emits an `intro.asset_load.begin` perf marker, (2) loads the Yarn asset text, (3) parses the `YarnProject`, (4) emits an `intro.asset_load.end` perf marker, (5) constructs the `CtDialogueView`, (6) starts the `DialogueRunner` on `game_start_intro`, and (7) emits an `intro.dialogue_begin` perf marker.
- **First-line marker:** The first time the view fires `onStateChanged(line, _)` with a non-null `line`, the widget emits `intro.first_line` exactly once (logged via `game_intro first_line_shown`).
- **Dismissal:** When `runner.startDialogue` completes (the node naturally ends), the widget sets `_dialogueFinished = true` and invokes `widget.onDismissed`. When loading or running throws, the widget surfaces a minimal error affordance and `widget.onDismissed` is invoked when the player taps Continue.

The overlay is meant to be **single-shot per game id per session**: once the host marks the id via `gameIdsWithIntroShownProvider`, the host stops wrapping and the overlay is unmounted on the next build.

---

## Layout / wireframe

```text
+----------------------------------------------+
| Stack                                        |
|   widget.child                               |
|   Material(color: Colors.black54)            |
|     Center                                   |
|       CtDialogShell(maxWidth: 520)           |
|         Padding(all: 20)                     |
|           Column(mainAxisSize: min)          |
|             -- presenting line --            |
|             Text(line.text, bodyMedium)      |
|             SizedBox(height: 16)             |
|             Align(centerRight)               |
|               CtNinePatchButton(Continue)    |
|             -- presenting choice --          |
|             ListView of                      |
|               CtNinePatchButton(option.text) |
|             -- transient / loading --        |
|             GameStartIntroLoadingIndicator   |
+----------------------------------------------+
```

Error mode renders the same `Stack` but the `CtDialogShell` body is the localized error message (`l10n.game_intro_loadError`) plus a single Continue button (`l10n.game_intervention_continue`).

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Loading | `_view == null && _runner == null && _loadError == null` | `Stack` with `widget.child`, scrim, and `GameStartIntroLoadingIndicator` inside `CtDialogShell`. |
| Presenting line | `_view!.currentLine != null` | Line text + right-aligned Continue button (`l10n.game_intervention_continue`); tap calls `_view!.advanceLine()`. |
| Presenting choice | `_view!.currentLine == null && _view!.currentChoice != null` | Vertical stack of one `CtNinePatchButton` per `choice.options[i]`; tap calls `_view!.selectOption(i)`. |
| Transient between Jenny events | Both `currentLine` and `currentChoice` are `null` while `_dialogueFinished == false` | Loading indicator inside the shell. |
| Error | `_loadError != null` | Localized error text + Continue button; tapping Continue clears `_loadError` and invokes `widget.onDismissed` so the host advances even when the Yarn asset is broken. |
| Dismissed | `_dialogueFinished == true` **or** `_view == null && _runner == null` after error-Continue | Renders `widget.child` only — no scrim, no shell. |

---

## Navigation and bus

- The overlay does **not** read or emit `AppEventBus` events directly.
- All navigation side effects flow through the `onDismissed` callback supplied by [`game-screen.md`](game-screen.md). The host owns the `gameIdsWithIntroShownProvider.notifier.markShown` call; this widget only signals completion.
- The overlay does not interact with `Navigator` for any reason: no `pushNamed`, no `pop`, no `popUntil`. The host route remains mounted; only the scrim is removed when the overlay dismisses.

---

## Components

- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`) — frame.
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`) — Continue and option buttons (no Material buttons in dialogue chrome).
- `CtLoadingIndicator` (`app/lib/widgets/ct_loading_indicator.dart`) — wrapped as `GameStartIntroLoadingIndicator` so the catalog can story it without re-importing the shared widget.
- `CtDialogueView` ([`ct-dialogue-view.md`](ct-dialogue-view.md)) — the Jenny adapter that owns Line / Choice state.
- `jenny.DialogueRunner` — Jenny's runner; receives the single `CtDialogueView` in `dialogueViews:`.
- Localized strings via `appL10n(context).game_intervention_continue` and `appL10n(context).game_intro_loadError(...)`.

---

## Side effects (perf and logging)

- Perf markers (in order, per successful run): `intro.asset_load.begin`, `intro.asset_load.end`, `intro.dialogue_begin`, `intro.first_line` (only on the first non-null line state-change).
- Logger prefix: `dialogue` via `packageLogger('dialogue')` unless the caller injects a `CtLogger`. Failures are logged with `level == error` and include the original exception plus stack trace.

---

## Acceptance Criteria (Given–When–Then)

- Given a `GameStartIntroOverlay` is mounted with a Yarn `AssetBundle` that contains `game_start_intro` with one line and one option,
  When the widget tree settles after `initState`,
  Then the overlay first renders the `Stack` with the dim scrim and the loading indicator, then renders the line text inside a `CtDialogShell`, then renders the option button(s), and finally — after `selectOption(0)` — calls `widget.onDismissed` exactly once.

- Given the overlay is presenting a Yarn line,
  When the user taps the Continue `CtNinePatchButton`,
  Then `CtDialogueView.advanceLine()` is invoked exactly once and the dialogue advances to the next Jenny event (line, choice, or finish).

- Given the overlay is presenting a Yarn choice with `n >= 2` options,
  When the user taps the `i`-th option button,
  Then `CtDialogueView.selectOption(i)` is invoked exactly once with the same index and the dialogue advances to the next Jenny event.

- Given the overlay has just been mounted and the Yarn `AssetBundle` resolves `kDialogueGameIntroAsset` to text that does not declare a `game_start_intro` node,
  When `_loadAndRun` reaches the node existence check,
  Then the widget catches a `StateError`, sets `_loadError`, and renders the error `CtDialogShell` with a localized error message and a single Continue button.

- Given the overlay is in the error state,
  When the user taps the error-state Continue button,
  Then `widget.onDismissed` is invoked exactly once and the scrim/shell are unmounted on the next build so `widget.child` is visible.

- Given the overlay has finished playing the intro Yarn node,
  When `runner.startDialogue` resolves,
  Then `_dialogueFinished` is set to `true`, `widget.onDismissed` is invoked exactly once, and subsequent builds render `widget.child` directly with no scrim or shell.

- Given the overlay is mounted with a custom `CtLogger`,
  When the widget logs any of the load / first-line / failure messages,
  Then the messages are emitted via the injected logger only; `package_logger.packageLogger('dialogue')` is not invoked.

- Given the overlay's `widget.child` is a `KeyedSubtree` whose key persists across rebuilds,
  When the overlay transitions from presenting-line to dismissed,
  Then the `KeyedSubtree` is **not** remounted (the child remains in the tree the whole time and host state is preserved).

---

## Widgetbook

Catalog directory: `Game Start Intro Overlay` (registered in `app/lib/widgetbook/catalog.dart` via `gameStartIntroOverlayDirectories` in `catalog_part3.dart`). Required use cases:

1. **Default — single-line intro** — wraps an inline placeholder child in `GameStartIntroOverlay` using a stub `AssetBundle` that returns a minimal Yarn document (one line, one Continue option) for `kDialogueGameIntroAsset`. The story exercises the loading → presenting-line → dismissed transitions without depending on the production asset path.

The story analyzes cleanly with no hardcoded UI strings on user-facing chrome (Continue / error messages come from `appL10n`).

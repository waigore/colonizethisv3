# CtDialogueView (Flutter / Jenny adapter)

**SPEC/ui** — Non-visual Flutter adapter that bridges Jenny's `DialogueRunner` to the app's dialogue overlay widgets. Single source of truth for **how the app drives Jenny-managed lines and choices** from Flutter UI state. Modal / overlay rules: [`dialogue-presentation.md`](dialogue-presentation.md). Yarn content map: [`dialogue-content-and-yarn.md`](../ai/dialogue-content-and-yarn.md). System contract: [`dialogue-system.md`](../program/dialogue-system.md). Consuming overlays: [`game-start-intro-overlay.md`](game-start-intro-overlay.md), [`screens/pending-intervention-overlay.md`](screens/pending-intervention-overlay.md), [`pending-diplomacy-state.md`](pending-diplomacy-state.md).

---

## Widget contract

`CtDialogueView` is a `DialogueView` subclass (`app/lib/features/game/dialogue/ct_dialogue_view.dart`). It is **not** a Flutter widget — it produces no UI by itself. Consumer widgets construct a `CtDialogueView`, register it with a `DialogueRunner`, and rebuild whenever the view's `onStateChanged` callback fires.

| Constructor parameter | Type | Default | Description |
|-----------------------|------|---------|-------------|
| `logger` | `CtLogger?` | `packageLogger('dialogue')` | Optional logger override; tests inject deterministic loggers. |

| Public API | Type | Used by | Behaviour |
|------------|------|---------|-----------|
| `currentLine` | `DialogueLine?` | UI build | Non-null exactly while a line is awaiting `advanceLine()`. |
| `currentChoice` | `DialogueChoice?` | UI build | Non-null exactly while a choice is awaiting `selectOption(...)`. |
| `onStateChanged` | `void Function(DialogueLine?, DialogueChoice?)?` | Consumer | Invoked once per state transition (line shown, choice shown, line/choice cleared, dialogue finished). |
| `advanceLine()` | `void` | Consumer | Completes the line completer at most once; no-op when no line is pending. |
| `selectOption(int index)` | `void` | Consumer | Completes the choice completer with `index` at most once; no-op when no choice is pending. |

Idempotency is guaranteed: `advanceLine` / `selectOption` are safe to call after completion (each clears its completer on first use; a second call short-circuits to a no-op rather than throwing).

---

## Trigger conditions

- **Construction:** Created by a consumer overlay during `initState` (or equivalent), then passed in the `dialogueViews:` list of a `jenny.DialogueRunner`.
- **Lifecycle:** `onDialogueStart`, `onLineStart`, `onChoiceStart`, `onDialogueFinish` are invoked by Jenny as the runner walks a Yarn node. No direct user input is wired into the view; consumers wire UI buttons to `advanceLine` / `selectOption`.
- **Termination:** When `onDialogueFinish` fires, the view nulls `currentLine`, `currentChoice`, and both completers, then notifies the consumer one last time so the UI can transition out.

---

## States and variants

| State | When | `currentLine` | `currentChoice` | UI render expectation |
|-------|------|----------------|-----------------|------------------------|
| Idle | Before `onDialogueStart`, after `onDialogueFinish`, or while consumers are between transitions | `null` | `null` | Loading indicator or pass-through child. |
| Presenting line | Inside `onLineStart` until `advanceLine` resolves the line completer | the active `DialogueLine` | `null` | Show `line.text` plus a single Continue affordance. |
| Presenting choice | Inside `onChoiceStart` until `selectOption(i)` resolves the choice completer | `null` | the active `DialogueChoice` | Show `choice.options[i].text` for each option as separate buttons. |
| Transient between line and choice | Brief moment after `advanceLine` returns and before Jenny dispatches the next event | `null` | `null` | Loading indicator. |

Exactly one of `currentLine` / `currentChoice` is non-null at any time; consumers must treat the pair as mutually exclusive when rendering.

---

## Side effects (logging)

- `onLineStart` logs `dialogue` at debug level with the line text.
- `onChoiceStart` logs `dialogue` at debug level with the option count.
- `onDialogueStart` / `onDialogueFinish` log `dialogue` at debug level.

Logging follows the [logging core principle](../program/logging/logging.md): no `print`, prefix `dialogue:` via `CtLogger`, and the injected logger is honoured so tests can suppress output.

---

## Acceptance Criteria (Given–When–Then)

- Given a `CtDialogueView` is freshly constructed,
  When the consumer reads `currentLine` and `currentChoice`,
  Then both values are `null` and neither completer has been allocated.

- Given a `CtDialogueView` is registered on a `DialogueRunner` that starts a node whose first event is a Yarn line `L`,
  When `onLineStart(L)` is invoked,
  Then the view sets `currentLine == L`, `currentChoice == null`, allocates the line completer, and invokes `onStateChanged(L, null)` exactly once.

- Given the view is presenting line `L` and `onLineStart` is awaiting the line completer,
  When the consumer calls `advanceLine()`,
  Then the line completer completes exactly once, the view clears `currentLine` to `null`, and invokes `onStateChanged(null, null)` exactly once.

- Given the view is idle (no pending line or choice),
  When the consumer calls `advanceLine()`,
  Then no completer is allocated, no exception is thrown, and `onStateChanged` is not invoked.

- Given the view is presenting line `L`,
  When the consumer calls `advanceLine()` twice in succession,
  Then the line completer completes exactly once (the second call is a no-op) and no `StateError` from `Completer.complete()` is thrown.

- Given a `CtDialogueView` is registered on a `DialogueRunner` whose next event is a Yarn choice `C` with `C.options.length == n`,
  When `onChoiceStart(C)` is invoked,
  Then the view sets `currentChoice == C`, `currentLine == null`, allocates the choice completer, and invokes `onStateChanged(null, C)` exactly once.

- Given the view is presenting choice `C` and `onChoiceStart` is awaiting the choice completer,
  When the consumer calls `selectOption(i)` with `0 <= i < C.options.length`,
  Then the choice completer completes with `i`, the view clears `currentChoice` to `null`, and invokes `onStateChanged(null, null)` exactly once.

- Given the view is presenting choice `C`,
  When the consumer calls `selectOption(i)` twice in succession,
  Then the choice completer completes exactly once (the second call is a no-op) and no `StateError` from `Completer.complete()` is thrown.

- Given a `CtDialogueView` has just emitted `currentLine == null` and `currentChoice == null` after a line transition,
  When the runner invokes `onDialogueFinish`,
  Then the view clears both completers to `null` and invokes `onStateChanged(null, null)` exactly once more so the consumer can dismiss the overlay.

- Given a custom `CtLogger` is passed to the constructor,
  When the view processes any of `onDialogueStart`, `onLineStart`, `onChoiceStart`, or `onDialogueFinish`,
  Then the injected logger receives all `dialogue:` debug messages (no `print` is emitted) and the default `packageLogger('dialogue')` is not constructed.

---

## Widgetbook

Catalog directory: `Dialogue Engine` (registered in `app/lib/widgetbook/catalog.dart` via `ctDialogueViewDirectories` in `catalog_part3.dart`). Required use cases:

1. **Lines and choice trace** — runs a small inline Yarn snippet (two lines + one choice) under a `CtDialogueView`, renders the live `currentLine` / `currentChoice` next to manual **Advance** and **Select option** buttons. The story acts as the canonical visual probe for the state machine described above and lets reviewers exercise both `advanceLine` and `selectOption` without loading any real Yarn assets from disk.

The story analyzes cleanly with no hardcoded UI strings on user-facing chrome (button labels for option text are sourced from the inline Yarn node so the catalog matches what Jenny renders at runtime).

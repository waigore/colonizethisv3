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
| `contextLine` | `DialogueLine?` | UI build | The **immediately preceding** narrative line, retained from `onLineStart` through the transient null state after `advanceLine()` **and** through the subsequent choice. Cleared to `null` only when a choice resolves (`selectOption`) or the dialogue finishes. Lets consumers keep the message visible above option buttons (see § Combined line+choice presentation). Refs #3628. |
| `onStateChanged` | `void Function(DialogueLine?, DialogueChoice?)?` | Consumer | Invoked once per state transition (line shown, choice shown, line/choice cleared, dialogue finished). Carries `currentLine` / `currentChoice` only; consumers read `contextLine` from the view when rebuilding. |
| `advanceLine()` | `void` | Consumer | Completes the line completer at most once; no-op when no line is pending. Retains `contextLine`. |
| `selectOption(int index)` | `void` | Consumer | Completes the choice completer with `index` at most once; no-op when no choice is pending. Clears `contextLine`. |

Idempotency is guaranteed: `advanceLine` / `selectOption` are safe to call after completion (each clears its completer on first use; a second call short-circuits to a no-op rather than throwing).

---

## Trigger conditions

- **Construction:** Created by a consumer overlay during `initState` (or equivalent), then passed in the `dialogueViews:` list of a `jenny.DialogueRunner`.
- **Lifecycle:** `onDialogueStart`, `onLineStart`, `onChoiceStart`, `onDialogueFinish` are invoked by Jenny as the runner walks a Yarn node. No direct user input is wired into the view; consumers wire UI buttons to `advanceLine` / `selectOption`.
- **Termination:** When `onDialogueFinish` fires, the view nulls `currentLine`, `currentChoice`, and both completers, then notifies the consumer one last time so the UI can transition out.

---

## States and variants

| State | When | `currentLine` | `currentChoice` | `contextLine` | UI render expectation |
|-------|------|----------------|-----------------|----------------|------------------------|
| Idle | Before `onDialogueStart`, after `onDialogueFinish`, or while consumers are between transitions | `null` | `null` | `null` | Loading indicator or pass-through child. |
| Presenting line | Inside `onLineStart` until `advanceLine` resolves the line completer | the active `DialogueLine` | `null` | same as `currentLine` | Show `line.text` plus a single Continue affordance. |
| Presenting choice | Inside `onChoiceStart` until `selectOption(i)` resolves the choice completer | `null` | the active `DialogueChoice` | the immediately preceding line (or `null` if the node opened with a choice) | Show the retained `contextLine.text` (when non-null) **above** the option buttons, so the narrative message and the option(s) render together. |
| Transient between line and choice | Brief moment after `advanceLine` returns and before Jenny dispatches the next event | `null` | `null` | the immediately preceding line | Keep the `contextLine.text` visible above a loading indicator (no message-only flash before the choice appears). |

Exactly one of `currentLine` / `currentChoice` is non-null at any time; consumers must treat that pair as mutually exclusive when choosing the active affordance, but `contextLine` is **orthogonal** — it remains set across the line→choice boundary so the message stays on screen.

### Combined line+choice presentation (Refs #3628)

Yarn nodes in this app model narrative as a `line` event followed by a `-> option` `choice` event. Rendering those two events in mutually exclusive branches dropped the message the instant the choice appeared (a message-only step followed by an option-only step). `contextLine` fixes this systemically:

- `onLineStart(L)` sets `contextLine = L` (alongside `currentLine = L`).
- `advanceLine()` clears `currentLine` but **retains** `contextLine = L`.
- `onChoiceStart(C)` sets `currentChoice = C` while **retaining** `contextLine = L`; consumers render `L.text` above `C`'s option buttons.
- `selectOption(i)` clears both `currentChoice` and `contextLine`.
- A later `onLineStart(L2)` overwrites `contextLine = L2`, so only the line **immediately** preceding a choice accompanies it (earlier lines in a multi-line node do not linger).
- `onDialogueFinish` clears `contextLine`.

The shared widget `CtDialogueLineChoiceBody` (`app/lib/features/game/dialogue/ct_dialogue_line_choice_body.dart`) encapsulates this render contract for all blocking dialogue overlays.

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

- Given a `CtDialogueView` is presenting line `L` (`onLineStart(L)` invoked),
  When the consumer reads `contextLine`,
  Then `contextLine == L` (equal to `currentLine`).

- Given the view was presenting line `L` and the consumer calls `advanceLine()`,
  When the consumer reads the view state after the line completer resolves and before the next Jenny event,
  Then `currentLine == null`, `currentChoice == null`, and `contextLine == L` (the message is retained for the transient).

- Given the view presented line `L` and then `onChoiceStart(C)` is invoked,
  When the consumer reads the view state,
  Then `currentChoice == C`, `currentLine == null`, and `contextLine == L`, so the consumer can render `L.text` above `C`'s options.

- Given the view is presenting choice `C` with retained `contextLine == L`,
  When the consumer calls `selectOption(i)` with `0 <= i < C.options.length`,
  Then the choice completer completes with `i`, `currentChoice` clears to `null`, and `contextLine` clears to `null`.

- Given the view presented line `L1`, advanced it, and then `onLineStart(L2)` is invoked,
  When the consumer reads `contextLine`,
  Then `contextLine == L2` (the most recent line overwrites the previous), so a multi-line node shows only the line immediately preceding a choice.

- Given a `CtDialogueView` has just emitted `currentLine == null` and `currentChoice == null` after a line transition,
  When the runner invokes `onDialogueFinish`,
  Then the view clears both completers and `contextLine` to `null` and invokes `onStateChanged(null, null)` exactly once more so the consumer can dismiss the overlay.

- Given a custom `CtLogger` is passed to the constructor,
  When the view processes any of `onDialogueStart`, `onLineStart`, `onChoiceStart`, or `onDialogueFinish`,
  Then the injected logger receives all `dialogue:` debug messages (no `print` is emitted) and the default `packageLogger('dialogue')` is not constructed.

---

## Widgetbook

Catalog directory: `Dialogue Engine` (registered in `app/lib/widgetbook/catalog.dart` via `ctDialogueViewDirectories` in `catalog_part4.dart`). Required use cases:

1. **Lines and choice trace** — runs a small inline Yarn snippet (two lines + one choice) under a `CtDialogueView`, renders the live `currentLine` / `currentChoice` next to manual **Advance** and **Select option** buttons. When a choice is active the probe also renders the retained `contextLine.text` above the option buttons, mirroring the combined line+choice contract (Refs #3628). The story acts as the canonical visual probe for the state machine described above and lets reviewers exercise both `advanceLine` and `selectOption` without loading any real Yarn assets from disk.

The story analyzes cleanly with no hardcoded UI strings on user-facing chrome (button labels for option text are sourced from the inline Yarn node so the catalog matches what Jenny renders at runtime).

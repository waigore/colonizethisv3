# Game Screen

**Screen ID:** `GAME10001` — stable; do not reassign.
**SPEC/ui** — In-game host screen for the Flutter app. Lives at `Routes.game` and orchestrates the map / Flame canvas, the next-turn flow, the pause menu, the Victory overlay, the intro dialogue, and the pending diplomacy overlays. Source of truth for the in-game shell layout (region tabs, map widget, sidebars): [`empire-overview.md`](empire-overview.md). The Game Screen widget itself is the **router** that decides which content is mounted; this spec covers that contract. Bus wiring: [`app-ui-wiring.md`](../program/app-ui-wiring.md). Bus events: [`app-event-bus.md`](../program/app-event-bus.md). Turn resolution: [`turn-resolution.md`](../program/turn-resolution.md), [`next-turn-confirmation.md`](next-turn-confirmation.md). Victory: [`victory.md`](../game/victory.md). Routes: `app/lib/config/routes.dart`.

---

## Widget contract

`GameScreen` is a `ConsumerWidget` (`app/lib/features/game/flame/game_screen.dart`). It takes no constructor parameters; all state comes from Riverpod providers.

| Provider | Read mode | Used for |
|----------|-----------|----------|
| `currentGameProvider` | `watch` | Active `Game?`; `null` falls through to the default Flame canvas branch. |
| `mapViewDataProvider` | `watch` | When non-null, mount [`GameMapArea`](empire-overview.md) instead of `GameWidget`. |
| `gameIdsWithIntroShownProvider` | `watch` | Set of ids whose [intro overlay](#intro-overlay) has been dismissed. |
| `pendingDiplomacyProvider` | `watch` | Three-way pending state (overtures / interventions / call-to-arms) wrapping the screen with the matching overlay. |
| `turnResolutionBlockingProvider` | `watch` | While `true`, the Next turn button is disabled and bus-driven dialog opens are gated per [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Turn resolution in progress. |
| `appEventBusProvider` | `read` | For pause-menu emit and the Android-back exit confirm flow. |
| `gameServiceProvider`, `turnResolutionRunnerProvider`, `currentOrdersProvider` | `read` | Used by the next-turn handler and pending-diplomacy resume callbacks. |

The widget is wrapped in a `PopScope(canPop: false)` so the system back gesture is intercepted and shows the Exit-to-Main-Menu confirm dialog.

---

## Trigger conditions

- **Entry:** `Routes.game` (`/game`) per `app/lib/config/routes.dart`. Pushed via `NavigateToRouteEvent(Routes.game)` from [`shell-screen.md`](shell-screen.md) (New Game / Resume game / Load game) and from the new-game setup flow.
- **Bus gating:** While `turnResolutionBlockingProvider == true`, only `OpenPauseMenuPanelEvent` and `ClosePanelEvent` may open per [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Turn resolution in progress. The screen wires the pause button to that gate (see ACs).
- **Lifecycle:** The screen is destroyed when `NavigateToShellEvent` triggers a pop back to `Routes.shell`; pending in-memory state is cleared by the bus handler, not by this widget.

---

## Layout / wireframe

```text
+--------------------------------------------------------------+
| CtScreenShell (title: gameScreenTitle)                       |
| PopScope (canPop: false; intercepts Android back)            |
|                                                              |
|  -- pending diplomacy wrapper (when set) --                  |
|  OvertureDialogueOverlay      |                              |
|  InterventionDialogueOverlay  | (mutually exclusive)         |
|  CallToArmsDialogueOverlay    |                              |
|                                                              |
|  -- intro wrapper (when not yet shown) --                    |
|  GameStartIntroOverlay (onDismissed: mark shown)             |
|                                                              |
|  -- bus listener wrapper (when game != null) --              |
|  GameToUIBusListener(gameId)                                 |
|                                                              |
|  -- core stack --                                            |
|  Stack:                                                      |
|    if mapViewData != null && game != null                    |
|       GameMapArea(game, mapViewData)                         |
|    else                                                      |
|       GameWidget(ColonizeThisGame())                         |
|                                                              |
|    if showOverlayButtons (game != null && victory == null    |
|                            && mapViewData == null):          |
|       Positioned(left:16,top:16) IconButton(menu) -> pause   |
|       Positioned(right:16,top:16) CtNinePatchButton          |
|         label: game_nextTurnButton(turn, year)               |
|         enabled: !blocking && allowsFullTurnResolution(game) |
|                                                              |
|    if game != null && victory != null:                       |
|       VictoryOverlay(game, victory, bus)                     |
+--------------------------------------------------------------+
```

The screen never paints chrome around the map / Flame canvas itself; layout for that surface is governed by [`empire-overview.md`](empire-overview.md) (region tabs, sidebars, treasury indicator, minimap).

---

## States and variants

| State | Trigger condition | Render |
|-------|------------------|--------|
| Map view (default) | `mapViewData != null && game != null` | `GameMapArea(game, mapViewData)` plus pause + Next turn overlays unless suppressed. |
| Flame canvas (legacy / fallback) | `mapViewData == null` | `GameWidget(ColonizeThisGame())` plus pause + Next turn overlays unless suppressed. |
| Victory | `game != null && victory != null` | Map / Flame remains mounted; pause and Next turn buttons are **hidden** (`showOverlayButtons == false`); [`victory-overlay.md`](victory-overlay.md) `VictoryOverlay` is stacked on top. |
| Intro overlay | `game != null && !introShownIds.contains(game.id)` | The whole screen is wrapped in `GameStartIntroOverlay`; dismissing marks the id shown via `gameIdsWithIntroShownProvider.notifier.markShown`. |
| Pending overtures | `pendingDiplomacy is PendingDiplomacyOvertures && offers.isNotEmpty` | Wraps the content in `OvertureDialogueOverlay`; `onDecisions` invokes `gameServiceProvider.resumeOvertureDecisions` and applies the result via `applyTurnResolutionResult(ref, result)`. |
| Pending interventions | `pendingDiplomacy is PendingDiplomacyIntervention && prompts.isNotEmpty` | Wraps the content in `InterventionDialogueOverlay`; `onDecisions` invokes `gameServiceProvider.resumeInterventionDecisions`. |
| Pending call-to-arms | `pendingDiplomacy is PendingDiplomacyCallToArms && pending.isNotEmpty` | Wraps the content in `CallToArmsDialogueOverlay`; `onDecisions` invokes `gameServiceProvider.resumeCallToArmsDecisions`. |
| Turn resolution in progress | `turnResolutionBlockingProvider == true` | Next turn button is disabled (`onPressed == null`); the pause button still works (allowed gating); per [`app-ui-wiring.md`](../program/app-ui-wiring.md) the Processing Turn dialog is shown by the next-turn handler, not this widget. |
| Exit confirm | Android back / `PopScope.onPopInvoked` | Local `showDialog` (`useRootNavigator: true`) opens the Exit-to-Main-Menu `CtDialogShell`; on confirm the screen emits `NavigateToShellEvent`. |

The pending-diplomacy variants are mutually exclusive — exactly one wrapper is used per build pass, matching the `switch` order: overtures, interventions, call-to-arms.

---

## Navigation

- **Entry:** `NavigateToRouteEvent(Routes.game)` from [`shell-screen.md`](shell-screen.md) or the setup flow.
- **Pause menu:** Emit `OpenPauseMenuPanelEvent` (handled by `AppEventHandlerScope` per [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Typed panel events). Allowed even while `turnResolutionBlockingProvider == true`.
- **Next turn:** Tapping Next turn runs the local in-screen flow `_runFlameCanvasNextTurn` (defined in `game_screen.dart`):
  1. Open `NextTurnConfirmationDialog` (root navigator). On cancel: return.
  2. Set `turnResolutionBlockingProvider == true` and show `TurnResolutionProcessingDialog` (root navigator) with a `phaseNotifier`.
  3. Run `turnResolutionRunnerProvider.startResolution(...)` and listen for progress events; update the phase notifier.
  4. On `TurnResolutionTerminalComplete`: dismiss the processing dialog, call `gameServiceProvider.handleExternallyResolvedTurnResult`, optionally export turn trace, and apply via `applyTurnResolutionResult(ref, result)`.
  5. On `TurnResolutionTerminalError`: show a snackbar with the localized failure message and rethrow.
  6. Always: clear the blocking flag, cancel the progress subscription, and dispose the phase notifier on the next frame.
  Behaviour during failures and trace export must keep the contract in [`turn-resolution.md`](../program/turn-resolution.md) and [`logging/turn-resolution.md`](../program/logging/turn-resolution.md).
- **Exit to main menu:** The `PopScope` callback opens a local exit confirm dialog. On confirm, emit `NavigateToShellEvent`; the bus handler pops back to `Routes.shell` per [`app-ui-wiring.md`](../program/app-ui-wiring.md). The screen does not call `Navigator.popUntil` directly.
- **Debug log route:** Reached via `NavigateToRouteEvent(Routes.debugLog)` from the pause menu, not from this widget directly.
- **Victory return:** `VictoryOverlay` emits `NavigateToShellEvent` per [`victory-overlay.md`](victory-overlay.md); this screen does not own that path.

---

## Components

- `CtScreenShell` (`app/lib/widgets/ct_screen_shell.dart`) — outer container with the localized `game_screenTitle`.
- `GameMapArea` ([`empire-overview.md`](empire-overview.md)) or `GameWidget(ColonizeThisGame())` — map vs Flame canvas branch.
- `CtNinePatchButton` (Next turn) and `IconButton` (`Icons.menu`, pause).
- `VictoryOverlay`, `GameStartIntroOverlay`, `OvertureDialogueOverlay`, `InterventionDialogueOverlay`, `CallToArmsDialogueOverlay`, `GameToUIBusListener`.
- Local-by-design dialogs (per [`app-ui-wiring.md`](../program/app-ui-wiring.md)): `NextTurnConfirmationDialog`, `TurnResolutionProcessingDialog`, exit-to-main-menu confirm `CtDialogShell`.
- Localized strings via `appL10n(context).game_*`.

---

## Acceptance Criteria (Given–When–Then)

- Given `GameScreen` is mounted with `currentGameProvider == game`, `mapViewDataProvider == null`, `victory == null`, `turnResolutionBlockingProvider == false`, and `introShownIds` containing `game.id`,
  When `GameScreen.build` runs,
  Then the widget tree contains exactly one `GameWidget`, exactly one `IconButton(Icons.menu)`, and exactly one `CtNinePatchButton` whose label resolves to `game_nextTurnButton(turn, year)`.

- Given `GameScreen` is mounted with `mapViewDataProvider != null` and `currentGameProvider != null`,
  When `GameScreen.build` runs,
  Then the widget tree contains exactly one `GameMapArea` and zero `GameWidget` instances.

- Given `GameScreen` is mounted with `currentGameProvider == game` and `game.victory != null`,
  When `GameScreen.build` runs,
  Then the widget tree contains exactly one `VictoryOverlay`, no pause `IconButton`, and no Next turn `CtNinePatchButton` (`showOverlayButtons == false`).

- Given `GameScreen` is mounted, no victory is set, and `turnResolutionBlockingProvider == true`,
  When `GameScreen.build` runs,
  Then the Next turn `CtNinePatchButton` is rendered with `onPressed == null` (disabled) and the pause `IconButton` remains enabled (gating allows pause-menu opens per [`app-ui-wiring.md`](../program/app-ui-wiring.md)).

- Given `GameScreen` is mounted with a bus listener subscribed to `OpenPauseMenuPanelEvent`,
  When the user taps the pause `IconButton`,
  Then the screen emits exactly one `OpenPauseMenuPanelEvent` on the supplied bus.

- Given `GameScreen` is mounted with `currentGameProvider == game` and `introShownIds` does not contain `game.id`,
  When `GameScreen.build` runs,
  Then the outermost wrapper is `GameStartIntroOverlay`; once dismissed (`onDismissed`), the screen calls `gameIdsWithIntroShownProvider.notifier.markShown(game.id)` exactly once.

- Given `pendingDiplomacyProvider == PendingDiplomacyOvertures(offers: [<non-empty>])`,
  When `GameScreen.build` runs,
  Then the visible content is wrapped in exactly one `OvertureDialogueOverlay`; the screen does not also wrap with `InterventionDialogueOverlay` or `CallToArmsDialogueOverlay`.

- Given `pendingDiplomacyProvider == PendingDiplomacyIntervention(prompts: [<non-empty>])` and overtures are empty,
  When `GameScreen.build` runs,
  Then the visible content is wrapped in exactly one `InterventionDialogueOverlay`.

- Given `pendingDiplomacyProvider == PendingDiplomacyCallToArms(pending: [<non-empty>])` and overtures and interventions are empty,
  When `GameScreen.build` runs,
  Then the visible content is wrapped in exactly one `CallToArmsDialogueOverlay`.

- Given `pendingDiplomacyProvider != null` but its only collection is empty (e.g. `PendingDiplomacyOvertures(offers: [])`),
  When `GameScreen.build` runs,
  Then no diplomacy overlay is wrapped (the `switch` falls through the empty guards).

- Given `GameScreen` is mounted on Android with `PopScope.canPop == false`,
  When the system back gesture fires and `onPopInvokedWithResult(didPop: false, ...)` triggers,
  Then the screen opens an exit-to-main-menu `CtDialogShell` confirm dialog; on Cancel no bus event is emitted, on Exit exactly one `NavigateToShellEvent` is emitted on the bus.

- Given `GameScreen` is mounted,
  When the widget tree is inspected,
  Then there are zero direct `Navigator.pushNamed` / `pushReplacement` / `popUntil` calls inside the widget for cross-screen navigation; cross-cutting transitions are bus events only (matches [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Banned `Navigator` chains). Local `Navigator.pop` for the exit confirm dialog and the next-turn flow's processing dialog is allowed.

---

## Widgetbook

Catalog directory: `Game Screen` (registered in `app/lib/widgetbook/catalog.dart`). Required use cases:

1. **Default — map view, no victory, intro shown** — `currentGameProvider`, `mapViewDataProvider`, and `gameIdsWithIntroShownProvider` overridden so the screen mounts `GameMapArea`, the pause button, and the Next turn button without the intro overlay.
2. **Victory** — same providers as default, plus `currentGameProvider` overridden to a game with `victory != null` (military victory by `game.players.first`); the story renders the `VictoryOverlay` and hides the overlay buttons.

Each story uses a `ProviderScope` that overrides `appEventBusProvider` with a fresh `AppEventBus.create()` (disposed on scope dispose) and supplies a fresh `Hive` box / `gameServiceProvider` only if a story specifically exercises the next-turn flow. The default stories must analyze cleanly with no hardcoded UI strings (use `appL10n` via `MaterialApp`).

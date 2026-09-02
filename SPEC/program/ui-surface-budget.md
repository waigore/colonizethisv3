# Game-app UI surface budget

**SPEC/program** — Hard wall-clock budget for opening player **game-app** panels, dialogs, overlays, and feature routes. Agent policy: [`.cursor/rules/colonizethis-ui-surface-budget.mdc`](../../.cursor/rules/colonizethis-ui-surface-budget.mdc). Wiring: [app-ui-wiring.md](app-ui-wiring.md). Tracing: [flutter-performance-tracing.md](flutter-performance-tracing.md). Distinct from the **15 s** next-turn budget in [turn-resolution.md](turn-resolution.md).

## Scope

**In:** `colonizethis_app` (`app/`) player UI: panels, dialogs, overlays, bottom sheets, in-game feature routes, Yarn/Jenny hosts, in-panel minimaps, and the projections those surfaces must compute.

**Out:** `ctdev/`, `tool/`, `widgetbook_host/`, packages that are not the running game UI. Widgetbook stories must still dispose any `FlameGame` they create; they are not timed against this budget.

## Ceiling

**1 000 ms** wall clock on the project target environment (same class as the `quality` workflow). Symbol: **`kUiSurfaceOpenBudgetMs`** (`packages/colonizethis_data/lib/src/ui_surface_open_budget.dart`).

**Consumers:** unit test asserts `1000`; always-applied rule and this TDD cite the symbol; `verify-github-issue` and `accept-github-issue` standing gates reference it. No app-runtime enforcement in the documentation slice (#4691).

Overflows are **release-blocking** defects for surfaces **introduced or modified** by the work under review (see **Existing overflows**).

## Ready state

Canonical definition (also in `.cursor/rules/colonizethis-ui-surface-budget.mdc`):

- **Start:** the open trigger (typed panel event, `OpenDialogEvent`, local `showDialog` / `showModalBottomSheet`, route push, overlay predicate flipping true).
- **End:** first frame after every load the **screen spec** requires for that surface's visible state is ready: read models and calculations, minimaps, Yarn/Jenny parse and first presentable line/options, and required images. Deferral (post-frame gates) is allowed only if that work still finishes inside the same 1 000 ms. Painting chrome without required content does **not** meet the budget.
- **Excluded:** lazy/off-screen inactive-tab content unless the surface is on the **First-open tab allowlist** (below).

## First-open tab allowlist

Inactive tabs are **not** in the first-open segment unless listed here. Do **not** duplicate this table into per-screen `SPEC/ui/**` files — add rows here when a screen spec requires inactive-tab content on first open.

| Screen ID | Surface | Tabs required on first open | Notes |
|-----------|---------|-------------------------------|-------|
| *(none yet)* | — | — | Default: only the selected/default tab body is in the first-open segment. |

Selecting a tab **not** on this allowlist starts a **new** 1 000 ms segment for that tab's required content.

## Existing overflows

Surfaces that already exceed 1 000 ms before this policy lands are **grandfathered** for unrelated verification: track them as separate follow-up performance defects (for example #4688, #4690, #4715). The standing verify/accept gate hard-fails only when the issue under verification **touches or introduces** a surface whose open path exceeds the budget.

## Measured segment (summary)

Same as **Ready state** above. Legacy alias: "open trigger → ready state."

## Mount and dispose

- Construct dialogs, panels, overlay widgets, `GameWidget` / `FlameGame`, Jenny runners, and dual-region / full-game view data **only while the surface is shown**. Prefer route push / `showDialog` / `if (visible)` over `Offstage`, eager `IndexedStack` of maps, or hidden `OverlayEntry`.
- Dialog builders registered on the shell are **factories**, not prebuilt widgets (`extraDialogBuilders` in [app-ui-wiring.md](app-ui-wiring.md)).
- One live `FlameGame` per **visible** map canvas. Do not keep a dummy `ColonizeThisGame` when map data is absent; use a cheap placeholder widget.
- On close (`ClosePanelEvent`, `UnitsPanelClosedEvent`, `Navigator.pop`, overlay predicate false): unmount the subtree; `dispose()` Flutter controllers, tickers, subscriptions (`SubscriptionTracker`); Flame `onRemove()`; drop Jenny runners and decoded images. Closed UI must not retain a `Game` or `FlameGame`.
- `CtTabStrip.lazyTabBodies` when a tab holds a map, Flame canvas, or heavy projection.

## Standing verification

`verify-github-issue` and `accept-github-issue` apply this contract to **game-app UI** work on merged `dev` **even when the issue ACs omit it**, scoped to surfaces **introduced or modified** by that issue (not untouched panels elsewhere that may already overflow). Evidence: open-path timing test, unmount test, and/or a recorded open whose wall-clock includes required minimap/Yarn/calcs and is ≤ 1000 ms. Missing evidence for a **touched** surface → gaps remain / REJECT. ctdev-only and non-UI issues are N/A.

## Profiling

Extend `CtAppPerf.<surface>.*` markers so the **full** open path (calcs + map + Yarn) is visible in [flutter-performance-tracing.md](flutter-performance-tracing.md). First-chrome-only markers are insufficient.

## Tests

- Constant: `kUiSurfaceOpenBudgetMs == 1000`.
- Open-path timing for heavy surfaces (Development panel peer tests remain complementary; they do not replace this ceiling).
- After dismiss, panel/dialog keys, `GameWidget`, and Jenny hosts are **absent** (not merely not visible).

## Acceptance criteria

- Given a game-app panel, dialog, or overlay whose spec lists required content (projections, minimap, Yarn, assets), when the Player opens that surface, then the UI layer completes every required load within `kUiSurfaceOpenBudgetMs` (1000).
- Given that surface is dismissed, when the widget tree is inspected, then the UI layer has unmounted its widgets, `FlameGame`s, and Jenny hosts.
- Given `verify-github-issue` on a game-app UI change whose issue text never mentions performance, when verification runs, then the comment includes a standing surface-budget row (`pass`, `N/A: not game-app UI`, or `gap`) scoped to surfaces touched by that issue.
- Given `kUiSurfaceOpenBudgetMs` is read from `colonizethis_data`, then the value is `1000`.

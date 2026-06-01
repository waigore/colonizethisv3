# CtGameFeatureScreenShell (component)

**SPEC/ui/components** — Reusable host wrapper for game-bound feature screens. Implementation: [`app/lib/widgets/ct_game_feature_screen_shell.dart`](../../../app/lib/widgets/ct_game_feature_screen_shell.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtTopBar*, § *CtScreenShell*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical scaffolding for in-game feature surfaces (production, technology, diplomacy, trade) referenced by the screen specs listed under [Consumers](#consumers).

---

## Purpose

Hosts game-bound feature screens with three guarantees: a live-game swap via `currentGameProvider`, optional `GameToUIBusListener` wiring, and a two-chrome-path body host (legacy `CtScreenShell` or dark `Scaffold` + `topBar`). Callers compose only the body; the shell owns the rest (issue [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9).

---

## Widget contract

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `game` | `Game` | yes | — | Initial game snapshot supplied by the route. Always passed to `bodyBuilder` unless a same-id live game is available. |
| `bodyBuilder` | `GameFeatureBodyBuilder` | yes | — | Signature `Widget Function(BuildContext context, WidgetRef ref, Game displayGame)`. Receives the resolved `displayGame` (live snapshot when present, otherwise `game`). |
| `title` | `String?` | conditional | — | Required when `topBar == null` (legacy `CtScreenShell` chrome path). Ignored when `topBar` is provided. |
| `topBar` | `Widget?` | conditional | — | Required when `title == null`. When supplied, the shell renders a dark `Scaffold` + `SafeArea` + `Column` body host with the top bar above the body. Typically a `CtTopBar`. |
| `showBackButton` | `bool` | no | `true` | Forwarded to the legacy `CtScreenShell`. No effect on the dark-chrome path. |
| `attachGameToUiListener` | `bool` | no | `true` | When `true`, the body is wrapped in `GameToUIBusListener(gameId: game.id, child: shell)`. |

Invariant (assertion): `topBar != null || title != null`. When both are supplied, the dark-chrome path wins.

---

## Layout / wireframe

### Dark-chrome path (`topBar` non-null)

```text
GameToUIBusListener(gameId: game.id)?                 -- when attachGameToUiListener == true
  Scaffold(backgroundColor: colorScheme.surface)
    SafeArea
      Column(crossAxisAlignment: stretch)
        topBar                                        -- supplied CtTopBar
        Expanded(child: bodyBuilder(context, ref, displayGame))
```

### Legacy-chrome path (`topBar == null`, `title` required)

```text
GameToUIBusListener(gameId: game.id)?                 -- when attachGameToUiListener == true
  CtScreenShell(title: title, showBackButton: showBackButton)
    bodyBuilder(context, ref, displayGame)
```

In both paths `displayGame` is the live `currentGameProvider` value when its `id == game.id`; otherwise the original `game` snapshot is forwarded so a stale route argument never displaces a live snapshot.

---

## Behavior

1. **Live-game swap.** When `attachGameToUiListener == true`, the shell watches `currentGameProvider`. If the live value is non-null and `live.id == game.id`, `displayGame == live`; else `displayGame == game`.
2. **Listener gating.** When `attachGameToUiListener == false`, the shell skips both the `currentGameProvider` watch (`displayGame == game` always) and the surrounding `GameToUIBusListener` wrapper.
3. **Chrome is non-overlapping.** Exactly one of (`_DarkChromeShell`, `CtScreenShell`) is mounted. The dark path uses `Theme.of(context).colorScheme.surface` for the `Scaffold` background so the surface inherits the active theme (`AppThemes.editorialMonocle` in production per `colonizethis-ui-design.mdc` § *Dark theme*).
4. **No chrome of its own.** The shell paints no borders, dividers, or titles; the supplied `topBar` or `CtScreenShell` owns all chrome.
5. **Listener wraps outermost.** When attached, `GameToUIBusListener` wraps the entire chrome subtree so back navigation and inbound events see the listener.

---

## States and variants

The composite has no internal state. Variants are driven entirely by `topBar` and `attachGameToUiListener`:

| Variant | `topBar` | `attachGameToUiListener` | Chrome |
|---------|----------|--------------------------|--------|
| Dark + live | non-null | `true` | `_DarkChromeShell` inside `GameToUIBusListener` |
| Dark, no listener | non-null | `false` | `_DarkChromeShell` directly (Widgetbook) |
| Legacy + live | `null` | `true` | `CtScreenShell` inside `GameToUIBusListener` |
| Legacy, no listener | `null` | `false` | `CtScreenShell` directly (Widgetbook) |

---

## Consumers

The following screen specs use this composite as their host shell:

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `GAME20001` | [`production-panel.md`](../production-panel.md) | Dark chrome with `CtTopBar` (issue #2862 S1). |
| `GAME40001` | [`technology-panel.md`](../technology-panel.md) | Dark chrome with `CtTopBar` (issue #2862 S2). |
| `GAME30001` | [`diplomacy-panel.md`](../diplomacy-panel.md) | Dark chrome with `CtTopBar` (issue #2863). |
| `GAME60001` | [`trade-screen.md`](../trade-screen.md) | Dark chrome with `CtTopBar` (issue #2993). |

Each consumer spec links back here for the live-game-swap, listener-gating, and chrome-path contract instead of duplicating the wireframe.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `CtGameFeatureScreenShell` mounted with `topBar != null` and `attachGameToUiListener == true`,
  **When** the widget tree settles,
  **Then** exactly one `_DarkChromeShell` is mounted in the subtree, exactly one `GameToUIBusListener` is mounted with `gameId == game.id`, and the legacy `CtScreenShell` is **not** mounted in the subtree.

- **Given** a `CtGameFeatureScreenShell` mounted with `topBar == null` and `title == 'Diplomacy'`,
  **When** the widget tree settles,
  **Then** exactly one `CtScreenShell` is mounted in the subtree with `title == 'Diplomacy'` and the `_DarkChromeShell` is **not** mounted in the subtree.

- **Given** a `CtGameFeatureScreenShell` constructed with both `topBar == null` and `title == null`,
  **When** the constructor runs in a `--enable-asserts` build,
  **Then** the assertion `topBar != null || title != null` fails (regression guard against silent fall-through).

- **Given** a `CtGameFeatureScreenShell` with `attachGameToUiListener == true` and a `currentGameProvider` whose live value has `id == game.id` and a distinct first-player `displayName`,
  **When** `bodyBuilder` runs,
  **Then** `displayGame.players.first.displayName` matches the live value (not the route snapshot).

- **Given** a `CtGameFeatureScreenShell` with `attachGameToUiListener == true` and a `currentGameProvider` whose live value has `id != game.id`,
  **When** `bodyBuilder` runs,
  **Then** `displayGame` is identical to the original `game` route argument.

- **Given** a `CtGameFeatureScreenShell` with `attachGameToUiListener == false`,
  **When** the widget tree settles,
  **Then** no `GameToUIBusListener` is mounted in the subtree.

---

## Tests

- `app/test/ct_game_feature_screen_shell_test.dart` — widget-level contract tests pinning the live-game swap rule, listener wrapping, and chrome selection.
- `app/test/spec_components_ct_game_feature_screen_shell_test.dart` — spec-pinning regression tests asserting that this component spec exists, declares the required sections (Widget contract, Layout, Behavior, Consumers, Acceptance criteria), and enumerates the four consumer screens by stable id.

---

## Related

- Catalog reference: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtTopBar*, § *CtScreenShell*, § *Editorial-monocle palette*.
- Listener helper: [`app/lib/widgets/game_to_ui_bus_listener.dart`](../../../app/lib/widgets/game_to_ui_bus_listener.dart).
- Legacy chrome: [`app/lib/widgets/ct_screen_shell.dart`](../../../app/lib/widgets/ct_screen_shell.dart).
- Tracking issue: [#2914](https://github.com/waigore/issues/2914) S9 (component spec authoring).

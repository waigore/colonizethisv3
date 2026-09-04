# Intelligence Council

**Screen ID:** `GAME30003` — stable; do not reassign.
**SPEC/ui** — Last-turn world briefing and spy-gated court reports hosted from Diplomacy. Implementation: `app/lib/features/game/screens/diplomacy/intelligence_council_screen.dart`.
**Widgetbook:** `Intelligence Council` → `widgetbook_host/lib/catalogs/catalog_intelligence_council.dart`.

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `game` | `Game` | yes | Live game; reads `lastTurnIntelligenceDigest`. |
| `humanPlayerId` | `String` | yes | Observer GP for spy blocks. |

## Trigger conditions

- `GAME30001` top-bar **Intelligence** (`NavigateToRouteEvent` → `Routes.intelligence`).
- `DLG50001` footer when spy-report lines exist (same route; dialog pops).
- Spy-gated `OVL70001` row tap (council or `GAME30002`).

Observe mode: same `observeNotDefinedSentinel` as Diplomacy. No idle-spy nag (`UXD-002`).

## Layout / wireframe

```
CtGameFeatureScreenShell
├── GameFeatureScreenTopBar (← Map, diplomacy icon, "Intelligence")
└── ListView
    ├── heading World briefing
    │   └── world lines | empty: No major world events last turn.
    └── heading Spy reports
        └── per court: Our spy in {name} reports: {fact}
        └── or empty: No spy reports. Station a Spy in a foreign province to hear that court's news.
```

Ct-* only. Editorial-monocle tokens. Display names only (no raw ids, no `declare_war`, no `hiddenAgenda`). World vs spy provenance always visible.

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Diplomacy **Intelligence** | Human GP | Opens `GAME30003`. |
| Turn-news footer | Spy line count `N` > 0 | Footer + navigate to council. |
| Feed spy row | Spy-gated digest line | Opens council or `GAME30002`. |

### User actions → outcomes

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| ← Map | Always | `Navigator.maybePop()` | Returns to Diplomacy or prior. |
| World/spy line naming a court | Faction resolvable | `NavigateToRouteEvent(Routes.diplomacyDetail, …)` | `GAME30002`; dossier stays on detail. |
| Capture/discovery line | Province id present | `PopNavigationEvent` then `OpenProvinceDetailPanelEvent` | Map-focus `MAP20001`. |

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `GAME30003` | World-only | World lines, no spy blocks | World list; spy empty copy. |
| `GAME30003` | Spy reports | ≥1 court block | Prefixed spy lines. |
| `GAME30003` | Empty | Null or empty digest | Both empty copies. |
| `GAME30003` | Mobile | 360 × 640 dp `mobileViewport` | Same stack; scroll. |

## Components

- `CtGameFeatureScreenShell` — [components/ct-game-feature-screen-shell.md](components/ct-game-feature-screen-shell.md).
- `GameFeatureScreenTopBar` / `CtTopBar` — Diplomacy-family chrome; back is `← Map`.
- `IntelligenceCouncilLineTile` — world or spy fact row; tap emits bus events above.

## Widgetbook

Folder **Intelligence Council**. Use cases: **World briefing**, **Spy reports**, **Empty**, **Mobile viewport** (shared `mobileViewport`, 360 × 640 dp per `SPEC/ui/mobile-adaptation.md`).

## Acceptance criteria

- Given a digest with a third-party war and a faction-to-faction capture, when the human opens Intelligence from `GAME30001`, then World briefing lists both in display names, and the same lines remain after `DLG50001` is closed.
- Given no Spy in France, when France finishes a tech and fights a battle the human is not in, then those France-only lines are absent from the council and from `OVL70001`.
- Given a remaining Spy in France and France finished a catalog tech and declared war on Spain, when the council renders, then a Spy reports block includes both as `Our spy in France reports:` with display names (never raw ids or `hiddenAgenda`).
- Given last-turn spy reports exist, when `DLG50001` opens, then a footer states spies reported N items and navigates to the council.
- Given a world war line naming a court, when The Player taps that row, then the UI layer emits `NavigateToRouteEvent` for `Routes.diplomacyDetail` (`GAME30002`).
- Given a capture world line with a province id, when The Player taps that row, then the UI layer emits `PopNavigationEvent` then `OpenProvinceDetailPanelEvent` for that province.
- Given a spy-gated `OVL70001` row from the digest, when The Player taps it, then the UI layer opens `GAME30003`. Public world gazette lines are not appended to the feed.
- Given `DLG60001` / end-turn readiness, when this ships, then no idle/unassigned Spy list is added.
- **Join Empire Intelligence Tribe colony (Refs #4729):** Given a spy/world digest line with `DiplomaticEventType.joinEmpireResolved` whose `toFactionId` is a Tribe still on the map (or listed in `Game.colonyStates`), when `GAME30003` formats that line, then the UI layer does not say the Tribe was absorbed and uses colony / land-stayed-theirs copy.
- **Join Empire Intelligence Minor/GP absorb (Refs #4729):** Given the same event type for a Minor or Great Power absorption target, when `GAME30003` formats that line, then the UI layer describes absorption (land, armies, and fleets transferred).

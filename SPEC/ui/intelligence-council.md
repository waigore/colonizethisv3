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
| `GAME30003` | Mobile | Width ≤ 320 dp | Same stack; scroll. |

## Widgetbook

Folder **Intelligence Council**. Use cases: **World briefing**, **Spy reports**, **Empty**, **Mobile viewport** (`mobileViewport`, 320 dp).

## Acceptance criteria

- Given a digest with a third-party war and a faction-to-faction capture, when the human opens Intelligence from `GAME30001`, then World briefing lists both in display names, and the same lines remain after `DLG50001` is closed.
- Given no Spy in France, when France finishes a tech and fights a battle the human is not in, then those France-only lines are absent from the council and from `OVL70001`.
- Given a remaining Spy in France and France finished a catalog tech and declared war on Spain, when the council renders, then a Spy reports block includes both as `Our spy in France reports:` with display names (never raw ids or `hiddenAgenda`).
- Given last-turn spy reports exist, when `DLG50001` opens, then a footer states spies reported N items and navigates to the council.
- Given `DLG60001` / end-turn readiness, when this ships, then no idle/unassigned Spy list is added.

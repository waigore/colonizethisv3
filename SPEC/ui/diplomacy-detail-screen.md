# Diplomacy Detail Screen

**SPEC/ui** — Full-screen route showing diplomatic **history** and (for Great Powers) **dossier evidence** for one discovered faction. Opened from [`diplomacy-panel.md`](diplomacy-panel.md). Route: `Routes.diplomacyDetail` (`/game/diplomacy/detail`). Bus contract: [`app-event-bus.md`](../program/app-event-bus.md). Source: `app/lib/features/game/screens/diplomacy_detail_screen.dart`.

---

## Widget contract

`DiplomacyDetailScreen` is a `ConsumerWidget`. Route arguments are passed as constructor parameters (the route builder reads `ModalRoute.settings.arguments`).

| Parameter | Type | Description |
|-----------|------|-------------|
| `game` | `Game` | Active game; supplies history, relations, dossier entries. |
| `humanPlayerId` | `String` | Observing Great Power (`A` in panel copy). |
| `factionId` | `String` | Target faction `B`. |
| `factionDisplayName` | `String` | App bar title text. |
| `kind` | `FactionKind` | `greatPower`, `minorNation`, or `tribe` — controls dossier visibility. |
| `relation` | `DiplomacyRelation?` | Current relation row snapshot; `null` when undiscovered/unknown. |

`formatDiplomaticEvent` (same library file) is the shared formatter for history sentences; unknown counterparties render as `Unknown faction` when no relation exists.

---

## Trigger conditions

- **Open:** User selects a faction row on `DiplomacyScreen` → `NavigateToRouteEvent(Routes.diplomacyDetail, { game, humanPlayerId, factionId, factionDisplayName, kind, relation })` per [`diplomacy-panel.md`](diplomacy-panel.md).
- **Close:** App bar back `IconButton` → `PopNavigationEvent` on `appEventBusProvider` (no direct `Navigator.pop` in the widget).

---

## Layout / wireframe

```text
Scaffold
  AppBar(title: factionDisplayName, back -> PopNavigationEvent)
  body: ListView (padding 16h x 8v)
    CtPanel — current relation (state · one-word score label, or "—")
    section: History (titleMedium)
      [empty] diplomacy_detail_noEvents
      OR Card per event (year/turn label + formatDiplomaticEvent sentence)
    if kind == greatPower:
      section: Dossier (titleMedium)
        [empty] diplomacy_detail_noDossier
        OR rows: turn label + evidence description (newest first)
```

Outgoing subsidy/grant pending copy from the diplomacy **list** row is **not** duplicated here (see [`diplomacy-panel.md`](diplomacy-panel.md) § Per-faction row).

---

## States and variants

| State | Condition | Render |
|-------|-----------|--------|
| Peace + score | `relation != null`, `!relation.atWar` | Summary shows localized peace + `relationScoreToDisplayLabel(score)`. |
| War | `relation != null`, `relation.atWar` | Summary shows localized war + score label when applicable. |
| Unknown relation | `relation == null` | Summary shows `—` only (no score words). |
| Empty history | `diplomaticHistoryForPair` returns `[]` | `diplomacy_detail_noEvents` body text. |
| Non-empty history | One or more events for the pair | Newest-first `Card` list with year/turn header per event. |
| GP dossier | `kind == FactionKind.greatPower` | Dossier section always present (empty or populated). |
| Non-GP | `kind != greatPower` | No dossier section (history only). |
| Empty dossier | GP with zero matching `dossierEvidenceEntries` | `diplomacy_detail_noDossier`. |

History ordering: `(turn desc, intraTurnIndex desc)` via `diplomaticHistoryForPair`.

---

## Navigation

- **Back:** `PopNavigationEvent` only — handled by shell / route stack per [`app-ui-wiring.md`](../program/app-ui-wiring.md).
- **No bus events** for history scroll or dossier display.
- **No order submission** on this screen (actions remain on [`diplomacy-panel.md`](diplomacy-panel.md)).

---

## Acceptance Criteria (Given–When–Then)

- Given the screen is mounted for a Great Power target with `relation` at peace and score 70,
  When the widget builds,
  Then the UI layer shows the localized peace label and a non-empty relation score display string in the summary `CtPanel`.

- Given `kind` is not `FactionKind.greatPower`,
  When the widget builds,
  Then the UI layer does not render the dossier section title (`diplomacy_detail_dossierTitle`).

- Given `kind` is `FactionKind.greatPower` and no dossier entries exist for `(humanPlayerId, factionId)`,
  When the widget builds,
  Then the UI layer shows `diplomacy_detail_noDossier` under the dossier heading.

- Given at least one diplomatic history event exists for the human/target pair,
  When the widget builds,
  Then the UI layer renders at least one `Card` whose body includes text from `formatDiplomaticEvent` for that event.

- Given the app bar back button is visible,
  When the user taps it,
  Then the UI layer emits exactly one `PopNavigationEvent` on `appEventBusProvider`.

- Given a history event references a faction id with no relation to the human player,
  When the event sentence is formatted,
  Then the UI layer shows `Unknown faction` for that party name in the sentence text.

---

## Widgetbook

- **Folder:** `Diplomacy Detail Screen`
- **Default use case:** `ProviderScope` with `appEventBusProvider` → `AppEventBus.create()`; renders `DiplomacyDetailScreen` with a minimal inline `Game` fixture (human GP + rival GP, one peace relation, one history event, one dossier entry) inside `MaterialApp`.

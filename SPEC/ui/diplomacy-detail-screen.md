# Diplomacy Detail Screen

**Screen ID:** `GAME30002` — stable; do not reassign.
**SPEC/ui** — Full-screen route showing diplomatic **history** and (for Great Powers) **dossier evidence** for one discovered faction. Opened from [`diplomacy-panel.md`](diplomacy-panel.md). Route: `Routes.diplomacyDetail` (`/game/diplomacy/detail`). Bus contract: [`app-event-bus.md`](../program/app-event-bus.md). Source: `app/lib/features/game/screens/diplomacy_detail_screen.dart`.

**Mockup:** [mockups/GAME30002-diplomacy-detail-screen.html](mockups/GAME30002-diplomacy-detail-screen.html)
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
CtGameFeatureScreenShell (backgroundColor: --bg, attachGameToUiListener: false)
  SafeArea (owned by shell)
    Column (owned by shell)
      CtTopBar (title: factionDisplayName, chevron back -> PopNavigationEvent)
      Center / ConstrainedBox (maxWidth: 600)
        ListView (padding 14h x 14v, gap 14 between cards)
          DetailCard — title "CURRENT RELATION"
            if kind == greatPower:
              RelativePowerLine ("Relative power: +N% · Tier"; shared with diplomacy-panel.md § Relative power line)
            RelationSummary (state word in --danger / --success + one-word score label, or "—")
          DetailCard — title "DIPLOMATIC HISTORY"
            [empty] diplomacy_detail_noEvents (italic --muted)
            OR LeftBorderTile per event (mono --accent-dim year/turn label + sentence)
          if kind == greatPower:
            DetailCard — title "DOSSIER"
              [empty] diplomacy_detail_noDossier (italic --muted)
              OR LeftBorderTile per evidence entry (mono --accent-dim turn label + description)
```

`CtGameFeatureScreenShell` owns the screen-level `Scaffold` (with the
`EditorialMonoclePalette.bg` background passed via the shell's
`backgroundColor` parameter), the `SafeArea`, and the top-bar / body
`Column`. Detail screens no longer construct `Scaffold` themselves; the
`repo.app_no_material_scaffold` lint enforces the same Ct-* shell
contract that `repo.app_no_material_iconbutton`,
`repo.app_no_material_alertdialog`, and `repo.app_no_material_textbutton`
already enforce for chrome catalog widgets (`SPEC/program/repo-lint.md`).
`attachGameToUiListener` is `false` because the screen does not need
the live-`Game` rebind that the shell uses for panel-style game
features.

Visual chrome notes (per [mockups/GAME30002-diplomacy-detail-screen.html](mockups/GAME30002-diplomacy-detail-screen.html)):

- `CtTopBar` paints the `--surface-lite → --surface` gradient with a `--accent-dim` bottom border; the title uses the display font in `--accent`.
- `DetailCard` chrome paints a `--surface-lite → --surface → --bg-deep` vertical gradient with a 1 px `--border` outline and 14 px inner padding.
- Card titles use the display font in `--muted` uppercase, 13 px, letter-spacing `0.06 em`. They render as **upper-case** text (e.g. `DIPLOMATIC HISTORY`) on platforms without smcp glyphs.
- `LeftBorderTile` paints a `--surface` background with a 2 px `--accent-dim` left border, 10×12 px inner padding, an 11 px monospace `--accent-dim` label line, and a `--fg` body sentence.

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
| GP relative power | `kind == FactionKind.greatPower` | `RelativePowerLine` rendered above the relation summary in the `CURRENT RELATION` card; `pct` recomputed from `greatPowerPowerScore(game, factionId)` vs `greatPowerPowerScore(game, humanPlayerId)` per [diplomacy-panel.md](diplomacy-panel.md) § Relative power line. |
| Non-GP relative power | `kind != greatPower` | No relative-power line in the `CURRENT RELATION` card. |

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
  Then the UI layer shows the localized peace label and a non-empty relation score display string in the current-relation `DetailCard`.

- Given `relation.atWar` is `true`,
  When the current-relation `DetailCard` renders,
  Then the localized war state label resolves its text colour to `EditorialMonoclePalette.danger` per mockup `.relation-row .war`.

- Given `relation.atWar` is `false` and `relation` is non-null,
  When the current-relation `DetailCard` renders,
  Then the localized peace state label resolves its text colour to `EditorialMonoclePalette.success` per mockup `.relation-row .state`.

- Given the widget builds,
  When the chrome is inspected,
  Then the screen chrome is rendered via `CtGameFeatureScreenShell` with `backgroundColor: EditorialMonoclePalette.bg` (no direct Material `Scaffold` is constructed by `DiplomacyDetailScreen` itself, per `repo.app_no_material_scaffold`), exactly one `CtTopBar` is present, the legacy Material `AppBar` is absent, and the `CtTopBar` carries a `CtBackButton` chevron.

- Given `kind` is `FactionKind.greatPower` and `greatPowerPowerScore(game, factionId)` exceeds `greatPowerPowerScore(game, humanPlayerId)`,
  When the `CURRENT RELATION` `DetailCard` renders,
  Then the UI layer renders a `RelativePowerLine` above the relation summary whose percentage and tier word resolve their text colour to `EditorialMonoclePalette.danger` per [diplomacy-panel.md](diplomacy-panel.md) § Relative power line.

- Given `kind` is not `FactionKind.greatPower`,
  When the `CURRENT RELATION` `DetailCard` renders,
  Then the UI layer does not render a `RelativePowerLine` widget.

- Given `kind` is not `FactionKind.greatPower`,
  When the widget builds,
  Then the UI layer does not render the dossier section title (`diplomacy_detail_dossierTitle`).

- Given `kind` is `FactionKind.greatPower` and no dossier entries exist for `(humanPlayerId, factionId)`,
  When the widget builds,
  Then the UI layer shows `diplomacy_detail_noDossier` under the dossier heading.

- Given at least one diplomatic history event exists for the human/target pair,
  When the widget builds,
  Then the UI layer renders at least one `Card` whose body includes text from `formatDiplomaticEvent` for that event.

- Given the `CtTopBar` back button is visible,
  When the user taps it,
  Then the UI layer emits exactly one `PopNavigationEvent` on `appEventBusProvider`.

- Given a history event references a faction id with no relation to the human player,
  When the event sentence is formatted,
  Then the UI layer shows `Unknown faction` for that party name in the sentence text.

- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp and the screen is mounted for a Great Power target with one seeded history event and one seeded dossier entry,
  When the widget builds,
  Then the UI layer renders exactly one `CtTopBar` with the target faction `displayName` as its title and a descendant `CtBackButton`, the `CURRENT RELATION` / `DIPLOMATIC HISTORY` / `DOSSIER` `_DetailCard` titles all render in the `ListView` body, and `WidgetTester.takeException()` returns `null` (per [mobile-adaptation.md](mobile-adaptation.md) § 7 — minimum-viewport pin; the screen must lay out without horizontal overflow inside the 320 dp column).

- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp and the screen is mounted with `kind = FactionKind.minor`, empty history, and empty dossier entries,
  When the widget builds,
  Then the UI layer renders the `CURRENT RELATION` and `DIPLOMATIC HISTORY` titles but does NOT mount the `DOSSIER` title, and `WidgetTester.takeException()` returns `null` (negative AC for the GP-only branch at the minimum viewport per [mobile-adaptation.md](mobile-adaptation.md) § 7).

- Given the screen is mounted under `AppThemes.editorialMonocle` for a Great Power target whose `greatPowerPowerScore` exceeds the human player's (deterministic province fixture),
  When the golden test in `app/test/diplomacy_relative_power_goldens_test.dart` captures the screen's keyed `RepaintBoundary`,
  Then the captured boundary matches its committed baseline `app/test/goldens/diplomacy_detail_relative_power.png` via `matchesGoldenFile`, the `CURRENT RELATION` card title renders, and exactly one `RelativePowerLine` is present (visual-regression baseline for the relative-power line on GAME30002 per [diplomacy-panel.md](diplomacy-panel.md) § Relative power line).

---

## Widgetbook

- **Folder:** `Diplomacy Detail Screen`
- **Default use case:** `ProviderScope` with `appEventBusProvider` → `AppEventBus.create()`; renders `DiplomacyDetailScreen` with a minimal inline `Game` fixture (human GP + rival GP, one peace relation, one history event, one dossier entry) inside `MaterialApp`.

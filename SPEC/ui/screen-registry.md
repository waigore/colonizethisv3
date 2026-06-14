# UI Screen Registry

**SPEC/ui** — Canonical index of player-app screen IDs. Assign IDs per [`.cursor/rules/colonizethis-ui-documentation.mdc`](../../.cursor/rules/colonizethis-ui-documentation.mdc). **Do not renumber** existing IDs; add new rows only.

**Code:** `app/lib/config/ui_screen_ids.dart` — every **active** row must have a matching `static const`.

---

## Categories (3-letter codes)

Major flows only; keep this table small.

| Code | Flow | Sub-flow digits (4th char) |
|------|------|----------------------------|
| `SHEL` | App shell, main menu, initializing, pause menu | `1` menu/shell route, `3` game initializing, `4` pause menu panel |
| `GAME` | In-game route hosts and side menu | `1` game screen, `2` production route, `3` diplomacy routes, `4` technology route, `5` game side menu, `6` trade route |
| `MAP` | Map widget and map-attached UI | `1` map area/widget, `2` province/sea-zone overlay |
| `UNIT` | Unit management panels and train dialogs | `1` civilian, `2` military, `3` naval, `4` train civilians, `5` train military |
| `DIPL` | Diplomacy panels and grant flows | `1` diplomacy panel/screen, `2` grant/subsidy dialog |
| `PROD` | Production surfaces | `1` production panel/screen, `2` commodity breakdown dialog |
| `TECH` | Technology surfaces | `1` technology panel/screen |
| `CMPT` | Combat and quick battle | `1` mode choice, `2` quick battle screen, `3` deployment, `4` action selector, `5` result dialog |
| `OVL` | Full-screen overlays and narrative UI | `1` game-start intro, `2` victory, `3` overture dialogue, `4` call-to-arms, `5` pending intervention, `6` observe mode, `7` player turn event feed |
| `DLG` | Modal dialogs (non-route) | `1` leader selection, `2` move army, `3` move fleet, `4` transfer home fleet, `5` turn news, `6` next-turn confirm (if spec-owned) |
| `SYS` | System/debug surfaces | `1` debug log viewer, `2` debug console panel |

---

## Registry

Status: `draft` = ID reserved, spec incomplete; `active` = spec + Widgetbook + code binding expected.

| ID | Title | Spec | Implementation | Widgetbook | Status |
|----|-------|------|----------------|------------|--------|
| `SHEL10001` | Shell screen | [shell-screen.md](shell-screen.md) | `app/lib/features/shell/shell_screen.dart` | Shell Screen | active |
| `SHEL10002` | Main menu (CtMainMenu) | [main-menu.md](main-menu.md) | `app/lib/widgets/main_menu.dart` | Main Menu | active |
| `SHEL30001` | Game initializing | [game-initializing.md](game-initializing.md) | TBD | — | draft |
| `SHEL40001` | Pause menu panel | [pause-menu-panel.md](pause-menu-panel.md) | `app/lib/features/game/widgets/pause_menu_panel.dart` | Pause Menu Panel | active |
| `GAME10001` | Game screen | [game-screen.md](game-screen.md) | `app/lib/features/game/flame/game_screen.dart` | Game Screen | active |
| `GAME20001` | Production screen | [production-panel.md](production-panel.md) | `app/lib/features/game/screens/production_screen.dart` | Production Panel | active |
| `GAME30001` | Diplomacy screen | [diplomacy-panel.md](diplomacy-panel.md) | `app/lib/features/game/screens/diplomacy_screen.dart` | Diplomacy Panel | active |
| `GAME30002` | Diplomacy detail screen | [diplomacy-detail-screen.md](diplomacy-detail-screen.md) | `app/lib/features/game/screens/diplomacy_detail_screen.dart` | Diplomacy Detail Screen | active |
| `GAME40001` | Technology screen | [technology-panel.md](technology-panel.md) | `app/lib/features/game/screens/technology_screen.dart` | Tech Tree | active |
| `GAME50001` | Game side menu | [game-side-menu.md](game-side-menu.md) | `app/lib/features/game/flame/game_side_menu.dart` | Game Side Menu | active |
| `GAME60001` | Trade screen | [trade-screen.md](trade-screen.md) | `app/lib/features/game/screens/trade_screen.dart` | Trade Screen | draft |
| `MAP10001` | Empire overview / map area | [empire-overview.md](empire-overview.md) | `app/lib/features/game/flame/game_map_area.dart` | Map Widget | active |
| `MAP20001` | Province sea-zone overlay | [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md) | `app/lib/features/game/widgets/province_sea_zone_detail_overlay.dart` | Province Overlay | active |
| `UNIT10001` | Civilian units panel | [civilian-units-panel.md](civilian-units-panel.md) | `app/lib/features/game/widgets/civilian_units_panel.dart` | Civilian Units Panel | active |
| `UNIT20001` | Military units panel | [military-units-panel.md](military-units-panel.md) | `app/lib/features/game/widgets/military_units_panel.dart` | Military Units Panel | active |
| `UNIT30001` | Naval units panel | [naval-units-panel.md](naval-units-panel.md) | `app/lib/features/game/widgets/naval_units_panel.dart` | Naval Units Panel | active |
| `UNIT40001` | Train civilians dialog | [train-civilians-dialog.md](train-civilians-dialog.md) | `app/lib/features/game/widgets/train_civilians_dialog.dart` | Train Civilians Dialog | active |
| `UNIT50001` | Train military dialog | [train-military-dialog.md](train-military-dialog.md) | `app/lib/features/game/widgets/train_military_dialog.dart` | Train Military Dialog | active |
| `DIPL20001` | Grant or subsidy dialog | [grant-or-subsidy-dialog.md](grant-or-subsidy-dialog.md) | `app/lib/features/game/widgets/diplomacy_dialogs.dart` | Grant or Subsidy Dialog | active |
| `PROD20001` | Production commodity breakdown dialog | [production-commodity-breakdown-dialog.md](production-commodity-breakdown-dialog.md) | `app/lib/features/game/widgets/production_commodity_breakdown_dialog.dart` | Production Commodity Breakdown Dialog | active |
| `CMPT10001` | Combat mode choice dialog | [combat-mode-choice-dialog.md](combat-mode-choice-dialog.md) | `app/lib/features/game/combat/combat_mode_choice_dialog.dart` | Quick Battle | active |
| `CMPT20001` | Quick battle screen | [quick-battle-screen.md](quick-battle-screen.md) | `app/lib/features/game/combat/quick_battle_screen.dart` | Quick Battle | active |
| `CMPT50001` | Quick battle result dialog | [quick-battle-result-dialog.md](quick-battle-result-dialog.md) | `app/lib/features/game/combat/quick_battle_result_dialog.dart` | Quick Battle | active |
| `DLG10001` | New game leader selection | [new-game-leader-selection-dialog.md](new-game-leader-selection-dialog.md) | `app/lib/features/shell/new_game_leader_selection_dialog.dart` | New Game Leader Selection Dialog | active |
| `DLG20001` | Move army dialog | [move-army-dialog.md](move-army-dialog.md) | `app/lib/features/game/widgets/move_army_dialog.dart` | Move Army Dialog | active |
| `DLG30001` | Move fleet dialog | [move-fleet-dialog.md](move-fleet-dialog.md) | `app/lib/features/game/widgets/move_fleet_dialog.dart` | Move Fleet Dialog | active |
| `DLG40001` | Transfer to home fleet | [transfer-to-home-fleet-dialog.md](transfer-to-home-fleet-dialog.md) | `app/lib/features/game/widgets/transfer_to_home_fleet_dialog.dart` | Transfer to Home Fleet Dialog | active |
| `DLG50001` | Turn news dialog | [turn-news-dialog.md](turn-news-dialog.md) | `app/lib/features/game/widgets/turn_news_dialog.dart` | Turn news | active |
| `DLG60001` | Next turn confirmation | [next-turn-confirmation.md](next-turn-confirmation.md) | TBD | — | draft |
| `OVL10001` | Game start intro | [game-start-intro-overlay.md](game-start-intro-overlay.md) | `app/lib/features/game/dialogue/game_start_intro_overlay.dart` | Game Start Intro Overlay | active |
| `OVL20001` | Victory overlay | [victory-overlay.md](victory-overlay.md) | `app/lib/features/game/flame/victory_overlay.dart` | Victory | active |
| `OVL30001` | Overture dialogue | [overture-dialogue-overlay.md](overture-dialogue-overlay.md) | `app/lib/features/game/dialogue/overture_dialogue_overlay.dart` | Overture Dialogue Overlay | active |
| `OVL40001` | Call to arms dialogue overlay | [call-to-arms-dialogue-overlay.md](call-to-arms-dialogue-overlay.md) | `app/lib/features/game/dialogue/call_to_arms_dialogue_overlay.dart` | Call to Arms Dialogue Overlay | active |
| `OVL50001` | Pending intervention overlay | [pending-intervention-overlay.md](screens/pending-intervention-overlay.md) | `app/lib/features/game/dialogue/intervention_dialogue_overlay.dart` | Dialogue | active |
| `OVL60001` | Observe mode overlay | [observe-mode.md](observe-mode.md) | TBD | — | draft |
| `OVL70001` | Player turn event feed | [player-turn-event-feed.md](player-turn-event-feed.md) | TBD | — | draft |
| `OVL80001` | Tribe first contact herald | [tribe-first-contact-overlay.md](tribe-first-contact-overlay.md) | `app/lib/features/game/dialogue/tribe_first_contact_overlay.dart` | Tribe First Contact Overlay | active |
| `SYS10001` | Debug log viewer | — | `app/lib/features/debug_log/debug_log_viewer_screen.dart` | — | draft |
| `SYS20001` | Debug console panel | [debug-console-panel.md](debug-console-panel.md) | TBD | — | draft |

Add new rows at the bottom of the sub-flow group. Gaps in `####` are intentional only when reserved in an open PR.

---

## Component specs (`SPEC/ui/components/`)

Reusable composites referenced by screen specs (no screen ID):

| Document | Widget | Used by |
|----------|--------|---------|
| (create as needed) | `Ct*` widgets | See [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) |

When extracting a composite used in 2+ screens, add a component spec before duplicating layout tables in screen specs.

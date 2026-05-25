# UI Screen Registry

**SPEC/ui** — Canonical index of player-app screen IDs. Assign IDs per [`.cursor/rules/colonizethis-ui-documentation.mdc`](../../.cursor/rules/colonizethis-ui-documentation.mdc). **Do not renumber** existing IDs; add new rows only.

**Code:** `app/lib/config/ui_screen_ids.dart` — every **active** row must have a matching `static const`.

---

## Categories (3-letter codes)

Major flows only; keep this table small.

| Code | Flow | Sub-flow digits (4th char) |
|------|------|----------------------------|
| `SHEL` | App shell, main menu, setup, initializing | `1` menu/shell route, `2` game setup, `3` game initializing |
| `GAME` | In-game route hosts | `1` game screen, `2` production route, `3` diplomacy routes, `4` technology route |
| `MAP` | Map widget and map-attached UI | `1` map area/widget, `2` province/sea-zone overlay |
| `UNIT` | Unit management panels and train dialogs | `1` civilian, `2` military, `3` naval, `4` train civilians, `5` train military |
| `DIPL` | Diplomacy panels and grant flows | `1` diplomacy panel/screen, `2` grant/subsidy dialog |
| `PROD` | Production surfaces | `1` production panel/screen, `2` commodity breakdown dialog |
| `TECH` | Technology surfaces | `1` technology panel/screen |
| `CMPT` | Combat and quick battle | `1` mode choice, `2` quick battle screen, `3` deployment, `4` action selector, `5` result dialog |
| `OVL` | Full-screen overlays and narrative UI | `1` game-start intro, `2` victory, `3` overture dialogue, `4` call-to-arms, `5` pending intervention, `6` observe mode |
| `DLG` | Modal dialogs (non-route) | `1` leader selection, `2` move army, `3` move fleet, `4` transfer home fleet, `5` turn news, `6` next-turn confirm (if spec-owned) |
| `SYS` | System/debug surfaces | `1` debug log viewer, `2` debug console panel |

---

## Registry

Status: `draft` = ID reserved, spec incomplete; `active` = spec + Widgetbook + code binding expected.

| ID | Title | Spec | Implementation | Widgetbook | Status |
|----|-------|------|----------------|------------|--------|
| `SHEL10001` | Shell screen | [shell-screen.md](shell-screen.md) | `app/lib/features/shell/shell_screen.dart` | Shell Screen | active |
| `SHEL10002` | Main menu (CtMainMenu) | [main-menu.md](main-menu.md) | `app/lib/widgets/main_menu.dart` | Main Menu | active |
| `SHEL20001` | Game setup (CtGameSetup) | [game-setup.md](game-setup.md) | `app/lib/widgets/game_setup.dart` | Game Setup | active |
| `SHEL30001` | Game initializing | [game-initializing.md](game-initializing.md) | TBD | — | draft |
| `GAME10001` | Game screen | [game-screen.md](game-screen.md) | `app/lib/features/game/flame/game_screen.dart` | Game Screen | active |
| `GAME20001` | Production screen | [production-panel.md](production-panel.md) | `app/lib/features/game/screens/production_screen.dart` | (panel stories) | active |
| `GAME30001` | Diplomacy screen | [diplomacy-panel.md](diplomacy-panel.md) | `app/lib/features/game/screens/diplomacy_screen.dart` | — | active |
| `GAME30002` | Diplomacy detail screen | [diplomacy-panel.md](diplomacy-panel.md) | `app/lib/features/game/screens/diplomacy_detail_screen.dart` | — | draft |
| `GAME40001` | Technology screen | [technology-panel.md](technology-panel.md) | `app/lib/features/game/screens/technology_screen.dart` | — | active |
| `MAP10001` | Empire overview / map area | [empire-overview.md](empire-overview.md) | `app/lib/features/game/widgets/game_map_area.dart` | Map Widget | active |
| `MAP20001` | Province sea-zone overlay | [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md) | `app/lib/features/game/widgets/province_sea_zone_detail_overlay.dart` | — | active |
| `UNIT10001` | Civilian units panel | [civilian-units-panel.md](civilian-units-panel.md) | TBD | Civilian Units Panel | active |
| `UNIT20001` | Military units panel | [military-units-panel.md](military-units-panel.md) | TBD | Military Units Panel | active |
| `UNIT30001` | Naval units panel | [naval-units-panel.md](naval-units-panel.md) | TBD | Naval Units Panel | active |
| `DLG10001` | New game leader selection | [new-game-leader-selection-dialog.md](new-game-leader-selection-dialog.md) | TBD | New Game Leader Selection Dialog | active |
| `DLG20001` | Move army dialog | [move-army-dialog.md](move-army-dialog.md) | TBD | Move Army Dialog | active |
| `DLG30001` | Move fleet dialog | [move-fleet-dialog.md](move-fleet-dialog.md) | TBD | Move Fleet Dialog | active |
| `DLG40001` | Transfer to home fleet | [transfer-to-home-fleet-dialog.md](transfer-to-home-fleet-dialog.md) | TBD | Transfer to Home Fleet Dialog | active |
| `OVL10001` | Game start intro | [game-start-intro-overlay.md](game-start-intro-overlay.md) | TBD | Game Start Intro Overlay | active |
| `OVL20001` | Victory overlay | [victory-overlay.md](victory-overlay.md) | TBD | Victory | active |
| `OVL30001` | Overture dialogue | [overture-dialogue-overlay.md](overture-dialogue-overlay.md) | TBD | Overture Dialogue Overlay | active |
| `CMPT20001` | Quick battle screen | [quick-battle-screen.md](quick-battle-screen.md) | TBD | Quick Battle Screen | active |
| `SYS10001` | Debug log viewer | — | `app/lib/features/debug_log/debug_log_viewer_screen.dart` | — | draft |

Add new rows at the bottom of the sub-flow group. Gaps in `####` are intentional only when reserved in an open PR.

---

## Component specs (`SPEC/ui/components/`)

Reusable composites referenced by screen specs (no screen ID):

| Document | Widget | Used by |
|----------|--------|---------|
| (create as needed) | `Ct*` widgets | See [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) |

When extracting a composite used in 2+ screens, add a component spec before duplicating layout tables in screen specs.

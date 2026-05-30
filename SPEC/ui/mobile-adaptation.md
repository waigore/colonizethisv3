# Mobile adaptation

**SPEC/ui** — Requirements for Flutter screens on small and narrow viewports. Applies to all screen-level widgets in the catalog (e.g. CtMainMenu, CtGameSetup). Authority: UXD 03; derives from GDD/TDD.

---

## Design requirement

When designing screens for the app, **mobile must be considered from the start.** Layouts, wireframes, and component choices should account for narrow viewports (~320 dp and up) and short viewports. It may be **necessary to create a mobile-only mockup in Widgetbook** (e.g. a use case that only makes sense or is primarily intended for the mobile viewport) in addition to, or instead of, a single responsive story. When in doubt, add a dedicated mobile viewport use case so that mobile layout and behavior can be reviewed in isolation.

---

## Scope

- **Target:** Phones and narrow/short viewports (min ~320 dp width; height may be short).
- **Screens:** Every screen designed in Widgetbook must behave correctly on mobile: no overflow, usable touch targets, readable layout. This spec defines the rules; individual screen specs (main-menu, game-setup, etc.) implement them.

---

## Rules

### 1. Touch targets

- Interactive elements (buttons, list tiles, dropdowns) must have **at least 44 dp** in the smallest dimension (already required in UXD 03). Buttons in Main Menu and Game Setup use 48 dp height; keep that or larger.

### 2. Content width and centering

- Content columns use a **max width of 400 dp** so that on tablets/desktop the layout doesn’t stretch. On narrow viewports (&lt; 400 dp) the content uses full width (minus padding). Content is **centered** (e.g. `Center` + `ConstrainedBox(maxWidth: 400)`).

### 3. Scroll on overflow

- **Full-screen screens** (Main Menu, Game Setup, etc.) must **scroll** when content overflows the viewport. Use `SingleChildScrollView` (or equivalent) so that on short viewports the user can scroll to reach all actions. No unreachable content.

### 4. Narrow viewport layout (breakpoints)

This rule covers four normalised Flutter dp breakpoints, each matching a per-screen mockup `@media` rule:

- **`< 600 dp`** — in-game shell narrow adaptations.
- **`< 500 dp`** — Game Setup stacked rows.
- **`≤ 500 dp`** — Diplomacy faction-row stacked layout (action buttons wrap below info, left-aligned). Source: [diplomacy-panel.md](diplomacy-panel.md) § Responsive layout; `SPEC/ui/mockups/GAME30001-diplomacy-panel.html` `@media (max-width: 500px)`.
- **`≤ 430 dp`** — Main Menu extra-tight padding and letter-spacing.

#### Game Setup (`< 500 dp`)

- Each player-slot row uses a **stacked layout**: slot label on one line, nation dropdown full width on the next, leader dropdown full width below. Above the breakpoint, one row: label | nation | leader. Source: [game-setup.md](game-setup.md) and `SPEC/ui/mockups/SHEL20001-game-setup.html` `@media (max-width:499px)`.

#### Main Menu (`≤ 430 dp`)

- Below `430 dp` viewport width the menu container compacts and button labels reduce letter-spacing per `SPEC/ui/mockups/SHEL10002-main-menu.html` `@media (max-width: 430px)`:
  - Menu container padding compacts to `24 px 12 px` (mockup `.menu-container` override).
  - Wood-panel `CtNinePatchButton` labels reduce `letter-spacing` from `0.08em` to `0.04em` (mockup `.menu-btn` override).
- Above `430 dp` the vertical list of buttons keeps its default padding and letter-spacing; only scroll is required (see §3).
- Source: [main-menu.md](main-menu.md) § Responsive rules; `SPEC/ui/mockups/SHEL10002-main-menu.html`.

#### In-game shell (`< 600 dp`)

- Below `600 dp` the in-game shell adopts the narrow chrome defined in [in-game-shell-narrow.md](in-game-shell-narrow.md) and [empire-buttons.md](empire-buttons.md): the top bar carries only the hamburger and the turn counter, the **Debug log** lives in the hamburger side menu, and empire actions stay on the map left rail (rendered at the narrow measurements below).
- The following measurements are normative for the narrow chrome. They mirror `SPEC/ui/mockups/GAME10001-game-screen.html` `@media (max-width:600px)` and the layout sections of [in-game-shell-narrow.md](in-game-shell-narrow.md):

| Element             | Narrow (`< 600 dp`)                                            | Default (`≥ 600 dp`)                                | Source                                                                                                                  |
|---------------------|----------------------------------------------------------------|-----------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| Minimap panel       | 90 × 70 dp                                                     | `clamp(100, 15vw, 160) × clamp(80, 12vw, 120)` dp   | `GAME10001-game-screen.html` `.minimap-panel @media`; [empire-overview.md](empire-overview.md) § Region minimap          |
| Left-rail buttons   | 26 × 26 dp                                                     | 36 × 36 dp                                          | `GAME10001-game-screen.html` `.empire-btn @media`; [empire-buttons.md](empire-buttons.md) § Display                       |
| Corner controls     | 24 × 24 dp                                                     | 32 × 32 dp                                          | `GAME10001-game-screen.html` `.corner-btn @media`; [empire-overview.md](empire-overview.md) § Corner controls            |
| Players bar         | Hidden (not present in widget tree)                            | Visible (per-player chip strip)                     | `GAME10001-game-screen.html` `.players-bar @media`                                                                       |
| Province / sea detail | Full-width bottom sheet, height ~33 vh, accent-dim top border | Right side panel, width 320 dp                       | `GAME10001-game-screen.html` `.province-panel @media`; [in-game-shell-narrow.md](in-game-shell-narrow.md) § Province/sea zone detail overlay |
| Victory overlay (OVL20001) | Laurel `24` px, title `titleMedium`, body `bodyMedium`, action buttons stacked in a vertical `Column` (full-width) | Laurel `28` px, title `headlineSmall`, body `bodyLarge`, actions in a `Wrap` row (12 dp spacing) | [victory-overlay.md](victory-overlay.md) § Narrow viewport; `OVL20001-game-victory-overlay.html` `.victory-actions { flex-wrap:wrap }` + `clamp()` lower bounds |

- The wide-layout widgets themselves (left rail, corner controls, minimap, players bar, province panel, victory overlay) are introduced by their per-screen alignment issues; this section codifies the **narrow measurements** so the cross-cutting adaptation work has a single authoritative source.

### 5. Safe area

- Use `SafeArea` (or equivalent) so that content and buttons are not obscured by system UI (notches, status bar, navigation bar).

### 6. Widgetbook verification

- For each screen in Widgetbook, provide at least one **mobile viewport** use case: render the widget inside a constrained viewport (e.g. 360×640 dp) so that mobile layout and scroll can be verified without resizing the window. Document in the widget catalog or story name (e.g. "Default (mobile)").
- **Mobile-only mockups:** When a screen's mobile layout differs meaningfully from desktop (e.g. stacked vs row, different navigation), consider adding a **mobile-only** Widgetbook use case that is designed and named for the mobile viewport (e.g. "Mobile layout" or "Narrow — stacked slots"). This makes mobile the primary frame for that story and ensures the mobile design is reviewed explicitly.

### 7. Minimum-viewport pin (`kMinViewportWidth = 320`)

The minimum supported viewport width is **`kMinViewportWidth = 320` dp** (from `app/lib/config/constants.dart`). The minimum touch-target size is **`kMinTouchTargetSize = 44` dp** (matching §1 and UXD 03). Both constants are normative for screen tests that pin the AC below.

#### Acceptance criteria

- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **CtMainMenu** (`plain` and `pixelArt` variants, all `MainMenuState` values) is rendered with the running theme, then `WidgetTester.takeException()` returns `null`, no `RenderFlex` overflow exception is thrown by the framework, and every visible `CtNinePatchButton` reports a rendered height ≥ `kMinTouchTargetSize`.
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **CtGameSetup** (any `GameSetupVariant` × `GameSetupState`) is rendered with the running theme, then `WidgetTester.takeException()` returns `null`, no `RenderFlex` overflow exception is thrown, and the six player-slot rows render in the stacked layout (label / nation dropdown / leader dropdown) defined by §4 Game Setup.
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **ProductionPanel** is rendered with the full or partial production-panel test fixtures, then `WidgetTester.takeException()` returns `null` and both `Available` and `Allocation` labels render (the narrow `_ProductionPanelNarrowLayout` path selected at `MediaQuery.sizeOf(context).width < kNarrowBreakpoint`, per [production-panel.md](production-panel.md) § Layout).
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **DiplomacyPanel** is rendered with the debug-init-game fixture, then `WidgetTester.takeException()` returns `null`, the first discovered faction row's body widget is a `Column` (narrow variant at `≤ kDiplomacyRowNarrowMaxWidth`), and the bottom mode-bar filter chips wrap onto a second run instead of overflowing horizontally (per [diplomacy-panel.md](diplomacy-panel.md) § Mode bar).
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **TechnologyPanel** is rendered inside the same `SingleChildScrollView` + 16 dp padding host as `TechnologyScreen`’s Slots tab (`_SlotsBody`), with the debug-init-game fixture, then `WidgetTester.takeException()` returns `null`, three `ResearchSlotCard` widgets and one `LockedResearchSlotCard` (slot 4) render, and the `RESEARCHED TECHS` section heading is visible (slot cards and researched grid scroll vertically within the host per [technology-panel.md](technology-panel.md) § Body).
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **CivilianUnitsPanel** is rendered with the debug-init-game fixture and the first seeded player as the human, then `WidgetTester.takeException()` returns `null` and the `Civilian Units` title from [civilian-units-panel.md](civilian-units-panel.md) renders (the shared `UnitsPanelShell` chrome — `max-width: 400` `ConstrainedBox` + 8 dp padding + `ListView` body + per-unit `UnitsEntityActionRow` with `iconOnlyBreakpoint = 280` — must fit within the 304 dp content column without overflowing).
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **MilitaryUnitsPanel** is rendered with the debug-init-game fixture (`topology = const MapTopology()`, `draftOrders = const Orders()`) and the first seeded player as the human, then `WidgetTester.takeException()` returns `null` and the `Military Units` title from [military-units-panel.md](military-units-panel.md) renders (the shared `UnitsPanelShell` chrome plus Army `ExpansionTile` rows and per-army `UnitsEntityActionRow` must fit within the 304 dp content column without overflowing).
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **NavalUnitsPanel** is rendered with the debug-init-game fixture (`topology = result.combinedTopology` from `getDebugInitGameResult()`), the first seeded player as the human, and the brass nine-patch button asset (`assets/images/ui_button_nine_patch.png`) pre-warmed into the Flame image cache, then `WidgetTester.takeException()` returns `null` and the `Naval Units` title from [naval-units-panel.md](naval-units-panel.md) renders (the shared `UnitsPanelShell` chrome plus header Combine + select-all checkbox, Fleet `ExpansionTile` rows, and per-fleet `UnitsEntityActionRow` must fit within the 304 dp content column without overflowing, with `_panelConstraints` resolving to `UnitsPanelShell.defaultPanelConstraints` because `MediaQuery.sizeOf(context).width < 1280` per the naval panel `_desktopViewportThreshold`).
- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when **ProvinceSeaZoneDetailOverlay** is rendered against the `province_overlay_demo_data` fixture (`displayId = sampleProvinceIdForOverlay`, `selectedTileKey = sampleTileKeyForProvinceOverlay`) inside a bottom-anchored `SizedBox(height: viewport.height * 0.33)` host that mirrors `GameMapNarrowDetailOverlaySlot`, then `WidgetTester.takeException()` returns `null`, the `Province` header label renders, and the narrow `CtTabStrip` body exposes the `Tile` tab label (the six-tab Tile / Political / Economic / Military / Civilian / Naval narrow layout per [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md) § Tabs and [in-game-shell-narrow.md](in-game-shell-narrow.md) § Province/sea zone detail overlay must fit within the 320 dp column without horizontal overflow).

#### Pinning tests

The above ACs are pinned by:

- `app/test/mobile_320dp_min_viewport_test.dart` — Main Menu + Game Setup (Refs #2870 S10).
- `app/test/panels_320dp_min_viewport_test.dart` — ProductionPanel, DiplomacyPanel, TechnologyPanel, and ProvinceSeaZoneDetailOverlay (Refs #2870 S10). The ProvinceSeaZoneDetailOverlay pin hosts the overlay inside a bottom-anchored `SizedBox(height: viewport.height * 0.33)` to mirror `GameMapNarrowDetailOverlaySlot`'s 33 vh slot so the narrow `CtTabStrip` body lays out under the same constraints it would in the running game.
- `app/test/unit_panels_320dp_min_viewport_test.dart` — CivilianUnitsPanel, MilitaryUnitsPanel, and NavalUnitsPanel (Refs #2870 S10). The Naval pin pre-warms the brass nine-patch asset into the Flame image cache (mirroring the helper used by the DiplomacyPanel group in `panels_320dp_min_viewport_test.dart`) so the `FleetExpansionTile` `CtNinePatchButton` chrome lays out at its true declared height instead of falling back to a `SizedBox.shrink()` silhouette.

---

## Summary table

| Requirement        | Main Menu          | Game Setup        | Diplomacy panel       | In-game shell        |
|--------------------|--------------------|-------------------|-----------------------|----------------------|
| Max width 400 dp   | ✓                  | ✓                 | —                     | —                    |
| Scroll on overflow | ✓                  | ✓                 | —                     | —                    |
| Safe area          | ✓                  | ✓                 | ✓                     | ✓                    |
| 44 dp touch        | ✓ (48 dp)          | ✓ (48 dp)         | ✓                     | ✓                    |
| Narrow breakpoint  | ✓ tight ≤ 430 dp   | ✓ stacked < 500 dp | ✓ row stacked ≤ 500 dp | ✓ side menu < 600 dp |

---

## References

- Main menu: [main-menu.md](main-menu.md) § Responsive rules — layout, scroll, ≤ 430 dp tight-layout rule.
- Game Setup: [game-setup.md](game-setup.md) — layout, narrow breakpoint, scroll.
- Diplomacy panel: [diplomacy-panel.md](diplomacy-panel.md) § Responsive layout — faction-row wrapping at ≤ 500 dp.
- In-game shell (narrow): [in-game-shell-narrow.md](in-game-shell-narrow.md) — side menu, top bar, province/sea detail overlay; [empire-buttons.md](empire-buttons.md) — empire buttons; [empire-overview.md](empire-overview.md) — minimap, corner controls.
- Per-screen mockups (visual source of truth for `@media` rules normalised above): `SPEC/ui/mockups/SHEL10002-main-menu.html`, `SPEC/ui/mockups/SHEL20001-game-setup.html`, `SPEC/ui/mockups/GAME30001-diplomacy-panel.html`, `SPEC/ui/mockups/GAME10001-game-screen.html`.
- UXD 03: acceptance criteria and touch targets.

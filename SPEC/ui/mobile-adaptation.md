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

### 4. Narrow viewport layout (breakpoint)

- **Breakpoint:** 500 dp width. Below that, screens may switch to a **narrow layout** (e.g. stacked rows, single-column forms) when the default horizontal layout would be cramped.
- **Game Setup:** Below the breakpoint, each player-slot row uses a **stacked layout**: slot label on one line, nation dropdown full width on the next, leader dropdown full width below. Above the breakpoint, one row: label | nation | leader.
- **Main Menu:** No breakpoint change; vertical list of buttons already suits narrow width. Only scroll is required (see §3).

### 5. Safe area

- Use `SafeArea` (or equivalent) so that content and buttons are not obscured by system UI (notches, status bar, navigation bar).

### 6. Widgetbook verification

- For each screen in Widgetbook, provide at least one **mobile viewport** use case: render the widget inside a constrained viewport (e.g. 360×640 dp) so that mobile layout and scroll can be verified without resizing the window. Document in the widget catalog or story name (e.g. "Default (mobile)").
- **Mobile-only mockups:** When a screen's mobile layout differs meaningfully from desktop (e.g. stacked vs row, different navigation), consider adding a **mobile-only** Widgetbook use case that is designed and named for the mobile viewport (e.g. "Mobile layout" or "Narrow — stacked slots"). This makes mobile the primary frame for that story and ensures the mobile design is reviewed explicitly.

---

## Summary table

| Requirement        | Main Menu | Game Setup |
|-------------------|-----------|------------|
| Max width 400 dp  | ✓         | ✓          |
| Scroll on overflow| ✓         | ✓          |
| Safe area         | ✓         | ✓          |
| 44 dp touch       | ✓ (48 dp) | ✓ (48 dp)  |
| Narrow breakpoint | —         | ✓ stacked  |

---

## References

- Main menu: [main-menu.md](main-menu.md) — layout, scroll.
- Game Setup: [game-setup.md](game-setup.md) — layout, narrow breakpoint, scroll.
- UXD 03: acceptance criteria and touch targets.

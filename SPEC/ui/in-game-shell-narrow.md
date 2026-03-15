# In-game shell: narrow viewport (side menu)

**SPEC/ui** — When the in-game viewport width is below the breakpoint, the top bar shows only the menu trigger and turn counter; empire buttons move into a side menu opened by swipe or hamburger. Authority: [empire-overview.md](empire-overview.md), [empire-buttons.md](empire-buttons.md), [mobile-adaptation.md](mobile-adaptation.md).

---

## Breakpoint

- **Narrow:** viewport width **< 600 dp**. Side menu and reduced top bar apply.
- **Wide:** viewport width **≥ 600 dp**. No side menu; empire buttons remain in the top bar (current behaviour).

---

## Top bar (narrow only)

When width < 600 dp:

- **Left:** Hamburger control (menu trigger). Same control as the existing pause-menu trigger; on narrow it opens the **side menu** (which contains empire buttons). Pause menu options (e.g. Debug log, Resume) may be included in the side menu or kept behind a secondary action; spec: hamburger opens the side menu.
- **Center/right:** Turn counter only (e.g. "Next turn (N / year)" or equivalent). No empire buttons in the top bar.
- Empire buttons are **not** shown in this row; they appear only in the side menu.

---

## Side menu (narrow only)

- **Visibility:** Shown only when viewport is narrow (width < 600 dp). Not present on wide.
- **Open:** Swipe in from the **left** edge, or tap the **hamburger** in the top bar.
- **Close:** Swipe the menu to the **left** (drag to close), or tap a **close (cross)** button in the menu.
- **Content:** All [empire buttons](empire-buttons.md) in order: Production, Civilian Units, Military Units, Diplomacy, Technology. Same behaviour as in the wide top bar (each opens the same panel/screen).
- **Layout:** Pixel-art layout. Uses the same styling as the rest of the UI: **CtPanel** (or equivalent framed container), **CtNinePatchButton** for each empire button, same icons and labels as [game-toolbar-icons.md](game-toolbar-icons.md). No Material chrome.
- **Width:** Menu has a fixed or max width (e.g. 280 dp or 80% of viewport) so the map remains partially visible or dimmed when open; implementation may use a drawer or custom overlay.
- **Optional:** The side menu may include secondary actions (e.g. Debug log, Resume) at the bottom so the same hamburger serves both empire actions and pause menu.

---

## Wireframe (narrow)

```
+------------------------------------------+
| [≡]     Next turn (42 / 1650)            |  <- top bar: hamburger + turn counter
+------------------------------------------+
| [Old World] [New World]                  |  <- region tabs (unchanged)
+------------------------------------------+
|                                          |
|              Map area                     |
|                                          |
+------------------------------------------+

Side menu (when open, overlaid from left):
+------------------+
| [×] Close        |
|                  |
| [icon] Production|
| [icon] Civilian  |
| [icon] Military  |
| [icon] Diplomacy  |
| [icon] Technology|
+------------------+
```

---

## Acceptance criteria

- **Given** the in-game shell is shown and viewport width is **≥ 600 dp**, **when** the user looks at the top bar, **then** the empire buttons (Production, Civilian Units, Military Units, Diplomacy, Technology) are visible in the top bar and there is no side menu.
- **Given** the in-game shell is shown and viewport width is **< 600 dp**, **when** the user looks at the top bar, **then** only the hamburger (menu trigger) and the turn counter are shown; empire buttons are not in the top bar.
- **Given** viewport width is **< 600 dp** and the side menu is closed, **when** the user swipes in from the left edge, **then** the side menu opens and displays all empire buttons in pixel-art style.
- **Given** viewport width is **< 600 dp** and the side menu is closed, **when** the user taps the hamburger in the top bar, **then** the side menu opens and displays all empire buttons.
- **Given** the side menu is open, **when** the user swipes the menu to the left (drag to close), **then** the side menu closes.
- **Given** the side menu is open, **when** the user taps the close (cross) button in the menu, **then** the side menu closes.
- **Given** the side menu is open, **when** the user taps an empire button, **then** the same panel or screen opens as when that button is used in the wide top bar, and the side menu closes (or remains open; spec: close on action so the user sees the panel).
- **Given** viewport width is **< 600 dp**, **when** the side menu is built, **then** it uses pixel-art layout (CtPanel, CtNinePatchButton, same icons as game-toolbar-icons) and no Material buttons or chrome.

---

## References

- [empire-buttons.md](empire-buttons.md) — list and order of empire buttons, styling
- [empire-overview.md](empire-overview.md) — in-game shell
- [mobile-adaptation.md](mobile-adaptation.md) — breakpoints, touch targets
- [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) — CtPanel, CtNinePatchButton

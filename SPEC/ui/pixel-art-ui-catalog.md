# Pixel-art UI catalog and Material ban

**SPEC/ui** — Source of truth for UI component catalog when building the Flutter shell for ColonizeThis. Derives from GDD/TDD and UI design rules (UXD 02/03/07).

---

## Material design ban

- **No Material chrome:** The app **must not** use Material or Cupertino widgets for visible chrome: no `ElevatedButton`, `FilledButton`, `TextButton`, `OutlinedButton`, `AlertDialog`, `Dialog`, `Card`, `ChoiceChip`, `Chip`, `Slider`, `DropdownButton`, `ListTile`, `AppBar`, or Material theming for these.
- **Plumbing only:** Material is allowed **only** where Flutter requires it for plumbing (e.g. `MaterialApp`, `DefaultTabController`, `ThemeData`, focus/overlay internals). These must not leak default Material visuals into the UI.
- **CI/test enforcement:** Widget tests should assert against the Ct-* catalog types (e.g. `CtNinePatchButton`, `CtDropdown`, `CtSlider`, `CtScreenShell`) rather than Material button/slider types.

---

## Pixel-art component catalog (Flutter shell)

- **CtNinePatchButton:** Primary/secondary/action button. Uses Flame `NineTileBoxWidget` with `ui_button_nine_patch.png`. All tappable controls must be built from this (or a component that wraps it).
- **CtDialogShell:** Pixel-art dialog frame (nine-patch border, solid interior). Replaces `AlertDialog`/`Dialog` for all popups.
- **CtPanel:** Pixel-art framed panel for in-screen sections (production, technology, diplomacy, victory overlays, unit panels). Replaces `Card`.
- **CtChoiceChip:** Small, pixel-friendly toggle chip used for region/visibility toggles and similar controls. Replaces `ChoiceChip`.
- **CtSlider:** Pixel-art slider (rectangular track, square handle) for integer values. Used in Production Allocation; replaces `Slider`.
- **CtDropdown:** Pixel-art dropdown (nine-patch button + modal list inside `CtDialogShell`). Replaces `DropdownButton`.
- **CtScreenShell:** Full-screen pixel-art shell: background + framed content area + title bar text. Replaces visible use of `Scaffold`/`AppBar` in user-facing screens.

Any new UI component must either:

1. Be built from this catalog, or
2. Extend it in this spec first (new Ct-* widget with props, behavior, and pixel-art requirements) before implementation.

---

## Pixel-art requirements for components

- **Assets:** All framed components (buttons, dialogs, panels, shells) must use nine-patch or explicit pixel borders; no Material shadows, rounded corners, or elevation.
- **Typography:** Follow UXD 02 for fonts and sizes; no default Material typography without explicit spec.
- **States:** Hover/pressed/disabled states are implemented via palette shifts, bobbing, or overlays as described in per-component specs (e.g. `main-menu.md`, `buttons-nine-patch.md`), not Material ink ripples.

---

## Commodity / resource labels

- Whenever the UI shows a **resource or commodity** by id or human-readable name (lists, province overlay, production, tooltips, etc.), show the **pixel commodity icon** (`ResourceIcon` / `ResourceLabelInline` in app widgets) **immediately to the left** of the text, with a small gap (e.g. 4 logical px). If no icon asset exists for that id, keep the reserved icon width (empty box) so layout stays aligned.
- Do not show resource/commodity names as plain text-only rows in new shell UI unless the spec explicitly exempts that surface.

---

## References

- [buttons-nine-patch.md](buttons-nine-patch.md)
- [game-toolbar-icons.md](game-toolbar-icons.md)
- [main-menu.md](main-menu.md)
- [game-setup.md](game-setup.md)
- [production-panel.md](production-panel.md)
- [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md)


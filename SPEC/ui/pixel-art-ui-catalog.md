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
- **CtDialogShell:** Pixel-art dialog frame (nine-patch border, solid interior). Replaces `AlertDialog`/`Dialog` for all popups. **Layout:** The framed area grows with body content up to `maxHeight` (no empty vertical filler at `maxHeight` when content is shorter). When content exceeds `maxHeight`, **one** outer vertical scroll on the shell exposes the full body (including footer actions). Dialog bodies should use `Column(mainAxisSize: MainAxisSize.min)` and must not use vertical `Expanded` / `Flexible` against the shell’s inner height; nested inner vertical scroll regions for the primary flow are discouraged—prefer a single shell scroll. Secondary scrolls (e.g. horizontal table pan, fixed-height transfer lists) remain valid where specified.
- **CtPanel:** Pixel-art framed panel for in-screen sections (production, technology, diplomacy, victory overlays, unit panels). Replaces `Card`.
- **CtChoiceChip:** Small, pixel-friendly toggle chip used for region/visibility toggles and similar controls. Replaces `ChoiceChip`.
- **CtSlider:** Pixel-art slider (rectangular track, square handle) for integer values. Used in Production Allocation; replaces `Slider`.
- **CtDropdown:** Pixel-art dropdown (nine-patch button + modal list inside `CtDialogShell`). Replaces `DropdownButton`.
- **CtScreenShell:** Full-screen pixel-art shell: background + framed content area + title bar text. Replaces visible use of `Scaffold`/`AppBar` in user-facing screens.
- **CtGradients:** Shared utility (not a widget) exposing the canonical gradients used by every Ct-* component: `.buttonGradient` (top→bottom `--surface-lite`→`--surface` for tappable button surfaces), `.panelGradient` (top→bottom `--surface`→`--bg` for `CtPanel` / `CtDialogShell`), `.rowGradient` (left→right `--bg`→`--surface` for list rows), `.topBarGradient` (top→bottom `--surface-lite`→`--surface` for `CtScreenShell` / `CtTopBar`). All colors resolve from § *Editorial-monocle palette* tokens (`--bg`, `--surface`, `--surface-lite`). No hard-coded hex literals.
- **CtBrassDivider:** Ornate horizontal divider used to separate sections inside `CtPanel` / `CtDialogShell` and similar surfaces. Replaces Material `Divider`. **Key props:** none — the widget paints itself based purely on parent width. **Pixel-art requirements:** 8px fixed height; 1px gradient line (`--accent-dim` at midpoint fading to transparent at both ends); 8x8 diamond centerpiece (fill `--accent`, 1px `--accent-bright` outline) centered horizontally; three dots per side, 2px radius, 4px spacing between centers, first dot 6px from the diamond edge, color `--accent-dim`. No asset dependency. **Forbidden Material counterpart:** `Divider`, `VerticalDivider`.
- **CtSectionLabel:** Small-caps section label with a brass-tinted bottom border. Used to head sub-sections inside panels (production category bands, diplomacy faction groups, etc.). Replaces Material `ListSubheader` / similar. **Key props:** `text` (label string); optional outer `padding`. **Pixel-art requirements:** label text rendered in `--muted`, upper-cased + `FontFeature.enable('smcp')`, font weight `500`; 1px bottom border colored `--accent-dim` spanning the full label container width; 2px vertical padding between the text baseline and the border. No asset dependency. **Forbidden Material counterpart:** `ListSubheader`, `Divider`-only section heads.
- **CtProgressBar:** Horizontal progress bar with optional monospace label. Used for resource fill, build queue progress, and similar `0..1` indicators. Replaces Material `LinearProgressIndicator`. **Key props:** `value` (`double?` clamped to `[0.0, 1.0]`; `null` treated as `0.0`); optional `label` (consumer string rendered 4px to the right of the bar); `enabled` (false → entire widget at 0.4 opacity, shared with `CtNinePatchButton` etc.). **Pixel-art requirements:** 12px fixed height; full available parent width (no intrinsic width); `--surface` track with a 1px `--accent-dim` border; `--accent` fill anchored to inner-left growing left-to-right; fill width interpolates over 120ms using `Curves.easeOut`; 0% renders no fill artifact; 100% touches both inner border edges; optional label uses the dark-theme monospace `TextTheme` slot in `--muted`. No asset dependency. **Forbidden Material counterpart:** `LinearProgressIndicator`, `CircularProgressIndicator` for horizontal progress.

Any new UI component must either:

1. Be built from this catalog, or
2. Extend it in this spec first (new Ct-* widget with props, behavior, and pixel-art requirements) before implementation.

---

## Pixel-art requirements for components

- **Assets:** All framed components (buttons, dialogs, panels, shells) must use nine-patch or explicit pixel borders; no Material shadows, rounded corners, or elevation.
- **Typography:** Follow UXD 02 for fonts and sizes; no default Material typography without explicit spec.
- **States:** Hover/pressed/disabled states are implemented via palette shifts, bobbing, or overlays as described in per-component specs (e.g. `main-menu.md`, `buttons-nine-patch.md`), not Material ink ripples.

---

## Editorial-monocle palette

Canonical color and typography tokens for the dark `editorialMonocle` theme
exposed by `AppThemes.editorialMonocle` (`app/lib/config/themes.dart`). This
table is the **single source of truth** for the running-app theme and is the
authoritative palette cited by `colonizethis-ui-design.mdc` and the UI
visual-fidelity quality gates in `implement-github-issue/SKILL.md` and
`review-pr/SKILL.md`. Per-screen mockups under `SPEC/ui/mockups/` are
**optional**; if present they illustrate this palette in context, but their
absence does not block UI implementation work.

### Color tokens

OKLCH values are the editable source. The Dart implementation in
`app/lib/config/editorial_monocle_palette.dart` converts each triple to the
sRGB hex shown alongside via the Björn Ottosson OKLab → linear-sRGB matrix
plus IEC 61966-2-1 gamma encoding. Tests pin the conversion against these
hex values.

| Token | OKLCH | sRGB (approx.) | Role |
|-------|-------|----------------|------|
| `--bg` | `oklch(16% 0.018 50)` | `#140B07` | Scaffold background |
| `--bg-deep` | `oklch(12% 0.015 45)` | `#0A0403` | Deepest dark (map, deep panels) |
| `--surface` | `oklch(24% 0.015 45)` | `#261D19` | Cards, panels, rows |
| `--surface-lite` | `oklch(30% 0.016 52)` | `#352C27` | Raised surfaces, gradient tops |
| `--fg` | `oklch(88% 0.015 80)` | `#DDD7CD` | Primary text |
| `--muted` | `oklch(65% 0.025 70)` | `#998D7F` | Secondary text, labels |
| `--border` | `oklch(40% 0.020 55)` | `#51453E` | Borders, dividers |
| `--accent` | `oklch(72% 0.14 85)` | `#CD9C1F` | Gold/brass accent |
| `--accent-dim` | `oklch(60% 0.12 82)` | `#A4780E` | Subdued brass |
| `--accent-bright` | `oklch(82% 0.13 90)` | `#E5C057` | Hover/active brass |
| `--danger` | `oklch(62% 0.16 22)` | `#D55759` | War, negative, destructive |
| `--success` | `oklch(62% 0.12 150)` | `#4A9A5E` | Positive, growth |

**WCAG AA notes.** `--fg` on `--bg` measures ~13.6:1 (body-text AA). `--muted`
on `--bg` measures ~6.0:1 (secondary). `--accent` on `--bg` measures ~7.8:1
(decorative/non-text). `--danger` and `--success` on `--bg` measure ≥4.9:1
and ≥5.6:1 respectively so each clears the AA 4.5:1 text bar required for
status indicators.

**Issue #2858 deviation note.** The original issue Design proposal set
`--danger` and `--success` to `L = 0.55`, which yielded ~3.7:1 / ~4.3:1 and
failed the issue's own AA AC of ≥4.5:1. The canonical lightness for both
tokens is therefore raised to `L = 0.62` here; chroma and hue are preserved
so the warm-red / cool-green perceptual identity is unchanged. All other
tokens match the issue's Design proposal verbatim.

### Font stacks

| Role | Stack |
|------|-------|
| Display | `'Iowan Old Style', 'Cinzel', 'Charter', Georgia, serif` |
| Body | `-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif` |
| Mono | `'SF Mono', ui-monospace, Menlo, monospace` |

The Flutter theme realizes Display via `GoogleFonts.cinzel(...)` on
`headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, and
`titleSmall`; Body uses Flutter's platform default (`Roboto` on Android,
system on iOS/desktop) so the system-ui fallback chain applies per OS; Mono
inherits the platform-default monospace family until a dedicated style is
needed.

### Backward compatibility

`AppThemes.colonial` and `AppThemes.colonialPixelArt` remain loadable for
Widgetbook fallback and debug toggles, but the running app's default theme
is `AppThemes.editorialMonocle`. No code path outside Widgetbook and debug
toggles may render a screen in the light colonial theme.

---

## Commodity / resource labels

- Whenever the UI shows a **resource or commodity** by id or human-readable name (lists, province overlay, production, tooltips, etc.), show the **pixel commodity icon** (`ResourceIcon` / `ResourceLabelInline` in app widgets) **immediately to the left** of the text, with a small gap (e.g. 4 logical px). If no icon asset exists for that id, keep the reserved icon width (empty box) so layout stays aligned.
- Do not show resource/commodity names as plain text-only rows in new shell UI unless the spec explicitly exempts that surface.

## Map label capital icon

- The map province-label capital indicator uses `app/assets/icons/ui_icon_map_capital_star.png`.
- The icon is generated via PixelLab and must keep transparent background plus recognizable gold-star silhouette at map-label scale.

---

## References

- [buttons-nine-patch.md](buttons-nine-patch.md)
- [game-toolbar-icons.md](game-toolbar-icons.md)
- [main-menu.md](main-menu.md)
- [game-setup.md](game-setup.md)
- [production-panel.md](production-panel.md)
- [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md)


# Pixel-art UI catalog and Material ban

**SPEC/ui** — Source of truth for UI component catalog when building the Flutter shell for ColonizeThis. Derives from GDD/TDD and UI design rules (UXD 02/03/07).

---

## Material design ban

- **No Material chrome:** The app **must not** use Material or Cupertino widgets for visible chrome: no `ElevatedButton`, `FilledButton`, `TextButton`, `OutlinedButton`, `AlertDialog`, `Dialog`, `Card`, `ChoiceChip`, `Chip`, `FilterChip`, `Slider`, `DropdownButton`, `ListTile`, `SwitchListTile`, generic `IconButton`, generic `Scaffold`, `AppBar`, or Material theming for these.
- **Ct-\* counterparts (per #2914 Phase 0a):** Each banned widget MUST be replaced with the corresponding Ct-\* catalog widget below. The list below is normative for replacement direction; deviations require either an existing Ct-\* widget that already covers the use (cited in the replacement PR) or a SPEC extension adding a new Ct-\* widget before the replacement lands.

| Banned Material widget | Ct-\* counterpart | Notes |
|------------------------|-------------------|-------|
| `ElevatedButton`, `FilledButton`, `TextButton`, `OutlinedButton` | `CtNinePatchButton` | Use `dangerVariant: true` for destructive actions. |
| `AlertDialog`, `Dialog` | `CtDialogShell` (single dialog) or `CtFullScreenDialogueShell` (scrim + dialog scaffold) | `barrierColor` / scrim resolves through `EditorialMonoclePalette.dialogScrim`. |
| `Card` | `CtPanel` | In-screen sections; horizontal-band visual contract. |
| `ChoiceChip`, `Chip`, `FilterChip` | `CtChoiceChip` | Single-select toggle chips. Multi-select pickers compose `CtChoiceChip` rows; no Material `FilterChip` on visible chrome. |
| `Slider` | `CtSlider` | Continuous and discrete (`divisions`) variants both use `CtSlider`. |
| `DropdownButton` | `CtDropdown` | Trigger + modal picker inside `CtDialogShell`. |
| `ListTile`, `SwitchListTile` | `CtToggleSwitch` (paired with `CtSectionLabel` or composed `Row`) | `SwitchListTile`'s combined label + switch composition is reproduced by laying out `CtSectionLabel` (or body text in the active theme `TextTheme` slot) alongside `CtToggleSwitch`; no Material `ListTile` row chrome. |
| Generic `IconButton` | `CtBackButton` (back-affordance chrome) or `CtNinePatchButton` with an icon `child` (action affordance) | "Generic" here means an `IconButton` used as visible chrome — back arrows, glyph-only action buttons, dialog dismiss buttons. Glyph-only affordances that do not fit `CtBackButton`/`CtNinePatchButton` MUST add a new Ct-\* primitive in this catalog before implementation. |
| Generic `Scaffold`, `AppBar` | `CtScreenShell` (which embeds `CtTopBar`) | "Generic" here means a `Scaffold` used as visible screen chrome on a route. `MaterialApp`'s internal `Scaffold` plumbing for routing/overlays remains permitted under the Plumbing-only rule below. |

- **Plumbing only:** Material is allowed **only** where Flutter requires it for plumbing (e.g. `MaterialApp`, `DefaultTabController`, `ThemeData`, focus/overlay internals, the implicit `Scaffold` inside route hosts that mount a Ct-\* surface). These must not leak default Material visuals into the UI.
- **CI/test enforcement:** Widget tests should assert against the Ct-\* catalog types (e.g. `CtNinePatchButton`, `CtDropdown`, `CtSlider`, `CtScreenShell`) rather than Material button/slider types. The `disallowed_ast_patterns` CI gate (`tool/check_disallowed_ast_patterns.dart`) is the enforcement vehicle for `app/lib/features/**` — see issue #2914 Phase 2 G2 for the gate-extension scope that picks up the additions above.

### Acceptance criteria (Material design ban)

- **Given** a developer reads the §Material design ban list, **when** they look for `FilterChip`, `SwitchListTile`, generic `IconButton`, or generic `Scaffold`, **then** each appears in the comma-separated banned-widget list and has a row in the Ct-\* counterparts table identifying the replacement and any usage notes.
- **Given** a feature file under `app/lib/features/**` introduces one of the banned widgets above as visible chrome, **when** the planned `disallowed_ast_patterns` CI gate (issue #2914 Phase 2 G2) runs, **then** the gate fails the build and reports the file/line of the banned widget; until that gate lands, code review must apply the same rule manually using the table above.

---

## Pixel-art component catalog (Flutter shell)

- **CtNinePatchButton:** Primary/secondary/action button for the dark editorial-monocle theme. **Visual contract (per #2859 R1 / S2):** background painted from `CtGradients.buttonGradient` (`--surface-lite` → `--surface`); 1px border in `--border` that shifts to `--accent` on hover; four 10x10 px L-shaped brass corner brackets painted in `--accent` at 0.75 alpha by default and `--accent-bright` at 1.0 alpha on hover; engraved label text drawn with a single 1 px downward drop-shadow (`Offset(0, 1)`, blur `0`, colour `--surface`) over body colour `--accent` (default) / `--accent-bright` (hover); disabled state wraps the widget in 0.4 opacity (shared convention with `CtBackButton`, `CtToggleSwitch`, `CtProgressBar`) and suppresses pointer events. Hover transitions animate over 120 ms (`Curves.easeOut`). The legacy `ui_button_nine_patch.png` parchment asset is no longer required for rendering — the class name `CtNinePatchButton` is preserved for API stability only. **Key props:** `onPressed` (`VoidCallback?`, required); `child` (label/icon, required); `enabled` (default `true`); optional `padding` (defaults to 16 px horizontal / 12 px vertical); `minHeight` (default 48 dp to honour the 44 dp touch target); `dangerVariant` (`bool`, default `false`). All colours resolve from § *Editorial-monocle palette* tokens; no hard-coded hex literals. **Danger variant (per #2863 S2):** when `dangerVariant: true`, the resolved border and the engraved label foreground swap from the brass `--border`/`--accent` family to the `--danger` token (border `--danger`, label `--danger`, hover preserves `--danger` for both); the gradient surface and corner brackets are unchanged. Used by destructive action buttons such as the diplomacy panel `Declare War` button per [diplomacy-panel.md](diplomacy-panel.md) § Action button styling and the move-army war confirmation `Declare war and move` button per [move-army-dialog.md](move-army-dialog.md) § Invade-confirm sub-dialog. All tappable chrome must be built from this (or a component that wraps it). **Forbidden Material counterpart:** `ElevatedButton`, `FilledButton`, `TextButton`, `OutlinedButton`.
- **CtFullScreenDialogueShell:** Reusable full-screen scrim + centered `CtDialogShell` wrapper for blocking dialogue overlays (overture, call-to-arms, intervention, game-start intro per `SPEC/ui/dialogue-presentation.md`). Replaces the duplicated `Stack` → `Material(dialogScrim)` → `Center` → `CtDialogShell` → `Padding` scaffolding previously inlined into each overlay file (issue #2914 S2). **Visual contract:** outer `Stack` paints the `backdrop` widget (the underlying game canvas / app shell) at the bottom; over it the shell paints a full-screen `Material` whose color resolves from the canonical `EditorialMonoclePalette.dialogScrim` token (§ *Dialog scrim*); on top of that, a centered `CtDialogShell` carries the dialog body inside a configurable inner `Padding`. No hard-coded hex literals; the scrim color is the single token from § *Dialog scrim* and the dialog frame inherits the canonical 2px `--accent-dim` border and `CtGradients.panelGradient` background from `CtDialogShell`. The shell renders no title, divider, or layout chrome itself — callers compose those above `body` so per-overlay differences (title ordering, brass divider position, intro line styling) are preserved. **Key props:** `backdrop` (`Widget`, required — the widget tree painted underneath the scrim); `body` (`Widget`, required — the dialog content placed inside the dialog shell); `maxWidth` (`double`, default `520` — forwarded to `CtDialogShell`); `maxHeight` (`double`, default `600` — forwarded to `CtDialogShell`); `padding` (`EdgeInsetsGeometry`, default `EdgeInsets.all(20)` — inner padding wrapping `body` inside the dialog frame). **Forbidden Material counterpart:** open-coded `Stack` + `Material(color: Colors.black54)` + `Dialog` scaffolds; ad-hoc per-file `_buildScrimmedShell` helpers replicating the same pattern.
- **CtDialogShell:** Dark editorial-monocle dialog frame. Replaces `AlertDialog`/`Dialog` for all popups. **Visual contract (per #2859 R3 / S4):** default 2px `--accent-dim` border on all four sides; top-to-bottom background gradient sourced from `CtGradients.panelGradient` (`--surface` → `--bg`); no nine-patch chrome, no hard-coded hex literals. The modal barrier (scrim) is the caller's responsibility — pass `barrierColor` to `showDialog` or rely on the route default; this widget paints only the dialog content frame. **Border overrides (destructive-flow sub-dialogs):** the `borderColor` and `borderWidth` props let callers paint a `--danger` 1px frame for destructive-confirmation sub-dialogs (per `SPEC/ui/move-army-dialog.md` § Invade-confirm sub-dialog and issue #2867 R9). Overrides MUST still resolve from `--bg` / `--surface` / `--surface-lite` / `--accent` / `--accent-dim` / `--danger` tokens; no hard-coded hex literals are allowed in caller sites. Defaults preserve the canonical 2px `--accent-dim` brass frame when both props are omitted. **Layout:** The framed area grows with body content up to `maxHeight` (no empty vertical filler at `maxHeight` when content is shorter). When content exceeds `maxHeight`, **one** outer vertical scroll on the shell exposes the full body (including footer actions). Dialog bodies should use `Column(mainAxisSize: MainAxisSize.min)` and must not use vertical `Expanded` / `Flexible` against the shell’s inner height; nested inner vertical scroll regions for the primary flow are discouraged—prefer a single shell scroll. Secondary scrolls (e.g. horizontal table pan, fixed-height transfer lists) remain valid where specified.
- **CtPanel:** Dark editorial-monocle framed panel for in-screen sections (production, technology, diplomacy, victory overlays, unit panels). Replaces Material `Card`. **Visual contract (per #2859 R2 / S3):** background painted from `CtGradients.panelGradient` (top→bottom `--surface` → `--bg`); top and bottom edges render 1.5 px horizontal `--accent-dim` border strips (`CtPanel.accentEdgeWidth`). Left and right edges intentionally render no border so the panel reads as a horizontally-banded section rather than a full frame (the four-sided frame contract is owned by `CtDialogShell` per #2859 R3 / S4). No nine-patch asset dependency, no hard-coded hex literals. **Key props:** `child` (`Widget`, required); `padding` (`EdgeInsetsGeometry`, default `EdgeInsets.all(12)` inside the edge strips). The legacy `destTileSize` argument is retained as a no-op for source-level backward compatibility with pre-#2859 call sites and has **no effect** on rendering. **Forbidden Material counterpart:** `Card`, `Material` decorative wrapping for in-screen panels.
- **CtChoiceChip:** Small, pixel-friendly toggle chip used for region/visibility toggles and similar controls. Replaces `ChoiceChip`.
- **CtSlider:** Pixel-art slider for integer or continuous values (`divisions: 0`). Used in Production Allocation and region minimap zoom; replaces `Slider`. **Key props:** `value`, `min`, `max`, `divisions`, `onChanged` (required); optional `comfortHeadroomActive` / `comfortHeadroomColor` (production-panel comfort segment to the right of the thumb; default comfort color `--bg-deep`); optional `onDragStart` / `onDragEnd`. **Pixel-art requirements:** 6px-tall `--surface` track with 1px `--accent-dim` border; `--accent` fill from inner-left to thumb center; round 14px `--accent` thumb with 1px `--accent-bright` border; 24px hit target height. Optional comfort headroom paints the thumb→max inner segment in `comfortHeadroomColor` (defaults to `--bg-deep`). All colors resolve from § *Editorial-monocle palette*; no hard-coded hex literals. **Forbidden Material counterpart:** `Slider`.
- **CtDropdown:** Pixel-art dropdown (nine-patch button + modal list inside `CtDialogShell`). Replaces `DropdownButton`. **Visual contract — chevron rotation (per #2859 R5d / S6):** The trigger renders a 16x16 px `Icons.expand_more` (chevron-down) glyph coloured `--accent-dim` from the editorial-monocle palette (no hex literals). When the picker opens, the chevron rotates 180° (to chevron-up) over **120 ms** using `Curves.easeOut`; when the picker closes, it rotates back over the same 120 ms window. The animation is driven by an `AnimatedRotation` widget (Dart `turns` from `0.0` closed → `0.5` open) keyed by `CtDropdown.kChevronAnimatedRotationKey` so widget tests can pin the rotation target and duration without depending on tree order. **Visual contract — picker selected-row highlight (per #2859 R5c / S6):** Inside the modal picker, each row paints a 1 dp left-edge border (`width = kCtDropdownPickerSelectedLeftEdgeWidth`, stable across selection state so the layout never shifts). When the row's value equals the trigger's current `value`, the left edge is coloured `--accent` and the row's outer surface is painted `--accent-dim`; non-selected rows render the same 1 dp left edge transparent (`Colors.transparent`) and no background tint. The selected row exposes the stable test key `CtDropdown.kCtDropdownPickerSelectedRowKey` on the outer `DecoratedBox` so widget tests can locate the highlight without depending on tree order. When `value` is `null`, no row in the picker is treated as selected and the tinted highlight is omitted from every row. The inner `CtNinePatchButton` chrome is unchanged across both states; the highlight wraps the button rather than altering its own brass chrome. All colours resolve from § *Editorial-monocle palette* tokens (`--accent`, `--accent-dim`); no hard-coded hex literals. The remaining R5 visual concerns (own-gradient trigger surface, swatch-dot styling) remain out of scope for this contract entry and are tracked separately under #2859 S6.
- **CtScreenShell:** Full-screen pixel-art shell: dark editorial-monocle background + framed content area + 36 px `CtTopBar` top chrome. Replaces visible use of `Scaffold`/`AppBar` in user-facing screens. **Visual contract (per #2859 R4 / S5):** the scaffold paints the dark theme's `scaffoldBackgroundColor` (`--bg`); the framed body is a single outer `CtPanel` containing a leading `CtTopBar` (`CtGradients.topBarGradient` + 1 px `--accent-dim` bottom border, fixed 36 px height) followed by the consumer `child`. When `showBackButton` is `false` (default) the embedded `CtTopBar` omits the leading `CtBackButton`; when `true` the shell forwards through to `CtTopBar` so the chevron-left glyph and `Navigator.maybePop()` semantics come from the shared `CtBackButton` primitive (no Material `AppBar`, no `Icons.arrow_back`). **Key props:** `title` (required `String`), `child` (required `Widget`), `showBackButton` (`bool`, default `false`). **Forbidden Material counterpart:** `Scaffold`+`AppBar` for user-facing screen chrome.
- **CtGradients:** Shared utility (not a widget) exposing the canonical gradients used by every Ct-* component: `.buttonGradient` (top→bottom `--surface-lite`→`--surface` for tappable button surfaces), `.panelGradient` (top→bottom `--surface`→`--bg` for `CtPanel` / `CtDialogShell`), `.rowGradient` (left→right `--bg`→`--surface` for list rows), `.topBarGradient` (top→bottom `--surface-lite`→`--surface` for `CtScreenShell` / `CtTopBar`). All colors resolve from § *Editorial-monocle palette* tokens (`--bg`, `--surface`, `--surface-lite`). No hard-coded hex literals.
- **CtBrassDivider:** Ornate horizontal divider used to separate sections inside `CtPanel` / `CtDialogShell` and similar surfaces. Replaces Material `Divider`. **Key props:** none — the widget paints itself based purely on parent width. **Pixel-art requirements:** 8px fixed height; 1px gradient line (`--accent-dim` at midpoint fading to transparent at both ends); 8x8 diamond centerpiece (fill `--accent`, 1px `--accent-bright` outline) centered horizontally; three dots per side, 2px radius, 4px spacing between centers, first dot 6px from the diamond edge, color `--accent-dim`. No asset dependency. **Forbidden Material counterpart:** `Divider`, `VerticalDivider`.
- **CtSectionLabel:** Small-caps section label with a brass-tinted bottom border. Used to head sub-sections inside panels (production category bands, diplomacy faction groups, etc.). Replaces Material `ListSubheader` / similar. **Key props:** `text` (label string); optional outer `padding`. **Pixel-art requirements:** label text rendered in `--muted`, upper-cased + `FontFeature.enable('smcp')`, font weight `500`; 1px bottom border colored `--accent-dim` spanning the full label container width; 2px vertical padding between the text baseline and the border. No asset dependency. **Forbidden Material counterpart:** `ListSubheader`, `Divider`-only section heads.
- **CtProgressBar:** Horizontal progress bar with optional monospace label. Used for resource fill, build queue progress, and similar `0..1` indicators. Replaces Material `LinearProgressIndicator`. **Key props:** `value` (`double?` clamped to `[0.0, 1.0]`; `null` treated as `0.0`); optional `label` (consumer string rendered 4px to the right of the bar); `enabled` (false → entire widget at 0.4 opacity, shared with `CtNinePatchButton` etc.). **Pixel-art requirements:** 12px fixed height; full available parent width (no intrinsic width); `--surface` track with a 1px `--accent-dim` border; `--accent` fill anchored to inner-left growing left-to-right; fill width interpolates over 120ms using `Curves.easeOut`; 0% renders no fill artifact; 100% touches both inner border edges; optional label uses the dark-theme monospace `TextTheme` slot in `--muted`. No asset dependency. **Forbidden Material counterpart:** `LinearProgressIndicator`, `CircularProgressIndicator` for horizontal progress.
- **CtToggleSwitch:** Two-state toggle control with a sliding knob inside a horizontal track. Used wherever the running UI needs an on/off / enabled/disabled affordance (settings, debug toggles, feature flags). Replaces Material `Switch`. **Key props:** `value` (`bool` on/off); `onChanged` (`ValueChanged<bool>?`; when `null` the widget renders disabled per the shared 0.4-opacity convention from `CtNinePatchButton`/`CtBackButton`). **Pixel-art requirements:** 24x12px track; off-state track fill `--surface` with 1px `--accent-dim` border; on-state track fill `--surface-lite` with 1px `--accent` border; 10x10px square knob (off: fill `--muted`, 1px `--accent-dim` border, positioned 1px from track left; on: fill `--accent`, 1px `--accent-bright` border, positioned 13px from track left — total slide distance 12px); on-state draws a 1px outer halo around the knob in `--accent` at 60% alpha; hover off → knob fill brightens from `--muted` to `--accent-dim`, no glow drawn; hover on → knob fill brightens from `--accent` to `--accent-bright`, active-glow alpha rises from 60% to 100%; slide + colour interpolation animate over 120ms using `Curves.easeOut`; disabled wraps the widget in 0.4 opacity, suppresses taps, and freezes any in-flight slide animation. All colors resolve from § *Editorial-monocle palette* tokens (`--surface`, `--surface-lite`, `--muted`, `--accent`, `--accent-dim`, `--accent-bright`); no hard-coded hex literals. **Forbidden Material counterpart:** `Switch`, `Checkbox` for on/off toggles.
- **CtResourceCell:** Compact icon + name + quantity (+ optional signed delta) row used by the production panel, province overlay, and any panel that lists commodities, workers, or other identifier-keyed resources. Mirrors the `GAME20001-production-panel.html` `.resource-cell` mockup. Replaces ad-hoc `Row` builds that scatter resource layout and delta-color logic across feature files. **Key props:** `iconBuilder` (consumer-supplied widget that paints the leading 20x20 pixel icon — typically a `ResourceIcon` from `resource_icon.dart`); `name` (display label); `quantity` (`int`; rendered as a thousands-separated monospace number, color `--accent-dim`); `delta` (`int?`; sign-driven colour rules below); optional `padding`. **Pixel-art requirements:** horizontal row with 5px gap, 4px vertical / 6px horizontal cell padding; leading 20x20 icon region; flexible name column with overflow ellipsis using the dark-theme body font; trailing monospace quantity (`--accent-dim`); optional trailing monospace delta with 2px gap from quantity. Delta rendering: `delta > 0` → `+N`, color `--success`; `delta < 0` → `-N` (numeric sign), color `--danger`; `delta == 0` → `0` (no `+` prefix), color `--muted`; `delta == null` → delta region not laid out. No asset dependency beyond the consumer-supplied `iconBuilder`. **Forbidden Material counterpart:** `ListTile`, `Chip`.
- **CtBackButton:** Standalone pixel-art back-affordance for the dark editorial-monocle theme. Used by `CtTopBar`, dialog headers, and any chrome that needs a glyph-only back tap target. **Key props:** `onPressed` (`VoidCallback?`; when `null`, defaults to `Navigator.maybePop()`); `enabled` (`bool`, default `true`; `false` → 0.4 opacity and not tappable); `semanticLabel` (`String`, default `'Back'`; consumers pass a localised override). **Pixel-art requirements:** 28x28 px square tap target with a centered 16x16 px chevron-left glyph (`Icons.chevron_left` until a dedicated pixel-art chevron asset lands). Default state paints no background and tints the glyph `--accent-dim`; hover fades a `--surface-lite` panel in at 40% alpha and brightens the glyph to `--accent`; pressed state bumps the panel to 60% alpha and the glyph to `--accent-bright`; disabled wraps the widget in 0.4 opacity and suppresses tap/hover handling. Hover/press fade animates over 120 ms with `Curves.easeOut`. Wrapped in `Semantics(label, button: true, enabled)` so screen readers expose the affordance. All colors resolve from § *Editorial-monocle palette* tokens (`--accent`, `--accent-dim`, `--accent-bright`, `--surface-lite`); no hard-coded hex literals. **Forbidden Material counterpart:** `BackButton`, `IconButton(Icons.arrow_back)` as chrome.
- **CtTopBar:** Pixel-art 36 px top bar combining a leading `CtBackButton`, an optional `--muted` back-label, an optional pixel-art icon, the screen title, and an optional trailing slot. Used as the top chrome of feature screens (e.g. the production screen per #2862) wherever a Material `AppBar` would otherwise appear. Replaces Material `AppBar`. **Key props:** `title` (required `String`); `icon` (`Widget?`); `backButtonLabel` (`String?` rendered in `--muted` next to the chevron); `onBackPressed` (`VoidCallback?` forwarded to the embedded `CtBackButton`); `backButtonEnabled` (`bool`, default `true`; forwarded); `backButtonSemanticLabel` (`String?` forwarded as the back affordance's accessibility label); `trailing` (`Widget?`). **Pixel-art requirements:** 36 px fixed height; full parent width; paints `CtGradients.topBarGradient`; 1 px `--accent-dim` bottom border; 8 px outer horizontal padding; 4 px gap between the chevron, the back-label, the icon, and the title; 8 px gap before the trailing slot; title text uses the dark-theme `titleMedium` slot in `--accent` with `0.05em` letter-spacing; back-label text uses `--muted` and dims to 0.4 opacity when `backButtonEnabled` is `false`. No asset dependency. **Forbidden Material counterpart:** `AppBar`, `SliverAppBar`, `Material` toolbar chrome.
- **CtTabStrip:** Horizontal pixel-art tab strip for inline tabbed surfaces (e.g. the narrow-shell `ProvinceSeaZoneDetailOverlay` per `SPEC/ui/province-sea-zone-detail-overlay.md`). Renders one tappable label per tab in a scrollable row above an `IndexedStack` of tab bodies; replaces Material `TabBar` + `TabBarView`. **Key props:** `tabLabels` (`List<String>`, required, non-empty); `tabViews` (`List<Widget>`, required, same length as `tabLabels`); optional `contentPadding` (defaults to `EdgeInsets.zero`). **Visual contract (per #2865 S3):** each tab label paints a 1 px rectangular frame with `EdgeInsets.symmetric(horizontal: 10, vertical: 6)` content padding. The **selected** tab paints a background of `EditorialMonoclePalette.accentDim` at `0.25` alpha, a 1 px `EditorialMonoclePalette.accent` border, and label text colored `EditorialMonoclePalette.accentBright`. The **unselected** tabs paint a background of `EditorialMonoclePalette.surface` at `0.5` alpha, a 1 px `EditorialMonoclePalette.accentDim` border, and label text colored `EditorialMonoclePalette.muted`. Adjacent tabs are separated by a 4 px horizontal gap (no gap after the last tab). The label `TextStyle` is the dark-theme `bodySmall` slot with the color override above; no Material `colorScheme.primary` / `colorScheme.outline` / `colorScheme.surface` lookups remain. An 8 px vertical gap separates the tab row from the `IndexedStack` body. All colors resolve from § *Editorial-monocle palette* tokens; no hard-coded hex literals. **Forbidden Material counterpart:** `TabBar`, `TabBarView`, `DefaultTabController` for pixel-art panel chrome.
- **CtCompassRose:** Ornate 8-arm compass-rose emblem rendered as a self-painted decoration (no asset). Used in title regions for the dark editorial-monocle theme (e.g. `CtMainMenu` `pixelArt` variant per `SPEC/ui/main-menu.md`). **Key props:** `size` (`double`; outer square side length; default `48`). **Pixel-art requirements:** square aspect (painter scales to `min(width, height)`); two crossing cardinal arms — 2px-wide vertical line spanning the full height and 2px-tall horizontal line spanning the full width — painted `--accent` at `0.8` alpha; two diagonal arms 1.5px wide rotated `±45°` of length `60%` of the side painted `--accent` at `0.45` alpha; outer ring stroked 1px at diameter `75%` of the side, painted `--accent` at `0.35` alpha; centered filled medallion of diameter `25%` of the side painted `--accent`, overlaid with a small `--bg-deep` pinhole of diameter `~8.3%` of the side. No asset dependency. **Forbidden Material counterpart:** none (decorative-only).
- **CtFleurDeLisOrnament:** Stylized fleur-de-lis flourish rendered as a self-painted ornament (no asset). Used to flank title text in the dark editorial-monocle theme (e.g. `CtMainMenu` `pixelArt` variant title row per `SPEC/ui/main-menu.md`). **Key props:** `width` (`double`; default `24`), `height` (`double`; default `32`). **Pixel-art requirements:** canonical `24 x 32` viewBox; painter preserves the `3:4` aspect ratio (pillarbox/letterbox excess space inside the parent box); five filled primitives — top petal (ellipse, center `(12, 6)`, radii `3 x 5`), left/right side petals (ellipses, centers `(5, 10)` and `(19, 10)`, radii `4 x 3.5`), cross bar (RRect `(7, 14, 10, 2.5)`, radius `1`), stem (RRect `(10.5, 14, 3, 16)`, radius `1.5`); all primitives painted in `--accent-dim` at `0.6` alpha so the ornament reads as a muted brass flourish. No asset dependency. **Forbidden Material counterpart:** none (decorative-only).
- **CtMainMenuCollage:** Decorative dark SVG-collage background rendered as a self-painted full-screen ornament (no asset). Used as the fixed-position background of `CtMainMenu` `pixelArt` variant per `SPEC/ui/main-menu.md`. **Key props:** none — the widget expands to fill its parent and paints into that box. **Pixel-art requirements:** canonical `1920 x 1080` viewBox with `preserveAspectRatio="xMidYMid meet"` (painter scales uniformly to the smaller axis and centers with pillarbox/letterbox margins); thirteen mockup-aligned glyph families painted in `--accent` at family-specific group alphas — dashed trade-route arcs (`0.40`, five quadratic curves), navigation-star waypoints (`0.45`, four diamond+ring pairs), telescope (`0.55`, rotated `-14°`), spyglass (`0.50`, rotated `-6°`), crossed muskets (`0.55`, rotated `+32°` and `-36°`), powder horn (`0.50`, rotated `-40°`), sextant (`0.55`), hourglass (`0.55`), anchor (`0.55`), soldier silhouette (`0.55`), ship's wheel (`0.55`), cannon with cannonballs (`0.55`), and layered wave bands (`0.50`); a final group alpha of `0.8` (`.collage-svg { opacity }` rule) is layered over every primitive via `Canvas.saveLayer` so the collage reads as a muted background. No asset dependency. **Forbidden Material counterpart:** none (decorative-only).

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

### Dialog scrim

Modal dialogs, full-screen overture / victory / call-to-arms / intervention
overlays, and any surface that uses Flutter `showDialog` (or an equivalent
full-screen `Stack` layer) on the running app theme MUST dim the underlying
canvas with a single canonical scrim token derived from the `--bg-deep`
hue family:

| Token | OKLCH | sRGB (approx.) | Role |
|-------|-------|----------------|------|
| `--dialog-scrim` | `oklch(8% 0.01 30 / 0.70)` | `#070303` at 70% alpha | Universal modal scrim color (`barrierColor` for `showDialog`; container fill for full-screen overlay scrims) |

The opaque base color (`oklch(8% 0.01 30)`) is darker than `--bg-deep` so
the scrim reads as a near-black wash; the `0.70` alpha keeps the underlying
map / shell readable underneath. The Dart implementation exposes this token
as `EditorialMonoclePalette.dialogScrim` (`app/lib/config/editorial_monocle_palette.dart`).
Widgets MUST resolve the scrim through that token (or, for `showDialog`
calls, by passing `EditorialMonoclePalette.dialogScrim` as `barrierColor`)
rather than hard-coding `Colors.black54` / hex literals.

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

## Spacing and radius tokens

Canonical spacing and corner-radius scales for the dark `editorialMonocle`
theme. Values are derived from observed `app/lib/widgets/**` and
`app/lib/features/**` patterns and are formalised here so per-component
review (issues #2914 S5 / S6) can adopt them in Ct-\* widget defaults and
feature padding/radius callsites without re-deriving the scale per file.

### Spacing tokens

The Dart implementation lands as `CtSpacing` constants in
`app/lib/widgets/ct_spacing.dart` (issue #2914 S5). Token names use a
`xs`/`s`/`m`/`ml`/`l`/`xl`/`xxl` shorthand so callsites read as
`EdgeInsets.all(CtSpacing.m)` rather than embedding the literal `8`.

| Token | Logical px | Typical role |
|-------|-----------|--------------|
| `xs` | `2` | Hairline gaps inside compact widgets (e.g. `CtTransferList` per-row vertical breath, between `CtPanel` accent edge and inner content). |
| `s` | `6` | Resource-cell horizontal padding and similar tight chrome (e.g. `CtResourceCell` default `EdgeInsets.symmetric(horizontal: s, vertical: 4)`-style usage). |
| `m` | `8` | Default screen-shell outer padding and panel inner padding for compact surfaces (`CtScreenShell` outer body padding, `CtPanel` default inner padding). |
| `ml` | `12` | Dialog body line breaks, button row gaps, mid-density panel insets. |
| `l` | `16` | Standard card / dialog block padding on default-density surfaces (predominant `EdgeInsets.all(16)` usage). |
| `xl` | `20` | Full-screen dialogue shell inner padding (`CtFullScreenDialogueShell.defaultPadding = EdgeInsets.all(xl)`). |
| `xxl` | `24` | Roomy main-menu container padding, generous block padding for low-density surfaces. |

The scale is intentionally non-linear: it skips over `4`, `10`, and `14`
because those values are rare and either approximate (`4 ≈ s/2 or m/2`) or
better expressed as a per-component override (`14`, used once in default
densities, is a candidate for explicit override during S5 adoption rather
than a global token). Per-component review (S5) MAY extend the scale with
additional named tokens if a value occurs in three or more callsites; new
tokens MUST land here in the SPEC table before code adoption.

### Radius tokens

The Dart implementation lands as `CtRadius` constants in
`app/lib/widgets/ct_radius.dart` (issue #2914 S6) and is consumed via
`BorderRadius.circular(CtRadius.medium)` (or an equivalent helper).

| Token | Logical px | Typical role |
|-------|-----------|--------------|
| `small` | `2` | Hairline rounding on chip/tab corners (e.g. `BorderRadius.circular(2)` in `CtChoiceChip` / `CtTabStrip` style frames). |
| `medium` | `4` | Default rounded chrome on resource cells, transfer list rows, compact panels. |
| `large` | `8` | Dialog/panel outer frame rounding for default-density surfaces. |
| `xl` | `12` | Roomy dialog frames and full-screen overlays where the corner radius reads at human scale rather than as pixel-art chamfer. |

The scale stops at `12`. The single observed `BorderRadius.circular(24)`
callsite is a per-screen affordance (not a global token); per-component
review (S6) treats it as an explicit override rather than promoting a
`xxl` radius token. The single observed `BorderRadius.circular(1)` and
`BorderRadius.circular(6)` callsites are similarly out-of-scale and are
candidates for adjustment to the nearest defined token during adoption,
unless per-component review documents an explicit pixel-art reason to
keep the literal.

### Acceptance criteria (Spacing and radius tokens)

- **Given** a developer reads the §Spacing tokens table, **when** they look for the `xs`, `s`, `m`, `ml`, `l`, `xl`, and `xxl` rows, **then** each token appears with its logical-px value (`2`, `6`, `8`, `12`, `16`, `20`, `24` respectively) and a typical-role description, and the prose around the table calls out the deliberate omissions of `4`, `10`, and `14` from the scale.
- **Given** a developer reads the §Radius tokens table, **when** they look for the `small`, `medium`, `large`, and `xl` rows, **then** each token appears with its logical-px value (`2`, `4`, `8`, `12` respectively) and a typical-role description, and the prose around the table calls out that observed values `1`, `6`, and `24` are out-of-scale per-component overrides rather than global tokens.
- **Given** issue #2914 S5 / S6 implements `CtSpacing` and `CtRadius` Dart constants, **when** the implementation is reviewed against this SPEC, **then** every Dart constant name and value matches a row in the corresponding token table and no extra named constants exist that are not present in the SPEC table.

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


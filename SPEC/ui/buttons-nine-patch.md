# Buttons: nine-patch slicing

**SPEC/ui** — All app buttons support nine-patch slicing. Authority: UI design rule; derives from GDD/TDD.

---

## Scope

- **Flutter layer (shell, overlays, menus):** Use the `CtNinePatchButton` catalog widget. Under the dark editorial-monocle theme the widget paints its own gradient surface and brass corner brackets from canonical OKLCH tokens (`Refs #2859` R1 / S2); the legacy nine-patch image is no longer required for chrome.
- **Flame layer (game canvas, HUD):** Use Flame’s `NineTileBoxComponent` for any button-like UI drawn directly on the game canvas. Flame components remain on the legacy asset path because in-canvas chrome continues to leverage nine-patch tiling at this time.

## Asset

- **Id:** `ui_button_nine_patch`
- **Path:** `assets/images/ui_button_nine_patch.png`
- **Status:** Retained for the Flame-layer component and any historical references. The Flutter `CtNinePatchButton` no longer rasterises this image; deletion is deferred until the Flame-layer button surface migrates too.
- **Layout (Flame use):** Square image for 3×3 grid. Recommended: 48×48 px with **tile size 16** (so corners and edges are 16 px; center stretches).
- **Style:** Same palette and pixel style as main menu (UXD 02). Can be derived from or consistent with `ui_main_menu_button.png`.

**Naming:** Snake_case per asset rule.

## Widget contract

- **Catalog:** `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`). Reusable wherever a primary or secondary button is needed.
- **API:** `onPressed` (`VoidCallback?`), `child` (label/icon), optional `enabled` (default `true`), optional `padding` (default 16 px horizontal / 12 px vertical), optional `minHeight` (default 48 dp), optional `shrinkWrap` (default `false`). Sizing: width/height from constraints or child; minimum touch target 44 dp per UXD. When `shrinkWrap` is `false` (default) the surface centers its content and expands to fill the available cross-axis width (legacy behaviour). When `shrinkWrap` is `true` the surface sizes to its content width instead of expanding, so several compact buttons can share a `Wrap` run and flow left-to-right rather than each filling the run as a vertical column (used by the diplomacy action cluster per `SPEC/ui/diplomacy-panel.md` § Action button styling, Refs #3621). The historical `destTileSize` argument is retained for backward compatibility only and no longer affects rendering under the dark theme.
- **Visual contract (dark editorial-monocle, `Refs #2859` R1 / S2):**
  - Background gradient sourced from `CtGradients.buttonGradient` (top→bottom `--surface-lite` → `--surface`).
  - 1 px border in `--border` (default) shifting to `--accent` on hover.
  - Four 10x10 px brass corner brackets painted in `--accent` at 0.75 alpha (default) / `--accent-bright` at 1.0 alpha (hover).
  - Engraved label text: body colour `--accent` (default) / `--accent-bright` (hover), with a single 1 px downward drop-shadow (`Offset(0, 1)`, blur `0`, colour `--surface`).
  - Disabled state wraps the widget in 0.4 opacity (shared convention with `CtBackButton`, `CtToggleSwitch`, `CtProgressBar`) and suppresses pointer events; hover transitions animate over 120 ms (`Curves.easeOut`).
- **Fallback:** No image asset is required for rendering under the dark theme; the widget paints purely from palette tokens. If a future light-theme variant reintroduces nine-patch chrome, the fallback solid background (theme primary colour) remains the contract.

## Theme and framework integration

- **Material shell only:** Material and Cupertino widgets are **not used for user-facing chrome** (no `ElevatedButton`, `TextButton`, `FilledButton`, `AlertDialog`, `Card`, `ChoiceChip`, `Slider`, `DropdownButton`, etc.). They may be used only as invisible plumbing (e.g. `MaterialApp`, `DefaultTabController`) where required by Flutter.
- **Button catalog:** All tappable controls (primary, secondary, toolbar, dialog actions) are built from `CtNinePatchButton` or components that wrap it (e.g. `CtDropdown`, `CtSlider`, `CtChoiceChip`, `CtScreenShell` headers). No new button-like components may be introduced without reusing this nine-patch canon.
- **Pixel-art first:** Every interactive component must either (a) use nine-patch assets for its frame/chrome or (b) be explicitly specified in SPEC/ui as a pixel-art friendly primitive (e.g. 1-px borders, hard-edged fills) with no Material elevation, ripples, or rounded-corner cards.

## References

- Flame: [NineTileBoxWidget](https://pub.dev/documentation/flame/latest/widgets/NineTileBoxWidget-class.html), [NineTileBoxComponent](https://pub.dev/documentation/flame/latest/components/NineTileBoxComponent-class.html).
- Main menu assets: [main-menu.md](main-menu.md). Palette and style lock: UXD 02.

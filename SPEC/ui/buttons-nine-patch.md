# Buttons: nine-patch slicing

**SPEC/ui** — All app buttons support nine-patch slicing. Authority: UI design rule; derives from GDD/TDD.

---

## Scope

- **Flutter layer (shell, overlays, menus):** Use Flame’s `NineTileBoxWidget` from `package:flame/widgets.dart` so buttons scale without distorting corners or edges.
- **Flame layer (game canvas, HUD):** Use Flame’s `NineTileBoxComponent` for any button-like UI drawn in the game.

## Asset

- **Id:** `ui_button_nine_patch`
- **Path:** `assets/images/ui_button_nine_patch.png`
- **Layout:** Square image for 3×3 grid. Recommended: 48×48 px with **tile size 16** (so corners and edges are 16 px; center stretches).
- **Style:** Same palette and pixel style as main menu (UXD 02). Can be derived from or consistent with `ui_main_menu_button.png`.

**Naming:** Snake_case per asset rule.

## Widget contract

- **Catalog:** `CtNinePatchButton`. Reusable wherever a primary or secondary button is needed.
- **API:** `onPressed`, `child` (label/icon), optional `enabled`, optional `padding`, optional `destTileSize` (default matches theme min height). Sizing: width/height from constraints or child; minimum touch target 44 dp per UXD.
- **Fallback:** If the nine-patch asset is missing, show a solid background (theme primary colour) so the app remains usable.

## Theme and framework integration

- **Material shell only:** Material and Cupertino widgets are **not used for user-facing chrome** (no `ElevatedButton`, `TextButton`, `FilledButton`, `AlertDialog`, `Card`, `ChoiceChip`, `Slider`, `DropdownButton`, etc.). They may be used only as invisible plumbing (e.g. `MaterialApp`, `DefaultTabController`) where required by Flutter.
- **Button catalog:** All tappable controls (primary, secondary, toolbar, dialog actions) are built from `CtNinePatchButton` or components that wrap it (e.g. `CtDropdown`, `CtSlider`, `CtChoiceChip`, `CtScreenShell` headers). No new button-like components may be introduced without reusing this nine-patch canon.
- **Pixel-art first:** Every interactive component must either (a) use nine-patch assets for its frame/chrome or (b) be explicitly specified in SPEC/ui as a pixel-art friendly primitive (e.g. 1-px borders, hard-edged fills) with no Material elevation, ripples, or rounded-corner cards.

## References

- Flame: [NineTileBoxWidget](https://pub.dev/documentation/flame/latest/widgets/NineTileBoxWidget-class.html), [NineTileBoxComponent](https://pub.dev/documentation/flame/latest/components/NineTileBoxComponent-class.html).
- Main menu assets: [main-menu.md](main-menu.md). Palette and style lock: UXD 02.

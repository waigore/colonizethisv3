/// Canonical spacing tokens for the dark editorial-monocle theme.
///
/// Implements `Refs #2914` S5: lands the Dart constants for the
/// **Spacing tokens** table in
/// `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens* (the `xs` / `s`
/// / `m` / `ml` / `l` / `xl` / `xxl` shorthand scale).
///
/// **Authoritative scale (logical px):**
///
/// | Token | Logical px | Typical role |
/// |-------|-----------|--------------|
/// | `xs`  | `2`  | Hairline gaps inside compact widgets. |
/// | `s`   | `6`  | Resource-cell horizontal padding and similar tight chrome. |
/// | `m`   | `8`  | Default screen-shell outer padding and panel inner padding for compact surfaces. |
/// | `ml`  | `12` | Dialog body line breaks, button row gaps, mid-density panel insets. |
/// | `l`   | `16` | Standard card / dialog block padding on default-density surfaces. |
/// | `xl`  | `20` | Full-screen dialogue shell inner padding. |
/// | `xxl` | `24` | Roomy main-menu container padding, generous block padding for low-density surfaces. |
///
/// The scale is intentionally non-linear: it skips over `4`, `10`, and
/// `14` because those values are rare and either approximate
/// (`4 ≈ s/2 or m/2`) or better expressed as a per-component override.
/// Per-component review (S5 adoption) MAY extend the scale with
/// additional named tokens, but new tokens MUST land in the SPEC table
/// **first**, then in this file.
///
/// All constants are `int` to match Flutter's `EdgeInsets.all(int)`,
/// `SizedBox(height: int)`-style call sites without an implicit
/// double conversion.
class CtSpacing {
  CtSpacing._();

  /// `2` px — hairline gaps inside compact widgets (e.g. `CtTransferList`
  /// per-row vertical breath, accent-edge ↔ inner-content separation
  /// inside `CtPanel`).
  static const double xs = 2;

  /// `6` px — resource-cell horizontal padding and similar tight chrome
  /// (e.g. `CtResourceCell` default `EdgeInsets.symmetric(horizontal: s,
  /// vertical: 4)`-style usage).
  static const double s = 6;

  /// `8` px — default screen-shell outer padding and panel inner padding
  /// for compact surfaces (`CtScreenShell` outer body padding,
  /// `CtPanel`-style compact insets).
  static const double m = 8;

  /// `12` px — dialog body line breaks, button row gaps, mid-density
  /// panel insets (`CtPanel` default inner padding).
  static const double ml = 12;

  /// `16` px — standard card / dialog block padding on default-density
  /// surfaces (the predominant `EdgeInsets.all(16)` usage).
  static const double l = 16;

  /// `20` px — full-screen dialogue shell inner padding
  /// (`CtFullScreenDialogueShell.defaultPadding = EdgeInsets.all(xl)`).
  static const double xl = 20;

  /// `24` px — roomy main-menu container padding, generous block
  /// padding for low-density surfaces.
  static const double xxl = 24;
}

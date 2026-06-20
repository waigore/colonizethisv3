/// Canonical corner-radius tokens for the dark editorial-monocle theme.
///
/// Implements `Refs #2914` S6: lands the Dart constants for the
/// **Radius tokens** table in
/// `SPEC/ui/pixel-art-ui-catalog.md` § *Radius tokens*.
///
/// **Authoritative scale (logical px):**
///
/// | Token   | Logical px | Typical role |
/// |---------|-----------|--------------|
/// | `small` | `2`  | Hairline rounding on chip/tab corners (e.g. `BorderRadius.circular(2)` in `CtChoiceChip` / `CtTabStrip` style frames). |
/// | `medium`| `4`  | Default rounded chrome on resource cells, transfer-list rows, compact panels. |
/// | `large` | `8`  | Dialog/panel outer frame rounding for default-density surfaces. |
/// | `xl`    | `12` | Roomy dialog frames and full-screen overlays where the corner radius reads at human scale rather than as pixel-art chamfer. |
///
/// The scale stops at `12`. Observed `BorderRadius.circular(24)` and
/// `BorderRadius.circular(1)` / `BorderRadius.circular(6)` call sites
/// are out-of-scale per-component overrides; they are intentionally
/// **not** promoted to a global token (per SPEC § *Radius tokens*).
/// Adoption review (S6) treats them as explicit overrides — to add a
/// new token, update the SPEC table first, then add the constant here.
///
/// Constants are `double` to match Flutter's
/// `BorderRadius.circular(double)` API directly.
class CtRadius {
  CtRadius._();

  /// `2` px — hairline rounding on chip/tab corners (e.g.
  /// `CtChoiceChip` / `CtTabStrip` style frames).
  static const double small = 2;

  /// `4` px — default rounded chrome on resource cells, transfer-list
  /// rows, compact panels.
  static const double medium = 4;

  /// `8` px — dialog/panel outer frame rounding for default-density
  /// surfaces.
  static const double large = 8;

  /// `12` px — roomy dialog frames and full-screen overlays where the
  /// corner radius reads at human scale rather than as pixel-art
  /// chamfer.
  static const double xl = 12;
}

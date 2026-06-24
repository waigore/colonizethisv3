import 'package:flutter/widgets.dart';

import 'ct_spacing.dart';

/// Named [SizedBox] gap widgets whose dimensions are sourced **only** from
/// the SPEC-pinned [CtSpacing] tokens.
///
/// `CtGap` introduces **no new spacing values** — every gap forwards an
/// existing [CtSpacing] token, so adopting it is a behavior-preserving,
/// zero-golden-diff refactor (Refs #3594). It replaces the proliferation of
/// raw single-dimension `SizedBox(height: N)` / `SizedBox(width: N)` spacers
/// across `app/lib/features/game/widgets/` with intent-revealing,
/// axis-explicit constants.
///
/// **Axis convention:** vertical (height) gaps use the bare token name
/// (`m` / `ml` / `l`); horizontal (width) gaps use a `w`-prefix (`wm`) to
/// disambiguate the axis at the callsite.
///
/// | Member     | Maps to                          | Logical px |
/// |------------|----------------------------------|-----------|
/// | [m]        | `SizedBox(height: CtSpacing.m)`  | `8`        |
/// | [ml]       | `SizedBox(height: CtSpacing.ml)` | `12`       |
/// | [l]        | `SizedBox(height: CtSpacing.l)`  | `16`       |
/// | [wm]       | `SizedBox(width: CtSpacing.m)`   | `8`        |
///
/// The off-scale `4` px gaps (`SizedBox(width: 4)` / `SizedBox(height: 4)`)
/// are intentionally **not** represented here: `4` is deliberately absent
/// from the [CtSpacing] scale, and adding it would require a SPEC change
/// first (`SPEC/ui/pixel-art-ui-catalog.md` § Spacing tokens documents the
/// `4` / `10` / `14` skips). Those gaps remain raw literals pending a
/// separate SPEC decision.
class CtGap {
  CtGap._();

  /// Vertical gap of [CtSpacing.m] (`8` px).
  static const SizedBox m = SizedBox(height: CtSpacing.m);

  /// Vertical gap of [CtSpacing.ml] (`12` px).
  static const SizedBox ml = SizedBox(height: CtSpacing.ml);

  /// Vertical gap of [CtSpacing.l] (`16` px).
  static const SizedBox l = SizedBox(height: CtSpacing.l);

  /// Horizontal gap of [CtSpacing.m] (`8` px).
  static const SizedBox wm = SizedBox(width: CtSpacing.m);
}

import 'package:flutter/material.dart';

import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../widgets/ct_radius.dart';

/// Bottom-sheet host chrome shared by the three unit panels (Civilian
/// `UNIT10001`, Military `UNIT20001`, Naval `UNIT30001`).
///
/// Paints the mockup `.sheet` treatment so the modal bottom-sheet host that
/// mounts each panel matches the HTML mockups instead of the bare Material
/// sheet surface (`SPEC/ui/components/units-panel-shell.md` § Bottom-sheet
/// host chrome, owner decision #4 in issue #3514):
///
/// - a `surface → bg-deep` vertical gradient background
///   (`.sheet { background: linear-gradient(180deg, var(--surface) 0%,
///   var(--bg-deep) 100%) }`),
/// - a 2 px `--accent-dim` top edge (`.sheet { border-top: 2px solid
///   var(--accent-dim) }`), and
/// - a 4 px top corner radius (`.sheet { border-radius: 4px 4px 0 0 }`).
///
/// Hosts pass `showModalBottomSheet(backgroundColor: Colors.transparent,
/// elevation: 0, ...)` so this surface owns the visible sheet frame. The
/// panel content (`UnitsPanelShell`) is rendered as the [child]; this widget
/// only contributes the outer sheet chrome and does not constrain the
/// panel's own sizing.
class UnitsPanelSheetSurface extends StatelessWidget {
  const UnitsPanelSheetSurface({super.key, required this.child});

  /// The panel content mounted inside the decorated sheet (typically a
  /// `UnitsPanelShell`-based panel, optionally wrapped in a height
  /// `ConstrainedBox` by the host).
  final Widget child;

  /// Width of the 2 px `--accent-dim` top edge. Mirrors the mockup
  /// `.sheet { border-top: 2px solid var(--accent-dim) }` rule.
  static const double topEdgeWidth = 2.0;

  /// Top corner radius (`CtRadius.medium` = 4 dp) mirroring the mockup
  /// `.sheet { border-radius: 4px 4px 0 0 }` rule.
  static const double topCornerRadius = CtRadius.medium;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            EditorialMonoclePalette.surface,
            EditorialMonoclePalette.bgDeep,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: EditorialMonoclePalette.accentDim,
            width: topEdgeWidth,
          ),
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(topCornerRadius),
        ),
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_nine_patch_button.dart';

import 'victory_overlay_panel_layout.dart';

/// Three-glyph laurel decoration sitting above the victory-type label. Uses
/// Unicode glyphs in `--accent` at 0.6 alpha (no asset dependency).
///
/// Renders at [VictoryPanel.laurelFontSizeNarrow] when [narrow] is true and at
/// [VictoryPanel.laurelFontSizeWide] otherwise. SPEC/ui/victory-overlay.md
/// § Narrow viewport pins both values (lower-bound of the mockup's
/// `clamp(24px,5vw,36px)` for narrow; default for wide).
class VictoryLaurelRow extends StatelessWidget {
  const VictoryLaurelRow({required this.narrow, super.key});

  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final double fontSize = narrow
        ? VictoryPanelLayout.laurelFontSizeNarrow
        : VictoryPanelLayout.laurelFontSizeWide;
    final TextStyle laurelStyle = TextStyle(
      color: EditorialMonoclePalette.accent.withValues(alpha: 0.6),
      fontSize: fontSize,
      height: 1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('\u269C', style: laurelStyle),
        const SizedBox(width: 6),
        Text('\u2605', style: laurelStyle),
        const SizedBox(width: 6),
        Text('\u269C', style: laurelStyle),
      ],
    );
  }
}

/// Primary/secondary action row for [VictoryPanel].
Widget buildVictoryPanelActionRow(
  BuildContext context,
  AppLocalizations l10n, {
  required ct_models.AppEventBus bus,
  required VoidCallback? onViewFinalState,
  required bool narrow,
}) {
  final ThemeData theme = Theme.of(context);
  final TextStyle? secondaryButtonStyle = theme.textTheme.titleSmall?.copyWith(
    color: EditorialMonoclePalette.muted,
  );
  final Widget primary = CtNinePatchButton(
    onPressed: () => bus.emit(const ct_models.NavigateToShellEvent()),
    child: Text(l10n.victory_returnToMainMenu),
  );
  final Widget secondary = CtNinePatchButton(
    onPressed: () {
      onViewFinalState?.call();
    },
    child: Text(
      l10n.victory_viewFinalState,
      style: secondaryButtonStyle,
    ),
  );
  if (narrow) {
    // SPEC/ui/victory-overlay.md § Narrow viewport: stacked vertical Column
    // mirroring the mockup's `flex-wrap:wrap` + `min-width:clamp(120,...)`
    // collapse to a single column at narrow widths.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        primary,
        const SizedBox(height: 8),
        secondary,
      ],
    );
  }
  return Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 8,
    children: <Widget>[primary, secondary],
  );
}

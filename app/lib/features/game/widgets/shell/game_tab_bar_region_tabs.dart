import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../../screens/game/game_screen_shared.dart' show kCargoHoldIndicatorKey;
import 'game_tab_bar.dart';

class GameRegionTab extends StatelessWidget {
  const GameRegionTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _horizontalPadding = 12;
  static const double _verticalPadding = 4;
  static const double _activeBottomBorderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle labelStyle = (theme.textTheme.bodySmall ??
            const TextStyle(fontSize: 12))
        .copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.03 * 11,
          color: selected
              ? EditorialMonoclePalette.accent
              : EditorialMonoclePalette.muted,
        );

    final BoxDecoration decoration = selected
        ? BoxDecoration(
            color: EditorialMonoclePalette.bg,
            border: Border(
              left: BorderSide(color: EditorialMonoclePalette.accentDim),
              top: BorderSide(color: EditorialMonoclePalette.accentDim),
              right: BorderSide(color: EditorialMonoclePalette.accentDim),
              bottom: BorderSide(
                color: EditorialMonoclePalette.accent,
                width: _activeBottomBorderWidth,
              ),
            ),
          )
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                EditorialMonoclePalette.bgDeep,
                EditorialMonoclePalette.surface,
              ],
            ),
            border: Border(
              left: BorderSide(color: EditorialMonoclePalette.border),
              top: BorderSide(color: EditorialMonoclePalette.border),
              right: BorderSide(color: EditorialMonoclePalette.border),
            ),
          );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: _verticalPadding,
          ),
          decoration: decoration,
          child: Text(label, style: labelStyle),
        ),
      ),
    );
  }
}

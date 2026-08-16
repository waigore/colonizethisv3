import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../../screens/game/game_screen_shared.dart' show kOldWorldRaceChipKey;
import 'old_world_race_snapshot.dart';

/// Tab-bar Old World province race control (`MAP10001`).
///
/// SPEC: `SPEC/ui/components/old-world-race-chip.md`. Refs #4451.
class OldWorldRaceChip extends StatelessWidget {
  const OldWorldRaceChip({
    super.key,
    required this.snapshot,
    this.narrow = false,
    this.onTap,
  });

  final OldWorldRaceSnapshot snapshot;
  final bool narrow;
  final VoidCallback? onTap;

  static const double iconSize = 18;
  static const double wideMaxWidth = 220;
  static const double narrowMaxWidth = 108;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle mono = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.0,
          color: EditorialMonoclePalette.accentDim,
        );
    final String count = '${snapshot.focusCount}';
    final String threshold = '${snapshot.threshold}';
    final String fraction = narrow
        ? l10n.mapControls_oldWorldRace_compact(count, threshold)
        : l10n.mapControls_oldWorldRace(count, threshold);
    final String? rivalText = snapshot.rivalIsAhead
        ? (narrow
              ? l10n.mapControls_oldWorldRace_rivalCueCompact(
                  snapshot.rivalLeaderName!,
                  '${snapshot.rivalLeaderCount}',
                )
              : l10n.mapControls_oldWorldRace_rivalCue(
                  snapshot.rivalLeaderName!,
                  '${snapshot.rivalLeaderCount}',
                  threshold,
                ))
        : null;
    final String semanticsLabel = snapshot.rivalIsAhead
        ? l10n.mapControls_oldWorldRace_semanticsWithRival(
            count,
            threshold,
            snapshot.rivalLeaderName!,
            '${snapshot.rivalLeaderCount}',
          )
        : l10n.mapControls_oldWorldRace_semanticsLabel(count, threshold);

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StrictAssetIcon(
          assetPath: '${kAppIconAssetPrefix}ui_icon_victory.png',
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(width: 4),
        Text(fraction, style: mono),
        if (rivalText != null) Text(rivalText, style: mono),
      ],
    );

    Widget chip = Container(
      key: kOldWorldRaceChipKey,
      padding: const EdgeInsets.symmetric(horizontal: CtSpacing.m),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: EditorialMonoclePalette.border, width: 1),
        ),
      ),
      margin: const EdgeInsets.only(left: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: narrow ? narrowMaxWidth : wideMaxWidth,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: content,
        ),
      ),
    );

    if (onTap != null) {
      chip = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      );
    }
    chip = Tooltip(message: l10n.mapControls_oldWorldRace_tooltip, child: chip);
    return Semantics(button: onTap != null, label: semanticsLabel, child: chip);
  }
}

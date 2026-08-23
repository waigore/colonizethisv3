import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
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
    final _OldWorldRaceChipCopy copy = _OldWorldRaceChipCopy.resolve(
      l10n,
      snapshot,
      narrow: narrow,
    );
    Widget chip = _OldWorldRaceChipVisual(
      narrow: narrow,
      fraction: copy.fraction,
      rivalText: copy.rivalText,
      style: mono,
    );
    if (onTap != null) {
      chip = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      );
    }
    return Semantics(
      button: onTap != null,
      label: copy.semanticsLabel,
      child: Tooltip(
        message: _raceChipTooltip(l10n, snapshot.calendarClock),
        child: chip,
      ),
    );
  }
}

class _OldWorldRaceChipCopy {
  const _OldWorldRaceChipCopy({
    required this.fraction,
    required this.semanticsLabel,
    this.rivalText,
  });

  final String fraction;
  final String semanticsLabel;
  final String? rivalText;

  static _OldWorldRaceChipCopy resolve(
    AppLocalizations l10n,
    OldWorldRaceSnapshot snapshot, {
    required bool narrow,
  }) {
    final String count = '${snapshot.focusCount}';
    final String threshold = '${snapshot.threshold}';
    final String fraction = narrow
        ? l10n.mapControls_oldWorldRace_compact(count, threshold)
        : l10n.mapControls_oldWorldRace(count, threshold);
    final String raceSemantics = snapshot.rivalIsAhead
        ? l10n.mapControls_oldWorldRace_semanticsWithRival(
            count,
            threshold,
            snapshot.rivalLeaderName!,
            '${snapshot.rivalLeaderCount}',
          )
        : l10n.mapControls_oldWorldRace_semanticsLabel(count, threshold);
    if (!snapshot.rivalIsAhead) {
      return _OldWorldRaceChipCopy(
        fraction: fraction,
        semanticsLabel: _withCalendarSemantics(
          l10n,
          snapshot.calendarClock,
          raceSemantics,
        ),
      );
    }
    final String rivalName = snapshot.rivalLeaderName!;
    final String rivalCount = '${snapshot.rivalLeaderCount}';
    return _OldWorldRaceChipCopy(
      fraction: fraction,
      rivalText: narrow
          ? l10n.mapControls_oldWorldRace_rivalCueCompact(rivalName, rivalCount)
          : l10n.mapControls_oldWorldRace_rivalCue(
              rivalName,
              rivalCount,
              threshold,
            ),
      semanticsLabel: _withCalendarSemantics(
        l10n,
        snapshot.calendarClock,
        raceSemantics,
      ),
    );
  }
}

String _raceChipTooltip(AppLocalizations l10n, CampaignCalendarClock? clock) {
  if (clock == null) {
    return l10n.mapControls_oldWorldRace_tooltip;
  }
  if (clock.kind == CampaignCalendarClockKind.remaining) {
    return l10n.mapControls_oldWorldRace_tooltipRemaining(
      clock.remainingYears,
      clock.lastCampaignYear,
    );
  }
  if (clock.kind == CampaignCalendarClockKind.lastYear) {
    return l10n.mapControls_oldWorldRace_tooltipLastYear(
      clock.lastCampaignYear,
    );
  }
  return l10n.mapControls_oldWorldRace_tooltip;
}

String _withCalendarSemantics(
  AppLocalizations l10n,
  CampaignCalendarClock? clock,
  String raceSemantics,
) {
  if (clock == null) {
    return raceSemantics;
  }
  if (clock.kind == CampaignCalendarClockKind.remaining) {
    return '$raceSemantics ${l10n.mapControls_oldWorldRace_yearsRemain(clock.remainingYears, clock.lastCampaignYear)}';
  }
  if (clock.kind == CampaignCalendarClockKind.lastYear) {
    return '$raceSemantics ${l10n.mapControls_oldWorldRace_lastYearClause(clock.lastCampaignYear)}';
  }
  return raceSemantics;
}

class _OldWorldRaceChipVisual extends StatelessWidget {
  const _OldWorldRaceChipVisual({
    required this.narrow,
    required this.fraction,
    required this.style,
    this.rivalText,
  });

  final bool narrow;
  final String fraction;
  final String? rivalText;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          maxWidth: narrow
              ? OldWorldRaceChip.narrowMaxWidth
              : OldWorldRaceChip.wideMaxWidth,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StrictAssetIcon(
                assetPath: '${kAppIconAssetPrefix}ui_icon_victory.png',
                width: OldWorldRaceChip.iconSize,
                height: OldWorldRaceChip.iconSize,
              ),
              const SizedBox(width: 4),
              Text(fraction, style: style),
              if (rivalText != null) Text(rivalText!, style: style),
            ],
          ),
        ),
      ),
    );
  }
}

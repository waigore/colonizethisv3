/// On-request Tile teaching helper for MAP20001 (Refs #4369).
library;

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_build_port.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_label_text.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

/// Stable key for widget tests that open Tile details.
const Key kProvinceTileDetailsPanelKey = Key('province_tile_details_panel');

/// Named Tile details affordance (a11y / Widgetbook / tests).
const Key kProvinceTileDetailsActionKey = Key('province_tile_details_action');

/// Transport / connectivity text cluster that opens Tile details.
const Key kProvinceTileDetailsClusterKey = Key(
  'province_tile_details_cluster',
);

String tileCapitalLinkLine(
  AppLocalizations l10n,
  ProvinceTileConnectivityDisplay display,
) {
  if (display.capitalConnected) {
    final pathLevel = display.pathTransportLevel;
    if (pathLevel != null) {
      return l10n.provinceOverlay_tileCapitalLinkConnectedWithPath(pathLevel);
    }
    return l10n.provinceOverlay_tileCapitalLinkConnected;
  }
  return l10n.provinceOverlay_tileCapitalLinkNotConnected;
}

/// Whether default Tile should show the stranded capital-link exception.
bool showDefaultStrandedCapitalLink(
  ProvinceTileConnectivityDisplay? tileConnectivity,
) {
  if (tileConnectivity == null) {
    return false;
  }
  return !tileConnectivity.capitalConnected &&
      tileConnectivity.showExtractionRow;
}

/// Whether details should list `E of F` (E > 0 and F > 0).
bool showTileDetailsExtractionRow(
  ProvinceTileConnectivityDisplay? tileConnectivity,
) {
  if (tileConnectivity == null) {
    return false;
  }
  final effective = tileConnectivity.extractionEffective;
  final full = tileConnectivity.extractionFull;
  return effective != null && full != null && effective > 0 && full > 0;
}

@visibleForTesting
List<String> tileConnectivityDetailLinesForTests({
  required AppLocalizations l10n,
  required ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  if (tileConnectivity == null) {
    return const [];
  }
  final lines = <String>[tileCapitalLinkLine(l10n, tileConnectivity)];
  if (showTileDetailsExtractionRow(tileConnectivity)) {
    lines.add(
      l10n.provinceOverlay_tileExtractionFromTile(
        tileConnectivity.extractionEffective!,
        tileConnectivity.extractionFull!,
      ),
    );
  }
  return lines;
}

/// Teaching lines for the Tile details helper (Refs #4369).
@visibleForTesting
List<String> provinceTileDetailsLines({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required int? roadLevel,
  required ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  final lines = <String>[];
  if (roadLevel != null) {
    lines.add(roadRailSupplementaryLabel(l10n, roadLevel));
    if (roadLevel == 1) {
      lines.add(l10n.provinceOverlay_tileRoadRailGloss);
    }
  }
  final province = game.worldState.tryGetProvince(provinceId);
  final showPortStatus = province != null && province.ownerId == humanPlayerId;
  if (showPortStatus) {
    final portPresent =
        GameMapAreaProvinceActionStatesBuildPort.provinceHasAnyPort(
      game: game,
      prefixedProvinceId: provinceId,
    );
    lines.add(
      portPresent
          ? l10n.provinceOverlay_tilePortStatusPresent
          : l10n.provinceOverlay_tilePortStatusNone,
    );
  }
  if (tileConnectivity != null) {
    lines.add(tileCapitalLinkLine(l10n, tileConnectivity));
    if (showTileDetailsExtractionRow(tileConnectivity)) {
      lines.add(
        l10n.provinceOverlay_tileExtractionFromTile(
          tileConnectivity.extractionEffective!,
          tileConnectivity.extractionFull!,
        ),
      );
    }
  }
  return lines;
}

/// Opens the dismissible Tile details helper dialog.
Future<void> showProvinceTileDetailsDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required int? roadLevel,
  required ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  final lines = provinceTileDetailsLines(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    roadLevel: roadLevel,
    tileConnectivity: tileConnectivity,
  );
  return showDialog<void>(
    context: context,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) => ProvinceTileDetailsDialog(
      l10n: l10n,
      lines: lines,
    ),
  );
}

/// Compact read-only Tile teaching dialog (Refs #4369).
@visibleForTesting
class ProvinceTileDetailsDialog extends StatelessWidget {
  const ProvinceTileDetailsDialog({
    super.key,
    required this.l10n,
    required this.lines,
  });

  final AppLocalizations l10n;
  final List<String> lines;

  static const Key closeButtonKey = Key('province_tile_details_close');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.fg,
      height: 1.35,
    );
    final captionStyle =
        (theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
      color: EditorialMonoclePalette.muted,
      height: 1.25,
    );
    return CtDialogShell(
      maxWidth: 320,
      child: ConstrainedBox(
        key: kProvinceTileDetailsPanelKey,
        constraints: const BoxConstraints(maxHeight: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.provinceOverlay_tileDetailsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: EditorialMonoclePalette.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: CtSpacing.m),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == lines.length - 1 ? 0 : CtSpacing.s,
                        ),
                        child: Text(
                          lines[i],
                          style: i == 0 ||
                                  lines[i] ==
                                      l10n.provinceOverlay_tileRoadRailGloss
                              ? captionStyle
                              : bodyStyle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CtSpacing.ml),
            CtNinePatchButton(
              key: closeButtonKey,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_close),
            ),
          ],
        ),
      ),
    );
  }
}

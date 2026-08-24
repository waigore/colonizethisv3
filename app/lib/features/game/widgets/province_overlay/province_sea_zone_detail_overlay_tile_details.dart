/// On-request Tile teaching helper for MAP20001 (Refs #4369).
library;

import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_build_port.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_details_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_label_text.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

export 'province_sea_zone_detail_overlay_tile_details_dialog.dart';

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

/// Tile-details cause when an owned disconnected tile is cut by blockade.
String? tileBlockadeCapitalLinkCauseLine({
  required AppLocalizations l10n,
  required ProvinceTileConnectivityDisplay display,
  required ProvinceBlockadeStatus blockadeStatus,
}) {
  if (display.capitalConnected) return null;
  if (blockadeStatus == ProvinceBlockadeStatus.none) return null;
  return l10n.provinceOverlay_tileCapitalLinkCutByBlockade;
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
  final nextPreview = tileConnectivity.nextImproveYield;
  if (nextPreview != null) {
    lines.add(
      buildImprovementNextYieldGistLine(l10n: l10n, preview: nextPreview),
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
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
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
    final blockadeCause = tileBlockadeCapitalLinkCauseLine(
      l10n: l10n,
      display: tileConnectivity,
      blockadeStatus: blockadeStatus,
    );
    if (blockadeCause != null) {
      lines.add(blockadeCause);
    }
    if (showTileDetailsExtractionRow(tileConnectivity)) {
      lines.add(
        l10n.provinceOverlay_tileExtractionFromTile(
          tileConnectivity.extractionEffective!,
          tileConnectivity.extractionFull!,
        ),
      );
    }
    final nextPreview = tileConnectivity.nextImproveYield;
    if (nextPreview != null) {
      lines.add(
        buildImprovementNextYieldGistLine(l10n: l10n, preview: nextPreview),
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
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
}) {
  final lines = provinceTileDetailsLines(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    roadLevel: roadLevel,
    tileConnectivity: tileConnectivity,
    blockadeStatus: blockadeStatus,
  );
  return showDialog<void>(
    context: context,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) => ProvinceTileDetailsDialog(l10n: l10n, lines: lines),
  );
}

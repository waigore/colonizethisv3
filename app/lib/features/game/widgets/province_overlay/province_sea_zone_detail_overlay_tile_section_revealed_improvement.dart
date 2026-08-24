/// Build-improvement row + next-yield gist for the revealed MAP20001 tile body.
library;

import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_assignable.dart'
    show ProvinceInlineActionState;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_labels.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_gist_line.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show VisibilityLevel;
import 'package:flutter/material.dart';

Widget buildRevealedTileImprovementRow({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required ProvinceInlineActionState buildImprovement,
  required ProvinceInlineActionCallbacks inlineActionCallbacks,
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? resourceRaw,
  required String? resourceVisible,
  ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  final tooltip = provinceOverlayBuildImprovementTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    enabled: buildImprovement.enabled,
    hasMatchingUnits: buildImprovement.hasMatchingUnits,
  );
  final nextYieldPreview = tileConnectivity?.nextImproveYield;
  final nextYieldGist = buildImprovement.enabled && nextYieldPreview != null
      ? buildImprovementNextYieldGistLine(
          l10n: l10n,
          preview: nextYieldPreview,
        )
      : null;
  final iconRow = Row(
    children: [
      Expanded(
        child: buildTileImprovementLabel(
          l10n: l10n,
          impLevel: impLevel,
          visLevel: visLevel,
          rawResourceId: resourceRaw,
          visibleResourceId: resourceVisible,
        ),
      ),
      if (buildImprovement.showIcon)
        CtIconAction(
          tooltip: tooltip,
          onPressed: buildImprovement.enabled
              ? inlineActionCallbacks.onBuildImprovementTap
              : null,
          icon: Icons.handyman,
          enabled: buildImprovement.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
  if (nextYieldGist == null) {
    return iconRow;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      iconRow,
      BuildImprovementYieldGistLine(text: nextYieldGist),
    ],
  );
}

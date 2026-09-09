/// Prospected row + Train Explorer for the revealed MAP20001 tile body.
library;

import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_assignable.dart'
    show ProvinceInlineActionState;
import 'package:colonizethis_app/features/game/widgets/units/civilian/explore_payoff_gist_line.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_control.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_offer.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/prospect_payoff_gist_line.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section_tokens.dart';

Widget buildRevealedTileProspectedRow({
  required AppLocalizations l10n,
  required Widget prospectedIconRow,
  required String? explorePayoffGist,
  required String? prospectPayoffGist,
  required ProvinceInlineActionState explore,
  required ProvinceInlineActionState prospect,
  required bool consulateGated,
  required VoidCallback? onTrainCivilianTap,
}) {
  final trainExplorer = buildMapTrainCivilianControl(
    l10n: l10n,
    kind: MapTrainCivilianKind.explorer,
    show:
        offerMapTrainCivilianForState(
          state: explore,
          otherNonUnitGateApplies: consulateGated,
          trainTapAvailable: onTrainCivilianTap != null,
        ) ||
        offerMapTrainCivilianForState(
          state: prospect,
          otherNonUnitGateApplies: consulateGated,
          trainTapAvailable: onTrainCivilianTap != null,
        ),
    onTap: onTrainCivilianTap,
  );
  if (explorePayoffGist == null &&
      prospectPayoffGist == null &&
      trainExplorer == null) {
    return prospectedIconRow;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      prospectedIconRow,
      if (explorePayoffGist != null)
        ExplorePayoffGistLine(text: explorePayoffGist),
      if (prospectPayoffGist != null)
        ProspectPayoffGistLine(text: prospectPayoffGist),
      ?trainExplorer,
    ],
  );
}

Widget buildRevealedTileProspectedIconRow({
  required AppLocalizations l10n,
  required String prospectedLabel,
  required ProvinceInlineActionState explore,
  required ProvinceInlineActionState prospect,
  required String exploreTooltip,
  required String prospectTooltip,
  required ProvinceInlineActionCallbacks inlineActionCallbacks,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          l10n.provinceOverlay_tileProspected(prospectedLabel),
          style: overlayFgBodyStyle(),
        ),
      ),
      if (explore.showIcon)
        CtIconAction(
          tooltip: exploreTooltip,
          onPressed: explore.enabled
              ? inlineActionCallbacks.onExploreWithExplorerTap
              : null,
          icon: Icons.explore,
          enabled: explore.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
      if (prospect.showIcon)
        CtIconAction(
          tooltip: prospectTooltip,
          onPressed: prospect.enabled
              ? inlineActionCallbacks.onProspectWithExplorerTap
              : null,
          icon: Icons.travel_explore,
          enabled: prospect.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
}

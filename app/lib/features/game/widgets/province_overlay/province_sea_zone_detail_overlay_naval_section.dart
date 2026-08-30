import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import '../../flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import '../../flame/map_state/province_naval_combine_overlay_controls.dart'
    show ProvinceNavalCombineOverlayControls;
import '../../flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import '../../flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart'
    show ProvinceTransferToHomeFleetOverlayControls;
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'province_panel_labels.dart';
import 'province_sea_zone_detail_overlay_naval_mission_actions.dart';
import 'province_sea_zone_detail_overlay_naval_pending_lines.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show homeFleetIdFor;

export 'province_sea_zone_detail_overlay_naval_pending_lines.dart';

Widget buildNavalSection({
  required AppLocalizations l10n,
  required Game game,
  required List<Fleet> fleets,
  required String humanPlayerId,
  required Orders draftOrders,
  String? pendingNavalPortProvinceId,
  String? pendingNavalSeaZoneId,
  bool rosterObfuscated = false,
  ProvinceNavalMissionOverlayControls navalMission =
      ProvinceNavalMissionOverlayControls.hidden,
  ProvinceDetachAndSailOverlayControls detachAndSail =
      ProvinceDetachAndSailOverlayControls.hidden,
  ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet =
      ProvinceTransferToHomeFleetOverlayControls.hidden,
  ProvinceNavalCombineOverlayControls navalCombine =
      ProvinceNavalCombineOverlayControls.hidden,
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
}) {
  final pending = pendingNavalLines(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    pendingNavalPortProvinceId: pendingNavalPortProvinceId,
    pendingNavalSeaZoneId: pendingNavalSeaZoneId,
  );
  final missionActions = navalMissionActionWidgets(
    l10n,
    navalMission,
    detachAndSail,
    transferToHomeFleet,
    navalCombine,
  );
  final hasRoster = fleets.isNotEmpty || pending.isNotEmpty;
  final blockadeLine = switch (blockadeStatus) {
    ProvinceBlockadeStatus.none => null,
    ProvinceBlockadeStatus.portBlockaded => l10n.provinceOverlay_underBlockade,
    ProvinceBlockadeStatus.capitalBlockaded =>
      l10n.provinceOverlay_underBlockadeCapital,
  };
  return buildOverlaySection(
    l10n.provinceOverlay_sectionNaval,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (blockadeLine != null)
          Text(
            blockadeLine,
            style: TextStyle(color: EditorialMonoclePalette.danger),
          ),
        if (rosterObfuscated)
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown)
        else if (!hasRoster && missionActions.isEmpty)
          overlayEmptyBodyDashText(),
        if (!rosterObfuscated && fleets.isNotEmpty)
          ...fleets.map((f) {
            final ownerName = ownerNameForProvinceOverlay(
              l10n,
              game,
              f.ownerId,
            );
            final byType = <String, int>{};
            for (final s in f.ships) {
              byType[s.typeId] = (byType[s.typeId] ?? 0) + 1;
            }
            final fleetLabel = f.id == homeFleetIdFor(f.ownerId)
                ? l10n.naval_homeFleetLabel
                : l10n.naval_fleetLabel(f.id);
            final shipParts = byType.entries
                .map((e) {
                  final label = shipTypeDisplayLabel(l10n, e.key);
                  return '$label×${e.value}';
                })
                .join(', ');
            return Text(
              l10n.provinceOverlay_fleetSummary(
                ownerName,
                fleetLabel,
                shipParts,
              ),
              style: TextStyle(color: EditorialMonoclePalette.fg),
            );
          }),
        if (!rosterObfuscated && pending.isNotEmpty) ...[
          const SizedBox(height: CtSpacing.m / 2),
          ...pending.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: CtSpacing.m / 2),
              child: Text(
                line,
                style: TextStyle(color: EditorialMonoclePalette.muted),
              ),
            ),
          ),
        ],
        ...missionActions,
      ],
    ),
  );
}

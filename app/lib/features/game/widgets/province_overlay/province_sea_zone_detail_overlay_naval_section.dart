import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import '../../flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import '../../flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show homeFleetIdFor;

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
  final missionActions = _navalMissionActions(
    l10n,
    navalMission,
    detachAndSail,
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

List<Widget> _navalMissionActions(
  AppLocalizations l10n,
  ProvinceNavalMissionOverlayControls navalMission,
  ProvinceDetachAndSailOverlayControls detachAndSail,
) {
  final showDetach = detachAndSail.showDetachAndSail;
  if (!navalMission.showBlockade &&
      !navalMission.showBeachhead &&
      !navalMission.showPatrol &&
      !navalMission.showDefend &&
      !showDetach) {
    return const [];
  }
  return [
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (showDetach)
            CtActionTextButton(
              label: l10n.provinceOverlay_detachAndSailAction,
              tooltip: detachAndSail.detachAndSailTooltip,
              enabled: detachAndSail.detachAndSailEnabled,
              onPressed: detachAndSail.detachAndSailEnabled
                  ? detachAndSail.onDetachAndSailTap
                  : null,
            ),
          if (navalMission.showBlockade)
            CtActionTextButton(
              label: l10n.provinceOverlay_blockadeAction,
              tooltip: navalMission.blockadeTooltip,
              enabled: navalMission.blockadeEnabled,
              onPressed: navalMission.blockadeEnabled
                  ? navalMission.onBlockadeTap
                  : null,
            ),
          if (navalMission.showBeachhead)
            CtActionTextButton(
              label: l10n.provinceOverlay_beachheadAction,
              tooltip: navalMission.beachheadTooltip,
              enabled: navalMission.beachheadEnabled,
              onPressed: navalMission.beachheadEnabled
                  ? navalMission.onBeachheadTap
                  : null,
            ),
          if (navalMission.showPatrol)
            CtActionTextButton(
              label: l10n.provinceOverlay_patrolAction,
              tooltip: navalMission.patrolTooltip,
              enabled: navalMission.patrolEnabled,
              onPressed: navalMission.patrolEnabled
                  ? navalMission.onPatrolTap
                  : null,
            ),
          if (navalMission.showDefend)
            CtActionTextButton(
              label: l10n.provinceOverlay_defendAction,
              tooltip: navalMission.defendTooltip,
              enabled: navalMission.defendEnabled,
              onPressed: navalMission.defendEnabled
                  ? navalMission.onDefendTap
                  : null,
            ),
        ],
      ),
    ),
  ];
}

List<String> pendingNavalLines({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders draftOrders,
  required String? pendingNavalPortProvinceId,
  required String? pendingNavalSeaZoneId,
}) {
  if (pendingNavalPortProvinceId != null) {
    return provincePanelPendingNavalLines(
      game: game,
      orders: draftOrders,
      provinceId: pendingNavalPortProvinceId,
      humanPlayerId: humanPlayerId,
      l10n: l10n,
    );
  }
  if (pendingNavalSeaZoneId == null) return const [];
  final localSea = prefixedIdLocalSegment(pendingNavalSeaZoneId);
  final regionId = prefixedIdRegionSegment(pendingNavalSeaZoneId);
  final fleetIds = <String>{
    for (final fleet in game.worldState.fleets)
      if (fleet.ownerId == humanPlayerId &&
          fleet.isAtSea &&
          fleet.seaZoneId == localSea &&
          (regionId == null || fleet.regionId == regionId))
        fleet.id,
  };
  if (fleetIds.isEmpty) return const [];
  return pendingNavalLinesForFleets(
    game: game,
    orders: draftOrders,
    fleetIds: fleetIds,
    humanPlayerId: humanPlayerId,
    l10n: l10n,
  );
}

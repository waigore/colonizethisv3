import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show PlayerView, foreignCivilianVisibleToPlayer, homeFleetIdFor;

Widget buildCivilianSectionFiltered({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> civilian,
  required String humanPlayerId,
  required PlayerView playerView,
  required Orders draftOrders,
  ProvinceOverlayStationSpyProps stationSpy = kProvinceOverlayStationSpyHidden,
}) {
  final visible = civilian
      .where(
        (u) => foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: humanPlayerId,
          view: playerView,
        ),
      )
      .toList();
  final stationSpyButton = !stationSpy.showControl
      ? null
      : Padding(
          padding: const EdgeInsets.only(top: 4),
          child: CtActionTextButton(
            label: l10n.provinceOverlay_stationSpyAction,
            tooltip: stationSpy.tooltip,
            enabled: stationSpy.enabled,
            onPressed: stationSpy.enabled ? stationSpy.onTap : null,
          ),
        );
  if (visible.isEmpty && stationSpyButton == null) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionCivilian,
      overlayEmptyBodyDashText(),
    );
  }
  if (visible.isEmpty) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionCivilian,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [overlayEmptyBodyDashText(), stationSpyButton!],
      ),
    );
  }
  final workList = draftOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];
  return buildOverlaySection(
    l10n.provinceOverlay_sectionCivilian,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((u) {
          if (u.ownerId == humanPlayerId) {
            WorkOrder? pending;
            for (final o in workList) {
              if (o.unitId == u.id) {
                pending = o;
                break;
              }
            }
            if (pending != null) {
              final targetLabel = workOrderTargetDisplayLabel(
                l10n,
                pending.target,
              );
              return Text(
                l10n.provinceOverlay_unitTarget(u.type, targetLabel),
                style: TextStyle(color: EditorialMonoclePalette.fg),
              );
            }
            return Text(
              l10n.provinceOverlay_unitTarget(
                u.type,
                unitStatusDisplayLabel(l10n, u.status),
              ),
              style: TextStyle(color: EditorialMonoclePalette.fg),
            );
          }
          final o = ownerNameForProvinceOverlay(l10n, game, u.ownerId);
          return Text(
            l10n.provinceOverlay_foreignUnitStatus(
              o,
              u.type,
              unitStatusDisplayLabel(l10n, u.status),
            ),
            style: TextStyle(color: EditorialMonoclePalette.muted),
          );
        }),
        ?stationSpyButton,
      ],
    ),
  );
}

Widget buildNavalSection({
  required AppLocalizations l10n,
  required Game game,
  required List<Fleet> fleets,
  required String humanPlayerId,
  required Orders draftOrders,
  String? pendingNavalPortProvinceId,
  bool rosterObfuscated = false,
  ProvinceNavalMissionOverlayControls navalMission =
      ProvinceNavalMissionOverlayControls.hidden,
}) {
  final pending = pendingNavalPortProvinceId == null
      ? const <String>[]
      : provincePanelPendingNavalLines(
          game: game,
          orders: draftOrders,
          provinceId: pendingNavalPortProvinceId,
          humanPlayerId: humanPlayerId,
          l10n: l10n,
        );
  final missionActions = _navalMissionActions(l10n, navalMission);
  final hasRoster = fleets.isNotEmpty || pending.isNotEmpty;
  return buildOverlaySection(
    l10n.provinceOverlay_sectionNaval,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
) {
  if (!navalMission.showBlockade && !navalMission.showBeachhead) {
    return const [];
  }
  return [
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
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
        ],
      ),
    ),
  ];
}

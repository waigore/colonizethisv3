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
  ProvinceOverlayCounterEspionageProps counterEspionage =
      kProvinceOverlayCounterEspionageHidden,
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
  final stationSpyButton = _civilianShortcutControl(
    showControl: stationSpy.showControl,
    label: l10n.provinceOverlay_stationSpyAction,
    tooltip: stationSpy.tooltip,
    enabled: stationSpy.enabled,
    onTap: stationSpy.onTap,
  );
  final counterEspionageButton = _civilianShortcutControl(
    showControl: counterEspionage.showControl,
    label: l10n.provinceOverlay_counterEspionageAction,
    tooltip: counterEspionage.tooltip,
    enabled: counterEspionage.enabled,
    onTap: counterEspionage.onTap,
    gist: counterEspionage.gist,
  );
  final extras = <Widget>[
    if (stationSpyButton != null) stationSpyButton,
    if (counterEspionageButton != null) counterEspionageButton,
  ];
  if (visible.isEmpty && extras.isEmpty) {
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
        children: [overlayEmptyBodyDashText(), ...extras],
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
        ?counterEspionageButton,
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
  ProvinceDetachAndSailOverlayControls detachAndSail =
      ProvinceDetachAndSailOverlayControls.hidden,
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
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
        ],
      ),
    ),
  ];
}

Widget? _civilianShortcutControl({
  required bool showControl,
  required String label,
  required String tooltip,
  required bool enabled,
  required VoidCallback? onTap,
  String gist = '',
}) {
  if (!showControl) return null;
  final button = CtActionTextButton(
    label: label,
    tooltip: tooltip,
    enabled: enabled,
    onPressed: enabled ? onTap : null,
  );
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: gist.isEmpty
        ? button
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              button,
              Text(
                gist,
                style: TextStyle(
                  color: EditorialMonoclePalette.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
  );
}

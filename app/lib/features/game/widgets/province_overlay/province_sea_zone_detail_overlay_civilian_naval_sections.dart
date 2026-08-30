import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_panel_labels.dart';
import 'province_sea_zone_detail_overlay_civilian_shortcut_control.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show PlayerView, foreignCivilianVisibleToPlayer;

export 'province_sea_zone_detail_overlay_naval_section.dart';

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
  final stationSpyButton = buildProvinceOverlayCivilianShortcutControl(
    showControl: stationSpy.showControl,
    label: l10n.provinceOverlay_stationSpyAction,
    tooltip: stationSpy.tooltip,
    enabled: stationSpy.enabled,
    onTap: stationSpy.onTap,
    gist: stationSpy.gist,
  );
  final counterEspionageButton = buildProvinceOverlayCivilianShortcutControl(
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

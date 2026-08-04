
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView, foreignCivilianVisibleToPlayer, homeFleetIdFor;

Widget buildCivilianSectionFiltered({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> civilian,
  required String humanPlayerId,
  required PlayerView playerView,
  required Orders draftOrders,
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
  if (visible.isEmpty) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionCivilian,
      overlayEmptyBodyDashText(),
    );
  }
  final workList = draftOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];
  return buildOverlaySection(
    l10n.provinceOverlay_sectionCivilian,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: visible.map((u) {
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
      }).toList(),
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
  return buildOverlaySection(
    l10n.provinceOverlay_sectionNaval,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fleets.isEmpty && pending.isEmpty) overlayEmptyBodyDashText(),
        if (fleets.isNotEmpty)
          ...fleets.map((f) {
            final ownerName = ownerNameForProvinceOverlay(l10n, game, f.ownerId);
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
        if (pending.isNotEmpty) ...[
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
      ],
    ),
  );
}

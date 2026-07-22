import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';

Widget buildMilitarySectionByOwner({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> military,
  required String humanPlayerId,
  required String provinceId,
  required Orders draftOrders,
}) {
  final pending = provincePanelPendingMilitaryLines(
    game: game,
    orders: draftOrders,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    l10n: l10n,
  );
  if (military.isEmpty && pending.isEmpty) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionMilitary,
      overlayEmptyBodyDashText(),
    );
  }
  if (military.isEmpty) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionMilitary,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: pending
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(left: CtSpacing.m / 2),
                child: Text(
                  line,
                  style: TextStyle(color: EditorialMonoclePalette.muted),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
  final byOwner = <String, List<Unit>>{};
  for (final u in military) {
    byOwner.putIfAbsent(u.ownerId, () => []).add(u);
  }
  final ownerIds = byOwner.keys.toList()
    ..sort((a, b) {
      if (a == humanPlayerId) return -1;
      if (b == humanPlayerId) return 1;
      return ownerNameForProvinceOverlay(l10n, game, a)
          .compareTo(ownerNameForProvinceOverlay(l10n, game, b));
    });
  return buildOverlaySection(
    l10n.provinceOverlay_sectionMilitary,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...ownerIds.map((oid) {
          final list = byOwner[oid]!;
          final byType = <String, int>{};
          for (final u in list) {
            byType[u.type] = (byType[u.type] ?? 0) + 1;
          }
          final name = ownerNameForProvinceOverlay(l10n, game, oid);
          return Padding(
            padding: const EdgeInsets.only(bottom: CtSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: EditorialMonoclePalette.fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ...byType.entries.map((e) {
                  final label = regimentTypeDisplayLabel(l10n, e.key);
                  return Text(
                    l10n.provinceOverlay_indentedCount(label, e.value),
                    style: TextStyle(color: EditorialMonoclePalette.fg),
                  );
                }),
              ],
            ),
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

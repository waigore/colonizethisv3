// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for ProvinceSeaZoneDetailOverlay wide layout (scroll column).
// Mirrors app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart for e2e.
// If drift fails tests, align this file with the overlay widget.


import 'package:colonizethis_data/colonizethis_data.dart'
    show
        CommodityCatalog,
        MapTopology,
        TileMapResult,
        isMilitaryUnit,
        terrainDisplayName;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_labels.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_pending_orders.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'province_panel_e2e_expected_lines_ctx.dart';
import 'province_panel_e2e_expected_lines_labels.dart';

void appendProvincePanelMilitarySection(
  List<String> out,
  ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  appendProvincePanelSection(out, 'Military', () {
    final pending = provincePanelPendingMilitaryLines(
      game: ctx.game,
      orders: ctx.draftOrders,
      provinceId: ctx.provinceId,
      humanPlayerId: ctx.humanPlayerId,
      l10n: l10n,
    );
    if (ctx.military.isEmpty && pending.isEmpty) {
      out.add('—');
      return;
    }
    if (ctx.military.isEmpty) {
      for (final line in pending) {
        out.add(line);
      }
      return;
    }
    final byOwner = <String, List<Unit>>{};
    for (final u in ctx.military) {
      byOwner.putIfAbsent(u.ownerId, () => []).add(u);
    }
    final ownerIds = byOwner.keys.toList()
      ..sort((a, b) {
        if (a == ctx.humanPlayerId) return -1;
        if (b == ctx.humanPlayerId) return 1;
        return ownerDisplayName(ctx.game, a).compareTo(ownerDisplayName(ctx.game, b));
      });
    for (final oid in ownerIds) {
      final list = byOwner[oid]!;
      final byType = <String, int>{};
      for (final u in list) {
        byType[u.type] = (byType[u.type] ?? 0) + 1;
      }
      final name = ownerDisplayName(ctx.game, oid);
      out.add(name);
      for (final e in byType.entries) {
        final label = regimentTypeDisplayLabel(l10n, e.key);
        out.add('  $label: ${e.value}');
      }
    }
    for (final line in pending) {
      out.add(line);
    }
  });
}

void appendProvincePanelCivilianSection(
  List<String> out,
  ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  appendProvincePanelSection(out, 'Civilian', () {
    final visible = ctx.civilian
        .where(
          (u) => foreignCivilianVisibleToPlayer(
            unit: u,
            viewerPlayerId: ctx.humanPlayerId,
            view: ctx.playerView,
          ),
        )
        .toList();
    if (visible.isEmpty) {
      out.add('—');
      return;
    }
    final workList =
        ctx.draftOrders.workOrdersByPlayerId[ctx.humanPlayerId] ?? const [];
    for (final u in visible) {
      if (u.ownerId == ctx.humanPlayerId) {
        WorkOrder? pending;
        for (final o in workList) {
          if (o.unitId == u.id) {
            pending = o;
            break;
          }
        }
        if (pending != null) {
          final targetLabel = workOrderTargetDisplayLabel(l10n, pending.target);
          out.add('${u.type}: $targetLabel');
        } else {
          out.add('${u.type}: ${unitStatusDisplayLabel(l10n, u.status)}');
        }
      } else {
        final o = ownerDisplayName(ctx.game, u.ownerId);
        out.add('$o — ${u.type}: ${unitStatusDisplayLabel(l10n, u.status)}');
      }
    }
  });
}

void appendProvincePanelNavalSection(
  List<String> out,
  ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  appendProvincePanelSection(out, 'Naval', () {
    final pending = provincePanelPendingNavalLines(
      game: ctx.game,
      orders: ctx.draftOrders,
      provinceId: ctx.provinceId,
      humanPlayerId: ctx.humanPlayerId,
      l10n: l10n,
    );
    if (ctx.fleetsInPort.isEmpty && pending.isEmpty) {
      out.add('—');
      return;
    }
    if (ctx.fleetsInPort.isNotEmpty) {
      for (final f in ctx.fleetsInPort) {
        final ownerName = ownerDisplayName(ctx.game, f.ownerId);
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
        out.add(
          l10n.provinceOverlay_fleetSummary(ownerName, fleetLabel, shipParts),
        );
      }
    }
    for (final line in pending) {
      out.add(line);
    }
  });
}

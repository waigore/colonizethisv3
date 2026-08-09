part of 'province_panel_e2e_expected_lines.dart';

void _appendProvincePanelMilitarySection(
  List<String> out,
  _ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  _appendProvincePanelSection(out, 'Military', () {
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
        return _ownerName(ctx.game, a).compareTo(_ownerName(ctx.game, b));
      });
    for (final oid in ownerIds) {
      final list = byOwner[oid]!;
      final byType = <String, int>{};
      for (final u in list) {
        byType[u.type] = (byType[u.type] ?? 0) + 1;
      }
      final name = _ownerName(ctx.game, oid);
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

void _appendProvincePanelCivilianSection(
  List<String> out,
  _ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  _appendProvincePanelSection(out, 'Civilian', () {
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
        final o = _ownerName(ctx.game, u.ownerId);
        out.add('$o — ${u.type}: ${unitStatusDisplayLabel(l10n, u.status)}');
      }
    }
  });
}

void _appendProvincePanelNavalSection(
  List<String> out,
  _ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  _appendProvincePanelSection(out, 'Naval', () {
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
        final ownerName = _ownerName(ctx.game, f.ownerId);
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

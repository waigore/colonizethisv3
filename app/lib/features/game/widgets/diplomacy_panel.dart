// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'diplomacy_dialogs.dart';

/// Faction type for display. SPEC/game/factions.md.
enum FactionKind { greatPower, minor, tribe }

/// One row of data for the diplomacy list.
class DiplomacyRowData {
  const DiplomacyRowData({
    required this.factionId,
    required this.displayName,
    required this.kind,
    required this.relation,
    this.overture,
    required this.actions,
    this.powerScore,
    this.playerPowerScore,
  });

  final String factionId;
  final String displayName;
  final FactionKind kind;
  final DiplomacyRelation? relation;
  final OvertureState? overture;
  final List<DiplomaticOrder> actions;
  /// Great Power power score (SPEC/game/diplomacy.md). Only set for GP rows.
  final int? powerScore;
  /// Human player's power score for comparison (red if GP score > this). Only set for GP rows.
  final int? playerPowerScore;
}

/// Builds list of discovered factions and their available actions.
/// Discovered = has a relation with the player. SPEC/ui/diplomacy-panel.md.
List<DiplomacyRowData> buildDiplomacyRows(
  Game game,
  MapTopology topology,
  String humanPlayerId,
  Orders currentOrders,
) {
  final view = buildPlayerView(game, topology, humanPlayerId);
  final discoveredIds = view.diplomacyByOtherId.keys.toList();
  final suggestions = suggestDiplomaticOrders(view, game, topology, currentOrders);
  final actionsByTarget = <String, List<DiplomaticOrder>>{};
  for (final order in suggestions) {
    actionsByTarget.putIfAbsent(order.targetFactionId, () => []).add(order);
  }

  final gpIds = <String>[];
  final minorIds = <String>[];
  final tribeIds = <String>[];
  for (final id in discoveredIds) {
    if (id == humanPlayerId) continue;
    if (game.players.any((p) => p.id == id)) {
      gpIds.add(id);
    } else if (game.minorNations.any((m) => m.id == id)) {
      minorIds.add(id);
    } else if (game.tribes.any((t) => t.id == id)) {
      tribeIds.add(id);
    }
  }

  // GPs: sort by military power desc, then province count desc. SPEC/ui/diplomacy-panel.md.
  gpIds.sort((a, b) {
    final strA = aggregateMilitaryStrengthForPlayer(game, a);
    final strB = aggregateMilitaryStrengthForPlayer(game, b);
    final cmp = strB.compareTo(strA);
    if (cmp != 0) return cmp;
    final provA = provinceCountOwnedBy(game, a);
    final provB = provinceCountOwnedBy(game, b);
    return provB.compareTo(provA);
  });

  String displayNameFor(String id) {
    final p = game.playerById(id);
    if (p != null) return p.displayName;
    for (final m in game.minorNations) {
      if (m.id == id) return m.displayName ?? id;
    }
    for (final t in game.tribes) {
      if (t.id == id) return t.displayName ?? id;
    }
    return id;
  }

  List<DiplomacyRowData> rows = [];
  final playerPower = greatPowerPowerScore(game, humanPlayerId);
  for (final id in gpIds) {
    rows.add(DiplomacyRowData(
      factionId: id,
      displayName: displayNameFor(id),
      kind: FactionKind.greatPower,
      relation: view.diplomacyByOtherId[id],
      overture: getOverture(game, humanPlayerId, id),
      actions: actionsByTarget[id] ?? [],
      powerScore: greatPowerPowerScore(game, id),
      playerPowerScore: playerPower,
    ));
  }
  minorIds.sort((a, b) => (displayNameFor(a)).compareTo(displayNameFor(b)));
  for (final id in minorIds) {
    rows.add(DiplomacyRowData(
      factionId: id,
      displayName: displayNameFor(id),
      kind: FactionKind.minor,
      relation: view.diplomacyByOtherId[id],
      overture: getOverture(game, humanPlayerId, id),
      actions: actionsByTarget[id] ?? [],
      powerScore: null,
      playerPowerScore: null,
    ));
  }
  tribeIds.sort((a, b) => (displayNameFor(a)).compareTo(displayNameFor(b)));
  for (final id in tribeIds) {
    rows.add(DiplomacyRowData(
      factionId: id,
      displayName: displayNameFor(id),
      kind: FactionKind.tribe,
      relation: view.diplomacyByOtherId[id],
      overture: getOverture(game, humanPlayerId, id),
      actions: actionsByTarget[id] ?? [],
      powerScore: null,
      playerPowerScore: null,
    ));
  }
  return rows;
}

/// Full-page diplomacy panel. SPEC/ui/diplomacy-panel.md.
class DiplomacyPanel extends StatelessWidget {
  const DiplomacyPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.topology,
    required this.currentOrders,
    required this.onOrdersChanged,
    this.onClose,
  });

  final Game game;
  final String humanPlayerId;
  final MapTopology topology;
  final Orders currentOrders;
  final void Function(Orders) onOrdersChanged;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final rows = buildDiplomacyRows(game, topology, humanPlayerId, currentOrders);
    final gps = rows.where((r) => r.kind == FactionKind.greatPower).toList();
    final minors = rows.where((r) => r.kind == FactionKind.minor).toList();
    final tribes = rows.where((r) => r.kind == FactionKind.tribe).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (gps.isNotEmpty) ...[
          _sectionHeader(context, 'Great Powers'),
          ...gps.map((r) => _DiplomacyRow(
                data: r,
                onAction: (order) => _submitOrDialog(context, order),
              )),
        ],
        if (minors.isNotEmpty) ...[
          _sectionHeader(context, 'Minor Nations'),
          ...minors.map((r) => _DiplomacyRow(
                data: r,
                onAction: (order) => _submitOrDialog(context, order),
              )),
        ],
        if (tribes.isNotEmpty) ...[
          _sectionHeader(context, 'Tribes'),
          ...tribes.map((r) => _DiplomacyRow(
                data: r,
                onAction: (order) => _submitOrDialog(context, order),
              )),
        ],
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No other factions discovered yet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _submitOrDialog(BuildContext context, DiplomaticOrder order) {
    final needsParams = order.type == DiplomaticOrderType.grantAid ||
        order.type == DiplomaticOrderType.setSubsidy ||
        (order.type == DiplomaticOrderType.establishOverture &&
            order.overtureStage != null);
    if (needsParams) {
      _showDialogForOrder(context, order);
    } else {
      _appendOrder(order);
    }
  }

  void _showDialogForOrder(BuildContext context, DiplomaticOrder order) {
    if (order.type == DiplomaticOrderType.grantAid ||
        order.type == DiplomaticOrderType.setSubsidy) {
      showGrantOrSubsidyDialog(
        context: context,
        game: game,
        humanPlayerId: humanPlayerId,
        targetFactionId: order.targetFactionId,
        isSubsidy: order.type == DiplomaticOrderType.setSubsidy,
        onSubmitted: (amount) {
          _appendOrder(DiplomaticOrder(
            type: order.type,
            targetFactionId: order.targetFactionId,
            amount: amount,
          ));
        },
      );
    } else if (order.type == DiplomaticOrderType.establishOverture &&
        order.overtureStage != null) {
      _appendOrder(order);
    }
  }

  void _appendOrder(DiplomaticOrder order) {
    final list = List<DiplomaticOrder>.from(
      currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ?? [],
    )..add(order);
    onOrdersChanged(currentOrders.copyWith(
      diplomaticOrdersByPlayerId: {
        ...currentOrders.diplomaticOrdersByPlayerId,
        humanPlayerId: list,
      },
    ));
  }
}

class _DiplomacyRow extends StatelessWidget {
  const _DiplomacyRow({
    required this.data,
    required this.onAction,
  });

  final DiplomacyRowData data;
  final void Function(DiplomaticOrder) onAction;

  @override
  Widget build(BuildContext context) {
    final rel = data.relation;
    final stateLabel = rel == null
        ? '—'
        : rel.atWar
            ? 'War'
            : 'Peace';
    // SPEC/game/diplomacy.md § Player-facing relation display: show one-word state, hide score.
    final relationStateLabel = rel == null ? '' : relationScoreToDisplayLabel(rel.score);
    final overtureLabel = data.overture == null
        ? ''
        : ' · ${_overtureStageLabel(data.overture!.stage)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        data.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 8),
                      _kindChip(context, data.kind),
                      if (data.powerScore != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Power: ${data.powerScore}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: data.playerPowerScore != null &&
                                        data.powerScore! > data.playerPowerScore!
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    relationStateLabel.isEmpty
                        ? '$stateLabel$overtureLabel'
                        : '$stateLabel · $relationStateLabel$overtureLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.actions.map((order) {
                return _ActionButton(
                  order: order,
                  onPressed: () => onAction(order),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindChip(BuildContext context, FactionKind kind) {
    final (label, color) = switch (kind) {
      FactionKind.greatPower => ('GP', Colors.blue),
      FactionKind.minor => ('Minor', Colors.grey),
      FactionKind.tribe => ('Tribe', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _overtureStageLabel(OvertureStage stage) {
    return switch (stage) {
      OvertureStage.none => 'None',
      OvertureStage.tradeConsulate => 'Consulate',
      OvertureStage.embassy => 'Embassy',
      OvertureStage.nap => 'NAP',
      OvertureStage.joinEmpire => 'Join Empire',
    };
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.order,
    required this.onPressed,
  });

  final DiplomaticOrder order;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = _actionLabel(order);
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  String _actionLabel(DiplomaticOrder o) {
    switch (o.type) {
      case DiplomaticOrderType.declareWar:
        return 'Declare War';
      case DiplomaticOrderType.offerPeace:
        return 'Offer Peace';
      case DiplomaticOrderType.alliance:
        return 'Alliance';
      case DiplomaticOrderType.establishOverture:
        return o.overtureStage != null
            ? _overtureStageShort(o.overtureStage!)
            : 'Overture';
      case DiplomaticOrderType.grantAid:
        return o.amount != null ? 'Grant Aid (£${o.amount})' : 'Grant Aid';
      case DiplomaticOrderType.setSubsidy:
        return o.amount != null ? 'Subsidy (£${o.amount})' : 'Set Subsidy';
    }
  }

  String _overtureStageShort(OvertureStage s) {
    return switch (s) {
      OvertureStage.none => 'Overture',
      OvertureStage.tradeConsulate => 'Consulate',
      OvertureStage.embassy => 'Embassy',
      OvertureStage.nap => 'NAP',
      OvertureStage.joinEmpire => 'Join Empire',
    };
  }
}

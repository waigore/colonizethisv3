// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../../config/routes.dart';
import '../../../core/services/app_event_handler_scope.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import 'diplomacy_order_helpers.dart';

int? _outgoingSubsidyPerTurn(Game game, String payerId, String targetId) {
  for (final s in game.subsidyStates) {
    if (s.payerId == payerId && s.targetId == targetId) {
      return s.amountPerTurn;
    }
  }
  return null;
}

({int? grant, int? subsidy}) _pendingEconomicAmounts(
  List<DiplomaticOrder> list,
  String targetId,
) {
  int? grant;
  int? subsidy;
  for (final o in list) {
    if (o.targetFactionId != targetId) continue;
    if (o.type == DiplomaticOrderType.grantAid) {
      grant = o.amount;
    }
    if (o.type == DiplomaticOrderType.setSubsidy) {
      subsidy = o.amount;
    }
  }
  return (grant: grant, subsidy: subsidy);
}

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
    required this.pendingOrderTypes,
    this.activeSubsidyPerTurn,
    this.pendingGrantAmount,
    this.pendingSubsidyAmount,
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

  /// Set of DiplomaticOrderType that are currently pending for this target faction.
  final Set<DiplomaticOrderType> pendingOrderTypes;

  /// Active £/turn subsidy from the human GP to this row's faction (`Game.subsidyStates`).
  final int? activeSubsidyPerTurn;

  /// Pending grant aid amount in current-turn orders (not yet resolved).
  final int? pendingGrantAmount;

  /// Pending set-subsidy amount per turn in current-turn orders.
  final int? pendingSubsidyAmount;
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
  final suggestions = suggestDiplomaticOrders(
    view,
    game,
    topology,
    currentOrders,
  );
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

  final pendingByTarget = <String, Set<DiplomaticOrderType>>{};
  final pendingList =
      currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in pendingList) {
    pendingByTarget.putIfAbsent(o.targetFactionId, () => {}).add(o.type);
  }

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
    final econ = _pendingEconomicAmounts(pendingList, id);
    rows.add(
      DiplomacyRowData(
        factionId: id,
        displayName: displayNameFor(id),
        kind: FactionKind.greatPower,
        relation: view.diplomacyByOtherId[id],
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? [],
        powerScore: greatPowerPowerScore(game, id),
        playerPowerScore: playerPower,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        activeSubsidyPerTurn: _outgoingSubsidyPerTurn(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyAmount: econ.subsidy,
      ),
    );
  }
  minorIds.sort((a, b) => (displayNameFor(a)).compareTo(displayNameFor(b)));
  for (final id in minorIds) {
    final econ = _pendingEconomicAmounts(pendingList, id);
    rows.add(
      DiplomacyRowData(
        factionId: id,
        displayName: displayNameFor(id),
        kind: FactionKind.minor,
        relation: view.diplomacyByOtherId[id],
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? [],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        activeSubsidyPerTurn: _outgoingSubsidyPerTurn(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyAmount: econ.subsidy,
      ),
    );
  }
  tribeIds.sort((a, b) => (displayNameFor(a)).compareTo(displayNameFor(b)));
  for (final id in tribeIds) {
    final econ = _pendingEconomicAmounts(pendingList, id);
    rows.add(
      DiplomacyRowData(
        factionId: id,
        displayName: displayNameFor(id),
        kind: FactionKind.tribe,
        relation: view.diplomacyByOtherId[id],
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? [],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        activeSubsidyPerTurn: _outgoingSubsidyPerTurn(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyAmount: econ.subsidy,
      ),
    );
  }
  return rows;
}

/// Full-page diplomacy panel. SPEC/ui/diplomacy-panel.md.
class DiplomacyPanel extends StatefulWidget {
  const DiplomacyPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.topology,
    required this.currentOrders,
    required this.onOrdersChanged,
    required this.bus,
    this.onClose,
  });

  final Game game;
  final String humanPlayerId;
  final MapTopology topology;
  final Orders currentOrders;
  final void Function(Orders) onOrdersChanged;
  final AppEventBus bus;
  final VoidCallback? onClose;

  @override
  State<DiplomacyPanel> createState() => _DiplomacyPanelState();
}

class _DiplomacyPanelState extends State<DiplomacyPanel> {
  final Map<String, String> _moodByLeaderId = <String, String>{};
  StreamSubscription<PortraitMoodEvent>? _moodSub;

  @override
  void initState() {
    super.initState();
    _moodSub = widget.bus.on<PortraitMoodEvent>().listen((event) {
      _moodByLeaderId[event.leaderId] = event.toMood;
    });
  }

  @override
  void dispose() {
    _moodSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = buildDiplomacyRows(
      widget.game,
      widget.topology,
      widget.humanPlayerId,
      widget.currentOrders,
    );
    final gps = rows.where((r) => r.kind == FactionKind.greatPower).toList();
    final minors = rows.where((r) => r.kind == FactionKind.minor).toList();
    final tribes = rows.where((r) => r.kind == FactionKind.tribe).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (gps.isNotEmpty) ...[
          _sectionHeader(context, 'Great Powers'),
          ...gps.map(
            (r) => _DiplomacyRow(
              data: r,
              onAction: _submitOrDialog,
              onTap: () => _openDetail(r),
            ),
          ),
        ],
        if (minors.isNotEmpty) ...[
          _sectionHeader(context, 'Minor Nations'),
          ...minors.map(
            (r) => _DiplomacyRow(
              data: r,
              onAction: _submitOrDialog,
              onTap: () => _openDetail(r),
            ),
          ),
        ],
        if (tribes.isNotEmpty) ...[
          _sectionHeader(context, 'Tribes'),
          ...tribes.map(
            (r) => _DiplomacyRow(
              data: r,
              onAction: _submitOrDialog,
              onTap: () => _openDetail(r),
            ),
          ),
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _submitOrDialog(DiplomaticOrder order) {
    final pending =
        widget.currentOrders.diplomaticOrdersByPlayerId[widget.humanPlayerId] ??
        [];
    final alreadyPending = pending.any(
      (o) => o.type == order.type && o.targetFactionId == order.targetFactionId,
    );
    if (alreadyPending) {
      _removeOrder(order.type, order.targetFactionId);
      _emitNegotiationMood(
        leaderId: order.targetFactionId,
        offerQualityDelta: -0.25,
        stallCounter: pending.length,
        discriminator: '${order.type.name}:cancel',
      );
      return;
    }
    final needsParams =
        order.type == DiplomaticOrderType.grantAid ||
        order.type == DiplomaticOrderType.setSubsidy ||
        (order.type == DiplomaticOrderType.establishOverture &&
            order.overtureStage != null);
    if (needsParams) {
      _showDialogForOrder(order);
    } else {
      _showConfirmDialog(order);
    }
  }

  void _showConfirmDialog(DiplomaticOrder order) {
    final actionLabel = diplomacyActionLabel(order);
    widget.bus.emit(
      ConfirmDialogEvent(
        title: actionLabel,
        message:
            'Confirm $actionLabel against ${_targetName(order.targetFactionId)}?',
        onResult: (confirmed) {
          if (confirmed) {
            _appendOrder(order);
            _emitNegotiationMood(
              leaderId: order.targetFactionId,
              offerQualityDelta: _offerQualityDeltaFor(order.type),
              stallCounter: _pendingCountForTarget(order.targetFactionId),
              discriminator: order.type.name,
            );
          }
        },
      ),
    );
  }

  String _targetName(String factionId) {
    final p = widget.game.playerById(factionId);
    if (p != null) return p.displayName;
    for (final m in widget.game.minorNations) {
      if (m.id == factionId) return m.displayName ?? factionId;
    }
    for (final t in widget.game.tribes) {
      if (t.id == factionId) return t.displayName ?? factionId;
    }
    return factionId;
  }

  void _showDialogForOrder(DiplomaticOrder order) {
    if (order.type == DiplomaticOrderType.grantAid ||
        order.type == DiplomaticOrderType.setSubsidy) {
      widget.bus.emit(
        OpenDialogEvent(grantOrSubsidyDialogId, {
          'targetFactionId': order.targetFactionId,
          'isSubsidy': order.type == DiplomaticOrderType.setSubsidy,
        }),
      );
    } else if (order.type == DiplomaticOrderType.establishOverture &&
        order.overtureStage != null) {
      _showConfirmDialog(order);
    }
  }

  void _removeOrder(DiplomaticOrderType type, String targetFactionId) {
    widget.onOrdersChanged(
      widget.currentOrders.removeDiplomaticOrderForPlayer(
        widget.humanPlayerId,
        type: type,
        targetFactionId: targetFactionId,
      ),
    );
  }

  void _openDetail(DiplomacyRowData row) {
    widget.bus.emit(
      NavigateToRouteEvent(Routes.diplomacyDetail, {
        'game': widget.game,
        'humanPlayerId': widget.humanPlayerId,
        'factionId': row.factionId,
        'factionDisplayName': row.displayName,
        'kind': row.kind,
        'relation': row.relation,
      }),
    );
  }

  void _appendOrder(DiplomaticOrder order) {
    widget.onOrdersChanged(
      widget.currentOrders.appendDiplomaticOrderForPlayer(
        widget.humanPlayerId,
        order,
      ),
    );
  }

  int _pendingCountForTarget(String targetFactionId) {
    final list =
        widget.currentOrders.diplomaticOrdersByPlayerId[widget.humanPlayerId] ??
        const <DiplomaticOrder>[];
    return list.where((o) => o.targetFactionId == targetFactionId).length;
  }

  double _offerQualityDeltaFor(DiplomaticOrderType type) {
    switch (type) {
      case DiplomaticOrderType.declareWar:
        return -0.8;
      case DiplomaticOrderType.offerPeace:
        return 0.6;
      case DiplomaticOrderType.alliance:
        return 0.4;
      case DiplomaticOrderType.establishOverture:
        return 0.5;
      case DiplomaticOrderType.grantAid:
        return 0.7;
      case DiplomaticOrderType.setSubsidy:
        return 0.5;
    }
  }

  int _stableSeed({
    required String leaderId,
    required String discriminator,
    required int stallCounter,
  }) {
    final turn = widget.game.worldState.turnState.turnNumber;
    final base = widget.game.globalGameSeed ?? 0;
    final text = '$leaderId|$discriminator|$stallCounter|$turn';
    var hash = 0x811C9DC5;
    for (final code in text.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return base ^ hash;
  }

  void _emitNegotiationMood({
    required String leaderId,
    required double offerQualityDelta,
    required int stallCounter,
    required String discriminator,
  }) {
    final currentMood = _moodByLeaderId[leaderId] ?? kDefaultMood;
    widget.bus.emit(
      NegotiationMoodUpdateEvent(
        leaderId: leaderId,
        currentMood: currentMood,
        offerQualityDelta: offerQualityDelta,
        stallCounter: stallCounter,
        seed: _stableSeed(
          leaderId: leaderId,
          discriminator: discriminator,
          stallCounter: stallCounter,
        ),
      ),
    );
  }
}

class _DiplomacyRow extends StatelessWidget {
  const _DiplomacyRow({required this.data, required this.onAction, this.onTap});

  final DiplomacyRowData data;
  final void Function(DiplomaticOrder) onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rel = data.relation;
    final stateLabel = rel == null
        ? '—'
        : rel.atWar
        ? 'War'
        : 'Peace';
    // SPEC/game/diplomacy.md § Player-facing relation display: show one-word state, hide score.
    final relationStateLabel = rel == null
        ? ''
        : relationScoreToDisplayLabel(rel.score);
    final overtureLabel = data.overture == null
        ? ''
        : ' · ${_overtureStageLabel(data.overture!.stage)}';

    final content = Row(
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
                        color:
                            data.playerPowerScore != null &&
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
              if (data.activeSubsidyPerTurn != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Outgoing subsidy: £${data.activeSubsidyPerTurn}/turn to ${data.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (data.pendingGrantAmount != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Pending grant aid: £${data.pendingGrantAmount} (resolves end of turn)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
              if (data.pendingSubsidyAmount != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Pending subsidy: £${data.pendingSubsidyAmount}/turn (resolves end of turn)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final order in data.actions)
              if (!data.pendingOrderTypes.contains(order.type))
                _ActionButton(order: order, onPressed: () => onAction(order)),
            for (final orderType in data.pendingOrderTypes)
              _ActionButton(
                order: DiplomaticOrder(
                  type: orderType,
                  targetFactionId: data.factionId,
                ),
                onPressed: () {},
                isPending: true,
                onCancel: () => onAction(
                  DiplomaticOrder(
                    type: orderType,
                    targetFactionId: data.factionId,
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: CtPanel(padding: const EdgeInsets.all(12), child: content),
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
    this.isPending = false,
    this.onCancel,
  });

  final DiplomaticOrder order;
  final VoidCallback onPressed;
  final bool isPending;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final label = isPending ? 'Cancel' : diplomacyActionLabel(order);
    return SizedBox(
      height: 32,
      child: CtNinePatchButton(
        onPressed: isPending ? onCancel : onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

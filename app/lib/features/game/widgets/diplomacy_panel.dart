// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/routes.dart';
import '../../../core/services/app_event_handler_scope.dart';
import '../../../core/services/subscription_tracker.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import 'diplomacy_order_helpers.dart';
import 'diplomacy_panel_rows.dart';
import 'fnv1a_hash_constants.dart';

export 'diplomacy_panel_rows.dart';

/// Full-page diplomacy panel. SPEC/ui/diplomacy-panel.md.
class DiplomacyPanel extends StatefulWidget {
  const DiplomacyPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.topology,
    required this.currentOrders,
    required this.bus,
    this.onClose,
    this.readOnly = false,
  });

  final Game game;
  final String humanPlayerId;
  final MapTopology topology;
  final Orders currentOrders;
  final AppEventBus bus;
  final VoidCallback? onClose;
  final bool readOnly;

  @override
  State<DiplomacyPanel> createState() => _DiplomacyPanelState();
}

class _DiplomacyPanelState extends State<DiplomacyPanel> {
  final Map<String, String> _moodByLeaderId = <String, String>{};
  final SubscriptionTracker _subscriptions = SubscriptionTracker();

  @override
  void initState() {
    super.initState();
    _subscriptions.track(
      widget.bus.on<PortraitMoodEvent>().listen((event) {
        _moodByLeaderId[event.leaderId] = event.toMood;
      }),
    );
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final rows = buildDiplomacyRows(
      widget.game,
      widget.topology,
      widget.humanPlayerId,
      widget.currentOrders,
    );
    final gps = <DiplomacyRowData>[];
    final minors = <DiplomacyRowData>[];
    final tribes = <DiplomacyRowData>[];
    for (final r in rows) {
      switch (r.kind) {
        case FactionKind.greatPower:
          gps.add(r);
        case FactionKind.minor:
          minors.add(r);
        case FactionKind.tribe:
          tribes.add(r);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (gps.isNotEmpty) ...[
          _sectionHeader(context, l10n.diplomacy_section_greatPowers),
          ...gps.map(
            (r) => _DiplomacyRow(
              data: r,
              onAction: _submitOrDialog,
              onTap: () => _openDetail(r),
              readOnly: widget.readOnly,
            ),
          ),
        ],
        if (minors.isNotEmpty) ...[
          _sectionHeader(context, l10n.diplomacy_section_minorNations),
          ...minors.map(
            (r) => _DiplomacyRow(
              data: r,
              onAction: _submitOrDialog,
              onTap: () => _openDetail(r),
              readOnly: widget.readOnly,
            ),
          ),
        ],
        if (tribes.isNotEmpty) ...[
          _sectionHeader(context, l10n.diplomacy_section_tribes),
          ...tribes.map(
            (r) => _DiplomacyRow(
              data: r,
              onAction: _submitOrDialog,
              onTap: () => _openDetail(r),
              readOnly: widget.readOnly,
            ),
          ),
        ],
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.diplomacy_panel_noFactions,
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
    widget.bus.emit(
      RemoveDiplomaticOrderRequestedEvent(
        playerId: widget.humanPlayerId,
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
    widget.bus.emit(
      AppendDiplomaticOrderRequestedEvent(
        playerId: widget.humanPlayerId,
        order: order,
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
    var hash = kFnv1aOffsetBasis32;
    for (final code in text.codeUnits) {
      hash ^= code;
      hash = (hash * kFnv1aPrime32) & kDeterministicLcg31Mask;
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
  const _DiplomacyRow({
    required this.data,
    required this.onAction,
    this.onTap,
    this.readOnly = false,
  });

  final DiplomacyRowData data;
  final void Function(DiplomaticOrder) onAction;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: CtPanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildInfoColumn(context)),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderRow(context),
        const SizedBox(height: 4),
        Text(
          _relationSummary(context),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        ..._buildOptionalStatusLines(context),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        Text(
          data.displayName,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        _kindChip(context, data.kind),
        ..._buildPowerComparison(context),
      ],
    );
  }

  /// Renders the Great Power power-comparison percentage per
  /// SPEC/ui/diplomacy-panel.md § Power comparison percentage.
  List<Widget> _buildPowerComparison(BuildContext context) {
    final int? gpScore = data.powerScore;
    final int? playerScore = data.playerPowerScore;
    if (gpScore == null || playerScore == null) {
      return const [];
    }
    final int pct = powerComparisonPercent(gpScore, playerScore);
    final String text = formatPowerComparisonPercent(pct);
    // SPEC: red (--danger) when GP stronger (pct > 0), green (--success) when
    // weaker or equal (pct <= 0). Token colors live in the editorial-monocle
    // palette so the row matches the dark theme rather than raw Material reds.
    final Color color = pct > 0
        ? EditorialMonoclePalette.danger
        : EditorialMonoclePalette.success;
    return [
      const SizedBox(width: 8),
      Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
  }

  String _relationSummary(BuildContext context) {
    final l10n = appL10n(context);
    final rel = data.relation;
    final stateLabel = rel == null
        ? '—'
        : rel.atWar
        ? l10n.diplomacy_relationState_war
        : l10n.diplomacy_relationState_peace;
    // SPEC/game/diplomacy.md § Player-facing relation display: show one-word state, hide score.
    final relationStateLabel = rel == null
        ? ''
        : relationScoreToDisplayLabel(rel.score);
    final overtureLabel = data.overture == null
        ? ''
        : ' · ${_overtureStageLabel(data.overture!.stage)}';
    if (relationStateLabel.isEmpty) {
      return '$stateLabel$overtureLabel';
    }
    return '$stateLabel · $relationStateLabel$overtureLabel';
  }

  List<Widget> _buildOptionalStatusLines(BuildContext context) {
    final l10n = appL10n(context);
    final lines = <Widget>[];
    if (data.activeSubsidyPerTurn != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_outgoingSubsidy(
            data.activeSubsidyPerTurn!,
            data.displayName,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      ]);
    }
    if (data.pendingGrantAmount != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_pendingGrant(data.pendingGrantAmount!),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ]);
    }
    if (data.pendingSubsidyAmount != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_pendingSubsidy(data.pendingSubsidyAmount!),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ]);
    }
    return lines;
  }

  Widget _buildActionButtons() {
    if (readOnly) {
      return const SizedBox.shrink();
    }
    return Wrap(
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
              DiplomaticOrder(type: orderType, targetFactionId: data.factionId),
            ),
          ),
      ],
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

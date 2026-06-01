// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/routes.dart';
import '../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../core/services/app_event_handler_scope.dart';
import '../../../core/services/subscription_tracker.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';
import 'diplomacy_order_helpers.dart';
import 'diplomacy_panel_rows.dart';
import 'fnv1a_hash_constants.dart';

export 'diplomacy_panel_rows.dart';

part 'diplomacy_panel_chrome.dart';
part 'diplomacy_panel_mode_bar.dart';

/// Maximum viewport width (Flutter dp) at which the diplomacy faction-row
/// body switches to its narrow stacked variant (info column above the
/// action-button cluster, left-aligned).
///
/// SPEC/ui/diplomacy-panel.md § Responsive layout — mirrors the
/// `@media (max-width: 500px)` cutoff in
/// [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// and the `≤ 500 dp` Diplomacy entry in
/// [mobile-adaptation.md](../../../../../SPEC/ui/mobile-adaptation.md) § 4.
///
/// Exposed at library scope so widget tests can pin the boundary
/// deterministically without re-deriving the constant.
const double kDiplomacyRowNarrowMaxWidth = 500.0;

/// Key prefix attached to a faction-row body widget so tests can resolve
/// the live Row (wide) vs Column (narrow) layout selection driven by
/// [kDiplomacyRowNarrowMaxWidth].
///
/// Each row uses `ValueKey('${kDiplomacyRowBodyKeyPrefix}<factionId>')`.
/// SPEC/ui/diplomacy-panel.md § Responsive layout cites this key so
/// widget tests can pin both variants without touching private types.
const String kDiplomacyRowBodyKeyPrefix = 'diplomacyRowBody:';

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

  /// Bottom-mode-bar filter (SPEC/ui/diplomacy-panel.md § Mode bar (filter)).
  /// Local UI state — does not persist across panel close/reopen.
  DiplomacyFilterMode _filterMode = DiplomacyFilterMode.all;

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
    final showGps = diplomacyFilterShowsKind(
      _filterMode,
      FactionKind.greatPower,
    );
    final showMinors = diplomacyFilterShowsKind(_filterMode, FactionKind.minor);
    final showTribes = diplomacyFilterShowsKind(_filterMode, FactionKind.tribe);

    final list = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (showGps && gps.isNotEmpty) ...[
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
        if (showMinors && minors.isNotEmpty) ...[
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
        if (showTribes && tribes.isNotEmpty) ...[
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
            padding: const EdgeInsets.all(CtSpacing.xxl),
            child: Text(
              l10n.diplomacy_panel_noFactions,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
      ],
    );

    return Column(
      children: [
        Expanded(child: list),
        _DiplomacyModeBar(
          mode: _filterMode,
          onModeChanged: (next) {
            if (next == _filterMode) return;
            setState(() => _filterMode = next);
          },
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return _DiplomacySectionHeader(title: title);
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
      case DiplomaticOrderType.establishFtp:
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
    // SPEC/ui/diplomacy-panel.md § Per-faction row → Row chrome: each row
    // is rendered as a flat gradient tile with a 1 px outline and pointer
    // hover behaviour. The InkWell sits inside the hover-aware chrome so
    // taps still navigate to the detail screen (or order-cancel toggle).
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final bool narrow = viewportWidth <= kDiplomacyRowNarrowMaxWidth;
    return _DiplomacyRowChrome(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.ml),
          child: narrow
              ? _buildNarrowBody(context)
              : _buildWideBody(context),
        ),
      ),
    );
  }

  Key get _bodyKey =>
      ValueKey('$kDiplomacyRowBodyKeyPrefix${data.factionId}');

  // SPEC/ui/diplomacy-panel.md § Responsive layout (wide variant): info
  // column shares a Row with the action cluster, anchored trailing-edge.
  Widget _buildWideBody(BuildContext context) {
    return Row(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInfoColumn(context)),
        _buildActionButtons(),
      ],
    );
  }

  // SPEC/ui/diplomacy-panel.md § Responsive layout (narrow ≤ 500 dp): info
  // column stacks above the action cluster; cluster aligns leading-edge.
  Widget _buildNarrowBody(BuildContext context) {
    final bool hasActions =
        !readOnly &&
        (data.actions.isNotEmpty || data.pendingOrderTypes.isNotEmpty);
    return Column(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoColumn(context),
        if (hasActions) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: _buildActionButtons()),
        ],
      ],
    );
  }

  Widget _buildInfoColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderRow(context),
        const SizedBox(height: 4),
        _buildRelationRow(context),
        ..._buildOptionalStatusLines(context),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    // SPEC/ui/mobile-adaptation.md § 7 Minimum-viewport pin: at
    // `kMinViewportWidth` (320 dp) the inner Row width is ~262 dp once the
    // ListView, row padding, and chrome border are subtracted. A long
    // faction display name (e.g. `Holy Roman Empire`) plus the
    // `_FactionKindBadge` chip and the optional `+N% / −N%` power
    // comparison label exceeds that budget by ~162 px without a
    // shrinkable child, producing the documented overflow. Wrap the name
    // in `Flexible` + `TextOverflow.ellipsis` so the name absorbs all
    // available width and shrinks gracefully at narrow viewports while
    // the chip + percentage retain their natural size for legibility.
    // SPEC/ui/diplomacy-panel.md § Per-faction row text layout is
    // preserved: the chip, optional percentage, and their leading gap
    // continue to anchor to the name's trailing edge.
    return Row(
      children: [
        Flexible(
          child: Text(
            data.displayName,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
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

  /// Renders the relation summary row per SPEC/ui/diplomacy-panel.md
  /// § Relation state badge + § Per-faction row. The WAR/PEACE chip uses
  /// the dedicated [_RelationStateBadge]; the one-word relation state
  /// (Hostile / Unfriendly / Cordial / Friendly) and the optional
  /// overture stage stay as inline text.
  Widget _buildRelationRow(BuildContext context) {
    final TextStyle? bodySmall = Theme.of(context).textTheme.bodySmall;
    final DiplomacyRelation? rel = data.relation;
    if (rel == null) {
      return Text('—', style: bodySmall);
    }
    // SPEC/game/diplomacy.md § Player-facing relation display: show
    // one-word state, hide score.
    final String relationStateLabel = relationScoreToDisplayLabel(rel.score);
    final String overtureLabel = data.overture == null
        ? ''
        : ' · ${_overtureStageLabel(data.overture!.stage)}';
    final String trailing = relationStateLabel.isEmpty
        ? overtureLabel
        : ' · $relationStateLabel$overtureLabel';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RelationStateBadge(atWar: rel.atWar),
        if (trailing.isNotEmpty)
          Flexible(
            child: Text(
              trailing,
              style: bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
      ],
    );
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
    return _FactionKindBadge(kind: kind);
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

  /// SPEC/ui/diplomacy-panel.md § Action button styling — destructive
  /// `Declare War` action resolves both the button outline and the
  /// engraved label to the canonical `--danger` token. Pending state
  /// keeps the default brass chrome so the "Cancel" affordance still
  /// reads as a recoverable toggle.
  bool get _isWarVariant =>
      !isPending && order.type == DiplomaticOrderType.declareWar;

  @override
  Widget build(BuildContext context) {
    final label = isPending ? 'Cancel' : diplomacyActionLabel(order);
    return SizedBox(
      height: 32,
      child: CtNinePatchButton(
        onPressed: isPending ? onCancel : onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        dangerVariant: _isWarVariant,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

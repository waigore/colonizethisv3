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
            padding: const EdgeInsets.all(24),
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

/// Bottom mode-bar filter for the Diplomacy panel.
///
/// SPEC/ui/diplomacy-panel.md § Mode bar (filter): anchored to the bottom of
/// the panel with a `--border` top divider; buttons use mono font with
/// inactive label `--muted`, active label `--accent`, and `--accent-dim`
/// border on the active item.
class _DiplomacyModeBar extends StatelessWidget {
  const _DiplomacyModeBar({required this.mode, required this.onModeChanged});

  final DiplomacyFilterMode mode;
  final ValueChanged<DiplomacyFilterMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EditorialMonoclePalette.border, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DiplomacyModeButton(
              label: l10n.diplomacy_filter_all,
              isActive: mode == DiplomacyFilterMode.all,
              onPressed: () => onModeChanged(DiplomacyFilterMode.all),
            ),
            const SizedBox(width: 8),
            _DiplomacyModeButton(
              label: l10n.diplomacy_filter_greatPowersOnly,
              isActive: mode == DiplomacyFilterMode.greatPowersOnly,
              onPressed: () =>
                  onModeChanged(DiplomacyFilterMode.greatPowersOnly),
            ),
            const SizedBox(width: 8),
            _DiplomacyModeButton(
              label: l10n.diplomacy_filter_minorsOnly,
              isActive: mode == DiplomacyFilterMode.minorsOnly,
              onPressed: () => onModeChanged(DiplomacyFilterMode.minorsOnly),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiplomacyModeButton extends StatelessWidget {
  const _DiplomacyModeButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = isActive
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.muted;
    final Border? border = isActive
        ? Border.all(color: EditorialMonoclePalette.accentDim, width: 1)
        : null;
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: border,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier'],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Section heading for a diplomacy faction group (Great Powers / Minor
/// Nations / Tribes).
///
/// SPEC/ui/diplomacy-panel.md § Section headings: display font, `--accent`
/// text color, 2 px `--accent-dim` bottom border per
/// [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// `.section-head`.
class _DiplomacySectionHeader extends StatelessWidget {
  const _DiplomacySectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 14);
    final TextStyle headingStyle = baseStyle.copyWith(
      color: EditorialMonoclePalette.accent,
      fontFamily: editorialMonocleDisplayFontFamily,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.accentDim,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(title, style: headingStyle),
        ),
      ),
    );
  }
}

/// Faction type badge (GP / Minor / Tribe) for diplomacy rows.
///
/// SPEC/ui/diplomacy-panel.md § Per-faction row → Type badge colors:
/// - GP: `--accent-dim` background, `--bg-deep` foreground.
/// - Minor: `--muted` background, `--bg-deep` foreground.
/// - Tribe: outlined — transparent background, `--muted` border + foreground.
///
/// Matches [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// `.f-badge` chrome (mono font, tight letter-spacing, square `1px`
/// border-radius). All colors resolve from the canonical editorial-monocle
/// palette — no hardcoded Material chrome.
class _FactionKindBadge extends StatelessWidget {
  const _FactionKindBadge({required this.kind});

  final FactionKind kind;

  @override
  Widget build(BuildContext context) {
    final ({String label, Color? background, Color? border, Color foreground})
    spec = switch (kind) {
      FactionKind.greatPower => (
        label: 'GP',
        background: EditorialMonoclePalette.accentDim,
        border: null,
        foreground: EditorialMonoclePalette.bgDeep,
      ),
      FactionKind.minor => (
        label: 'Minor',
        background: EditorialMonoclePalette.muted,
        border: null,
        foreground: EditorialMonoclePalette.bgDeep,
      ),
      FactionKind.tribe => (
        label: 'Tribe',
        background: null,
        border: EditorialMonoclePalette.muted,
        foreground: EditorialMonoclePalette.muted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: spec.background,
        border: spec.border == null
            ? null
            : Border.all(color: spec.border!, width: 1),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          color: spec.foreground,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier'],
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/routes.dart';
import '../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../config/ui_screen_ids.dart';
import '../../../core/services/app_event_handler_scope.dart';
import '../../../core/services/subscription_tracker.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_radius.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_spacing.dart';
import 'diplomacy_order_helpers.dart';
import 'game_panel_contract.dart';
import 'diplomacy_panel_rows.dart';
import 'fnv1a_hash_constants.dart';

export 'diplomacy_panel_rows.dart';

part 'diplomacy_panel_chrome.dart';
part 'diplomacy_panel_mode_bar.dart';
part 'diplomacy_panel_row.dart';

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
class DiplomacyPanel extends StatefulWidget with GamePanelMixin {
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

  /// SPEC/ui/diplomacy-panel.md — [UiScreenIds.diplomacyScreen]. Hosted by
  /// `DiplomacyScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.diplomacyScreen;

  @override
  final Game game;
  @override
  final String humanPlayerId;
  final MapTopology topology;
  final Orders currentOrders;
  @override
  final AppEventBus bus;
  final VoidCallback? onClose;
  @override
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
      padding: const EdgeInsets.symmetric(
        horizontal: CtSpacing.l,
        vertical: CtSpacing.m,
      ),
      children: [
        // SPEC/ui/diplomacy-panel.md § Section headings: each section
        // heading is always rendered (subject to the mode-bar filter),
        // even when the section has no rows. An empty visible section
        // renders placeholder copy beneath its heading.
        if (showGps) ...[
          _sectionHeader(context, l10n.diplomacy_section_greatPowers),
          if (gps.isEmpty)
            _emptySectionPlaceholder(
              context,
              l10n.diplomacy_panel_noGreatPowers,
            )
          else
            ...gps.map(
              (r) => _DiplomacyRow(
                data: r,
                onAction: _submitOrDialog,
                onTap: () => _openDetail(r),
                readOnly: widget.readOnly,
              ),
            ),
        ],
        if (showMinors) ...[
          _sectionHeader(context, l10n.diplomacy_section_minorNations),
          if (minors.isEmpty)
            _emptySectionPlaceholder(
              context,
              l10n.diplomacy_panel_noMinorNations,
            )
          else
            ...minors.map(
              (r) => _DiplomacyRow(
                data: r,
                onAction: _submitOrDialog,
                onTap: () => _openDetail(r),
                readOnly: widget.readOnly,
              ),
            ),
        ],
        if (showTribes) ...[
          _sectionHeader(context, l10n.diplomacy_section_tribes),
          if (tribes.isEmpty)
            _emptySectionPlaceholder(context, l10n.diplomacy_panel_noTribes)
          else
            ...tribes.map(
              (r) => _DiplomacyRow(
                data: r,
                onAction: _submitOrDialog,
                onTap: () => _openDetail(r),
                readOnly: widget.readOnly,
              ),
            ),
        ],
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

  /// Placeholder copy rendered beneath an empty (but always-visible)
  /// section heading. SPEC/ui/diplomacy-panel.md § Section headings —
  /// muted italic text using the editorial-monocle `--muted` token
  /// (matches the mockup `.empty` style), e.g. the Tribes section before
  /// any tribe has been contacted shows "No tribes contacted yet.".
  Widget _emptySectionPlaceholder(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CtSpacing.s,
        vertical: CtSpacing.m,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: EditorialMonoclePalette.muted,
          fontStyle: FontStyle.italic,
        ),
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

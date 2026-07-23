// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../core/services/subscription_tracker.dart';
import '../panels/game_panel_contract.dart';
import 'diplomacy_panel_body.dart';
import 'diplomacy_panel_filter.dart';
import 'diplomacy_panel_mode_bar.dart';
import 'diplomacy_panel_order_actions.dart';
import 'diplomacy_panel_order_actions_mood.dart';
import 'diplomacy_panel_rows.dart';

export 'diplomacy_panel_chrome_relation_badges.dart'
    show DiplomacyAllianceBadge;
export 'diplomacy_panel_chrome_standing.dart'
    show DiplomacyStandingChipCluster;
export 'diplomacy_panel_constants.dart';
export 'diplomacy_panel_rows.dart';
export 'relative_power_line.dart';

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
  State<DiplomacyPanel> createState() => DiplomacyPanelState();
}

class DiplomacyPanelState extends State<DiplomacyPanel>
    with DiplomacyOrderActionsMood, DiplomacyOrderActions {
  final Map<String, String> _moodByLeaderId = <String, String>{};
  final SubscriptionTracker _subscriptions = SubscriptionTracker();

  @override
  Map<String, String> get moodByLeaderId => _moodByLeaderId;

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
    final rows = buildDiplomacyRows(
      widget.game,
      widget.topology,
      widget.humanPlayerId,
      widget.currentOrders,
    );
    final filtered = filterDiplomacyPanelRows(
      rows: rows,
      filterMode: _filterMode,
    );

    return Column(
      children: [
        Expanded(
          child: DiplomacyPanelBody(
            gps: filtered.gps,
            minors: filtered.minors,
            tribes: filtered.tribes,
            showGps: filtered.showGps,
            showMinors: filtered.showMinors,
            showTribes: filtered.showTribes,
            firstShownKind: filtered.firstShownKind,
            onAction: submitOrDialog,
            onTap: openDetail,
            readOnly: widget.readOnly,
          ),
        ),
        DiplomacyModeBar(
          mode: _filterMode,
          onModeChanged: (next) {
            if (next == _filterMode) return;
            setState(() => _filterMode = next);
          },
        ),
      ],
    );
  }
}

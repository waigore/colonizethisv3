import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/subscription_tracker.dart';
import 'diplomacy_panel_body.dart';
import 'diplomacy_panel_filter.dart';
import 'diplomacy_panel_mode_bar.dart';
import 'diplomacy_panel_order_actions.dart';
import 'diplomacy_panel_order_actions_mood.dart';
import 'diplomacy_panel_rows.dart';
import 'diplomacy_panel_widget.dart';

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

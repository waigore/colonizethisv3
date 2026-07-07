// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/routes.dart';
import '../../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../../config/ui_screen_ids.dart';
import '../../../../core/services/app_event_handler/app_event_handler_scope.dart';
import '../../../../core/services/subscription_tracker.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_radius.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/relation_meter.dart';
import 'diplomacy_order_helpers.dart';
import '../panels/game_panel_contract.dart';
import 'diplomacy_panel_rows.dart';
import 'fnv1a_hash_constants.dart';
import 'relative_power_line.dart';

export 'diplomacy_panel_rows.dart';
export 'relative_power_line.dart';

part 'diplomacy_panel_body.dart';
part 'diplomacy_panel_chrome_badges.dart';
part 'diplomacy_panel_chrome_standing.dart';
part 'diplomacy_panel_constants.dart';
part 'diplomacy_panel_filter.dart';
part 'diplomacy_panel_mode_bar.dart';
part 'diplomacy_panel_order_actions.dart';
part 'diplomacy_panel_row.dart';
part 'diplomacy_panel_row_info.dart';
part 'diplomacy_panel_row_actions.dart';

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

class _DiplomacyPanelState extends State<DiplomacyPanel>
    with _DiplomacyOrderActions {
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
    final filtered = _filterDiplomacyPanelRows(
      rows: rows,
      filterMode: _filterMode,
    );

    return Column(
      children: [
        Expanded(
          child: _DiplomacyPanelBody(
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
}

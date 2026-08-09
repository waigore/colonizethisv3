// Military units panel. SPEC/ui/military-units-panel.md, SPEC/ui/military-units-army-management.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../config/ui_screen_ids.dart';
import '../../panels/game_panel_contract.dart';
import 'military_units_panel_state.dart';

export 'military_units_panel_state.dart' show MilitaryUnitsPanelState;

class MilitaryUnitsPanel extends StatefulWidget with GamePanelMixin {
  const MilitaryUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.draftOrders,
    this.readOnly = false,
  });

  /// SPEC/ui/military-units-panel.md — [UiScreenIds.militaryUnitsPanel].
  static const screenId = UiScreenIds.militaryUnitsPanel;

  @override
  final Game game;
  @override
  final String humanPlayerId;
  @override
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;
  @override
  final bool readOnly;

  @override
  State<MilitaryUnitsPanel> createState() => MilitaryUnitsPanelState();
}

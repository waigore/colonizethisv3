// Diplomacy panel widget. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../panels/game_panel_contract.dart';
import 'diplomacy_panel_state.dart';

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
  State<DiplomacyPanel> createState() => DiplomacyPanelState();
}

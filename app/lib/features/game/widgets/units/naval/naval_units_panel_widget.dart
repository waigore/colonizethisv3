// Naval units panel screen widget. SPEC/ui/naval-units-panel.md.
//
// De-parted wave-9 cluster (Refs #4117): explicit-import libraries replace the
// former part library. Public surface: [NavalUnitsPanel].

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../config/ui_screen_ids.dart';
import '../../panels/game_panel_contract.dart';
import 'naval_units_panel_state.dart';

/// Naval fleets panel. SPEC/ui/naval-units-panel.md.
class NavalUnitsPanel extends StatefulWidget with GamePanelMixin {
  const NavalUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    this.draftOrders = const Orders(),
    this.tileMapByRegion,
    this.topologyByRegion,
    this.locationScopeKey,
    this.initialSelectedFleetId,
    this.tileScopeTileKey,
    this.readOnly = false,
  });

  /// SPEC/ui/naval-units-panel.md — [UiScreenIds.navalUnitsPanel].
  static const screenId = UiScreenIds.navalUnitsPanel;

  @override
  final Game game;
  @override
  final String humanPlayerId;
  @override
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, MapTopology>? topologyByRegion;
  final String? locationScopeKey;
  final String? initialSelectedFleetId;
  final String? tileScopeTileKey;
  @override
  final bool readOnly;

  @override
  State<NavalUnitsPanel> createState() => NavalUnitsPanelState();
}

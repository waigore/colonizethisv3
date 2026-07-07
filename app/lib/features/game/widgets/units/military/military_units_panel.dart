// Military units panel. SPEC/ui/military-units-panel.md, SPEC/ui/military-units-army-management.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../config/ui_screen_ids.dart';
import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../core/services/app_event_handler/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import '../../../../../widgets/ct_spacing.dart';
import '../../chrome/ct_action_text_button.dart';
import '../../panels/game_panel_contract.dart';
import '../../panels/tree_builders/military_tree_builder.dart';
import '../../unit_orders/move_army_dialog.dart';
import '../../unit_orders/split_army_dialog.dart';
import '../shared/base_units_panel.dart';
import '../shared/location_section_header.dart';
import '../shared/region_section_header.dart';
import '../shared/units_entity_action_row.dart';
import '../shared/units_entity_card.dart';
import '../shared/region_labels.dart';

part 'military_units_panel_support_army_tile.dart';
part 'military_units_panel_support_detail_rows.dart';
part 'military_units_panel_build.dart';
part 'military_units_panel_dialogs.dart';

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
  State<MilitaryUnitsPanel> createState() => _MilitaryUnitsPanelState();
}

class _MilitaryUnitsPanelState
    extends BaseUnitsPanelState<MilitaryUnitsPanel> {
  @override
  Widget build(BuildContext context) => buildMilitaryUnitsPanel(context);
}

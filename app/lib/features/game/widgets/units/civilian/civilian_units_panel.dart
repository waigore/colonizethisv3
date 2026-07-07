// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import '../../../../../config/ui_screen_ids.dart';
import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../core/services/app_event_handler/app_event_handler_scope.dart';
import '../../../../../providers/games_provider.dart';
import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../widgets/ct_gap.dart';
import '../../../../../widgets/ct_spacing.dart';
import '../../chrome/ct_action_text_button.dart';
import '../../chrome/ct_circular_locate_button.dart';
import '../../chrome/ct_danger_text_button.dart';
import '../../../../../widgets/resource_icon.dart';
import 'civilian_units_sort.dart';
import '../../panels/game_panel_contract.dart';
import '../../train/train_dialog_chrome.dart';
import '../shared/region_section_header.dart';
import '../shared/units_entity_action_row.dart';
import '../shared/units_panel_shell.dart';
import '../shared/region_labels.dart';

/// Panel that lists all civilian units for the human player. SPEC/ui/civilian-units-panel.md.

part 'civilian_units_panel_list.dart';
part 'civilian_units_panel_build.dart';
part 'civilian_units_panel_support_resolution.dart';
part 'civilian_units_panel_support_row_card.dart';
part 'civilian_units_panel_support_unit_row.dart';
part 'civilian_units_panel_support_unit_row_labels.dart';
part 'civilian_units_panel_support_unit_row_actions.dart';

class CivilianUnitsPanel extends ConsumerStatefulWidget with GamePanelMixin {
  const CivilianUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.civilianOwnerIds,
    required this.bus,
    this.currentOrders = const Orders(),
    this.tileScopeTileKey,
    this.initialSelectedUnitId,
    this.explorerOnly = false,
    this.builderOnly = false,
    this.prospectShortcutTargetTileKey,
    this.exploreShortcutTargetTileKey,
    this.buildImprovementShortcutTargetTileKey,
    this.readOnly = false,
  });

  /// SPEC/ui/civilian-units-panel.md — [UiScreenIds.civilianUnitsPanel].
  static const screenId = UiScreenIds.civilianUnitsPanel;

  @override
  final Game game;
  @override
  final String humanPlayerId;

  /// When set, lists civilians for every id (global observe). Otherwise [humanPlayerId] only.
  final Set<String>? civilianOwnerIds;

  @override
  final AppEventBus bus;

  /// Current-turn orders (to show Assign only when no pending work, Cancel when pending or in-progress).
  final Orders currentOrders;

  /// Optional tile key (`regionId|provinceId|x|y`) for tile-scoped mode.
  final String? tileScopeTileKey;

  /// Optional initial selected unit in tile-scoped mode.
  final String? initialSelectedUnitId;

  /// Optional filter mode used by province prospect shortcut.
  final bool explorerOnly;

  /// Optional filter mode used by province build-improvement shortcut.
  final bool builderOnly;

  /// Optional selected tile key for immediate explorer prospect assign flow.
  final String? prospectShortcutTargetTileKey;

  /// Optional selected tile key for immediate explorer explore assign flow.
  final String? exploreShortcutTargetTileKey;

  /// Optional selected tile key for immediate builder build-improvement assign flow.
  final String? buildImprovementShortcutTargetTileKey;

  /// When true, work assign/cancel and train are disabled (observe mode).
  @override
  final bool readOnly;

  @override
  ConsumerState<CivilianUnitsPanel> createState() => _CivilianUnitsPanelState();
}

class _CivilianUnitsPanelState extends ConsumerState<CivilianUnitsPanel> {
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.initialSelectedUnitId;
  }

  @override
  void didUpdateWidget(covariant CivilianUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedUnitId != widget.initialSelectedUnitId) {
      _selectedUnitId = widget.initialSelectedUnitId;
    }
  }

  @override
  Widget build(BuildContext context) => buildCivilianUnitsPanel(context);
}

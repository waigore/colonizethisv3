// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/ui_screen_ids.dart';
import '../../panels/game_panel_contract.dart';
import 'civilian_units_panel_state.dart';

export 'civilian_units_panel_support_row_card.dart' show CivilianUnitRowCard;
export 'civilian_units_panel_state.dart' show CivilianUnitsPanelState;

/// Panel that lists all civilian units for the human player. SPEC/ui/civilian-units-panel.md.
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
    this.engineerOnly = false,
    this.prospectShortcutTargetTileKey,
    this.exploreShortcutTargetTileKey,
    this.buildImprovementShortcutTargetTileKey,
    this.buildRoadShortcutTargetTileKey,
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

  /// Optional filter mode used by province build-road shortcut.
  final bool engineerOnly;

  /// Optional selected tile key for immediate explorer prospect assign flow.
  final String? prospectShortcutTargetTileKey;

  /// Optional selected tile key for immediate explorer explore assign flow.
  final String? exploreShortcutTargetTileKey;

  /// Optional selected tile key for immediate builder build-improvement assign flow.
  final String? buildImprovementShortcutTargetTileKey;

  /// Optional selected tile key for immediate engineer build-road assign flow.
  final String? buildRoadShortcutTargetTileKey;

  /// When true, work assign/cancel and train are disabled (observe mode).
  @override
  final bool readOnly;

  @override
  ConsumerState<CivilianUnitsPanel> createState() => CivilianUnitsPanelState();
}

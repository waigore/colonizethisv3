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
    this.railBuilderOnly = false,
    this.merchantOnly = false,
    this.spyOnly = false,
    this.prospectShortcutTargetTileKey,
    this.exploreShortcutTargetTileKey,
    this.buildImprovementShortcutTargetTileKey,
    this.buildRoadShortcutTargetTileKey,
    this.buildFortShortcutTargetTileKey,
    this.buildPortShortcutTargetTileKey,
    this.buildRailShortcutTargetTileKey,
    this.purchaseLandShortcutTargetTileKey,
    this.upgradeTownShortcutTargetTileKey,
    this.relocateShortcutTargetTileKey,
    this.counterSpyShortcutTargetTileKey,
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

  /// Optional filter mode used by province build-railroad shortcut.
  final bool railBuilderOnly;

  /// Optional filter mode used by province purchase-land shortcut.
  final bool merchantOnly;

  /// Optional filter mode used by province Station spy shortcut (Refs #4439).
  final bool spyOnly;

  /// Optional selected tile key for immediate explorer prospect assign flow.
  final String? prospectShortcutTargetTileKey;

  /// Optional selected tile key for immediate explorer explore assign flow.
  final String? exploreShortcutTargetTileKey;

  /// Optional selected tile key for immediate builder build-improvement assign flow.
  final String? buildImprovementShortcutTargetTileKey;

  /// Optional selected tile key for immediate engineer build-road assign flow.
  final String? buildRoadShortcutTargetTileKey;

  /// Optional selected tile key for immediate engineer build-fort assign flow.
  final String? buildFortShortcutTargetTileKey;
  final String? buildPortShortcutTargetTileKey;

  /// Optional selected tile key for immediate Rail Builder build-rail assign flow.
  final String? buildRailShortcutTargetTileKey;

  /// Optional selected tile key for immediate merchant purchase-land assign flow.
  final String? purchaseLandShortcutTargetTileKey;

  /// Optional selected tile key for immediate builder upgrade-town assign flow.
  final String? upgradeTownShortcutTargetTileKey;

  /// Optional selected tile key for immediate Spy Relocate (Refs #4439).
  final String? relocateShortcutTargetTileKey;

  /// Optional province-level tile key for Spy Counter-espionage (Refs #4528).
  final String? counterSpyShortcutTargetTileKey;

  /// When true, work assign/cancel and train are disabled (observe mode).
  @override
  final bool readOnly;

  @override
  ConsumerState<CivilianUnitsPanel> createState() => CivilianUnitsPanelState();
}


import 'package:colonizethis_models/colonizethis_models.dart';

import 'military_tree_builder.dart';
import 'military_tree_builder_assembly_province.dart';
import 'military_tree_builder_assembly_sea.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

List<RegionMilitaryGroup> buildMilitaryGroups(Game game, String humanPlayerId) {
  final unitsById = game.worldState.allUnitsById;

  final armies = militaryTreeArmiesForPanel(game, humanPlayerId);

  final result = <RegionMilitaryGroup>[];

  game.worldState.forEachRegion((regionKey, regionData) {
    final provinceNodes = militaryTreeProvinceArmyNodesForRegion(
      game: game,
      regionKey: regionKey,
      regionData: regionData,
      armies: armies,
      unitsById: unitsById,
    );

    final seaLocations = militaryTreeSeaZoneNodesForRegion(
      game: game,
      regionKey: regionKey,
      humanPlayerId: humanPlayerId,
    );

    if (provinceNodes.isNotEmpty || seaLocations.isNotEmpty) {
      result.add(
        RegionMilitaryGroup(
          regionKey: regionKey,
          provinces: provinceNodes,
          seaLocations: seaLocations,
        ),
      );
    }
  });

  return result;
}

List<ArmyBlock> flattenMilitaryArmyBlocks(List<RegionMilitaryGroup> groups) {
  final out = <ArmyBlock>[];
  for (final g in groups) {
    for (final p in g.provinces) {
      out.addAll(p.armies);
    }
  }
  return out;
}

bool canCombineArmySelection(
  List<ArmyBlock> flat,
  Set<String> selectedArmyIds,
) {
  if (selectedArmyIds.length < 2) return false;
  final selected = flat
      .where((b) => selectedArmyIds.contains(b.army.id))
      .toList();
  if (selected.length < 2) return false;
  final province = selected.first.army.stationedProvinceId;
  return selected.every((b) => b.army.stationedProvinceId == province);
}

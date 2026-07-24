import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'military_tree_builder.dart';
import 'military_tree_builder_assembly_province.dart';
import 'military_tree_builder_assembly_sea.dart';

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

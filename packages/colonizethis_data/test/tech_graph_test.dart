import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Tech ids from SPEC/game tech-tree.md and category sub-docs (source of truth for "all techs in the tree").
/// Used to assert the catalog matches the spec and every spec tech is present and reachable.
const Set<String> _specTechIds = {
  // Gathering — tech-tree-gathering.md
  'crop_rotation',
  'saw_mill',
  'land_enclosure',
  'mine_engineering',
  'iron_mining',
  'copper_and_tin_mining',
  'coal_mining',
  'wind_saw_mill',
  'seed_drill',
  'sheep_ranching',
  'animal_husbandry',
  'square_set_timbering',
  'steam_in_mining',
  'large_coal_mines',
  'large_copper_and_tin_mines',
  'circular_saw',
  'scientific_sheep_breeding',
  'scientific_cattle_breeding',
  'moldboard_plow',
  'safety_lamp',
  'large_precious_stone_mines',
  'extraction_of_precious_metals',
  'geological_prospecting',
  'amalgamation_process',
  'industrial_iron_mining',
  'efficient_extraction_of_copper_and_tin',
  // Labour — tech-tree-labour-economy.md
  'printing_press',
  'apprentice_workers',
  'trained_journeymen',
  'master_artisans',
  'money_lending',
  'banking',
  'trade_fairs',
  'university',
  // Transport — tech-tree-transport.md
  'road_construction',
  'early_steam_engine',
  'later_steam_engine',
  'dynamite',
  // Diplomacy / Civilian — tech-tree-diplomacy-civilian.md
  'diplomatic_expertise',
  'merchant_companies',
  'national_bureaucracy',
  'propaganda',
  'nationalism',
  'empire_building',
  // Naval — tech-tree-naval.md
  'superior_hull_design',
  'improved_sail_design',
  'convoying',
  'navigation',
  'large_hulls',
  'clipper_ships',
  'paddlewheels',
  'merchant_steamships',
  'advanced_hull_design',
  'ship_of_the_line',
  'privateering_companies',
  'advanced_iron_working',
  // Military — tech-tree-military.md (infantry, cavalry, artillery/forts)
  'organised_regiments',
  'improved_iron_weapons',
  'improved_infantry_tactics',
  'crucible_process',
  'bayonet',
  'weapon_craftsmanship',
  'industrial_machinery',
  'explosives',
  'early_rifles',
  'long_range_rifles',
  'needle_guns',
  'elite_military_training',
  'recruit_steppe_horsemen',
  'improved_cavalry_tactics',
  'hussars',
  'improved_cavalry_weapons',
  'scouting',
  'repeating_cavalry_carbine',
  'horse_artillery',
  'siege_engineering',
  'light_artillery_tactics',
  'modern_forts',
  'heavy_artillery',
  'heavy_emplaced_artillery',
  'field_artillery_tactics',
  'high_grade_steel',
  'emplaced_siege_guns',
  'modern_military_funding',
  'industrial_funding_of_research',
  // New World — tech-tree-new-world.md
  'discovery_of_sugar',
  'sugar_planting',
  'sugar_refining',
  'large_sugar_plantations',
  'sugar_industry',
  'discovery_of_tobacco',
  'tobacco_planting',
  'cigar_production',
  'large_tobacco_plantations',
  'tobacco_industry',
  'discovery_of_cotton',
  'cotton_planting',
  'cotton_weaving',
  'large_cotton_plantations',
  'cotton_gin',
  'discovery_of_furs',
  'improved_trapping_techniques',
  'hat_production',
  'riverboats',
  'excessive_fur_harvesting',
  'discovery_of_spices',
  'improved_sea_routes',
  'large_spice_plantations',
  'improved_food_preservation',
  'discovery_of_gold_or_silver',
  'precious_metals_mining',
  'discovery_of_gems_or_diamonds',
  'precious_stone_mining',
};

void main() {
  group('tech graph integrity', () {
    test('catalog contains exactly the techs defined in SPEC/game tech-tree docs', () {
      expect(_specTechIds.length, equals(113), reason: 'SPEC defines 113 technologies');
      final catalogIds = techCatalog.keys.toSet();
      final missing = _specTechIds.difference(catalogIds);
      final extra = catalogIds.difference(_specTechIds);
      expect(missing, isEmpty, reason: 'Catalog missing spec techs: $missing');
      expect(extra, isEmpty, reason: 'Catalog has techs not in spec: $extra');
    });

    test('every prerequisite references a tech in the catalog', () {
      for (final entry in techCatalog.entries) {
        for (final prereqId in entry.value.prerequisiteIds) {
          expect(
            techCatalog.containsKey(prereqId),
            isTrue,
            reason: '${entry.key} has prerequisite $prereqId which is not in the catalog',
          );
        }
      }
    });

    test('all techs are reachable from starting techs (except the starting techs themselves) and graph is acyclic', () {
      // Build adjacency list: prereq -> list of techs that require it.
      final Map<String, List<String>> graph = {
        for (final id in techCatalog.keys) id: <String>[],
      };
      final Set<String> techsThatAppearAsPrereq = <String>{};

      techCatalog.forEach((id, def) {
        for (final prereq in def.prerequisiteIds) {
          techsThatAppearAsPrereq.add(prereq);
          final List<String> dependents = graph.putIfAbsent(prereq, () => <String>[]);
          dependents.add(id);
        }
      });

      // Starting techs: those with no prerequisites.
      final Set<String> startingTechIds = techCatalog.values
          .where((def) => def.prerequisiteIds.isEmpty)
          .map((def) => def.id)
          .toSet();

      expect(startingTechIds, isNotEmpty, reason: 'There should be at least one starting tech');

      // Terminal techs: techs that are never prerequisites of any other tech (no outgoing edges).
      final Set<String> terminalTechIds = techCatalog.keys
          .where((id) => !techsThatAppearAsPrereq.contains(id))
          .toSet();

      expect(terminalTechIds, isNotEmpty, reason: 'There should be at least one terminal tech');

      // Reachability: all non-starting techs (including terminal techs) must be reachable from some starting tech.
      final Set<String> visited = <String>{};

      void dfs(String id) {
        if (visited.contains(id)) {
          return;
        }
        visited.add(id);
        for (final next in graph[id] ?? const <String>[]) {
          dfs(next);
        }
      }

      for (final start in startingTechIds) {
        dfs(start);
      }

      // Every non-starting tech must be reachable from at least one starting tech.
      final Iterable<String> nonStartingTechIds =
          techCatalog.keys.where((id) => !startingTechIds.contains(id));
      for (final techId in nonStartingTechIds) {
        expect(
          visited.contains(techId),
          isTrue,
          reason: 'Tech $techId must be reachable from at least one starting tech',
        );
      }

      // All terminal techs are a subset of non-starting techs; this is a stricter check.
      for (final terminal in terminalTechIds) {
        expect(
          visited.contains(terminal),
          isTrue,
          reason: 'Terminal tech $terminal must be reachable from at least one starting tech',
        );
      }

      // Cycle check: the directed tech graph must not contain cycles.
      final Set<String> permVisited = <String>{};
      final Set<String> tempStack = <String>{};

      bool hasCycleFrom(String id) {
        if (tempStack.contains(id)) {
          return true; // Found a back edge => cycle.
        }
        if (permVisited.contains(id)) {
          return false;
        }
        tempStack.add(id);
        for (final next in graph[id] ?? const <String>[]) {
          if (hasCycleFrom(next)) {
            return true;
          }
        }
        tempStack.remove(id);
        permVisited.add(id);
        return false;
      }

      bool hasCycle = false;
      for (final id in graph.keys) {
        if (!permVisited.contains(id) && hasCycleFrom(id)) {
          hasCycle = true;
          break;
        }
      }

      expect(hasCycle, isFalse, reason: 'Tech tree must not contain cyclic paths');
    });

    test('catalog has exactly 113 techs and techIds matches', () {
      expect(techCatalog.length, equals(113), reason: 'Imperialism II 08-technology chart defines 113 technologies');
      expect(techIds.length, equals(113));
      expect(techIds.toSet().length, equals(113), reason: 'techIds must have unique entries');
      for (final id in techIds) {
        expect(techCatalog.containsKey(id), isTrue, reason: 'techIds must be subset of catalog keys');
      }
      for (final id in techCatalog.keys) {
        expect(techIds.contains(id), isTrue, reason: 'catalog keys must be in techIds');
      }
    });
  });
}


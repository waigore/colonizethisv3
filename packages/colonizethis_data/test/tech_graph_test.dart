import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('tech graph integrity', () {
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


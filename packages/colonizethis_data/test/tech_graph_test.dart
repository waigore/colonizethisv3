import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'support/tech_graph_spec_ids.dart';

void main() {
  group('tech graph integrity', () {
    test(
      'catalog contains exactly the techs defined via kTechId* / SPEC/game tech-tree docs',
      () {
        expect(
          techGraphSpecTechIds.length,
          equals(113),
          reason: 'SPEC defines 113 technologies',
        );
        final catalogIds = techCatalog.keys.toSet();
        final missing = techGraphSpecTechIds.difference(catalogIds);
        final extra = catalogIds.difference(techGraphSpecTechIds);
        expect(
          missing,
          isEmpty,
          reason: 'Catalog missing spec techs: $missing',
        );
        expect(extra, isEmpty, reason: 'Catalog has techs not in spec: $extra');
      },
    );

    test('every prerequisite references a tech in the catalog', () {
      for (final entry in techCatalog.entries) {
        for (final prereqId in entry.value.prerequisiteIds) {
          expect(
            techCatalog.containsKey(prereqId),
            isTrue,
            reason:
                '${entry.key} has prerequisite $prereqId which is not in the catalog',
          );
        }
      }
    });

    test(
      'all techs are reachable from starting techs and the graph is acyclic',
      () {
        final graph = <String, List<String>>{
          for (final id in techCatalog.keys) id: <String>[],
        };
        final techsThatAppearAsPrereq = <String>{};

        techCatalog.forEach((id, def) {
          for (final prereq in def.prerequisiteIds) {
            techsThatAppearAsPrereq.add(prereq);
            graph.putIfAbsent(prereq, () => <String>[]).add(id);
          }
        });

        final startingTechIds = techCatalog.values
            .where((def) => def.prerequisiteIds.isEmpty)
            .map((def) => def.id)
            .toSet();

        expect(
          startingTechIds,
          isNotEmpty,
          reason: 'There should be at least one starting tech',
        );

        final terminalTechIds = techCatalog.keys
            .where((id) => !techsThatAppearAsPrereq.contains(id))
            .toSet();

        expect(
          terminalTechIds,
          isNotEmpty,
          reason: 'There should be at least one terminal tech',
        );

        final visited = <String>{};

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

        final nonStartingTechIds = techCatalog.keys.where(
          (id) => !startingTechIds.contains(id),
        );
        for (final techId in nonStartingTechIds) {
          expect(
            visited.contains(techId),
            isTrue,
            reason:
                'Tech $techId must be reachable from at least one starting tech',
          );
        }

        for (final terminal in terminalTechIds) {
          expect(
            visited.contains(terminal),
            isTrue,
            reason:
                'Terminal tech $terminal must be reachable from at least one starting tech',
          );
        }

        final permVisited = <String>{};
        final tempStack = <String>{};

        bool hasCycleFrom(String id) {
          if (tempStack.contains(id)) {
            return true;
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

        var hasCycle = false;
        for (final id in graph.keys) {
          if (!permVisited.contains(id) && hasCycleFrom(id)) {
            hasCycle = true;
            break;
          }
        }

        expect(
          hasCycle,
          isFalse,
          reason: 'Tech tree must not contain cyclic paths',
        );
      },
    );

    test('catalog has exactly 113 techs and techIds matches', () {
      expect(
        techCatalog.length,
        equals(113),
        reason: 'Imperialism II 08-technology chart defines 113 technologies',
      );
      expect(techIds.length, equals(113));
      expect(
        techIds.toSet().length,
        equals(113),
        reason: 'techIds must have unique entries',
      );
      for (final id in techIds) {
        expect(
          techCatalog.containsKey(id),
          isTrue,
          reason: 'techIds must be subset of catalog keys',
        );
      }
      for (final id in techCatalog.keys) {
        expect(
          techIds.contains(id),
          isTrue,
          reason: 'catalog keys must be in techIds',
        );
      }
    });
  });
}

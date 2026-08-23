// Layout unit pins split from tech_tree_widget_core_test (Refs #4606 Slice D).
// SPEC/ui/tech-tree-widget.md column/connector rules.

import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test(
    'Column rule: A→B→C and A→C places B between A and C (gap between A and C)',
    () {
      // SPEC/ui/tech-tree-widget.md: when there is both a chain (A→B→C) and a
      // direct edge (A→C), there must be a gap between A and C because B
      // occupies the column in between.
      TechDefinition def(String id, List<String> prereqs) => TechDefinition(
        id: id,
        era: 1,
        category: 'gathering',
        cost: 1,
        prerequisiteIds: prereqs,
        regimentUnlockIds: const [],
        shipUnlockIds: const [],
      );
      final catalog = <String, TechDefinition>{
        'a': def('a', const []),
        'b': def('b', const ['a']),
        'c': def('c', const ['a', 'b']),
      };
      final positions = TechTreeWidget.computeLayout(catalog);
      expect(positions.length, 3);
      final posA = positions.firstWhere((p) => p.techId == 'a');
      final posB = positions.firstWhere((p) => p.techId == 'b');
      final posC = positions.firstWhere((p) => p.techId == 'c');
      expect(posA.x, lessThan(posB.x), reason: 'A must be left of B');
      expect(
        posB.x,
        lessThan(posC.x),
        reason: 'B must be left of C so B occupies column between A and C',
      );
    },
  );

  test(
    'Connector slot: edge A→C reserves row in middle layer so B is not on same row',
    () {
      // SPEC: when an edge spans columns (A→C), the layout reserves that row
      // in intermediate columns so the connector does not pass through other
      // nodes (e.g. B).
      TechDefinition def(String id, List<String> prereqs) => TechDefinition(
        id: id,
        era: 1,
        category: 'gathering',
        cost: 1,
        prerequisiteIds: prereqs,
        regimentUnlockIds: const [],
        shipUnlockIds: const [],
      );
      final catalog = <String, TechDefinition>{
        'a': def('a', const []),
        'b': def('b', const ['a']),
        'c': def('c', const ['a']),
      };
      final positions = TechTreeWidget.computeLayout(catalog);
      expect(positions.length, 3);
      final posB = positions.firstWhere((p) => p.techId == 'b');
      final posC = positions.firstWhere((p) => p.techId == 'c');
      const rowGap = 52.0;
      const baseY = 24.0;
      final rowB = ((posB.y - baseY) / rowGap).round();
      final rowC = ((posC.y - baseY) / rowGap).round();
      expect(
        rowB,
        isNot(equals(rowC)),
        reason:
            'B must not share row with C so A→C connector has its own slot '
            'in middle column',
      );
    },
  );
}

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_topology_identity_home.dart';

void main() {
  group('runCheckWorldTopologyIdentityHome', () {
    test('fails when naval.dart re-declares an identity helper', () {
      final temp = Directory.systemTemp.createTempSync('world-topo-id-naval-');
      try {
        final worldLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'lib', 'src', 'world'),
        )..createSync(recursive: true);
        File(p.join(worldLib.path, 'topology_identity.dart')).writeAsStringSync(
          'String? provinceTopologyNodeId() => null;\n'
          'Map<String, Map<String, Object>> indexTopologyNodesByRegion() => {};\n'
          'List<String> provinceIdsAdjacentToSeaZone() => [];\n'
          'String? regionIdForSeaZone() => null;\n',
        );
        File(p.join(worldLib.path, 'naval.dart')).writeAsStringSync(
          "export 'topology_identity.dart';\n"
          'String? provinceTopologyNodeId(Object a, Object b) => null;\n',
        );

        final errors = <String>[];
        final exitCode = runCheckWorldTopologyIdentityHome(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('naval.dart'));
        expect(errors.join('\n'), contains('provinceTopologyNodeId'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when helpers live only in topology_identity.dart', () {
      final temp = Directory.systemTemp.createTempSync('world-topo-id-ok-');
      try {
        final worldLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'lib', 'src', 'world'),
        )..createSync(recursive: true);
        File(p.join(worldLib.path, 'topology_identity.dart')).writeAsStringSync(
          'String? provinceTopologyNodeId() => null;\n'
          'Map<String, Map<String, Object>> indexTopologyNodesByRegion() => {};\n'
          'List<String> provinceIdsAdjacentToSeaZone() => [];\n'
          'String? regionIdForSeaZone() => null;\n',
        );
        File(p.join(worldLib.path, 'naval.dart')).writeAsStringSync(
          "export 'topology_identity.dart';\n"
          'void fleetHelper() {}\n',
        );

        final exitCode = runCheckWorldTopologyIdentityHome(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

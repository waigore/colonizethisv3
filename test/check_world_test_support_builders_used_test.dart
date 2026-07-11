import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_test_support_builders_used.dart';

void main() {
  group('runCheckWorldTestSupportBuildersUsed', () {
    test('fails when a required builder has no external call site', () {
      final temp = Directory.systemTemp.createTempSync('world-support-orphan-');
      try {
        final support = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_world',
            'test',
            'world_test_support',
          ),
        )..createSync(recursive: true);
        File(p.join(support.path, 'builders.dart')).writeAsStringSync(
          'Game spyRevealFogGame() => throw UnimplementedError();\n'
          'Game capitalLossGame() => throw UnimplementedError();\n'
          'Game gpCapitalReassignmentGame() => throw UnimplementedError();\n'
          'Game factionCapitalReassignmentGame() => throw UnimplementedError();\n'
          'Game ordersPhaseGame() => throw UnimplementedError();\n',
        );
        final worldTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'test', 'world'),
        )..createSync(recursive: true);
        // Only one builder used externally.
        File(p.join(worldTest.path, 'sample_test.dart')).writeAsStringSync(
          'void main() { capitalLossGame(); }\n',
        );

        final errors = <String>[];
        final exitCode = runCheckWorldTestSupportBuildersUsed(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('spyRevealFogGame'));
        expect(errors.join('\n'), contains('ordersPhaseGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when every required builder has an external call site', () {
      final temp = Directory.systemTemp.createTempSync('world-support-used-');
      try {
        final worldTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'test', 'world'),
        )..createSync(recursive: true);
        File(p.join(worldTest.path, 'sample_test.dart')).writeAsStringSync(
          'void main() {\n'
          '  spyRevealFogGame();\n'
          '  ownershipTransferVisibilityGame();\n'
          '  coastalSeaVisibilityGame();\n'
          '  capitalLossGame();\n'
          '  gpCapitalReassignmentGame();\n'
          '  factionCapitalReassignmentGame();\n'
          '  ordersPhaseGame();\n'
          '  topologyGraph();\n'
          '}\n',
        );

        final exitCode = runCheckWorldTestSupportBuildersUsed(
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

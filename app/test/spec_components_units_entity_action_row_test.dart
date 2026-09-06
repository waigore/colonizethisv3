// Static pins for SPEC/ui/components/units-entity-action-row.md (#2914 S9).
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/units-entity-action-row.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();
  group('SPEC/ui/components/units-entity-action-row.md (#2914 S9)', () {
    test('spec file exists and is non-empty', () {
      final file = File(_kSpecPath);
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync().trim(), isNotEmpty);
    });

    test('spec declares all canonical sections', () {
      final body = _readSpec();
      for (final heading in <String>[
        '## Purpose',
        '## Widget contract',
        '## Layout / wireframe',
        '## Behavior',
        '## Consumers',
        '## Acceptance criteria (Given–When–Then)',
        '## Tests',
        '## Related',
      ]) {
        expect(body, contains(heading));
      }
    });

    test('spec lists all three unit-panel consumers by stable screen ID', () {
      final body = _readSpec();
      for (final consumerId in <String>[
        'UNIT10001',
        'UNIT20001',
        'UNIT30001',
      ]) {
        expect(body, contains(consumerId));
      }
      for (final consumerSpecFile in <String>[
        'civilian-units-panel.md',
        'military-units-panel.md',
        'naval-units-panel.md',
      ]) {
        expect(body, contains(consumerSpecFile));
      }
    });

    test('spec encodes collapse breakpoints and dense mode contract', () {
      final body = _readSpec();
      expect(body, contains('iconOnlyBreakpoint'));
      expect(body, contains('280'));
      expect(body, contains('70 * actions.length'));
      expect(body, contains('dense'));
      expect(body, contains('UnitsPanelRowChrome'));
    });

    test('spec links to catalog atoms and tracking issue #2914', () {
      final body = _readSpec();
      expect(body, contains('pixel-art-ui-catalog.md'));
      expect(body, contains('#2914'));
    });

    test('spec is at most 1000 words', () {
      final body = _readSpec();
      final words = body
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
      expect(words.length <= 1000, isTrue);
    });
  });
}

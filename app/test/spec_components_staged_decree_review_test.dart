/// Pins SPEC/ui/components/staged-decree-review.md for DLG60001.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/staged-decree-review.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();

  group('SPEC/ui/components/staged-decree-review.md (#4469)', () {
    test('spec file exists and is non-empty', () {
      expect(File(_kSpecPath).existsSync(), isTrue);
      expect(_readSpec().trim(), isNotEmpty);
    });

    test('spec declares the canonical component-spec sections', () {
      final body = _readSpec();
      for (final heading in <String>[
        '## Purpose',
        '## Widget contract',
        '## Layout / wireframe',
        '## Behavior',
        '## Acceptance criteria',
        '## Tests',
        '## Related',
      ]) {
        expect(body, contains(heading));
      }
    });

    test('spec is consumed by DLG60001 and listed in the components index', () {
      expect(_readSpec(), contains('DLG60001'));
      expect(
        File(_kComponentsReadmePath).readAsStringSync(),
        contains('staged-decree-review.md'),
      );
    });

    test(
      'spec is at most 1000 words (colonizethis-spec-required.mdc § Layout)',
      () {
        final words = _readSpec()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty);
        expect(
          words.length,
          lessThanOrEqualTo(1000),
          reason:
              'colonizethis-spec-required.mdc § Layout. Current word count '
              'is ${words.length}.',
        );
      },
    );
  });
}

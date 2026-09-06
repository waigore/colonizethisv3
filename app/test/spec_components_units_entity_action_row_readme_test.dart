/// README index pin for units-entity-action-row component spec (Refs #2914 S9).
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

void main() {
  suppressLogsForTests();
  test(
    'components README index lists the UnitsEntityActionRow row',
    () {
      final readme = File(_kComponentsReadmePath);
      expect(readme.existsSync(), isTrue);
      final body = readme.readAsStringSync();
      expect(body, contains('SPEC/ui/components/'));
      expect(body, contains('UnitsEntityActionRow'));
      expect(body, contains('units-entity-action-row.md'));
    },
  );
}

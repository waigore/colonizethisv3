// README index guard for production-allocation-row component spec (Refs #4734 Slice G).
// Core spec sections: spec_components_production_allocation_row_test.dart.

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String kProductionAllocationRowSpecPath =
    '../SPEC/ui/components/production-allocation-row.md';
const String kProductionAllocationRowComponentsReadmePath =
    '../SPEC/ui/components/README.md';

void main() {
  suppressLogsForTests();

  test(
    'components README index lists the ProductionAllocationRow row '
    '(negative regression guard — README must continue to enumerate '
    'every composite spec under it)',
    () {
      final readme = File(kProductionAllocationRowComponentsReadmePath);
      expect(
        readme.existsSync(),
        isTrue,
        reason:
            'SPEC/ui/components/README.md must remain in place so '
            'authoring rules for new composite specs stay discoverable.',
      );
      final body = readme.readAsStringSync();
      expect(
        body,
        contains('SPEC/ui/components/'),
        reason:
            'README must continue to introduce the components/ '
            'directory.',
      );
      expect(
        body,
        contains('ProductionAllocationRow'),
        reason:
            'README index must enumerate ProductionAllocationRow so '
            'the composite is discoverable from the directory landing '
            'page (issue #2914 S9).',
      );
      expect(
        body,
        contains('production-allocation-row.md'),
        reason: 'README index row must link to the spec file path.',
      );
      expect(
        body,
        contains('GAME20001'),
        reason:
            'README index row for ProductionAllocationRow must '
            'reference the Production panel stable screen id '
            'GAME20001.',
      );
    },
  );
}

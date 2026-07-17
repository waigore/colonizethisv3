import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_diplomacy_no_list_relation_wrappers.dart';

void main() {
  group('findDiplomacyListRelationWrapperViolations', () {
    test('positive: clean source has no violations', () {
      expect(
        findDiplomacyListRelationWrapperViolations(
          relativePath:
              'packages/colonizethis_diplomacy/lib/src/diplomacy/war_resolver.dart',
          source: 'void f() {\n  relationsIndex.upsert(a, b, updater);\n}\n',
        ),
        isEmpty,
      );
    });

    test('negative: setWarStateForPair call is flagged', () {
      final v = findDiplomacyListRelationWrapperViolations(
        relativePath:
            'packages/colonizethis_diplomacy/lib/src/diplomacy/war_resolver.dart',
        source: 'void f() {\n  setWarStateForPair(relations: r);\n}\n',
      );
      expect(v, hasLength(1));
      expect(v.single, contains('setWarStateForPair('));
    });
  });

  group('runCheckDiplomacyNoListRelationWrappers', () {
    test('passes on current diplomacy lib tree', () {
      expect(runCheckDiplomacyNoListRelationWrappers('.'), 0);
    });

    test('fails when a forbidden wrapper appears under lib/', () {
      final temp =
          Directory.systemTemp.createTempSync('diplomacy-no-list-wrap-');
      try {
        final lib = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_diplomacy',
            'lib',
            'src',
          ),
        )..createSync(recursive: true);
        File(p.join(lib.path, 'bad.dart')).writeAsStringSync(
          'void f() { applyGrantAidModifier(relations: const []); }\n',
        );
        final errors = <String>[];
        final code = runCheckDiplomacyNoListRelationWrappers(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('applyGrantAidModifier('));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

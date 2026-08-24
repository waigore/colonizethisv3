import 'dart:io';

import 'package:colonizethis_test/test.dart';

void main() {
  group('wave 7 Slice D 250 ratchets (Refs #4626 AC8–AC10)', () {
    test('data lib and test checkers pin 250 with empty grandfather lists', () {
      final libChecker = File(
        '../../tool/check_data_lib_file_size.dart',
      ).readAsStringSync();
      final testChecker = File(
        '../../tool/check_data_test_file_size.dart',
      ).readAsStringSync();
      expect(libChecker.contains('dataLibFileSizeCeiling = 250'), isTrue);
      expect(testChecker.contains('dataTestFileSizeCeiling = 250'), isTrue);
      expect(
        libChecker.contains('dataFileSizeGrandfatheredForTests = <String>[]'),
        isTrue,
      );
      expect(
        testChecker.contains(
          'dataTestFileSizeGrandfatheredForTests = <String>[]',
        ),
        isTrue,
      );
    });
  });
}

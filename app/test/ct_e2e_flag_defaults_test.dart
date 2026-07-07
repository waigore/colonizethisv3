import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  test('CT_E2E defaults false for normal flutter test (widget CI)', () {
    expect(kCtE2EEnabled, isFalse);
  });
}

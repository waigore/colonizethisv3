import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('debug worker tier ids are canonical and lexicographically sorted', () {
    expect(
      debugConsoleSupportedWorkerTierIdsSorted,
      orderedEquals(<String>['apprentices', 'journeymen', 'masters', 'peasants']),
    );
    expect(debugConsoleSupportedWorkerTierIds, hasLength(4));
    expect(debugConsoleSupportedWorkerTierIds, contains('peasants'));
    expect(debugConsoleSupportedWorkerTierIds, contains('apprentices'));
    expect(debugConsoleSupportedWorkerTierIds, contains('journeymen'));
    expect(debugConsoleSupportedWorkerTierIds, contains('masters'));
  });
}

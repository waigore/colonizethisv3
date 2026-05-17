import 'package:test/test.dart';

import '../tool/check_logic_all_provinces_sanctioned_calls.dart';

void main() {
  group('logicSourceLineContainsAllProvincesCall', () {
    test('detects top-level allProvinces(', () {
      expect(
        logicSourceLineContainsAllProvincesCall(
          'for (final p in allProvinces(game.worldState)) {',
        ),
        isTrue,
      );
    });

    test('detects WorldState.allProvinces()', () {
      expect(
        logicSourceLineContainsAllProvincesCall(
          'for (final p in game.worldState.allProvinces()) {',
        ),
        isTrue,
      );
    });

    test('ignores province id substring', () {
      expect(
        logicSourceLineContainsAllProvincesCall(
          'final id = "oldWorld|all_provinces_ignored";',
        ),
        isFalse,
      );
    });
  });

  test('current repo passes allProvinces sanction gate', () {
    expect(runCheckLogicAllProvincesSanctionedCalls('.', info: (_) {}), 0);
  });
}

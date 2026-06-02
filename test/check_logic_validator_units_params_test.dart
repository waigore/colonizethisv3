import 'package:test/test.dart';

import '../tool/check_logic_validator_units_params.dart';

void main() {
  group('logicValidatorUnitsParamLineMatches', () {
    test('matches required named parameter terminated by comma', () {
      expect(
        logicValidatorUnitsParamLineMatches(
          '  required Map<String, Unit> unitsById,',
        ),
        isTrue,
      );
    });

    test('matches non-required positional parameter terminated by paren', () {
      expect(
        logicValidatorUnitsParamLineMatches('  Map<String, Unit> unitsById)'),
        isTrue,
      );
    });

    test('matches indented parameter declaration with extra whitespace', () {
      expect(
        logicValidatorUnitsParamLineMatches(
          '      Map<String,  Unit>  unitsById,',
        ),
        isTrue,
      );
    });

    test('ignores `final` class field declaration', () {
      expect(
        logicValidatorUnitsParamLineMatches(
          '  final Map<String, Unit> unitsById;',
        ),
        isFalse,
      );
    });

    test('ignores doc-comment reference', () {
      expect(
        logicValidatorUnitsParamLineMatches(
          '/// callers used to pass Map<String, Unit> unitsById directly.',
        ),
        isFalse,
      );
    });

    test('ignores line-comment reference', () {
      expect(
        logicValidatorUnitsParamLineMatches(
          '  // legacy: Map<String, Unit> unitsById, was a free-standing param.',
        ),
        isFalse,
      );
    });

    test('ignores unrelated identifier with same generic type', () {
      expect(
        logicValidatorUnitsParamLineMatches(
          '  Map<String, Unit> someOtherMap,',
        ),
        isFalse,
      );
    });

    test('ignores OrderResolutionContext threading line', () {
      expect(
        logicValidatorUnitsParamLineMatches(
          '  required OrderResolutionContext resolution,',
        ),
        isFalse,
      );
    });
  });

  test('current repo passes logic validator units-params gate', () {
    expect(runCheckLogicValidatorUnitsParams('.', info: (_) {}), 0);
  });
}

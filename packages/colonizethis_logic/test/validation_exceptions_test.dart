import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/logic_validation_exception.dart';
import 'package:colonizethis_logic/src/setup/setup_validation_exception.dart';
import 'package:colonizethis_world/src/world/capital_reassignment_fatal.dart';

void main() {
  group('CapitalReassignmentFatalError', () {
    test('toString without cause', () {
      final error = CapitalReassignmentFatalError('capital resolution failed');
      expect(
        error.toString(),
        'CapitalReassignmentFatalError: capital resolution failed',
      );
    });

    test('toString with cause', () {
      final error = CapitalReassignmentFatalError(
        'capital resolution failed',
        StateError('invalid state'),
      );
      expect(error.toString(), contains('(cause: Bad state: invalid state)'));
    });
  });

  group('SetupValidationException', () {
    test('default constructor stores message', () {
      final error = SetupValidationException('bad setup');
      expect(error, isA<ArgumentError>());
      expect(error.message, 'bad setup');
    });

    test('value constructor stores details', () {
      final error = SetupValidationException.value(42, 'population', 'invalid');
      expect(error.invalidValue, 42);
      expect(error.name, 'population');
      expect(error.message, 'invalid');
    });
  });

  group('LogicValidationException', () {
    test('default constructor stores message', () {
      final error = LogicValidationException('bad logic');
      expect(error, isA<ArgumentError>());
      expect(error.message, 'bad logic');
    });

    test('value constructor stores details', () {
      final error = LogicValidationException.value('x', 'field', 'invalid');
      expect(error.invalidValue, 'x');
      expect(error.name, 'field');
      expect(error.message, 'invalid');
    });
  });
}

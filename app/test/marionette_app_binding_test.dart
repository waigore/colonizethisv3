import 'package:colonizethis_app/config/marionette_app_binding.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('marionetteBindingEnabled', () {
    test('enabled only in debug non-test non-e2e runs', () {
      expect(
        marionetteBindingEnabled(
          debugMode: true,
          flutterTest: false,
          ctE2eEnabled: false,
        ),
        isTrue,
      );
    });

    test('disabled under flutter test', () {
      expect(
        marionetteBindingEnabled(
          debugMode: true,
          flutterTest: true,
          ctE2eEnabled: false,
        ),
        isFalse,
      );
    });

    test('disabled under CT_E2E', () {
      expect(
        marionetteBindingEnabled(
          debugMode: true,
          flutterTest: false,
          ctE2eEnabled: true,
        ),
        isFalse,
      );
    });

    test('disabled in release', () {
      expect(
        marionetteBindingEnabled(
          debugMode: false,
          flutterTest: false,
          ctE2eEnabled: false,
        ),
        isFalse,
      );
    });
  });
}

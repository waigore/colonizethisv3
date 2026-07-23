import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app/widgets/main_menu_body.dart';
import 'package:colonizethis_app/widgets/main_menu_constants.dart';
import 'package:colonizethis_app/widgets/main_menu_types.dart';

/// De-parted main-menu library seam checks (Refs #4117).
void main() {
  suppressLogsForTests();

  group('MainMenu modular split (Refs #4117)', () {
    test('types, constants, and body widget are importable', () {
      expect(MainMenuVariant.pixelArt, isNotNull);
      expect(MainMenuState.default_, isNotNull);
      expect(kMainMenuNarrowBreakpoint, isNotNull);
      expect(MainMenuBody, isNotNull);
      expect(CtMainMenu.screenId, isNotEmpty);
    });
  });
}

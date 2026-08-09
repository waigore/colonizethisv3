import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_navigation.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_unit_panels.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_units_panel_sheet.dart';

/// De-parted [AppEventHandler] library seam checks (Refs #4117).
void main() {
  suppressLogsForTests();

  group('AppEventHandler modular split (Refs #4117)', () {
    test('state bag and implementation libraries are importable', () {
      expect(AppEventHandlerState, isNotNull);
      expect(appEventHandlerOpenDialog, isNotNull);
      expect(appEventHandlerNavigateToShell, isNotNull);
      expect(appEventHandlerShowUnitsPanelSheet, isNotNull);
      expect(appEventHandlerOpenCivilianUnitsPanel, isNotNull);
    });

    test('DialogBuilder typedef remains exported from app_event_handler.dart', () {
      expect(DialogBuilder, isNotNull);
      expect(NavigatorKeyDialogBuilder, isNotNull);
    });
  });
}

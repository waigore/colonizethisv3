import 'package:colonizethis_app/config/app_display_strings.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('debug-aware display formatting', () {
    test('suffix constants are stable', () {
      expect(kAppVersion, 'v0.0.1');
      expect(kDebugDisplaySuffix, ' (debug)');
    });

    test('does not append suffix when debug mode is off', () {
      expect(
        formatDebugAwareTitle('Colonize This', debugConsoleEnabled: false),
        'Colonize This',
      );
      expect(
        formatDebugAwareVersion('v0.0.1', debugConsoleEnabled: false),
        'v0.0.1',
      );
      expect(appDisplayVersion(debugConsoleEnabled: false), 'v0.0.1');
    });

    test('appends suffix when debug mode is on', () {
      expect(
        formatDebugAwareTitle('Colonize This', debugConsoleEnabled: true),
        'Colonize This (debug)',
      );
      expect(
        formatDebugAwareVersion('v0.0.1', debugConsoleEnabled: true),
        'v0.0.1 (debug)',
      );
      expect(appDisplayVersion(debugConsoleEnabled: true), 'v0.0.1 (debug)');
    });

    test('keeps suffix terminal without duplicating it', () {
      expect(
        formatDebugAwareTitle(
          'Colonize This (debug)',
          debugConsoleEnabled: true,
        ),
        'Colonize This (debug)',
      );
      expect(
        formatDebugAwareVersion('v0.0.1 (debug)', debugConsoleEnabled: true),
        'v0.0.1 (debug)',
      );
    });
  });
}

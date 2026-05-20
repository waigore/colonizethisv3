import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/game_service.dart';

/// #2575 work item 12 — [GameService] library split sanity checks.
void main() {
  suppressLogsForTests();

  group('GameService modular split (Refs #2575)', () {
    test('newGameSetupProgressStepCount remains on GameService', () {
      expect(GameService.newGameSetupProgressStepCount, 5);
    });
  });
}

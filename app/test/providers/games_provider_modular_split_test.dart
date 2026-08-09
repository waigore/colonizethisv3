import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/games_provider.dart';

/// De-parted games-provider library seam checks (Refs #4117).
void main() {
  suppressLogsForTests();

  group('GamesProvider modular split (Refs #4117)', () {
    test('barrel and submodule providers are importable', () {
      expect(currentGameProvider, isNotNull);
      expect(currentOrdersProvider, isNotNull);
      expect(pendingDiplomacyProvider, isNotNull);
      expect(availableWorkTargetIdsForUnitProvider, isNotNull);
      expect(devExclusiveReservedWorkTileKeysProvider, isNotNull);
      expect(gameListIdsProvider, isNotNull);
      expect(mainMenuAutoSaveAvailableProvider, isNotNull);
      expect(gameIdsWithIntroShownProvider, isNotNull);
      expect(tribeFirstContactHeraldsShownProvider, isNotNull);
      expect(tribeFirstContactHeraldQueueProvider, isNotNull);
    });
  });
}

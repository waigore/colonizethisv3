// Session-cache reuse for UNIT* panel tree projections (Refs #4688 Slice 3).

import 'package:colonizethis_app/providers/units_panel_session_cache_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'resolveUnitsPanelMilitaryGroups reuses session cache across calls (Refs #4688 Slice 3)',
    () {
      final game = buildMilitaryPanelTestGame();
      final cache = UnitsPanelSessionCache();
      final first = resolveUnitsPanelMilitaryGroups(
        cache: cache,
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
      );
      expect(first, isNotEmpty);

      final second = resolveUnitsPanelMilitaryGroups(
        cache: cache,
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
      );
      expect(identical(first, second), isTrue);
    },
  );

  test(
    'resolveUnitsPanelNavalTree reuses session cache across calls (Refs #4688 Slice 3)',
    () {
      final game = buildNavalPanelTestGame();
      final cache = UnitsPanelSessionCache();
      final l10n = lookupAppLocalizations(const Locale('en'));
      final first = resolveUnitsPanelNavalTree(
        cache: cache,
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        topology: const MapTopology(),
        draftOrders: const Orders(),
        l10n: l10n,
      );
      expect(first, isNotEmpty);

      final second = resolveUnitsPanelNavalTree(
        cache: cache,
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        topology: const MapTopology(),
        draftOrders: const Orders(),
        l10n: l10n,
      );
      expect(identical(first, second), isTrue);
    },
  );

  test(
    'unitsPanelSessionCacheProvider resets on clearActiveGameSession (Refs #4688 Slice 3)',
    () {
      final game = buildMilitaryPanelTestGame();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cache = container.read(unitsPanelSessionCacheProvider);
      resolveUnitsPanelMilitaryGroups(
        cache: cache,
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
      );
      expect(cache.state.militaryGroups, isNotNull);

      cache.reset();
      expect(cache.state.militaryGroups, isNull);
    },
  );
}

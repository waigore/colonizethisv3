// Session-cache reuse for Counsel panel tab projections (Refs #4688 Slice 8).

import 'package:colonizethis_app/providers/counsel_panel_session_cache_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'resolveCounselIndustryRecommendations reuses session cache on same revision (Refs #4688 Slice 8)',
    () {
      final game = buildMilitaryPanelTestGame();
      const topology = MapTopology();
      const orders = Orders();
      const desiredOutput = <String, int>{};
      final revision = counselPanelSessionRevision(
        game: game,
        orders: orders,
        desiredOutputByRecipe: desiredOutput,
        topology: topology,
      );
      final cache = CounselPanelSessionCache();

      final first = resolveCounselIndustryRecommendations(
        cache: cache,
        revision: revision,
        game: game,
        playerId: kPanelTestHumanPlayerId,
        currentOrders: orders,
        topology: topology,
        tileMapByRegion: const {},
      );
      final second = resolveCounselIndustryRecommendations(
        cache: cache,
        revision: revision,
        game: game,
        playerId: kPanelTestHumanPlayerId,
        currentOrders: orders,
        topology: topology,
        tileMapByRegion: const {},
      );
      expect(identical(first, second), isTrue);
    },
  );

  test(
    'CounselPanelSessionCache.reset drops cached tab projections (Refs #4688 Slice 8)',
    () {
      final game = buildMilitaryPanelTestGame();
      const topology = MapTopology();
      const orders = Orders();
      final cache = CounselPanelSessionCache();
      final revision = counselPanelSessionRevision(
        game: game,
        orders: orders,
        desiredOutputByRecipe: const {},
        topology: topology,
      );

      resolveCounselIndustryRecommendations(
        cache: cache,
        revision: revision,
        game: game,
        playerId: kPanelTestHumanPlayerId,
        currentOrders: orders,
        topology: topology,
        tileMapByRegion: const {},
      );
      expect(cache.state.industry, isNotNull);

      cache.reset();
      expect(cache.state.industry, isNull);
      expect(cache.state.industryRevision, isNull);
    },
  );
}

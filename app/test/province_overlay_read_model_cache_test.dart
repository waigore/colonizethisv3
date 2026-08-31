// Session-cache reuse for MAP20001 province-wide read model (Refs #4690 Slice B).

import 'package:colonizethis_app/providers/province_overlay_read_model_cache_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';

void main() {
  suppressLogsForTests();

  const displayId = provinceDetailSupportProvinceId;

  test(
    'resolveProvinceOverlayProvinceReadModel reuses same object identity (Refs #4690 AC2)',
    () {
      final cache = ProvinceOverlaySessionCache();
      final game = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
      final mapData = provinceDetailMapDataForProjection();

      final first = resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: game,
        displayId: displayId,
        mapData: mapData,
      );
      final second = resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: game,
        displayId: displayId,
        mapData: mapData,
      );

      expect(identical(first, second), isTrue);
      expect(first.extractionSnapshot, isNotNull);
    },
  );

  test(
    'resolveProvinceOverlayHumanConnectivity reuses session cache (Refs #4690 Slice B)',
    () {
      final cache = ProvinceOverlaySessionCache();
      final game = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
      final mapData = provinceDetailMapDataForProjection();

      final first = resolveProvinceOverlayHumanConnectivity(
        cache: cache,
        game: game,
        humanPlayerId: provinceDetailSupportPlayerId,
        mapData: mapData,
      );
      final second = resolveProvinceOverlayHumanConnectivity(
        cache: cache,
        game: game,
        humanPlayerId: provinceDetailSupportPlayerId,
        mapData: mapData,
      );

      expect(identical(first, second), isTrue);
    },
  );

  test(
    'ProvinceOverlaySessionCache clears province entries on turn advance (Refs #4690 AC2)',
    () {
      final cache = ProvinceOverlaySessionCache();
      final mapData = provinceDetailMapDataForProjection();
      final turnOne = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
      final turnTwo = turnOne.copyWith(
        worldState: turnOne.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
        ),
      );

      final turnOneRead = resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: turnOne,
        displayId: displayId,
        mapData: mapData,
      );
      final turnTwoRead = resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: turnTwo,
        displayId: displayId,
        mapData: mapData,
      );

      expect(identical(turnOneRead, turnTwoRead), isFalse);
    },
  );

  test(
    'ProvinceOverlaySessionCache.reset drops cached province read models (Refs #4690 AC6)',
    () {
      final cache = ProvinceOverlaySessionCache();
      final game = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
      final mapData = provinceDetailMapDataForProjection();

      resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: game,
        displayId: displayId,
        mapData: mapData,
      );
      expect(cache.state.provinceReadModelsByDisplayId, isNotEmpty);

      cache.reset();
      expect(cache.state.provinceReadModelsByDisplayId, isEmpty);
      expect(cache.state.humanConnectivity, isNull);
    },
  );
}

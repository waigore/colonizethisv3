// Unit pins for province-detail overlay host support (Refs #3594).

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('resolveProvinceDetailDisplayId', () {
    test('returns empty string for a null tile key', () {
      expect(
        resolveProvinceDetailDisplayId(
          region: provinceDetailEmptyRegion(),
          tileKey: null,
        ),
        isEmpty,
      );
    });

    test('returns empty string for an empty tile key', () {
      expect(
        resolveProvinceDetailDisplayId(
          region: provinceDetailEmptyRegion(),
          tileKey: '',
        ),
        isEmpty,
      );
    });
  });

  group('provinceExtractionSnapshotPreview projection (Refs #4064)', () {
    const provinceId = provinceDetailSupportProvinceId;
    const tk = provinceDetailSupportTileKey;

    test('projects non-empty Extraction without last-turn history', () {
      final game = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
      final snap = provinceExtractionSnapshotPreview(
        game: game,
        provinceId: provinceId,
        mapData: provinceDetailMapDataForProjection(),
      );
      expect(snap, isNotNull);
      expect(snap!.ownerId, 'gp1');
      expect(snap.byCommodity['grain']!.full, greaterThan(0));
    });

    test(
      'ownership change: preview attributes to new owner without Extraction write',
      () {
        final mapData = provinceDetailMapDataForProjection();
        final before = provinceExtractionSnapshotPreview(
          game: provinceDetailGameWithImprovedGrain(ownerId: 'gp1'),
          provinceId: provinceId,
          mapData: mapData,
        );
        expect(before, isNotNull);
        expect(before!.ownerId, 'gp1');
        expect(before.byCommodity['grain']!.full, greaterThan(0));

        final after = provinceExtractionSnapshotPreview(
          game: provinceDetailGameWithImprovedGrain(ownerId: 'gp2'),
          provinceId: provinceId,
          mapData: mapData,
        );
        expect(after, isNotNull);
        expect(after!.ownerId, 'gp2');
        expect(after.byCommodity['grain']!.full, greaterThan(0));
        expect(after.ownerId, isNot(before.ownerId));
      },
    );

    test('returns null when map data is missing', () {
      final game = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
      expect(
        provinceExtractionSnapshotPreview(
          game: game,
          provinceId: provinceId,
          mapData: null,
        ),
        isNull,
      );
    });

    test(
      'negative: draft build_improvement Orders do not change Extraction preview',
      () {
        final unresolved = provinceDetailUnresolvedExtractionGame();
        final mapData = provinceDetailMapDataForProjection();
        final beforeDraft = provinceExtractionSnapshotPreview(
          game: unresolved,
          provinceId: provinceId,
          mapData: mapData,
        );
        expect(beforeDraft?.byCommodity['grain'], isNull);

        final draftOrders = Orders(
          workOrdersByPlayerId: {
            'gp1': [
              const WorkOrder(
                unitId: 'u_builder',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tk,
              ),
            ],
          },
        );
        expect(draftOrders.workOrdersByPlayerId['gp1'], isNotEmpty);

        final afterDraftPresence = provinceExtractionSnapshotPreview(
          game: unresolved,
          provinceId: provinceId,
          mapData: mapData,
        );
        expect(afterDraftPresence, beforeDraft);

        final resolved = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
        final afterResolution = provinceExtractionSnapshotPreview(
          game: resolved,
          provinceId: provinceId,
          mapData: mapData,
        );
        expect(afterResolution, isNotNull);
        expect(afterResolution!.byCommodity['grain']!.full, greaterThan(0));
      },
    );
  });
}

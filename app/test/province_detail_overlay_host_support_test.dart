// Unit pins for the shared province-detail overlay host support extracted in
// Refs #3594 (work item 7 — resolve flame-host ↔ widget duplication/coupling).
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

  group('buildProvinceDetailShortcutCallbacks gating', () {
    late AppEventBus bus;

    setUp(() {
      bus = AppEventBus.create();
    });

    tearDown(() {
      bus.dispose();
    });

    test('returns all-null callbacks when no tile is selected', () {
      final callbacks = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: null,
        exploreEnabled: true,
        prospectEnabled: true,
        buildImprovementEnabled: true,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: true,
        bus: bus,
      );

      expect(callbacks.onExploreWithExplorerTap, isNull);
      expect(callbacks.onProspectWithExplorerTap, isNull);
      expect(callbacks.onBuildImprovementTap, isNull);
      expect(callbacks.onBuildRoadTap, isNull);
      expect(callbacks.onPurchaseLandTap, isNull);
    });

    test('returns all-null callbacks when every action is disabled', () {
      final callbacks = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );

      expect(callbacks.onExploreWithExplorerTap, isNull);
      expect(callbacks.onProspectWithExplorerTap, isNull);
      expect(callbacks.onBuildImprovementTap, isNull);
      expect(callbacks.onBuildRoadTap, isNull);
      expect(callbacks.onPurchaseLandTap, isNull);
    });

    test('exposes only the enabled action callback (per-action gating)', () {
      final exploreOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: true,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(exploreOnly.onExploreWithExplorerTap, isNotNull);
      expect(exploreOnly.onProspectWithExplorerTap, isNull);
      expect(exploreOnly.onBuildImprovementTap, isNull);
      expect(exploreOnly.onBuildRoadTap, isNull);
      expect(exploreOnly.onPurchaseLandTap, isNull);

      final prospectOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: true,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(prospectOnly.onExploreWithExplorerTap, isNull);
      expect(prospectOnly.onProspectWithExplorerTap, isNotNull);
      expect(prospectOnly.onBuildImprovementTap, isNull);
      expect(prospectOnly.onBuildRoadTap, isNull);
      expect(prospectOnly.onPurchaseLandTap, isNull);

      final buildOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: true,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(buildOnly.onExploreWithExplorerTap, isNull);
      expect(buildOnly.onProspectWithExplorerTap, isNull);
      expect(buildOnly.onBuildImprovementTap, isNotNull);
      expect(buildOnly.onBuildRoadTap, isNull);
      expect(buildOnly.onPurchaseLandTap, isNull);

      final buildRoadOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: true,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(buildRoadOnly.onExploreWithExplorerTap, isNull);
      expect(buildRoadOnly.onProspectWithExplorerTap, isNull);
      expect(buildRoadOnly.onBuildImprovementTap, isNull);
      expect(buildRoadOnly.onBuildRoadTap, isNotNull);
      expect(buildRoadOnly.onPurchaseLandTap, isNull);

      final purchaseLandOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: true,
        bus: bus,
      );
      expect(purchaseLandOnly.onExploreWithExplorerTap, isNull);
      expect(purchaseLandOnly.onProspectWithExplorerTap, isNull);
      expect(purchaseLandOnly.onBuildImprovementTap, isNull);
      expect(purchaseLandOnly.onBuildRoadTap, isNull);
      expect(purchaseLandOnly.onPurchaseLandTap, isNotNull);
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
      'negative: draft build_improvement Orders do not change Extraction '
      'preview (world tile state only)',
      () {
        // Host preview has no draftOrders parameter; staged WorkOrders must not
        // invent yields until turn resolution updates Game.tileState.
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

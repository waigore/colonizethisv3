// Unit pins for the shared province-detail overlay host support extracted in
// Refs #3594 (work item 7 — resolve flame-host ↔ widget duplication/coupling).
//
// The wide side panel (`GameMapProvinceDetailSidePanel`) and the narrow
// bottom-sheet slot (`GameMapNarrowDetailOverlaySlot`) previously duplicated
// the `displayId` resolution and the explore/prospect/build-improvement
// shortcut callback gating verbatim. These pins assert the extracted helper
// keeps the same gating contract (null tile key → no callbacks; disabled
// actions → null callback; enabled action → non-null callback). The full
// runtime tap/emit behavior remains pinned by the host-level tests
// (`province_*_shortcut_host_emit_event_test.dart`).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kPlayerId = 'gp1';
const String _kTileKey = 'oldWorld|p1|0|0';

Game _minimalGame() => Game(
      id: 'g_support',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [], units: []),
        newWorld: RegionData(provinces: [], units: []),
      ),
      players: const [
        Player(
          id: _kPlayerId,
          displayName: 'Human',
          isHuman: true,
          capitalProvinceId: '',
        ),
      ],
      minorNations: const [],
      tribes: const [],
    );

RegionMapViewData _emptyRegion() => const RegionMapViewData(
      regionId: 'oldWorld',
      width: 1,
      height: 1,
      cellSize: 16,
      cells: [],
      capitalMarkers: [],
      portMarkers: [],
      factionColors: {},
      greatPowerFactionIds: {},
      terrainColors: {},
      provincePoliticalOwnerByPrefixedProvinceId: {},
    );

PlayerView _playerView(Game game) =>
    buildPlayerView(game, const MapTopology(nodes: [], edges: []), _kPlayerId);

ProvinceDetailShortcutCallbacks _callbacks({
  required Game game,
  required String? selectedTileKey,
  required bool exploreEnabled,
  required bool prospectEnabled,
  required bool buildImprovementEnabled,
  required AppEventBus bus,
}) =>
    buildProvinceDetailShortcutCallbacks(
      game: game,
      humanPlayerId: _kPlayerId,
      region: _emptyRegion(),
      playerView: _playerView(game),
      workTargetSelectionCache:
          PerPlayerWorkTargetSelectionCache(strategies: const {}),
      draftOrders: const Orders(),
      mapData: null,
      selectedTileKey: selectedTileKey,
      exploreEnabled: exploreEnabled,
      prospectEnabled: prospectEnabled,
      buildImprovementEnabled: buildImprovementEnabled,
      bus: bus,
    );

void main() {
  suppressLogsForTests();

  group('resolveProvinceDetailDisplayId', () {
    test('returns empty string for a null tile key', () {
      expect(
        resolveProvinceDetailDisplayId(region: _emptyRegion(), tileKey: null),
        isEmpty,
      );
    });

    test('returns empty string for an empty tile key', () {
      expect(
        resolveProvinceDetailDisplayId(region: _emptyRegion(), tileKey: ''),
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
      final callbacks = _callbacks(
        game: _minimalGame(),
        selectedTileKey: null,
        exploreEnabled: true,
        prospectEnabled: true,
        buildImprovementEnabled: true,
        bus: bus,
      );

      expect(callbacks.onExploreWithExplorerTap, isNull);
      expect(callbacks.onProspectWithExplorerTap, isNull);
      expect(callbacks.onBuildImprovementTap, isNull);
    });

    test('returns all-null callbacks when every action is disabled', () {
      final callbacks = _callbacks(
        game: _minimalGame(),
        selectedTileKey: _kTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        bus: bus,
      );

      expect(callbacks.onExploreWithExplorerTap, isNull);
      expect(callbacks.onProspectWithExplorerTap, isNull);
      expect(callbacks.onBuildImprovementTap, isNull);
    });

    test('exposes only the enabled action callback (per-action gating)', () {
      final exploreOnly = _callbacks(
        game: _minimalGame(),
        selectedTileKey: _kTileKey,
        exploreEnabled: true,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        bus: bus,
      );
      expect(exploreOnly.onExploreWithExplorerTap, isNotNull);
      expect(exploreOnly.onProspectWithExplorerTap, isNull);
      expect(exploreOnly.onBuildImprovementTap, isNull);

      final prospectOnly = _callbacks(
        game: _minimalGame(),
        selectedTileKey: _kTileKey,
        exploreEnabled: false,
        prospectEnabled: true,
        buildImprovementEnabled: false,
        bus: bus,
      );
      expect(prospectOnly.onExploreWithExplorerTap, isNull);
      expect(prospectOnly.onProspectWithExplorerTap, isNotNull);
      expect(prospectOnly.onBuildImprovementTap, isNull);

      final buildOnly = _callbacks(
        game: _minimalGame(),
        selectedTileKey: _kTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: true,
        bus: bus,
      );
      expect(buildOnly.onExploreWithExplorerTap, isNull);
      expect(buildOnly.onProspectWithExplorerTap, isNull);
      expect(buildOnly.onBuildImprovementTap, isNotNull);
    });
  });

  group('provinceExtractionSnapshotPreview projection (Refs #4064)', () {
    const provinceId = 'oldWorld|p1';
    const tk = 'oldWorld|p1|0|0';

    Game gameWithImprovedGrain({required String ownerId}) {
      return Game(
        id: 'g_extraction_preview',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: 'oldWorld',
                ownerId: ownerId,
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: TileMapState().setImprovement(tk, 2).setRoadLevel(tk, 4),
          resourceByTileKey: const {tk: 'grain'},
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p1': [tk],
            },
          },
        ),
        players: [
          Player(
            id: ownerId,
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: provinceId,
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
            techUnlocked: const {kTechIdMoldboardPlow: true},
          ),
        ],
      );
    }

    GameMapData mapDataForProjection() {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['p1'],
        ],
        resourceGrid: const [
          [Resource.grain],
        ],
      );
      return (
        combinedTopology: const MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        ),
        tileMapByRegion: {'oldWorld': tileMap},
        topologyByRegion: const <String, MapTopology>{},
        warpLinks: null,
      );
    }

    test('projects non-empty Extraction without last-turn history', () {
      final game = gameWithImprovedGrain(ownerId: 'gp1');
      final snap = provinceExtractionSnapshotPreview(
        game: game,
        provinceId: provinceId,
        mapData: mapDataForProjection(),
      );
      expect(snap, isNotNull);
      expect(snap!.ownerId, 'gp1');
      expect(snap.byCommodity['grain']!.full, greaterThan(0));
    });

    test('returns null when map data is missing', () {
      final game = gameWithImprovedGrain(ownerId: 'gp1');
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
        final unresolved = Game(
          id: 'g_extraction_draft_ignore',
          capitalTileGrainBonusPerTurn: 0,
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: provinceId,
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                  townDevelopmentLevel: 4,
                ),
              ],
            ),
            newWorld: const RegionData(),
            // No improvement yet — draft build_improvement would raise this.
            tileState: const TileMapState(),
            resourceByTileKey: const {tk: 'grain'},
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|p1': [tk],
              },
            },
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP',
              isHuman: true,
              capitalProvinceId: provinceId,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
              techUnlocked: const {kTechIdMoldboardPlow: true},
            ),
          ],
        );
        final mapData = mapDataForProjection();
        final beforeDraft = provinceExtractionSnapshotPreview(
          game: unresolved,
          provinceId: provinceId,
          mapData: mapData,
        );
        expect(beforeDraft?.byCommodity['grain'], isNull);

        // Local draft Orders exist mid-turn but are never passed into preview.
        final draftOrders = Orders(
          workOrdersByPlayerId: {
            'gp1': [
              const WorkOrder(
                unitId: 'u_builder',
                target: 'build_improvement',
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

        final resolved = gameWithImprovedGrain(ownerId: 'gp1');
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

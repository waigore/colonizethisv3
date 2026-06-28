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

import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_detail_overlay_host_support.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
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
}

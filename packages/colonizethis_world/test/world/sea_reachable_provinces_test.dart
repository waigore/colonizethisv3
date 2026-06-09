import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/sea_reachable_provinces.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Sea-reachability BFS in `lib/src/world/sea_reachable_provinces.dart`.
/// SPEC/ai/ai-architecture.md § Colonial expansion and SPEC/program/
/// order-suggestions.md § COLONIAL phase planner (Refs #2509).
TopologyNode _prov(String id, {String regionId = 'oldWorld'}) =>
    TopologyNode(id: id, regionId: regionId, type: TopologyNodeType.province);

TopologyNode _sea(String id, {String regionId = 'oldWorld'}) =>
    TopologyNode(id: id, regionId: regionId, type: TopologyNodeType.seaZone);

PlayerView _viewOwning(Map<String, String?> ownersByProvinceId) {
  final provincesById = <String, Province>{
    for (final entry in ownersByProvinceId.entries)
      entry.key: Province(
        id: entry.key,
        regionId: ProvinceId.regionIdFrom(entry.key),
        ownerId: entry.value,
      ),
  };
  return PlayerView(
    playerId: 'p1',
    player: const Player(id: 'p1', displayName: 'P1', isHuman: true),
    ownUnitsById: const {},
    provincesById: provincesById,
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

void main() {
  group('reachableNonOwnedProvinceIdsViaSeas', () {
    test('reaches a foreign province across a sea zone from an owned anchor', () {
      final topology = MapTopology(
        nodes: [
          _prov('oldWorld|own'),
          _sea('oldWorld|sea'),
          _prov('oldWorld|enemy'),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|sea'),
          TopologyEdge(id1: 'oldWorld|sea', id2: 'oldWorld|enemy'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'oldWorld|enemy': 'p2',
      });

      final result = reachableNonOwnedProvinceIdsViaSeas(
        topology,
        {'oldWorld|own'},
        view,
      );
      expect(result, {'oldWorld|enemy'});
    });

    test('ignores anchors the player does not actually own', () {
      final topology = MapTopology(
        nodes: [_prov('oldWorld|own'), _prov('oldWorld|enemy')],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|enemy'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p2',
        'oldWorld|enemy': 'p3',
      });

      final result = reachableNonOwnedProvinceIdsViaSeas(
        topology,
        {'oldWorld|own'},
        view,
      );
      expect(result, isEmpty);
    });

    test('does not expand through a foreign province', () {
      final topology = MapTopology(
        nodes: [
          _prov('oldWorld|own'),
          _prov('oldWorld|enemy'),
          _prov('oldWorld|beyond'),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|enemy'),
          TopologyEdge(id1: 'oldWorld|enemy', id2: 'oldWorld|beyond'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'oldWorld|enemy': 'p2',
        'oldWorld|beyond': 'p3',
      });

      final result = reachableNonOwnedProvinceIdsViaSeas(
        topology,
        {'oldWorld|own'},
        view,
      );
      expect(result, {'oldWorld|enemy'});
    });

    test('skips unowned (ownerless) provinces', () {
      final topology = MapTopology(
        nodes: [_prov('oldWorld|own'), _prov('oldWorld|wild')],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|wild'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'oldWorld|wild': null,
      });

      final result = reachableNonOwnedProvinceIdsViaSeas(
        topology,
        {'oldWorld|own'},
        view,
      );
      expect(result, isEmpty);
    });

    test('regionIdFilter restricts collected foreign provinces', () {
      final topology = MapTopology(
        nodes: [
          _prov('oldWorld|own'),
          _sea('oldWorld|sea'),
          _prov('newWorld|colony', regionId: 'newWorld'),
          _prov('oldWorld|enemy'),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|sea'),
          TopologyEdge(id1: 'oldWorld|sea', id2: 'newWorld|colony'),
          TopologyEdge(id1: 'oldWorld|sea', id2: 'oldWorld|enemy'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'newWorld|colony': 'p2',
        'oldWorld|enemy': 'p2',
      });

      final result = reachableNonOwnedProvinceIdsViaSeas(
        topology,
        {'oldWorld|own'},
        view,
        regionIdFilter: 'newWorld',
      );
      expect(result, {'newWorld|colony'});
    });
  });

  group('reachableNonOwnedProvinceDistancesViaSeas', () {
    test('a direct province-province border foreign province has distance 1', () {
      final topology = MapTopology(
        nodes: [_prov('oldWorld|own'), _prov('oldWorld|enemy')],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|enemy'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'oldWorld|enemy': 'p2',
      });

      final result = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|own'},
        view,
      );
      expect(result, {'oldWorld|enemy': 1});
    });

    test('counts each traversed edge, sea zone included', () {
      final topology = MapTopology(
        nodes: [
          _prov('oldWorld|own'),
          _sea('oldWorld|sea'),
          _prov('oldWorld|enemy'),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|sea'),
          TopologyEdge(id1: 'oldWorld|sea', id2: 'oldWorld|enemy'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'oldWorld|enemy': 'p2',
      });

      final result = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|own'},
        view,
      );
      expect(result, {'oldWorld|enemy': 2});
    });

    test('keeps the shortest distance when multiple paths exist', () {
      // enemy reachable directly (1) and via a sea detour (3).
      final topology = MapTopology(
        nodes: [
          _prov('oldWorld|own'),
          _prov('oldWorld|enemy'),
          _sea('oldWorld|sea'),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|enemy'),
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|sea'),
          TopologyEdge(id1: 'oldWorld|sea', id2: 'oldWorld|enemy'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'oldWorld|enemy': 'p2',
      });

      final result = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|own'},
        view,
      );
      expect(result['oldWorld|enemy'], 1);
    });

    test('regionIdFilter restricts the distance map entries', () {
      final topology = MapTopology(
        nodes: [
          _prov('oldWorld|own'),
          _sea('oldWorld|sea'),
          _prov('newWorld|colony', regionId: 'newWorld'),
          _prov('oldWorld|enemy'),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|sea'),
          TopologyEdge(id1: 'oldWorld|sea', id2: 'newWorld|colony'),
          TopologyEdge(id1: 'oldWorld|sea', id2: 'oldWorld|enemy'),
        ],
      );
      final view = _viewOwning(const {
        'oldWorld|own': 'p1',
        'newWorld|colony': 'p2',
        'oldWorld|enemy': 'p2',
      });

      final result = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|own'},
        view,
        regionIdFilter: 'newWorld',
      );
      expect(result.keys, ['newWorld|colony']);
    });
  });
}

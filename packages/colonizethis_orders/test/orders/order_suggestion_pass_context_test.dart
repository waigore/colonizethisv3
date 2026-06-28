import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_pass_context.dart';
import 'package:colonizethis_world/src/world/player_view.dart';

void main() {
  const topology = MapTopology(nodes: [], edges: []);

  group('order_suggestion_pass_context helpers (Refs #3500 Phase 2)', () {
    test('indexExistingTargetsByEntityId skips empty targets when requested', () {
      final indexed = indexExistingTargetsByEntityId(
        const [
          NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: 'seaA',
          ),
          NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: '',
          ),
        ],
        (o) => o.fleetId,
        (o) => o.destinationSeaZoneId ?? '',
        skipEmptyTargets: true,
      );
      expect(indexed['f1'], {'seaA'});
    });

    test('emitAcceptedCandidates collects accepted in iteration order', () {
      final into = <NavalMoveOrder>[];
      emitAcceptedCandidates<NavalMoveOrder>(
        candidates: const [
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaB'),
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaC'),
        ],
        // Reject only seaC so we cover both accept and reject branches.
        accept: (o) => o.destinationSeaZoneId != 'seaC',
        into: into,
      );
      expect(
        into.map((o) => o.destinationSeaZoneId).toList(),
        ['seaB', 'seaA'],
        reason: 'preserves candidate order and performs no sorting',
      );
    });

    test('emitAcceptedCandidates skips candidates already targeted', () {
      final into = <NavalMoveOrder>[];
      emitAcceptedCandidates<NavalMoveOrder>(
        candidates: const [
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaB'),
          NavalMoveOrder(fleetId: 'f2', destinationSeaZoneId: 'seaA'),
        ],
        accept: (_) => true,
        into: into,
        existingByEntity: {
          'f1': {'seaA'},
        },
        entityId: (o) => o.fleetId,
        dedupKey: (o) => o.destinationSeaZoneId ?? '',
      );
      expect(
        into.map((o) => '${o.fleetId}:${o.destinationSeaZoneId}').toList(),
        // f1:seaA is deduped; f2:seaA survives (different entity).
        ['f1:seaB', 'f2:seaA'],
      );
    });

    test('emitAcceptedCandidates probes every candidate without dedup args', () {
      final into = <NavalMoveOrder>[];
      emitAcceptedCandidates<NavalMoveOrder>(
        candidates: const [
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
        ],
        accept: (_) => true,
        into: into,
        // entityId/dedupKey omitted -> dedup disabled even though duplicates.
        existingByEntity: {
          'f1': {'seaA'},
        },
      );
      expect(into.length, 2);
    });

    test('runCappedSuggestionProbeLoop respects acceptance and probe caps', () {
      final accepted = <int>[];
      final probes = List.generate(10, (i) => i);
      runCappedSuggestionProbeLoop<int>(
        candidates: probes,
        shouldSkip: (n) => n.isEven,
        probe: (n) => n % 3 == 1,
        onAccepted: accepted.add,
        maxAccepted: 2,
        maxProbes: 4,
      );
      expect(accepted, [1, 7]);
    });

    test('ownedProvinceIdsFromView returns full province ids for owner', () {
      final view = buildPlayerView(
        Game(
          id: 'g-owned',
          worldState: WorldState(
            turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: 'p1', regionId: kOldWorldRegionId, ownerId: 'gp1'),
                Province(id: 'p2', regionId: kOldWorldRegionId, ownerId: 'gp2'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: true),
            Player(id: 'gp2', displayName: 'P2', isHuman: true),
          ],
        ),
        topology,
        'gp1',
      );
      expect(
        ownedProvinceIdsFromView(view, 'gp1'),
        {ProvinceId.full(kOldWorldRegionId, 'p1')},
      );
    });
  });
}

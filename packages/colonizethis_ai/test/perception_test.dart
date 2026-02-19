import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('AIWorldSnapshot.fromPlayerView', () {
    PlayerView _view({
      required String playerId,
      Map<String, DiplomacyRelation> diplomacyByOtherId = const {},
      Map<String, Province> provincesById = const {},
      int workerCount = 0,
      int treasury = 0,
    }) {
      final player = Player(
        id: playerId,
        displayName: 'P',
        isHuman: false,
        workerPool: WorkerPool(peasants: workerCount),
        treasury: treasury,
      );
      return PlayerView(
        playerId: playerId,
        player: player,
        ownUnitsById: const {},
        provincesById: provincesById,
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: diplomacyByOtherId,
      );
    }

    test('threats include atWarWith from diplomacy', () {
      final view = _view(
        playerId: 'gp1',
        diplomacyByOtherId: {
          'gp2': DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
          ),
          'gp3': DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atPeace,
          ),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.threats.atWarWith, ['gp2']);
    });

    test('opportunities count unclaimed provinces', () {
      const r = 'oldWorld';
      final view = _view(
        playerId: 'gp1',
        provincesById: {
          '$r|p1': const Province(id: 'p1', regionId: r, displayName: 'P1', ownerId: null),
          '$r|p2': const Province(id: 'p2', regionId: r, displayName: 'P2', ownerId: ''),
          '$r|p3': const Province(id: 'p3', regionId: r, displayName: 'P3', ownerId: 'gp1'),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.opportunities.unclaimedProvinces, 2);
    });

    test('economy summarizes worker count treasury own provinces', () {
      const r = 'oldWorld';
      final view = _view(
        playerId: 'gp1',
        workerCount: 5,
        treasury: 100,
        provincesById: {
          '$r|p1': const Province(id: 'p1', regionId: r, displayName: 'P1', ownerId: 'gp1'),
          '$r|p2': const Province(id: 'p2', regionId: r, displayName: 'P2', ownerId: 'gp2'),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.economy.workerCount, 5);
      expect(snap.economy.treasury, 100);
      expect(snap.economy.ownProvinceCount, 1);
    });

    test('relations copied from view', () {
      final view = _view(
        playerId: 'gp1',
        diplomacyByOtherId: {
          'gp2': DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.relations.length, 1);
      expect(snap.relations['gp2'], isNotNull);
    });
  });
}

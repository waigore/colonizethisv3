import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/turn_news_digest_test_support.dart';

void main() {
  group('buildTurnNewsDigestForComplete', () {
    test('Given victory on end state When build Then digest is null', () {
      final start = turnNewsMinimalGame(turn: 5);
      final end = start.copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'gp1',
          type: VictoryType.military,
          turnNumber: 5,
        ),
      );
      final r = buildTurnNewsDigestForComplete(start: start, end: end);
      expect(r.digest, isNull);
      expect(r.game, same(end));
    });

    test('Given relation atPeace to atWar When build Then war line', () {
      final start = turnNewsTwoGpGame(turn: 0, relState: RelationState.atPeace);
      final end = turnNewsTwoGpGame(turn: 1, relState: RelationState.atWar);
      final r = buildTurnNewsDigestForComplete(start: start, end: end);
      expect(r.digest, isNotNull);
      final warLines = r.digest!.lines.whereType<TurnNewsDiplomacyLine>();
      expect(warLines, hasLength(1));
      expect(warLines.single.kind, TurnNewsDiplomacyKind.war);
      expect({
        warLines.single.factionIdA,
        warLines.single.factionIdB,
      }, equals({'gp1', 'gp2'}));
    });

    test(
      'Given first province reveal When build Then discovery line and id tracked',
      () {
        const regionId = 'oldWorld';
        const localPid = 'P1';
        final fullPid = ProvinceId.full(regionId, localPid);
        final start = turnNewsGameWithProvinceVis(
          turn: 0,
          fullProvinceId: fullPid,
          regionId: regionId,
          localProvinceId: localPid,
          visibility: 'unknown',
        );
        final end = turnNewsGameWithProvinceVis(
          turn: 1,
          fullProvinceId: fullPid,
          regionId: regionId,
          localProvinceId: localPid,
          visibility: 'fogged',
        );
        final r = buildTurnNewsDigestForComplete(start: start, end: end);
        expect(
          r.game.worldState.newsDigestProvinceRevealDoneIds,
          contains(fullPid),
        );
        final disc = r.digest!.lines
            .whereType<TurnNewsProvinceDiscoveredLine>();
        expect(disc, hasLength(1));
        expect(disc.single.provinceId, fullPid);
      },
    );

    test(
      'Given province ownership gp1 to null When build Then no province captured line',
      () {
        const regionId = 'oldWorld';
        const localPid = 'P1';
        final pair = turnNewsProvinceOwnershipPair(
          regionId: regionId,
          localPid: localPid,
          startTurn: 0,
          startOwner: 'gp1',
          endOwner: null,
        );
        final r = buildTurnNewsDigestForComplete(
          start: pair.start,
          end: pair.end,
        );
        final caps = r.digest!.lines.whereType<TurnNewsProvinceCapturedLine>();
        expect(caps, isEmpty);
      },
    );

    test(
      'Given province ownership gp1 to gp2 When build Then capture line',
      () {
        const regionId = 'oldWorld';
        const localPid = 'P1';
        final fullPid = ProvinceId.full(regionId, localPid);
        final pair = turnNewsProvinceOwnershipPair(
          regionId: regionId,
          localPid: localPid,
          startTurn: 0,
          startOwner: 'gp1',
          endOwner: 'gp2',
        );
        final r = buildTurnNewsDigestForComplete(
          start: pair.start,
          end: pair.end,
        );
        final caps = r.digest!.lines.whereType<TurnNewsProvinceCapturedLine>();
        expect(caps, hasLength(1));
        expect(caps.single.provinceId, fullPid);
        expect(caps.single.previousOwnerId, 'gp1');
        expect(caps.single.newOwnerId, 'gp2');
      },
    );

    test('Given relation atWar to atPeace When build Then peace line', () {
      final start = turnNewsTwoGpGame(turn: 0, relState: RelationState.atWar);
      final end = turnNewsTwoGpGame(turn: 1, relState: RelationState.atPeace);
      final r = buildTurnNewsDigestForComplete(start: start, end: end);
      final dip = r.digest!.lines.whereType<TurnNewsDiplomacyLine>();
      expect(dip, hasLength(1));
      expect(dip.single.kind, TurnNewsDiplomacyKind.peace);
      expect({
        dip.single.factionIdA,
        dip.single.factionIdB,
      }, equals({'gp1', 'gp2'}));
    });

    test(
      'Given overture stage advances When build Then overture line sorted',
      () {
        final pair = turnNewsOvertureAdvancePair();
        final r = buildTurnNewsDigestForComplete(
          start: pair.start,
          end: pair.end,
        );
        final ov = r.digest!.lines.whereType<TurnNewsOvertureAdvancedLine>();
        expect(ov, hasLength(1));
        expect(ov.single.offererGpId, 'gp1');
        expect(ov.single.targetFactionId, 'm1');
        expect(ov.single.newStage, OvertureStage.tradeConsulate);
      },
    );

    test(
      'Given first fleet at sea in zone When build Then sea line and id tracked',
      () {
        const regionId = 'oldWorld';
        const localSea = 'seaA';
        final fullSea = ProvinceId.full(regionId, localSea);
        final pair = turnNewsSeaZoneFleetPair();
        final r = buildTurnNewsDigestForComplete(
          start: pair.start,
          end: pair.end,
        );
        expect(
          r.game.worldState.newsDigestSeaZoneFleetDoneIds,
          contains(fullSea),
        );
        final sea = r.digest!.lines.whereType<TurnNewsSeaZoneFleetLine>();
        expect(sea, hasLength(1));
        expect(sea.single.seaZoneId, fullSea);
      },
    );

    test(
      'Given same start and end When build twice Then identical digest lines',
      () {
        final start = turnNewsTwoGpGame(
          turn: 0,
          relState: RelationState.atPeace,
        );
        final end = turnNewsTwoGpGame(turn: 1, relState: RelationState.atWar);
        final r1 = buildTurnNewsDigestForComplete(start: start, end: end);
        final r2 = buildTurnNewsDigestForComplete(start: start, end: end);
        expect(r1.digest, isNotNull);
        expect(r2.digest, isNotNull);
        expectDigestLinesEqual(r1.digest!, r2.digest!);
      },
    );

    test(
      'Given province already in reveal done When reveal again Then no second discovery',
      () {
        const regionId = 'oldWorld';
        const localPid = 'P1';
        final fullPid = ProvinceId.full(regionId, localPid);
        final start = turnNewsGameWithProvinceVis(
          turn: 1,
          fullProvinceId: fullPid,
          regionId: regionId,
          localProvinceId: localPid,
          visibility: 'unknown',
          revealDone: [fullPid],
        );
        final end = turnNewsGameWithProvinceVis(
          turn: 2,
          fullProvinceId: fullPid,
          regionId: regionId,
          localProvinceId: localPid,
          visibility: 'fogged',
          revealDone: [fullPid],
        );
        final r = buildTurnNewsDigestForComplete(start: start, end: end);
        final disc = r.digest!.lines
            .whereType<TurnNewsProvinceDiscoveredLine>();
        expect(disc, isEmpty);
      },
    );
  });
}

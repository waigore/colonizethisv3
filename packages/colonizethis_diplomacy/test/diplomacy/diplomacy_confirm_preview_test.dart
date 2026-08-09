import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const humanId = 'gp1';
  const targetGp = 'gp2';
  const minorId = 'minor1';
  const tribeId = 'tribe1';

  Game baseGame() => diplomacyGame(
    players: const [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 50_000),
      Player(id: targetGp, displayName: 'Spain', isHuman: false),
    ],
    minorNations: const [MinorNation(id: minorId, displayName: 'Bavaria')],
    tribes: const [Tribe(id: tribeId, displayName: 'Aztec')],
    oldWorld: RegionData(
      provinces: [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: minorId),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: tribeId),
      ],
    ),
  );

  test('break alliance includes immediate timing line only', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.breakAlliance,
        targetFactionId: targetGp,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    expect(lines.any((l) => l.startsWith('When:')), isTrue);
    expect(lines.any((l) => l.contains('immediately')), isTrue);
    expect(lines.any((l) => l.contains('-50')), isFalse);
    expect(lines.any((l) => l.contains('-10')), isFalse);
  });

  test('declare war states pair war and overture end without timing line', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetGp,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
    expect(lines.join('\n').toLowerCase(), contains('war'));
    expect(lines.join('\n').toLowerCase(), contains('overtures'));
  });

  test('consulate overture shows single treasury cost', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.tradeConsulate,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Bavaria',
    );
    final body = lines.join('\n');
    expect(body, contains('£$overtureConsulateCost'));
    expect('£'.allMatches(body).length, 1);
    expect(body, contains('only on acceptance'));
  });

  test('join empire minor absorb omits province counts', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.joinEmpire,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Bavaria',
    );
    final body = lines.join('\n');
    expect(body, contains('join your realm'));
    expect(body, contains('£'));
    expect(body.toLowerCase(), isNot(contains('province')));
  });

  test('join empire tribe colony outcome', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: tribeId,
        overtureStage: OvertureStage.joinEmpire,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Aztec',
    );
    expect(lines.join('\n'), contains('colony'));
  });

  test('join empire toward nearly defeated GP uses absorption copy', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: targetGp,
        overtureStage: OvertureStage.joinEmpire,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    final body = lines.join('\n');
    expect(body, contains('nearly defeated'));
    expect(body, contains('absorbed'));
    expect(body, isNot(contains('£')));
  });

  test('offer peace states conditional peace without timing line', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: targetGp,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    final body = lines.join('\n');
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
    expect(body.toLowerCase(), contains('peace'));
    expect(body.toLowerCase(), contains('accept'));
  });

  test('alliance states free cost and mutual-defence offer', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: targetGp,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    final body = lines.join('\n');
    expect(body, contains('No treasury charge'));
    expect(body.toLowerCase(), contains('treaty'));
    expect(body.toLowerCase(), contains('allied'));
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
  });

  test('embassy overture shows single treasury cost', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.embassy,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Bavaria',
    );
    final body = lines.join('\n');
    expect(body, contains('£$overtureEmbassyCost'));
    expect('£'.allMatches(body).length, 1);
    expect(body, contains('only on acceptance'));
  });

  test('nap overture states free cost and pact offer', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.nap,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Bavaria',
    );
    final body = lines.join('\n');
    expect(body, contains('No treasury charge'));
    expect(body, contains('Non-Aggression Pact'));
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
  });

  test('establish ftp states free cost and favoured-trading terms', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.establishFtp,
        targetFactionId: targetGp,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    final body = lines.join('\n');
    expect(body, contains('No treasury charge'));
    expect(body.toLowerCase(), contains('favoured-trading-partner'));
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
  });

  test('boycott states colony trade embargo', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.boycott,
        targetFactionId: targetGp,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    final body = lines.join('\n');
    expect(body, contains('No treasury charge'));
    expect(body.toLowerCase(), contains('colonies'));
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
  });

  test('revoke boycott ends trade embargo copy', () {
    final lines = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.revokeBoycott,
        targetFactionId: targetGp,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Spain',
    );
    final body = lines.join('\n');
    expect(body, contains('No treasury charge'));
    expect(body.toLowerCase(), contains('embargo'));
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
  });

  test('preview lines stay short structured labels without prose wall', () {
    final orders = <DiplomaticOrder>[
      const DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetGp,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: targetGp,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: targetGp,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.breakAlliance,
        targetFactionId: targetGp,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.establishFtp,
        targetFactionId: targetGp,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.boycott,
        targetFactionId: targetGp,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.revokeBoycott,
        targetFactionId: targetGp,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: minorId,
        amount: 1000,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: minorId,
        amount: 10,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.tradeConsulate,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.embassy,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.nap,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: minorId,
        overtureStage: OvertureStage.joinEmpire,
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: targetGp,
        overtureStage: OvertureStage.joinEmpire,
      ),
    ];
    for (final order in orders) {
      final lines = buildDiplomacyConfirmPreviewLines(
        order: order,
        game: baseGame(),
        humanPlayerId: humanId,
        targetDisplayName: 'Spain',
      );
      expect(lines, isNotEmpty);
      expect(lines.length, lessThanOrEqualTo(4));
      for (final line in lines) {
        expect(
          line.startsWith('Cost:') ||
              line.startsWith('Effect:') ||
              line.startsWith('When:'),
          isTrue,
          reason: 'Unexpected line prefix in $order: $line',
        );
      }
    }
  });

  test('grant aid and subsidy preview lines', () {
    final grant = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: minorId,
        amount: 2000,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Bavaria',
    );
    expect(grant.join('\n'), contains('£2000'));
    expect(grant.join('\n').toLowerCase(), contains('standing'));

    final subsidy = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: minorId,
        amount: 15,
      ),
      game: baseGame(),
      humanPlayerId: humanId,
      targetDisplayName: 'Bavaria',
    );
    final subsidyBody = subsidy.join('\n');
    expect(subsidyBody, contains('15%'));
    expect(subsidyBody, contains('No per-turn gold'));
  });
}

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _humanId = 'gp1';
const _spainId = 'gp2';
const _franceId = 'gp3';
const _englandId = 'gp4';
const _bavariaId = 'minor1';

Game _fourGpGame({
  List<DiplomacyRelation> relations = const [],
  List<OvertureState> overtures = const [],
  List<MinorNation> minors = const [],
}) {
  return diplomacyGame(
    players: const [
      Player(id: _humanId, displayName: 'Portugal', isHuman: true),
      Player(id: _spainId, displayName: 'Spain', isHuman: false),
      Player(id: _franceId, displayName: 'France', isHuman: false),
      Player(id: _englandId, displayName: 'England', isHuman: false),
    ],
    minorNations: minors,
    diplomacyRelations: relations,
    overtureStates: overtures,
  );
}

DiplomaticOrder get _declareOnSpain => const DiplomaticOrder(
  type: DiplomaticOrderType.declareWar,
  targetFactionId: _spainId,
);

DiplomaticOrder get _declareOnBavaria => const DiplomaticOrder(
  type: DiplomaticOrderType.declareWar,
  targetFactionId: _bavariaId,
);

void main() {
  test(
    'declare war names a persisted formal ally who may be called to defend',
    () {
      final game = _fourGpGame(
        relations: const [
          DiplomacyRelation(
            factionId1: _spainId,
            factionId2: _franceId,
            formalAlliance: true,
          ),
        ],
      );
      final lines = buildDiplomacyConfirmPreviewLines(
        order: _declareOnSpain,
        game: game,
        humanPlayerId: _humanId,
        targetDisplayName: 'Spain',
      );
      final body = lines.join('\n');
      expect(
        body,
        contains(
          'Effect: France holds a formal alliance with Spain and may be '
          'called to defend. They may join the war against you or refuse.',
        ),
      );
      expect(body.toLowerCase(), isNot(contains('will join')));
      expect(body, isNot(contains('formalAlliance')));
      expect(body, isNot(contains('-50')));
      expect(body, isNot(contains('-10')));
    },
  );

  test('declare war omits informal Allied band without a formal alliance', () {
    final game = _fourGpGame(
      relations: const [
        DiplomacyRelation(
          factionId1: _spainId,
          factionId2: _franceId,
          score: 80,
          level: RelationLevel.allied,
        ),
      ],
    );
    final body = buildDiplomacyConfirmPreviewLines(
      order: _declareOnSpain,
      game: game,
      humanPlayerId: _humanId,
      targetDisplayName: 'Spain',
    ).join('\n');
    expect(body, isNot(contains('France')));
  });

  test(
    'declare war omits a same-turn draft Alliance without a persisted treaty',
    () {
      final game = _fourGpGame();
      const draftAlliance = DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: _franceId,
      );
      final draft = Orders(
        diplomaticOrdersByPlayerId: {
          _spainId: [draftAlliance],
        },
      );
      expect(
        draft.diplomaticOrdersByPlayerId[_spainId],
        contains(draftAlliance),
      );
      final body = buildDiplomacyConfirmPreviewLines(
        order: _declareOnSpain,
        game: game,
        humanPlayerId: _humanId,
        targetDisplayName: 'Spain',
      ).join('\n');
      expect(body, isNot(contains('France')));
      expect(body, contains('War with Spain'));
    },
  );

  test('declare war omits a court with no persisted formal alliance', () {
    final game = _fourGpGame();
    final body = buildDiplomacyConfirmPreviewLines(
      order: _declareOnSpain,
      game: game,
      humanPlayerId: _humanId,
      targetDisplayName: 'Spain',
    ).join('\n');
    expect(body, isNot(contains('France')));
    expect(body, contains('War with Spain'));
    expect(body, contains('overtures'));
  });

  test('declare war omits an ally already at war with the declaring GP', () {
    final game = _fourGpGame(
      relations: const [
        DiplomacyRelation(
          factionId1: _spainId,
          factionId2: _franceId,
          formalAlliance: true,
        ),
        DiplomacyRelation(
          factionId1: _humanId,
          factionId2: _franceId,
          state: RelationState.atWar,
        ),
      ],
    );
    final body = buildDiplomacyConfirmPreviewLines(
      order: _declareOnSpain,
      game: game,
      humanPlayerId: _humanId,
      targetDisplayName: 'Spain',
    ).join('\n');
    expect(body, isNot(contains('France')));
  });

  test('declare war emits one Effect line per ally sorted by display name', () {
    final game = _fourGpGame(
      relations: const [
        DiplomacyRelation(
          factionId1: _spainId,
          factionId2: _franceId,
          formalAlliance: true,
        ),
        DiplomacyRelation(
          factionId1: _spainId,
          factionId2: _englandId,
          formalAlliance: true,
        ),
      ],
    );
    final lines = declareWarThirdPartyPreviewLines(
      game: game,
      humanPlayerId: _humanId,
      targetFactionId: _spainId,
    );
    expect(lines, hasLength(2));
    expect(lines[0], contains('England'));
    expect(lines[1], contains('France'));
    expect(lines.join('\n'), isNot(contains('England and France')));
  });

  test('declare war on a Minor names a GP with an Embassy as intervention', () {
    final game = _fourGpGame(
      minors: const [MinorNation(id: _bavariaId, displayName: 'Bavaria')],
      overtures: const [
        OvertureState(
          gpId: _franceId,
          targetId: _bavariaId,
          stage: OvertureStage.embassy,
        ),
      ],
    );
    final body = buildDiplomacyConfirmPreviewLines(
      order: _declareOnBavaria,
      game: game,
      humanPlayerId: _humanId,
      targetDisplayName: 'Bavaria',
    ).join('\n');
    expect(
      body,
      contains(
        'Effect: France holds an Embassy or purchased land in Bavaria '
        'and may be asked to intervene.',
      ),
    );
  });

  test('declare war omits third-party lines when nobody qualifies', () {
    final game = _fourGpGame();
    final lines = buildDiplomacyConfirmPreviewLines(
      order: _declareOnSpain,
      game: game,
      humanPlayerId: _humanId,
      targetDisplayName: 'Spain',
    );
    expect(lines, hasLength(2));
    expect(
      lines.every((l) => l.contains('Spain') && !l.contains('France')),
      isTrue,
    );
  });

  test(
    'formal allies roster lists persisted treaties even if already at war',
    () {
      final game = _fourGpGame(
        relations: const [
          DiplomacyRelation(
            factionId1: _spainId,
            factionId2: _franceId,
            formalAlliance: true,
          ),
          DiplomacyRelation(
            factionId1: _humanId,
            factionId2: _franceId,
            state: RelationState.atWar,
          ),
        ],
      );
      expect(
        formalAllyDisplayNames(
          game: game,
          viewedGpId: _spainId,
          humanPlayerId: _humanId,
        ),
        ['France'],
      );
      expect(
        declareWarThirdPartyPreviewLines(
          game: game,
          humanPlayerId: _humanId,
          targetFactionId: _spainId,
        ),
        isEmpty,
      );
    },
  );

  test('formal allies roster omits the human and the viewed court', () {
    final game = _fourGpGame(
      relations: const [
        DiplomacyRelation(
          factionId1: _humanId,
          factionId2: _spainId,
          formalAlliance: true,
        ),
        DiplomacyRelation(
          factionId1: _spainId,
          factionId2: _franceId,
          formalAlliance: true,
        ),
      ],
    );
    expect(
      formalAllyDisplayNames(
        game: game,
        viewedGpId: _spainId,
        humanPlayerId: _humanId,
      ),
      ['France'],
    );
  });
}

// Diplomacy confirm dialog first-order preview pins (Refs #4181).

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_orders_pump_support.dart';
import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

Game _minorConsulateConfirmGame() {
  const ow = 'oldWorld';
  return buildPanelTestGame(
    id: 'diplomacy-consulate-confirm-test',
    players: const [
      Player(
        id: diplomacyOrdersHumanId,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
        techUnlocked: {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [
      MinorNation(id: diplomacyOrdersMinorId, displayName: 'Free City'),
    ],
    oldWorldProvinces: [
      Province(id: '$ow|p1', regionId: ow, ownerId: diplomacyOrdersHumanId),
      Province(
        id: '$ow|m1',
        regionId: ow,
        ownerId: diplomacyOrdersMinorId,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersMinorId,
        state: RelationState.atPeace,
        score: 50,
      ),
    ],
  );
}

Game _minorJoinEmpireConfirmGame() {
  return buildDiplomacyRichPanelTestGame().copyWith(
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp2',
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp3',
        state: RelationState.atWar,
        score: 20,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersMinorId,
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 't1',
        state: RelationState.atPeace,
        score: 50,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersMinorId,
        stage: OvertureStage.nap,
      ),
    ],
  );
}

Game _gpJoinEmpireConfirmGame() {
  const ow = 'oldWorld';
  const rivalCapital = '$ow|cap2';
  const rivalProv1 = '$ow|p2a';
  return buildPanelTestGame(
    id: 'diplomacy-gp-join-empire-confirm-test',
    players: const [
      Player(
        id: diplomacyOrdersHumanId,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
        techUnlocked: {kTechIdEmpireBuilding: true},
      ),
      Player(
        id: diplomacyOrdersGp2,
        displayName: 'Rival Power',
        isHuman: false,
        capitalProvinceId: rivalCapital,
      ),
    ],
    oldWorldProvinces: [
      Province(id: '$ow|p1', regionId: ow, ownerId: diplomacyOrdersHumanId),
      Province(id: rivalCapital, regionId: ow, ownerId: diplomacyOrdersHumanId),
      Province(id: rivalProv1, regionId: ow, ownerId: diplomacyOrdersGp2),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersGp2,
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
  ).copyWith(
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersGp2,
        stage: OvertureStage.nap,
      ),
    ],
  );
}

Game _tribeJoinEmpireConfirmGame() {
  return buildDiplomacyRichPanelTestGame().copyWith(
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp2',
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp3',
        state: RelationState.atWar,
        score: 20,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersMinorId,
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 't1',
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: 't1',
        stage: OvertureStage.nap,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  setUp(() {
    AppEventBus.reset();
  });

  testWidgets(
    'DiplomacyPanel confirm body includes first-order preview lines',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame().copyWith(
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 90,
            formalAlliance: true,
          ),
        ],
      );
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final confirmFuture = bus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      await pumpDiplomacyOrdersPanel(tester, game: game, humanId: humanId, bus: bus);
      await tapVisibleDiplomacy(tester, find.text('Break Alliance'));

      final confirm = await confirmFuture;
      expect(confirm.message, contains('When:'));
      expect(confirm.message.toLowerCase(), contains('immediately'));
      expect(confirm.message, isNot(contains('Confirm Break Alliance against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Declare War confirm includes first-order preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await awaitConfirmOnDiplomacyActionTap(
        tester,
        game: buildDiplomacyPanelTestGame(),
        actionFinder: find.text('Declare War'),
        tall: true,
      );
      final body = confirm.message;
      expect(body.toLowerCase(), contains('war'));
      expect(body.toLowerCase(), contains('overtures'));
      expect(body, isNot(contains('When:')));
      expect(body, isNot(contains('Confirm Declare War against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Consulate confirm shows paid overture preview (Refs #4181)',
    (WidgetTester tester) async {
      final eventBus = AppEventBus.create();
      final confirmFuture = eventBus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      await pumpDiplomacyOrdersPanel(
        tester,
        game: _minorConsulateConfirmGame(),
        bus: eventBus,
        minorsTab: true,
        tall: true,
      );
      final consulateInMinorRow = find.descendant(
        of: diplomacyMinorRow(),
        matching: find.text('Consulate'),
      );
      await tapVisibleDiplomacy(tester, consulateInMinorRow);
      final confirm = await confirmFuture;
      final body = confirm.message;
      expect(body, contains('£$overtureConsulateCost'));
      expect(body, contains('only on acceptance'));
      expect(body, isNot(contains('Confirm Consulate against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Join Empire minor confirm shows absorb preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await awaitConfirmOnDiplomacyActionTap(
        tester,
        game: _minorJoinEmpireConfirmGame(),
        actionFinder: find.text('Join Empire').first,
        minorsTab: true,
        tall: true,
      );
      final body = confirm.message.toLowerCase();
      expect(body, contains('join your realm'));
      expect(body, isNot(contains('province')));
    },
  );

  testWidgets(
    'DiplomacyPanel Join Empire tribe confirm shows colony preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await awaitConfirmOnDiplomacyActionTap(
        tester,
        game: _tribeJoinEmpireConfirmGame(),
        actionFinder: find.text('Join Empire').last,
        tall: true,
      );
      expect(confirm.message.toLowerCase(), contains('colony'));
      expect(confirm.message, isNot(contains('Confirm Join Empire against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Join Empire GP confirm shows absorption preview (Refs #4181)',
    (WidgetTester tester) async {
      final eventBus = AppEventBus.create();
      final confirmFuture = eventBus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      await pumpDiplomacyOrdersPanel(
        tester,
        game: _gpJoinEmpireConfirmGame(),
        bus: eventBus,
        tall: true,
      );
      final gpRow = find.byKey(
        ValueKey('$kDiplomacyRowBodyKeyPrefix$diplomacyOrdersGp2'),
      );
      final joinEmpireInGpRow = find.descendant(
        of: gpRow,
        matching: find.text('Join Empire'),
      );
      await tapVisibleDiplomacy(tester, joinEmpireInGpRow);
      final confirm = await confirmFuture;
      final body = confirm.message;
      expect(body.toLowerCase(), contains('nearly defeated'));
      expect(body.toLowerCase(), contains('absorbed'));
      expect(body, isNot(contains('Confirm Join Empire against')));
      expect(body, isNot(contains('£')));
    },
  );
}

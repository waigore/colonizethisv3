// GAME30001 Join Empire confirm stories (Refs #4729).

part of 'catalog.dart';

Widget joinEmpireConfirmMinorAbsorbStory() {
  const humanId = 'gp1';
  final game = Game(
    id: 'wb-join-empire-minor',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 50000),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Bavaria'),
    ],
  );
  final message = buildDiplomacyConfirmPreviewMessage(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.joinEmpire,
    ),
    game: game,
    humanPlayerId: humanId,
    targetDisplayName: 'Bavaria',
  );
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: Center(
      child: CtConfirmDialog(title: 'Join Empire', message: message),
    ),
  );
}

Widget joinEmpireConfirmTribeColonyStory() {
  const humanId = 'gp1';
  final game = Game(
    id: 'wb-join-empire-tribe',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 50000),
    ],
    tribes: const [
      Tribe(id: 'tribe1', displayName: 'Aztec'),
    ],
  );
  final message = buildDiplomacyConfirmPreviewMessage(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'tribe1',
      overtureStage: OvertureStage.joinEmpire,
    ),
    game: game,
    humanPlayerId: humanId,
    targetDisplayName: 'Aztec',
  );
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: Center(
      child: CtConfirmDialog(title: 'Join Empire', message: message),
    ),
  );
}

Widget joinEmpireConfirmGpAbsorbStory() {
  const humanId = 'gp1';
  const spainId = 'gp2';
  final game = Game(
    id: 'wb-join-empire-gp',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: humanId, displayName: 'England', isHuman: true),
      Player(id: spainId, displayName: 'Spain', isHuman: false),
    ],
  );
  final message = buildDiplomacyConfirmPreviewMessage(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: spainId,
      overtureStage: OvertureStage.joinEmpire,
    ),
    game: game,
    humanPlayerId: humanId,
    targetDisplayName: 'Spain',
  );
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: Center(
      child: CtConfirmDialog(title: 'Join Empire', message: message),
    ),
  );
}

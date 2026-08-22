part of 'catalog.dart';

/// GAME30001 Boycott / Revoke Boycott confirm stories (Refs #4584).
Game _boycottConfirmCatalogGame() {
  const humanId = 'gp1';
  return Game(
    id: 'wb-boycott-confirm',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: humanId, displayName: 'England', isHuman: true),
      Player(id: 'gp2', displayName: 'Spain', isHuman: false),
    ],
    tribes: const [
      Tribe(id: 'tribe_aztec', displayName: 'Aztec'),
      Tribe(id: 'tribe_inca', displayName: 'Inca'),
    ],
    colonyStates: const [
      ColonyState(tribeId: 'tribe_aztec', colonyOfGpId: humanId, sinceTurn: 1),
      ColonyState(tribeId: 'tribe_inca', colonyOfGpId: humanId, sinceTurn: 1),
    ],
  );
}

Widget _boycottConfirmDialogStory({
  required String title,
  required DiplomaticOrderType type,
}) {
  final game = _boycottConfirmCatalogGame();
  final message = buildDiplomacyConfirmPreviewMessage(
    order: DiplomaticOrder(type: type, targetFactionId: 'gp2'),
    game: game,
    humanPlayerId: 'gp1',
    targetDisplayName: 'Spain',
  );
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: Center(
      child: CtConfirmDialog(title: title, message: message),
    ),
  );
}

Widget boycottConfirmTwoColoniesStory() => _boycottConfirmDialogStory(
  title: 'Boycott',
  type: DiplomaticOrderType.boycott,
);

Widget revokeBoycottConfirmTwoColoniesStory() => _boycottConfirmDialogStory(
  title: 'Revoke Boycott',
  type: DiplomaticOrderType.revokeBoycott,
);

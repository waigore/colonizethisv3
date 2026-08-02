// coverage:ignore-file
// Dev-only Widgetbook catalog part; generals strip on UNIT20001 (Refs #4233).
part of 'catalog.dart';

const _generalsStripStoryPlayerId = 'gp_generals_strip_story';

Game _generalsStripStoryGame() {
  return Game(
    id: 'g_generals_strip_story',
    generals: const [
      General(id: 'g1', ownerId: _generalsStripStoryPlayerId, medals: 0),
      General(id: 'g2', ownerId: _generalsStripStoryPlayerId, medals: 2),
    ],
    players: const [
      Player(
        id: _generalsStripStoryPlayerId,
        displayName: 'Story GP',
        isHuman: true,
        generalCap: 3,
      ),
    ],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
  );
}

/// Military Units generals strip use cases. SPEC/ui/military-units-panel.md (#4233).
List<WidgetbookUseCase> get militaryGeneralsStripUseCases => [
  WidgetbookUseCase(
    name: 'Generals strip (#4233)',
    builder: (context) {
      return widgetbookEditorialMonocleApp(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: MilitaryGeneralsStrip(
              game: _generalsStripStoryGame(),
              humanPlayerId: _generalsStripStoryPlayerId,
            ),
          ),
        ),
      );
    },
  ),
];

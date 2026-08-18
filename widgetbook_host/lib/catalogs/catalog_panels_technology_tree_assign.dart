// coverage:ignore-file
// Dev-only Widgetbook catalog part; GAME40001 Tree assign preview
// stories (Refs #4498).
part of 'catalog.dart';

/// Tree node dialog assign / replace / observe / locked previews.
List<WidgetbookUseCase> get technologyTreeAssignUseCases => [
  WidgetbookUseCase(
    name: 'Tree assign — empty seat',
    builder: (context) {
      const p = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        researchSlots: 3,
      );
      final game = Game(
        id: 'wb_tech_tree_assign_empty',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [p],
      );
      return widgetbookEditorialMonocleApp(
        child: TechTreeWidget(game: game, player: p, onOrdersChanged: (_) {}),
      );
    },
  ),
  WidgetbookUseCase(
    name: 'Tree assign — seats full',
    builder: (context) {
      const p = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        researchSlots: 3,
        techUnlocked: {kTechIdCropRotation: true},
        researchSlotAssignments: {
          0: ResearchSlotAssignment(
            techId: kTechIdSawMill,
            funding: ResearchFundingLevel.medium,
          ),
          1: ResearchSlotAssignment(
            techId: kTechIdLandEnclosure,
            funding: ResearchFundingLevel.medium,
          ),
          2: ResearchSlotAssignment(
            techId: kTechIdIronMining,
            funding: ResearchFundingLevel.medium,
          ),
        },
        researchProgressByTechId: {kTechIdSawMill: 40},
      );
      final game = Game(
        id: 'wb_tech_tree_assign_full',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [p],
      );
      return widgetbookEditorialMonocleApp(
        child: TechTreeWidget(game: game, player: p, onOrdersChanged: (_) {}),
      );
    },
  ),
  WidgetbookUseCase(
    name: 'Tree assign — observe only',
    builder: (context) {
      const p = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        researchSlots: 3,
      );
      final game = Game(
        id: 'wb_tech_tree_assign_observe',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [p],
      );
      return widgetbookEditorialMonocleApp(
        child: TechTreeWidget(game: game, player: p),
      );
    },
  ),
  WidgetbookUseCase(
    name: 'Tree assign — locked reason',
    builder: (context) {
      const p = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        researchSlots: 3,
      );
      final game = Game(
        id: 'wb_tech_tree_assign_locked',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [p],
      );
      return widgetbookEditorialMonocleApp(
        child: TechTreeWidget(game: game, player: p, onOrdersChanged: (_) {}),
      );
    },
  ),
  WidgetbookUseCase(
    name: 'Tree dialog — in-progress finish line',
    builder: (context) {
      const p = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        researchSlots: 3,
        treasury: 2000,
        researchSlotAssignments: {
          0: ResearchSlotAssignment(
            techId: kTechIdSawMill,
            funding: ResearchFundingLevel.medium,
          ),
        },
        researchProgressByTechId: {kTechIdSawMill: 1600},
      );
      final game = Game(
        id: 'wb_tech_tree_finish_line',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [p],
      );
      return widgetbookEditorialMonocleApp(
        child: TechTreeWidget(game: game, player: p, onOrdersChanged: (_) {}),
      );
    },
  ),
];

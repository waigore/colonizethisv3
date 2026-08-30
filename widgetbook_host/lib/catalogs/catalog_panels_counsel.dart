// coverage:ignore-file
// Dev-only Widgetbook catalog part; Counsel panel stories (Refs #4332 Development tab).
part of 'catalog.dart';

/// Minimal game fixture with no industry counsel recommendations.
Game _counselEmptyAdviceGame() {
  const playerId = 'counsel_empty_gp';
  return const Game(
    id: 'counsel_empty_advice',
    players: [
      Player(
        id: playerId,
        displayName: 'Empty counsel GP',
        isHuman: true,
      ),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
  );
}

Widget _counselIndustryStory(
  BuildContext context, {
  required Game game,
  String? highlightRecommendationId,
  bool narrowViewport = false,
}) {
  final screen = CounselScreen(
    game: game,
    humanPlayerId: game.players.first.id,
    highlightRecommendationId: highlightRecommendationId,
  );
  final child = ProviderScope(
    child: widgetbookEditorialMonocleApp(child: screen),
  );
  return narrowViewport ? mobileViewport(context, child) : child;
}

Widget _counselMilitaryStory(
  BuildContext context, {
  required Game game,
  String? highlightRecommendationId,
  bool narrowViewport = false,
}) {
  final screen = CounselScreen(
    game: game,
    humanPlayerId: game.players.first.id,
    highlightRecommendationId: highlightRecommendationId,
    initialTab: CounselTab.military,
  );
  final child = ProviderScope(
    child: widgetbookEditorialMonocleApp(child: screen),
  );
  return narrowViewport ? mobileViewport(context, child) : child;
}

Widget _counselDevelopmentStory(
  BuildContext context, {
  required Game game,
  String? highlightRecommendationId,
  bool narrowViewport = false,
}) {
  final screen = CounselScreen(
    game: game,
    humanPlayerId: game.players.first.id,
    highlightRecommendationId: highlightRecommendationId,
    initialTab: CounselTab.development,
  );
  final child = ProviderScope(
    child: widgetbookEditorialMonocleApp(child: screen),
  );
  return narrowViewport ? mobileViewport(context, child) : child;
}

Widget _counselTradeStory(
  BuildContext context, {
  required Game game,
  String? highlightRecommendationId,
  bool narrowViewport = false,
}) {
  final screen = CounselScreen(
    game: game,
    humanPlayerId: game.players.first.id,
    highlightRecommendationId: highlightRecommendationId,
    initialTab: CounselTab.trade,
  );
  final child = ProviderScope(
    child: widgetbookEditorialMonocleApp(child: screen),
  );
  return narrowViewport ? mobileViewport(context, child) : child;
}

/// Counsel Panel stories. SPEC/ui/counsel-panel.md.
List<WidgetbookNode> get counselPanelDirectories => [
  WidgetbookFolder(
    name: 'Counsel Panel',
    children: [
      WidgetbookUseCase(
        name: 'Counsel Industry (default)',
        builder: (context) => _counselIndustryStory(
          context,
          game: demoGameForOverlay,
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Industry (highlight)',
        builder: (context) => _counselIndustryStory(
          context,
          game: demoGameForOverlay,
          highlightRecommendationId: 'produce:lumber_from_timber',
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Industry (empty)',
        builder: (context) {
          final game = _counselEmptyAdviceGame();
          return _counselIndustryStory(context, game: game);
        },
      ),
      WidgetbookUseCase(
        name: 'Counsel Industry (narrow 360)',
        builder: (context) => _counselIndustryStory(
          context,
          game: demoGameForOverlay,
          narrowViewport: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Trade (default)',
        builder: (context) => _counselTradeStory(
          context,
          game: demoGameForOverlay,
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Trade (highlight)',
        builder: (context) => _counselTradeStory(
          context,
          game: demoGameForOverlay,
          highlightRecommendationId: 'offer:timber',
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Trade (empty)',
        builder: (context) {
          final game = _counselEmptyAdviceGame();
          return _counselTradeStory(context, game: game);
        },
      ),
      WidgetbookUseCase(
        name: 'Counsel Trade (narrow 360)',
        builder: (context) => _counselTradeStory(
          context,
          game: demoGameForOverlay,
          narrowViewport: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Military (default)',
        builder: (context) => _counselMilitaryStory(
          context,
          game: demoGameForOverlay,
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Military (empty)',
        builder: (context) {
          final game = _counselEmptyAdviceGame();
          return _counselMilitaryStory(context, game: game);
        },
      ),
      WidgetbookUseCase(
        name: 'Counsel Military (narrow 360)',
        builder: (context) => _counselMilitaryStory(
          context,
          game: demoGameForOverlay,
          narrowViewport: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Development (default)',
        builder: (context) => _counselDevelopmentStory(
          context,
          game: demoGameForOverlay,
        ),
      ),
      WidgetbookUseCase(
        name: 'Counsel Development (empty)',
        builder: (context) {
          final game = _counselEmptyAdviceGame();
          return _counselDevelopmentStory(context, game: game);
        },
      ),
      WidgetbookUseCase(
        name: 'Counsel Development (narrow 360)',
        builder: (context) => _counselDevelopmentStory(
          context,
          game: demoGameForOverlay,
          narrowViewport: true,
        ),
      ),
    ],
  ),
];

part of 'catalog.dart';

Game _turnNewsCatalogGame({required String id, int turnNumber = 2}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: 'oldWorld|P1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
            displayName: 'Sample Province',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Portugal', isHuman: false, treasury: 0),
    ],
  );
}

TurnNewsDigest _turnNewsSampleDigest() {
  return const TurnNewsDigest(
    resolvedTurnNumber: 2,
    lines: [
      TurnNewsDiplomacyLine(
        factionIdA: 'gp1',
        factionIdB: 'gp2',
        kind: TurnNewsDiplomacyKind.war,
      ),
      TurnNewsProvinceDiscoveredLine(provinceId: 'oldWorld|P1'),
    ],
  );
}

const TurnNewsCourtSnapshot _turnNewsResearchCourt = TurnNewsCourtSnapshot(
  families: [
    TurnNewsCourtFamilyHit(
      family: TurnNewsCourtFamily.researchComplete,
      count: 1,
      techDisplayName: 'Improved Sail Design',
    ),
  ],
);

Widget _turnNewsHost({
  required Game game,
  required TurnNewsDigest digest,
  TurnNewsCourtSnapshot court = TurnNewsCourtSnapshot.empty,
  int spyReportCount = 0,
}) {
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: Center(
      child: TurnNewsDialog(
        game: game,
        digest: digest,
        newTurnNumber: 3,
        courtSnapshot: court,
        spyReportCount: spyReportCount,
        onOpenEvents: court.isEmpty ? null : () {},
        onOpenIntelligence: spyReportCount > 0 ? () {} : null,
      ),
    ),
  );
}

/// Turn news dialog. SPEC/ui/turn-news-dialog.md.
List<WidgetbookNode> get turnNewsDialogDirectories => [
  WidgetbookFolder(
    name: 'Turn news',
    children: [
      WidgetbookUseCase(
        name: 'Sample lines',
        builder: (context) => _turnNewsHost(
          game: _turnNewsCatalogGame(id: 'wb_news', turnNumber: 3),
          digest: _turnNewsSampleDigest(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Empty digest',
        builder: (context) => _turnNewsHost(
          game: _turnNewsCatalogGame(id: 'wb_news_e'),
          digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
        ),
      ),
      WidgetbookUseCase(
        name: 'Empty gazette + court',
        builder: (context) => _turnNewsHost(
          game: _turnNewsCatalogGame(id: 'wb_news_court_empty'),
          digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
          court: _turnNewsResearchCourt,
        ),
      ),
      WidgetbookUseCase(
        name: 'Gazette + court',
        builder: (context) => _turnNewsHost(
          game: _turnNewsCatalogGame(id: 'wb_news_court_gaz'),
          digest: _turnNewsSampleDigest(),
          court: _turnNewsResearchCourt,
        ),
      ),
      WidgetbookUseCase(
        name: 'Spy footer coexistence',
        builder: (context) => _turnNewsHost(
          game: _turnNewsCatalogGame(id: 'wb_news_court_spy'),
          digest: _turnNewsSampleDigest(),
          court: _turnNewsResearchCourt,
          spyReportCount: 2,
        ),
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) => mobileViewport(
          context,
          _turnNewsHost(
            game: _turnNewsCatalogGame(id: 'wb_news_m'),
            digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
            court: _turnNewsResearchCourt,
          ),
        ),
      ),
    ],
  ),
];

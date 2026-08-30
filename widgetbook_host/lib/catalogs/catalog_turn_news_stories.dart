part of 'catalog.dart';

/// Turn news dialog. SPEC/ui/turn-news-dialog.md.
List<WidgetbookNode> get turnNewsDialogDirectories => [
  WidgetbookFolder(
    name: 'Turn news',
    children: [
      WidgetbookUseCase(
        name: 'Sample lines',
        builder: (context) {
          final game = Game(
            id: 'wb_news',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: 'oldWorld|P1',
                    regionId: 'oldWorld',
                    ownerId: 'gp1',
                    displayName: 'Sample Province',
                  ),
                ],
              ),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
              Player(
                id: 'gp2',
                displayName: 'Portugal',
                isHuman: false,
                treasury: 0,
              ),
            ],
          );
          final digest = TurnNewsDigest(
            resolvedTurnNumber: 2,
            lines: [
              const TurnNewsDiplomacyLine(
                factionIdA: 'gp1',
                factionIdB: 'gp2',
                kind: TurnNewsDiplomacyKind.war,
              ),
              const TurnNewsProvinceDiscoveredLine(provinceId: 'oldWorld|P1'),
            ],
          );
          return widgetbookEditorialMonocleApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            child: Center(
              child: TurnNewsDialog(
                game: game,
                digest: digest,
                newTurnNumber: 3,
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Empty digest',
        builder: (context) {
          final game = Game(
            id: 'wb_news_e',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
            ],
          );
          return widgetbookEditorialMonocleApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            child: Center(
              child: TurnNewsDialog(
                game: game,
                digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
                newTurnNumber: 2,
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Empty digest + court',
        builder: (context) {
          final game = Game(
            id: 'wb_news_court',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
            ],
          );
          return widgetbookEditorialMonocleApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            child: Center(
              child: TurnNewsDialog(
                game: game,
                digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
                newTurnNumber: 2,
                courtSummary: const TurnNewsCourtSummary(
                  clauses: ['Sailing finished'],
                ),
                onOpenEvents: () {},
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Gazette + court',
        builder: (context) {
          final game = Game(
            id: 'wb_news_both',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
              Player(
                id: 'gp2',
                displayName: 'Portugal',
                isHuman: false,
                treasury: 0,
              ),
            ],
          );
          return widgetbookEditorialMonocleApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            child: Center(
              child: TurnNewsDialog(
                game: game,
                digest: const TurnNewsDigest(
                  resolvedTurnNumber: 2,
                  lines: [
                    TurnNewsDiplomacyLine(
                      factionIdA: 'gp1',
                      factionIdB: 'gp2',
                      kind: TurnNewsDiplomacyKind.war,
                    ),
                  ],
                ),
                newTurnNumber: 3,
                courtSummary: const TurnNewsCourtSummary(
                  clauses: ['work finished'],
                ),
                onOpenEvents: () {},
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Court + spy footer',
        builder: (context) {
          final game = Game(
            id: 'wb_news_court_spy',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
            ],
          );
          return widgetbookEditorialMonocleApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            child: Center(
              child: TurnNewsDialog(
                game: game,
                digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
                newTurnNumber: 2,
                courtSummary: const TurnNewsCourtSummary(
                  clauses: ['market and realm accounts'],
                ),
                spyReportCount: 2,
                onOpenIntelligence: () {},
                onOpenEvents: () {},
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) {
          final game = Game(
            id: 'wb_news_m',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
            ],
          );
          return mobileViewport(
            context,
            widgetbookEditorialMonocleApp(
              localizationsDelegates:
                  AppLocalizationsBinding.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              child: Center(
                child: TurnNewsDialog(
                  game: game,
                  digest: const TurnNewsDigest(
                    resolvedTurnNumber: 1,
                    lines: [],
                  ),
                  newTurnNumber: 2,
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

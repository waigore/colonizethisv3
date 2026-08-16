part of 'catalog.dart';

Game _intelligenceCouncilStoryGame({
  required LastTurnIntelligenceDigest digest,
}) {
  return Game(
    id: 'wb_intel',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|fr1',
            regionId: 'oldWorld',
            ownerId: 'france',
            displayName: 'Paris',
          ),
        ],
      ),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'spain', displayName: 'Spain', isHuman: true, treasury: 0),
      Player(id: 'france', displayName: 'France', isHuman: false, treasury: 0),
      Player(id: 'gp_es', displayName: 'Spain AI', isHuman: false, treasury: 0),
    ],
    lastTurnIntelligenceDigest: digest,
  );
}

Widget _intelligenceCouncilStory(LastTurnIntelligenceDigest digest) {
  final game = _intelligenceCouncilStoryGame(digest: digest);
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: SizedBox(
      width: 480,
      height: 640,
      child: IntelligenceCouncilBody(game: game, humanPlayerId: 'spain'),
    ),
  );
}

/// Intelligence Council stories. SPEC/ui/intelligence-council.md.
List<WidgetbookNode> get intelligenceCouncilDirectories => [
  WidgetbookFolder(
    name: 'Intelligence Council',
    children: [
      WidgetbookUseCase(
        name: 'World briefing',
        builder: (context) => _intelligenceCouncilStory(
          const LastTurnIntelligenceDigest(
            resolvedTurnNumber: 2,
            worldLines: [
              IntelligenceWorldLine(
                kind: IntelligenceWorldKind.war,
                factionIdA: 'france',
                factionIdB: 'gp_es',
              ),
              IntelligenceWorldLine(
                kind: IntelligenceWorldKind.provinceCaptured,
                provinceId: 'oldWorld|fr1',
                factionIdA: 'gp_es',
                factionIdB: 'france',
              ),
            ],
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Spy reports',
        builder: (context) => _intelligenceCouncilStory(
          const LastTurnIntelligenceDigest(
            resolvedTurnNumber: 2,
            spyReportsByObserverId: {
              'spain': [
                IntelligenceSpyCourtBlock(
                  courtFactionId: 'france',
                  lines: [
                    IntelligenceSpyLine(
                      kind: IntelligenceSpyKind.diplomatic,
                      diplomaticType: DiplomaticEventType.declareWar,
                      fromFactionId: 'france',
                      toFactionId: 'gp_es',
                    ),
                    IntelligenceSpyLine(
                      kind: IntelligenceSpyKind.researchComplete,
                      techId: 'crop_rotation',
                      fromFactionId: 'france',
                    ),
                  ],
                ),
              ],
            },
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Empty',
        builder: (context) => _intelligenceCouncilStory(
          const LastTurnIntelligenceDigest(resolvedTurnNumber: 2),
        ),
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) => mobileViewport(
          context,
          _intelligenceCouncilStory(
            const LastTurnIntelligenceDigest(
              resolvedTurnNumber: 2,
              worldLines: [
                IntelligenceWorldLine(
                  kind: IntelligenceWorldKind.war,
                  factionIdA: 'france',
                  factionIdB: 'gp_es',
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
];

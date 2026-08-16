// coverage:ignore-file
// Dev-only Widgetbook catalog part; GAME40001 spy-insight preview
// stories (Refs #4457).
part of 'catalog.dart';

const String _kSpyInsightOldWorld = 'oldWorld';
const String _kSpyInsightFranceProvince = 'oldWorld|fr1';
const String _kSpyInsightSpainProvince = 'oldWorld|es1';

/// GAME40001 spy-insight / funding-None use cases. Refs #4457.
List<WidgetbookUseCase> get technologySpyInsightUseCases => [
  WidgetbookUseCase(
    name: 'Slots — spy insight (one rival)',
    builder: (context) => _technologySpyInsightStoryHost(rivalCount: 1),
  ),
  WidgetbookUseCase(
    name: 'Slots — spy insight (two rivals)',
    builder: (context) => _technologySpyInsightStoryHost(rivalCount: 2),
  ),
  WidgetbookUseCase(
    name: 'Slots — funding None',
    builder: (context) =>
        _technologySpyInsightStoryHost(rivalCount: 1, fundingNone: true),
  ),
];

Widget _technologySpyInsightStoryHost({
  required int rivalCount,
  bool fundingNone = false,
}) {
  final fixture = technologySpyInsightPreviewFixture(rivalCount: rivalCount);
  var orders = fixture.orders;
  if (fundingNone) {
    final humanId = fixture.player.id;
    final existing = orders.researchOrdersByPlayerId[humanId] ?? const [];
    orders = Orders(
      researchOrdersByPlayerId: <String, List<ResearchOrder>>{
        humanId: [
          for (final order in existing)
            ResearchOrder(
              slotIndex: order.slotIndex,
              techId: order.techId,
              funding: ResearchFundingLevel.none,
            ),
        ],
      },
    );
  }
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: TechnologyPanel(
        game: fixture.game,
        player: fixture.player,
        currentOrders: orders,
        onOrdersChanged: (_) {},
      ),
    ),
  );
}

/// Editable Slots fixture with [rivalCount] qualifying spy-insight courts.
({Player player, Game game, Orders orders}) technologySpyInsightPreviewFixture({
  required int rivalCount,
}) {
  const human = Player(
    id: 'gp1',
    displayName: 'England',
    isHuman: true,
    treasury: 8000,
    researchSlots: 3,
  );
  const france = Player(
    id: 'gp2',
    displayName: 'France',
    isHuman: false,
    techUnlocked: {
      kTechIdCropRotation: true,
      kTechIdSawMill: true,
      kTechIdLandEnclosure: true,
    },
  );
  const spain = Player(
    id: 'gp3',
    displayName: 'Spain',
    isHuman: false,
    techUnlocked: {
      kTechIdCropRotation: true,
      kTechIdSawMill: true,
      kTechIdLandEnclosure: true,
    },
  );
  final rivals = rivalCount >= 2 ? [france, spain] : [france];
  final provinces = <Province>[
    const Province(
      id: _kSpyInsightFranceProvince,
      regionId: _kSpyInsightOldWorld,
      ownerId: 'gp2',
    ),
    if (rivalCount >= 2)
      const Province(
        id: _kSpyInsightSpainProvince,
        regionId: _kSpyInsightOldWorld,
        ownerId: 'gp3',
      ),
  ];
  final spies = <Unit>[
    Unit(
      id: 'spy_fr',
      type: kUnitTypeSpy,
      ownerId: human.id,
      locationProvinceId: _kSpyInsightFranceProvince,
      tileKey: '$_kSpyInsightFranceProvince|0|0',
    ),
    if (rivalCount >= 2)
      Unit(
        id: 'spy_es',
        type: kUnitTypeSpy,
        ownerId: human.id,
        locationProvinceId: _kSpyInsightSpainProvince,
        tileKey: '$_kSpyInsightSpainProvince|0|0',
      ),
  ];
  final baseGame = Game(
    id: 'wb_tech_spy_insight',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: spies),
      newWorld: const RegionData(),
    ),
    players: [human, ...rivals],
  );
  return technologyFundingPreviewFixture(baseGame: baseGame, basePlayer: human);
}

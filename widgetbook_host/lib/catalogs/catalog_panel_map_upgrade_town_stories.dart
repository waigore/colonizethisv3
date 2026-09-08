// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Upgrade town overlay stories (Refs #4316).
part of 'catalog.dart';

/// MAP20001 Political **Upgrade town** shortcut use cases. Refs #4316.
List<WidgetbookUseCase> get provinceOverlayUpgradeTownUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Political Upgrade town enabled',
    builder: (context) => _provinceOverlayUpgradeTownStory(
      showUpgradeTownControl: true,
      upgradeTownEnabled: true,
      upgradeTownHasBuilderUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Upgrade town disabled',
    builder: (context) => _provinceOverlayUpgradeTownStory(
      showUpgradeTownControl: true,
      upgradeTownEnabled: false,
      upgradeTownHasBuilderUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Upgrade town hidden',
    builder: (context) => _provinceOverlayUpgradeTownStory(
      showUpgradeTownControl: false,
      upgradeTownEnabled: false,
      upgradeTownHasBuilderUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Upgrade town payoff start',
    builder: (context) => _provinceOverlayUpgradeTownPayoffStory(townLevel: 1),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Upgrade town payoff pause until 4',
    builder: (context) => _provinceOverlayUpgradeTownPayoffStory(townLevel: 2),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Upgrade town payoff 320 dp',
    builder: (context) => SizedBox(
      width: 320,
      child: _provinceOverlayUpgradeTownPayoffStory(townLevel: 2),
    ),
  ),
];

/// MAP20001 Political **Upgrade town** shortcut variants. Refs #4316.
Widget _provinceOverlayUpgradeTownStory({
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required bool upgradeTownHasBuilderUnits,
  Game? game,
}) {
  final overlayGame = game ?? demoGameForOverlay;
  final region = demoRegionForOverlay;
  return SizedBox(
    width: 640,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: overlayGame,
      region: region,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: overlayGame.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      showUpgradeTownControl: showUpgradeTownControl,
      upgradeTownEnabled: upgradeTownEnabled,
      upgradeTownHasBuilderUnits: upgradeTownHasBuilderUnits,
      upgradeTownTargetTileKey: showUpgradeTownControl
          ? sampleTileKeyForProvinceOverlay
          : null,
      onUpgradeTownTap: () {},
      onClose: () {},
    ),
  );
}

Widget _provinceOverlayUpgradeTownPayoffStory({required int townLevel}) {
  final base = demoGameForOverlay;
  final oldWorld = base.worldState.oldWorld;
  final provinces = [
    for (final p in oldWorld.provinces)
      p.id == sampleProvinceIdForOverlay
          ? p.copyWith(townDevelopmentLevel: townLevel)
          : p,
  ];
  final game = base.copyWith(
    worldState: base.worldState.copyWith(
      oldWorld: RegionData(provinces: provinces, units: oldWorld.units),
    ),
  );
  return _provinceOverlayUpgradeTownStory(
    showUpgradeTownControl: true,
    upgradeTownEnabled: true,
    upgradeTownHasBuilderUnits: true,
    game: game,
  );
}

/// UNIT10001 Upgrade town payoff stories. Refs #4747.
List<WidgetbookUseCase> get civilianUnitsPanelUpgradeTownPayoffUseCases => [
  WidgetbookUseCase(
    name: 'Upgrade town pending pause gist',
    builder: (context) => _civilianUpgradeTownPayoffStory(pending: true),
  ),
  WidgetbookUseCase(
    name: 'Upgrade town shortcut pause gist',
    builder: (context) => _civilianUpgradeTownPayoffStory(pending: false),
  ),
];

Widget _civilianUpgradeTownPayoffStory({required bool pending}) {
  const humanId = 'gp1';
  const provinceId = 'oldWorld|p1';
  const tile = 'oldWorld|p1|0|0';
  const builderId = 'u_builder';
  final game = Game(
    id: pending ? 'g_wb_ut_pending' : 'g_wb_ut_shortcut',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: humanId,
            displayName: 'Alpha',
            townDevelopmentLevel: 2,
            townTileKey: tile,
          ),
        ],
        units: [
          Unit(
            id: builderId,
            type: kUnitTypeBuilder,
            ownerId: humanId,
            locationProvinceId: provinceId,
            tileKey: tile,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          provinceId: [tile],
        },
      },
    ),
    players: const [Player(id: humanId, displayName: 'Human', isHuman: true)],
    minorNations: const [],
    tribes: const [],
  );
  return civilianUnitsPanelWithRiverpod(
    game: game,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      child: CivilianUnitsPanel(
        game: game,
        humanPlayerId: humanId,
        bus: AppEventBus(),
        builderOnly: true,
        currentOrders: pending
            ? const Orders(
                workOrdersByPlayerId: {
                  humanId: [
                    WorkOrder(
                      unitId: builderId,
                      target: kWorkTargetUpgradeTown,
                      targetTileKey: tile,
                    ),
                  ],
                },
              )
            : const Orders(),
        upgradeTownShortcutTargetTileKey: pending ? null : tile,
      ),
    ),
  );
}

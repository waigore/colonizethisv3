// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Prospect payoff overlay stories
// (Refs #4741).
part of 'catalog.dart';

/// MAP20001 Tile **Prospect** payoff gist use cases. Refs #4741.
List<WidgetbookUseCase> get provinceOverlayProspectPayoffUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Prospect payoff one turn',
    builder: (context) => _provinceOverlayProspectPayoffStory(width: 360),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Prospect payoff 320 dp',
    builder: (context) => _provinceOverlayProspectPayoffStory(width: 320),
  ),
];

Widget _provinceOverlayProspectPayoffStory({required double width}) {
  const humanId = 'gp1';
  const p1 = 'oldWorld|p1';
  const tile = 'oldWorld|p1|0|0';
  final game = Game(
    id: 'wb_prospect_payoff',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: 'oldWorld', ownerId: humanId),
        ],
        units: [
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: humanId,
            locationProvinceId: p1,
            tileKey: tile,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: [tile],
        },
      },
      playerVisibilityByTile: {
        humanId: {tile: 'fullyVisible'},
      },
    ),
    players: const [Player(id: humanId, displayName: 'Human', isHuman: true)],
    minorNations: const [],
    tribes: const [],
  );
  final region = RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.hills,
        ownerFactionId: humanId,
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.fogged,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {humanId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {p1: humanId},
  );
  final playerView = buildPlayerView(
    game,
    const MapTopology(
      nodes: [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [],
    ),
    humanId,
  );
  return SizedBox(
    width: width,
    height: 640,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: p1,
      selectedTileKey: tile,
      humanPlayerId: humanId,
      playerView: playerView,
      civilianInlineActions: provinceOverlayInlineActions(
        prospect: (showIcon: true, enabled: true, hasMatchingUnits: true),
      ),
      inlineActionCallbacks: (
        onExploreWithExplorerTap: null,
        onProspectWithExplorerTap: () {},
        onBuildImprovementTap: null,
        onBuildRoadTap: null,
        onBuildFortTap: null,
        onBuildPortTap: null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
      ),
      onClose: () {},
    ),
  );
}

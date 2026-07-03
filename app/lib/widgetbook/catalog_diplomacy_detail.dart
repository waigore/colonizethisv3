// Extracted from catalog_data_screens.dart to keep each part fragment file
// under the repo.part_unit_size 1000-line ceiling (SPEC/program/part-unit-size.md).
part of 'catalog.dart';

Game _diplomacyDetailStoryGame() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  return Game(
    id: 'wb_diplomacy_detail',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
      Player(id: rivalId, displayName: 'Spain', isHuman: false, treasury: 0),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: rivalId,
        score: 70,
        state: RelationState.atPeace,
      ),
    ],
    diplomaticHistoryEvents: [
      DiplomaticEvent(
        turn: 2,
        intraTurnIndex: 0,
        type: DiplomaticEventType.overtureAccepted,
        participants: {humanId, rivalId},
        fromFactionId: humanId,
        toFactionId: rivalId,
        overtureStage: OvertureStage.embassy,
      ),
    ],
    dossierEvidenceEntries: [
      DossierEvidenceEntry(
        observerId: humanId,
        subjectId: rivalId,
        agendaType: 'trade_focus',
        turnNumber: 2,
        description: 'Favoured trade over military buildup.',
      ),
    ],
  );
}

ProviderScope _diplomacyDetailScreenProviderScope() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  final game = _diplomacyDetailStoryGame();
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: rivalId,
        factionDisplayName: 'Spain',
        kind: FactionKind.greatPower,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

ProviderScope _diplomacyDetailScreenProviderScopeWar() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  final game = Game(
    id: 'wb_diplomacy_detail_war',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
      Player(id: rivalId, displayName: 'Spain', isHuman: false, treasury: 0),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: rivalId,
        score: 25,
        state: RelationState.atWar,
      ),
    ],
    diplomaticHistoryEvents: [
      DiplomaticEvent(
        turn: 4,
        intraTurnIndex: 0,
        type: DiplomaticEventType.declareWar,
        participants: {humanId, rivalId},
        fromFactionId: rivalId,
        toFactionId: humanId,
      ),
      DiplomaticEvent(
        turn: 3,
        intraTurnIndex: 0,
        type: DiplomaticEventType.agreementsClearedOnWar,
        participants: {humanId, rivalId},
        fromFactionId: humanId,
        toFactionId: rivalId,
      ),
    ],
    dossierEvidenceEntries: const [],
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: rivalId,
        factionDisplayName: 'Spain',
        kind: FactionKind.greatPower,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

ProviderScope _diplomacyDetailScreenProviderScopeMinor() {
  const humanId = 'gp_human';
  const minorId = 'minor_venice';
  final game = Game(
    id: 'wb_diplomacy_detail_minor',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
    ],
    minorNations: [MinorNation(id: minorId, displayName: 'Venice')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: minorId,
        score: 55,
        state: RelationState.atPeace,
      ),
    ],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: minorId,
        factionDisplayName: 'Venice',
        kind: FactionKind.minor,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

ProviderScope _diplomacyDetailScreenProviderScopeAlliance() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  final game = Game(
    id: 'wb_diplomacy_detail_alliance',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 6),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
      Player(id: rivalId, displayName: 'Spain', isHuman: false, treasury: 0),
    ],
    diplomacyRelations: [
      // Friendly band (90) AND a persisted formal alliance so the ALLIANCE
      // treaty badge renders in the CURRENT RELATION card (Refs #3625, AC4).
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: rivalId,
        score: 90,
        state: RelationState.atPeace,
        formalAlliance: true,
      ),
    ],
    diplomaticHistoryEvents: [
      DiplomaticEvent(
        turn: 5,
        intraTurnIndex: 0,
        type: DiplomaticEventType.allianceFormed,
        participants: {humanId, rivalId},
        fromFactionId: humanId,
        toFactionId: rivalId,
      ),
    ],
    dossierEvidenceEntries: const [],
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: rivalId,
        factionDisplayName: 'Spain',
        kind: FactionKind.greatPower,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

ProviderScope _diplomacyDetailScreenProviderScopeColonyTribe() {
  const humanId = 'gp1';
  const tribeId = 't1';
  const ow = 'oldWorld';
  const nw = 'newWorld';
  final game = Game(
    id: 'wb_diplomacy_detail_colony_tribe',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$ow|p1',
            regionId: ow,
            displayName: 'Home',
            ownerId: humanId,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: '$nw|t1prov',
            regionId: nw,
            displayName: 'Tribe Land',
            ownerId: tribeId,
          ),
        ],
      ),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: const [
      Player(id: humanId, displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    tribes: const [Tribe(id: tribeId, displayName: 'Powhatan')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: humanId, factionId2: tribeId, score: 60),
      DiplomacyRelation(factionId1: humanId, factionId2: 'gp2', score: 40),
    ],
    overtureStates: const [
      OvertureState(gpId: humanId, targetId: tribeId, stage: OvertureStage.embassy),
    ],
    colonyStates: const [
      ColonyState(tribeId: tribeId, colonyOfGpId: humanId, sinceTurn: 5),
    ],
    boycottStates: const [
      BoycottState(gpId: humanId, targetGpId: 'gp2', sinceTurn: 6),
    ],
    diplomaticHistoryEvents: const [
      DiplomaticEvent(
        turn: 5,
        intraTurnIndex: 0,
        type: DiplomaticEventType.overtureAccepted,
        participants: {humanId, tribeId},
        fromFactionId: humanId,
        toFactionId: tribeId,
        overtureStage: OvertureStage.embassy,
      ),
    ],
    dossierEvidenceEntries: const [],
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: tribeId,
        factionDisplayName: 'Powhatan',
        kind: FactionKind.tribe,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

ProviderScope _diplomacyDetailScreenProviderScopeSubsidizedMinor() {
  const humanId = 'gp1';
  const minorId = 'm1';
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const minorProvinceId = '$nw|m1prov';
  const tileA = '$minorProvinceId|0|0';
  const tileB = '$minorProvinceId|1|0';
  final game = Game(
    id: 'wb_diplomacy_detail_subsidized_minor',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$ow|p1',
            regionId: ow,
            displayName: 'Home',
            ownerId: humanId,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: minorProvinceId,
            regionId: nw,
            displayName: 'Bavaria Coast',
            ownerId: minorId,
          ),
        ],
      ),
      purchasedTilesByTileKey: const {tileA: humanId, tileB: humanId},
      tileKeysByRegionAndProvince: const {
        nw: {
          minorProvinceId: [tileA, tileB],
        },
      },
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: const [Player(id: humanId, displayName: 'Albion', isHuman: true)],
    minorNations: const [MinorNation(id: minorId, displayName: 'Bavaria')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: humanId, factionId2: minorId, score: 80),
    ],
    overtureStates: const [
      OvertureState(gpId: humanId, targetId: minorId, stage: OvertureStage.embassy),
    ],
    subsidyStates: const [
      SubsidyState(payerId: humanId, targetId: minorId, percent: 10),
    ],
    diplomaticHistoryEvents: const [
      DiplomaticEvent(
        turn: 7,
        intraTurnIndex: 0,
        type: DiplomaticEventType.subsidySet,
        participants: {humanId, minorId},
        fromFactionId: humanId,
        toFactionId: minorId,
        amount: 10,
      ),
    ],
    dossierEvidenceEntries: const [],
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: minorId,
        factionDisplayName: 'Bavaria',
        kind: FactionKind.minor,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

/// Diplomacy detail screen stories. SPEC/ui/diplomacy-detail-screen.md.
List<WidgetbookNode> get diplomacyDetailScreenDirectories => [
  WidgetbookFolder(
    name: 'Diplomacy Detail Screen',
    children: [
      WidgetbookUseCase(
        name: 'Default — GP with history and dossier',
        builder: (context) => _diplomacyDetailScreenProviderScope(),
      ),
      WidgetbookUseCase(
        name: 'At war — GP, no dossier',
        builder: (context) => _diplomacyDetailScreenProviderScopeWar(),
      ),
      WidgetbookUseCase(
        name: 'Minor nation — no dossier, empty history',
        builder: (context) => _diplomacyDetailScreenProviderScopeMinor(),
      ),
      WidgetbookUseCase(
        name: 'Formal alliance — GP with treaty badge',
        builder: (context) => _diplomacyDetailScreenProviderScopeAlliance(),
      ),
      WidgetbookUseCase(
        name: 'Colony Tribe — standing chips + relation meter',
        builder: (context) => _diplomacyDetailScreenProviderScopeColonyTribe(),
      ),
      WidgetbookUseCase(
        name: 'Subsidized Minor — overseas chip + relation meter',
        builder: (context) =>
            _diplomacyDetailScreenProviderScopeSubsidizedMinor(),
      ),
    ],
  ),
];

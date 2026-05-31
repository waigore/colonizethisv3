// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Extracted out of `catalog_part5.dart` to keep each part fragment file
// under the `repo.part_unit_size` 1000-line ceiling
// (`SPEC/program/part-unit-size.md`).
part of 'catalog.dart';

/// Showcases [CtDropdown] R5c selected-row highlight under the dark
/// editorial-monocle theme. The story preselects a non-null value so
/// opening the picker immediately demonstrates the `--accent-dim` tint
/// + 1 dp `--accent` left-edge border on the row matching that value.
/// Registered as the "CtDropdown — selected-row highlight" use case via
/// `ctDarkThemePrimitiveDirectories` in `catalog_part5.dart`; the class
/// itself lives here so `catalog_part5.dart` stays under the
/// `repo.part_unit_size` 1000-line ceiling.
/// See SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog
/// (CtDropdown) and issue #2859 R5c / S6.
class _CtDropdownSelectedRowStory extends StatefulWidget {
  const _CtDropdownSelectedRowStory();

  @override
  State<_CtDropdownSelectedRowStory> createState() =>
      _CtDropdownSelectedRowStoryState();
}

class _CtDropdownSelectedRowStoryState
    extends State<_CtDropdownSelectedRowStory> {
  static const List<String> _options = <String>[
    // ignore: avoid_hardcoded_strings_in_widgets
    'England',
    // ignore: avoid_hardcoded_strings_in_widgets
    'France',
    // ignore: avoid_hardcoded_strings_in_widgets
    'Spain',
  ];

  // ignore: avoid_hardcoded_strings_in_widgets
  String? _value = 'France';

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Tap the trigger — the row matching the current value paints '
            '--accent-dim tint + 1 dp --accent left edge (R5c); other rows '
            'paint a transparent same-width left edge so the layout never '
            'shifts.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 220,
            child: CtDropdown<String>(
              value: _value,
              items: _options,
              // ignore: avoid_hardcoded_strings_in_widgets
              hint: 'Select nation',
              onChanged: (v) => setState(() => _value = v),
            ),
          ),
        ],
      ),
    );
  }
}

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
    ],
  ),
];

Game _tradeScreenStoryGame() {
  const humanId = 'gp_human';
  return Game(
    id: 'wb_trade_screen',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 500),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
  );
}

ProviderScope _tradeScreenProviderScope({required Widget child}) {
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
      home: child,
    ),
  );
}

Widget _tradeScreenDefaultStory() {
  final game = _tradeScreenStoryGame();
  final player = game.players.first;
  return _tradeScreenProviderScope(
    child: TradeScreen(game: game, player: player),
  );
}

/// Trade screen stories. SPEC/ui/trade-screen.md (Refs #2993 E1+E2+E3+E4
/// scaffold slice — two-tab body with placeholder panels until #2989 /
/// #2990 data types land for the live Market and Deal Book content).
List<WidgetbookNode> get tradeScreenDirectories => [
  WidgetbookFolder(
    name: 'Trade Screen',
    children: [
      WidgetbookUseCase(
        name: 'Scaffold (Market tab)',
        builder: (context) => _tradeScreenDefaultStory(),
      ),
      WidgetbookUseCase(
        name: 'Scaffold (mobile)',
        builder: (context) =>
            mobileViewport(context, _tradeScreenDefaultStory()),
      ),
    ],
  ),
];

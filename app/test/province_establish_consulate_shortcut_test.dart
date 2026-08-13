// Pins MAP20001 Political Establish Consulate action state + UI (Refs #4346).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Political Consulate shortcut.
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_establish_consulate.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_shortcuts.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';
const String _kGameId = 'g_consulate_shortcut';
const String _kHumanPlayerId = 'gp1';
const String _kMinorId = 'minor1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|s1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1')],
);

Game _buildGame({
  required String? ownerId,
  bool diplomaticExpertise = true,
  int treasury = 1000,
  bool asMinor = true,
  OvertureStage? overtureStage,
}) {
  return Game(
    id: _kGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: ownerId,
            townTileKey: _kTileKey,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {_kTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTileKey],
        },
      },
      playerVisibilityByTile: {
        _kHumanPlayerId: {_kTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: _kHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _kProvinceId,
        treasury: treasury,
        techUnlocked: {
          if (diplomaticExpertise) kTechIdDiplomaticExpertise: true,
        },
      ),
    ],
    minorNations: [
      if (asMinor && ownerId != null)
        MinorNation(id: ownerId, displayName: 'Minor One'),
    ],
    tribes: const [],
    overtureStates: [
      if (overtureStage != null && ownerId != null)
        OvertureState(
          gpId: _kHumanPlayerId,
          targetId: ownerId,
          stage: overtureStage,
        ),
    ],
  );
}

RegionMapViewData _emptyRegion() => const RegionMapViewData(
  regionId: 'oldWorld',
  width: 1,
  height: 1,
  cellSize: 16,
  cells: [],
  capitalMarkers: [],
  portMarkers: [],
  factionColors: {},
  greatPowerFactionIds: {},
  terrainColors: {},
  provincePoliticalOwnerByPrefixedProvinceId: {},
);

void main() {
  suppressLogsForTests();

  group('Establish Consulate action state', () {
    test('shows enabled when gate applies and probe accepts', () {
      final game = _buildGame(ownerId: _kMinorId);
      final state =
          GameMapAreaStateLogicProvinceActions.provinceEstablishConsulateActionState(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isTrue);
      expect(state.enabled, isTrue);
      expect(state.pending, isFalse);
      expect(state.ownerId, _kMinorId);
      expect(state.order?.overtureStage, OvertureStage.tradeConsulate);
    });

    test('hides when Consulate already held', () {
      final game = _buildGame(
        ownerId: _kMinorId,
        overtureStage: OvertureStage.tradeConsulate,
      );
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isFalse);
    });

    test('hides for human-owned province', () {
      final game = _buildGame(ownerId: _kHumanPlayerId, asMinor: false);
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isFalse);
    });

    test('pending Consulate order enables Cancel path', () {
      final game = _buildGame(ownerId: _kMinorId);
      final pending = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: _kMinorId,
        overtureStage: OvertureStage.tradeConsulate,
      );
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: Orders(
          diplomaticOrdersByPlayerId: {
            _kHumanPlayerId: [pending],
          },
        ),
      );
      expect(state.showControl, isTrue);
      expect(state.enabled, isTrue);
      expect(state.pending, isTrue);
    });

    test('disabled when Diplomatic Expertise missing', () {
      final game = _buildGame(ownerId: _kMinorId, diplomaticExpertise: false);
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isTrue);
      expect(state.enabled, isFalse);
      expect(state.rejectionReason, isNotEmpty);
    });
  });

  group('shortcut callback emit', () {
    test('enabled tap emits ConfirmDialogEvent then Append on confirm', () async {
      final game = _buildGame(ownerId: _kMinorId);
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final confirmFuture = bus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final order = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: _kMinorId,
        overtureStage: OvertureStage.tradeConsulate,
      );
      final callbacks = buildProvinceDetailShortcutCallbacks(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        region: _emptyRegion(),
        playerView: buildPlayerView(game, _topology, _kHumanPlayerId),
        workTargetSelectionCache:
            PerPlayerWorkTargetSelectionCache(strategies: const {}),
        draftOrders: const Orders(),
        mapData: (
          combinedTopology: _topology,
          tileMapByRegion: const {},
          topologyByRegion: const {},
          warpLinks: null,
        ),
        selectedTileKey: _kTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        provinceId: _kProvinceId,
        upgradeTownEnabled: false,
        upgradeTownTargetTileKey: null,
        establishConsulateEnabled: true,
        establishConsulatePending: false,
        establishConsulateOrder: order,
        establishConsulateTargetName: 'Minor One',
        bus: bus,
      );
      expect(callbacks.onEstablishConsulateTap, isNotNull);
      callbacks.onEstablishConsulateTap!();
      final confirm = await confirmFuture;
      confirm.result(true);
      final append = await appendFuture;
      expect(append.order.targetFactionId, _kMinorId);
      expect(append.order.overtureStage, OvertureStage.tradeConsulate);
    });

    test('pending tap emits RemoveDiplomaticOrderRequestedEvent', () async {
      final game = _buildGame(ownerId: _kMinorId);
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final order = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: _kMinorId,
        overtureStage: OvertureStage.tradeConsulate,
      );
      final callbacks = buildProvinceDetailShortcutCallbacks(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        region: _emptyRegion(),
        playerView: buildPlayerView(game, _topology, _kHumanPlayerId),
        workTargetSelectionCache:
            PerPlayerWorkTargetSelectionCache(strategies: const {}),
        draftOrders: Orders(
          diplomaticOrdersByPlayerId: {
            _kHumanPlayerId: [order],
          },
        ),
        mapData: (
          combinedTopology: _topology,
          tileMapByRegion: const {},
          topologyByRegion: const {},
          warpLinks: null,
        ),
        selectedTileKey: _kTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        provinceId: _kProvinceId,
        upgradeTownEnabled: false,
        upgradeTownTargetTileKey: null,
        establishConsulateEnabled: true,
        establishConsulatePending: true,
        establishConsulateOrder: order,
        establishConsulateTargetName: 'Minor One',
        bus: bus,
      );
      expect(callbacks.onEstablishConsulateTap, isNotNull);
      callbacks.onEstablishConsulateTap!();
      final remove = await removeFuture;
      expect(remove.targetFactionId, _kMinorId);
      expect(remove.type, DiplomaticOrderType.establishOverture);
    });
  });

  group('Political Establish Consulate widget', () {
    testWidgets('renders Establish Consulate under Owner when shown', (
      tester,
    ) async {
      final l10n = AppLocalizationsEn();
      final game = _buildGame(ownerId: _kMinorId);
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          showEstablishConsulateControl: true,
          establishConsulateEnabled: true,
          onEstablishConsulateTap: () {},
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_establishConsulateAction),
        findsOneWidget,
      );
      expect(find.textContaining('No consulate with'), findsOneWidget);
    });

    testWidgets('pending shows Cancel label', (tester) async {
      final l10n = AppLocalizationsEn();
      final game = _buildGame(ownerId: _kMinorId);
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          showEstablishConsulateControl: true,
          establishConsulateEnabled: true,
          establishConsulatePending: true,
          onEstablishConsulateTap: () {},
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_cancelEstablishConsulateAction),
        findsOneWidget,
      );
    });

    testWidgets('hidden when control flag false', (tester) async {
      final l10n = AppLocalizationsEn();
      final game = _buildGame(ownerId: _kHumanPlayerId, asMinor: false);
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_establishConsulateAction),
        findsNothing,
      );
    });

    testWidgets('narrow disabled shows inline rejection reason', (
      tester,
    ) async {
      final game = _buildGame(ownerId: _kMinorId);
      const reason = 'Need Diplomatic Expertise';
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: buildProvinceOverlayDarkThemeShell(
            game: game,
            displayId: _kProvinceId,
            selectedTileKey: _kTileKey,
            showEstablishConsulateControl: true,
            establishConsulateEnabled: false,
            establishConsulateRejectionReason: reason,
          ),
        ),
      );
      expect(find.text(reason), findsOneWidget);
      final btn = find.byType(CtActionTextButton);
      expect(btn, findsOneWidget);
    });
  });
}

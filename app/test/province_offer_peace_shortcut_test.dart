// Pins MAP20001 Political owner standing + Offer Peace (Refs #4479).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Political standing / Offer Peace.
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_offer_peace.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_shortcuts.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart'
    show kDiplomacyAllianceBadgeLabel;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';
import 'province_overlay_test_harness.dart';

const String _kGameId = 'g_offer_peace_shortcut';
const String _kHumanPlayerId = 'gp1';
const String _kRivalId = 'gp2';
const String _kProvinceId = 'oldWorld|p_rival';
const String _kTileKey = 'oldWorld|p_rival|0|0';

final MapTopology _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p_rival',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p_human',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game _buildGame({
  required String ownerId,
  RelationState relationState = RelationState.atPeace,
  bool formalAlliance = false,
  bool includeRelation = true,
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
          const Province(
            id: 'oldWorld|p_human',
            regionId: 'oldWorld',
            ownerId: _kHumanPlayerId,
            townTileKey: 'oldWorld|p_human|0|0',
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: const [
      Player(
        id: _kHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p_human',
        treasury: 5000,
      ),
      Player(
        id: _kRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: _kProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
    diplomacyRelations: includeRelation
        ? [
            DiplomacyRelation(
              factionId1: _kHumanPlayerId,
              factionId2: _kRivalId,
              state: relationState,
              formalAlliance: formalAlliance,
              score: formalAlliance ? 90 : 50,
            ),
          ]
        : const [],
  );
}

void main() {
  suppressLogsForTests();

  group('Owner standing / Offer Peace action state', () {
    test('at war shows standing and Offer Peace when probe accepts', () {
      final game = _buildGame(
        ownerId: _kRivalId,
        relationState: RelationState.atWar,
      );
      final state =
          GameMapAreaStateLogicProvinceActions.provinceOfferPeaceActionState(
            game: game,
            humanPlayerId: _kHumanPlayerId,
            provinceId: _kProvinceId,
            topology: _topology,
            currentOrders: const Orders(),
            isSeaZone: false,
          );
      expect(state.showStanding, isTrue);
      expect(state.atWar, isTrue);
      expect(state.showOfferPeaceControl, isTrue);
      expect(state.offerPeaceEnabled, isTrue);
      expect(state.offerPeacePending, isFalse);
      expect(state.order?.type, DiplomaticOrderType.offerPeace);
    });

    test('at peace shows standing without Offer Peace', () {
      final game = _buildGame(ownerId: _kRivalId);
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isTrue);
      expect(state.atWar, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
      expect(state.showAllianceBadge, isFalse);
    });

    test('formal alliance shows ALLIANCE badge at peace', () {
      final game = _buildGame(ownerId: _kRivalId, formalAlliance: true);
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isTrue);
      expect(state.showAllianceBadge, isTrue);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('hides when own province', () {
      final game = _buildGame(ownerId: _kHumanPlayerId);
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: 'oldWorld|p_human',
        topology: _topology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('hides when no DiplomacyRelation', () {
      final game = _buildGame(ownerId: _kRivalId, includeRelation: false);
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('hides when sea-zone context', () {
      final game = _buildGame(
        ownerId: _kRivalId,
        relationState: RelationState.atWar,
      );
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
        isSeaZone: true,
      );
      expect(state.showStanding, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('pending offerPeace enables Cancel path', () {
      final game = _buildGame(
        ownerId: _kRivalId,
        relationState: RelationState.atWar,
      );
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(
          diplomaticOrdersByPlayerId: {
            _kHumanPlayerId: [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: _kRivalId,
              ),
            ],
          },
        ),
        isSeaZone: false,
      );
      expect(state.showOfferPeaceControl, isTrue);
      expect(state.offerPeaceEnabled, isTrue);
      expect(state.offerPeacePending, isTrue);
    });
  });

  group('Offer Peace shortcut callbacks', () {
    test('enabled tap emits confirm then append', () async {
      final bus = AppEventBus();
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: _kRivalId,
      );
      final game = _buildGame(
        ownerId: _kRivalId,
        relationState: RelationState.atWar,
      );
      final confirmFuture = bus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final callbacks = buildProvinceDetailShortcutCallbacks(
        game: game,
        humanPlayerId: _kHumanPlayerId,
        region: provinceDetailEmptyRegion(),
        playerView: provinceDetailPlayerView(game),
        workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(
          strategies: const {},
        ),
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
        buildRailEnabled: false,
        purchaseLandEnabled: false,
        provinceId: _kProvinceId,
        upgradeTownEnabled: false,
        upgradeTownTargetTileKey: null,
        establishConsulateEnabled: false,
        establishConsulatePending: false,
        establishConsulateOrder: null,
        establishConsulateTargetName: '',
        isSeaZone: false,
        offerPeaceEnabled: true,
        offerPeacePending: false,
        offerPeaceOrder: order,
        offerPeaceTargetName: 'Rival',
        bus: bus,
      );
      expect(callbacks.onOfferPeaceTap, isNotNull);
      callbacks.onOfferPeaceTap!();
      final confirm = await confirmFuture;
      confirm.result(true);
      final append = await appendFuture;
      expect(append.order.type, DiplomaticOrderType.offerPeace);
    });

    test('pending tap emits remove only', () async {
      final bus = AppEventBus();
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: _kRivalId,
      );
      final game = _buildGame(
        ownerId: _kRivalId,
        relationState: RelationState.atWar,
      );
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final callbacks = provinceDetailCallbacks(
        game: game,
        selectedTileKey: _kTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        offerPeaceEnabled: true,
        offerPeacePending: true,
        offerPeaceOrder: order,
        offerPeaceTargetName: 'Rival',
        bus: bus,
      );
      callbacks.onOfferPeaceTap!();
      final remove = await removeFuture;
      expect(remove.type, DiplomaticOrderType.offerPeace);
      expect(remove.targetFactionId, _kRivalId);
    });
  });

  group('Political standing / Offer Peace widget', () {
    testWidgets('renders At war and Offer Peace when shown', (tester) async {
      final game = _buildGame(
        ownerId: _kRivalId,
        relationState: RelationState.atWar,
      );
      final l10n = AppLocalizationsEn();
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          omniscientDetail: true,
          showOwnerStanding: true,
          ownerStandingAtWar: true,
          showOfferPeaceControl: true,
          offerPeaceEnabled: true,
          onOfferPeaceTap: () {},
        ),
      );
      await tester.pump();
      expect(find.text(l10n.provinceOverlay_ownerStandingAtWar), findsOneWidget);
      expect(find.text(l10n.provinceOverlay_offerPeaceAction), findsOneWidget);
      expect(find.text('AT_WAR'), findsNothing);
    });

    testWidgets('renders At peace without Offer Peace; ALLIANCE when allied', (
      tester,
    ) async {
      final game = _buildGame(ownerId: _kRivalId, formalAlliance: true);
      final l10n = AppLocalizationsEn();
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          omniscientDetail: true,
          showOwnerStanding: true,
          ownerStandingAtWar: false,
          showOwnerAllianceBadge: true,
          showOfferPeaceControl: false,
        ),
      );
      await tester.pump();
      expect(
        find.text(l10n.provinceOverlay_ownerStandingAtPeace),
        findsOneWidget,
      );
      expect(find.text(l10n.provinceOverlay_offerPeaceAction), findsNothing);
      expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
    });

    testWidgets('pending shows Cancel', (tester) async {
      final game = _buildGame(
        ownerId: _kRivalId,
        relationState: RelationState.atWar,
      );
      final l10n = AppLocalizationsEn();
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          omniscientDetail: true,
          showOwnerStanding: true,
          ownerStandingAtWar: true,
          showOfferPeaceControl: true,
          offerPeaceEnabled: true,
          offerPeacePending: true,
          onOfferPeaceTap: () {},
        ),
      );
      await tester.pump();
      expect(
        find.text(l10n.provinceOverlay_cancelOfferPeaceAction),
        findsOneWidget,
      );
    });
  });
}

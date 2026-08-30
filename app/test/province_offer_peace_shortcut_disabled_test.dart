// Pins MAP20001 Political Offer Peace disabled + unclaimed hide (Refs #4479).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Offer Peace disabled / hide.
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_offer_peace.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show grantAidAmountStep;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';
import 'province_overlay_test_harness.dart';

const String _kGameId = 'g_offer_peace_disabled';
const String _kHumanPlayerId = 'gp1';
const String _kRivalId = 'gp2';
const String _kProvinceId = 'oldWorld|p_rival';
const String _kTileKey = 'oldWorld|p_rival|0|0';
const String _kExclusivityReason =
    'Already have a diplomatic order for this faction this turn';

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
  String? ownerId = _kRivalId,
  RelationState relationState = RelationState.atPeace,
  bool includeRelation = true,
  bool embassy = false,
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
              score: 20,
            ),
          ]
        : const [],
    overtureStates: embassy
        ? const [
            OvertureState(
              gpId: _kHumanPlayerId,
              targetId: _kRivalId,
              stage: OvertureStage.embassy,
            ),
          ]
        : const [],
  );
}

Orders _pendingGrantAid() => Orders(
  diplomaticOrdersByPlayerId: {
    _kHumanPlayerId: [
      DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: _kRivalId,
        amount: grantAidAmountStep,
      ),
    ],
  },
);

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('Owner standing / Offer Peace hide and disabled state', () {
    test('hides when ownerId is null (unclaimed)', () {
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: _buildGame(ownerId: null, relationState: RelationState.atWar),
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state, GameMapAreaProvinceActionStatesOfferPeace.hidden);
    });

    test('hides when ownerId is empty (unowned)', () {
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: _buildGame(ownerId: '', relationState: RelationState.atWar),
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state, GameMapAreaProvinceActionStatesOfferPeace.hidden);
    });

    test('pending grantAid disables Offer Peace with exclusivity reason', () {
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: _buildGame(
          ownerId: _kRivalId,
          relationState: RelationState.atWar,
          embassy: true,
        ),
        humanPlayerId: _kHumanPlayerId,
        provinceId: _kProvinceId,
        topology: _topology,
        currentOrders: _pendingGrantAid(),
        isSeaZone: false,
      );
      expect(state.showStanding, isTrue);
      expect(state.atWar, isTrue);
      expect(state.showOfferPeaceControl, isTrue);
      expect(state.offerPeaceEnabled, isFalse);
      expect(state.offerPeacePending, isFalse);
      expect(state.rejectionReason, _kExclusivityReason);
    });
  });

  group('Offer Peace disabled callbacks', () {
    test('disabled tap callback is null so no order is staged', () {
      final bus = AppEventBus();
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: _kRivalId,
      );
      final callbacks = provinceDetailCallbacks(
        game: _buildGame(
          ownerId: _kRivalId,
          relationState: RelationState.atWar,
        ),
        selectedTileKey: _kTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        offerPeaceEnabled: false,
        offerPeacePending: false,
        offerPeaceOrder: order,
        offerPeaceTargetName: 'Rival',
        combinedTopology: _topology,
        bus: bus,
      );
      expect(callbacks.onOfferPeaceTap, isNull);
    });
  });

  group('Political Offer Peace disabled widget', () {
    testWidgets(
      'narrow disabled shows tooltip, semantics, inline reason; tap stages nothing',
      (tester) async {
        await pumpProvinceOverlayAtDarkTheme(
          tester,
          game: _buildGame(
            ownerId: _kRivalId,
            relationState: RelationState.atWar,
          ),
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          omniscientDetail: true,
          showOwnerStanding: true,
          ownerStandingAtWar: true,
          showOfferPeaceControl: true,
          offerPeaceEnabled: false,
          offerPeaceRejectionReason: _kExclusivityReason,
          onOfferPeaceTap: () {},
          shellWidth: 360,
          viewport: const Size(360, 640),
        );
        final button = tester.widget<CtActionTextButton>(
          find.widgetWithText(
            CtActionTextButton,
            l10n.provinceOverlay_offerPeaceAction,
          ),
        );
        expect(button.enabled, isFalse);
        expect(button.onPressed, isNull);
        expect(button.tooltip, _kExclusivityReason);
        expect(button.semanticLabel, contains(_kExclusivityReason));
        expect(find.text(_kExclusivityReason), findsOneWidget);
      },
    );
  });
}

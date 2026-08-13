import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_establish_consulate.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';

const _humanId = 'gp1';
const _minorId = 'minor1';
const _provinceId = 'oldWorld|p1';
const _tileKey = 'oldWorld|p1|0|0';
const _topology = MapTopology();

Game _game({
  bool expertise = true,
  int treasury = 5000,
  String? ownerId = _minorId,
  List<OvertureState> overtures = const [],
}) {
  return Game(
    id: 'consulate-overlay',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: _provinceId, regionId: 'oldWorld', ownerId: ownerId),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          _provinceId: [_tileKey],
        },
      },
      playerVisibilityByTile: const {
        _humanId: {_tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: _humanId,
        displayName: 'Human',
        isHuman: true,
        treasury: treasury,
        techUnlocked: expertise
            ? const {kTechIdDiplomaticExpertise: true}
            : const {},
      ),
    ],
    minorNations: const [MinorNation(id: _minorId, displayName: 'Bavaria')],
    tribes: const [],
    overtureStates: overtures,
  );
}

RegionMapViewData _region() => RegionMapViewData(
  regionId: 'oldWorld',
  width: 1,
  height: 1,
  cellSize: 16,
  cells: const [
    CellViewData(
      x: 0,
      y: 0,
      regionCellId: 'p1',
      isSea: false,
      terrainType: TerrainType.hills,
      ownerFactionId: _minorId,
      provinceDisplayName: 'Bavaria',
      visibility: TileVisibility.visible,
    ),
  ],
  capitalMarkers: const [],
  portMarkers: const [],
  factionColors: const {},
  greatPowerFactionIds: const {_humanId},
  terrainColors: const {},
  provincePoliticalOwnerByPrefixedProvinceId: const {_provinceId: _minorId},
);

Orders _pendingOrders() => const Orders(
  diplomaticOrdersByPlayerId: {
    _humanId: [
      DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: _minorId,
        overtureStage: OvertureStage.tradeConsulate,
      ),
    ],
  },
);

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  test(
    'state is enabled, disabled with validator reason, pending, and hidden',
    () {
      final enabled = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: _game(),
        humanPlayerId: _humanId,
        provinceId: _provinceId,
        topology: _topology,
        currentOrders: const Orders(),
      );
      expect(enabled.showControl, isTrue);
      expect(enabled.enabled, isTrue);
      expect(enabled.pending, isFalse);

      final disabled =
          GameMapAreaProvinceActionStatesEstablishConsulate.compute(
            game: _game(expertise: false),
            humanPlayerId: _humanId,
            provinceId: _provinceId,
            topology: _topology,
            currentOrders: const Orders(),
          );
      expect(disabled.showControl, isTrue);
      expect(disabled.enabled, isFalse);
      expect(disabled.rejectionReason, contains('Diplomatic Expertise'));

      final pending = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: _game(),
        humanPlayerId: _humanId,
        provinceId: _provinceId,
        topology: _topology,
        currentOrders: _pendingOrders(),
      );
      expect(pending.pending, isTrue);
      expect(pending.enabled, isTrue);

      for (final game in [
        _game(ownerId: _humanId),
        _game(ownerId: null),
        _game(
          overtures: const [
            OvertureState(
              gpId: _humanId,
              targetId: _minorId,
              stage: OvertureStage.tradeConsulate,
            ),
          ],
        ),
      ]) {
        final hidden =
            GameMapAreaProvinceActionStatesEstablishConsulate.compute(
              game: game,
              humanPlayerId: _humanId,
              provinceId: _provinceId,
              topology: _topology,
              currentOrders: const Orders(),
            );
        expect(hidden.showControl, isFalse);
      }
    },
  );

  testWidgets('disabled Political control exposes reason inline and semantics', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 640));
    final game = _game(expertise: false);
    const reason =
        'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes';
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      region: _region(),
      displayId: _provinceId,
      selectedTileKey: _tileKey,
      playerView: buildPlayerView(game, _topology, _humanId),
      shellWidth: 360,
      viewport: const Size(360, 640),
      showEstablishConsulateControl: true,
      establishConsulateEnabled: false,
      establishConsulateRejectionReason: reason,
    );

    final button = tester.widget<CtActionTextButton>(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_establishConsulateAction,
      ),
    );
    expect(button.enabled, isFalse);
    expect(button.tooltip, reason);
    expect(button.semanticLabel, contains(reason));
    expect(find.text(reason), findsOneWidget);
  });

  testWidgets('pending Political control reads Cancel', (tester) async {
    final game = _game();
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      region: _region(),
      displayId: _provinceId,
      selectedTileKey: _tileKey,
      playerView: buildPlayerView(game, _topology, _humanId),
      showEstablishConsulateControl: true,
      establishConsulateEnabled: true,
      establishConsulatePending: true,
    );
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_cancelEstablishConsulateAction,
      ),
      findsOneWidget,
    );
  });

  testWidgets('narrow gated Tile tooltip names Political Establish Consulate', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 640));
    final game = _game();
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      region: _region(),
      displayId: _provinceId,
      selectedTileKey: _tileKey,
      playerView: buildPlayerView(game, _topology, _humanId),
      shellWidth: 360,
      viewport: const Size(360, 640),
      showExploreActionIcon: true,
      exploreActionEnabled: false,
    );
    await tester.tap(find.text(l10n.provinceOverlay_sectionTile));
    await tester.pump();
    final action = tester.widget<CtIconAction>(find.byType(CtIconAction).first);
    expect(action.tooltip, contains('Political'));
    expect(action.tooltip, contains('Establish Consulate'));
  });
}

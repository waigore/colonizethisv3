// Visual goldens for MAP20001 Political owner standing + Offer Peace
// (Refs #4479). SPEC/ui/province-sea-zone-detail-overlay.md § States and variants.

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart'
    show kDiplomacyAllianceBadgeLabel;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TerrainType;
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const String _kHumanId = 'gp1';
const String _kRivalId = 'gp2';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

class _StandingGoldenCase {
  const _StandingGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showStanding,
    this.atWar = false,
    this.showAlliance = false,
    this.showOfferPeace = false,
    this.offerPeaceEnabled = false,
    this.offerPeacePending = false,
  });

  final String name;
  final String goldenFile;
  final bool showStanding;
  final bool atWar;
  final bool showAlliance;
  final bool showOfferPeace;
  final bool offerPeaceEnabled;
  final bool offerPeacePending;
}

const List<_StandingGoldenCase> _wideCases = [
  _StandingGoldenCase(
    name: 'at war Offer Peace enabled',
    goldenFile: 'goldens/province_overlay_owner_standing_at_war.png',
    showStanding: true,
    atWar: true,
    showOfferPeace: true,
    offerPeaceEnabled: true,
  ),
  _StandingGoldenCase(
    name: 'at war Offer Peace pending',
    goldenFile: 'goldens/province_overlay_owner_standing_pending.png',
    showStanding: true,
    atWar: true,
    showOfferPeace: true,
    offerPeaceEnabled: true,
    offerPeacePending: true,
  ),
  _StandingGoldenCase(
    name: 'at peace',
    goldenFile: 'goldens/province_overlay_owner_standing_at_peace.png',
    showStanding: true,
  ),
  _StandingGoldenCase(
    name: 'at peace ALLIANCE',
    goldenFile: 'goldens/province_overlay_owner_standing_alliance.png',
    showStanding: true,
    showAlliance: true,
  ),
  _StandingGoldenCase(
    name: 'hidden own',
    goldenFile: 'goldens/province_overlay_owner_standing_hidden.png',
    showStanding: false,
  ),
];

Game _rivalOwnedGame() {
  return Game(
    id: 'g_standing_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kRivalId,
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
        _kHumanId: {_kTileKey: 'fullyVisible'},
      },
    ),
    players: const [
      Player(
        id: _kHumanId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: '',
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
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: _kHumanId,
        factionId2: _kRivalId,
        state: RelationState.atWar,
        score: 20,
      ),
    ],
  );
}

RegionMapViewData _region() {
  return const RegionMapViewData(
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
        ownerFactionId: _kRivalId,
        provinceDisplayName: 'Rival Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: [],
    portMarkers: [],
    factionColors: {},
    greatPowerFactionIds: {_kHumanId, _kRivalId},
    terrainColors: {},
    provincePoliticalOwnerByPrefixedProvinceId: {_kProvinceId: _kRivalId},
  );
}

Future<void> _pumpStandingGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size surface,
  required Size overlaySize,
  required _StandingGoldenCase c,
}) async {
  await configureGoldenSurface(tester, size: surface);
  configureGoldenView(tester, physicalSize: surface, devicePixelRatio: 1.0);
  final game = _rivalOwnedGame();
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: _region(),
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          humanPlayerId: _kHumanId,
          playerView: buildPlayerView(game, const MapTopology(), _kHumanId),
          omniscientDetail: true,
          showOwnerStanding: c.showStanding,
          ownerStandingAtWar: c.atWar,
          showOwnerAllianceBadge: c.showAlliance,
          showOfferPeaceControl: c.showOfferPeace,
          offerPeaceEnabled: c.offerPeaceEnabled,
          offerPeacePending: c.offerPeacePending,
          onOfferPeaceTap: () {},
          onClose: () {},
        ),
      ),
    ),
  );
  await pumpForGolden(tester);
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _wideCases) {
    testWidgets('golden: ${c.name} (Refs #4479)', (WidgetTester tester) async {
      final boundaryKey = ValueKey<String>(
        'province_standing_${c.name}_golden',
      );
      await _pumpStandingGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(640, 720),
        overlaySize: const Size(460, 680),
        c: c,
      );
      expect(tester.takeException(), isNull);
      if (c.showStanding) {
        expect(
          find.text(
            c.atWar
                ? l10n.provinceOverlay_ownerStandingAtWar
                : l10n.provinceOverlay_ownerStandingAtPeace,
          ),
          findsOneWidget,
        );
      }
      if (c.showAlliance) {
        expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
      }
      if (c.showOfferPeace) {
        final finder = find.widgetWithText(
          CtActionTextButton,
          c.offerPeacePending
              ? l10n.provinceOverlay_cancelOfferPeaceAction
              : l10n.provinceOverlay_offerPeaceAction,
        );
        expect(finder, findsOneWidget);
        await tester.ensureVisible(finder);
        await tester.pump();
      }
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }

  testWidgets(
    'golden: standing + Offer Peace wraps at 320 dp (Refs #4479)',
    (WidgetTester tester) async {
      const c = _StandingGoldenCase(
        name: 'at war 320',
        goldenFile: 'goldens/province_overlay_owner_standing_at_war_320.png',
        showStanding: true,
        atWar: true,
        showOfferPeace: true,
        offerPeaceEnabled: true,
      );
      const boundaryKey = ValueKey<String>('province_standing_320_golden');
      await _pumpStandingGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(320, 720),
        overlaySize: const Size(300, 680),
        c: c,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.provinceOverlay_ownerStandingAtWar), findsOneWidget);
      expect(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_offerPeaceAction,
        ),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    },
  );
}

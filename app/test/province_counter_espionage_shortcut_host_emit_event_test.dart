// Pins host-level MAP20001 Counter-espionage tap → OpenCivilianUnitsPanelEvent (Refs #4528).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_counter_espionage_action_state.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'province_shortcut_host_emit_test_support.dart';

const _kGameId = 'g_counter_espionage_emit';
const _kHuman = kProvinceShortcutHostHumanPlayerId;
const _kProvince = kProvinceShortcutHostOldWorldProvinceId;
const _kSpyTile = kProvinceShortcutHostTileKey;
const _kTargetTile = kProvinceShortcutHostSecondTileKey;
const _kProvinceLevelKey = kProvinceShortcutHostTileKey;
final _maps = provinceShortcutHostTwoTileMaps();
final _region = provinceShortcutHostTwoTileRegionView();
final _l10n = AppLocalizationsEn();

ProvinceShortcutHostCase _hostWithoutTileTab(ProvinceShortcutHostCase host) => (
  label: host.label,
  hostType: host.hostType,
  surfaceSize: host.surfaceSize,
  selectTileTab: false,
  wide: host.wide,
);

Game _buildGame({required bool withSpy}) => Game(
  id: _kGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: _kProvince, regionId: 'oldWorld', ownerId: _kHuman)],
      units: [
        if (withSpy)
          Unit(
            id: 'u_spy',
            type: kUnitTypeSpy,
            ownerId: _kHuman,
            locationProvinceId: _kProvince,
            tileKey: _kSpyTile,
            status: UnitStatus.idle,
          ),
      ],
    ),
    newWorld: const RegionData(provinces: [], units: []),
    resourceByTileKey: const {_kSpyTile: 'grain', _kTargetTile: 'grain'},
    tileKeysByRegionAndProvince: {
      'oldWorld': {_kProvince: [_kSpyTile, _kTargetTile]},
    },
    playerVisibilityByTile: {
      _kHuman: {_kSpyTile: 'fullyVisible', _kTargetTile: 'fullyVisible'},
    },
  ),
  players: [Player(id: _kHuman, displayName: 'Human', isHuman: true)],
);

void main() {
  suppressLogsForTests();
  late Box<dynamic> gamesBox;
  late ProvinceShortcutHostEmitPump pumpHost;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_counter_espionage_shortcut_emit');
  });

  setUp(() {
    pumpHost = ProvinceShortcutHostEmitPump(
      gamesBox: gamesBox,
      gameId: _kGameId,
      humanPlayerId: _kHuman,
      maps: _maps,
      region: _region,
      selectedTileKey: _kTargetTile,
    );
  });

  test('counter-espionage action state is enabled for host wiring', () {
    final resolved = computeProvinceCounterEspionageActionState(
      game: _buildGame(withSpy: true),
      orders: const Orders(),
      humanPlayerId: _kHuman,
      displayId: _kProvince,
      canMutateViaUi: true,
      isSeaZone: false,
      civilianSectionObfuscated: false,
    );
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isTrue);
  });

  Finder counterEspionageButton() =>
      find.widgetWithText(CtActionTextButton, _l10n.provinceOverlay_counterEspionageAction);

  for (final host in provinceShortcutHostCases) {
    testWidgets('${host.label} Counter-espionage emits spyOnly Assign shortcut', (tester) async {
      final opened = await pumpHost(
        tester,
        game: _buildGame(withSpy: true),
        host: _hostWithoutTileTab(host),
      );
      await revealProvinceShortcutCivilianTab(tester, wide: host.wide);
      final button = counterEspionageButton();
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(opened, hasLength(1));
      final event = opened.single;
      expect(event.spyOnly, isTrue);
      expect(event.counterSpyShortcutTargetTileKey, _kProvinceLevelKey);
      expect(event.relocateShortcutTargetTileKey, isNull);
      expect(event.explorerOnly, isFalse);
    });

    testWidgets('${host.label} without a Spy does not emit event', (tester) async {
      final opened = await pumpHost(
        tester,
        game: _buildGame(withSpy: false),
        host: _hostWithoutTileTab(host),
      );
      await revealProvinceShortcutCivilianTab(tester, wide: host.wide);
      final button = counterEspionageButton();
      expect(button, findsOneWidget);
      final action = tester.widget<CtActionTextButton>(button);
      expect(action.enabled, isFalse);
      expect(action.onPressed, isNull);
      expect(opened, isEmpty);
    });
  }
}

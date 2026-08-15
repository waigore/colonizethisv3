// Host goldens for Split Army detach-then-move copy (Refs #4407).
// SPEC/ui/military-units-army-management.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_army_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  setUpAll(setUpNinePatchAssets);

  const home = Army(
    id: 'home',
    ownerId: 'gp1',
    regionId: 'oldWorld',
    stationedProvinceId: 'oldWorld|cap',
    regimentUnitIds: ['u1'],
    isHomeArmy: true,
  );

  Game game() => Game(
    id: 'g_detach_split_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            ownerId: 'gp1',
            displayName: 'Capital',
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|cap',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [home],
    ),
    players: const [Player(id: 'gp1', displayName: 'Human', isHuman: true)],
  );

  Future<void> pumpDetachSplit({
    required WidgetTester tester,
    required Key boundaryKey,
    required Size size,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: size,
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: SplitArmyDialog(
        army: home,
        game: game(),
        humanPlayerId: 'gp1',
        bus: AppEventBus(),
        isHomeArmy: true,
        title: l10n.splitArmy_detachTitle,
        confirmLabel: l10n.splitArmy_detachConfirm,
      ),
    );
  }

  testWidgets('golden: detach Split Army title and confirm (Refs #4407)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('homeArmyDetachSplitGolden');
    await pumpDetachSplit(
      tester: tester,
      boundaryKey: boundaryKey,
      size: const Size(520, 640),
    );
    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text(l10n.splitArmy_detachTitle), findsOneWidget);
    expect(find.text(l10n.splitArmy_detachConfirm), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/home_army_detach_split.png'),
    );
  });

  testWidgets('golden: detach Split Army wraps at 320 dp (Refs #4407)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('homeArmyDetachSplit320Golden');
    await pumpDetachSplit(
      tester: tester,
      boundaryKey: boundaryKey,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.splitArmy_detachConfirm), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/home_army_detach_split_320dp.png'),
    );
  });
}

// Widget pins for MAP20001 Naval Combine (Refs #4659).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_combine_overlay_controls.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_fleet_combine.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart' show homeFleetIdFor;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  ProvinceSeaZoneDetailOverlay overlay({
    required bool show,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final game = demoGameForOverlay;
    return ProvinceSeaZoneDetailOverlay(
      game: game,
      region: demoRegionForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      omniscientDetail: true,
      navalCombine: ProvinceNavalCombineOverlayControls(
        showCombineFleets: show,
        combineFleetsEnabled: enabled,
        combineFleetsTooltip: enabled
            ? l10n.provinceOverlay_combineFleetsAction
            : l10n.provinceOverlay_combineFleetsPendingOrderTooltip,
        onCombineFleetsTap: onTap,
      ),
      onClose: () {},
    );
  }

  testWidgets('enabled Combine is visible', (tester) async {
    await tester.pumpWidget(wrap(overlay(show: true, enabled: true)));
    await tester.pumpAndSettle();
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_combineFleetsAction,
    );
    expect(finder, findsOneWidget);
    expect(tester.widget<CtActionTextButton>(finder).enabled, isTrue);
  });

  testWidgets('hidden Combine is absent', (tester) async {
    await tester.pumpWidget(wrap(overlay(show: false, enabled: false)));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_combineFleetsAction,
      ),
      findsNothing,
    );
  });

  testWidgets('disabled Combine is visible but not enabled', (tester) async {
    await tester.pumpWidget(wrap(overlay(show: true, enabled: false)));
    await tester.pumpAndSettle();
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_combineFleetsAction,
    );
    expect(tester.widget<CtActionTextButton>(finder).enabled, isFalse);
  });

  testWidgets('confirm emits NavalFleetsUpdatedEvent; escape does not', (
    tester,
  ) async {
    final bus = AppEventBus();
    NavalFleetsUpdatedEvent? captured;
    bus.on<NavalFleetsUpdatedEvent>().listen((e) => captured = e);
    final human = 'gp1';
    final homeId = homeFleetIdFor(human);
    final fleets = [
      Fleet(
        id: '2',
        ownerId: human,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|p1',
        ships: const [ShipInstance(id: 's2', typeId: 'carrack')],
      ),
      Fleet(
        id: homeId,
        ownerId: human,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|p1',
        ships: const [ShipInstance(id: 's1', typeId: 'fluyte')],
      ),
    ];
    final game = demoGameForOverlay.copyWith(
      worldState: demoGameForOverlay.worldState.copyWith(fleets: fleets),
    );
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showProvinceOverlayFleetCombineConfirm(
                  context: context,
                  l10n: l10n,
                  game: game,
                  fleets: fleets,
                  humanPlayerId: human,
                  bus: bus,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CtConfirmDialog), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(captured, isNull);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.common_confirm));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured!.game.worldState.fleets, hasLength(1));
    expect(captured!.game.worldState.fleets.single.id, homeId);
  });

  testWidgets('confirm merges three locality fleets into one', (tester) async {
    final bus = AppEventBus();
    NavalFleetsUpdatedEvent? captured;
    bus.on<NavalFleetsUpdatedEvent>().listen((e) => captured = e);
    const human = 'gp1';
    final fleets = [
      Fleet(
        id: 'a',
        ownerId: human,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|p1',
        ships: const [ShipInstance(id: 'sa', typeId: 'fluyte')],
      ),
      Fleet(
        id: 'b',
        ownerId: human,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|p1',
        ships: const [ShipInstance(id: 'sb', typeId: 'carrack')],
      ),
      Fleet(
        id: 'c',
        ownerId: human,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|p1',
        ships: const [ShipInstance(id: 'sc', typeId: 'galleon')],
      ),
    ];
    final game = demoGameForOverlay.copyWith(
      worldState: demoGameForOverlay.worldState.copyWith(fleets: fleets),
    );
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showProvinceOverlayFleetCombineConfirm(
                  context: context,
                  l10n: l10n,
                  game: game,
                  fleets: fleets,
                  humanPlayerId: human,
                  bus: bus,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.common_confirm));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured!.game.worldState.fleets, hasLength(1));
    expect(captured!.game.worldState.fleets.single.id, 'a');
    expect(
      captured!.game.worldState.fleets.single.ships.map((s) => s.id).toSet(),
      {'sa', 'sb', 'sc'},
    );
  });
}

// Widget pins for MAP20001 Military Combine (Refs #4610).

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_army_combine.dart';
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
      showCombineArmiesControl: show,
      combineArmiesEnabled: enabled,
      combineArmiesTooltip: enabled
          ? l10n.provinceOverlay_combineArmiesAction
          : l10n.provinceOverlay_combineArmiesPendingMarchTooltip,
      onCombineArmiesTap: onTap,
      onClose: () {},
    );
  }

  testWidgets('enabled Combine is visible', (tester) async {
    await tester.pumpWidget(wrap(overlay(show: true, enabled: true)));
    await tester.pumpAndSettle();
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_combineArmiesAction,
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
        l10n.provinceOverlay_combineArmiesAction,
      ),
      findsNothing,
    );
  });

  testWidgets('disabled Combine is visible but not enabled', (tester) async {
    await tester.pumpWidget(wrap(overlay(show: true, enabled: false)));
    await tester.pumpAndSettle();
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_combineArmiesAction,
    );
    expect(tester.widget<CtActionTextButton>(finder).enabled, isFalse);
  });

  testWidgets('confirm emits ArmyCombineRequestedEvent; escape does not', (
    tester,
  ) async {
    final bus = AppEventBus();
    ArmyCombineRequestedEvent? captured;
    bus.on<ArmyCombineRequestedEvent>().listen((e) => captured = e);
    final armies = [
      const Army(
        id: 'b',
        ownerId: 'gp1',
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|p1',
        regimentUnitIds: [],
      ),
      const Army(
        id: 'a',
        ownerId: 'gp1',
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|p1',
        regimentUnitIds: [],
      ),
    ];
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showProvinceOverlayArmyCombineConfirm(
                  context: context,
                  l10n: l10n,
                  game: demoGameForOverlay,
                  armies: armies,
                  humanPlayerId: 'gp1',
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
    expect(captured!.armyIds, ['a', 'b']);
  });
}

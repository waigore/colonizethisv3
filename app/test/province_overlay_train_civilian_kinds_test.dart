// MAP20001 Train kinds + Spy / Counter-espionage omit (Refs #4752).

import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart'
    show ProvinceActionStates;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_control.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_offer.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'widget_test_assets.dart';

const _missing = (showIcon: true, enabled: false, hasMatchingUnits: false);

Widget _overlay({
  required ProvinceActionStates actions,
  VoidCallback? onTrain,
  ProvinceOverlayStationSpyProps stationSpy = kProvinceOverlayStationSpyHidden,
  ProvinceOverlayCounterEspionageProps counterEspionage =
      kProvinceOverlayCounterEspionageHidden,
}) {
  final game = demoGameForOverlay;
  return buildAppShell(
    viewport: const Size(800, 640),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        civilianInlineActions: actions,
        inlineActionCallbacks: (
          onExploreWithExplorerTap: null,
          onProspectWithExplorerTap: null,
          onBuildImprovementTap: null,
          onBuildRoadTap: null,
          onBuildFortTap: null,
          onBuildPortTap: null,
          onBuildRailroadTap: null,
          onPurchaseLandTap: null,
          onTrainCivilianTap: onTrain,
        ),
        stationSpy: stationSpy,
        counterEspionage: counterEspionage,
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsEn();

  setUpAll(preloadNinePatchImage);

  testWidgets('Train Builder is enabled beside disabled Build improvement', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _overlay(
        actions: provinceOverlayInlineActions(buildImprovement: _missing),
        onTrain: () => opened++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainBuilderKey), findsOneWidget);
    expect(find.text(l10n.provinceOverlay_trainBuilder), findsOneWidget);
    await tester.tap(find.text(l10n.provinceOverlay_trainBuilder));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('Train Engineer is enabled beside disabled Build road', (
    tester,
  ) async {
    await tester.pumpWidget(
      _overlay(
        actions: provinceOverlayInlineActions(buildRoad: _missing),
        onTrain: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainEngineerKey), findsOneWidget);
    expect(find.text(l10n.provinceOverlay_trainEngineer), findsOneWidget);
  });

  testWidgets('Train Merchant is enabled beside disabled Purchase land', (
    tester,
  ) async {
    await tester.pumpWidget(
      _overlay(
        actions: provinceOverlayInlineActions(purchaseLand: _missing),
        onTrain: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainMerchantKey), findsOneWidget);
    expect(find.text(l10n.provinceOverlay_trainMerchant), findsOneWidget);
  });

  testWidgets('Train Explorer is enabled beside disabled Prospect', (
    tester,
  ) async {
    await tester.pumpWidget(
      _overlay(
        actions: provinceOverlayInlineActions(prospect: _missing),
        onTrain: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsOneWidget);
  });

  testWidgets('Train Rail Builder control is enabled hire chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return buildMapTrainCivilianControl(
              l10n: appL10n(context),
              kind: MapTrainCivilianKind.railBuilder,
              show: true,
              onTap: () {},
            )!;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainRailBuilderKey), findsOneWidget);
    expect(find.text(l10n.provinceOverlay_trainRailBuilder), findsOneWidget);
  });

  testWidgets('Station spy does not add Train Spy (UXD-002)', (tester) async {
    await tester.pumpWidget(
      _overlay(
        actions: provinceOverlayInlineActions(),
        onTrain: () {},
        stationSpy: (
          showControl: true,
          enabled: false,
          tooltip: l10n.provinceOverlay_stationSpyDisabledNoIdleSpyTooltip,
          gist: '',
          onTap: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.text(l10n.provinceOverlay_sectionCivilian.toUpperCase()),
    );
    await tester.pump();
    expect(find.text(l10n.provinceOverlay_stationSpyAction), findsOneWidget);
    expect(find.text('Train Spy'), findsNothing);
    for (final kind in MapTrainCivilianKind.values) {
      expect(find.byKey(mapTrainCivilianKey(kind)), findsNothing);
    }
  });

  testWidgets('Counter-espionage does not add Train Spy (UXD-002)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _overlay(
        actions: provinceOverlayInlineActions(),
        onTrain: () {},
        counterEspionage: (
          showControl: true,
          enabled: false,
          tooltip:
              l10n.provinceOverlay_counterEspionageDisabledNoIdleSpyTooltip,
          gist: l10n.provinceOverlay_counterEspionageGist,
          onTap: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.text(l10n.provinceOverlay_sectionCivilian.toUpperCase()),
    );
    await tester.pump();
    expect(
      find.text(l10n.provinceOverlay_counterEspionageAction),
      findsOneWidget,
    );
    expect(find.text('Train Spy'), findsNothing);
    for (final kind in MapTrainCivilianKind.values) {
      expect(find.byKey(mapTrainCivilianKey(kind)), findsNothing);
    }
  });
}

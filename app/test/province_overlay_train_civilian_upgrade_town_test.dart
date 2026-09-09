// MAP20001 Political Train Builder beside Upgrade town (Refs #4752).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_control.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdNationalBureaucracy;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'widget_test_assets.dart';

Game _game({required bool bureaucracy}) {
  final base = demoGameForOverlay;
  final human = base.players.first;
  return base.copyWith(
    players: [
      human.copyWith(
        techUnlocked: {
          ...?human.techUnlocked,
          kTechIdNationalBureaucracy: bureaucracy,
        },
      ),
      ...base.players.skip(1),
    ],
  );
}

Widget _overlay({
  required Game game,
  required bool hasBuilders,
  VoidCallback? onTrain,
}) {
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
        showUpgradeTownControl: true,
        upgradeTownEnabled: hasBuilders,
        upgradeTownHasBuilderUnits: hasBuilders,
        upgradeTownTargetTileKey: sampleTileKeyForProvinceOverlay,
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
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsEn();

  setUpAll(preloadNinePatchImage);

  testWidgets('Train Builder is enabled beside disabled Upgrade town', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _overlay(
        game: _game(bureaucracy: true),
        hasBuilders: false,
        onTrain: () => opened++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainBuilderKey), findsOneWidget);
    expect(find.text(l10n.provinceOverlay_trainBuilder), findsOneWidget);
    expect(
      find.textContaining('appears at your capital after Next turn'),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.provinceOverlay_trainBuilder));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('Train Builder is omitted when Builder units exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      _overlay(
        game: _game(bureaucracy: true),
        hasBuilders: true,
        onTrain: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainBuilderKey), findsNothing);
  });

  testWidgets('Train Builder is omitted when National Bureaucracy is locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _overlay(
        game: _game(bureaucracy: false),
        hasBuilders: false,
        onTrain: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainBuilderKey), findsNothing);
  });
}

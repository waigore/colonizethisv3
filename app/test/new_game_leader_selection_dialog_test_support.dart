// Shared pump / tap helpers for NewGameLeaderSelectionDialog widget tests.
// Used by `new_game_leader_selection_dialog_part1_test.dart` and
// `new_game_leader_selection_dialog_part2_test.dart` (Refs #4013).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

typedef NewGameLeaderSelectionConfirmed = void Function(
  List<String> orderedGreatPowerIds,
  Map<String, String> leaderVariantByGpId,
  int seed,
  bool infiniteMode,
  double terrainVariation,
  Map<String, String?> aiProfileByGpId,
  AdvancedStartType advancedStart,
);

/// Opens [NewGameLeaderSelectionDialog] via a MaterialApp opener button.
///
/// Defaults to [GameSetupConfig.defaultConfig] and a no-op [onConfirmed].
Future<void> pumpNewGameLeaderSelectionDialog(
  WidgetTester tester, {
  GameSetupConfig? baseConfig,
  Size surfaceSize = const Size(800, 1300),
  NewGameLeaderSelectionConfirmed? onConfirmed,
  List<String> blessedProfileNames = const [],
}) async {
  final config = baseConfig ?? GameSetupConfig.defaultConfig;
  final confirmed = onConfirmed ?? (_, _, _, _, _, _, _) {};
  addTearDown(tester.view.reset);
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  // Colonial specialization via buildAppShell theme (Refs #4035).
  await tester.pumpWidget(
    buildAppShell(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                final naming = defaultNamingConfig;
                final initial = <String, String>{};
                for (final gpId in config.selectedGreatPowerIds) {
                  final gp = naming.gpById(gpId);
                  if (gp != null && gp.leaderVariants.isNotEmpty) {
                    initial[gpId] = gp.defaultLeaderVariantId;
                  }
                }
                showDialog<void>(
                  context: context,
                  builder: (ctx) => NewGameLeaderSelectionDialog(
                    baseConfig: config,
                    naming: naming,
                    initialLeaderByGpId: initial,
                    blessedProfileNames: blessedProfileNames,
                    onCancel: () => Navigator.of(ctx).pop(),
                    onConfirmed: confirmed,
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> ensureTapNewGameLeaderSelectionStart(WidgetTester tester) async {
  final startButton = find.ancestor(
    of: find.text('Start'),
    matching: find.byType(CtNinePatchButton),
  );
  await tester.ensureVisible(startButton);
  await tester.pumpAndSettle();
  await tester.tap(startButton);
  await tester.pumpAndSettle();
}

Future<void> ensureTapNewGameLeaderSelectionCancel(WidgetTester tester) async {
  final cancelButton = find.ancestor(
    of: find.text('Cancel'),
    matching: find.byType(CtNinePatchButton),
  );
  await tester.ensureVisible(cancelButton);
  await tester.pumpAndSettle();
  await tester.tap(cancelButton);
  await tester.pumpAndSettle();
}

const Size kNewGameLeaderLargeViewport = Size(900, 2000);
const Size kNewGameLeaderDuplicateSurface = Size(900, 1600);
const List<String> kNewGameLeaderDuplicateEnglandIds = <String>[
  'england',
  'france',
  'spain',
  'portugal',
  'netherlands',
  'england',
];

GameSetupConfig get newGameLeaderDuplicateEnglandConfig =>
    GameSetupConfig(selectedGreatPowerIds: kNewGameLeaderDuplicateEnglandIds);

Future<void> enterNewGameLeaderSeed(WidgetTester tester, String value) async {
  final field = find.byType(TextField);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> tapNewGameLeaderSliderEdge(
  WidgetTester tester, {
  required bool left,
}) async {
  final slider = find.byType(CtSlider);
  await tester.ensureVisible(slider);
  await tester.pumpAndSettle();
  final rect = tester.getRect(slider);
  await tester.tapAt(
    Offset(left ? rect.left + 1 : rect.right - 1, rect.center.dy),
  );
  await tester.pumpAndSettle();
}

CtNinePatchButton newGameLeaderStartButton(WidgetTester tester) {
  return tester.widget<CtNinePatchButton>(
    find.ancestor(
      of: find.text('Start'),
      matching: find.byType(CtNinePatchButton),
    ),
  );
}

void expectNewGameLeaderDialogChromeTexts(Iterable<String> texts) {
  for (final text in texts) {
    expect(find.text(text), findsOneWidget);
  }
}

Finder newGameLeaderKeyedFinder(String key) => find.byKey(ValueKey<String>(key));

Text newGameLeaderKeyedText(WidgetTester tester, String key) =>
    tester.widget<Text>(newGameLeaderKeyedFinder(key));

Future<void> pumpNewGameLeaderDuplicateEngland(WidgetTester tester) {
  return pumpNewGameLeaderSelectionDialog(
    tester,
    baseConfig: newGameLeaderDuplicateEnglandConfig,
    surfaceSize: kNewGameLeaderDuplicateSurface,
  );
}

Future<int?> confirmNewGameLeaderWithSeed(WidgetTester tester, String seed) async {
  int? gotSeed;
  await pumpNewGameLeaderSelectionDialog(
    tester,
    onConfirmed: (_, _, s, _, _, _, _) => gotSeed = s,
  );
  await enterNewGameLeaderSeed(tester, seed);
  await ensureTapNewGameLeaderSelectionStart(tester);
  return gotSeed;
}

Future<double?> confirmNewGameLeaderTerrain(
  WidgetTester tester, {
  bool? dragLeft,
}) async {
  double? gotTerrainVariation;
  await pumpNewGameLeaderSelectionDialog(
    tester,
    onConfirmed: (_, _, _, _, terrainVariation, _, _) =>
        gotTerrainVariation = terrainVariation,
  );
  if (dragLeft != null) {
    await tapNewGameLeaderSliderEdge(tester, left: dragLeft);
  }
  await ensureTapNewGameLeaderSelectionStart(tester);
  return gotTerrainVariation;
}

Future<AdvancedStartType?> confirmNewGameLeaderAdvancedStart(
  WidgetTester tester, {
  Size surfaceSize = const Size(800, 1300),
  GameSetupConfig? baseConfig,
  Future<void> Function(WidgetTester tester)? beforeStart,
}) async {
  AdvancedStartType? gotAdvancedStart;
  await pumpNewGameLeaderSelectionDialog(
    tester,
    surfaceSize: surfaceSize,
    baseConfig: baseConfig,
    onConfirmed: (_, _, _, _, _, _, advancedStart) =>
        gotAdvancedStart = advancedStart,
  );
  if (beforeStart != null) {
    await beforeStart(tester);
  }
  await ensureTapNewGameLeaderSelectionStart(tester);
  return gotAdvancedStart;
}

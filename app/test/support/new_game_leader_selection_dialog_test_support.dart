// Shared pump / tap helpers for NewGameLeaderSelectionDialog widget tests.
// Used by `new_game_leader_selection_dialog_part1_test.dart` and
// `new_game_leader_selection_dialog_part2_test.dart` (Refs #4013).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
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

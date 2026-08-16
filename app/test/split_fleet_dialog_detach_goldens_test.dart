// Host goldens for Home Fleet detach-then-sail SplitFleetDialog (Refs #4448).
// SPEC/ui/naval-units-fleet-management.md § Home Fleet cargo consequence.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'split_fleet_dialog_test_support.dart';
import 'widget_test_assets.dart';

class _DetachGoldenCase {
  _DetachGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.boundaryName,
    required this.size,
    required this.overseasCargoUsed,
    required this.isCargoUsedReliable,
    required this.expectedRemaining,
    required this.expectedUsedLabel,
    required this.expectedColor,
  });

  final String name;
  final String goldenFile;
  final String boundaryName;
  final Size size;
  final int overseasCargoUsed;
  final bool isCargoUsedReliable;
  final int expectedRemaining;
  final String expectedUsedLabel;
  final Color expectedColor;
}

final List<_DetachGoldenCase> _cases = [
  _DetachGoldenCase(
    name: 'detach title/confirm cargo muted',
    goldenFile: 'goldens/split_fleet_dialog_detach.png',
    boundaryName: 'splitFleetDetachGolden',
    size: Size(520, 640),
    overseasCargoUsed: 4,
    isCargoUsedReliable: true,
    expectedRemaining: 7,
    expectedUsedLabel: '4',
    expectedColor: EditorialMonoclePalette.muted,
  ),
  _DetachGoldenCase(
    name: 'detach wraps at 320 dp',
    goldenFile: 'goldens/split_fleet_dialog_detach_320dp.png',
    boundaryName: 'splitFleetDetach320Golden',
    size: Size(320, 640),
    overseasCargoUsed: 4,
    isCargoUsedReliable: true,
    expectedRemaining: 7,
    expectedUsedLabel: '4',
    expectedColor: EditorialMonoclePalette.muted,
  ),
  _DetachGoldenCase(
    name: 'detach cargo accent (tight)',
    goldenFile: 'goldens/split_fleet_dialog_detach_cargo_accent.png',
    boundaryName: 'splitFleetDetachAccentGolden',
    size: Size(520, 640),
    overseasCargoUsed: 7,
    isCargoUsedReliable: true,
    expectedRemaining: 7,
    expectedUsedLabel: '7',
    expectedColor: EditorialMonoclePalette.accent,
  ),
  _DetachGoldenCase(
    name: 'detach cargo danger (shortfall)',
    goldenFile: 'goldens/split_fleet_dialog_detach_cargo_danger.png',
    boundaryName: 'splitFleetDetachDangerGolden',
    size: Size(520, 640),
    overseasCargoUsed: 9,
    isCargoUsedReliable: true,
    expectedRemaining: 7,
    expectedUsedLabel: '9',
    expectedColor: EditorialMonoclePalette.danger,
  ),
  _DetachGoldenCase(
    name: 'detach cargo unreliable em dash',
    goldenFile: 'goldens/split_fleet_dialog_detach_cargo_unreliable.png',
    boundaryName: 'splitFleetDetachUnreliableGolden',
    size: Size(520, 640),
    overseasCargoUsed: 9,
    isCargoUsedReliable: false,
    expectedRemaining: 7,
    expectedUsedLabel: '—',
    expectedColor: EditorialMonoclePalette.muted,
  ),
];

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();
  final fleet = splitFleetHome(shipTypeIds: const ['carrack', 'fluyte']);

  setUpAll(setUpNinePatchAssets);

  Future<void> pumpDetachSplit({
    required WidgetTester tester,
    required Key boundaryKey,
    required _DetachGoldenCase c,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: c.size,
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: SplitFleetDialog(
        originalFleet: fleet,
        game: splitFleetCapitalHomeGame(),
        humanPlayerId: 'gp1',
        bus: AppEventBus.create(),
        isHomeFleet: true,
        title: l10n.splitFleet_detachTitle,
        confirmLabel: l10n.splitFleet_detachConfirm,
        overseasCargoUsed: c.overseasCargoUsed,
        isCargoUsedReliable: c.isCargoUsedReliable,
      ),
    );
  }

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4448)', (tester) async {
      final boundaryKey = ValueKey<String>(c.boundaryName);
      await pumpDetachSplit(tester: tester, boundaryKey: boundaryKey, c: c);
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text(l10n.splitFleet_detachTitle), findsOneWidget);
      expect(find.text(l10n.splitFleet_detachConfirm), findsOneWidget);
      final cargo = find.text(
        l10n.splitFleet_homeCargoConsequence(
          c.expectedRemaining,
          c.expectedUsedLabel,
        ),
      );
      expect(cargo, findsOneWidget);
      expect(tester.widget<Text>(cargo).style?.color, c.expectedColor);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }
}

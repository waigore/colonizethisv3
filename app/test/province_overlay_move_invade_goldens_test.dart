// Visual goldens for MAP20001 Military Move / Invade variants (Refs #4350).
// SPEC/ui/province-sea-zone-detail-overlay.md § States and variants.

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

class _MoveInvadeGoldenCase {
  const _MoveInvadeGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showMove,
    required this.moveEnabled,
    required this.showInvade,
    required this.invadeEnabled,
    this.moveTooltip = '',
    this.invadeTooltip = '',
  });

  final String name;
  final String goldenFile;
  final bool showMove;
  final bool moveEnabled;
  final bool showInvade;
  final bool invadeEnabled;
  final String moveTooltip;
  final String invadeTooltip;
}

const List<_MoveInvadeGoldenCase> _cases = [
  _MoveInvadeGoldenCase(
    name: 'Military Move enabled',
    goldenFile: 'goldens/province_overlay_move_enabled.png',
    showMove: true,
    moveEnabled: true,
    showInvade: false,
    invadeEnabled: false,
  ),
  _MoveInvadeGoldenCase(
    name: 'Military Move disabled',
    goldenFile: 'goldens/province_overlay_move_disabled.png',
    showMove: true,
    moveEnabled: false,
    showInvade: false,
    invadeEnabled: false,
    moveTooltip:
        'The Home Army cannot leave the capital. Split a field army first.',
  ),
  _MoveInvadeGoldenCase(
    name: 'Military Move hidden',
    goldenFile: 'goldens/province_overlay_move_hidden.png',
    showMove: false,
    moveEnabled: false,
    showInvade: false,
    invadeEnabled: false,
  ),
  _MoveInvadeGoldenCase(
    name: 'Military Invade enabled',
    goldenFile: 'goldens/province_overlay_invade_enabled.png',
    showMove: false,
    moveEnabled: false,
    showInvade: true,
    invadeEnabled: true,
  ),
  _MoveInvadeGoldenCase(
    name: 'Military Invade disabled',
    goldenFile: 'goldens/province_overlay_invade_disabled.png',
    showMove: false,
    moveEnabled: false,
    showInvade: true,
    invadeEnabled: false,
    invadeTooltip: 'No field army can reach this province this turn.',
  ),
  _MoveInvadeGoldenCase(
    name: 'Military Invade hidden',
    goldenFile: 'goldens/province_overlay_invade_hidden.png',
    showMove: false,
    moveEnabled: false,
    showInvade: false,
    invadeEnabled: false,
  ),
];

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4350)', (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(640, 720));
      configureGoldenView(
        tester,
        physicalSize: const Size(640, 720),
        devicePixelRatio: 1.0,
      );

      final boundaryKey = ValueKey<String>('province_overlay_${c.name}_golden');
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          child: SizedBox(
            width: 460,
            height: 680,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: humanId,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              showMoveArmyControl: c.showMove,
              moveArmyEnabled: c.moveEnabled,
              moveArmyTooltip: c.moveTooltip,
              onMoveArmyTap: () {},
              showInvadeArmyControl: c.showInvade,
              invadeArmyEnabled: c.invadeEnabled,
              invadeArmyTooltip: c.invadeTooltip,
              onInvadeArmyTap: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      final militaryHeader = find.text(
        l10n.provinceOverlay_sectionMilitary.toUpperCase(),
      );
      expect(militaryHeader, findsOneWidget);
      await tester.ensureVisible(militaryHeader);
      await tester.pump();

      final moveFinder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_moveArmyAction,
      );
      if (c.showMove) {
        expect(moveFinder, findsOneWidget);
        final move = tester.widget<CtActionTextButton>(moveFinder);
        expect(move.enabled, c.moveEnabled);
        expect(move.onPressed, c.moveEnabled ? isNotNull : isNull);
        await tester.ensureVisible(moveFinder);
        await tester.pump();
      } else {
        expect(moveFinder, findsNothing);
      }

      final invadeFinder = find.byWidgetPredicate(
        (Widget w) => w is CtActionTextButton && w.label.startsWith('Invade'),
      );
      if (c.showInvade) {
        expect(invadeFinder, findsOneWidget);
        final invade = tester.widget<CtActionTextButton>(invadeFinder);
        expect(invade.enabled, c.invadeEnabled);
        expect(invade.onPressed, c.invadeEnabled ? isNotNull : isNull);
        await tester.ensureVisible(invadeFinder);
        await tester.pump();
      } else {
        expect(invadeFinder, findsNothing);
      }

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }
}

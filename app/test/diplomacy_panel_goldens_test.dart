// Widget goldens for the diplomacy surface visual acceptance criteria
// (Refs #3341 AC-14). Pixel baselines live under `app/test/goldens/` and are
// asserted with `matchesGoldenFile`, following the committed golden harness
// pattern (`new_game_leader_selection_dialog_golden_test.dart`,
// `province_build_improvement_shortcut_host_goldens_test.dart`): a keyed
// `RepaintBoundary` wraps each surface, deterministic fixtures pin the content,
// and `AppThemes.editorialMonocle` supplies the dark-theme chrome
// (`colonizethis-ui-design.mdc`).
//
// Each golden is paired with structural finder assertions so the test still
// maps to an AC even on a platform where pixel goldens are regenerated:
//
//  - AC-1  empty-state panel: three section headings + "No tribes contacted
//          yet." placeholder.
//  - AC-7  Great Power row at peace: overture stages + `Establish FTP`.
//  - AC-6  discovered Tribe row: overture stages.
//  - AC-10 disabled-not-hidden: at least one disabled `CtNinePatchButton`.
//  - AC-4  first-contact herald `OVL80001` (`TribeFirstContactOverlay`).
//  - R12/R13 colony Tribe row: Colony + Embassy standing chips, a
//          `Boycott vs Castile` chip, and the 10-step relation meter.
//  - R3/R8/R12 subsidized Minor row: `Outgoing subsidy: 10%` economic line and
//          the `Overseas: 2 · 80%` standing chip.
//
// SPEC: SPEC/ui/diplomacy-panel.md § Acceptance criteria (AC-14), § Diplomatic
// standing chip cluster acceptance criteria (Refs #3753 R12), and
// SPEC/ui/tribe-first-contact-overlay.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/tribe_first_contact_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';

import 'diplomacy_panel_goldens_test_fixtures.dart';
import 'diplomacy_panel_test_support.dart';
import 'golden_capture_harness.dart';
import 'yarn_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  for (final case_
      in <
        ({
          String name,
          Game Function() game,
          String keyId,
          String golden,
          void Function(WidgetTester tester) pin,
        })
      >[
        (
          name: 'AC-1 golden: empty-state panel shows headings + tribe placeholder',
          game: diplomacyPanelGoldenEmptyStateGame,
          keyId: 'diplomacy_empty_state_golden',
          golden: 'goldens/diplomacy_panel_empty_state.png',
          pin: (_) {
            expect(find.text('Great Powers'), findsOneWidget);
            expect(find.text('Minor Nations'), findsOneWidget);
            expect(find.text('Tribes'), findsOneWidget);
            expect(find.text('No tribes contacted yet.'), findsOneWidget);
          },
        ),
        (
          name:
              'AC-7/AC-10 golden: GP row shows default shortlist + More control',
          game: diplomacyPanelGoldenGreatPowerRowGame,
          keyId: 'diplomacy_gp_row_golden',
          golden: 'goldens/diplomacy_panel_gp_row.png',
          pin: (_) {
            expect(find.text('Great Powers'), findsOneWidget);
            expect(find.text('Castile'), findsOneWidget);
            expect(find.text('More actions'), findsWidgets);
            expect(
              find.text('Declare War').evaluate().isNotEmpty ||
                  find.text('Alliance').evaluate().isNotEmpty,
              isTrue,
            );
            expect(find.text('Offer Peace'), findsNothing);
          },
        ),
        (
          name: 'AC-4 (#3625) golden: allied GP row shows ALLIANCE treaty badge',
          game: diplomacyPanelGoldenAlliedGreatPowerRowGame,
          keyId: 'diplomacy_gp_alliance_row_golden',
          golden: 'goldens/diplomacy_panel_gp_alliance_row.png',
          pin: (_) {
            expect(find.text('Castile'), findsOneWidget);
            expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
            expect(find.textContaining('Devoted'), findsWidgets);
            expect(find.text('Break Alliance'), findsOneWidget);
            expect(find.text('Alliance'), findsNothing);
          },
        ),
        (
          name: 'AC-6 golden: discovered Tribe row shows overture controls',
          game: diplomacyPanelGoldenTribeRowGame,
          keyId: 'diplomacy_tribe_row_golden',
          golden: 'goldens/diplomacy_panel_tribe_row.png',
          pin: (_) {
            expect(find.text('Tribes'), findsOneWidget);
            expect(find.text('Powhatan'), findsOneWidget);
            expect(find.text('No tribes contacted yet.'), findsNothing);
            expect(find.text('More actions'), findsWidgets);
          },
        ),
        (
          name:
              'R12/R13 golden: colony Tribe row shows standing chips + relation meter',
          game: diplomacyPanelGoldenColonyTribeRowGame,
          keyId: 'diplomacy_colony_tribe_row_golden',
          golden: 'goldens/diplomacy_panel_colony_tribe_row.png',
          pin: (_) {
            expect(find.text('Powhatan'), findsOneWidget);
            expect(find.text(kDiplomacyChipColony), findsOneWidget);
            expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
            expect(
              find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
              findsOneWidget,
            );
            expect(find.byType(RelationMeter), findsWidgets);
          },
        ),
        (
          name:
              'R3/R8/R12 golden: subsidized Minor row shows subsidy line + overseas chip',
          game: diplomacyPanelGoldenSubsidizedMinorRowGame,
          keyId: 'diplomacy_subsidized_minor_row_golden',
          golden: 'goldens/diplomacy_panel_subsidized_minor_row.png',
          pin: (_) {
            expect(find.text('Bavaria'), findsOneWidget);
            expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
            expect(
              find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'),
              findsOneWidget,
            );
            expect(
              find.text('Outgoing subsidy: 10% to Bavaria'),
              findsOneWidget,
            );
          },
        ),
      ]) {
    testWidgets(case_.name, (WidgetTester tester) async {
      await runDiplomacyPanelGolden(
        tester,
        game: case_.game(),
        keyId: case_.keyId,
        golden: case_.golden,
        pin: case_.pin,
      );
    });
  }

  testWidgets(
    'wide GP-row golden: trailing action cluster flows left-to-right (Refs #3621)',
    (WidgetTester tester) async {
      await runDiplomacyPanelGolden(
        tester,
        game: diplomacyPanelGoldenGreatPowerRowGame(),
        keyId: 'diplomacy_gp_row_wide_golden',
        golden: 'goldens/diplomacy_panel_gp_row_wide.png',
        surface: const Size(1000, 1200),
        width: 800,
        height: 1200,
        pin: (tester) {
          final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
          expect(find.byKey(bodyKey), findsOneWidget);
          expect(
            tester.widget(find.byKey(bodyKey)),
            isA<Row>(),
            reason:
                'Wide (> 500 dp) GP row body must be a Row per § Responsive layout.',
          );
          final Finder buttons = find.descendant(
            of: find.byKey(bodyKey),
            matching: find.byType(CtNinePatchButton),
          );
          final int count = buttons.evaluate().length;
          expect(count, greaterThanOrEqualTo(3));
          const double tol = 0.5;
          double quantize(double v) => (v / tol).roundToDouble() * tol;
          final Map<double, Set<double>> leftsByRunTop =
              <double, Set<double>>{};
          for (int i = 0; i < count; i++) {
            final Rect r = tester.getRect(buttons.at(i));
            leftsByRunTop
                .putIfAbsent(quantize(r.top), () => <double>{})
                .add(quantize(r.left));
          }
          final int largestRun = leftsByRunTop.values
              .map((Set<double> lefts) => lefts.length)
              .reduce((int a, int b) => a > b ? a : b);
          expect(
            largestRun,
            greaterThanOrEqualTo(2),
            reason:
                'Wide action cluster must place at least two buttons on one run '
                'so the cluster flows left-to-right (Refs #3621).',
          );
        },
      );
    },
  );

  testWidgets(
    'AC-4 golden: first-contact herald (OVL80001) names tribe and capital',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 800));
      const boundaryKey = ValueKey<String>('tribe_first_contact_herald_golden');

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          center: false,
          useScaffold: false,
          child: TribeFirstContactOverlay(
            tribeName: 'Powhatan',
            capitalName: 'Werowocomoco',
            assetBundle: YarnStringAssetBundle({
              kDialogueTribeFirstContactAsset: kYarnTribeFirstContactHerald,
            }),
            onDismissed: () {},
            child: const ColoredBox(color: Color(0xFF101014)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('First Contact'), findsOneWidget);
      expect(find.textContaining('Powhatan'), findsOneWidget);
      expect(find.textContaining('Werowocomoco'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_tribe_first_contact_herald.png'),
      );
    },
  );
}

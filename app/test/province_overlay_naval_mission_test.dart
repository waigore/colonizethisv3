// Pins MAP20001 Naval Blockade/Beachhead overlay controls (Refs #4413).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'province_overlay_naval_mission_harness.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  final game = demoNavalMissionOverlayGame();
  final humanId = game.players.first.id;

  testWidgets('hidden controls omit Blockade and Beachhead', (tester) async {
    await pumpNavalMissionOverlay(tester, game: game, humanId: humanId);
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_blockadeAction,
      ),
      findsNothing,
    );
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_beachheadAction,
      ),
      findsNothing,
    );
  });

  testWidgets('enabled controls show Blockade and Beachhead', (tester) async {
    await pumpNavalMissionOverlay(
      tester,
      game: game,
      humanId: humanId,
      navalMission: ProvinceNavalMissionOverlayControls(
        showBlockade: true,
        blockadeEnabled: true,
        blockadeTooltip: l10n.naval_mission_effect_blockade,
        onBlockadeTap: () {},
        showBeachhead: true,
        beachheadEnabled: true,
        beachheadTooltip: l10n.naval_mission_effect_beachhead,
        onBeachheadTap: () {},
      ),
    );
    final navalHeader = find.text(
      l10n.provinceOverlay_sectionNaval.toUpperCase(),
    );
    await tester.ensureVisible(navalHeader);
    await tester.pump();
    final blockade = tester.widget<CtActionTextButton>(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_blockadeAction,
      ),
    );
    expect(blockade.enabled, isTrue);
    final beachhead = tester.widget<CtActionTextButton>(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_beachheadAction,
      ),
    );
    expect(beachhead.enabled, isTrue);
    expect(beachhead.tooltip, l10n.naval_mission_effect_beachhead);
    expect(
      (beachhead.tooltip ?? '').toLowerCase(),
      isNot(contains('this turn')),
    );
  });

  testWidgets('fogged roster still shows mission actions', (tester) async {
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return buildNavalSection(
              l10n: appL10n(context),
              game: game,
              fleets: const [],
              humanPlayerId: humanId,
              draftOrders: const Orders(),
              rosterObfuscated: true,
              navalMission: ProvinceNavalMissionOverlayControls(
                showBlockade: true,
                blockadeEnabled: true,
                blockadeTooltip: l10n.naval_mission_effect_blockade,
                onBlockadeTap: () {},
                showBeachhead: true,
                beachheadEnabled: true,
                beachheadTooltip: l10n.naval_mission_effect_beachhead,
                onBeachheadTap: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text(l10n.provinceOverlay_unknown), findsOneWidget);
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_blockadeAction,
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_beachheadAction,
      ),
      findsOneWidget,
    );
  });
}

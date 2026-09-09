// MAP20001 sea-zone Patrol/Defend default-visible stay-mission gists
// (Refs #4750). SPEC: SPEC/ui/province-sea-zone-detail-overlay.md

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  final game = demoGameForOverlay;
  final humanId = game.players.first.id;

  Future<void> pumpOverlay(
    WidgetTester tester, {
    required String displayId,
    String? selectedTileKey,
    ProvinceNavalMissionOverlayControls navalMission =
        ProvinceNavalMissionOverlayControls.hidden,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: SizedBox(
          width: 460,
          height: 680,
          child: ProvinceSeaZoneDetailOverlay(
            game: game,
            region: demoRegionForOverlay,
            displayId: displayId,
            selectedTileKey: selectedTileKey,
            humanPlayerId: humanId,
            playerView: demoHumanPlayerViewForOverlay,
            omniscientDetail: true,
            navalMission: navalMission,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpSea(
    WidgetTester tester, {
    ProvinceNavalMissionOverlayControls navalMission =
        ProvinceNavalMissionOverlayControls.hidden,
  }) async {
    final region = demoRegionForOverlay;
    final seaId = sampleSeaZoneIdForOverlay;
    final local = seaId.contains('|') ? seaId.split('|').last : seaId;
    CellViewData? seaCell;
    for (final c in region.cells) {
      if (c.isSea && c.regionCellId == local) {
        seaCell = c;
        break;
      }
    }
    final tileKey = seaCell == null
        ? null
        : '${region.regionId}|${seaCell.regionCellId}|${seaCell.x}|${seaCell.y}';
    await pumpOverlay(
      tester,
      displayId: seaId,
      selectedTileKey: tileKey,
      navalMission: navalMission,
    );
  }

  testWidgets('enabled Patrol and Defend show muted intercept-vs-hold gists', (
    tester,
  ) async {
    var patrolTaps = 0;
    await pumpSea(
      tester,
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: true,
        patrolEnabled: true,
        patrolTooltip: l10n.naval_mission_effect_patrol,
        onPatrolTap: () => patrolTaps++,
        showDefend: true,
        defendEnabled: true,
        defendTooltip: l10n.naval_mission_effect_defend,
        onDefendTap: () {},
      ),
    );
    final patrolGist = tester.widget<Text>(
      find.text(l10n.naval_mission_effect_patrol),
    );
    final defendGist = tester.widget<Text>(
      find.text(l10n.naval_mission_effect_defend),
    );
    expect(patrolGist.style?.color, EditorialMonoclePalette.muted);
    expect(defendGist.style?.color, EditorialMonoclePalette.muted);
    expect(l10n.naval_mission_effect_patrol.contains('%'), isFalse);
    expect(RegExp(r'\d').hasMatch(l10n.naval_mission_effect_patrol), isFalse);
    expect(RegExp(r'\d').hasMatch(l10n.naval_mission_effect_defend), isFalse);
    final patrol = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_patrolAction,
    );
    await tester.ensureVisible(patrol);
    await tester.tap(patrol);
    await tester.pump();
    expect(patrolTaps, 1);
  });

  testWidgets('disabled Patrol and Defend keep gists and do not emit', (
    tester,
  ) async {
    var tapped = false;
    await pumpSea(
      tester,
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: true,
        patrolEnabled: false,
        patrolTooltip: l10n.naval_mission_noMissionsAvailable,
        onPatrolTap: () => tapped = true,
        showDefend: true,
        defendEnabled: false,
        defendTooltip: l10n.naval_mission_noMissionsAvailable,
        onDefendTap: () => tapped = true,
      ),
    );
    expect(find.text(l10n.naval_mission_effect_patrol), findsOneWidget);
    expect(find.text(l10n.naval_mission_effect_defend), findsOneWidget);
    await tester.tap(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_patrolAction,
      ),
      warnIfMissed: false,
    );
    expect(tapped, isFalse);
  });

  testWidgets('hidden Patrol and Defend omit stay-mission gists', (
    tester,
  ) async {
    await pumpSea(tester);
    expect(find.text(l10n.naval_mission_effect_patrol), findsNothing);
    expect(find.text(l10n.naval_mission_effect_defend), findsNothing);
  });

  testWidgets('province Blockade path does not show stay-mission gists', (
    tester,
  ) async {
    await pumpOverlay(
      tester,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
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
    expect(find.text(l10n.naval_mission_effect_patrol), findsNothing);
    expect(find.text(l10n.naval_mission_effect_defend), findsNothing);
  });
}

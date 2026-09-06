// Pixel goldens for Build fort payoff gist variants (Refs #4668).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Build fort payoff gist;
// SPEC/ui/map-widget.md work-target selection.

import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show provinceOverlayInlineActions;
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_gist_line.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_build_fort_shortcut_host_golden_fixtures.dart'
    show goldenBuildFortGame, goldenBuildFortRegion;
import 'province_shortcut_host_emit_fixtures.dart'
    show provinceShortcutHostCombinedTopology;

class _FortPayoffGoldenCase {
  const _FortPayoffGoldenCase({
    required this.slug,
    required this.fortLevel,
    required this.fromLabel,
    required this.toLabel,
    required this.turns,
  });

  final String slug;
  final int fortLevel;
  final String Function(AppLocalizationsEn l10n) fromLabel;
  final String Function(AppLocalizationsEn l10n) toLabel;
  final int turns;
}

List<_FortPayoffGoldenCase> _cases(AppLocalizationsEn l10n) => [
  _FortPayoffGoldenCase(
    slug: 'open_to_wood',
    fortLevel: 0,
    fromLabel: (l) => l.moveArmy_fortOpenField,
    toLabel: (l) => l.moveArmy_fortWoodSiege,
    turns: 1,
  ),
  _FortPayoffGoldenCase(
    slug: 'wood_to_stone',
    fortLevel: 1,
    fromLabel: (l) => l.moveArmy_fortWoodSiege,
    toLabel: (l) => l.moveArmy_fortStoneSiege,
    turns: 2,
  ),
  _FortPayoffGoldenCase(
    slug: 'stone_to_modern',
    fortLevel: 2,
    fromLabel: (l) => l.moveArmy_fortStoneSiege,
    toLabel: (l) => l.moveArmy_fortModernSiege,
    turns: 3,
  ),
];

Game _gameWithFortLevel(int fortLevel) {
  final base = goldenBuildFortGame();
  final oldWorld = base.worldState.oldWorld;
  final provinces = [
    for (final p in oldWorld.provinces)
      p.id == 'oldWorld|p1' ? p.copyWith(fortLevel: fortLevel) : p,
  ];
  return base.copyWith(
    worldState: base.worldState.copyWith(
      oldWorld: RegionData(provinces: provinces, units: oldWorld.units),
    ),
  );
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();
  final cases = _cases(l10n);

  for (final c in cases) {
    testWidgets('golden: overlay Build fort payoff ${c.slug} (Refs #4668)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('build_fort_payoff_overlay');
      final game = _gameWithFortLevel(c.fortLevel);
      final playerView = buildPlayerView(
        game,
        provinceShortcutHostCombinedTopology(),
        game.players.first.id,
      );
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(640, 720),
        includeLocalizations: true,
        settle: false,
        child: SizedBox(
          width: 460,
          height: 680,
          child: ProvinceSeaZoneDetailOverlay(
            game: game,
            region: goldenBuildFortRegion(),
            displayId: 'oldWorld|p1',
            selectedTileKey: 'oldWorld|p1|0|0',
            humanPlayerId: 'gp1',
            playerView: playerView,
            civilianInlineActions: provinceOverlayInlineActions(
              buildFort: (
                showIcon: true,
                enabled: true,
                hasMatchingUnits: true,
              ),
            ),
            inlineActionCallbacks: (
              onExploreWithExplorerTap: null,
              onProspectWithExplorerTap: null,
              onBuildImprovementTap: null,
              onBuildRoadTap: null,
              onBuildFortTap: () {},
              onBuildPortTap: null,
              onBuildRailroadTap: null,
              onPurchaseLandTap: null,
            ),
            onClose: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(kBuildFortPayoffGistKey), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/build_fort_payoff_overlay_${c.slug}.png'),
      );
    });

    testWidgets('golden: selection prompt Build fort payoff ${c.slug} (Refs #4668)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('build_fort_payoff_prompt');
      final gist = buildFortPayoffGistLine(
        l10n: l10n,
        fromLabel: c.fromLabel(l10n),
        toLabel: c.toLabel(l10n),
        turns: c.turns,
      );
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(640, 220),
        includeLocalizations: true,
        useScaffold: false,
        center: false,
        settle: false,
        child: SizedBox(
          width: 640,
          height: 220,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GameMapCanvasStackSelectionPrompt(
                isNarrow: false,
                overlayOpen: false,
                onCancel: () {},
                buildFortGist: gist,
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('After this work:'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/build_fort_payoff_prompt_${c.slug}.png'),
      );
    });
  }
}

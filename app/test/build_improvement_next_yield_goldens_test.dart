// Pixel goldens for Build improvement next-yield gist variants (Refs #4627).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Build improvement
// next-yield gist; SPEC/ui/components/development-assign-row.md;
// SPEC/ui/map-widget.md work-target selection.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/screens/development/development_assign_preview.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show provinceOverlayInlineActions;
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_gist_line.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

class _YieldGoldenCase {
  const _YieldGoldenCase({
    required this.slug,
    required this.kind,
    required this.commodityId,
    required this.currentEffective,
    required this.nextEffective,
  });

  final String slug;
  final BuildImprovementYieldKind kind;
  final String commodityId;
  final int currentEffective;
  final int nextEffective;

  BuildImprovementYieldPreview get preview => BuildImprovementYieldPreview(
    commodityId: commodityId,
    currentEffective: currentEffective,
    nextEffective: nextEffective,
    kind: kind,
  );
}

const List<_YieldGoldenCase> _cases = [
  _YieldGoldenCase(
    slug: 'raise',
    kind: BuildImprovementYieldKind.raise,
    commodityId: 'grain',
    currentEffective: 0,
    nextEffective: 1,
  ),
  _YieldGoldenCase(
    slug: 'road_cap',
    kind: BuildImprovementYieldKind.roadPathLimit,
    commodityId: 'timber',
    currentEffective: 2,
    nextEffective: 2,
  ),
  _YieldGoldenCase(
    slug: 'town_cap',
    kind: BuildImprovementYieldKind.townDevelopmentLimit,
    commodityId: 'grain',
    currentEffective: 2,
    nextEffective: 2,
  ),
  _YieldGoldenCase(
    slug: 'disconnected',
    kind: BuildImprovementYieldKind.disconnected,
    commodityId: 'grain',
    currentEffective: 2,
    nextEffective: 2,
  ),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: overlay Tile next-yield ${c.slug} (Refs #4627)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('next_yield_overlay');
      final game = demoGameForOverlay;
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
            region: demoRegionForOverlay,
            displayId: sampleProvinceIdForOverlay,
            selectedTileKey: sampleTileKeyForProvinceOverlay,
            humanPlayerId: game.players.first.id,
            playerView: demoHumanPlayerViewForOverlay,
            civilianInlineActions: provinceOverlayInlineActions(
              buildImprovement: (
                showIcon: true,
                enabled: true,
                hasMatchingUnits: true,
              ),
            ),
            tileConnectivity: ProvinceTileConnectivityDisplay(
              capitalConnected:
                  c.kind != BuildImprovementYieldKind.disconnected,
              extractionEffective: c.currentEffective,
              extractionFull: c.kind == BuildImprovementYieldKind.raise ? 0 : 2,
              nextImproveYield: c.preview,
            ),
            inlineActionCallbacks: (
              onExploreWithExplorerTap: null,
              onProspectWithExplorerTap: null,
              onBuildImprovementTap: () {},
              onBuildRoadTap: null,
              onBuildFortTap: null,
              onBuildPortTap: null,
              onBuildRailroadTap: null,
              onPurchaseLandTap: null,
            ),
            onClose: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(kBuildImprovementNextYieldGistKey), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/build_improvement_next_yield_overlay_${c.slug}.png',
        ),
      );
    });

    testWidgets('golden: selection prompt next-yield ${c.slug} (Refs #4627)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('next_yield_prompt');
      final gist = buildImprovementNextYieldGistLine(
        l10n: l10n,
        preview: c.preview,
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
                affordPreview: const WorkOrderAffordPreview(
                  materialCosts: {'lumber': 1, 'castIron': 1},
                  canAfford: true,
                ),
                nextYieldGist: gist,
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('After this work:'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/build_improvement_next_yield_prompt_${c.slug}.png',
        ),
      );
    });

    testWidgets(
      'golden: Development Assign preview next-yield ${c.slug} (Refs #4627)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>('next_yield_assign');
        final gist = buildImprovementNextYieldGistLine(
          l10n: l10n,
          preview: c.preview,
        );
        await pumpGoldenHost(
          tester,
          boundaryKey: boundaryKey,
          physicalSize: const Size(420, 80),
          includeLocalizations: true,
          settle: false,
          scaffoldBackgroundColor:
              AppThemes.editorialMonocle.scaffoldBackgroundColor,
          child: SizedBox(
            width: 400,
            child: DevelopmentAssignPreviewCaption(
              scopeKey: 'nextYield',
              commodityId: c.commodityId,
              previewLine: 'Avalon (0, 0) · 0 → 1 · Lumber 1 · $gist',
              textTheme: AppThemes.editorialMonocle.textTheme,
            ),
          ),
        );
        expect(find.textContaining('After this work:'), findsOneWidget);
        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/build_improvement_next_yield_assign_${c.slug}.png',
          ),
        );
      },
    );
  }
}

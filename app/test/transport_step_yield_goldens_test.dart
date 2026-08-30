// Pixel goldens for transport-step payoff gist variants (Refs #4663).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Transport-step payoff;
// SPEC/ui/map-widget.md work-target selection.

import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show provinceOverlayInlineActions;
import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_gist_line.dart';
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

class _TransportGoldenCase {
  const _TransportGoldenCase({
    required this.slug,
    required this.kind,
    this.commodityId,
    required this.currentEffective,
    required this.nextEffective,
    this.useBuildPort = false,
  });

  final String slug;
  final TransportStepYieldKind kind;
  final String? commodityId;
  final int currentEffective;
  final int nextEffective;
  final bool useBuildPort;

  TransportStepYieldPreview get preview => TransportStepYieldPreview(
    commodityId: commodityId,
    currentEffective: currentEffective,
    nextEffective: nextEffective,
    kind: kind,
  );
}

const List<_TransportGoldenCase> _cases = [
  _TransportGoldenCase(
    slug: 'raise',
    kind: TransportStepYieldKind.raise,
    commodityId: 'grain',
    currentEffective: 0,
    nextEffective: 1,
  ),
  _TransportGoldenCase(
    slug: 'road_cap',
    kind: TransportStepYieldKind.roadPathLimit,
    commodityId: 'timber',
    currentEffective: 2,
    nextEffective: 2,
  ),
  _TransportGoldenCase(
    slug: 'disconnected',
    kind: TransportStepYieldKind.disconnected,
    commodityId: 'grain',
    currentEffective: 2,
    nextEffective: 2,
  ),
  _TransportGoldenCase(
    slug: 'binds_capital',
    kind: TransportStepYieldKind.bindsToCapital,
    currentEffective: 0,
    nextEffective: 0,
  ),
  _TransportGoldenCase(
    slug: 'port_on_coast',
    kind: TransportStepYieldKind.portOnCoast,
    currentEffective: 0,
    nextEffective: 0,
    useBuildPort: true,
  ),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: overlay Tile transport-step ${c.slug} (Refs #4663)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('transport_step_overlay');
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
              buildRoad: c.useBuildPort
                  ? null
                  : (
                      showIcon: true,
                      enabled: true,
                      hasMatchingUnits: true,
                    ),
              buildPort: c.useBuildPort
                  ? (
                      showIcon: true,
                      enabled: true,
                      hasMatchingUnits: true,
                    )
                  : null,
            ),
            tileConnectivity: ProvinceTileConnectivityDisplay(
              capitalConnected:
                  c.kind != TransportStepYieldKind.disconnected,
              extractionEffective: c.currentEffective,
              extractionFull: c.kind == TransportStepYieldKind.raise ? 0 : 2,
              nextBuildRoadYield: c.useBuildPort ? null : c.preview,
              nextBuildPortYield: c.useBuildPort ? c.preview : null,
            ),
            inlineActionCallbacks: (
              onExploreWithExplorerTap: null,
              onProspectWithExplorerTap: null,
              onBuildImprovementTap: null,
              onBuildRoadTap: c.useBuildPort ? null : () {},
              onBuildFortTap: null,
              onBuildPortTap: c.useBuildPort ? () {} : null,
              onBuildRailroadTap: null,
              onPurchaseLandTap: null,
            ),
            onClose: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(kTransportStepYieldGistKey), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/transport_step_yield_overlay_${c.slug}.png',
        ),
      );
    });

    testWidgets('golden: selection prompt transport-step ${c.slug} (Refs #4663)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('transport_step_prompt');
      final gist = transportStepYieldGistLine(
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
                transportGist: gist,
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('After this work:'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/transport_step_yield_prompt_${c.slug}.png',
        ),
      );
    });
  }
}

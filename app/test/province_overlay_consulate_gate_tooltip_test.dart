// Refs #3753 R4b / S4c: the ProvinceSeaZoneDetailOverlay Tile section surfaces
// the Consulate-gate rejection on the disabled Explore/Prospect inline actions.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Tile section inline
// actions — Consulate gate (R4b). When the issuing Great Power holds no
// Consulate (or higher) with the owning Minor/Tribe, the disabled Explore and
// Prospect inline actions show the tooltip "Establish a consulate before
// exploring or prospecting" instead of the default action hint. The message
// only appears when the disablement is caused by the Consulate gate.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

const String _kConsulateTooltip =
    'Establish a consulate before exploring or prospecting';

/// Rebuilds [demoGameForOverlay] with the sample province reassigned to
/// [ownerId]. When [asNewTribe] is true the owner is registered as a Tribe with
/// no overture, so the Consulate gate applies; otherwise the owner is left out
/// of the Minor/Tribe lists (no gate).
Game _demoGameWithSampleProvinceOwner(String ownerId, {bool asNewTribe = false}) {
  final base = demoGameForOverlay;
  final provinceId = sampleProvinceIdForOverlay;
  final ow = base.worldState.oldWorld;
  final provinces = [
    for (final p in ow.provinces)
      if (p.id == provinceId) p.copyWith(ownerId: ownerId) else p,
  ];
  return base.copyWith(
    worldState: base.worldState.copyWith(
      oldWorld: RegionData(provinces: provinces, units: ow.units),
    ),
    tribes: asNewTribe
        ? [...base.tribes, Tribe(id: ownerId, displayName: 'Gate Tribe')]
        : base.tribes,
  );
}

Widget _overlay({
  required Game game,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        showExploreActionIcon: showExploreActionIcon,
        exploreActionEnabled: exploreActionEnabled,
        onExploreWithExplorerTap: () {},
        showProspectActionIcon: showProspectActionIcon,
        prospectActionEnabled: prospectActionEnabled,
        onProspectWithExplorerTap: () {},
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay Tile inline actions — Consulate gate '
      'tooltip (Refs #3753 R4b)', () {
    testWidgets(
      'disabled Prospect in a no-Consulate Minor/Tribe province shows the '
      'consulate rejection tooltip',
      (tester) async {
        final game = _demoGameWithSampleProvinceOwner(
          'gate_tribe',
          asNewTribe: true,
        );
        await tester.pumpWidget(
          _overlay(
            game: game,
            showProspectActionIcon: true,
            prospectActionEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip(_kConsulateTooltip), findsOneWidget);
        expect(find.byTooltip('Prospect with explorer'), findsNothing);
      },
    );

    testWidgets(
      'disabled Explore in a no-Consulate Minor/Tribe province shows the '
      'consulate rejection tooltip',
      (tester) async {
        final game = _demoGameWithSampleProvinceOwner(
          'gate_tribe',
          asNewTribe: true,
        );
        await tester.pumpWidget(
          _overlay(
            game: game,
            showExploreActionIcon: true,
            exploreActionEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip(_kConsulateTooltip), findsOneWidget);
        expect(find.byTooltip('Explore with explorer'), findsNothing);
      },
    );

    testWidgets(
      'negative — disabled Prospect for a non-gated owner keeps the default '
      'tooltip (message is gate-specific)',
      (tester) async {
        // Own-province owner: the Consulate gate never applies, so a disabled
        // prospect keeps the default hint.
        final humanId = demoGameForOverlay.players.first.id;
        final game = _demoGameWithSampleProvinceOwner(humanId);
        await tester.pumpWidget(
          _overlay(
            game: game,
            showProspectActionIcon: true,
            prospectActionEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Prospect with explorer'), findsOneWidget);
        expect(find.byTooltip(_kConsulateTooltip), findsNothing);
      },
    );

    testWidgets(
      'enabled Prospect keeps the default action tooltip even for a Minor/Tribe '
      'owner',
      (tester) async {
        final game = _demoGameWithSampleProvinceOwner(
          'gate_tribe',
          asNewTribe: true,
        );
        await tester.pumpWidget(
          _overlay(
            game: game,
            showProspectActionIcon: true,
            prospectActionEnabled: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Prospect with explorer'), findsOneWidget);
        expect(find.byTooltip(_kConsulateTooltip), findsNothing);
      },
    );
  });
}

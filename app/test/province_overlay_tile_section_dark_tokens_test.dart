// Pins the dark editorial-monocle Tile section body tokens for
// ProvinceSeaZoneDetailOverlay (S5 — Tile body).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Tile section body tokens (Refs #2865 S5).
//
// Material defaults (`Theme.of(context).colorScheme.onSurface`,
// `Theme.of(context).disabledColor`) MUST NOT colour the Tile section
// body. All colours resolve from `EditorialMonoclePalette` tokens, so the
// dark theme owns the road caption and the disabled inline shortcut icons.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/l10n/app_localizations_en.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

Color _expectedDisabledIconColor() {
  return EditorialMonoclePalette.muted.withValues(
    alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
  );
}

Widget _darkOverlayWithRoadLevel({
  required int roadLevel,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
}) {
  final base = demoGameForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final ws = base.worldState;
  final tileState = ws.tileState.setRoadLevel(tileKey, roadLevel);
  final game = base.copyWith(
    worldState: ws.copyWith(tileState: tileState),
  );
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: tileKey,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        showExploreActionIcon: showExploreActionIcon,
        exploreActionEnabled: exploreActionEnabled,
        onExploreWithExplorerTap: () {},
        showProspectActionIcon: showProspectActionIcon,
        prospectActionEnabled: prospectActionEnabled,
        onProspectWithExplorerTap: () {},
        showBuildImprovementActionIcon: showBuildImprovementActionIcon,
        buildImprovementActionEnabled: buildImprovementActionEnabled,
        onBuildImprovementTap: () {},
      ),
    ),
  );
}

// The road wiring test in province_overlay_road_rail_transport_test.dart
// uses the full debug-init player view rather than the demo fixture so the
// land tile passes visibility gating; we follow that pattern here so the
// supplementary line actually renders.
Widget _darkOverlayWithRoadLevelFullPlayerView({required int roadLevel}) {
  final base = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final humanPlayerId = base.players.first.id;
  final init = getDebugInitGameResult();
  final playerView = buildPlayerView(
    base,
    init.combinedTopology,
    humanPlayerId,
  );
  final ws = base.worldState;
  final tileState = ws.tileState.setRoadLevel(tileKey, roadLevel);
  final game = base.copyWith(
    worldState: ws.copyWith(tileState: tileState),
  );
  final parts = tileKey.split('|');
  final provinceId = '${parts[0]}|${parts[1]}';
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        displayId: provinceId,
        selectedTileKey: tileKey,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
      ),
    ),
  );
}

TextStyle _textStyleFor(WidgetTester tester, String exactText) {
  final Text widget = tester.widget<Text>(find.text(exactText));
  return widget.style ?? const TextStyle();
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
    'body tokens (SPEC § Dark-theme Tile section body tokens)',
    () {
      testWidgets(
        'land transport level 2 — supplementary "improved road" caption '
        'resolves to EditorialMonoclePalette.muted under editorialMonocle',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevelFullPlayerView(roadLevel: 2),
          );
          await tester.pumpAndSettle();

          final style = _textStyleFor(tester, 'improved road');
          expect(
            style.color,
            EditorialMonoclePalette.muted,
            reason:
                'Supplementary GDD road caption must resolve to '
                'EditorialMonoclePalette.muted (SPEC § Dark-theme Tile '
                'section body tokens — Road / railroad caption lines).',
          );
        },
      );

      testWidgets(
        'land transport level 1 — primitive-road caption AND the level-1 '
        'railroad gloss both resolve to EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevelFullPlayerView(roadLevel: 1),
          );
          await tester.pumpAndSettle();

          final primitiveStyle = _textStyleFor(tester, 'primitive road');
          expect(primitiveStyle.color, EditorialMonoclePalette.muted);

          final glossStyle = _textStyleFor(
            tester,
            AppLocalizationsEn().provinceOverlay_tileRoadRailGloss,
          );
          expect(
            glossStyle.color,
            EditorialMonoclePalette.muted,
            reason:
                'Level-1 railroad gloss must use the same '
                'EditorialMonoclePalette.muted token as the supplementary '
                'caption (SPEC AC "Dark-theme Tile road caption — level-1 '
                'rail gloss colour").',
          );
        },
      );

      testWidgets(
        'land transport level 4 — supplementary "port or railroad" caption '
        'still resolves to EditorialMonoclePalette.muted (no fallback '
        'colour for the higher transport level)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevelFullPlayerView(roadLevel: 4),
          );
          await tester.pumpAndSettle();

          final style = _textStyleFor(tester, 'port or railroad');
          expect(style.color, EditorialMonoclePalette.muted);
        },
      );

      testWidgets(
        'land transport level 0 — supplementary "none" caption resolves to '
        'EditorialMonoclePalette.muted (regression guard against '
        'Theme.colorScheme.onSurface fallback)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevelFullPlayerView(roadLevel: 0),
          );
          await tester.pumpAndSettle();

          final style = _textStyleFor(tester, 'none');
          expect(style.color, EditorialMonoclePalette.muted);
        },
      );

      testWidgets(
        'disabled Explore inline icon resolves to '
        'EditorialMonoclePalette.muted at alpha 0.65',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevel(
              roadLevel: 0,
              showExploreActionIcon: true,
              exploreActionEnabled: false,
            ),
          );
          await tester.pumpAndSettle();

          final icon = tester.widget<Icon>(
            find.descendant(
              of: find.byTooltip('Explore with explorer'),
              matching: find.byType(Icon),
            ),
          );
          expect(
            icon.color,
            _expectedDisabledIconColor(),
            reason:
                'Disabled Explore icon must use '
                'EditorialMonoclePalette.muted at '
                'kProvinceOverlayTileInlineActionDisabledAlpha (SPEC AC '
                '"Dark-theme Tile inline action — disabled Explore icon '
                'colour").',
          );
        },
      );

      testWidgets(
        'disabled Prospect inline icon resolves to '
        'EditorialMonoclePalette.muted at alpha 0.65',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevel(
              roadLevel: 0,
              showProspectActionIcon: true,
              prospectActionEnabled: false,
            ),
          );
          await tester.pumpAndSettle();

          final icon = tester.widget<Icon>(
            find.descendant(
              of: find.byTooltip('Prospect with explorer'),
              matching: find.byType(Icon),
            ),
          );
          expect(
            icon.color,
            _expectedDisabledIconColor(),
            reason:
                'Disabled Prospect icon must use '
                'EditorialMonoclePalette.muted at '
                'kProvinceOverlayTileInlineActionDisabledAlpha (SPEC AC '
                '"Dark-theme Tile inline action — disabled Prospect icon '
                'colour").',
          );
        },
      );

      testWidgets(
        'disabled Build improvement inline icon resolves to '
        'EditorialMonoclePalette.muted at alpha 0.65',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevel(
              roadLevel: 0,
              showBuildImprovementActionIcon: true,
              buildImprovementActionEnabled: false,
            ),
          );
          await tester.pumpAndSettle();

          final icon = tester.widget<Icon>(
            find.descendant(
              of: find.byTooltip('Build improvement'),
              matching: find.byType(Icon),
            ),
          );
          expect(
            icon.color,
            _expectedDisabledIconColor(),
            reason:
                'Disabled Build improvement icon must use '
                'EditorialMonoclePalette.muted at '
                'kProvinceOverlayTileInlineActionDisabledAlpha (SPEC AC '
                '"Dark-theme Tile inline action — disabled Build '
                'improvement icon colour").',
          );
        },
      );

      testWidgets(
        'negative — disabled inline icon colours never equal '
        'Theme.of(context).disabledColor for the dark theme '
        '(Material default regression guard)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRoadLevel(
              roadLevel: 0,
              showExploreActionIcon: true,
              exploreActionEnabled: false,
              showProspectActionIcon: true,
              prospectActionEnabled: false,
              showBuildImprovementActionIcon: true,
              buildImprovementActionEnabled: false,
            ),
          );
          await tester.pumpAndSettle();

          // The Material-default fallback this S5 slice replaces:
          // `Theme.of(context).disabledColor.withValues(alpha: 0.65)`.
          // Under AppThemes.editorialMonocle the dark Material theme's
          // disabledColor is `Colors.white38` (white at alpha ~0.38).
          // The new tokens must not coincidentally resolve to that
          // colour, otherwise the regression guard would be a no-op.
          const Color materialDarkDisabled = Colors.white38;
          final Color forbidden = materialDarkDisabled.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          );

          for (final tooltip in const <String>[
            'Explore with explorer',
            'Prospect with explorer',
            'Build improvement',
          ]) {
            final icon = tester.widget<Icon>(
              find.descendant(
                of: find.byTooltip(tooltip),
                matching: find.byType(Icon),
              ),
            );
            expect(
              icon.color,
              isNot(forbidden),
              reason:
                  'Disabled "$tooltip" icon must not regress to the '
                  'legacy Theme.disabledColor-derived colour; it must '
                  'resolve from EditorialMonoclePalette.muted (SPEC AC '
                  '"Dark-theme Tile body — Material defaults regression '
                  'guard").',
            );
          }
        },
      );
    },
  );
}

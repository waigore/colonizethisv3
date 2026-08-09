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
// Shared road/caption + disabled-icon tables densify residual mid-size
// cases (Refs #4021).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart'
    show kProvinceOverlayTileInlineActionDisabledAlpha;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';

import 'province_overlay_test_harness.dart';

Color _expectedDisabledIconColor() {
  return EditorialMonoclePalette.muted.withValues(
    alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
  );
}

TextStyle _textStyleFor(WidgetTester tester, String exactText) {
  final Text widget = tester.widget<Text>(find.text(exactText));
  return widget.style ?? const TextStyle();
}

Future<void> _pumpFullPlayerRoad(
  WidgetTester tester, {
  required int roadLevel,
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayWithRoadLevelFullPlayerView(roadLevel: roadLevel),
  );
  await tester.pumpAndSettle();
}

Future<void> _assertMutedRoadCaption(
  WidgetTester tester, {
  required int roadLevel,
  required String caption,
  String? extraMutedText,
}) async {
  await _pumpFullPlayerRoad(tester, roadLevel: roadLevel);
  expect(_textStyleFor(tester, caption).color, EditorialMonoclePalette.muted);
  if (extraMutedText != null) {
    expect(
      _textStyleFor(tester, extraMutedText).color,
      EditorialMonoclePalette.muted,
    );
  }
}

Future<void> _expectDisabledInlineIcon(
  WidgetTester tester, {
  required String tooltip,
  required Widget Function() shell,
}) async {
  await tester.pumpWidget(shell());
  await tester.pumpAndSettle();
  final icon = tester.widget<Icon>(
    find.descendant(
      of: find.byTooltip(tooltip),
      matching: find.byType(Icon),
    ),
  );
  expect(icon.color, _expectedDisabledIconColor());
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
      'body tokens (SPEC § Dark-theme Tile section body tokens)', () {
    for (final c in <({int level, String caption, String? gloss})>[
      (level: 2, caption: 'improved road', gloss: null),
      (
        level: 1,
        caption: 'primitive road',
        gloss: AppLocalizationsEn().provinceOverlay_tileRoadRailGloss,
      ),
      (level: 4, caption: 'port or railroad', gloss: null),
      (level: 0, caption: 'none', gloss: null),
    ]) {
      testWidgets(
        'land transport level ${c.level} — "${c.caption}" resolves to muted',
        (WidgetTester tester) async {
          await _assertMutedRoadCaption(
            tester,
            roadLevel: c.level,
            caption: c.caption,
            extraMutedText: c.gloss,
          );
        },
      );
    }

    for (final c in <({String tooltip, Widget Function() shell})>[
      (
        tooltip: 'Explore with explorer',
        shell: () => buildProvinceOverlayWithRoadLevelDemoFixture(
          roadLevel: 0,
          showExploreActionIcon: true,
          exploreActionEnabled: false,
        ),
      ),
      (
        tooltip: 'Prospect with explorer',
        shell: () => buildProvinceOverlayWithRoadLevelDemoFixture(
          roadLevel: 0,
          showProspectActionIcon: true,
          prospectActionEnabled: false,
        ),
      ),
      (
        tooltip: AppLocalizationsEn()
            .provinceOverlay_tileBuildImprovementDisabledNoBuilderTooltip,
        shell: () => buildProvinceOverlayWithRoadLevelDemoFixture(
          roadLevel: 0,
          showBuildImprovementActionIcon: true,
          buildImprovementActionEnabled: false,
        ),
      ),
    ]) {
      testWidgets(
        'disabled ${c.tooltip} icon resolves to muted @ alpha 0.65',
        (WidgetTester tester) async {
          await _expectDisabledInlineIcon(
            tester,
            tooltip: c.tooltip,
            shell: c.shell,
          );
        },
      );
    }

    testWidgets('negative — disabled inline icon colours never equal '
        'Theme.of(context).disabledColor for the dark theme '
        '(Material default regression guard)', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildProvinceOverlayWithRoadLevelDemoFixture(
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

      const Color materialDarkDisabled = Colors.white38;
      final Color forbidden = materialDarkDisabled.withValues(
        alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
      );

      final l10n = AppLocalizationsEn();
      for (final tooltip in <String>[
        'Explore with explorer',
        'Prospect with explorer',
        l10n.provinceOverlay_tileBuildImprovementDisabledNoBuilderTooltip,
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
    });
  });
}

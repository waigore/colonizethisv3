// OVL70001 research-complete effect-gist goldens (Refs #4724).
// Baselines: app/test/goldens/player_turn_event_feed_research_complete_*.png.
// Widgetbook pin: widgetbook_player_turn_event_feed_research_complete_test.dart.
// SPEC: SPEC/ui/player-turn-event-feed.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_effect_summary.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const Size _kWideFeedViewport = Size(420, 320);
const Size _kCard320Viewport = Size(360, 280);

Widget _researchFeedGoldenHost({
  required Key boundaryKey,
  required Widget child,
  required Size viewport,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    includeLocalizations: true,
    center: false,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: MediaQuery(
      data: MediaQueryData(size: viewport),
      child: SizedBox(
        width: viewport.width,
        height: viewport.height,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    ),
  );
}

Future<void> _pumpResearchFeedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<PlayerTurnEventFeedEntry> entries,
  required Size viewport,
  bool narrow = false,
}) async {
  configureGoldenView(tester, physicalSize: viewport);
  await tester.pumpWidget(
    _researchFeedGoldenHost(
      boundaryKey: boundaryKey,
      viewport: viewport,
      child: PlayerTurnEventFeedCard(
        entries: entries,
        emptyLabel: 'No events this turn.',
        narrow: narrow,
      ),
    ),
  );
  await pumpForGolden(tester, settle: false);
}

void main() {
  suppressLogsForTests();

  final researchLine = formatResearchCompleteFeedLine(
    AppLocalizationsEn(),
    kTechIdCropRotation,
  );

  group('OVL70001 research-complete goldens (Refs #4724)', () {
    testWidgets('Crop Rotation effect gist under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('researchCompleteFeedCropRotation');
      await _pumpResearchFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [
          PlayerTurnEventFeedEntry(
            text: researchLine,
            linkAffordance: true,
            onTap: () {},
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Crop Rotation'), findsOneWidget);
      expect(find.textContaining('Sheep Ranching'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_research_complete_crop_rotation.png',
        ),
      );
    });

    testWidgets('Crop Rotation wraps safely at 320 dp card width', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'researchCompleteFeedCropRotation320',
      );
      await _pumpResearchFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kCard320Viewport,
        entries: [
          PlayerTurnEventFeedEntry(
            text: researchLine,
            linkAffordance: true,
            onTap: () {},
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Crop Rotation'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_research_complete_crop_rotation_320dp.png',
        ),
      );
    });

    testWidgets('narrow research row still meets 44 dp min height', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('researchCompleteFeedNarrow');
      await _pumpResearchFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: const Size(kMinViewportWidth, 640),
        narrow: true,
        entries: [
          PlayerTurnEventFeedEntry(
            text: researchLine,
            linkAffordance: true,
            onTap: () {},
          ),
        ],
      );

      final box = tester.getSize(
        find.descendant(
          of: find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          matching: find.byType(InkWell),
        ),
      );
      expect(box.height, greaterThanOrEqualTo(44));
    });
  });
}

// Visual goldens for MAP20001 Political Sight row (Refs #4406).
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

Future<void> _pumpPoliticalSightGolden(
  WidgetTester tester, {
  required GlobalKey boundaryKey,
  required String sightPhrase,
  Size physicalSize = const Size(300, 280),
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: ColoredBox(
      color: EditorialMonoclePalette.bgDeep,
      child: Builder(
        builder: (BuildContext ctx) {
          final l10n = appL10n(ctx);
          return Padding(
            padding: const EdgeInsets.all(8),
            child: buildPoliticalSection(
              l10n: l10n,
              name: 'Wessex',
              ownerName: 'England',
              sightPhrase: sightPhrase,
              regionLabel: 'Old World',
              isCapital: false,
              townDevelopmentLevel: 1,
              showUpgradeTownControl: false,
              upgradeTownEnabled: false,
              upgradeTownTooltip: '',
              showEstablishConsulateControl: false,
              establishConsulateEnabled: false,
              establishConsulatePending: false,
              establishConsulateRejectionReason: null,
              isNarrow: false,
            ),
          );
        },
      ),
    ),
  );
  await pumpSettleCapped(tester);
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: Political Sight fully visible', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpPoliticalSightGolden(
      tester,
      boundaryKey: boundaryKey,
      sightPhrase: 'Fully visible',
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_political_sight_visible.png'),
    );
  });

  testWidgets('golden: Political Sight fogged', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpPoliticalSightGolden(
      tester,
      boundaryKey: boundaryKey,
      sightPhrase: 'Fogged — terrain only',
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_political_sight_fogged.png'),
    );
  });

  testWidgets('golden: Political Sight unknown', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpPoliticalSightGolden(
      tester,
      boundaryKey: boundaryKey,
      sightPhrase: 'Unknown — no intel yet',
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_political_sight_unknown.png'),
    );
  });

  testWidgets('golden: Political Sight 320 dp', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpPoliticalSightGolden(
      tester,
      boundaryKey: boundaryKey,
      sightPhrase: 'Fully visible',
      physicalSize: const Size(320, 300),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_political_sight_320dp.png'),
    );
  });
}

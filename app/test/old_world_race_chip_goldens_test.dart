// Widget goldens for the MAP10001 Old World race chip (Refs #4451).
//
// AC mapping:
//  - human ahead (no rival cue)
//  - rival ahead (name + N / 31)
//  - 320 dp compact rival cue

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kOldWorldRaceChipKey;
import 'package:colonizethis_app/features/game/widgets/shell/old_world_race_chip.dart';
import 'package:colonizethis_app/features/game/widgets/shell/old_world_race_snapshot.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const OldWorldRaceSnapshot _kHumanAhead = OldWorldRaceSnapshot(
  focusPlayerId: 'gp1',
  focusCount: 18,
  threshold: 31,
);

const OldWorldRaceSnapshot _kRivalAhead = OldWorldRaceSnapshot(
  focusPlayerId: 'gp1',
  focusCount: 12,
  threshold: 31,
  rivalLeaderName: 'Spain',
  rivalLeaderCount: 20,
);

Future<void> _pumpRaceGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required OldWorldRaceSnapshot snapshot,
  required Size physicalSize,
  bool narrow = false,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    settle: false,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border(
          bottom: BorderSide(color: EditorialMonoclePalette.border),
        ),
      ),
      child: SizedBox(
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: OldWorldRaceChip(
            snapshot: snapshot,
            narrow: narrow,
            onTap: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: Old World race human ahead (Refs #4451)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('old_world_race_human_ahead');
    await _pumpRaceGolden(
      tester,
      boundaryKey: boundaryKey,
      snapshot: _kHumanAhead,
      physicalSize: const Size(220, 48),
    );
    expect(find.byKey(kOldWorldRaceChipKey), findsOneWidget);
    expect(find.text('18 / 31'), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/old_world_race_chip_human_ahead.png'),
    );
  });

  testWidgets('golden: Old World race rival ahead (Refs #4451)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('old_world_race_rival_ahead');
    await _pumpRaceGolden(
      tester,
      boundaryKey: boundaryKey,
      snapshot: _kRivalAhead,
      physicalSize: const Size(280, 48),
    );
    expect(find.textContaining('Spain'), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/old_world_race_chip_rival_ahead.png'),
    );
  });

  testWidgets('golden: Old World race 320 dp rival ahead (Refs #4451)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('old_world_race_320dp');
    await _pumpRaceGolden(
      tester,
      boundaryKey: boundaryKey,
      snapshot: _kRivalAhead,
      physicalSize: const Size(320, 48),
      narrow: true,
    );
    expect(find.text('12/31'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/old_world_race_chip_320dp.png'),
    );
  });
}

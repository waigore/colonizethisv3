// Widget goldens for GAME30003 Intelligence Council (Refs #4476 verification
// gaps). Pixel baselines under `app/test/goldens/` close the
// verify-github-issue UI proof requirement for world, spy, empty, and mobile.
//
// SPEC: SPEC/ui/intelligence-council.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/intelligence_council_screen.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

Game _councilGame(LastTurnIntelligenceDigest digest) {
  return Game(
    id: 'intel-council-golden',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|fr1',
            regionId: 'oldWorld',
            ownerId: 'france',
            displayName: 'Paris',
          ),
        ],
      ),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'france', displayName: 'France', isHuman: false, treasury: 0),
      Player(id: 'gp3', displayName: 'Spain', isHuman: false, treasury: 0),
    ],
    lastTurnIntelligenceDigest: digest,
  );
}

const _worldDigest = LastTurnIntelligenceDigest(
  resolvedTurnNumber: 2,
  worldLines: [
    IntelligenceWorldLine(
      kind: IntelligenceWorldKind.war,
      factionIdA: 'france',
      factionIdB: 'gp3',
    ),
    IntelligenceWorldLine(
      kind: IntelligenceWorldKind.provinceCaptured,
      provinceId: 'oldWorld|fr1',
      factionIdA: 'gp3',
      factionIdB: 'france',
    ),
  ],
);

const _spyDigest = LastTurnIntelligenceDigest(
  resolvedTurnNumber: 2,
  spyReportsByObserverId: {
    'gp1': [
      IntelligenceSpyCourtBlock(
        courtFactionId: 'france',
        lines: [
          IntelligenceSpyLine(
            kind: IntelligenceSpyKind.diplomatic,
            diplomaticType: DiplomaticEventType.declareWar,
            fromFactionId: 'france',
            toFactionId: 'gp3',
          ),
          IntelligenceSpyLine(
            kind: IntelligenceSpyKind.researchComplete,
            techId: kTechIdCropRotation,
            fromFactionId: 'france',
          ),
        ],
      ),
    ],
  },
);

Future<void> _pumpCouncilGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required LastTurnIntelligenceDigest digest,
  required Size physicalSize,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    center: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: SizedBox(
      width: physicalSize.width,
      height: physicalSize.height,
      child: IntelligenceCouncilBody(
        game: _councilGame(digest),
        humanPlayerId: 'gp1',
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: GAME30003 world briefing (Refs #4476)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('intelligence_council_world_golden');
    await _pumpCouncilGolden(
      tester,
      boundaryKey: boundaryKey,
      digest: _worldDigest,
      physicalSize: const Size(480, 640),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text('World briefing'), findsOneWidget);
    expect(find.text('France and Spain are now at war.'), findsOneWidget);
    expect(
      find.text('Paris: ownership changed from Spain to France.'),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/intelligence_council_world.png'),
    );
  });

  testWidgets('golden: GAME30003 spy reports (Refs #4476)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('intelligence_council_spy_golden');
    await _pumpCouncilGolden(
      tester,
      boundaryKey: boundaryKey,
      digest: _spyDigest,
      physicalSize: const Size(480, 640),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.textContaining('Our spy in France reports:'), findsNWidgets(2));
    expect(find.textContaining('Crop Rotation'), findsOneWidget);
    expect(find.textContaining('hiddenAgenda'), findsNothing);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/intelligence_council_spy.png'),
    );
  });

  testWidgets('golden: GAME30003 empty digest (Refs #4476)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('intelligence_council_empty_golden');
    await _pumpCouncilGolden(
      tester,
      boundaryKey: boundaryKey,
      digest: const LastTurnIntelligenceDigest(resolvedTurnNumber: 2),
      physicalSize: const Size(480, 640),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text('No major world events last turn.'), findsOneWidget);
    expect(
      find.text(
        'No spy reports. Station a Spy in a foreign province to hear that court\'s news.',
      ),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/intelligence_council_empty.png'),
    );
  });

  testWidgets('golden: GAME30003 mobile 320 dp (Refs #4476)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('intelligence_council_320dp_golden');
    await _pumpCouncilGolden(
      tester,
      boundaryKey: boundaryKey,
      digest: _worldDigest,
      physicalSize: const Size(kMinViewportWidth, 640),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text('World briefing'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/intelligence_council_320dp.png'),
    );
  });
}

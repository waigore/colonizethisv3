// Widget goldens for the diplomacy relative-power line visual acceptance
// criteria (Refs #3622). These pixel baselines close the verification gaps
// flagged against issue #3622: the implementation (merged PRs #3630 / #3640)
// shipped the shared `RelativePowerLine` widget and its panel/detail wiring,
// but no `matchesGoldenFile` baseline existed for
//
//   * the diplomacy detail screen (GAME30002) relative-power line,
//   * the five strength tiers (Vastly inferior … Vastly superior), or
//   * the narrow-viewport (320 dp minimum) wrap-without-ellipsis layout.
//
// Pixel baselines live under `app/test/goldens/` and are asserted with
// `matchesGoldenFile`, following the committed golden harness pattern in
// `diplomacy_panel_goldens_test.dart`: a keyed `RepaintBoundary` wraps each
// surface, deterministic fixtures pin the content, and
// `AppThemes.editorialMonocle` supplies the dark-theme chrome
// (`colonizethis-ui-design.mdc`). Each golden is paired with a structural
// finder so the test still maps to an AC when pixels are regenerated.
//
// SPEC: SPEC/ui/diplomacy-panel.md § Relative power line and § Acceptance
// criteria (AC-15); SPEC/ui/diplomacy-detail-screen.md § Acceptance Criteria
// (relative-power golden).

import 'dart:ui' as ui;

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// `pumpAndSettle` can hang on the detail surface (animated chrome keeps the
/// ticker busy); bounded pumps flush layout and the deferred build instead.
Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Themed host that mounts [child] under `AppThemes.editorialMonocle` with the
/// app localization delegates so the relative-power line resolves real copy
/// and palette colors (not raw Material defaults). The line is painted on the
/// editorial-monocle background inside the keyed [boundaryKey] `RepaintBoundary`
/// so the captured golden mirrors the in-app dark surface.
Widget _lineHost({
  required Widget child,
  required Key boundaryKey,
  required double width,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: const Color(0xFF101014),
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: ColoredBox(
            color: const Color(0xFF101014),
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Detail-screen fixture where Great Power `gp2` controls strictly more
/// provinces than the human `gp1`, so `greatPowerPowerScore` makes the
/// relative-power comparison positive (red `--danger`) deterministically.
Game _detailGame() {
  const ow = 'oldWorld';
  final provinces = <Province>[
    Province(id: '$ow|p1', regionId: ow, displayName: 'P1', ownerId: 'gp1'),
    Province(id: '$ow|p2', regionId: ow, displayName: 'P2', ownerId: 'gp2'),
    Province(id: '$ow|p3', regionId: ow, displayName: 'P3', ownerId: 'gp2'),
    Province(id: '$ow|p4', regionId: ow, displayName: 'P4', ownerId: 'gp2'),
  ];
  return Game(
    id: 'diplo-detail-relpower-golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 70,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    // The detail screen chrome (CtTopBar / CtBackButton) may consume the
    // shared nine-patch image; preload it so the golden renders the framed
    // button rather than an error box (mirrors diplomacy_detail_screen_test).
    try {
      final bytes = await rootBundle.load(
        'assets/images/ui_button_nine_patch.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      Flame.images.add('ui_button_nine_patch.png', frame.image);
    } catch (_) {
      // Best-effort: the golden still captures the relative-power line.
    }
  });

  setUp(AppEventBus.reset);

  // AC-15 (#3622): one representative golden per strength tier proves the
  // percentage + tier word render in the correct `--danger` / `--success`
  // color and copy for each `powerComparisonTier` bucket.
  const tierCases = <({String slug, int pct, String tier})>[
    (slug: 'vastly_inferior', pct: -40, tier: 'Vastly inferior'),
    (slug: 'inferior', pct: -20, tier: 'Inferior'),
    (slug: 'roughly_equal', pct: 0, tier: 'Roughly equal'),
    (slug: 'superior', pct: 20, tier: 'Superior'),
    (slug: 'vastly_superior', pct: 40, tier: 'Vastly superior'),
  ];

  for (final c in tierCases) {
    testWidgets('AC-15 golden: relative-power tier ${c.slug} (pct=${c.pct})', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(420, 220));
      final boundaryKey = ValueKey<String>('relative_power_${c.slug}');

      await tester.pumpWidget(
        _lineHost(
          child: RelativePowerLine(pct: c.pct),
          boundaryKey: boundaryKey,
          width: 360,
        ),
      );
      await _pumpBuilt(tester);

      expect(find.byType(RelativePowerLine), findsOneWidget);
      expect(find.textContaining(c.tier, findRichText: true), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_relative_power_${c.slug}.png'),
      );
    });
  }

  // AC-15 (#3622): the relative-power line wraps to additional lines (never
  // `TextOverflow.ellipsis`) when the available width is below the line's
  // intrinsic width — the layout path the 320 dp minimum viewport triggers
  // with a long faction name. The narrow box forces the multi-line render so
  // the golden captures the wrapped baseline.
  testWidgets('AC-15 golden: relative-power line wraps without ellipsis (narrow)', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 200));
    const boundaryKey = ValueKey<String>('relative_power_narrow_wrap');

    await tester.pumpWidget(
      _lineHost(
        child: const RelativePowerLine(pct: 40),
        boundaryKey: boundaryKey,
        width: 130,
      ),
    );
    await _pumpBuilt(tester);

    expect(tester.takeException(), isNull);
    final Text text = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(RelativePowerLine),
            matching: find.byType(Text),
          )
          .first,
    );
    expect(text.overflow, isNot(TextOverflow.ellipsis));

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/diplomacy_relative_power_narrow_wrap.png'),
    );
  });

  // SPEC/ui/diplomacy-detail-screen.md § Acceptance Criteria: the CURRENT
  // RELATION card on the GAME30002 detail screen renders the relative-power
  // line above the relation summary for Great Power targets. This golden gives
  // the detail surface its missing pixel baseline.
  testWidgets('GAME30002 golden: detail screen CURRENT RELATION shows relative-power line', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 900));
    const boundaryKey = ValueKey<String>('diplomacy_detail_relative_power');

    final Game game = _detailGame();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.editorialMonocle,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: boundaryKey,
            child: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: 'gp1',
              factionId: 'gp2',
              factionDisplayName: 'Castile',
              kind: FactionKind.greatPower,
              relation: getRelation(game, 'gp1', 'gp2'),
            ),
          ),
        ),
      ),
    );
    await _pumpBuilt(tester);

    expect(find.text('CURRENT RELATION'), findsOneWidget);
    expect(find.byType(RelativePowerLine), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/diplomacy_detail_relative_power.png'),
    );
  });
}

// Pin the 320 dp minimum-viewport contract for the `DiplomacyDetailScreen`
// (GAME30002) full-screen feature route — extending the existing screen-,
// panel-, dialog-, and unit-panel-level pins
// (`mobile_320dp_min_viewport_test.dart`, `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `technology_screen_320dp_min_viewport_test.dart`) to the in-game
// diplomacy detail route opened from the diplomacy panel.
//
// `DiplomacyDetailScreen` mounts `CtGameFeatureScreenShell` with the dark
// editorial-monocle `CtTopBar` (back affordance + faction display-name
// title) above a `Center` / `ConstrainedBox(maxWidth: 600)` / `ListView`
// stack of `_DetailCard` widgets. At `kMinViewportWidth` (320 dp) the
// available width collapses to 320 dp; the chrome and the
// CURRENT RELATION / DIPLOMATIC HISTORY / (optional) DOSSIER cards must
// still lay out without `RenderFlex` overflow per the SPEC § Acceptance
// criteria (mobile-adaptation.md § 7) and the screen spec
// (`SPEC/ui/diplomacy-detail-screen.md` § Layout / wireframe).
//
// Each test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`) escapes
//    the framework — the contract every other `*_320dp_min_viewport_test.dart`
//    file relies on.
//  * The dark `CtTopBar` resolves to exactly one widget carrying the
//    target faction `displayName` as its title; a single `CtBackButton`
//    chevron remains reachable inside that bar.
//  * Each card title that the SPEC layout / wireframe declares for the
//    rendered variant is present in the widget tree (`CURRENT RELATION`,
//    `DIPLOMATIC HISTORY`, and — for `FactionKind.greatPower` — `DOSSIER`).
//  * For the `FactionKind.minor` variant the `DOSSIER` title is absent
//    so the spec's "GP-only dossier" branch is exercised at 320 dp.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of `DiplomacyDetailScreen` itself would still surface.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/diplomacy-detail-screen.md` § Layout / wireframe and
// § Acceptance criteria.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/min_viewport_harness.dart';
import 'support/widget_test_assets.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same screen renders its default chrome. Mirrors
/// the contract used by `mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`,
/// `dialogs_320dp_min_viewport_test.dart`,
/// `unit_panels_320dp_min_viewport_test.dart`, and
/// `trade_screen_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

const String _kHumanPlayerId = 'gp1';
const String _kOtherFactionId = 'gp2';
const String _kOtherFactionDisplayName = 'Other GP';

/// Minimal in-memory `Game` carrying a single human GP and one other GP
/// (which acts as the detail-screen target). Mirrors the helper used by
/// `diplomacy_detail_screen_test.dart` so this 320 dp pin asserts against
/// the same fixture surface as the existing AC tests, but adds an
/// optional history entry so the `DIPLOMATIC HISTORY` card is exercised
/// with a populated `LeftBorderTile` row at the minimum viewport.
Game _minimalDetailGame({
  required bool includeHistory,
  required bool includeDossier,
  required bool atWar,
}) {
  final otherPlayer = Player(
    id: _kOtherFactionId,
    displayName: _kOtherFactionDisplayName,
    isHuman: false,
    treasury: 0,
  );

  final humanPlayer = Player(
    id: _kHumanPlayerId,
    displayName: 'Human GP',
    isHuman: true,
    treasury: 0,
  );

  final relation = DiplomacyRelation(
    factionId1: _kHumanPlayerId,
    factionId2: _kOtherFactionId,
    score: 70,
    state: atWar ? RelationState.atWar : RelationState.atPeace,
  );

  return Game(
    id: 'test-detail-320dp',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [humanPlayer, otherPlayer],
    diplomacyRelations: [relation],
    diplomaticHistoryEvents: includeHistory
        ? [
            DiplomaticEvent(
              turn: 2,
              intraTurnIndex: 0,
              type: DiplomaticEventType.declareWar,
              participants: {_kHumanPlayerId, _kOtherFactionId},
              fromFactionId: _kHumanPlayerId,
              toFactionId: _kOtherFactionId,
            ),
          ]
        : const [],
    dossierEvidenceEntries: includeDossier
        ? [
            DossierEvidenceEntry(
              observerId: _kHumanPlayerId,
              subjectId: _kOtherFactionId,
              agendaType: 'test_agenda',
              turnNumber: 3,
              description: 'evidence-1',
            ),
          ]
        : const [],
  );
}

/// Pumps the [DiplomacyDetailScreen] at [size] via the shared
/// min-viewport harness ([pumpAtMinViewport]).
Future<void> _pumpDetailScreen(
  WidgetTester tester, {
  required Size size,
  required Game game,
  required FactionKind kind,
  required DiplomacyRelation? relation,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    child: DiplomacyDetailScreen(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      factionId: _kOtherFactionId,
      factionDisplayName: _kOtherFactionDisplayName,
      kind: kind,
      relation: relation,
    ),
    settle: true,
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DiplomacyDetailScreen (great '
    'power, history + dossier) @ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) DiplomacyDetailScreen greatPower @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar (title = faction '
        'displayName) + CtBackButton + all three card titles render',
        (WidgetTester tester) async {
          final game = _minimalDetailGame(
            includeHistory: true,
            includeDossier: true,
            atWar: true,
          );
          final relation = getRelation(
            game,
            _kHumanPlayerId,
            _kOtherFactionId,
          );

          await _pumpDetailScreen(
            tester,
            size: _kMinViewport,
            game: game,
            kind: FactionKind.greatPower,
            relation: relation,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: DiplomacyDetailScreen '
                'must not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The dark CtTopBar (back '
                'chevron + faction displayName title) above the '
                'Center/ConstrainedBox(maxWidth:600)/ListView stack of '
                '_DetailCard widgets (CURRENT RELATION + DIPLOMATIC '
                'HISTORY + DOSSIER) must lay out within the 320 dp '
                'column per SPEC/ui/diplomacy-detail-screen.md § Layout '
                '/ wireframe.',
          );

          final topBarFinder = find.byType(CtTopBar);
          expect(topBarFinder, findsOneWidget);
          final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
          expect(
            topBar.title,
            _kOtherFactionDisplayName,
            reason:
                'CtTopBar.title MUST equal the target faction '
                'displayName per SPEC/ui/diplomacy-detail-screen.md '
                '§ Widget contract (title = factionDisplayName).',
          );

          expect(
            find.descendant(
              of: topBarFinder,
              matching: find.byType(CtBackButton),
            ),
            findsOneWidget,
            reason:
                'The CtTopBar back chevron must remain reachable at '
                '320 dp so the user can navigate back to the diplomacy '
                'panel (SPEC/ui/diplomacy-detail-screen.md § Trigger '
                'conditions — Close).',
          );

          // All three GP card titles render in the ListView at 320 dp
          // per SPEC § Layout / wireframe.
          expect(find.text('CURRENT RELATION'), findsOneWidget);
          expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
          expect(find.text('DOSSIER'), findsOneWidget);
        },
      );

      testWidgets(
        'AC (positive) DiplomacyDetailScreen greatPower @ 320×640: '
        'populated history event sentence + dossier evidence row both '
        'render inside the ~288 dp content column',
        (WidgetTester tester) async {
          final game = _minimalDetailGame(
            includeHistory: true,
            includeDossier: true,
            atWar: true,
          );
          final relation = getRelation(
            game,
            _kHumanPlayerId,
            _kOtherFactionId,
          );

          await _pumpDetailScreen(
            tester,
            size: _kMinViewport,
            game: game,
            kind: FactionKind.greatPower,
            relation: relation,
          );

          expect(tester.takeException(), isNull);
          // The seeded declareWar history event resolves to a sentence
          // containing "declared war"; pin the body so the
          // _LeftBorderTile actually lays out the wrapping body text at
          // narrow widths (SPEC § Layout / wireframe — LeftBorderTile
          // per event).
          expect(find.textContaining('declared war'), findsOneWidget);
          // The seeded DossierEvidenceEntry description renders in the
          // GP-only DOSSIER card per SPEC § States and variants.
          expect(find.textContaining('evidence-1'), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DiplomacyDetailScreen (minor '
    'nation, no dossier) @ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) DiplomacyDetailScreen minor @ 320×640: no '
        'RenderFlex overflow exception, CtTopBar + CURRENT RELATION + '
        'DIPLOMATIC HISTORY render, DOSSIER section is absent',
        (WidgetTester tester) async {
          final game = _minimalDetailGame(
            includeHistory: false,
            includeDossier: false,
            atWar: false,
          );
          final relation = getRelation(
            game,
            _kHumanPlayerId,
            _kOtherFactionId,
          );

          await _pumpDetailScreen(
            tester,
            size: _kMinViewport,
            game: game,
            kind: FactionKind.minor,
            relation: relation,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: '
                'DiplomacyDetailScreen MUST keep its 320 dp overflow '
                'contract under the non-GP variant too (the dossier '
                'card is the only branch that differs — the chrome and '
                'the other two cards still need to lay out at 320 dp).',
          );

          expect(find.byType(CtTopBar), findsOneWidget);
          expect(find.text('CURRENT RELATION'), findsOneWidget);
          expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
          // SPEC § States and variants: non-GP renders no dossier
          // section, so the title MUST NOT be in the tree at 320 dp
          // either (negative AC for the GP-only branch).
          expect(
            find.text('DOSSIER'),
            findsNothing,
            reason:
                'kind != FactionKind.greatPower at 320 dp MUST NOT '
                'mount the DOSSIER card (SPEC/ui/diplomacy-detail-'
                'screen.md § States and variants — Non-GP).',
          );
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DiplomacyDetailScreen wide '
    'regression sentinel (Refs #2870 S10)',
    () {
      testWidgets(
        'Negative control: DiplomacyDetailScreen greatPower @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful)',
        (WidgetTester tester) async {
          final game = _minimalDetailGame(
            includeHistory: true,
            includeDossier: true,
            atWar: false,
          );
          final relation = getRelation(
            game,
            _kHumanPlayerId,
            _kOtherFactionId,
          );

          await _pumpDetailScreen(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            kind: FactionKind.greatPower,
            relation: relation,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(CtTopBar), findsOneWidget);
          expect(find.text('CURRENT RELATION'), findsOneWidget);
          expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
          expect(find.text('DOSSIER'), findsOneWidget);
        },
      );
    },
  );
}

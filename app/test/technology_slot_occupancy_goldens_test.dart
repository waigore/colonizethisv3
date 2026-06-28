// Visual goldens for the GAME40001 deliverable-3 slot-occupancy surfaces
// (Refs #3512): the persisted in-slot in-progress panel (an in-progress tech
// keeps rendering inside its slot from `Player.researchSlotAssignments` alone,
// with an empty `currentOrders` and no standalone "In progress" block) and the
// Cancel-with-forfeiture `CtConfirmDialog` warning. These close the deferred
// deliverable-3 visual-golden gap flagged on issue #3512.
//
// Each surface is rendered against `AppThemes.editorialMonocle` (the running-app
// dark theme) at device pixel ratio 1.0 inside a keyed `RepaintBoundary`,
// matching the committed golden harness pattern
// (`technology_slots_panel_parity_goldens_test.dart`,
// `research_slot_card_goldens_test.dart`). The structural finder assertions that
// map these states to their ACs live in
// `technology_panel_slot_occupancy_test.dart`; this file adds the
// `matchesGoldenFile` visual proof.
//
// SPEC: SPEC/ui/technology-panel.md § Slot occupancy + § Slot behaviour > Cancel
// + Acceptance criteria (Slot occupancy visual golden coverage).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';

import 'support/panel_test_fixtures.dart';

// Three prerequisite-free tier-1 techs occupy slots 0-2, mirroring the
// `technologyPersistedSlotFixture` Widgetbook fixture so the golden matches the
// reviewed story. Accrued progress is non-zero so the in-slot in-progress
// rendering is exercised.
const List<String> _kTechIds = <String>[
  kTechIdCropRotation,
  kTechIdSawMill,
  kTechIdLandEnclosure,
];
const List<int> _kCommittedRp = <int>[600, 300, 0];
const List<ResearchFundingLevel> _kFunding = <ResearchFundingLevel>[
  ResearchFundingLevel.medium,
  ResearchFundingLevel.high,
  ResearchFundingLevel.low,
];

Player _persistedInProgressPlayer(Player basePlayer) {
  final progress = <String, int>{
    for (var i = 0; i < _kTechIds.length; i++) _kTechIds[i]: _kCommittedRp[i],
  };
  final assignments = <int, ResearchSlotAssignment>{
    for (var i = 0; i < _kTechIds.length; i++)
      i: ResearchSlotAssignment(techId: _kTechIds[i], funding: _kFunding[i]),
  };
  return basePlayer.copyWith(
    treasury: 8000,
    researchSlots: 3,
    researchProgressByTechId: progress,
    researchSlotAssignments: assignments,
  );
}

Future<void> _pumpBoundary(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size viewport,
  required Widget child,
}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Player basePlayer;

  setUpAll(() {
    baseGame = buildTechnologyPanelTestGame();
    basePlayer = baseGame.players.first;
  });

  testWidgets(
    'golden: persisted in-progress slots render from assignments alone at '
    '360x640 mobile (Refs #3512)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'technologySlotsPersistedInProgressGolden',
      );
      const viewport = Size(360, 640);
      final player = _persistedInProgressPlayer(basePlayer);
      final game = baseGame.copyWith(
        players: [player, ...baseGame.players.skip(1)],
      );

      await _pumpBoundary(
        tester,
        boundaryKey: boundaryKey,
        viewport: viewport,
        child: SizedBox(
          width: viewport.width,
          height: viewport.height,
          child: SingleChildScrollView(
            child: TechnologyPanel(
              game: game,
              player: player,
              currentOrders: const Orders(),
              onOrdersChanged: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/technology_slots_persisted_in_progress_mobile_360.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: cancel-forfeiture warning dialog (Refs #3512)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchCancelForfeitureGolden');
      const points = 600;
      late String title;
      late String message;
      late String confirmLabel;
      late String cancelLabel;

      await _pumpBoundary(
        tester,
        boundaryKey: boundaryKey,
        viewport: const Size(540, 360),
        child: Builder(
          builder: (context) {
            final l10n = appL10n(context);
            title = l10n.technologyPanel_cancelWarningTitle;
            message = l10n.technologyPanel_cancelWarningMessage(
              techDisplayName(kTechIdCropRotation),
              points,
            );
            confirmLabel = l10n.technologyPanel_cancelWarningConfirm;
            cancelLabel = l10n.technologyPanel_cancelWarningKeep;
            return CtConfirmDialog(
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
            );
          },
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_cancel_forfeiture_dialog.png'),
      );
    },
  );
}

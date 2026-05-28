// Pins SPEC/ui contracts for narrow map detail host and diplomacy detail route:
// - SPEC/ui/game-map-narrow-detail-overlay-slot.md
// - SPEC/ui/diplomacy-detail-screen.md

import 'package:colonizethis_app/features/game/flame/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('GameMapNarrowDetailOverlaySlot (SPEC/ui/game-map-narrow-detail-overlay-slot.md)', () {
    testWidgets(
      'AC: overlay closed renders SizedBox.shrink without Province header',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(400, 600)),
              child: MaterialApp(
                home: Scaffold(
                  body: GameMapNarrowDetailOverlaySlot(
                    game: demoGameForOverlay,
                    region: demoRegionForOverlay,
                    humanPlayerId: demoGameForOverlay.players.first.id,
                    playerView: demoHumanPlayerViewForOverlay,
                    workTargetSelectionCache:
                        PerPlayerWorkTargetSelectionCache(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Province'), findsNothing);
        expect(find.byType(GameMapNarrowDetailOverlaySlot), findsOneWidget);
      },
    );

    testWidgets(
      'AC: open overlay uses one-third viewport height',
      (WidgetTester tester) async {
        const viewportHeight = 600.0;
        final expectedMaxHeight = viewportHeight * 0.33;

        await tester.binding.setSurfaceSize(const Size(400, viewportHeight));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(400, viewportHeight)),
              child: MaterialApp(
                home: Scaffold(
                  body: GameMapNarrowDetailOverlaySlot(
                    game: demoGameForOverlay,
                    region: demoRegionForOverlay,
                    humanPlayerId: demoGameForOverlay.players.first.id,
                    playerView: demoHumanPlayerViewForOverlay,
                    workTargetSelectionCache:
                        PerPlayerWorkTargetSelectionCache(),
                  ),
                ),
              ),
            ),
          ),
        );
        final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
        final container = ProviderScope.containerOf(ctx);
        container
            .read(mapProvincePanelProvider.notifier)
            .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
        await tester.pumpAndSettle();

        final constrained = find.byWidgetPredicate(
          (w) => w is SizedBox && (w.height! - expectedMaxHeight).abs() < 0.01,
        );
        expect(constrained, findsOneWidget);
        expect(find.text('Province'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: close control sets overlayOpen false on provider',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(400, 600)),
              child: MaterialApp(
                home: Scaffold(
                  body: GameMapNarrowDetailOverlaySlot(
                    game: demoGameForOverlay,
                    region: demoRegionForOverlay,
                    humanPlayerId: demoGameForOverlay.players.first.id,
                    playerView: demoHumanPlayerViewForOverlay,
                    workTargetSelectionCache:
                        PerPlayerWorkTargetSelectionCache(),
                  ),
                ),
              ),
            ),
          ),
        );
        final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
        final container = ProviderScope.containerOf(ctx);
        container
            .read(mapProvincePanelProvider.notifier)
            .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('overlay_close')));
        await tester.pumpAndSettle();

        expect(container.read(mapProvincePanelProvider).overlayOpen, isFalse);
      },
    );
  });

  group('DiplomacyDetailScreen (SPEC/ui/diplomacy-detail-screen.md)', () {
    Game storyGame({
      required bool includeHistory,
      required bool includeDossier,
      required FactionKind kind,
    }) {
      const humanId = 'gp_human';
      const rivalId = 'gp_rival';
      return Game(
        id: 'spec_test',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        turnTimeMapping: TurnTimeMapping.gdd01,
        players: [
          Player(
            id: humanId,
            displayName: 'England',
            isHuman: true,
            treasury: 0,
          ),
          Player(
            id: rivalId,
            displayName: 'Spain',
            isHuman: false,
            treasury: 0,
          ),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: humanId,
            factionId2: rivalId,
            score: 70,
            state: RelationState.atPeace,
          ),
        ],
        diplomaticHistoryEvents: includeHistory
            ? [
                DiplomaticEvent(
                  turn: 2,
                  intraTurnIndex: 0,
                  type: DiplomaticEventType.peace,
                  participants: {humanId, rivalId},
                  fromFactionId: humanId,
                  toFactionId: rivalId,
                ),
              ]
            : const [],
        dossierEvidenceEntries: includeDossier
            ? [
                DossierEvidenceEntry(
                  observerId: humanId,
                  subjectId: rivalId,
                  agendaType: 'test',
                  turnNumber: 2,
                  description: 'evidence line',
                ),
              ]
            : const [],
      );
    }

    Future<void> pumpScreen(
      WidgetTester tester, {
      required Game game,
      required FactionKind kind,
      required DiplomacyRelation? relation,
      required AppEventBus bus,
    }) async {
      const humanId = 'gp_human';
      const rivalId = 'gp_rival';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
          ],
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanId,
              factionId: rivalId,
              factionDisplayName: 'Spain',
              kind: kind,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'AC: Great Power shows dossier section title',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final game = storyGame(
          includeHistory: true,
          includeDossier: true,
          kind: FactionKind.greatPower,
        );

        await pumpScreen(
          tester,
          game: game,
          kind: FactionKind.greatPower,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        // Refs #2863 S5: card titles are uppercased per mockup GAME30002.
        expect(find.text('DOSSIER'), findsOneWidget);
        expect(find.text('evidence line'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: non-Great Power hides dossier section',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final game = storyGame(
          includeHistory: false,
          includeDossier: false,
          kind: FactionKind.minor,
        );

        await pumpScreen(
          tester,
          game: game,
          kind: FactionKind.minor,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        expect(find.text('DOSSIER'), findsNothing);
      },
    );

    testWidgets(
      'AC: empty history shows no-events copy',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final game = storyGame(
          includeHistory: false,
          includeDossier: false,
          kind: FactionKind.greatPower,
        );

        await pumpScreen(
          tester,
          game: game,
          kind: FactionKind.greatPower,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        expect(
          find.text('No recorded events with this faction.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC: back button emits PopNavigationEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        final game = storyGame(
          includeHistory: true,
          includeDossier: false,
          kind: FactionKind.greatPower,
        );

        await pumpScreen(
          tester,
          game: game,
          kind: FactionKind.greatPower,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        // Refs #2863 S5: detail screen now renders a CtTopBar with a
        // CtBackButton chevron instead of the legacy Material AppBar.
        await tester.tap(find.byType(CtBackButton));
        await tester.pumpAndSettle();

        expect(events.whereType<PopNavigationEvent>(), hasLength(1));
      },
    );

    testWidgets(
      'AC: formatDiplomaticEvent uses Unknown faction for undiscovered party',
      (WidgetTester tester) async {
        const humanId = 'gp_human';
        const event = DiplomaticEvent(
          turn: 1,
          intraTurnIndex: 0,
          type: DiplomaticEventType.declareWar,
          participants: {humanId, 'unknown_gp'},
          fromFactionId: humanId,
          toFactionId: 'unknown_gp',
        );
        final game = Game(
          id: 'unknown',
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          turnTimeMapping: TurnTimeMapping.gdd01,
          players: [
            Player(
              id: humanId,
              displayName: 'England',
              isHuman: true,
              treasury: 0,
            ),
          ],
          diplomaticHistoryEvents: [event],
        );

        final sentence = formatDiplomaticEvent(event, game, humanId);
        expect(sentence, contains('Unknown faction'));
      },
    );
  });
}

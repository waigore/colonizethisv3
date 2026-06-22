// Widget tests for the compact wide-row action cluster on the Diplomacy
// panel, pinning SPEC/ui/diplomacy-panel.md § Action button styling
// (compact variant metrics) and § Responsive layout (wide cluster width
// cap + left-to-right flow). Refs #3621.
//
// The fixture seeds a human Great Power `gp1` at peace with a second Great
// Power `gp2` so the row renders the full GP action matrix (multiple
// buttons), which is the case the issue targets for the trailing cluster.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

/// Human GP `gp1` holds an at-peace relation with GP `gp2`, so the GP row
/// renders the full overture + action matrix (several action buttons).
Game _greatPowerRowGame() {
  const ow = 'oldWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final rival = Province(
    id: '$ow|p2',
    regionId: ow,
    displayName: 'Rival',
    ownerId: 'gp2',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-action-cluster',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
    ],
  );
}

Widget _panelHost({required Size viewportSize}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: Scaffold(
        body: DiplomacyPanel(
          game: _greatPowerRowGame(),
          humanPlayerId: 'gp1',
          topology: _emptyTopology,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
}

Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  Future<void> bindSurface(WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
  }

  group('Diplomacy compact action cluster (Refs #3621)', () {
    test('cluster constants pin the compact contract', () {
      expect(kDiplomacyActionClusterMaxWidth, 180.0);
      expect(kDiplomacyActionWrapSpacing, 4.0);
      expect(kDiplomacyActionButtonMinHeight, 24.0);
    });

    testWidgets(
      'wide (> 500 dp): trailing cluster is capped to 180 dp and the action '
      'Wrap flows end-aligned with 4 dp gaps',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(800, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        expect(find.byKey(bodyKey), findsOneWidget);

        // The action cluster is wrapped in a ConstrainedBox(maxWidth: 180).
        final Finder cappedBox = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is ConstrainedBox &&
                w.constraints.maxWidth == kDiplomacyActionClusterMaxWidth,
          ),
        );
        expect(
          cappedBox,
          findsOneWidget,
          reason:
              'Wide variant must cap the trailing action cluster to '
              'kDiplomacyActionClusterMaxWidth (180 dp) so buttons flow '
              'left-to-right per SPEC § Responsive layout.',
        );

        // The action Wrap inside the capped cluster is end-aligned with the
        // normative 4 dp spacing/runSpacing.
        final Finder endWrap = find.descendant(
          of: cappedBox,
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is Wrap &&
                w.alignment == WrapAlignment.end &&
                w.spacing == kDiplomacyActionWrapSpacing &&
                w.runSpacing == kDiplomacyActionWrapSpacing,
          ),
        );
        expect(endWrap, findsOneWidget);
      },
    );

    testWidgets(
      'action buttons use the compact CtNinePatchButton variant '
      '(24 dp min height, 7 x 3 dp padding)',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(800, 1200)),
        );
        await _pumpBuilt(tester);

        final Finder compactButtons = find.byWidgetPredicate(
          (Widget w) =>
              w is CtNinePatchButton &&
              w.minHeight == kDiplomacyActionButtonMinHeight &&
              w.padding == kDiplomacyActionButtonPadding,
        );
        expect(
          compactButtons,
          findsWidgets,
          reason:
              'Every diplomacy action button must use the compact variant '
              '(kDiplomacyActionButtonMinHeight / kDiplomacyActionButtonPadding) '
              'per SPEC § Action button styling.',
        );

        // Negative guard: no diplomacy action button retains the default
        // 48 dp panel-button min height.
        final Finder defaultHeightButtons = find.byWidgetPredicate(
          (Widget w) => w is CtNinePatchButton && w.minHeight == 48,
        );
        expect(defaultHeightButtons, findsNothing);
      },
    );

    testWidgets(
      'narrow (<= 500 dp): action Wrap is start-aligned and not width-capped '
      '(no regression to wide flow)',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(480, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        final Finder startWrap = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Wrap && w.alignment == WrapAlignment.start,
          ),
        );
        expect(startWrap, findsOneWidget);

        // The narrow body must not introduce the 180 dp cluster cap.
        final Finder cappedBox = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is ConstrainedBox &&
                w.constraints.maxWidth == kDiplomacyActionClusterMaxWidth,
          ),
        );
        expect(cappedBox, findsNothing);
      },
    );
  });
}

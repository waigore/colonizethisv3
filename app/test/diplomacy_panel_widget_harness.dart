// Shared diplomacy panel widget-test pump helpers (Refs #4269 Slice E).
// Lives outside `app/test/support/` so harness modules do not count toward the
// support LOC ratchet.
// SPEC: SPEC/ui/diplomacy-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';

export 'diplomacy_panel_test_support.dart'
    show
        buildDiplomacyPanel,
        buildDiplomacyRows,
        pumpDiplomacyPanelBuilt,
        relativePowerSpanColors;

/// Default rich-fixture state for diplomacy panel widget tests.
class DiplomacyPanelRichFixture {
  DiplomacyPanelRichFixture._({
    required this.gameWithFactions,
    required this.gameWithNoDiscovered,
    required this.humanPlayerId,
    required this.topology,
  });

  factory DiplomacyPanelRichFixture.create() {
    final gameWithFactions = buildDiplomacyRichPanelTestGame();
    return DiplomacyPanelRichFixture._(
      gameWithFactions: gameWithFactions,
      gameWithNoDiscovered: buildDiplomacyPanelGameWithNoDiscoveredFactions(),
      humanPlayerId: gameWithFactions.players.isNotEmpty
          ? gameWithFactions.players.first.id
          : 'gp1',
      topology: const MapTopology(),
    );
  }

  final Game gameWithFactions;
  final Game gameWithNoDiscovered;
  final String humanPlayerId;
  final MapTopology topology;
}

Future<void> pumpDiplomacyPanelOnTallSurface(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerId,
  MapTopology topology = const MapTopology(),
  Orders currentOrders = const Orders(),
}) async {
  await bindDiplomacyTallTestSurface(tester);
  await tester.pumpWidget(
    buildDiplomacyPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      topology: topology,
      currentOrders: currentOrders,
    ),
  );
  await pumpDiplomacyPanelBuilt(tester);
}

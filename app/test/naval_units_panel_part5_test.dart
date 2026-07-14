// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/naval_units_panel_test_support.dart';
import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  group('Draft naval move subtitle', () {
    testWidgets('shows Moving to line when draft order present', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_draft_line';
      final draftGame = buildNavalPanelDraftMoveSubtitleGame(humanId: humanId);
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          humanId: [
            const NavalMoveOrder(
              fleetId: 'f_at_sea',
              destinationSeaZoneId: 'sz1',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        buildNavalPanel(
          game: draftGame,
          humanPlayerId: humanId,
          draftOrders: orders,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Moving to: Target Sea'), findsOneWidget);
    });
  });
}

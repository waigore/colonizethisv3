import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Advanced-start 50-turn scenario (Refs #3895 S16).
///
/// Requires `CT_E2E=true` and `CT_E2E_LOCKED_FULL_INIT=true` so DLG10001 uses
/// the locked full-init profile and the advanced-start dropdown is enabled.
const Duration kAdvancedStart50E2eBudget = Duration(seconds: 120);
const String kAdvancedStart50E2eTestName = 'new_game_advanced_start_50';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'new game with 50 Turns In reaches map HUD showing turn 50 / year 1598',
    (WidgetTester tester) async {
      expect(kCtE2EEnabled, isTrue);
      expect(kCtE2ELockedFullInitEnabled, isTrue);

      final bootstrap = await runIntegrationTestBootstrap(
        tester,
        testName: kAdvancedStart50E2eTestName,
        bootstrapForIntegrationTest: bootstrapForIntegrationTest,
      );
      final perf = bootstrap.perf;
      final testSw = bootstrap.testSw;

      await ensureAllRelocated64pxPngsLoadSuiteOnce();

      final budgetSw = Stopwatch()..start();
      final ensureUnderBudget = e2eMakeWallClockGuard(
        testName: kAdvancedStart50E2eTestName,
        stopwatch: budgetSw,
        cap: kAdvancedStart50E2eBudget,
      );

      await bootstrapNewGameToMap(
        tester,
        perf: perf,
        overallCap: kAdvancedStart50E2eBudget,
        advancedStartOptionLabel: '50 Turns In (1598)',
      );
      ensureUnderBudget('after new_game_to_map');

      expect(find.byKey(kGameMapNextTurnButtonKey), findsOneWidget);
      expect(find.textContaining('Next turn (50 / 1598)'), findsOneWidget);

      ensureUnderBudget('test complete');
      perf.timing('test_total', testSw.elapsed);
      perf.timing(
        'init_path_after_asset_preload',
        budgetSw.elapsed,
        meta: 'budget_ms=${kAdvancedStart50E2eBudget.inMilliseconds}',
      );
    },
  );
}

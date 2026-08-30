import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test(
    'kUiSurfaceOpenBudgetMs is 1000 (SPEC/program/ui-surface-budget.md)',
    () {
      expect(kUiSurfaceOpenBudgetMs, 1000);
    },
  );
}

// Widget test pin for Turn news court Widgetbook use cases (Refs #4532).
// SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Turn news Widgetbook court stories (Refs #4532)', () {
    for (final name in const [
      'Empty gazette + court',
      'Gazette + court',
      'Spy footer coexistence',
    ]) {
      testWidgets('$name is wired into turnNewsDialogDirectories', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          turnNewsDialogDirectories,
          folderName: 'Turn news',
          useCaseName: name,
        );
        expect(useCase.builder, isNotNull);
      });
    }
  });
}

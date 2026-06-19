// Pins the shared move-dialog chrome contract:
// SPEC/ui/components/move-units-dialog-base.md (Refs #3546).

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/move_units_dialog_base.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpRow(WidgetTester tester, Widget row) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: Scaffold(body: Center(child: row)),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration _outlineDecoration(WidgetTester tester) {
  // The outline Container is the outermost Container inside the row (the
  // radio-dot Containers are nested deeper), so `.first` selects it.
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(MoveDialogDestinationRow),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

Finder _filledAccentDotFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration! as BoxDecoration).color == EditorialMonoclePalette.accent,
  );
}

void main() {
  suppressLogsForTests();

  group('MoveDialogDestinationRow (SPEC/ui/components/move-units-dialog-base.md)',
      () {
    testWidgets(
      'idle row paints a 1 px --border outline and no filled --accent dot',
      (WidgetTester tester) async {
        await _pumpRow(
          tester,
          MoveDialogDestinationRow(
            selected: false,
            onTap: () {},
            semanticsLabel: 'Dest A',
            content: const Text('Dest A'),
          ),
        );

        final deco = _outlineDecoration(tester);
        final border = deco.border! as Border;
        expect(border.top.width, MoveDialogDestinationRow.idleBorderWidth);
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(_filledAccentDotFinder(), findsNothing);
      },
    );

    testWidgets(
      'selected row paints a 2 px --accent outline and a filled --accent dot',
      (WidgetTester tester) async {
        await _pumpRow(
          tester,
          MoveDialogDestinationRow(
            selected: true,
            onTap: () {},
            semanticsLabel: 'Dest A',
            content: const Text('Dest A'),
          ),
        );

        final deco = _outlineDecoration(tester);
        final border = deco.border! as Border;
        expect(border.top.width, MoveDialogDestinationRow.selectedBorderWidth);
        expect(border.top.color, EditorialMonoclePalette.accent);
        expect(_filledAccentDotFinder(), findsOneWidget);
      },
    );

    testWidgets('tap on the row invokes onTap exactly once', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await _pumpRow(
        tester,
        MoveDialogDestinationRow(
          selected: false,
          onTap: () => taps++,
          semanticsLabel: 'Dest A',
          content: const Text('Dest A'),
        ),
      );

      await tester.tap(find.text('Dest A'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('renders the trailing widget when supplied', (
      WidgetTester tester,
    ) async {
      await _pumpRow(
        tester,
        MoveDialogDestinationRow(
          selected: false,
          onTap: () {},
          semanticsLabel: 'Dest A',
          content: const Text('Dest A'),
          trailing: const Icon(Icons.my_location),
        ),
      );

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('omits any trailing widget when trailing is null', (
      WidgetTester tester,
    ) async {
      await _pumpRow(
        tester,
        MoveDialogDestinationRow(
          selected: false,
          onTap: () {},
          semanticsLabel: 'Dest A',
          content: const Text('Dest A'),
        ),
      );

      expect(find.byIcon(Icons.my_location), findsNothing);
    });
  });

  group('MoveDialogRadioDot', () {
    testWidgets('selected dot mounts a filled --accent inner circle', (
      WidgetTester tester,
    ) async {
      await _pumpRow(tester, const MoveDialogRadioDot(selected: true));
      expect(_filledAccentDotFinder(), findsOneWidget);
    });

    testWidgets('idle dot mounts no filled --accent inner circle', (
      WidgetTester tester,
    ) async {
      await _pumpRow(tester, const MoveDialogRadioDot(selected: false));
      expect(_filledAccentDotFinder(), findsNothing);
    });
  });
}

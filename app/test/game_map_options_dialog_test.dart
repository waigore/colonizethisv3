// Pins SPEC/ui/empire-overview.md § Map display options button and dialog
// (dark editorial-monocle chrome — Refs #2861 S8 / R9, Refs #2867 R1).

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/features/game/widgets/game_map_options_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _frame({
  required MapViewState initialState,
  required ValueChanged<MapViewState> onChanged,
}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierColor: EditorialMonoclePalette.dialogScrim,
                builder: (_) => GameMapOptionsDialog(
                  initialState: initialState,
                  onChanged: onChanged,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  suppressLogsForTests();

  group('GameMapOptionsDialog dark chrome (Refs #2861 S8 / Refs #2867 R1)', () {
    testWidgets('renders inside CtDialogShell with no Material AlertDialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _frame(
          initialState: MapViewState.defaults,
          onChanged: (_) {},
        ),
      );
      await _openDialog(tester);

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);

      // Default 2px --accent-dim border per CtDialogShell contract.
      final CtDialogShell shell = tester.widget<CtDialogShell>(
        find.byType(CtDialogShell),
      );
      expect(shell.borderColor, isNull); // defaults to accentDim
      expect(shell.borderWidth, CtDialogShell.defaultBorderWidth);
    });

    testWidgets('title resolves from localizations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _frame(
          initialState: MapViewState.defaults,
          onChanged: (_) {},
        ),
      );
      await _openDialog(tester);

      expect(find.text('Map display options'), findsOneWidget);
      expect(find.text('Show province overlay'), findsOneWidget);
      expect(find.text('Show province ownership'), findsOneWidget);
      expect(find.text('Show province names'), findsOneWidget);
    });

    testWidgets('renders three keyed CtToggleSwitch rows with default values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _frame(
          initialState: MapViewState.defaults,
          onChanged: (_) {},
        ),
      );
      await _openDialog(tester);

      expect(
        find.byType(CtToggleSwitch),
        findsNWidgets(3),
      );

      final overlay = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowProvinceOverlayToggleKey),
      );
      final ownership = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
      );
      final names = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowProvinceNamesToggleKey),
      );

      expect(overlay.value, isTrue);
      expect(ownership.value, isFalse);
      expect(names.value, isTrue);
    });

    testWidgets('Close action uses CtNinePatchButton (no Material TextButton)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _frame(
          initialState: MapViewState.defaults,
          onChanged: (_) {},
        ),
      );
      await _openDialog(tester);

      expect(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(CtNinePatchButton),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );

      final CtNinePatchButton close = tester.widget<CtNinePatchButton>(
        find.widgetWithText(CtNinePatchButton, 'Close'),
      );
      expect(close.dangerVariant, isFalse);
    });

    testWidgets(
        'toggling a switch updates local state and emits onChanged with new MapViewState',
        (WidgetTester tester) async {
      final List<MapViewState> emitted = <MapViewState>[];
      await tester.pumpWidget(
        _frame(
          initialState: MapViewState.defaults,
          onChanged: emitted.add,
        ),
      );
      await _openDialog(tester);

      await tester.tap(
        find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(emitted, hasLength(1));
      expect(emitted.last.showProvinceOwnershipTint, isTrue);
      // Other fields unchanged from default.
      expect(emitted.last.showProvinceOverlay, isTrue);
      expect(emitted.last.showProvinceNamesLayer, isTrue);

      // Local state updated immediately within the same dialog session.
      final ownership = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
      );
      expect(ownership.value, isTrue);
    });

    testWidgets('Close button dismisses the dialog without emitting onChanged',
        (WidgetTester tester) async {
      final List<MapViewState> emitted = <MapViewState>[];
      await tester.pumpWidget(
        _frame(
          initialState: MapViewState.defaults,
          onChanged: emitted.add,
        ),
      );
      await _openDialog(tester);

      await tester.tap(find.widgetWithText(CtNinePatchButton, 'Close'));
      await tester.pumpAndSettle();

      expect(find.byType(CtDialogShell), findsNothing);
      expect(emitted, isEmpty);
    });
  });
}

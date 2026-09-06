// Pins SPEC/ui/empire-overview.md § Map display options button and dialog
// (dark editorial-monocle chrome — Refs #2861 S8 / R9, Refs #2867 R1).

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_map_options_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  group('GameMapOptionsDialog dark chrome (Refs #2861 S8 / Refs #2867 R1)', () {
    testWidgets('renders inside CtDialogShell with no Material AlertDialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        gameMapOptionsDialogFrame(
          initialState: MapViewState.defaults,
          onChanged: (_) {},
        ),
      );
      await openGameMapOptionsDialog(tester);

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);

      final CtDialogShell shell = tester.widget<CtDialogShell>(
        find.byType(CtDialogShell),
      );
      expect(shell.borderColor, isNull);
      expect(shell.borderWidth, CtDialogShell.defaultBorderWidth);
    });

    testWidgets('title resolves from localizations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        gameMapOptionsDialogFrame(
          initialState: MapViewState.defaults,
          onChanged: (_) {},
        ),
      );
      await openGameMapOptionsDialog(tester);

      expect(find.text('Map display options'), findsOneWidget);
      expect(find.text('Map marks'), findsOneWidget);
      expect(find.text('Show resources'), findsOneWidget);
      expect(find.text('Show improvements'), findsOneWidget);
      expect(find.text('Show roads and rails'), findsOneWidget);
      expect(find.text('Show province and sea borders'), findsOneWidget);
      expect(find.text('Show province ownership'), findsOneWidget);
      expect(find.text('Show province names'), findsOneWidget);
      expect(
        find.text('Highlight land not bound to the capital'),
        findsOneWidget,
      );
    });

    testWidgets('renders seven keyed CtToggleSwitch rows with default values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        gameMapOptionsDialogFrame(
          initialState: MapViewState.defaults,
          onChanged: (_) {},
        ),
      );
      await openGameMapOptionsDialog(tester);

      expect(find.byType(CtToggleSwitch), findsNWidgets(7));

      final resources = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowMapResourcesToggleKey),
      );
      final improvements = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowMapImprovementsToggleKey),
      );
      final roads = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowMapRoadsToggleKey),
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
      final capitalLink = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowCapitalLinkDisconnectedToggleKey),
      );

      expect(resources.value, isTrue);
      expect(improvements.value, isTrue);
      expect(roads.value, isTrue);
      expect(roads.onChanged, isNotNull);
      expect(overlay.value, isTrue);
      expect(ownership.value, isFalse);
      expect(names.value, isTrue);
      expect(capitalLink.value, isTrue);
    });

    testWidgets(
      'Close action uses CtNinePatchButton (no Material TextButton)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          gameMapOptionsDialogFrame(
            initialState: MapViewState.defaults,
            onChanged: (_) {},
          ),
        );
        await openGameMapOptionsDialog(tester);

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
      },
    );

    testWidgets(
      'toggling a switch updates local state and emits onChanged with new MapViewState',
      (WidgetTester tester) async {
        final List<MapViewState> emitted = <MapViewState>[];
        await tester.pumpWidget(
          gameMapOptionsDialogFrame(
            initialState: MapViewState.defaults,
            onChanged: emitted.add,
          ),
        );
        await openGameMapOptionsDialog(tester);

        await tester.tap(
          find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(emitted, hasLength(1));
        expect(emitted.last.showProvinceOwnershipTint, isTrue);
        expect(emitted.last.showProvinceOverlay, isTrue);
        expect(emitted.last.showProvinceNamesLayer, isTrue);

        final ownership = tester.widget<CtToggleSwitch>(
          find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
        );
        expect(ownership.value, isTrue);
      },
    );

    testWidgets(
      'Close button dismisses the dialog without emitting onChanged',
      (WidgetTester tester) async {
        final List<MapViewState> emitted = <MapViewState>[];
        await tester.pumpWidget(
          gameMapOptionsDialogFrame(
            initialState: MapViewState.defaults,
            onChanged: emitted.add,
          ),
        );
        await openGameMapOptionsDialog(tester);

        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Close'));
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsNothing);
        expect(emitted, isEmpty);
      },
    );
  });
}

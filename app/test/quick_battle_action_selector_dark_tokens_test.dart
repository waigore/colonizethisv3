import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_action_selector.dart';

/// Pins SPEC/ui/quick-battle-action-selector.md § Layout / wireframe and the
/// dark-theme `--muted` AC added under Refs #2869 S4 R17.
///
/// The CP indicator `Text` must resolve its foreground color to the canonical
/// `EditorialMonoclePalette.muted` token while still inheriting the rest of
/// `Theme.of(context).textTheme.titleSmall`.
void main() {
  suppressLogsForTests();

  Widget frame(Widget child) {
    // appL10n() falls back to English when no localization delegate is wired
    // (see app/lib/l10n/l10n.dart); no delegates needed for these widget
    // tests.
    return MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: Scaffold(body: Center(child: child)),
    );
  }

  Text findCpIndicator(WidgetTester tester) {
    final List<Text> matches = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => (t.data ?? '').contains('Command Points'))
        .toList();
    expect(matches, hasLength(1),
        reason: 'Action selector should render exactly one CP indicator '
            '(Command Points: <n>) per the spec.');
    return matches.single;
  }

  group('QuickBattleActionSelector dark editorial-monocle tokens', () {
    testWidgets('CP indicator resolves to --muted color (full CP)',
        (tester) async {
      await tester.pumpWidget(
        frame(
          QuickBattleActionSelector(
            cpRemaining: 3,
            onActionSelected: (_) {},
          ),
        ),
      );
      final Text indicator = findCpIndicator(tester);
      expect(indicator.style, isNotNull,
          reason: 'CP indicator Text must explicitly carry a TextStyle.');
      expect(indicator.style!.color, EditorialMonoclePalette.muted,
          reason:
              'Per #2869 R17 + SPEC/ui/quick-battle-action-selector.md, the '
              'CP indicator text color must resolve to '
              'EditorialMonoclePalette.muted (the --muted token).');
    });

    testWidgets('CP indicator stays --muted when CP is spent', (tester) async {
      await tester.pumpWidget(
        frame(
          QuickBattleActionSelector(
            cpRemaining: 0,
            onActionSelected: (_) {},
          ),
        ),
      );
      final Text indicator = findCpIndicator(tester);
      expect(indicator.style?.color, EditorialMonoclePalette.muted,
          reason: '--muted color must hold across CP variants.');
    });

    testWidgets(
        'CP indicator inherits font size/weight from titleSmall (only color overridden)',
        (tester) async {
      await tester.pumpWidget(
        frame(
          QuickBattleActionSelector(
            cpRemaining: 3,
            onActionSelected: (_) {},
          ),
        ),
      );

      late TextStyle titleSmallStyle;
      await tester.pumpWidget(
        frame(
          Builder(
            builder: (context) {
              titleSmallStyle =
                  Theme.of(context).textTheme.titleSmall ?? const TextStyle();
              return QuickBattleActionSelector(
                cpRemaining: 3,
                onActionSelected: (_) {},
              );
            },
          ),
        ),
      );

      final Text indicator = findCpIndicator(tester);
      expect(indicator.style?.fontSize, titleSmallStyle.fontSize,
          reason: 'Only color is overridden — the rest must come from theme.');
      expect(indicator.style?.fontWeight, titleSmallStyle.fontWeight,
          reason: 'titleSmall font weight should be preserved.');
    });
  });
}

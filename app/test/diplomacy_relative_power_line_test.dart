// Widget tests for the shared RelativePowerLine + diplomacy detail wiring.
// SPEC/ui/diplomacy-panel.md § Relative power line,
// SPEC/ui/diplomacy-detail-screen.md § Current relation. Refs #3622.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/relative_power_line.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Size? size}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: size == null
            ? child
            : SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );
}

({TextSpan label, TextSpan pct, TextSpan separator, TextSpan tier})
_spans(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find
        .descendant(
          of: find.byType(RelativePowerLine),
          matching: find.byType(RichText),
        )
        .first,
  );
  // `Text.rich` nests the supplied root span under the effective-style span
  // that `Text` builds, so the relative-power spans live one level deeper.
  final rootSpan = (richText.text as TextSpan).children!.first as TextSpan;
  final children = rootSpan.children!;
  return (
    label: children[0] as TextSpan,
    pct: children[1] as TextSpan,
    separator: children[2] as TextSpan,
    tier: children[3] as TextSpan,
  );
}

void main() {
  suppressLogsForTests();

  group('RelativePowerLine (SPEC § Relative power line)', () {
    testWidgets('positive pct renders +N% and tier in --danger', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const RelativePowerLine(pct: 22)));
      await tester.pump();

      final spans = _spans(tester);
      expect(spans.label.text, 'Relative power: ');
      expect(spans.label.style?.color, EditorialMonoclePalette.muted);
      expect(spans.pct.text, '+22%');
      expect(spans.pct.style?.color, EditorialMonoclePalette.danger);
      expect(spans.pct.style?.fontWeight, FontWeight.w600);
      expect(spans.tier.text, 'Superior');
      expect(spans.tier.style?.color, EditorialMonoclePalette.danger);
    });

    testWidgets('zero pct renders 0% · Roughly equal in --success', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const RelativePowerLine(pct: 0)));
      await tester.pump();

      final spans = _spans(tester);
      expect(spans.pct.text, '0%');
      expect(spans.pct.style?.color, EditorialMonoclePalette.success);
      expect(spans.tier.text, 'Roughly equal');
      expect(spans.tier.style?.color, EditorialMonoclePalette.success);
    });

    testWidgets('negative pct renders −N% (U+2212) and tier in --success', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const RelativePowerLine(pct: -22)));
      await tester.pump();

      final spans = _spans(tester);
      expect(spans.pct.text, '\u221222%');
      expect(spans.pct.style?.color, EditorialMonoclePalette.success);
      expect(spans.tier.text, 'Inferior');
      expect(spans.tier.style?.color, EditorialMonoclePalette.success);
    });

    testWidgets('boundary +11 is Superior; +10 is Roughly equal', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const RelativePowerLine(pct: 11)));
      await tester.pump();
      expect(_spans(tester).tier.text, 'Superior');

      await tester.pumpWidget(_host(const RelativePowerLine(pct: 10)));
      await tester.pump();
      expect(_spans(tester).tier.text, 'Roughly equal');
    });

    testWidgets('carries an explanatory Tooltip', (tester) async {
      await tester.pumpWidget(_host(const RelativePowerLine(pct: 5)));
      await tester.pump();

      final tooltip = tester.widget<Tooltip>(
        find
            .descendant(
              of: find.byType(RelativePowerLine),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(tooltip.message, isNotNull);
      expect(tooltip.message, contains('military power score'));
    });

    testWidgets('exposes a combined semanticsLabel', (tester) async {
      await tester.pumpWidget(_host(const RelativePowerLine(pct: 22)));
      await tester.pump();

      final richText = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(RelativePowerLine),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(richText.text.toPlainText(), 'Relative power: +22% \u00b7 Superior');
    });

    testWidgets('wraps without ellipsis at the 320 dp minimum viewport', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const RelativePowerLine(pct: -31),
          size: const Size(320, 200),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(RelativePowerLine),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });
  });

  group('DiplomacyDetailScreen relative-power line (Refs #3622)', () {
    Game gameWith({required bool gpStronger}) {
      // Human GP gp1 owns one province; gp2 owns provinces controlling the
      // relative power score so the comparison sign is deterministic.
      const ow = 'oldWorld';
      final provinces = <Province>[
        Province(id: '$ow|p1', regionId: ow, displayName: 'P1', ownerId: 'gp1'),
        Province(id: '$ow|p2', regionId: ow, displayName: 'P2', ownerId: 'gp2'),
      ];
      if (gpStronger) {
        provinces.add(
          Province(id: '$ow|p3', regionId: ow, displayName: 'P3', ownerId: 'gp2'),
        );
        provinces.add(
          Province(id: '$ow|p4', regionId: ow, displayName: 'P4', ownerId: 'gp2'),
        );
      }
      return Game(
        id: 'detail-relpower',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: provinces, units: const []),
          newWorld: const RegionData(),
        ),
        turnTimeMapping: TurnTimeMapping.gdd01,
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Other GP', isHuman: false),
        ],
        diplomacyRelations: const [],
      );
    }

    testWidgets('Great Power target renders the relative-power line', (
      tester,
    ) async {
      final game = gameWith(gpStronger: true);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: 'gp1',
              factionId: 'gp2',
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: getRelation(game, 'gp1', 'gp2'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.byType(RelativePowerLine), findsOneWidget);
      // gp2 owns strictly more provinces, so its score exceeds the human's.
      final spans = _spans(tester);
      expect(spans.pct.style?.color, EditorialMonoclePalette.danger);
    });

    testWidgets('Minor target renders no relative-power line', (tester) async {
      final game = gameWith(gpStronger: true);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: 'gp1',
              factionId: 'gp2',
              factionDisplayName: 'Other GP',
              kind: FactionKind.minor,
              relation: getRelation(game, 'gp1', 'gp2'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.byType(RelativePowerLine), findsNothing);
    });
  });
}

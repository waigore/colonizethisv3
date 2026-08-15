// Presentational MAP30001 radial. SPEC/ui/tile-context-radial.md (Refs #4440).

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_keys.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

List<TileRadialSpokeView> _wedges({bool exploreEnabled = true}) {
  return [
    TileRadialSpokeView(
      action: TileRadialCatalogAction.explore,
      enabled: exploreEnabled,
      label: 'Explore',
      tooltip: 'Need an Explorer in this province.',
    ),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.prospect,
      enabled: true,
      label: 'Prospect',
      tooltip: 'Prospect with explorer',
    ),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.buildImprovement,
      enabled: true,
      label: 'Build improvement',
      tooltip: 'Build improvement',
    ),
  ];
}

Future<void> _pumpRadial(
  WidgetTester tester, {
  required List<TileRadialSpokeView> wedges,
  required ValueChanged<TileRadialCatalogAction> onWedge,
  required VoidCallback onMore,
  required VoidCallback onDismiss,
  Size viewport = const Size(400, 400),
  Offset anchor = const Offset(200, 200),
}) {
  return pumpAppShell(
    tester,
    viewport: viewport,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: TileContextRadial(
      placeLine: 'Place: Wessex',
      wedges: wedges,
      onWedge: onWedge,
      onMore: onMore,
      onDismiss: onDismiss,
      anchor: anchor,
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('shows catalog wedges plus More and omits excluded actions', (
    tester,
  ) async {
    await _pumpRadial(
      tester,
      wedges: _wedges(),
      onWedge: (_) {},
      onMore: () {},
      onDismiss: () {},
    );
    expect(find.byKey(kTileContextRadialKey), findsOneWidget);
    expect(find.byKey(kTileRadialExploreKey), findsOneWidget);
    expect(find.byKey(kTileRadialProspectKey), findsOneWidget);
    expect(find.byKey(kTileRadialBuildImprovementKey), findsOneWidget);
    expect(find.byKey(kTileRadialMoreKey), findsOneWidget);
    expect(find.text('Spy station'), findsNothing);
    expect(find.text('Blockade'), findsNothing);
    expect(find.text('Move'), findsNothing);
    expect(find.text('Establish Consulate'), findsNothing);
  });

  testWidgets('enabled Explore spoke reports the catalog action', (
    tester,
  ) async {
    TileRadialCatalogAction? committed;
    await _pumpRadial(
      tester,
      wedges: _wedges(),
      onWedge: (action) => committed = action,
      onMore: () {},
      onDismiss: () {},
    );
    await tester.tap(find.byKey(kTileRadialExploreKey));
    await tester.pump();
    expect(committed, TileRadialCatalogAction.explore);
  });

  testWidgets('disabled Explore spoke does not commit', (tester) async {
    var committed = false;
    await _pumpRadial(
      tester,
      wedges: _wedges(exploreEnabled: false),
      onWedge: (_) => committed = true,
      onMore: () {},
      onDismiss: () {},
    );
    await tester.tap(find.byKey(kTileRadialExploreKey));
    await tester.pump();
    expect(committed, isFalse);
  });

  testWidgets('outside tap and Escape dismiss', (tester) async {
    var dismissed = 0;
    await _pumpRadial(
      tester,
      wedges: _wedges(),
      onWedge: (_) {},
      onMore: () {},
      onDismiss: () => dismissed++,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(dismissed, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(dismissed, 2);
  });

  testWidgets('More spoke is always present even with an empty catalog', (
    tester,
  ) async {
    var more = false;
    await _pumpRadial(
      tester,
      wedges: const [],
      onWedge: (_) {},
      onMore: () => more = true,
      onDismiss: () {},
    );
    expect(find.byKey(kTileRadialMoreKey), findsOneWidget);
    await tester.tap(find.byKey(kTileRadialMoreKey));
    await tester.pump();
    expect(more, isTrue);
  });
}

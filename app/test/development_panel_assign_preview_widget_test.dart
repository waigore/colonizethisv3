// Widget pins for Development Assign tile/level/cost preview (Refs #4472).
// SPEC/ui/components/development-assign-row.md.

import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_panel_scope_list.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const _scope = 'oldWorld|p1';
const _tileA = 'oldWorld|p1|0|0';
const _tileB = 'oldWorld|p1|1|0';
const _names = {_scope: 'Avalon'};

const _enabledCandidate = DevelopmentImproveAssignCandidate(
  builderUnitId: 'b1',
  targetTileKey: _tileA,
  isCapitalConnected: true,
  currentImprovementLevel: 1,
  materialCosts: {'lumber': 4, 'castIron': 4},
);

DevelopmentPanelRegionModel _grainRegion() {
  return const DevelopmentPanelRegionModel(
    regionId: kRegionOldWorld,
    ownedScopes: [
      DevelopmentPanelScopeRow(
        scopeKey: _scope,
        provinceId: _scope,
        displayName: 'Avalon',
        improvableCommodities: [
          DevelopmentImprovableCommodityRow(
            commodityId: 'grain',
            tileKeys: [_tileA, _tileB],
          ),
        ],
      ),
    ],
    purchasedScopes: [],
    landExtractionByCommodity: {},
    idleBuilderCount: 1,
    idleEngineerCount: 0,
  );
}

Future<void> _pumpList(
  WidgetTester tester, {
  required DevelopmentAssignRowState Function(String, String) assignRowStateFor,
  void Function(Set<String> keys, {String? selectedTileKey})? onShowTiles,
  void Function(DevelopmentImproveAssignCandidate candidate)? onAssign,
  Size size = const Size(360, 640),
}) async {
  await pumpAppShell(
    tester,
    viewport: size,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: DevelopmentPanelScopeList(
      regionModel: _grainRegion(),
      onShowTiles: onShowTiles ?? (keys, {selectedTileKey}) {},
      assignRowStateFor: assignRowStateFor,
      onAssign: onAssign ?? (_) {},
      provinceDisplayNamesById: _names,
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'enabled Assign row shows place, 1 → 2, and lumber + cast iron 4',
    (tester) async {
      await _pumpList(
        tester,
        assignRowStateFor: (_, _) => const DevelopmentAssignRowState(
          enabled: true,
          candidate: _enabledCandidate,
        ),
      );
      final preview = find.byKey(
        DevelopmentPanelKeys.assignPreviewKey(_scope, 'grain'),
      );
      expect(preview, findsOneWidget);
      expect(
        tester.widget<Text>(preview).data,
        'Next: Avalon (0, 0) · 1 → 2 · Cast iron 4, Lumber 4',
      );
      expect(find.textContaining('oldWorld|p1|0|0'), findsNothing);
      expect(find.textContaining('build_improvement'), findsNothing);
    },
  );

  testWidgets('Show reports the auto-picked tile among commodity keys', (
    tester,
  ) async {
    Set<String>? shown;
    String? selected;
    await _pumpList(
      tester,
      assignRowStateFor: (_, _) => const DevelopmentAssignRowState(
        enabled: true,
        candidate: _enabledCandidate,
      ),
      onShowTiles: (keys, {selectedTileKey}) {
        shown = keys;
        selected = selectedTileKey;
      },
    );
    await tester.tap(
      find.byKey(DevelopmentPanelKeys.showButtonKey(_scope, 'grain')),
    );
    expect(shown, {_tileA, _tileB});
    expect(selected, _tileA);
    expect(
      find.byKey(DevelopmentPanelKeys.assignPreviewKey(_scope, 'grain')),
      findsOneWidget,
    );
  });

  testWidgets('disabled Assign keeps refusal tooltip and hides spend preview', (
    tester,
  ) async {
    var assigned = false;
    await _pumpList(
      tester,
      assignRowStateFor: (_, _) => const DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'No idle Builders',
      ),
      onAssign: (_) => assigned = true,
    );
    expect(
      find.byKey(DevelopmentPanelKeys.assignPreviewKey(_scope, 'grain')),
      findsNothing,
    );
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'No idle Builders');
    await tester.tap(
      find.byKey(DevelopmentPanelKeys.assignButtonKey(_scope, 'grain')),
    );
    expect(assigned, isFalse);
  });

  testWidgets('disconnected enabled preview states not bound to the capital', (
    tester,
  ) async {
    await _pumpList(
      tester,
      assignRowStateFor: (_, _) => const DevelopmentAssignRowState(
        enabled: true,
        candidate: DevelopmentImproveAssignCandidate(
          builderUnitId: 'b1',
          targetTileKey: _tileB,
          isCapitalConnected: false,
          currentImprovementLevel: 0,
          materialCosts: {'lumber': 1, 'castIron': 1},
        ),
      ),
    );
    expect(find.textContaining('not bound to the capital'), findsOneWidget);
  });

  testWidgets('connected Assign commits in one tap with no confirm dialog', (
    tester,
  ) async {
    DevelopmentImproveAssignCandidate? assigned;
    await _pumpList(
      tester,
      assignRowStateFor: (_, _) => const DevelopmentAssignRowState(
        enabled: true,
        candidate: _enabledCandidate,
      ),
      onAssign: (c) => assigned = c,
    );
    await tester.tap(
      find.byKey(DevelopmentPanelKeys.assignButtonKey(_scope, 'grain')),
    );
    expect(assigned?.targetTileKey, _tileA);
    expect(find.text('Not connected to capital'), findsNothing);
  });

  testWidgets('preview wraps at 320 dp without overflow', (tester) async {
    await _pumpList(
      tester,
      size: const Size(320, 640),
      assignRowStateFor: (_, _) => const DevelopmentAssignRowState(
        enabled: true,
        candidate: _enabledCandidate,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(DevelopmentPanelKeys.assignPreviewKey(_scope, 'grain')),
      findsOneWidget,
    );
  });
}

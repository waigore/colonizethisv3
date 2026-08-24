// Development Assign preview copy (Refs #4472).
// SPEC/ui/components/development-assign-row.md.

import 'package:colonizethis_app/features/game/screens/development/development_assign_preview.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const names = {'oldWorld|p1': 'Avalon'};

  test('place uses province name and coordinates, not a raw tile key', () {
    final place = formatDevelopmentAssignPreviewPlace(
      tileKey: 'oldWorld|p1|0|0',
      provinceDisplayNamesById: names,
    );
    expect(place, 'Avalon (0, 0)');
    expect(place.contains('|'), isFalse);
  });

  test('enabled preview names place, 1 → 2, and lumber + cast iron 4', () {
    const state = DevelopmentAssignRowState(
      enabled: true,
      candidate: DevelopmentImproveAssignCandidate(
        builderUnitId: 'b1',
        targetTileKey: 'oldWorld|p1|0|0',
        isCapitalConnected: true,
        currentImprovementLevel: 1,
        materialCosts: {'lumber': 4, 'castIron': 4},
      ),
    );
    final line = formatDevelopmentAssignPreviewLine(
      l10n: l10n,
      assignState: state,
      provinceDisplayNamesById: names,
    );
    expect(line, isNotNull);
    expect(line, contains('Avalon (0, 0)'));
    expect(line, contains('1 → 2'));
    expect(line, contains('Lumber 4'));
    expect(line, contains('Cast iron 4'));
    expect(line!.contains('oldWorld|p1|0|0'), isFalse);
    expect(line.contains(kWorkTargetBuildImprovement), isFalse);
  });

  test('disconnected preview states not bound to the capital', () {
    const state = DevelopmentAssignRowState(
      enabled: true,
      candidate: DevelopmentImproveAssignCandidate(
        builderUnitId: 'b1',
        targetTileKey: 'oldWorld|p1|1|0',
        isCapitalConnected: false,
        currentImprovementLevel: 0,
        materialCosts: {'lumber': 1, 'castIron': 1},
      ),
    );
    final line = formatDevelopmentAssignPreviewLine(
      l10n: l10n,
      assignState: state,
      provinceDisplayNamesById: names,
    );
    expect(line, contains(l10n.development_assignPreviewNotBoundToCapital));
  });

  test('disabled assign has no spend preview', () {
    const state = DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'Insufficient materials',
      candidate: DevelopmentImproveAssignCandidate(
        builderUnitId: 'b1',
        targetTileKey: 'oldWorld|p1|0|0',
        isCapitalConnected: true,
        currentImprovementLevel: 1,
        materialCosts: {'lumber': 4, 'castIron': 4},
      ),
    );
    expect(
      formatDevelopmentAssignPreviewLine(
        l10n: l10n,
        assignState: state,
        provinceDisplayNamesById: names,
      ),
      isNull,
    );
  });

  test('waived empty cost omits the material segment', () {
    const state = DevelopmentAssignRowState(
      enabled: true,
      candidate: DevelopmentImproveAssignCandidate(
        builderUnitId: 'b1',
        targetTileKey: 'oldWorld|p1|0|0',
        isCapitalConnected: true,
      ),
    );
    final line = formatDevelopmentAssignPreviewLine(
      l10n: l10n,
      assignState: state,
      provinceDisplayNamesById: names,
    );
    expect(line, 'Next: Avalon (0, 0) · 0 → 1');
    expect(line, isNot(contains('Lumber')));
  });

  test('enabled preview appends next-yield gist', () {
    const state = DevelopmentAssignRowState(
      enabled: true,
      candidate: DevelopmentImproveAssignCandidate(
        builderUnitId: 'b1',
        targetTileKey: 'oldWorld|p1|0|0',
        isCapitalConnected: true,
        currentImprovementLevel: 0,
        materialCosts: {'lumber': 1, 'castIron': 1},
      ),
    );
    final line = formatDevelopmentAssignPreviewLine(
      l10n: l10n,
      assignState: state,
      provinceDisplayNamesById: names,
      nextYieldGist: 'After this work: 0 → 1 Grain if still linked',
    );
    expect(line, contains('Avalon (0, 0)'));
    expect(line, contains('0 → 1'));
    expect(line, contains('if still linked'));
    expect(line!.contains('build_improvement'), isFalse);
  });
}

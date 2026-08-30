import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

/// Connectivity GA tunability registry pins (Refs #4176 AC-G1).
/// Split from [full_ai_civilian_work_connectivity_selection_test.dart] for #4683.
void main() {
  group('Connectivity GA tunability (AC-G1)', () {
    test('connectivity scoring constants are registered in the registry', () {
      for (final name in const [
        'kEngineerFrontierRoadExtensionBonus',
        'kBuildImprovementConnectedBonus',
        'kBuildImprovementAdjacentToConnectedBonus',
        'kBuildRailBottleneckYieldBonus',
        'kEngineerPortOverseasLinkageBonus',
      ]) {
        final p = AiParameterRegistry.byName(name);
        expect(p, isNotNull, reason: name);
        expect(p!.category, AiParameterCategory.victoryConfig, reason: name);
        expect(p.isInteger, isTrue, reason: name);
        expect(p.minValue, 0, reason: name);
        expect(
          p.maxValue,
          greaterThanOrEqualTo(2000),
          reason: name,
        );
      }
    });
  });
}

// Display-only Build improvement next-yield gist (Refs #4627).
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  test('raise gist names current to next goods if still linked', () {
    const preview = BuildImprovementYieldPreview(
      commodityId: 'grain',
      currentEffective: 0,
      nextEffective: 1,
      kind: BuildImprovementYieldKind.raise,
    );
    final line = buildImprovementNextYieldGistLine(
      l10n: l10n,
      preview: preview,
    );
    expect(line, contains('0'));
    expect(line, contains('1'));
    expect(line.toLowerCase(), contains('grain'));
    expect(line.toLowerCase(), contains('still linked'));
    expect(line.toLowerCase(), isNot(contains('warehouse')));
    expect(line, isNot(contains('build_improvement')));
    expect(line, isNot(contains('this Next turn')));
  });

  test('road cap gist names the road as the limit', () {
    const preview = BuildImprovementYieldPreview(
      commodityId: 'timber',
      currentEffective: 2,
      nextEffective: 2,
      kind: BuildImprovementYieldKind.roadPathLimit,
    );
    final line = buildImprovementNextYieldGistLine(
      l10n: l10n,
      preview: preview,
    );
    expect(line, contains('2'));
    expect(line.toLowerCase(), contains('timber'));
    expect(line.toLowerCase(), contains('road'));
    expect(line.toLowerCase(), contains('limit'));
  });

  test('town cap gist names town development as the limit', () {
    const preview = BuildImprovementYieldPreview(
      commodityId: 'grain',
      currentEffective: 2,
      nextEffective: 2,
      kind: BuildImprovementYieldKind.townDevelopmentLimit,
    );
    final line = buildImprovementNextYieldGistLine(
      l10n: l10n,
      preview: preview,
    );
    expect(line.toLowerCase(), contains('town development'));
  });

  test('disconnected gist states still none and not bound to the capital', () {
    const preview = BuildImprovementYieldPreview(
      commodityId: 'grain',
      currentEffective: 0,
      nextEffective: 0,
      kind: BuildImprovementYieldKind.disconnected,
    );
    final line = buildImprovementNextYieldGistLine(
      l10n: l10n,
      preview: preview,
    );
    expect(line.toLowerCase(), contains('still none'));
    expect(line.toLowerCase(), contains('not bound to the capital'));
  });
}

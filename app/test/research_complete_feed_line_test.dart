// Unit coverage for formatResearchCompleteFeedLine (Refs #4724).
// SPEC/ui/player-turn-event-feed.md research-complete ACs.

import 'package:colonizethis_app/features/game/widgets/technology/tech_effect_summary.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  group('formatResearchCompleteFeedLine (Refs #4724)', () {
    test('positive: catalog tech appends effect clauses with display name', () {
      final crop = techById(kTechIdCropRotation)!;
      final effects = buildTechEffectSummaryLines(l10n, crop);
      expect(effects, isNotEmpty);

      final line = formatResearchCompleteFeedLine(l10n, kTechIdCropRotation);
      expect(
        line,
        'Research complete: Crop Rotation unlocked · ${effects.join(' · ')}',
      );
      expect(line, isNot(contains(kTechIdCropRotation)));
    });

    test('positive: more than two effect lines caps at Choose-tech default', () {
      final tech = techById(kTechIdCopperAndTinMining)!;
      final effects = buildTechEffectSummaryLines(l10n, tech);
      expect(effects.length, greaterThan(2));

      final line = formatResearchCompleteFeedLine(
        l10n,
        kTechIdCopperAndTinMining,
      );
      expect(
        line,
        'Research complete: Copper and Tin Mining unlocked · '
        '${effects[0]} · ${effects[1]}',
      );
      expect(line, isNot(contains(effects[2])));
    });

    test('positive: category-fallback clause is included when that is all', () {
      // buildTechEffectSummaryLines always returns ≥1 line; for a tech with no
      // unlocks or authored summary ids it is the category-improvement line.
      // formatResearchCompleteFeedLine only accepts catalog ids, so assert the
      // shared helper path that the feed reuses, then pin a catalog tech that
      // has authored lines still joins with ` · `.
      final fallbackOnly = TechDefinition(
        id: 'research_feed_fallback_fixture',
        era: 1,
        category: 'military',
        cost: 100,
        displayName: 'Fallback Fixture',
      );
      final fallbackLine = buildTechEffectSummaryLines(l10n, fallbackOnly);
      expect(fallbackLine, hasLength(1));
      expect(fallbackLine.single, contains('Military'));

      final university = formatResearchCompleteFeedLine(
        l10n,
        kTechIdUniversity,
      );
      expect(university, startsWith('Research complete: University unlocked'));
      expect(university, contains(' · '));
    });

    test('negative: unknown tech id uses safe fallback without raw id', () {
      const unknownId = 'agri_1_not_in_catalog';
      final line = formatResearchCompleteFeedLine(l10n, unknownId);
      expect(line, kResearchCompleteUnknownFallback);
      expect(line, isNot(contains(unknownId)));
      expect(line, isNot(contains(' · ')));
    });
  });
}

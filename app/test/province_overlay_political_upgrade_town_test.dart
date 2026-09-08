// Pins Political Upgrade town gist helper (Refs #4316).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_sections_political.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('provinceOverlayTownDevelopmentGist', () {
    test('level 4 uses max gist', () {
      final l10n = AppLocalizationsEn();
      expect(
        provinceOverlayTownDevelopmentGist(l10n, 4),
        l10n.provinceOverlay_townDevelopmentGistMax,
      );
    });

    test('level 2 uses active bonus gist', () {
      final l10n = AppLocalizationsEn();
      expect(
        provinceOverlayTownDevelopmentGist(l10n, 2),
        l10n.provinceOverlay_townDevelopmentGistBonusActiveNextAt4,
      );
    });

    test('level 1 points to next bonus at 2', () {
      final l10n = AppLocalizationsEn();
      expect(
        provinceOverlayTownDevelopmentGist(l10n, 1),
        l10n.provinceOverlay_townDevelopmentGistNextAt2,
      );
    });

    test('status gist uses town workshops, never manufacturing bonus', () {
      final l10n = AppLocalizationsEn();
      for (final level in const [1, 2, 3, 4]) {
        final gist = provinceOverlayTownDevelopmentGist(l10n, level);
        expect(gist.toLowerCase(), contains('town workshops'));
        expect(gist.toLowerCase(), isNot(contains('manufacturing bonus')));
      }
      expect(
        provinceOverlayTownDevelopmentGist(l10n, 2),
        'Town workshops are active and will pause at level 3.',
      );
      expect(
        provinceOverlayTownDevelopmentGist(l10n, 3),
        'Town workshops are paused until level 4.',
      );
    });
  });
}

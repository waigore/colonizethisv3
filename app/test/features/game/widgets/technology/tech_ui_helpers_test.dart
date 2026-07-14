import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/widgets/production/commodity_ui_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_ui_helpers.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('eraRoman', () {
    test('returns roman numerals for the first four eras', () {
      expect(eraRoman(1), 'I');
      expect(eraRoman(2), 'II');
      expect(eraRoman(3), 'III');
      expect(eraRoman(4), 'IV');
    });

    test('falls back to numeric string outside supported range', () {
      expect(eraRoman(0), '0');
      expect(eraRoman(5), '5');
    });
  });

  group('commodityDisplayName', () {
    final l10n = AppLocalizationsEn();

    test('returns localized display name for known commodity', () {
      expect(commodityDisplayName(l10n, 'castIron'), 'Cast iron');
      expect(commodityDisplayName(l10n, 'sugarCane'), 'Sugar cane');
    });

    test('returns input id for unknown commodity', () {
      expect(
        commodityDisplayName(l10n, 'unknown_commodity'),
        'unknown_commodity',
      );
    });
  });

  group('TechCategory', () {
    test('covers exactly the 8 canonical category ids', () {
      expect(TechCategory.values.map((c) => c.id).toList(), <String>[
        'gathering',
        'transport',
        'labour',
        'civilian',
        'diplomacy',
        'naval',
        'military',
        'new-world',
      ]);
    });

    test('fromId resolves known ids and returns null for unknown', () {
      expect(TechCategory.fromId('gathering'), TechCategory.gathering);
      expect(TechCategory.fromId('new-world'), TechCategory.newWorld);
      expect(TechCategory.fromId('military'), TechCategory.military);
      expect(TechCategory.fromId('unknown'), isNull);
      expect(TechCategory.fromId(null), isNull);
    });

    test('iconAsset prefixes the bundled icon path', () {
      expect(
        TechCategory.gathering.iconAsset,
        '${kAppIconAssetPrefix}ui_icon_tech_gathering.png',
      );
      expect(
        TechCategory.newWorld.iconAsset,
        '${kAppIconAssetPrefix}ui_icon_tech_new_world.png',
      );
    });
  });

  group('techCategoryIconAssetPath', () {
    test('returns the enum icon path for known categories', () {
      expect(techCategoryIconAssetPath('naval'), TechCategory.naval.iconAsset);
      expect(
        techCategoryIconAssetPath('new-world'),
        TechCategory.newWorld.iconAsset,
      );
    });

    test('returns null for unknown or null categories', () {
      expect(techCategoryIconAssetPath('unknown'), isNull);
      expect(techCategoryIconAssetPath(null), isNull);
    });
  });

  group('techCategoryLabelL10n', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('returns the localized label for known categories', () {
      expect(
        techCategoryLabelL10n(l10n, 'gathering'),
        TechCategory.gathering.l10nLabel(l10n),
      );
      expect(
        techCategoryLabelL10n(l10n, 'new-world'),
        TechCategory.newWorld.l10nLabel(l10n),
      );
    });

    test('falls back to the raw category id when unknown', () {
      expect(techCategoryLabelL10n(l10n, 'mystery'), 'mystery');
    });
  });
}

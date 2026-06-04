// Refs #2865 — Province/sea-zone overlay improvement-type names and the
// unclaimed owner label resolve through AppLocalizations (no hardcoded
// English literals). SPEC/ui/province-sea-zone-detail-overlay.md
// § Province overlay content (Tile improvement label / Political Owner row)
// and § Localization of improvement names and unclaimed owner.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/l10n/app_localizations_en.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  group('improvement-type names resolve from AppLocalizations (#2865)', () {
    test('AC: grain → Farm key', () {
      expect(
        provinceOverlayImprovementNameForResource(l10n, 'grain'),
        l10n.provinceOverlay_improvementFarm,
      );
      expect(l10n.provinceOverlay_improvementFarm, 'Farm');
    });

    test('AC: meat and horses → Ranch key', () {
      expect(
        provinceOverlayImprovementNameForResource(l10n, 'meat'),
        l10n.provinceOverlay_improvementRanch,
      );
      expect(
        provinceOverlayImprovementNameForResource(l10n, 'horses'),
        l10n.provinceOverlay_improvementRanch,
      );
      expect(l10n.provinceOverlay_improvementRanch, 'Ranch');
    });

    test('AC: wool → Pasture key', () {
      expect(
        provinceOverlayImprovementNameForResource(l10n, 'wool'),
        l10n.provinceOverlay_improvementPasture,
      );
      expect(l10n.provinceOverlay_improvementPasture, 'Pasture');
    });

    test('AC: timber → Lumber camp key', () {
      expect(
        provinceOverlayImprovementNameForResource(l10n, 'timber'),
        l10n.provinceOverlay_improvementLumberCamp,
      );
      expect(l10n.provinceOverlay_improvementLumberCamp, 'Lumber camp');
    });

    test('AC: plantation crops → Plantation key', () {
      for (final r in const ['sugarCane', 'tobacco', 'cotton', 'spices']) {
        expect(
          provinceOverlayImprovementNameForResource(l10n, r),
          l10n.provinceOverlay_improvementPlantation,
          reason: 'resource $r should map to Plantation',
        );
      }
      expect(l10n.provinceOverlay_improvementPlantation, 'Plantation');
    });

    test('AC: furs → Fur post key', () {
      expect(
        provinceOverlayImprovementNameForResource(l10n, 'furs'),
        l10n.provinceOverlay_improvementFurPost,
      );
      expect(l10n.provinceOverlay_improvementFurPost, 'Fur post');
    });

    test('AC: minerals → Mine key', () {
      for (final r in const [
        'iron',
        'copper',
        'tin',
        'coal',
        'silver',
        'gold',
        'gems',
        'diamonds',
      ]) {
        expect(
          provinceOverlayImprovementNameForResource(l10n, r),
          l10n.provinceOverlay_improvementMine,
          reason: 'resource $r should map to Mine',
        );
      }
      expect(l10n.provinceOverlay_improvementMine, 'Mine');
    });

    test('AC (negative): null resource → generic Improvement key', () {
      expect(
        provinceOverlayImprovementNameForResource(l10n, null),
        l10n.provinceOverlay_improvementGeneric,
      );
      expect(l10n.provinceOverlay_improvementGeneric, 'Improvement');
    });

    test('AC (negative): unknown resource id → generic Improvement key', () {
      expect(
        provinceOverlayImprovementNameForResource(l10n, 'unobtanium'),
        l10n.provinceOverlay_improvementGeneric,
      );
    });
  });

  group('owner display name resolves from AppLocalizations (#2865)', () {
    final game = demoGameForOverlay;

    test('AC: null owner id → localized Unclaimed key', () {
      expect(
        provinceOverlayOwnerName(l10n, game, null),
        l10n.provinceOverlay_ownerUnclaimed,
      );
      expect(l10n.provinceOverlay_ownerUnclaimed, 'Unclaimed');
    });

    test('AC: empty owner id → localized Unclaimed key', () {
      expect(
        provinceOverlayOwnerName(l10n, game, ''),
        l10n.provinceOverlay_ownerUnclaimed,
      );
    });

    test('AC (negative): known owner id → faction display name, not Unclaimed', () {
      final player = game.players.first;
      final name = provinceOverlayOwnerName(l10n, game, player.id);
      expect(name, player.displayName);
      expect(name, isNot(l10n.provinceOverlay_ownerUnclaimed));
    });
  });
}

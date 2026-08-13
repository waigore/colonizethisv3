import 'package:colonizethis_app/features/game/widgets/train/train_civilian_role_display.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildFort,
        kWorkTargetBuildImprovement,
        kWorkTargetBuildPort,
        kWorkTargetBuildRoad,
        kWorkTargetCounterSpy,
        kWorkTargetPurchaseLand,
        kWorkTargetUpgradeTown;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('TrainCivilianRoleDisplay', () {
    test('six catalog types return plain-language gists without raw ids', () {
      final byId = <String, String>{
        kUnitTypeExplorer: TrainCivilianRoleDisplay.roleGist(
          l10n,
          kUnitTypeExplorer,
        ),
        kUnitTypeBuilder: TrainCivilianRoleDisplay.roleGist(
          l10n,
          kUnitTypeBuilder,
        ),
        kUnitTypeEngineer: TrainCivilianRoleDisplay.roleGist(
          l10n,
          kUnitTypeEngineer,
        ),
        kUnitTypeSpy: TrainCivilianRoleDisplay.roleGist(l10n, kUnitTypeSpy),
        kUnitTypeMerchant: TrainCivilianRoleDisplay.roleGist(
          l10n,
          kUnitTypeMerchant,
        ),
        kUnitTypeRailBuilder: TrainCivilianRoleDisplay.roleGist(
          l10n,
          kUnitTypeRailBuilder,
        ),
      };

      expect(byId[kUnitTypeExplorer], 'Explores provinces · Prospects minerals');
      expect(byId[kUnitTypeBuilder], 'Improves tiles · Upgrades towns');
      expect(byId[kUnitTypeEngineer], 'Builds roads, ports, and forts');
      expect(
        byId[kUnitTypeSpy],
        'Holds foreign intel · Counter-espionage at home',
      );
      expect(
        byId[kUnitTypeMerchant],
        'Purchases land in Minor/Tribe provinces',
      );
      expect(byId[kUnitTypeRailBuilder], 'Upgrades roads to railroad');

      for (final gist in byId.values) {
        expect(gist, isNotEmpty);
        // Raw work-target / persistence ids must not appear.
        expect(gist, isNot(contains(kWorkTargetBuildImprovement)));
        expect(gist, isNot(contains(kWorkTargetCounterSpy)));
        expect(gist, isNot(contains(kWorkTargetPurchaseLand)));
        expect(gist, isNot(contains(kWorkTargetBuildRoad)));
        expect(gist, isNot(contains(kWorkTargetBuildFort)));
        expect(gist, isNot(contains(kWorkTargetBuildPort)));
        expect(gist, isNot(contains(kWorkTargetUpgradeTown)));
        expect(gist, isNot(contains('explore_province')));
      }
    });

    test('spy gist does not imply idle unused capacity', () {
      final gist = TrainCivilianRoleDisplay.roleGist(l10n, kUnitTypeSpy);
      expect(gist.toLowerCase(), isNot(contains('unused')));
      expect(gist.toLowerCase(), isNot(contains('idle')));
      expect(gist.toLowerCase(), isNot(contains('assign')));
      expect(gist.toLowerCase(), contains('intel'));
    });

    test('unknown civilian type returns empty string', () {
      expect(TrainCivilianRoleDisplay.roleGist(l10n, 'NotACivilian'), isEmpty);
    });
  });
}

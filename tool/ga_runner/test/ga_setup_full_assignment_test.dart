import 'package:colonizethis_test/test.dart';
import 'package:ga_runner/ga_runner.dart';
import 'package:ga_runner/setup/capital_resolver.dart';

void main() {
  group('GA init full province assignment', () {
    test(
      'a valid GA setup profile materializes a fully-assigned world',
      () {
        final profile = buildGaSetupProfile(
          selectedGreatPowerIds: const <String>['england', 'france'],
          minorNationCount: 3,
          tribeCount: 3,
          minProvincesPerMinor: 3,
          numProvincesNewWorld: 12,
        );

        // resolveCapitalProvinces runs runInitGame then
        // verifyFullProvinceAssignment; it throws on any dropped/unowned
        // province. A non-throwing call with two resolved GP capitals proves
        // the realistic GA world satisfies the full-assignment invariant.
        final capitals = resolveCapitalProvinces(profile.setupConfig);

        expect(capitals.length, profile.setupConfig.greatPowerCount);
        expect(capitals.values.every((id) => id.isNotEmpty), isTrue);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:test/test.dart';

void main() {
  group('GameSetupScreen auto-assign (SPEC/tui/screens/game-setup.md)', () {
    test('default naming config has enough unique Great Powers for setup', () {
      // The naming config should expose Great Powers with unique ids.
      final naming = defaultNamingConfig;
      final gpIds = naming.greatPowers.map((g) => g.id).toList();

      // Expect at least as many GPs as player slots.
      expect(gpIds.length >= 6, isTrue,
          reason: 'defaultNamingConfig should define >= 6 Great Powers');

      // Expect ids to be unique.
      expect(gpIds.toSet().length, gpIds.length);
    });
  });
}


import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('AIConfig', () {
    test('holds leaderId personalityId hiddenAgendaId', () {
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'industrial_trader',
        hiddenAgendaId: 'peacemaker',
      );
      expect(config.leaderId, 'victoria');
      expect(config.personalityId, 'industrial_trader');
      expect(config.hiddenAgendaId, 'peacemaker');
      expect(config.difficultyModifiers, isEmpty);
    });
    test('accepts difficultyModifiers', () {
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'militant',
        hiddenAgendaId: 'warmonger',
        difficultyModifiers: {'resourceBonus': 1.2},
      );
      expect(config.difficultyModifiers['resourceBonus'], 1.2);
    });
  });
}

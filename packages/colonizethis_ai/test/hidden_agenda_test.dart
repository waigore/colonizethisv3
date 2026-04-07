import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';

void main() {
  group('agendaConquerModifier', () {
    test('warmonger positive', () {
      expect(agendaConquerModifier('warmonger'), 40);
    });
    test('peacemaker negative', () {
      expect(agendaConquerModifier('peacemaker'), -50);
    });
    test('backstabber positive', () {
      expect(agendaConquerModifier('backstabber'), 20);
    });
    test('isolationist negative', () {
      expect(agendaConquerModifier('isolationist'), -30);
    });
    test('unknown returns 0', () {
      expect(agendaConquerModifier('tech_thief'), 0);
      expect(agendaConquerModifier('envy'), 0);
    });
  });

  group('agendaDiplomacyModifier', () {
    test('isolationist negative', () {
      expect(agendaDiplomacyModifier('isolationist'), -50);
    });
    test('peacemaker positive', () {
      expect(agendaDiplomacyModifier('peacemaker'), 30);
    });
    test('others return 0', () {
      expect(agendaDiplomacyModifier('warmonger'), 0);
      expect(agendaDiplomacyModifier('backstabber'), 0);
    });
  });

  group('agendaResearchModifier', () {
    test('tech_thief positive', () {
      expect(agendaResearchModifier('tech_thief'), 35);
    });
    test('others return 0', () {
      expect(agendaResearchModifier('warmonger'), 0);
      expect(agendaResearchModifier('envy'), 0);
    });
  });

  group('agendaBuildOrderModifier', () {
    test('envy positive', () {
      expect(agendaBuildOrderModifier('envy'), 20);
    });
    test('others return 0', () {
      expect(agendaBuildOrderModifier('tech_thief'), 0);
      expect(agendaBuildOrderModifier('warmonger'), 0);
    });
  });

  group('agendaPeaceAcceptanceModifier', () {
    test('peacemaker positive', () {
      expect(agendaPeaceAcceptanceModifier('peacemaker'), 30);
    });
    test('warmonger negative', () {
      expect(agendaPeaceAcceptanceModifier('warmonger'), -25);
    });
    test('others return 0', () {
      expect(agendaPeaceAcceptanceModifier('tech_thief'), 0);
    });
  });

  group('agendaAllianceAcceptanceModifier', () {
    test('isolationist negative', () {
      expect(agendaAllianceAcceptanceModifier('isolationist'), -40);
    });
    test('peacemaker positive', () {
      expect(agendaAllianceAcceptanceModifier('peacemaker'), 10);
    });
    test('others return 0', () {
      expect(agendaAllianceAcceptanceModifier('warmonger'), 0);
    });
  });

  group('agendaTreatyBreakingModifier', () {
    test('backstabber positive', () {
      expect(agendaTreatyBreakingModifier('backstabber'), 25);
    });
    test('warmonger positive', () {
      expect(agendaTreatyBreakingModifier('warmonger'), 20);
    });
    test('others return 0', () {
      expect(agendaTreatyBreakingModifier('peacemaker'), 0);
    });
  });

  group('agendaSpyOrderModifier', () {
    test('tech_thief positive', () {
      expect(agendaSpyOrderModifier('tech_thief'), 25);
    });
    test('others return 0', () {
      expect(agendaSpyOrderModifier('warmonger'), 0);
      expect(agendaSpyOrderModifier('envy'), 0);
    });
  });
}

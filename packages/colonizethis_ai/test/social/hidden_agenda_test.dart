import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';

void main() {
  group('getAgendaConquerModifier', () {
    test('warmonger positive', () {
      expect(getAgendaConquerModifier('warmonger'), 40);
    });
    test('peacemaker negative', () {
      expect(getAgendaConquerModifier('peacemaker'), -50);
    });
    test('backstabber positive', () {
      expect(getAgendaConquerModifier('backstabber'), 20);
    });
    test('isolationist negative', () {
      expect(getAgendaConquerModifier('isolationist'), -30);
    });
    test('unknown returns 0', () {
      expect(getAgendaConquerModifier('tech_thief'), 0);
      expect(getAgendaConquerModifier('envy'), 0);
    });
  });

  group('getAgendaDiplomacyModifier', () {
    test('isolationist negative', () {
      expect(getAgendaDiplomacyModifier('isolationist'), -50);
    });
    test('peacemaker positive', () {
      expect(getAgendaDiplomacyModifier('peacemaker'), 30);
    });
    test('others return 0', () {
      expect(getAgendaDiplomacyModifier('warmonger'), 0);
      expect(getAgendaDiplomacyModifier('backstabber'), 0);
    });
  });

  group('getAgendaResearchModifier', () {
    test('tech_thief positive', () {
      expect(getAgendaResearchModifier('tech_thief'), 35);
    });
    test('others return 0', () {
      expect(getAgendaResearchModifier('warmonger'), 0);
      expect(getAgendaResearchModifier('envy'), 0);
    });
  });

  group('getAgendaBuildOrderModifier', () {
    test('envy positive', () {
      expect(getAgendaBuildOrderModifier('envy'), 20);
    });
    test('others return 0', () {
      expect(getAgendaBuildOrderModifier('tech_thief'), 0);
      expect(getAgendaBuildOrderModifier('warmonger'), 0);
    });
  });

  group('getAgendaPeaceAcceptanceModifier', () {
    test('peacemaker positive', () {
      expect(getAgendaPeaceAcceptanceModifier('peacemaker'), 30);
    });
    test('warmonger negative', () {
      expect(getAgendaPeaceAcceptanceModifier('warmonger'), -25);
    });
    test('others return 0', () {
      expect(getAgendaPeaceAcceptanceModifier('tech_thief'), 0);
    });
  });

  group('getAgendaAllianceAcceptanceModifier', () {
    test('isolationist negative', () {
      expect(getAgendaAllianceAcceptanceModifier('isolationist'), -40);
    });
    test('peacemaker positive', () {
      expect(getAgendaAllianceAcceptanceModifier('peacemaker'), 10);
    });
    test('others return 0', () {
      expect(getAgendaAllianceAcceptanceModifier('warmonger'), 0);
    });
  });

  group('getAgendaTreatyBreakingModifier', () {
    test('backstabber positive', () {
      expect(getAgendaTreatyBreakingModifier('backstabber'), 25);
    });
    test('warmonger positive', () {
      expect(getAgendaTreatyBreakingModifier('warmonger'), 20);
    });
    test('others return 0', () {
      expect(getAgendaTreatyBreakingModifier('peacemaker'), 0);
    });
  });

  group('getAgendaSpyOrderModifier', () {
    test('tech_thief positive', () {
      expect(getAgendaSpyOrderModifier('tech_thief'), 25);
    });
    test('others return 0', () {
      expect(getAgendaSpyOrderModifier('warmonger'), 0);
      expect(getAgendaSpyOrderModifier('envy'), 0);
    });
  });
}

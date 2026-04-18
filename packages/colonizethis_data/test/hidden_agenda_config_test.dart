// Tests for hidden agenda config. SPEC/ai/hidden-agendas.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('agendaConquerModifiers', () {
    test('warmonger has positive modifier', () {
      expect(agendaConquerModifiers['warmonger'], 40);
    });
    test('peacemaker has negative modifier', () {
      expect(agendaConquerModifiers['peacemaker'], -50);
    });
    test('backstabber has positive modifier', () {
      expect(agendaConquerModifiers['backstabber'], 20);
    });
    test('isolationist has negative modifier', () {
      expect(agendaConquerModifiers['isolationist'], -30);
    });
  });

  group('agendaDiplomacyModifiers', () {
    test('isolationist has negative modifier', () {
      expect(agendaDiplomacyModifiers['isolationist'], -50);
    });
    test('peacemaker has positive modifier', () {
      expect(agendaDiplomacyModifiers['peacemaker'], 30);
    });
  });

  group('agendaResearchModifiers', () {
    test('tech_thief has positive modifier', () {
      expect(agendaResearchModifiers['tech_thief'], 35);
    });
  });

  group('agendaBuildOrderModifiers', () {
    test('envy has positive modifier', () {
      expect(agendaBuildOrderModifiers['envy'], 20);
    });
  });

  group('agendaPeaceAcceptanceModifiers', () {
    test('peacemaker has positive modifier', () {
      expect(agendaPeaceAcceptanceModifiers['peacemaker'], 30);
    });
    test('warmonger has negative modifier', () {
      expect(agendaPeaceAcceptanceModifiers['warmonger'], -25);
    });
  });

  group('agendaAllianceAcceptanceModifiers', () {
    test('isolationist has negative modifier', () {
      expect(agendaAllianceAcceptanceModifiers['isolationist'], -40);
    });
    test('peacemaker has positive modifier', () {
      expect(agendaAllianceAcceptanceModifiers['peacemaker'], 10);
    });
  });

  group('agendaTreatyBreakingModifiers', () {
    test('backstabber has positive modifier', () {
      expect(agendaTreatyBreakingModifiers['backstabber'], 25);
    });
    test('warmonger has positive modifier', () {
      expect(agendaTreatyBreakingModifiers['warmonger'], 20);
    });
  });

  group('agendaSpyOrderModifiers', () {
    test('tech_thief has positive modifier', () {
      expect(agendaSpyOrderModifiers['tech_thief'], 25);
    });
  });

  group('getAgendaConquerModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaConquerModifier('warmonger'), 40);
      expect(getAgendaConquerModifier('peacemaker'), -50);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaConquerModifier('unknown'), 0);
      expect(getAgendaConquerModifier('tech_thief'), 0);
    });
  });

  group('getAgendaDiplomacyModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaDiplomacyModifier('isolationist'), -50);
      expect(getAgendaDiplomacyModifier('peacemaker'), 30);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaDiplomacyModifier('warmonger'), 0);
    });
  });

  group('getAgendaResearchModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaResearchModifier('tech_thief'), 35);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaResearchModifier('warmonger'), 0);
    });
  });

  group('getAgendaBuildOrderModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaBuildOrderModifier('envy'), 20);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaBuildOrderModifier('warmonger'), 0);
    });
  });

  group('getAgendaPeaceAcceptanceModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaPeaceAcceptanceModifier('peacemaker'), 30);
      expect(getAgendaPeaceAcceptanceModifier('warmonger'), -25);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaPeaceAcceptanceModifier('tech_thief'), 0);
    });
  });

  group('getAgendaAllianceAcceptanceModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaAllianceAcceptanceModifier('isolationist'), -40);
      expect(getAgendaAllianceAcceptanceModifier('peacemaker'), 10);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaAllianceAcceptanceModifier('warmonger'), 0);
    });
  });

  group('getAgendaTreatyBreakingModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaTreatyBreakingModifier('backstabber'), 25);
      expect(getAgendaTreatyBreakingModifier('warmonger'), 20);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaTreatyBreakingModifier('peacemaker'), 0);
    });
  });

  group('getAgendaSpyOrderModifier', () {
    test('returns correct value for known agenda', () {
      expect(getAgendaSpyOrderModifier('tech_thief'), 25);
    });
    test('returns 0 for unknown agenda', () {
      expect(getAgendaSpyOrderModifier('warmonger'), 0);
    });
  });

  group('getDeclareWarMaxRelationScore', () {
    test('returns 70 for warmonger', () {
      expect(getDeclareWarMaxRelationScore('warmonger'), 70);
    });
    test('returns 30 for peacemaker', () {
      expect(getDeclareWarMaxRelationScore('peacemaker'), 30);
    });
    test('returns 100 for backstabber', () {
      expect(getDeclareWarMaxRelationScore('backstabber'), 100);
    });
    test('returns default 50 for unknown', () {
      expect(getDeclareWarMaxRelationScore('tech_thief'), kDeclareWarMaxRelationScoreDefault);
    });
  });

  group('getDeclareWarTargetBonusWeakerNeighbor', () {
    test('returns 30 for warmonger', () {
      expect(getDeclareWarTargetBonusWeakerNeighbor('warmonger'), 30);
    });
    test('returns 0 for others', () {
      expect(getDeclareWarTargetBonusWeakerNeighbor('peacemaker'), 0);
    });
  });

  group('getDeclareWarTargetBonusAlly', () {
    test('returns 25 for backstabber', () {
      expect(getDeclareWarTargetBonusAlly('backstabber'), 25);
    });
    test('returns 0 for others', () {
      expect(getDeclareWarTargetBonusAlly('warmonger'), 0);
    });
  });
}

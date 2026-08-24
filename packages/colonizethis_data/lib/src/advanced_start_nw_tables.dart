import 'package:colonizethis_models/colonizethis_models.dart';

/// NW province reveal target (50-turn: midpoint of 50–75% range). SPEC/game/advanced-starts.md.
const double kAdvancedStart50TurnNwRevealFraction = 0.625;

const double kAdvancedStart100TurnNwRevealFraction = 1.0;

const double kAdvancedStart50TurnProspectFraction = 0.50;

const double kAdvancedStart100TurnProspectFraction = 0.75;

/// NW provinces assigned per GP at 100-turn advanced start.
const int kAdvancedStart100TurnNwColonizationCount = 6;

const double kAdvancedStart50TurnDevelopmentFraction = 0.25;

const double kAdvancedStart100TurnDevelopmentFraction = 0.50;

double advancedStartNwRevealFraction(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => kAdvancedStart50TurnNwRevealFraction,
    AdvancedStartType.turns100 => kAdvancedStart100TurnNwRevealFraction,
  };
}

double advancedStartProspectFraction(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => kAdvancedStart50TurnProspectFraction,
    AdvancedStartType.turns100 => kAdvancedStart100TurnProspectFraction,
  };
}

double advancedStartDevelopmentFraction(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => kAdvancedStart50TurnDevelopmentFraction,
    AdvancedStartType.turns100 => kAdvancedStart100TurnDevelopmentFraction,
  };
}

int advancedStartNwColonizationCount(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => 0,
    AdvancedStartType.turns100 => kAdvancedStart100TurnNwColonizationCount,
  };
}

import 'package:colonizethis_models/colonizethis_models.dart';

sealed class NewGameSetupOutcome {}

class NewGameSetupOutcomeSuccess extends NewGameSetupOutcome {
  NewGameSetupOutcomeSuccess(this.game);

  final Game game;
}

class NewGameSetupOutcomeFailure extends NewGameSetupOutcome {
  NewGameSetupOutcomeFailure(this.error);

  final Object error;
}

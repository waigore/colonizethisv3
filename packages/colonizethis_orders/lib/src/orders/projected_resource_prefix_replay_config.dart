/// Table-driven cache-slot wiring for recruit-worker / build incremental
/// prefix replay (Refs #4109 wave 5 slice C).
///
/// Collapses the duplicated closure wiring in
/// [IncrementalCandidateValidatorPrefixReplay] so each order family supplies
/// only its cache slots and validator factory.
library;

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show OrderValidationResult;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'incremental_candidate_validator.dart';
import 'projected_economy_prefix_replay.dart';

/// Cache-slot accessors and validator wiring for one projected-resource prefix
/// replay family (recruit worker or build).
class ProjectedResourcePrefixReplayConfig<TOrder, V> {
  const ProjectedResourcePrefixReplayConfig({
    required this.existingOrders,
    required this.readPrefixReplaySucceeded,
    required this.readCachedLedgers,
    required this.writePrefixReplaySucceeded,
    required this.writeCachedLedgers,
    required this.createValidator,
    required this.readLedgers,
    required this.validate,
  });

  final List<TOrder> Function(IncrementalCandidateValidator validator)
  existingOrders;
  final bool? Function(IncrementalCandidateValidatorCache cache)
  readPrefixReplaySucceeded;
  final ProjectedResourceLedgers? Function(IncrementalCandidateValidatorCache cache)
  readCachedLedgers;
  final void Function(IncrementalCandidateValidatorCache cache, bool value)
  writePrefixReplaySucceeded;
  final void Function(
    IncrementalCandidateValidatorCache cache,
    ProjectedResourceLedgers ledgers,
  )
  writeCachedLedgers;
  final V Function(
    Player player,
    ProjectedResourceLedgers ledgers,
    IncrementalCandidateValidator validator,
  )
  createValidator;
  final ProjectedResourceLedgers Function(V validator) readLedgers;
  final OrderValidationResult Function(V validator, TOrder order) validate;
}

/// Shared recruit-worker / build candidate acceptance via
/// [ProjectedResourcePrefixReplayConfig].
bool acceptIncrementalProjectedResourceCandidate<TOrder, V>({
  required IncrementalCandidateValidator validator,
  required Player player,
  required ProjectedResourcePrefixReplayConfig<TOrder, V> config,
  required TOrder candidate,
}) {
  final cache = validator.cache;
  return acceptProjectedResourcePrefixCandidate<TOrder, V>(
    prefixReplaySucceeded: config.readPrefixReplaySucceeded(cache),
    cachedLedgers: config.readCachedLedgers(cache),
    setPrefixReplaySucceeded: (value) =>
        config.writePrefixReplaySucceeded(cache, value),
    setCachedLedgers: (ledgers) => config.writeCachedLedgers(cache, ledgers),
    existingOrders: config.existingOrders(validator),
    createPrefixValidator: () => config.createValidator(
      player,
      projectedResourceLedgersFromPlayer(player),
      validator,
    ),
    validate: config.validate,
    readLedgers: config.readLedgers,
    createCandidateValidator: (ledgers) =>
        config.createValidator(player, ledgers, validator),
    candidate: candidate,
  );
}

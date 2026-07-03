// Shared bounded retry executor for the init-game map+setup pipelines.
// SPEC/program/game-setup-pipeline.md (steps 3/5/6: regenerate maps with a
// bumped seed and retry on retriable topology codes; bounded attempts).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'game_setup.dart';
import 'setup_exceptions.dart';
import 'setup_logging.dart';

/// Bounded map+setup regeneration attempts shared by the locked and freeform
/// init pipelines.
const int kMaxInitPipelineAttempts = 64;

/// Per-attempt seed bump applied to the effective seed so each regeneration
/// explores a different map (`mapSeed = effectiveSeed + attempt * bump`).
const int kInitPipelineSeedBump = 100003;

/// Outcome of one successful init-pipeline attempt.
typedef InitPipelineOutcome = ({
  List<WarpLink> warpLinks,
  GameSetupResult setupResult,
});

/// True for [SetupTopologyDataException] codes whose only safe recovery is to
/// regenerate maps with a bumped seed (vs a hard, non-retriable failure).
bool isRetriableInitTopologyCode(String code) =>
    code == 'assigner_exhausted' ||
    code == 'faction_component_bin_pack_failed' ||
    code == 'assignment_remainder_not_connected' ||
    code == 'tribe_missing_sea_bound_province';

/// Result of the optional mode-specific error hook in
/// [runInitPipelineWithRetries].
enum InitPipelineErrorAction {
  /// The hook handled the error; the runner should regenerate and retry.
  retry,

  /// The hook did not handle the error; the runner applies standard handling.
  unhandled,
}

/// Runs the shared bounded retry loop used by both the locked and freeform init
/// pipelines.
///
/// For each attempt it computes `effectiveSeed + attempt * [kInitPipelineSeedBump]`,
/// invokes [generateAndCreate] with that map seed, retries on retriable
/// [SetupTopologyDataException] codes (see [isRetriableInitTopologyCode]), and
/// throws an `assigner_exhausted` exhaustion error after
/// [kMaxInitPipelineAttempts] attempts. [modeLabel] only prefixes log lines and
/// the exhaustion message.
///
/// [onAttemptError] lets a mode add handling for errors that are not standard
/// retriable topology failures (for example locked partition-gate exhaustion).
/// It may return [InitPipelineErrorAction.retry] to regenerate, throw to fail
/// hard, or return [InitPipelineErrorAction.unhandled] to fall through to
/// standard handling (rethrow of the original error).
InitPipelineOutcome runInitPipelineWithRetries({
  required int effectiveSeed,
  required String modeLabel,
  required InitPipelineOutcome Function(int mapSeed) generateAndCreate,
  InitPipelineErrorAction Function(
    Object error,
    StackTrace stackTrace,
    int attempt,
    bool isLastAttempt,
  )?
  onAttemptError,
}) {
  for (var attempt = 0; attempt < kMaxInitPipelineAttempts; attempt++) {
    final mapSeed = effectiveSeed + attempt * kInitPipelineSeedBump;
    final isLastAttempt = attempt == kMaxInitPipelineAttempts - 1;
    try {
      return generateAndCreate(mapSeed);
    } on SetupTopologyDataException catch (e, st) {
      if (isRetriableInitTopologyCode(e.code) && !isLastAttempt) {
        setupLog.w(
          'logic: $modeLabel setup topology retry at attempt=$attempt '
          '(code=${e.code}; mapSeed=$mapSeed)',
        );
        continue;
      }
      setupLog.e(
        'logic: $modeLabel setup failed: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      final action = onAttemptError?.call(e, st, attempt, isLastAttempt);
      if (action == InitPipelineErrorAction.retry) {
        continue;
      }
      rethrow;
    }
  }
  throw SetupTopologyDataException(
    code: 'assigner_exhausted',
    details:
        '$modeLabel pipeline exhausted after $kMaxInitPipelineAttempts '
        'map+setup attempts',
  );
}

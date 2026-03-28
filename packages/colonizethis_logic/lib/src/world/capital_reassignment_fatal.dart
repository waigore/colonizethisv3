/// Fatal error during runtime capital reassignment after combat.
/// Host must end the game session and retain logs. SPEC/game/capital-and-connectivity § Capital loss and reassignment.
class CapitalReassignmentFatalError implements Exception {
  CapitalReassignmentFatalError(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'CapitalReassignmentFatalError: $message (cause: $cause)';
    }
    return 'CapitalReassignmentFatalError: $message';
  }
}

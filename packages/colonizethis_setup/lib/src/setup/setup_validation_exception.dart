/// Domain-specific validation exception for game setup invariants.
///
/// This extends [ArgumentError] to preserve existing behavior for callers that
/// currently catch argument failures, while allowing precise setup-specific
/// error handling.
class SetupValidationException extends ArgumentError {
  SetupValidationException([super.message]);

  SetupValidationException.value(Object? value, [String? name, Object? message])
    : super.value(value, name, message);
}

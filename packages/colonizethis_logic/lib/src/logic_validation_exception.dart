/// Domain-specific validation exception for non-setup logic invariants.
///
/// Extends [ArgumentError] so callers that catch [ArgumentError] keep working.
class LogicValidationException extends ArgumentError {
  LogicValidationException([super.message]);

  LogicValidationException.value(Object? value, [String? name, Object? message])
    : super.value(value, name, message);
}

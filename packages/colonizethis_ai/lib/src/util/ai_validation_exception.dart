/// Base exception for AI domain runtime errors.
///
/// Extends [ArgumentError] for compatibility with existing generic catch
/// blocks while allowing AI-specific exception typing.
class AiDomainException extends ArgumentError {
  AiDomainException([super.message]);

  AiDomainException.value(Object? value, [String? name, Object? message])
    : super.value(value, name, message);
}

/// Domain-specific validation exception for AI planning invariants.
class AiValidationException extends AiDomainException {
  AiValidationException([super.message]);

  AiValidationException.value(Object? value, [String? name, Object? message])
    : super.value(value, name, message);
}

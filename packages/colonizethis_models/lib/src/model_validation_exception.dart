/// Domain-specific validation exception for model deserialization invariants.
class ModelValidationException extends ArgumentError {
  ModelValidationException([super.message]);

  ModelValidationException.value(Object? value, [String? name, Object? message])
    : super.value(value, name, message);
}

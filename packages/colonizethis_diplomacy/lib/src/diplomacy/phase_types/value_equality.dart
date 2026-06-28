/// Shared structural value-equality for the small Diplomacy-phase value types
/// (the Offer / Decision / Prompt / Pending pairs in this directory).
///
/// Each value type previously hand-wrote an identical `operator ==` +
/// `hashCode` pair over its identifying fields (Refs #3715). Mixing in
/// [ValueEquality] lets a type declare only its ordered identifying fields via
/// [equalityFields]; equality and hashing derive from that single list, so the
/// boilerplate has one source of truth. SPEC/program/turn-resolution-phases.md
/// § Blocking human input.
library;

/// Structural equality over an ordered field list.
///
/// Implementers expose their identifying fields through [equalityFields];
/// two instances are equal when they share a runtime type and field-by-field
/// equal [equalityFields]. The list must be deterministic for a given instance
/// (same order and values on each access) to keep `==`/`hashCode` consistent.
mixin ValueEquality {
  /// Ordered fields that define this value's identity.
  List<Object?> get equalityFields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ValueEquality &&
          _equalityFieldsEqual(equalityFields, other.equalityFields);

  @override
  int get hashCode => Object.hashAll(equalityFields);
}

bool _equalityFieldsEqual(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

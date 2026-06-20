// SPEC/program/game-setup-pipeline.md — deterministic seed perturbation helper.

/// Derives a deterministic perturbed seed from a [base] seed, a call-site
/// [salt], and optional extra [args].
///
/// Package-internal (Refs #3428): shared by the GP Old World redistribution
/// passes so each call site need not inline `Object.hash(...)`. This is
/// identity-preserving with the previous inline form because
/// `Object.hashAll(<Object?>[base, salt, ...args])` produces the same value as
/// `Object.hash(base, salt, ...args)` for the same arguments in the same order,
/// keeping golden-seed redistribution outputs unchanged. [args] is typed
/// `Object?` so heterogeneous keys (for example a `String` GP id) are accepted.
int perturbSeed(int base, int salt, {List<Object?> args = const <Object?>[]}) =>
    Object.hashAll(<Object?>[base, salt, ...args]);

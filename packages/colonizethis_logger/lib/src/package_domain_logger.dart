import 'ct_logger.dart';

/// Shared factory for per-package [CtLogger] instances (Refs #3393 Phase 2).
///
/// Every package previously copy-pasted an identical `packageLogger([subPrefix])`
/// body that composed its `kPackageLogPrefix` constant with an optional
/// sub-prefix. That duplication is consolidated here: each package keeps a local
/// `kPackageLogPrefix` constant plus a thin `packageLogger([subPrefix])` wrapper
/// that delegates to this factory instead of re-declaring the composition body.
///
/// When [subPrefix] is `null` or empty the logger uses [prefix] verbatim;
/// otherwise the logger prefix is `<prefix>.<subPrefix>`. Enforced by
/// `repo.domain_package_logger_dedup` (see `SPEC/program/repo-lint.md`).
CtLogger domainPackageLogger(String prefix, [String? subPrefix]) {
  if (subPrefix == null || subPrefix.isEmpty) {
    return CtLogger(prefix);
  }
  return CtLogger('$prefix.$subPrefix');
}

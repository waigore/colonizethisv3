// Resolved minor/tribe naming lookup used by entry builders and display-name
// updates. SPEC/program/game-setup-pipeline.md §7c. Refs #4054.

import 'package:colonizethis_data/colonizethis_data.dart';

/// Looks up [id] in [naming.minorNations], or an empty sentinel when missing.
MinorNationNaming resolvedMinorNaming(ResolvedNamingConfig naming, String id) {
  return naming.minorNations.firstWhere(
    (n) => n.id == id,
    orElse: () => const MinorNationNaming(id: '', displayName: ''),
  );
}

/// Looks up [id] in [naming.tribes], or an empty sentinel when missing.
TribeNaming resolvedTribeNaming(ResolvedNamingConfig naming, String id) {
  return naming.tribes.firstWhere(
    (n) => n.id == id,
    orElse: () =>
        const TribeNaming(id: '', displayName: '', provinceNamePool: []),
  );
}

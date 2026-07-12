import 'package:colonizethis_models/colonizethis_models.dart';

/// Units whose ids are not present in [casualtyIds], preserving encounter order.
///
/// Shared land auto-resolve / post-battle / Quick Battle apply filter
/// (Refs #3983). Does not sort or re-order survivors.
Iterable<Unit> unitsExcludingCasualtyIds(
  Iterable<Unit> units,
  Set<String> casualtyIds,
) =>
    units.where((u) => !casualtyIds.contains(u.id));

/// Ids from [ids] that are not present in [casualtyIds], preserving order.
Iterable<String> idsExcludingCasualtyIds(
  Iterable<String> ids,
  Set<String> casualtyIds,
) =>
    ids.where((id) => !casualtyIds.contains(id));

/// Canonical province → owner-faction map construction for colonizethis_map
/// view/visualization paths (Refs #3459).
///
/// Both the game-world-state PNG visualizer and the `InitGameMapViewData`
/// builder need a `provinceId → ownerId` lookup that skips provinces with no
/// (or empty) owner. Keeping that construction in a single helper avoids the
/// duplicated old/new region ownership loop the two paths previously carried.
/// SPEC/program/map-visualization.md § Game world state map visualizer.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Builds a `provinceId → ownerId` map from [provinces], including only
/// provinces whose `ownerId` is non-null and non-empty.
///
/// The province id key is the province's own id (typically a prefixed
/// `regionId|localId`); callers that index by prefixed province id rely on
/// `Province.id` already being prefixed.
Map<String, String> provinceOwnerByIdFromProvinces(List<Province> provinces) {
  final ownerByProvinceId = <String, String>{};
  for (final province in provinces) {
    final ownerId = province.ownerId;
    if (ownerId != null && ownerId.isNotEmpty) {
      ownerByProvinceId[province.id] = ownerId;
    }
  }
  return ownerByProvinceId;
}

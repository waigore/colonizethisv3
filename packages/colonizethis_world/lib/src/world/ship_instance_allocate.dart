import 'package:colonizethis_models/colonizethis_models.dart';

/// Allocates new [ShipInstance]s with ids `ship_<n>` starting at [nextShipInstanceSeq].
/// Returns the next sequence after the last minted id.
(int nextSeqAfter, List<ShipInstance> instances) mintShipInstances({
  required int nextShipInstanceSeq,
  required List<String> typeIds,
}) {
  final out = <ShipInstance>[];
  var s = nextShipInstanceSeq;
  for (final t in typeIds) {
    out.add(ShipInstance(id: 'ship_$s', typeId: t));
    s++;
  }
  return (s, out);
}

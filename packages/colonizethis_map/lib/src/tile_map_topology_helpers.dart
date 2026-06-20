import 'package:colonizethis_data/colonizethis_data.dart';

/// Sea-zone node ids from [topology], in iteration order of [MapTopology.nodes].
Set<String> seaZoneIdsFromTopology(MapTopology topology) => {
  for (final n in topology.nodes)
    if (n.type == TopologyNodeType.seaZone) n.id,
};

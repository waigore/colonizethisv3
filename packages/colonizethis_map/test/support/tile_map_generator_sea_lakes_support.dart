import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/tile_map_directions.dart';
import 'package:colonizethis_test/test.dart';

final _seaId = RegExp(r'^s\d+$');

void expectNoEnclosedSeaAfterFillLakes(TileMapResult result) {
  final seaCells = <(int, int)>{};
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      if (_seaId.hasMatch(result.cell(x, y))) {
        seaCells.add((x, y));
      }
    }
  }
  if (seaCells.isEmpty) return;
  final queue = List<(int, int)>.from(
    seaCells.where(
      (p) =>
          p.$1 == 0 ||
          p.$1 == result.width - 1 ||
          p.$2 == 0 ||
          p.$2 == result.height - 1,
    ),
  );
  final reachable = queue.toSet();
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeLast();
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < result.width && ny >= 0 && ny < result.height) {
        final nid = result.cell(nx, ny);
        if (_seaId.hasMatch(nid) && !reachable.contains((nx, ny))) {
          reachable.add((nx, ny));
          queue.add((nx, ny));
        }
      }
    }
  }
  expect(
    reachable.length,
    seaCells.length,
    reason: 'All sea cells should be reachable from edge (no lakes)',
  );
}

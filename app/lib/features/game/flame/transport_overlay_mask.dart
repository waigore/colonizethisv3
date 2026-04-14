import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;

const int kTransportMaskNorth = 1 << 0;
const int kTransportMaskEast = 1 << 1;
const int kTransportMaskSouth = 1 << 2;
const int kTransportMaskWest = 1 << 3;

int computeTransportConnectivityMask({
  required int x,
  required int y,
  required CellViewData? Function(int x, int y) getCellAt,
}) {
  final center = getCellAt(x, y);
  if (center == null || center.isSea || (center.roadLevel ?? 0) <= 0) {
    return 0;
  }

  var mask = 0;
  if (_isConnectedLandTransport(getCellAt(x, y - 1))) {
    mask |= kTransportMaskNorth;
  }
  if (_isConnectedLandTransport(getCellAt(x + 1, y))) {
    mask |= kTransportMaskEast;
  }
  if (_isConnectedLandTransport(getCellAt(x, y + 1))) {
    mask |= kTransportMaskSouth;
  }
  if (_isConnectedLandTransport(getCellAt(x - 1, y))) {
    mask |= kTransportMaskWest;
  }
  return mask;
}

bool _isConnectedLandTransport(CellViewData? cell) {
  return cell != null && !cell.isSea && (cell.roadLevel ?? 0) > 0;
}

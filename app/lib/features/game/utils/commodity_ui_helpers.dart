import 'package:colonizethis_data/colonizethis_data.dart';

String commodityDisplayName(String commodityId) {
  return CommodityCatalog.byId[commodityId]?.displayName ?? commodityId;
}

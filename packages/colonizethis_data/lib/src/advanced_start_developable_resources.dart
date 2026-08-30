import 'resource.dart';

/// Non-prospect resource ids eligible for advanced-start development.
final Set<String> kAdvancedStartDevelopableResourceIds = {
  Resource.grain.name,
  Resource.meat.name,
  Resource.wool.name,
  Resource.horses.name,
  Resource.timber.name,
  Resource.sugarCane.name,
  Resource.tobacco.name,
  Resource.cotton.name,
  Resource.furs.name,
  Resource.spices.name,
};

/// Lower rank = higher selection priority (food, then luxury, timber, minerals).
int advancedStartDevelopableTilePriority(String resourceId) {
  if (resourceId == Resource.grain.name || resourceId == Resource.meat.name) {
    return 0;
  }
  if (resourceId == Resource.wool.name ||
      resourceId == Resource.horses.name ||
      resourceId == Resource.sugarCane.name ||
      resourceId == Resource.tobacco.name ||
      resourceId == Resource.cotton.name ||
      resourceId == Resource.furs.name ||
      resourceId == Resource.spices.name) {
    return 1;
  }
  if (resourceId == Resource.timber.name) {
    return 2;
  }
  return 3;
}

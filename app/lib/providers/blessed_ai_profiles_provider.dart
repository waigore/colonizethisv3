import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/core/services/blessed_ai_profile_loader.dart';

/// Blessed tuned AI profiles from the asset bundle, keyed by profile name.
final blessedAiProfileCatalogProvider =
    FutureProvider<Map<String, AiProfile>>((ref) {
      return BlessedAiProfileLoader.loadCatalog();
    });

/// Sorted blessed profile names for new-game UI dropdowns.
final blessedAiProfileNamesProvider = FutureProvider<List<String>>((ref) {
  return BlessedAiProfileLoader.loadBlessedProfileNames();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/constants.dart';

/// Provides the Hive box for games. Box must be opened in main() before first read.
final gamesBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box(HiveBoxNames.games);
});

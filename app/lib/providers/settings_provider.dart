import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Stub provider for user settings. Phase 0: no real state; Phase 1+ wires to Hive.
final settingsProvider = StateProvider<Map<String, dynamic>>((ref) => {});

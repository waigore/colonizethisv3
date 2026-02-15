import 'package:flutter/material.dart';

import '../features/game/flame/game_screen.dart';
import '../features/shell/shell_screen.dart';

class Routes {
  Routes._();

  static const String shell = '/';
  static const String game = '/game';

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case shell:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ShellScreen(),
        );
      case game:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GameScreen(),
        );
      default:
        return null;
    }
  }
}

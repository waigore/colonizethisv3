import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'ctdev_log.dart';
import 'screens/init_game_screen.dart';

void main() {
  initCtdevLogging();
  runZonedGuarded(
    () => runApp(const CtDevApp()),
    (Object error, StackTrace stackTrace) {
      Logger().e('ctdev: uncaught error', error: error, stackTrace: stackTrace);
    },
  );
}

class CtDevApp extends StatelessWidget {
  const CtDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColonizeThis Dev',
      theme: ThemeData.light(useMaterial3: true),
      home: const CtDevHomeScreen(),
    );
  }
}

class CtDevHomeScreen extends StatelessWidget {
  const CtDevHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ColonizeThis Dev'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InitGameScreen(),
                  ),
                );
              },
              child: const Text('Init Game'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Placeholder for Load Savegame flow.
              },
              child: const Text('Load Savegame'),
            ),
          ],
        ),
      ),
    );
  }
}

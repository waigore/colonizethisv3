import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/desktop_window_settings.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:hive/hive.dart';
import 'package:window_manager/window_manager.dart';

enum DesktopStartupMode { restoreState, maximize, defaultSize }

class DesktopStartupDecision {
  const DesktopStartupDecision({
    required this.mode,
    required this.restoreState,
  });

  final DesktopStartupMode mode;
  final DesktopWindowState? restoreState;

  static DesktopStartupDecision resolve({
    required DesktopWindowState? restoreState,
    required bool startupMaximized,
  }) {
    if (restoreState != null) {
      return DesktopStartupDecision(
        mode: DesktopStartupMode.restoreState,
        restoreState: restoreState,
      );
    }
    if (startupMaximized) {
      return const DesktopStartupDecision(
        mode: DesktopStartupMode.maximize,
        restoreState: null,
      );
    }
    return const DesktopStartupDecision(
      mode: DesktopStartupMode.defaultSize,
      restoreState: null,
    );
  }
}

class DesktopWindowStartupService with WindowListener {
  DesktopWindowStartupService._();

  static final DesktopWindowStartupService _instance =
      DesktopWindowStartupService._();

  bool _listenerRegistered = false;
  bool _initialized = false;

  static bool get isSupportedDesktop =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  static Future<void> initializeIfSupported() async {
    if (!isSupportedDesktop) {
      return;
    }
    await _instance._initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await windowManager.ensureInitialized();

    final settings = Hive.box<dynamic>(HiveBoxNames.settings);
    final startupMaximized = _readStartupPreference(settings);
    final restoreState = DesktopWindowState.fromSettingsValue(
      settings.get(DesktopWindowSettingsKeys.lastWindowState),
    );
    final decision = DesktopStartupDecision.resolve(
      restoreState: restoreState,
      startupMaximized: startupMaximized,
    );

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: const Size(
          kDesktopWindowDefaultWidth,
          kDesktopWindowDefaultHeight,
        ),
        minimumSize: const Size(
          kDesktopWindowMinWidth,
          kDesktopWindowMinHeight,
        ),
        center: decision.mode == DesktopStartupMode.defaultSize,
      ),
      () async {
        await windowManager.setMinimumSize(
          const Size(kDesktopWindowMinWidth, kDesktopWindowMinHeight),
        );
        switch (decision.mode) {
          case DesktopStartupMode.restoreState:
            final state = decision.restoreState;
            if (state != null) {
              await windowManager.setBounds(state.toRect());
              if (state.maximized) {
                await windowManager.maximize();
              }
            }
            break;
          case DesktopStartupMode.maximize:
            await windowManager.maximize();
            break;
          case DesktopStartupMode.defaultSize:
            // WindowOptions covers default-size startup.
            break;
        }
        await windowManager.show();
        await windowManager.focus();
      },
    );

    if (!_listenerRegistered) {
      windowManager.addListener(this);
      _listenerRegistered = true;
    }
    await _persistCurrentWindowState(settings);
  }

  bool _readStartupPreference(Box<dynamic> settings) {
    final raw = settings.get(DesktopWindowSettingsKeys.startupMaximized);
    if (raw is bool) {
      return raw;
    }
    settings.put(DesktopWindowSettingsKeys.startupMaximized, true);
    return true;
  }

  @override
  Future<void> onWindowMove() => _saveStateSafely();

  @override
  Future<void> onWindowResize() => _saveStateSafely();

  @override
  Future<void> onWindowMaximize() => _saveStateSafely();

  @override
  Future<void> onWindowUnmaximize() => _saveStateSafely();

  Future<void> _saveStateSafely() async {
    try {
      final settings = Hive.box<dynamic>(HiveBoxNames.settings);
      await _persistCurrentWindowState(settings);
    } catch (e, st) {
      packageLogger(
        'app',
      ).w('desktop window state persistence failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persistCurrentWindowState(Box<dynamic> settings) async {
    final bounds = await windowManager.getBounds();
    final isMaximized = await windowManager.isMaximized();
    final state = DesktopWindowState(
      x: bounds.left,
      y: bounds.top,
      width: bounds.width,
      height: bounds.height,
      maximized: isMaximized,
    );
    await settings.put(
      DesktopWindowSettingsKeys.lastWindowState,
      state.toMap(),
    );
  }
}

// Generating World screen. SPEC/tui/screens/generating-world.md.

import 'dart:async';

import 'package:ctterm/package_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

final _log = packageLogger();

/// Screen shown while the game world is being generated.
/// SPEC/tui/screens/generating-world.md.
class GeneratingWorldScreen extends StatefulComponent {
  const GeneratingWorldScreen({
    super.key,
    required this.onComplete,
    required this.onCancel,
    this.runGeneration,
  });

  /// Called when world generation completes successfully.
  final void Function() onComplete;

  /// Called when user cancels generation.
  final void Function() onCancel;

  /// When set, run real init (runInitGame) instead of simulated progress. Called once on mount; when done, app navigates to in-game shell.
  final void Function()? runGeneration;

  @override
  State<GeneratingWorldScreen> createState() => _GeneratingWorldScreenState();
}

class _GeneratingWorldScreenState extends State<GeneratingWorldScreen> {
  String _status = 'Initializing...';
  int _dots = 0;
  Timer? _timer;
  bool _cancelled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  @override
  void dispose() {
    // No [StreamSubscription]; only [Timer]. ctterm does not depend on
    // colonizethis_app [SubscriptionTracker]; see SPEC/program/app-ui-wiring.md.
    _timer?.cancel();
    super.dispose();
  }

  void _startGeneration() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_cancelled) {
        timer.cancel();
        return;
      }

      setState(() {
        _dots = (_dots + 1) % 4;
        _updateStatus(timer.tick);
      });

      if (timer.tick >= 6) {
        timer.cancel();
        if (_cancelled) {
          return;
        }

        // When real generation is wired, delegate to app callback so it can
        // run init_game and navigate. Otherwise, use the simulated completion.
        if (component.runGeneration != null) {
          component.runGeneration!();
        } else {
          _onGenerationComplete();
        }
      }
    });
  }

  void _updateStatus(int tick) {
    switch (tick) {
      case 1:
        _status = 'Loading ruleset...';
        break;
      case 2:
        _status = 'Generating Old World map...';
        break;
      case 3:
        _status = 'Generating New World map...';
        break;
      case 4:
        _status = 'Assigning provinces...';
        break;
      case 5:
        _status = 'Placing capitals and towns...';
        break;
      default:
        _status = 'Finalizing...';
    }
  }

  void _onGenerationComplete() {
    if (_cancelled) return;
    _log.d('World generation complete -> in-game shell');
    component.onComplete();
  }

  void _handleCancel() {
    if (_error != null) {
      // After error, any key returns to main menu
      _log.d('Generation error acknowledged -> main menu');
      component.onCancel();
      return;
    }

    _cancelled = true;
    _log.d('Generation cancelled by user -> main menu');
    component.onCancel();
  }

  @override
  Component build(BuildContext context) {
    final dotsStr = '.' * _dots;
    final statusText = _error ?? '$_status$dotsStr';

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        if (key == LogicalKey.escape || key == LogicalKey.keyB) {
          _handleCancel();
          return true;
        }
        // After error, any key dismisses
        if (_error != null) {
          _handleCancel();
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Generating World',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(statusText),
            const SizedBox(height: 2),
            if (_error == null)
              Text(
                'Press [B] or [Escape] to cancel',
                style: TextStyle(color: Colors.gray),
              )
            else
              Text(
                'Press any key to continue',
                style: TextStyle(color: Colors.gray),
              ),
          ],
        ),
      ),
    );
  }
}

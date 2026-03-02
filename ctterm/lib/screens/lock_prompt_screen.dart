// Lock prompt: shown when games box lock is detected. User chooses to remove and continue or quit.

import 'package:nocterm/nocterm.dart';

/// Shown when the save-service lock file is held (e.g. another ctterm or stale lock).
/// [Y] Remove lock and continue; [N] Quit.
class LockPromptScreen extends StatelessComponent {
  const LockPromptScreen({
    super.key,
    required this.onRemoveAndContinue,
    required this.onQuit,
  });

  final void Function() onRemoveAndContinue;
  final void Function() onQuit;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final c = event.character?.toLowerCase();
        if (c == 'y') {
          onRemoveAndContinue();
          return true;
        }
        if (c == 'n' || c == 'q') {
          onQuit();
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Save data is locked.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Another instance may be running, or a previous run did not exit cleanly.',
              style: TextStyle(color: Colors.gray),
            ),
            const SizedBox(height: 4),
            Text(
              'Remove lock and continue anyway?',
              style: TextStyle(color: Colors.gray),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('[Y]es ', style: TextStyle(color: Colors.cyan)),
                Text(' [N]o (quit)', style: TextStyle(color: Colors.cyan)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

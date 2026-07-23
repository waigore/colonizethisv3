import 'package:colonizethis_models/colonizethis_models.dart';

/// Shows the in-game pause menu (Debug log, Resume). SPEC/program/debug-log-viewer.md.
/// Emits [OpenPauseMenuPanelEvent]; shell event handler shows the bottom sheet.
void showGameScreenPauseMenu(AppEventBus bus) {
  bus.emit(const OpenPauseMenuPanelEvent());
}

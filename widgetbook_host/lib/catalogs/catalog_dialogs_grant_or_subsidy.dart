// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
part of 'catalog.dart';

/// Grant or Subsidy Dialog stories. SPEC/ui/grant-or-subsidy-dialog.md.
List<WidgetbookNode> get grantOrSubsidyDialogDirectories => [
  WidgetbookFolder(
    name: 'Grant or Subsidy Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Grant mode — treasury sufficient',
        builder: (context) {
          final result = loadSeed42InitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.first.id;
          final targetFactionId = game.players.length >= 2
              ? game.players[1].id
              : (game.minorNations.isNotEmpty
                    ? game.minorNations.first.id
                    : 'm1');
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => GrantOrSubsidyDialog(
                      game: game,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: false,
                      bus: AppEventBus.create(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Grant Aid'),
              );
            },
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Subsidy mode — percent stepper',
        builder: (context) {
          final base = loadSeed42InitGameResult().game;
          final humanPlayerId = base.players.first.id;
          final targetFactionId = base.players.length >= 2
              ? base.players[1].id
              : (base.minorNations.isNotEmpty
                    ? base.minorNations.first.id
                    : 'm1');
          // Subsidy is a treasury-independent percentage (Refs #3753 R3); even
          // with treasury 0 the percent stepper (5–20%) stays enabled.
          final game = base.copyWith(
            players: [
              base.players.first.copyWith(treasury: 0),
              ...base.players.skip(1),
            ],
          );
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => GrantOrSubsidyDialog(
                      game: game,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: true,
                      bus: AppEventBus.create(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Set Subsidy'),
              );
            },
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Grant mode — treasury below minimum',
        builder: (context) {
          final base = loadSeed42InitGameResult().game;
          final humanPlayerId = base.players.first.id;
          final targetFactionId = base.players.length >= 2
              ? base.players[1].id
              : (base.minorNations.isNotEmpty
                    ? base.minorNations.first.id
                    : 'm1');
          final game = base.copyWith(
            players: [
              base.players.first.copyWith(treasury: 0),
              ...base.players.skip(1),
            ],
          );
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => GrantOrSubsidyDialog(
                      game: game,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: false,
                      bus: AppEventBus.create(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Grant Aid (empty treasury)'),
              );
            },
          );
        },
      ),
    ],
  ),
];

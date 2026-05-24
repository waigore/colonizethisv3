part of 'catalog.dart';

class _InlineYarnAssetBundle extends AssetBundle {
  _InlineYarnAssetBundle(this._text);

  final String _text;

  @override
  Future<ByteData> load(String key) {
    final bytes = Uint8List.fromList(utf8.encode(_text));
    return Future.value(
      ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.value(_text);
  }
}

const String _kCtDialogueViewStorySource = '''
title: ctdv_story
---
The story begins with a single archaic line.
The narrator pauses, then offers a choice.
-> Continue the tale.
-> Cut the tale short.
===
''';

/// CtDialogueView stories. SPEC/ui/ct-dialogue-view.md.
List<WidgetbookNode> get ctDialogueViewDirectories => [
  WidgetbookFolder(
    name: 'Dialogue Engine',
    children: [
      WidgetbookUseCase(
        name: 'Lines and choice trace',
        builder: (context) => MaterialApp(
          theme: AppThemes.colonial,
          home: const Scaffold(body: _CtDialogueViewStoryHarness()),
        ),
      ),
    ],
  ),
];

class _CtDialogueViewStoryHarness extends StatefulWidget {
  const _CtDialogueViewStoryHarness();

  @override
  State<_CtDialogueViewStoryHarness> createState() =>
      _CtDialogueViewStoryHarnessState();
}

class _CtDialogueViewStoryHarnessState
    extends State<_CtDialogueViewStoryHarness> {
  CtDialogueView? _view;
  DialogueRunner? _runner;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startDialogue();
  }

  Future<void> _startDialogue() async {
    final project = YarnProject();
    project.parse(_kCtDialogueViewStorySource);
    final view = CtDialogueView();
    final runner = DialogueRunner(
      yarnProject: project,
      dialogueViews: [view],
    );
    view.onStateChanged = (_, _) {
      if (mounted) setState(() {});
    };
    setState(() {
      _view = view;
      _runner = runner;
    });
    await runner.startDialogue('ctdv_story');
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    if (view == null || _runner == null) {
      return const CtLoadingIndicator();
    }
    if (_finished) {
      return const Center(child: Icon(Icons.check_circle, size: 32));
    }
    final line = view.currentLine;
    final choice = view.currentChoice;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line != null) ...[
            Text(line.text),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: view.advanceLine,
              child: const Icon(Icons.arrow_forward),
            ),
          ] else if (choice != null) ...[
            for (var i = 0; i < choice.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () => view.selectOption(i),
                  child: Text(choice.options[i].text),
                ),
              ),
          ] else
            const CtLoadingIndicator(),
        ],
      ),
    );
  }
}

const String _kGameStartIntroOverlayStorySource = '''
title: game_start_intro
---
The age of imperialism draweth nigh.
-> I shall.
===
''';

/// Game Start Intro Overlay stories. SPEC/ui/game-start-intro-overlay.md.
List<WidgetbookNode> get gameStartIntroOverlayDirectories => [
  WidgetbookFolder(
    name: 'Game Start Intro Overlay',
    children: [
      WidgetbookUseCase(
        name: 'Default — single-line intro',
        builder: (context) => MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GameStartIntroOverlay(
              onDismissed: () {},
              assetBundle: _InlineYarnAssetBundle(
                _kGameStartIntroOverlayStorySource,
              ),
              child: const Placeholder(),
            ),
          ),
        ),
      ),
    ],
  ),
];

Game _overtureStoryGame() {
  return const Game(
    id: 'wb_overture',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
      Player(
        id: 'gp_portugal',
        displayName: 'Portugal',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_player',
        displayName: 'Player',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

/// Overture Dialogue Overlay stories. SPEC/ui/overture-dialogue-overlay.md.
List<WidgetbookNode> get overtureDialogueOverlayDirectories => [
  WidgetbookFolder(
    name: 'Overture Dialogue Overlay',
    children: [
      WidgetbookUseCase(
        name: 'Default — two pending overtures',
        builder: (context) => MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OvertureDialogueOverlay(
              game: _overtureStoryGame(),
              pendingOvertures: const [
                OvertureOffer(
                  offererGpId: 'gp_spain',
                  targetFactionId: 'gp_player',
                  stage: OvertureStage.tradeConsulate,
                ),
                OvertureOffer(
                  offererGpId: 'gp_portugal',
                  targetFactionId: 'gp_player',
                  stage: OvertureStage.embassy,
                ),
              ],
              skipIntroForTest: true,
              onDecisions: (_) {},
              child: Center(
                child: Text(appL10n(context).widgetbook_gameShell),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
];

Game _callToArmsStoryGame() {
  return const Game(
    id: 'wb_cta',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
      Player(
        id: 'gp_portugal',
        displayName: 'Portugal',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_france',
        displayName: 'France',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_england',
        displayName: 'England',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_player',
        displayName: 'Player',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

/// Call to Arms Dialogue Overlay stories. SPEC/ui/call-to-arms-dialogue-overlay.md.
List<WidgetbookNode> get callToArmsDialogueOverlayDirectories => [
  WidgetbookFolder(
    name: 'Call to Arms Dialogue Overlay',
    children: [
      WidgetbookUseCase(
        name: 'Default — two pending calls',
        builder: (context) => MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CallToArmsDialogueOverlay(
              game: _callToArmsStoryGame(),
              pending: const [
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_portugal',
                  aggressorGpId: 'gp_spain',
                ),
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_france',
                  aggressorGpId: 'gp_england',
                ),
              ],
              onDecisions: (_) {},
              child: Center(
                child: Text(appL10n(context).widgetbook_gameShell),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
];

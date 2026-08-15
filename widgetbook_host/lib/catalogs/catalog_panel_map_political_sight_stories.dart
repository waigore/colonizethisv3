// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Political Sight overlay
// stories (Refs #4406).
part of 'catalog.dart';

/// MAP20001 Political **Sight** row variants. Refs #4406.
List<WidgetbookUseCase> get provinceOverlayPoliticalSightUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Political Sight fully visible',
    builder: (context) => _politicalSightStory(sightPhrase: 'Fully visible'),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Sight fogged',
    builder: (context) =>
        _politicalSightStory(sightPhrase: 'Fogged — terrain only'),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Sight unknown',
    builder: (context) =>
        _politicalSightStory(sightPhrase: 'Unknown — no intel yet'),
  ),
];

Widget _politicalSightStory({required String sightPhrase}) {
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
    child: Builder(
      builder: (BuildContext ctx) {
        final l10n = appL10n(ctx);
        return Center(
          child: SizedBox(
            width: 280,
            child: buildPoliticalSection(
              l10n: l10n,
              name: 'Wessex',
              ownerName: 'England',
              sightPhrase: sightPhrase,
              regionLabel: 'Old World',
              isCapital: false,
              townDevelopmentLevel: 1,
              showUpgradeTownControl: false,
              upgradeTownEnabled: false,
              upgradeTownTooltip: '',
              showEstablishConsulateControl: false,
              establishConsulateEnabled: false,
              establishConsulatePending: false,
              establishConsulateRejectionReason: null,
              isNarrow: false,
            ),
          ),
        );
      },
    ),
  );
}

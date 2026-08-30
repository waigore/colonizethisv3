// coverage:ignore-file
// Dev-only Widgetbook catalog part; Game Tab Bar treasury details
// stories (Refs #4560). Split from catalog_game_chrome.dart so that
// fragment stays under the repo-wide 1000 non-comment-line ceiling.
part of 'catalog.dart';

/// Game Tab Bar treasury-details panel use cases. Refs #4560.
List<WidgetbookUseCase> get _treasuryDetailsTabBarStories => [
  WidgetbookUseCase(
    name: 'Treasury details — committed spend (Refs #4560)',
    builder: (context) => widgetbookEditorialMonocleApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
      child: Builder(
        builder: (BuildContext ctx) {
          final l10n = appL10n(ctx);
          return Center(
            child: SizedBox(
              width: 280,
              child: TreasuryDetailsPanel(
                l10n: l10n,
                treasury: 12345,
                projectedDelta: -400,
                committedLines: const [
                  TreasuryCommittedSpendLine(
                    family: TreasuryCommittedSpendFamily.research,
                    amount: 150,
                  ),
                  TreasuryCommittedSpendLine(
                    family: TreasuryCommittedSpendFamily.grantAid,
                    amount: 1000,
                  ),
                ],
                showExact: true,
                onShowExactChanged: (_) {},
                onClose: () {},
              ),
            ),
          );
        },
      ),
    ),
  ),
  WidgetbookUseCase(
    name: 'Treasury details — forecast only (Refs #4560)',
    builder: (context) => widgetbookEditorialMonocleApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
      child: Builder(
        builder: (BuildContext ctx) {
          final l10n = appL10n(ctx);
          return Center(
            child: SizedBox(
              width: 280,
              child: TreasuryDetailsPanel(
                l10n: l10n,
                treasury: 8000,
                projectedDelta: 250,
                committedLines: const [],
                showExact: true,
                onShowExactChanged: (_) {},
                onClose: () {},
              ),
            ),
          );
        },
      ),
    ),
  ),
  WidgetbookUseCase(
    name: 'Treasury details — observe disabled (Refs #4560)',
    builder: (context) => _gameTabBarStoryFrame(
      treasuryNotDefined: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Treasury details — mobile 360×640 (Refs #4560)',
    builder: (context) => SizedBox(
      width: 360,
      height: 640,
      child: widgetbookEditorialMonocleApp(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
        child: Builder(
          builder: (BuildContext ctx) {
            final l10n = appL10n(ctx);
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 280,
                  child: TreasuryDetailsPanel(
                    l10n: l10n,
                    treasury: 12345,
                    projectedDelta: -400,
                    committedLines: const [
                      TreasuryCommittedSpendLine(
                        family: TreasuryCommittedSpendFamily.marketBids,
                        amount: 320,
                      ),
                    ],
                    showExact: false,
                    onShowExactChanged: (_) {},
                    onClose: () {},
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  ),
];

import 'package:colonizethis_models/colonizethis_models.dart';

import 'development_panel_session_cache.dart';
import 'panel_session_revision.dart';

int developmentPanelWorldRevision(Game game) => panelWorldRevision(game);

DevelopmentPanelStaticSessionRevision developmentPanelStaticSessionRevision({
  required Game game,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: developmentPanelWorldRevision(game),
  );
}

int developmentPanelOrdersRevision(Orders orders) =>
    panelOrdersRevision(orders);

DevelopmentPanelFullSessionRevision developmentPanelFullSessionRevision({
  required Game game,
  required Orders orders,
}) {
  return (
    staticRevision: developmentPanelStaticSessionRevision(game: game),
    ordersRevision: developmentPanelOrdersRevision(orders),
  );
}

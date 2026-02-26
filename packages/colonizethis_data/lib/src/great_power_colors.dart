/// Great Power map colours. GDD 09 (Great Powers & Leaders).
/// Used for ownership fill and ctdev Init Game colour dropdown.

/// Default RGB (r, g, b) per Great Power id. Source: GDD 09-great-powers.
const Map<String, (int r, int g, int b)> greatPowerDefaultColorRgb = {
  'england': (180, 80, 80),
  'france': (80, 140, 200),
  'spain': (220, 180, 60),
  'portugal': (90, 160, 90),
  'netherlands': (220, 140, 100),
  'prussia': (140, 100, 60),
  'sweden': (100, 120, 200),
};

/// Named colour option for dropdown: id, display label, RGB.
typedef GreatPowerColorOption = (String id, String label, (int r, int g, int b) rgb);

/// All GDD colours in fixed order for ctdev colour dropdown (Red, Dark Blue, …).
const List<GreatPowerColorOption> greatPowerColorOptions = [
  ('red', 'Red', (180, 80, 80)),
  ('darkBlue', 'Dark Blue', (80, 140, 200)),
  ('yellow', 'Yellow', (220, 180, 60)),
  ('green', 'Green', (90, 160, 90)),
  ('orange', 'Orange', (220, 140, 100)),
  ('brown', 'Brown', (140, 100, 60)),
  ('lightBlue', 'Light Blue', (100, 120, 200)),
];

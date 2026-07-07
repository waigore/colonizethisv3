part of 'production_allocation_row.dart';

extension _ProductionAllocationRowSlider on ProductionAllocationRow {
  Widget buildAllocationSlider(int maxAchievable) {
    final sliderMax = maxAchievable == 0
        ? 0.0
        : maxAchievable.clamp(1, kProductionAllocationSliderCap).toDouble();
    return CtSlider(
      value: desiredOutput.clamp(0, maxAchievable).toDouble(),
      min: 0,
      max: sliderMax,
      divisions: maxAchievable == 0
          ? 1
          : maxAchievable.clamp(1, kProductionAllocationSliderCap),
      comfortHeadroomActive: comfortHeadroom,
      onChanged: (value) {
        final next = Map<String, int>.from(desiredOutputByRecipe);
        final rounded = value.round().clamp(0, maxAchievable);
        if (rounded == 0) {
          next.remove(recipe.id);
        } else {
          next[recipe.id] = rounded;
        }
        onDesiredOutputChanged(next);
      },
    );
  }
}

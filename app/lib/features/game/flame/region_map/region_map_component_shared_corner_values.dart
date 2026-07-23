/// Wang corner bitmask for terrain transition tiles (Refs #4117).
class RegionMapComponentCornerValues {
  final bool nw;
  final bool ne;
  final bool sw;
  final bool se;
  final bool same;
  final bool value;

  const RegionMapComponentCornerValues({
    required this.nw,
    required this.ne,
    required this.sw,
    required this.se,
    required this.same,
    required this.value,
  });
}

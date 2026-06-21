enum LandSeedClusterShape { gaussian, uniformDisk, uniformAnnulus }

abstract interface class TileMapLandSeedParams {
  int get width;
  int get height;
  int get seed;
  double get seaFraction;
  double get voronoiNoiseScale;
  int get continentBufferTiles;
  LandSeedClusterShape get clusterShape;
}

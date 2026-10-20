/// Refrigerated location with an acceptable temperature band.
class Fridge {
  const Fridge({
    required this.id,
    required this.name,
    required this.minCelsius,
    required this.maxCelsius,
  });

  final String id;
  final String name;
  final double minCelsius;
  final double maxCelsius;

  bool contains(double temperatureCelsius) {
    return temperatureCelsius >= minCelsius && temperatureCelsius <= maxCelsius;
  }

  /// The dial starts here. The band is only a warning, not a block.
  double get midpoint => (minCelsius + maxCelsius) / 2;
}

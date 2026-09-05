enum DeadReckoningMode {
  uninitialized,
  gps,
  deadReckoning,
}

class DeadReckoningPosition {
  const DeadReckoningPosition({
    required this.latitude,
    required this.longitude,
    required this.headingDeg,
    required this.mode,
    required this.initialized,
  });

  final double latitude;
  final double longitude;
  final double headingDeg;
  final DeadReckoningMode mode;
  final bool initialized;
}
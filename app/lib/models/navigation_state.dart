enum NavigationMode {
  uninitialized,
  gps,
  deadReckoning,
}

class NavigationState {
  const NavigationState({
    required this.latitude,
    required this.longitude,
    required this.headingDeg,
    required this.speedMps,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.gpsAccuracyM,
    required this.gpsSpeedMps,
    required this.gpsHeadingDeg,
    required this.gnssHealthy,
    required this.initialized,
    required this.mode,
    required this.lastGpsTimestampMs,
  });

  factory NavigationState.initial() {
    return const NavigationState(
      latitude: 0.0,
      longitude: 0.0,
      headingDeg: 0.0,
      speedMps: 0.0,
      gpsLatitude: null,
      gpsLongitude: null,
      gpsAccuracyM: null,
      gpsSpeedMps: null,
      gpsHeadingDeg: null,
      gnssHealthy: false,
      initialized: false,
      mode: NavigationMode.uninitialized,
      lastGpsTimestampMs: null,
    );
  }

  final double latitude;
  final double longitude;
  final double headingDeg;
  final double speedMps;

  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? gpsAccuracyM;
  final double? gpsSpeedMps;
  final double? gpsHeadingDeg;

  final bool gnssHealthy;
  final bool initialized;

  final NavigationMode mode;

  final int? lastGpsTimestampMs;

  NavigationState copyWith({
    double? latitude,
    double? longitude,
    double? headingDeg,
    double? speedMps,
    double? gpsLatitude,
    double? gpsLongitude,
    double? gpsAccuracyM,
    double? gpsSpeedMps,
    double? gpsHeadingDeg,
    bool? gnssHealthy,
    bool? initialized,
    NavigationMode? mode,
    int? lastGpsTimestampMs,
    bool clearGps = false,
  }) {
    return NavigationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      headingDeg: headingDeg ?? this.headingDeg,
      speedMps: speedMps ?? this.speedMps,

      gpsLatitude:
          clearGps ? null : gpsLatitude ?? this.gpsLatitude,

      gpsLongitude:
          clearGps ? null : gpsLongitude ?? this.gpsLongitude,

      gpsAccuracyM:
          clearGps ? null : gpsAccuracyM ?? this.gpsAccuracyM,

      gpsSpeedMps:
          clearGps ? null : gpsSpeedMps ?? this.gpsSpeedMps,

      gpsHeadingDeg:
          clearGps ? null : gpsHeadingDeg ?? this.gpsHeadingDeg,

      gnssHealthy:
          gnssHealthy ?? this.gnssHealthy,

      initialized:
          initialized ?? this.initialized,

      mode:
          mode ?? this.mode,

      lastGpsTimestampMs:
          clearGps
              ? null
              : lastGpsTimestampMs ?? this.lastGpsTimestampMs,
    );
  }

  String get modeLabel {
    switch (mode) {
      case NavigationMode.gps:
        return 'GPS ACTIVE';

      case NavigationMode.deadReckoning:
        return 'AI DEAD-RECKONING';

      case NavigationMode.uninitialized:
        return 'INITIALIZING';
    }
  }
}
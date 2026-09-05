class SensorCapabilities {
  final bool accelerometer;
  final bool gyroscope;
  final bool magnetometer;
  final bool barometer;
  final bool gps;
  final bool camera;

  const SensorCapabilities({
    required this.accelerometer,
    required this.gyroscope,
    required this.magnetometer,
    required this.barometer,
    required this.gps,
    required this.camera,
  });
}
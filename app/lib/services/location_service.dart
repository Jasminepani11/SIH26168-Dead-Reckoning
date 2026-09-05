import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream =>
      _positionController.stream;

  Position? currentPosition;

  Future<bool> initialize() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      return false;
    }

    /*
     * Do not require an immediate GPS fix here.
     *
     * Android may take some time to obtain the first
     * GNSS position. The continuous position stream
     * should still be started immediately.
     */
    try {
      currentPosition =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      /*
       * No initial fix yet is not a fatal error.
       * startListening() will continue waiting for GPS.
       */
      currentPosition = null;
    }

    return true;
  }

  void startListening() {
    _positionSubscription?.cancel();

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (Position position) {
        currentPosition = position;

        if (!_positionController.isClosed) {
          _positionController.add(position);
        }
      },
    );
  }

  Future<Position> getCurrentPosition() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied.',
        );
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied.',
      );
    }

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    currentPosition = position;

    return position;
  }

  Future<bool> start() async {
    final initialized =
        await initialize();

    if (!initialized) {
      return false;
    }

    /*
     * Start the continuous stream regardless of
     * whether initialize() obtained an immediate fix.
     */
    startListening();

    return true;
  }

  void stop() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stop();

    if (!_positionController.isClosed) {
      _positionController.close();
    }
  }
}
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/dead_reckoning_models.dart';
import '../models/navigation_state.dart';
import 'dead_reckoning_bridge.dart';
import 'location_service.dart';
import 'sensor_service.dart';

class NavigationService {
  NavigationService({
    LocationService? locationService,
    SensorService? sensorService,
    DeadReckoningBridge? deadReckoningBridge,
  })  : _locationService =
            locationService ?? LocationService(),
        _sensorService =
            sensorService ?? SensorService(),
        _deadReckoningBridge =
            deadReckoningBridge ?? DeadReckoningBridge();

  final LocationService _locationService;
  final SensorService _sensorService;
  final DeadReckoningBridge _deadReckoningBridge;

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<SensorFrame>? _sensorSubscription;

  final StreamController<NavigationState> _stateController =
      StreamController<NavigationState>.broadcast();

  NavigationState _state = NavigationState.initial();

  bool _started = false;

  NavigationState get state => _state;

  Stream<NavigationState> get stateStream =>
      _stateController.stream;

  Future<bool> start() async {
    if (_started) {
      return true;
    }

    _started = true;

    final locationStarted =
        await _locationService.start();

    if (!locationStarted) {
      _updateState(
        _state.copyWith(
          gnssHealthy: false,
        ),
      );
    }

    _sensorService.start();

    _gpsSubscription =
        _locationService.positionStream.listen(
      _onGpsPosition,
    );

    _sensorSubscription =
        _sensorService.frameStream.listen(
      _onSensorFrame,
    );

    final initialPosition =
        _locationService.currentPosition;

    if (initialPosition != null) {
      _onGpsPosition(initialPosition!);
    }

    return locationStarted;
  }

  void _onGpsPosition(Position position) {
    final timestampMs =
        position.timestamp.millisecondsSinceEpoch;

    final accuracy = position.accuracy;
    final speed =
        position.speed.isFinite && position.speed >= 0
            ? position.speed
            : null;

    final heading =
        position.heading.isFinite &&
                position.heading >= 0
            ? position.heading
            : null;

    final gpsHealthy =
        accuracy.isFinite &&
        accuracy <= 20.0 &&
        position.latitude.isFinite &&
        position.longitude.isFinite;

    _deadReckoningBridge.updateGps(
      latitude: position.latitude,
      longitude: position.longitude,
      timestampMs: timestampMs,
      horizontalAccuracyM:
          accuracy.isFinite ? accuracy : null,
      speedMps: speed,
      bearingDeg: heading,
    );

    final drPosition =
        _deadReckoningBridge.position;

    _updateState(
      _state.copyWith(
        latitude: drPosition.latitude,
        longitude: drPosition.longitude,
        headingDeg: _selectHeading(
          drPosition,
          heading,
        ),
        speedMps: speed ?? _state.speedMps,
        gpsLatitude: position.latitude,
        gpsLongitude: position.longitude,
        gpsAccuracyM:
            accuracy.isFinite ? accuracy : null,
        gpsSpeedMps: speed,
        gpsHeadingDeg: heading,
        gnssHealthy: gpsHealthy,
        initialized: drPosition.initialized,
        mode: _mapMode(drPosition.mode),
        lastGpsTimestampMs: timestampMs,
      ),
    );
  }

  void _onSensorFrame(SensorFrame frame) {
    _deadReckoningBridge.updateImu(
      accelX: frame.accelX,
      accelY: frame.accelY,
      accelZ: frame.accelZ,
      gravityX: frame.gravityX,
      gravityY: frame.gravityY,
      gravityZ: frame.gravityZ,
      gyroX: frame.gyroX,
      gyroY: frame.gyroY,
      gyroZ: frame.gyroZ,
      yawDeg: frame.yawDeg,
      pitchDeg: frame.pitchDeg,
      rollDeg: frame.rollDeg,
      timestampMs: frame.timestampMs,
    );

    final drPosition =
        _deadReckoningBridge.position;

    final gpsStillFresh =
        _state.lastGpsTimestampMs != null &&
        DateTime.now()
                .millisecondsSinceEpoch -
            _state.lastGpsTimestampMs! <=
            2500;

    final mode = gpsStillFresh &&
            _state.gnssHealthy
        ? NavigationMode.gps
        : NavigationMode.deadReckoning;

    _updateState(
      _state.copyWith(
        latitude: drPosition.latitude,
        longitude: drPosition.longitude,
        headingDeg: drPosition.headingDeg,
        initialized: drPosition.initialized,
        mode: mode,
        gnssHealthy: gpsStillFresh &&
            _state.gnssHealthy,
      ),
    );
  }

  double _selectHeading(
    DeadReckoningPosition drPosition,
    double? gpsHeading,
  ) {
    if (gpsHeading != null &&
        gpsHeading.isFinite &&
        _state.gnssHealthy) {
      return gpsHeading;
    }

    return drPosition.headingDeg;
  }

  NavigationMode _mapMode(
    DeadReckoningMode mode,
  ) {
    switch (mode) {
      case DeadReckoningMode.gps:
        return NavigationMode.gps;

      case DeadReckoningMode.deadReckoning:
        return NavigationMode.deadReckoning;

      case DeadReckoningMode.uninitialized:
        return NavigationMode.uninitialized;
    }
  }

  void _updateState(NavigationState newState) {
    _state = newState;

    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void reset() {
    _deadReckoningBridge.reset();

    _state = NavigationState.initial();

    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void stop() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;

    _sensorSubscription?.cancel();
    _sensorSubscription = null;

    _locationService.stop();

    _started = false;
  }

  void dispose() {
    stop();

    _sensorService.close();
    _deadReckoningBridge.dispose();

    if (!_stateController.isClosed) {
      _stateController.close();
    }
  }
}
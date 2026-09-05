import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class SensorFrame {
  const SensorFrame({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gravityX,
    required this.gravityY,
    required this.gravityZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.magnetometerX,
    required this.magnetometerY,
    required this.magnetometerZ,
    required this.yawDeg,
    required this.pitchDeg,
    required this.rollDeg,
    required this.timestampMs,
  });

  final double accelX;
  final double accelY;
  final double accelZ;

  final double gravityX;
  final double gravityY;
  final double gravityZ;

  final double gyroX;
  final double gyroY;
  final double gyroZ;

  final double magnetometerX;
  final double magnetometerY;
  final double magnetometerZ;

  final double yawDeg;
  final double pitchDeg;
  final double rollDeg;

  final int timestampMs;
}

class SensorService {
  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription;

  StreamSubscription<UserAccelerometerEvent>?
      _userAccelerometerSubscription;

  StreamSubscription<GyroscopeEvent>?
      _gyroscopeSubscription;

  StreamSubscription<MagnetometerEvent>?
      _magnetometerSubscription;

  AccelerometerEvent? _accelerometer;
  UserAccelerometerEvent? _userAccelerometer;
  GyroscopeEvent? _gyroscope;
  MagnetometerEvent? _magnetometer;

  double _gravityX = 0.0;
  double _gravityY = 0.0;
  double _gravityZ = 0.0;

  bool accelerometerWorking = false;
  bool gyroscopeWorking = false;
  bool magnetometerWorking = false;

  SensorFrame? latestFrame;

  final StreamController<SensorFrame>
      _frameController =
      StreamController<SensorFrame>.broadcast();

  Stream<SensorFrame> get frameStream =>
      _frameController.stream;

  void start() {
    dispose();

    _accelerometerSubscription =
        accelerometerEventStream().listen(
      (event) {
        _accelerometer = event;
        accelerometerWorking = true;

        _updateGravity();
        _emitFrame();
      },
    );

    _userAccelerometerSubscription =
        userAccelerometerEventStream().listen(
      (event) {
        _userAccelerometer = event;

        _updateGravity();
        _emitFrame();
      },
    );

    _gyroscopeSubscription =
        gyroscopeEventStream().listen(
      (event) {
        _gyroscope = event;
        gyroscopeWorking = true;

        _emitFrame();
      },
    );

    _magnetometerSubscription =
        magnetometerEventStream().listen(
      (event) {
        _magnetometer = event;
        magnetometerWorking = true;

        _emitFrame();
      },
    );
  }

  void _updateGravity() {
    final accelerometer = _accelerometer;
    final userAccelerometer =
        _userAccelerometer;

    if (accelerometer == null) {
      return;
    }

    if (userAccelerometer == null) {
      _gravityX = accelerometer.x;
      _gravityY = accelerometer.y;
      _gravityZ = accelerometer.z;
      return;
    }

    _gravityX =
        accelerometer.x -
        userAccelerometer.x;

    _gravityY =
        accelerometer.y -
        userAccelerometer.y;

    _gravityZ =
        accelerometer.z -
        userAccelerometer.z;
  }

  void _emitFrame() {
    final accelerometer = _accelerometer;
    final userAccelerometer =
        _userAccelerometer;
    final gyroscope = _gyroscope;
    final magnetometer = _magnetometer;

    if (accelerometer == null ||
        userAccelerometer == null ||
        gyroscope == null ||
        magnetometer == null) {
      return;
    }

    final yaw = _calculateYaw(
      magnetometer.x,
      magnetometer.y,
      magnetometer.z,
    );

    final pitch = _calculatePitch(
      _gravityX,
      _gravityY,
      _gravityZ,
    );

    final roll = _calculateRoll(
      _gravityX,
      _gravityY,
      _gravityZ,
    );

    /*
     * IMPORTANT:
     *
     * accelX/Y/Z sent to the native DR engine are
     * USER acceleration values, not raw
     * accelerometer values.
     *
     * Raw accelerometer contains gravity.
     * User accelerometer has gravity removed.
     */
    final frame = SensorFrame(
      accelX: userAccelerometer.x,
      accelY: userAccelerometer.y,
      accelZ: userAccelerometer.z,

      gravityX: _gravityX,
      gravityY: _gravityY,
      gravityZ: _gravityZ,

      gyroX: gyroscope.x,
      gyroY: gyroscope.y,
      gyroZ: gyroscope.z,

      magnetometerX: magnetometer.x,
      magnetometerY: magnetometer.y,
      magnetometerZ: magnetometer.z,

      yawDeg: yaw,
      pitchDeg: pitch,
      rollDeg: roll,

      timestampMs:
          DateTime.now()
              .millisecondsSinceEpoch,
    );

    latestFrame = frame;

    if (!_frameController.isClosed) {
      _frameController.add(frame);
    }
  }

  double _calculateYaw(
    double x,
    double y,
    double z,
  ) {
    final heading =
        math.atan2(y, x) *
        180.0 /
        math.pi;

    return _normalizeDegrees(heading);
  }

  double _calculatePitch(
    double x,
    double y,
    double z,
  ) {
    return math.atan2(
          -x,
          math.sqrt(
            y * y +
            z * z,
          ),
        ) *
        180.0 /
        math.pi;
  }

  double _calculateRoll(
    double x,
    double y,
    double z,
  ) {
    return math.atan2(
          y,
          z,
        ) *
        180.0 /
        math.pi;
  }

  double _normalizeDegrees(
    double value,
  ) {
    var result = value % 360.0;

    if (result < 0) {
      result += 360.0;
    }

    return result;
  }

  void dispose() {
    _accelerometerSubscription
        ?.cancel();
    _accelerometerSubscription = null;

    _userAccelerometerSubscription
        ?.cancel();
    _userAccelerometerSubscription =
        null;

    _gyroscopeSubscription
        ?.cancel();
    _gyroscopeSubscription = null;

    _magnetometerSubscription
        ?.cancel();
    _magnetometerSubscription = null;
  }

  void close() {
    dispose();

    if (!_frameController.isClosed) {
      _frameController.close();
    }
  }
}
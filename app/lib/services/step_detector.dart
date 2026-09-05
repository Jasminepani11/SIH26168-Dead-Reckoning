import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class StepDetector {
  StreamSubscription<AccelerometerEvent>? _subscription;

  int stepCount = 0;

  double _previousMagnitude = 0;
  DateTime _lastStepTime = DateTime.fromMillisecondsSinceEpoch(0);

  final StreamController<int> _stepController =
      StreamController<int>.broadcast();

  Stream<int> get steps => _stepController.stream;

  void start() {
    _subscription = accelerometerEventStream().listen((event) {
      _processAcceleration(event);
    });
  }

  void _processAcceleration(AccelerometerEvent event) {
    // Calculate total acceleration magnitude.
    final magnitude = sqrt(
      event.x * event.x +
          event.y * event.y +
          event.z * event.z,
    );

    // How much the acceleration changed.
    final difference =
        (magnitude - _previousMagnitude).abs();

    _previousMagnitude = magnitude;

    final now = DateTime.now();

    // Prevent detecting multiple steps too quickly.
    final timeSinceLastStep =
        now.difference(_lastStepTime).inMilliseconds;

    // Basic walking detection.
    if (difference > 1.2 && timeSinceLastStep > 300) {
      stepCount++;

      _lastStepTime = now;

      _stepController.add(stepCount);
    }
  }

  void reset() {
    stepCount = 0;
    _stepController.add(stepCount);
  }

  void dispose() {
    _subscription?.cancel();
    _stepController.close();
  }
}
import 'dart:ffi';
import 'dart:io';

import '../models/dead_reckoning_models.dart';

typedef _CreateNative = Pointer<Void> Function();
typedef _CreateDart = Pointer<Void> Function();

typedef _DestroyNative = Void Function(Pointer<Void>);
typedef _DestroyDart = void Function(Pointer<Void>);

typedef _ResetNative = Void Function(Pointer<Void>);
typedef _ResetDart = void Function(Pointer<Void>);

typedef _UpdateGpsNative = Void Function(
  Pointer<Void>,
  Double,
  Double,
  Int64,
  Int32,
  Double,
  Int32,
  Double,
  Int32,
  Double,
);

typedef _UpdateGpsDart = void Function(
  Pointer<Void>,
  double,
  double,
  int,
  int,
  double,
  int,
  double,
  int,
  double,
);

typedef _UpdateImuNative = Void Function(
  Pointer<Void>,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
  Double,
  Int64,
);

typedef _UpdateImuDart = void Function(
  Pointer<Void>,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  int,
);

typedef _GetDoubleNative = Double Function(Pointer<Void>);
typedef _GetDoubleDart = double Function(Pointer<Void>);

typedef _GetIntNative = Int32 Function(Pointer<Void>);
typedef _GetIntDart = int Function(Pointer<Void>);

class DeadReckoningBridge {
  DeadReckoningBridge() : _library = _openLibrary() {
    _create = _library.lookupFunction<
        _CreateNative,
        _CreateDart>('dr_create');

    _destroy = _library.lookupFunction<
        _DestroyNative,
        _DestroyDart>('dr_destroy');

    _reset = _library.lookupFunction<
        _ResetNative,
        _ResetDart>('dr_reset');

    _updateGps = _library.lookupFunction<
        _UpdateGpsNative,
        _UpdateGpsDart>('dr_update_gps');

    _updateImu = _library.lookupFunction<
        _UpdateImuNative,
        _UpdateImuDart>('dr_update_imu');

    _getLatitude = _library.lookupFunction<
        _GetDoubleNative,
        _GetDoubleDart>('dr_get_latitude');

    _getLongitude = _library.lookupFunction<
        _GetDoubleNative,
        _GetDoubleDart>('dr_get_longitude');

    _getHeading = _library.lookupFunction<
        _GetDoubleNative,
        _GetDoubleDart>('dr_get_heading_deg');

    _getMode = _library.lookupFunction<
        _GetIntNative,
        _GetIntDart>('dr_get_mode');

    _isInitialized = _library.lookupFunction<
        _GetIntNative,
        _GetIntDart>('dr_is_initialized');

    _handle = _create();
  }

  final DynamicLibrary _library;

  late final _CreateDart _create;
  late final _DestroyDart _destroy;
  late final _ResetDart _reset;
  late final _UpdateGpsDart _updateGps;
  late final _UpdateImuDart _updateImu;

  late final _GetDoubleDart _getLatitude;
  late final _GetDoubleDart _getLongitude;
  late final _GetDoubleDart _getHeading;

  late final _GetIntDart _getMode;
  late final _GetIntDart _isInitialized;

  late Pointer<Void> _handle;

  static DynamicLibrary _openLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('libdead_reckoning.so');
    }

    if (Platform.isWindows) {
      return DynamicLibrary.open('dead_reckoning.dll');
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.process();
    }

    throw UnsupportedError(
      'Unsupported platform',
    );
  }

  void reset() {
    _reset(_handle);
  }

  void dispose() {
    if (_handle != nullptr) {
      _destroy(_handle);
      _handle = nullptr;
    }
  }

  void updateGps({
    required double latitude,
    required double longitude,
    required int timestampMs,
    double? horizontalAccuracyM,
    double? speedMps,
    double? bearingDeg,
  }) {
    _updateGps(
      _handle,
      latitude,
      longitude,
      timestampMs,
      horizontalAccuracyM != null ? 1 : 0,
      horizontalAccuracyM ?? 0.0,
      speedMps != null ? 1 : 0,
      speedMps ?? 0.0,
      bearingDeg != null ? 1 : 0,
      bearingDeg ?? 0.0,
    );
  }

  void updateImu({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gravityX,
    required double gravityY,
    required double gravityZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double yawDeg,
    required double pitchDeg,
    required double rollDeg,
    required int timestampMs,
  }) {
    _updateImu(
      _handle,
      accelX,
      accelY,
      accelZ,
      gravityX,
      gravityY,
      gravityZ,
      gyroX,
      gyroY,
      gyroZ,
      yawDeg,
      pitchDeg,
      rollDeg,
      timestampMs,
    );
  }

  DeadReckoningPosition get position {
    final rawMode = _getMode(_handle);

    final mode = switch (rawMode) {
      1 => DeadReckoningMode.gps,
      2 => DeadReckoningMode.deadReckoning,
      _ => DeadReckoningMode.uninitialized,
    };

    return DeadReckoningPosition(
      latitude: _getLatitude(_handle),
      longitude: _getLongitude(_handle),
      headingDeg: _getHeading(_handle),
      mode: mode,
      initialized: _isInitialized(_handle) != 0,
    );
  }
}
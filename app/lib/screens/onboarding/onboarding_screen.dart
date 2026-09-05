import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _locationReady = false;
  bool _sensorsReady = false;

  bool _checkingLocation = false;
  bool _checkingSensors = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  // ============================================================
  // INITIAL CHECK
  // ============================================================

  Future<void> _checkInitialStatus() async {
    await _checkLocationStatus();
    await _checkSensorStatus();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _checkLocationStatus() async {
    try {
      final permission = await Geolocator.checkPermission();

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      setState(() {
        _locationReady =
            serviceEnabled &&
            (permission == LocationPermission.always ||
                permission == LocationPermission.whileInUse);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _locationReady = false;
      });
    }
  }

  Future<void> _enableLocation() async {
    setState(() {
      _checkingLocation = true;
    });

    try {
      // Check whether GPS/location service is enabled.
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        await Geolocator.openLocationSettings();

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        serviceEnabled =
            await Geolocator.isLocationServiceEnabled();
      }

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on Location/GPS and try again.',
        );

        if (mounted) {
          setState(() {
            _checkingLocation = false;
          });
        }

        return;
      }

      // Check current permission.
      LocationPermission permission =
          await Geolocator.checkPermission();

      // Request permission if needed.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          'Location permission was denied.',
        );
      } else if (permission ==
          LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. '
          'Please enable it from Settings.',
        );

        await Geolocator.openAppSettings();
      }

      await _checkLocationStatus();
    } catch (e) {
      _showMessage(
        'Unable to check location permission.',
      );
    }

    if (!mounted) return;

    setState(() {
      _checkingLocation = false;
    });
  }

  // ============================================================
  // SENSOR CHECK
  // ============================================================

  Future<void> _checkSensorStatus() async {
    if (mounted) {
      setState(() {
        _checkingSensors = true;
      });
    }

    bool accelerometerWorking = false;
    bool gyroscopeWorking = false;

    try {
      // Wait for actual accelerometer data.
      try {
        await accelerometerEventStream()
            .first
            .timeout(
              const Duration(seconds: 2),
            );

        accelerometerWorking = true;
      } catch (_) {}

      // Wait for actual gyroscope data.
      try {
        await gyroscopeEventStream()
            .first
            .timeout(
              const Duration(seconds: 2),
            );

        gyroscopeWorking = true;
      } catch (_) {}
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _sensorsReady =
          accelerometerWorking &&
          gyroscopeWorking;

      _checkingSensors = false;
    });

    if (!_sensorsReady) {
      _showMessage(
        'Accelerometer or gyroscope could not be detected.',
      );
    }
  }

  // ============================================================
  // CONTINUE
  // ============================================================

  void _continue() {
    if (!_locationReady) {
      _showMessage(
        'Please enable Location first.',
      );
      return;
    }

    if (!_sensorsReady) {
      _showMessage(
        'Please make sure the required sensors are working.',
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainShell(),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),

            child: Column(
              children: [
                const SizedBox(height: 28),

                // ==================================================
                // LOGO
                // ==================================================

                Container(
                  width: 72,
                  height: 72,

                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color: const Color(0xFF00E5FF),
                      width: 2,
                    ),

                    color: const Color(0xFF00E5FF)
                        .withValues(alpha: 0.06),
                  ),

                  child: const Icon(
                    Icons.navigation_rounded,
                    size: 38,
                    color: Color(0xFF00E5FF),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'NAVIAI',

                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'INTELLIGENT NAVIGATION',

                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Let’s prepare your device for\n'
                  'intelligent navigation.',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // LOCATION CARD
                // ==================================================

                _SetupCard(
                  icon: Icons.location_on_rounded,

                  title: 'Location Access',

                  description:
                      'Used to determine your starting position '
                      'and provide GPS-based navigation.',

                  enabled: _locationReady,

                  loading: _checkingLocation,

                  buttonText: _locationReady
                      ? 'ENABLED'
                      : 'ENABLE LOCATION',

                  onPressed: _locationReady
                      ? null
                      : _enableLocation,
                ),

                const SizedBox(height: 14),

                // ==================================================
                // SENSOR CARD
                // ==================================================

                _SetupCard(
                  icon: Icons.sensors_rounded,

                  title: 'Motion Sensors',

                  description:
                      'Accelerometer and gyroscope are used '
                      'for movement tracking and dead reckoning.',

                  enabled: _sensorsReady,

                  loading: _checkingSensors,

                  buttonText: _sensorsReady
                      ? 'READY'
                      : 'CHECK SENSORS',

                  onPressed: _sensorsReady
                      ? null
                      : _checkSensorStatus,
                ),

                const SizedBox(height: 28),

                // ==================================================
                // STATUS
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    _StatusDot(
                      active: _locationReady,
                    ),

                    const SizedBox(width: 7),

                    Text(
                      _locationReady
                          ? 'Location ready'
                          : 'Location required',

                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    _StatusDot(
                      active: _sensorsReady,
                    ),

                    const SizedBox(width: 7),

                    Text(
                      _sensorsReady
                          ? 'Sensors ready'
                          : 'Sensors required',

                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CONTINUE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed: _continue,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF00E5FF),

                      foregroundColor: Colors.black,

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    child: const Text(
                      'CONTINUE',

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // BRANDING
                // ==================================================

                Text(
                  'Powered by DRIFT',

                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SETUP CARD
// ============================================================================

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final bool loading;
  final String buttonText;
  final VoidCallback? onPressed;

  const _SetupCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.loading,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: const Color(0xFF11161D),

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: enabled
              ? const Color(0xFF35E58A)
                  .withValues(alpha: 0.35)
              : Colors.white.withValues(
                  alpha: 0.06,
                ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ========================================================
          // ICON
          // ========================================================

          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(14),

              color: enabled
                  ? const Color(0xFF35E58A)
                      .withValues(alpha: 0.1)
                  : const Color(0xFF00E5FF)
                      .withValues(alpha: 0.08),
            ),

            child: loading
                ? const Padding(
                    padding:
                        EdgeInsets.all(12),

                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,

                      color:
                          Color(0xFF00E5FF),
                    ),
                  )
                : Icon(
                    enabled
                        ? Icons.check_rounded
                        : icon,

                    color: enabled
                        ? const Color(
                            0xFF35E58A,
                          )
                        : const Color(
                            0xFF00E5FF,
                          ),

                    size: 24,
                  ),
          ),

          const SizedBox(width: 14),

          // ========================================================
          // CONTENT
          // ========================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,

                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Colors.white
                        .withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),

                const SizedBox(height: 11),

                SizedBox(
                  height: 33,

                  child: OutlinedButton(
                    onPressed:
                        loading ? null : onPressed,

                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor: enabled
                          ? const Color(
                              0xFF35E58A,
                            )
                          : const Color(
                              0xFF00E5FF,
                            ),

                      side: BorderSide(
                        color: enabled
                            ? const Color(
                                0xFF35E58A,
                              ).withValues(
                                alpha: 0.4,
                              )
                            : const Color(
                                0xFF00E5FF,
                              ).withValues(
                                alpha: 0.4,
                              ),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 13,
                      ),
                    ),

                    child: Text(
                      buttonText,

                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS DOT
// ============================================================================

class _StatusDot extends StatelessWidget {
  final bool active;

  const _StatusDot({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: active
            ? const Color(0xFF35E58A)
            : Colors.white.withValues(
                alpha: 0.25,
              ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/navigation_state.dart' as nav;
import '../../models/place_result.dart';
import '../../models/route_request.dart';
import '../../services/navigation_service.dart';
import '../destination/destination_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final NavigationService _navigationService =
      NavigationService();

  StreamSubscription<nav.NavigationState>?
      _navigationSubscription;

  nav.NavigationState _navigationState =
      nav.NavigationState.initial();

  PlaceResult? _fromPlace;
  PlaceResult? _toPlace;

  List<LatLng> _routePoints = [];

  double _routeDistance = 0;
  double _routeDuration = 0;

  bool _loadingRoute = false;
  bool _journeyStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    _navigationService.dispose();
    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _initializeNavigation() async {
    _navigationSubscription =
        _navigationService.stateStream.listen(
      _onNavigationState,
    );

    try {
      await _navigationService.start();
    } catch (_) {
      // Native navigation will be fully available once the
      // Android native library is connected.
    }
  }

  void _onNavigationState(nav.NavigationState state) {
    if (!mounted) return;

    setState(() {
      _navigationState = state;
    });

    if (_journeyStarted &&
        state.initialized &&
        state.latitude.isFinite &&
        state.longitude.isFinite) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _mapController.move(
          LatLng(
            state.latitude,
            state.longitude,
          ),
          16,
        );
      });
    }
  }

  // ============================================================
  // DESTINATION SCREEN
  // ============================================================

  Future<void> _openDestinationScreen() async {
    final result = await Navigator.push<RouteRequest>(
      context,
      MaterialPageRoute(
        builder: (_) => const DestinationScreen(),
      ),
    );

    if (result == null || !mounted) return;

    await _applyRouteRequest(result);
  }

  Future<void> _applyRouteRequest(
    RouteRequest request,
  ) async {
    setState(() {
      _fromPlace = request.from;
      _toPlace = request.to;

      _routePoints = [];

      _routeDistance = 0;
      _routeDuration = 0;

      _journeyStarted = false;
    });

    await _calculateRoute();
  }

  // ============================================================
  // ROUTE CALCULATION
  // ============================================================

  Future<void> _calculateRoute() async {
    if (_fromPlace == null || _toPlace == null) {
      return;
    }

    setState(() {
      _loadingRoute = true;
    });

    try {
      final from = _fromPlace!.latLng;
      final to = _toPlace!.latLng;

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full'
        '&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Route request failed');
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        throw Exception('No route found');
      }

      final routes = data['routes'] as List;

      if (routes.isEmpty) {
        throw Exception('No route found');
      }

      final route =
          routes.first as Map<String, dynamic>;

      final geometry =
          route['geometry']
              as Map<String, dynamic>;

      final coordinates =
          geometry['coordinates'] as List;

      final points =
          coordinates.map<LatLng>((coordinate) {
        final pair = coordinate as List;

        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      final distance =
          (route['distance'] as num?)?.toDouble() ?? 0;

      final duration =
          (route['duration'] as num?)?.toDouble() ?? 0;

      if (!mounted) return;

      setState(() {
        _routePoints = points;
        _routeDistance = distance;
        _routeDuration = duration;
        _loadingRoute = false;
      });

      _fitRouteOnMap();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingRoute = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to calculate route. Check your internet connection.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // JOURNEY
  // ============================================================

  void _startJourney() {
    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please plan a route first.',
          ),
        ),
      );

      return;
    }

    if (!_navigationState.initialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Navigation is still initializing.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _journeyStarted = true;
    });

    _recenterMap();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Journey started',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopJourney() {
    setState(() {
      _journeyStarted = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Journey stopped',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  void _fitRouteOnMap() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;

    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat = math.min(
        minLat,
        point.latitude,
      );

      maxLat = math.max(
        maxLat,
        point.latitude,
      );

      minLng = math.min(
        minLng,
        point.longitude,
      );

      maxLng = math.max(
        maxLng,
        point.longitude,
      );
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    final latDifference =
        (maxLat - minLat).abs();

    final lngDifference =
        (maxLng - minLng).abs();

    final maxDifference = math.max(
      latDifference,
      lngDifference,
    );

    double zoom = 14;

    if (maxDifference > 0.2) {
      zoom = 9;
    } else if (maxDifference > 0.1) {
      zoom = 10;
    } else if (maxDifference > 0.05) {
      zoom = 11;
    } else if (maxDifference > 0.02) {
      zoom = 12;
    } else if (maxDifference > 0.01) {
      zoom = 13;
    } else if (maxDifference > 0.005) {
      zoom = 14;
    } else {
      zoom = 15;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _mapController.move(
        center,
        zoom,
      );
    });
  }

  void _recenterMap() {
    final state = _navigationState;

    LatLng? center;

    if (state.initialized &&
        state.latitude.isFinite &&
        state.longitude.isFinite &&
        !(state.latitude == 0 &&
            state.longitude == 0)) {
      center = LatLng(
        state.latitude,
        state.longitude,
      );
    } else if (_fromPlace != null) {
      center = _fromPlace!.latLng;
    }

    if (center == null) return;

    _mapController.move(
      center,
      _journeyStarted ? 16 : 14,
    );
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remaining}m';
  }

  String _formatSpeed(double speedMps) {
    return '${(speedMps * 3.6).toStringAsFixed(1)} km/h';
  }

  String _formatHeading(double heading) {
    return '${heading.round()}°';
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            0,
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF0D131A,
                  ).withValues(alpha: 0.94),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.navigation_rounded,
                      color: Color(0xFF00E5FF),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'NAVIAI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              _buildModeBadge(),

              const SizedBox(width: 8),

              _roundIconButton(
                Icons.my_location,
                _recenterMap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    final mode = _navigationState.mode;

    final Color borderColor;
    final String label;
    final IconData icon;

    switch (mode) {
      case nav.NavigationMode.gps:
        borderColor = const Color(0xFF35E58A);
        label = 'GPS';
        icon = Icons.gps_fixed;
        break;

      case nav.NavigationMode.deadReckoning:
        borderColor = const Color(0xFFB999FF);
        label = 'AI-DR';
        icon = Icons.psychology;
        break;

      case nav.NavigationMode.uninitialized:
        borderColor = Colors.white38;
        label = 'INIT';
        icon = Icons.sync;
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF0D131A,
        ).withValues(alpha: 0.94),
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: borderColor.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: borderColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: borderColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(
              0xFF0D131A,
            ).withValues(alpha: 0.94),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESTINATION CARD
  // ============================================================

  Widget _buildDestinationCard() {
    return Positioned(
      top: 80,
      left: 14,
      right: 14,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: _openDestinationScreen,
          child: Container(
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(
                0xFF0D131A,
              ).withValues(alpha: 0.96),
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white
                    .withValues(alpha: 0.07),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 25,
                  color: Colors.black
                      .withValues(alpha: 0.25),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          const BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Color(0xFF35E58A),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white
                          .withValues(alpha: 0.15),
                    ),
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          const BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fromPlace?.name ??
                            'Current location',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white
                              .withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        _toPlace?.name ??
                            'Where to?',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                          color: _toPlace == null
                              ? Colors.white
                                  .withValues(
                                  alpha: 0.75,
                                )
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ROUTE INFO
  // ============================================================

  Widget _buildRouteInfo() {
    if (_routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        10,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF0D131A,
        ).withValues(alpha: 0.96),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFF00E5FF,
          ).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _routeStat(
              'DISTANCE',
              _formatDistance(
                _routeDistance,
              ),
            ),
          ),

          Expanded(
            child: _routeStat(
              'ETA',
              _formatDuration(
                _routeDuration,
              ),
            ),
          ),

          Expanded(
            child: _routeStat(
              'SPEED',
              _formatSpeed(
                _navigationState.speedMps,
              ),
            ),
          ),

          Expanded(
            child: _routeStat(
              'MODE',
              _navigationState.modeLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeStat(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 0.8,
            color: Colors.white
                .withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons() {
    final navigationMode =
        _navigationState.mode;

    final bool isDeadReckoning =
        navigationMode ==
            nav.NavigationMode.deadReckoning;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: Icon(
                isDeadReckoning
                    ? Icons.psychology
                    : Icons.gps_fixed,
                size: 18,
              ),
              label: Text(
                isDeadReckoning
                    ? 'AI-DR ACTIVE'
                    : navigationMode ==
                            nav.NavigationMode.gps
                        ? 'GPS ACTIVE'
                        : 'INITIALIZING',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    isDeadReckoning
                        ? const Color(
                            0xFFB999FF,
                          )
                        : const Color(
                            0xFF35E58A,
                          ),
                disabledForegroundColor:
                    isDeadReckoning
                        ? const Color(
                            0xFFB999FF,
                          )
                        : const Color(
                            0xFF35E58A,
                          ),
                side: BorderSide(
                  color: isDeadReckoning
                      ? const Color(
                          0xFF8A5CFF,
                        ).withValues(
                          alpha: 0.6,
                        )
                      : const Color(
                          0xFF35E58A,
                        ).withValues(
                          alpha: 0.35,
                        ),
                ),
                minimumSize:
                    const Size(
                  0,
                  52,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _routePoints.isNotEmpty
                      ? (_journeyStarted
                          ? _stopJourney
                          : _startJourney)
                      : _openDestinationScreen,
              icon: Icon(
                _routePoints.isNotEmpty
                    ? (_journeyStarted
                        ? Icons.stop_circle
                        : Icons.navigation_rounded)
                    : Icons.route,
                size: 18,
              ),
              label: Text(
                _routePoints.isNotEmpty
                    ? (_journeyStarted
                        ? 'STOP JOURNEY'
                        : 'START JOURNEY')
                    : 'PLAN ROUTE',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _journeyStarted
                        ? Colors.redAccent
                        : const Color(
                            0xFF00E5FF,
                          ),
                foregroundColor:
                    Colors.black,
                minimumSize:
                    const Size(
                  0,
                  52,
                ),
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                textStyle:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    LatLng initialCenter;

    final navigationReady =
        _navigationState.initialized &&
        _navigationState.latitude.isFinite &&
        _navigationState.longitude.isFinite &&
        !(_navigationState.latitude == 0 &&
            _navigationState.longitude == 0);

    if (_fromPlace != null) {
      initialCenter =
          _fromPlace!.latLng;
    } else if (navigationReady) {
      initialCenter = LatLng(
        _navigationState.latitude,
        _navigationState.longitude,
      );
    } else {
      initialCenter = const LatLng(
        17.3850,
        78.4867,
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions:
            const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.example.drift',
        ),

        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 7,
                color: const Color(
                  0xFF00E5FF,
                ).withValues(
                  alpha: 0.18,
                ),
              ),
              Polyline(
                points: _routePoints,
                strokeWidth: 4,
                color: const Color(
                  0xFF00E5FF,
                ),
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            if (_fromPlace != null)
              Marker(
                point:
                    _fromPlace!.latLng,
                width: 38,
                height: 38,
                child: Container(
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color:
                        const Color(
                      0xFF35E58A,
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.trip_origin,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),

            if (_toPlace != null)
              Marker(
                point:
                    _toPlace!.latLng,
                width: 42,
                height: 42,
                child: Container(
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color:
                        const Color(
                      0xFF00E5FF,
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 22,
                    color: Colors.black,
                  ),
                ),
              ),

            if (navigationReady)
              Marker(
                point: LatLng(
                  _navigationState.latitude,
                  _navigationState.longitude,
                ),
                width: 50,
                height: 50,
                child: Transform.rotate(
                  angle:
                      _navigationState.headingDeg *
                      math.pi /
                      180,
                  child: Container(
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color:
                          const Color(
                        0xFF00E5FF,
                      ).withValues(
                        alpha: 0.16,
                      ),
                    ),
                    child:
                        const Center(
                      child: Icon(
                        Icons
                            .navigation_rounded,
                        color:
                            Color(
                          0xFF00E5FF,
                        ),
                        size: 27,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF080B10),
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMap(),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 210,
            child: IgnorePointer(
              child: Container(
                decoration:
                    const BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Color(0xD9080B10),
                      Color(0x00080B10),
                    ],
                  ),
                ),
              ),
            ),
          ),

          _buildTopBar(),

          if (!_journeyStarted)
            _buildDestinationCard(),

          if (_loadingRoute)
            Positioned(
              top: 165,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF0D131A,
                    ).withValues(
                      alpha: 0.95,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Color(
                            0xFF00E5FF,
                          ),
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Calculating route...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  _buildRouteInfo(),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
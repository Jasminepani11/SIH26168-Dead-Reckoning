import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/place_result.dart';
import '../../models/route_request.dart';
import '../../services/location_service.dart';
import '../../services/place_search_service.dart';
import '../../services/place_storage_service.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final PlaceSearchService _searchService = PlaceSearchService();
  final PlaceStorageService _storageService = PlaceStorageService();
  final LocationService _locationService = LocationService();

  final TextEditingController _toController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();

  List<PlaceResult> _searchResults = [];
  List<PlaceResult> _recentPlaces = [];
  List<PlaceResult> _savedPlaces = [];

  PlaceResult? _fromPlace;
  PlaceResult? _toPlace;

  bool _loadingLocation = true;
  bool _searching = false;
  bool _editingFrom = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPlaces();
    await _setCurrentLocation();
  }

  Future<void> _loadPlaces() async {
    _recentPlaces = await _storageService.getRecentPlaces();
    _savedPlaces = await _storageService.getSavedPlaces();

    if (mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------------------
  // DEFAULT FROM = CURRENT LOCATION
  // ------------------------------------------------------------

  Future<void> _setCurrentLocation() async {
    try {
      final Position position =
          await _locationService.getCurrentPosition();

      final place = PlaceResult(
        name: 'Current Location',
        displayName:
            'Current Location (${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)})',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        setState(() {
          _fromPlace = place;
          _fromController.text = place.displayName;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location'),
          ),
        );
      }
    }
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      final results = await _searchService.search(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searching = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // SELECT LOCATION
  // ------------------------------------------------------------

  void _selectPlace(PlaceResult place) {
    if (_editingFrom) {
      // User is changing FROM
      setState(() {
        _fromPlace = place;
        _fromController.text = place.displayName;
        _editingFrom = false;
        _searchResults = [];
      });
    } else {
      // User is selecting TO
      setState(() {
        _toPlace = place;
        _toController.text = place.displayName;
        _searchResults = [];
      });
    }
  }

  // ------------------------------------------------------------
  // START NAVIGATION
  // ------------------------------------------------------------

  Future<void> _startNavigation() async {
    if (_fromPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a starting location'),
        ),
      );
      return;
    }

    if (_toPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a destination'),
        ),
      );
      return;
    }

    await _storageService.addRecentPlace(_toPlace!);

    if (!mounted) return;

    Navigator.pop(
      context,
      RouteRequest(
        from: _fromPlace!,
        to: _toPlace!,
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        title: const Text('Plan Route'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFromCard(),
                  const SizedBox(height: 12),
                  _buildToCard(),
                  const SizedBox(height: 20),

                  if (_searching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  if (_searchResults.isNotEmpty)
                    _buildSearchResults(),

                  if (_searchResults.isEmpty &&
                      !_searching &&
                      !_editingFrom)
                    _buildRecentAndSaved(),
                ],
              ),
            ),

            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FROM
  // ------------------------------------------------------------

  Widget _buildFromCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF35E58A).withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.my_location,
                color: Color(0xFF35E58A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'FROM',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_editingFrom)
            TextField(
              controller: _fromController,
              autofocus: true,
              onChanged: _search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search starting location',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white54,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      _editingFrom = false;
                      _searchResults = [];
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFF080B10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF35E58A),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: _loadingLocation
                      ? const Text(
                          'Getting current location...',
                          style: TextStyle(
                            color: Colors.white54,
                          ),
                        )
                      : Text(
                          _fromPlace?.displayName ??
                              'Current Location',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      _editingFrom = true;
                      _fromController.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.edit,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TO
  // ------------------------------------------------------------

  Widget _buildToCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.flag,
                color: Color(0xFF00E5FF),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'TO',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _toController,
            onChanged: _search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Choose a destination',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white54,
              ),
              suffixIcon: _toController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        _toController.clear();

                        setState(() {
                          _toPlace = null;
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF080B10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SEARCH RESULTS
  // ------------------------------------------------------------

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEARCH RESULTS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        ..._searchResults.map(
          (place) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF18232B),
              child: Icon(
                Icons.location_on,
                color: Color(0xFF00E5FF),
              ),
            ),
            title: Text(
              place.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              place.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
            onTap: () => _selectPlace(place),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // RECENT / SAVED
  // ------------------------------------------------------------

  Widget _buildRecentAndSaved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentPlaces.isNotEmpty) ...[
          const Text(
            'RECENT',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          ..._recentPlaces.map(
            (place) => _buildPlaceTile(place),
          ),

          const SizedBox(height: 20),
        ],

        if (_savedPlaces.isNotEmpty) ...[
          const Text(
            'SAVED',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          ..._savedPlaces.map(
            (place) => _buildPlaceTile(place),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceTile(PlaceResult place) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(
        Icons.history,
        color: Colors.white54,
      ),
      title: Text(
        place.name,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        place.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white38),
      ),
      onTap: () => _selectPlace(place),
    );
  }

  // ------------------------------------------------------------
  // START BUTTON
  // ------------------------------------------------------------

  Widget _buildStartButton() {
    final ready = _fromPlace != null && _toPlace != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: ready ? _startNavigation : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF1B242B),
            disabledForegroundColor: Colors.white30,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'START NAVIGATION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _toController.dispose();
    _fromController.dispose();
    _locationService.dispose();
    super.dispose();
  }
}
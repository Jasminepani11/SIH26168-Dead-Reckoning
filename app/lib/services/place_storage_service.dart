import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/place_result.dart';

class PlaceStorageService {
  static const String _savedKey = 'saved_places';
  static const String _recentKey = 'recent_places';

  Future<List<PlaceResult>> getSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();

    final values = prefs.getStringList(_savedKey) ?? [];

    return values
        .map(
          (value) => PlaceResult.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<PlaceResult>> getRecentPlaces() async {
    final prefs = await SharedPreferences.getInstance();

    final values = prefs.getStringList(_recentKey) ?? [];

    return values
        .map(
          (value) => PlaceResult.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> savePlace(PlaceResult place) async {
    final prefs = await SharedPreferences.getInstance();

    final places = await getSavedPlaces();

    places.removeWhere(
      (item) =>
          item.latitude == place.latitude &&
          item.longitude == place.longitude,
    );

    places.insert(0, place);

    await prefs.setStringList(
      _savedKey,
      places
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }

  Future<void> removeSavedPlace(PlaceResult place) async {
    final prefs = await SharedPreferences.getInstance();

    final places = await getSavedPlaces();

    places.removeWhere(
      (item) =>
          item.latitude == place.latitude &&
          item.longitude == place.longitude,
    );

    await prefs.setStringList(
      _savedKey,
      places
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }

  Future<void> addRecentPlace(PlaceResult place) async {
    final prefs = await SharedPreferences.getInstance();

    final places = await getRecentPlaces();

    places.removeWhere(
      (item) =>
          item.latitude == place.latitude &&
          item.longitude == place.longitude,
    );

    places.insert(0, place);

    // Keep only the latest 10.
    final limited = places.take(10).toList();

    await prefs.setStringList(
      _recentKey,
      limited
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }
}
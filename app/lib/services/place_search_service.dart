import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_result.dart';

class PlaceSearchService {
  static const String _baseUrl =
      'https://nominatim.openstreetmap.org/search';

  Future<List<PlaceResult>> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return [];
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'q': trimmed,
        'format': 'jsonv2',
        'limit': '8',
        'countrycodes': 'in',
        'addressdetails': '1',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'NAVIAI/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Place search failed: ${response.statusCode}',
      );
    }

    final List<dynamic> data =
        jsonDecode(response.body) as List<dynamic>;

    return data.map((item) {
      final map = item as Map<String, dynamic>;

      final displayName =
          map['display_name'] as String? ?? 'Unknown place';

      final rawName = map['name'] as String?;

      final name = rawName != null && rawName.isNotEmpty
          ? rawName
          : displayName.split(',').first.trim();

      return PlaceResult(
        name: name,
        displayName: displayName,
        latitude: double.parse(map['lat'] as String),
        longitude: double.parse(map['lon'] as String),
      );
    }).toList();
  }
}
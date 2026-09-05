import 'package:latlong2/latlong.dart';

class PlaceResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;

  const PlaceResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
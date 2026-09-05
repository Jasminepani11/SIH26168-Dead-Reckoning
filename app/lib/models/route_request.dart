import 'place_result.dart';

class RouteRequest {
  final PlaceResult from;
  final PlaceResult to;

  const RouteRequest({
    required this.from,
    required this.to,
  });
}
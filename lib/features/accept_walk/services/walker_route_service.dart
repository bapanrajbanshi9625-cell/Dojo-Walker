import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WalkerRouteService {
  WalkerRouteService._();

  static final WalkerRouteService instance =
      WalkerRouteService._();

  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  static const Duration _timeout =
      Duration(seconds: 12);

  Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final String coordinates =
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}';

    final Uri uri = Uri.parse(
      '$_baseUrl/$coordinates'
      '?overview=full'
      '&geometries=geojson'
      '&steps=false',
    );

    try {
      final http.Response response =
          await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Route service returned ${response.statusCode}.',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid route response.',
        );
      }

      final String code =
          decoded['code']?.toString() ?? '';

      if (code != 'Ok') {
        throw Exception(
          'Road route is unavailable.',
        );
      }

      final dynamic routes =
          decoded['routes'];

      if (routes is! List ||
          routes.isEmpty) {
        throw Exception(
          'No road route found.',
        );
      }

      final dynamic firstRoute =
          routes.first;

      if (firstRoute is! Map) {
        throw Exception(
          'Invalid route data.',
        );
      }

      final dynamic geometry =
          firstRoute['geometry'];

      if (geometry is! Map) {
        throw Exception(
          'Route geometry is unavailable.',
        );
      }

      final dynamic coordinatesData =
          geometry['coordinates'];

      if (coordinatesData is! List ||
          coordinatesData.isEmpty) {
        throw Exception(
          'Route coordinates are unavailable.',
        );
      }

      final List<LatLng> points =
          <LatLng>[];

      for (final dynamic item
          in coordinatesData) {
        if (item is! List ||
            item.length < 2) {
          continue;
        }

        final double? longitude =
            _toDouble(item[0]);

        final double? latitude =
            _toDouble(item[1]);

        if (latitude == null ||
            longitude == null) {
          continue;
        }

        if (latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        points.add(
          LatLng(
            latitude,
            longitude,
          ),
        );
      }

      if (points.length < 2) {
        throw Exception(
          'Road route contains insufficient points.',
        );
      }

      return points;
    } catch (error) {
      debugPrint(
        'Walker route service error: $error',
      );

      throw Exception(
        'Unable to load road route.',
      );
    }
  }

  double? _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }
}

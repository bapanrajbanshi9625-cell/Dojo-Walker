import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

class LiveWalkRoutingService {
  LiveWalkRoutingService._();

  static final LiveWalkRoutingService instance =
      LiveWalkRoutingService._();

  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/foot';

  final HttpClient _client = HttpClient();

  Future<List<LatLng>> getRoadRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    if (!_valid(start) || !_valid(end)) {
      return <LatLng>[];
    }

    final double distance = const Distance().as(
      LengthUnit.Meter,
      start,
      end,
    );

    // Very small movements do not need a routing request.
    if (distance < 8) {
      return <LatLng>[start, end];
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/'
      '${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson&steps=false',
    );

    try {
      final HttpClientRequest request =
          await _client.getUrl(uri);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final HttpClientResponse response =
          await request.close();

      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return <LatLng>[];
      }

      final String body =
          await response.transform(utf8.decoder).join();

      final dynamic decoded =
          jsonDecode(body);

      if (decoded is! Map) {
        return <LatLng>[];
      }

      if (decoded['code']?.toString() != 'Ok') {
        return <LatLng>[];
      }

      final dynamic routes =
          decoded['routes'];

      if (routes is! List ||
          routes.isEmpty ||
          routes.first is! Map) {
        return <LatLng>[];
      }

      final dynamic geometry =
          routes.first['geometry'];

      if (geometry is! Map) {
        return <LatLng>[];
      }

      final dynamic coordinates =
          geometry['coordinates'];

      if (coordinates is! List) {
        return <LatLng>[];
      }

      final List<LatLng> result =
          <LatLng>[];

      for (final dynamic item in coordinates) {
        if (item is! List || item.length < 2) {
          continue;
        }

        final double? longitude =
            _toDouble(item[0]);

        final double? latitude =
            _toDouble(item[1]);

        if (latitude == null ||
            longitude == null ||
            !_validCoordinate(
              latitude,
              longitude,
            )) {
          continue;
        }

        result.add(
          LatLng(
            latitude,
            longitude,
          ),
        );
      }

      return result;
    } catch (_) {
      return <LatLng>[];
    }
  }

  Future<List<LatLng>> getRoadRouteThroughPoints({
    required List<LatLng> points,
  }) async {
    if (points.length < 2) {
      return List<LatLng>.from(points);
    }

    final List<LatLng> result =
        <LatLng>[];

    for (int index = 0;
        index < points.length - 1;
        index++) {
      final LatLng start = points[index];
      final LatLng end = points[index + 1];

      final List<LatLng> segment =
          await getRoadRoute(
        start: start,
        end: end,
      );

      if (segment.isEmpty) {
        _appendUnique(
          result,
          start,
        );
        _appendUnique(
          result,
          end,
        );
        continue;
      }

      for (final LatLng point in segment) {
        _appendUnique(
          result,
          point,
        );
      }
    }

    return result;
  }

  void _appendUnique(
    List<LatLng> points,
    LatLng point,
  ) {
    if (points.isEmpty) {
      points.add(point);
      return;
    }

    final LatLng last = points.last;

    final double distance =
        const Distance().as(
      LengthUnit.Meter,
      last,
      point,
    );

    if (distance >= 2) {
      points.add(point);
    }
  }

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  bool _valid(
    LatLng point,
  ) {
    return _validCoordinate(
      point.latitude,
      point.longitude,
    );
  }

  bool _validCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  void dispose() {
    _client.close(
      force: true,
    );
  }
}

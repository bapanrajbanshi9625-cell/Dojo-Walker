import 'package:flutter/material.dart';

import 'live_walk_map.dart';

class LiveWalkMapLayer extends StatelessWidget {
  const LiveWalkMapLayer({
    super.key,
    required this.sessionData,
    required this.gpsReady,
  });

  final Map<String, dynamic> sessionData;
  final bool gpsReady;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LiveWalkMap(
        sessionData: sessionData,
      ),
    );
  }
}

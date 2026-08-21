// File location: lib/screens/active_walk_details_screen.dart

import 'package:flutter/material.dart';

import '../features/walks/models/walk_request.dart';
import '../features/walks/screens/live_walk_screen.dart';

class ActiveWalkDetailsScreen extends StatefulWidget {
  final WalkRequest request;

  const ActiveWalkDetailsScreen({
    super.key,
    required this.request,
  });

  @override
  State<ActiveWalkDetailsScreen> createState() =>
      _ActiveWalkDetailsScreenState();
}

class _ActiveWalkDetailsScreenState
    extends State<ActiveWalkDetailsScreen> {
  static const Color dark = Color(0xFF263746);
  static const Color blue = Color(0xFF238EAE);
  static const Color green = Color(0xFF16A34A);
  static const Color orange = Color(0xFFF4511E);
  static const Color muted = Color(0xFF7A8289);

  bool _reached = false;

  double _sheetHeight = 190;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMapArea(),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                0,
              ),
              child: Row(
                children: [
                  _topButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  _topButton(
                    icon: Icons.headset_mic_rounded,
                    onTap: _showSupport,
                  ),
                  const SizedBox(width: 8),
                  _topButton(
                    icon: Icons.more_vert_rounded,
                    onTap: _showMoreOptions,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 220,
              ),
              height: _sheetHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _sheetHeight -= details.delta.dy;

                    if (_sheetHeight < 185) {
                      _sheetHeight = 185;
                    }

                    if (_sheetHeight > 570) {
                      _sheetHeight = 570;
                    }
                  });
                },
                child: _buildBottomSheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP AREA
  // ============================================================

  Widget _buildMapArea() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEAF5F8),
            Color(0xFFDDECEF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(),
            ),
          ),

          const Positioned(
            left: 80,
            top: 300,
            child: _MapMarker(
              color: blue,
              icon: Icons.person_rounded,
              label: 'You',
            ),
          ),

          const Positioned(
            right: 65,
            top: 180,
            child: _MapMarker(
              color: orange,
              icon: Icons.home_rounded,
              label: 'Owner',
            ),
          ),

          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(),
            ),
          ),

          Positioned(
            top: 105,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bike_rounded,
                    color: blue,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.dogName,
                        style: const TextStyle(
                          color: dark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.request.estimatedTime,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet() {
    return Column(
      children: [
        const SizedBox(height: 9),

        const SizedBox(
          width: 42,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFD0D5D8),
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
          ),
        ),

        const SizedBox(height: 13),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: green,
                  size: 25,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.dogName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.request.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _reached
                      ? const Color(0xFFEAF7EF)
                      : const Color(0xFFFFF3E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _reached ? 'REACHED' : 'ON THE WAY',
                  style: TextStyle(
                    color: _reached ? green : orange,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_sheetHeight > 280)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                15,
                18,
                10,
              ),
              child: Column(
                children: [
                  _section(
                    title: 'OWNER DETAILS',
                    icon: Icons.person_rounded,
                    children: [
                      _detail(
                        'Owner',
                        widget.request.ownerName,
                        Icons.person_outline_rounded,
                      ),
                      _detail(
                        'Pickup',
                        widget.request.pickupAddress,
                        Icons.location_on_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _section(
                    title: 'DOG DETAILS',
                    icon: Icons.pets_rounded,
                    children: [
                      _detail(
                        'Dog Name',
                        widget.request.dogName,
                        Icons.pets_outlined,
                      ),
                      if (widget.request.dogBreed.isNotEmpty)
                        _detail(
                          'Breed',
                          widget.request.dogBreed,
                          Icons.category_outlined,
                        ),
                      if (widget.request.dogAge.isNotEmpty)
                        _detail(
                          'Age',
                          widget.request.dogAge,
                          Icons.cake_outlined,
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _section(
                    title: 'WALK DETAILS',
                    icon: Icons.route_rounded,
                    children: [
                      _detail(
                        'Walk ID',
                        _walkId(),
                        Icons.tag_rounded,
                      ),
                      _detail(
                        'Distance',
                        '${widget.request.distanceKm.toStringAsFixed(1)} km',
                        Icons.straighten_rounded,
                      ),
                      _detail(
                        'Estimated Time',
                        widget.request.estimatedTime,
                        Icons.access_time_rounded,
                      ),
                      _detail(
                        'Walk Type',
                        widget.request.walkType,
                        Icons.directions_walk_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _reached
                          ? _startWalk
                          : _simulateReach,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _reached ? green : blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            _reached
                                ? Icons.play_arrow_rounded
                                : Icons.location_on_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _reached
                                ? 'START WALK'
                                : 'REACH',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // REACH
  // ============================================================

  void _simulateReach() {
    setState(() {
      _reached = true;
      _sheetHeight = 430;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Owner location reached. You can start the walk.',
          ),
          backgroundColor: green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // START WALK
  // ============================================================

  void _startWalk() {
    final String ownerUid = _ownerUid();
    final String walkId = _walkId();

    if (ownerUid.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Owner information is missing.',
            ),
          ),
        );
      return;
    }

    if (walkId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walk ID is missing.',
            ),
          ),
        );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          ownerUid: ownerUid,
          ownerName: widget.request.ownerName,
          walkId: walkId,
          dogName: widget.request.dogName,
          ownerPhone: null,
        ),
      ),
    );
  }

  // ============================================================
  // WALK ID
  // ============================================================

  String _walkId() {
    final String value = widget.request.id.trim();

    if (value.isNotEmpty) {
      return value;
    }

    return '';
  }

  // ============================================================
  // OWNER UID
  // ============================================================

  String _ownerUid() {
    final String ownerId =
        widget.request.ownerId.trim();

    if (ownerId.isNotEmpty) {
      return ownerId;
    }

    return '';
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE4EBE7),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: blue,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: dark,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detail(
    String title,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: muted,
            size: 17,
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: dark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BUTTON
  // ============================================================

  Widget _topButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: dark,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  void _showSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.headset_mic_rounded,
                  color: blue,
                  size: 34,
                ),
                SizedBox(height: 10),
                Text(
                  'Walk Support',
                  style: TextStyle(
                    color: dark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Need help with this walk?',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: blue,
                ),
                title: const Text(
                  'Walk Information',
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Close',
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================================================================
// MAP MARKER
// ==================================================================

class _MapMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _MapMarker({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// MAP BACKGROUND
// ==================================================================

class _MapPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint road = Paint()
      ..color = Colors.white.withOpacity(.65)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final Paint road2 = Paint()
      ..color = Colors.white.withOpacity(.45)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final Path path1 = Path()
      ..moveTo(0, size.height * .30)
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .18,
        size.width,
        size.height * .38,
      );

    final Path path2 = Path()
      ..moveTo(size.width * .10, size.height)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .65,
        size.width * .90,
        0,
      );

    canvas.drawPath(path1, road);
    canvas.drawPath(path2, road2);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ==================================================================
// ROUTE POLYLINE
// ==================================================================

class _RoutePainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint route = Paint()
      ..color = const Color(0xFF238EAE)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(
        size.width * .18,
        size.height * .57,
      )
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .50,
        size.width * .57,
        size.height * .40,
      )
      ..quadraticBezierTo(
        size.width * .70,
        size.height * .31,
        size.width * .84,
        size.height * .22,
      );

    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

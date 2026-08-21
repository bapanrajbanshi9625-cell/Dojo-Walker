import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveWalkSosSheet extends StatelessWidget {
  const LiveWalkSosSheet({super.key});

  static const Color red =
      Color(0xFFE53935);

  static const Color dark =
      Color(0xFF263746);

  Future<void> _dial(
    BuildContext context,
    String number,
  ) async {
    final Uri uri =
        Uri.parse('tel:$number');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open phone dialer.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          22,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(27),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFD5DADD),
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 17),

            const Icon(
              Icons.sos_rounded,
              color: red,
              size: 42,
            ),

            const SizedBox(height: 7),

            const Text(
              'Emergency Assistance',
              style: TextStyle(
                color: dark,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Choose an emergency service',
              style: TextStyle(
                color: Color(0xFF7A8289),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 17),

            _emergencyButton(
              context,
              icon: Icons.local_police_rounded,
              title: 'Police',
              subtitle: 'Emergency police assistance',
              number: '112',
            ),

            const SizedBox(height: 9),

            _emergencyButton(
              context,
              icon: Icons.local_hospital_rounded,
              title: 'Ambulance',
              subtitle: 'Medical emergency',
              number: '112',
            ),

            const SizedBox(height: 9),

            _emergencyButton(
              context,
              icon: Icons.local_fire_department_rounded,
              title: 'Fire Brigade',
              subtitle: 'Fire emergency',
              number: '112',
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: dark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String number,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFFFFF5F5),
        borderRadius:
            BorderRadius.circular(15),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(15),
          onTap: () => _dial(
            context,
            number,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration:
                      const BoxDecoration(
                    color: red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color: dark,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF7A8289),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.call_rounded,
                  color: red,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

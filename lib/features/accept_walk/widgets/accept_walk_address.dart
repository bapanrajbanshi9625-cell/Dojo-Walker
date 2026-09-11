import 'package:flutter/material.dart';

class AcceptWalkAddress extends StatelessWidget {
  const AcceptWalkAddress({
    super.key,
    required this.address,
  });

  final String address;

  @override
  Widget build(BuildContext context) {
    final fields = _parseAddress(address);

    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 7),
          ...fields.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: '${entry.key}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: entry.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _parseAddress(String raw) {
    final result = <String, String>{};

    final text = raw.trim();

    if (text.isEmpty) {
      return result;
    }

    final lines = text
        .split(RegExp(r'[\n,|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    const labels = <String, String>{
      'flat number': 'Flat Number',
      'flat': 'Flat Number',
      'flat no': 'Flat Number',
      'flat no.': 'Flat Number',
      'building': 'Building / Society',
      'building / society': 'Building / Society',
      'building/society': 'Building / Society',
      'society': 'Building / Society',
      'street': 'Street',
      'city': 'City',
      'state': 'State',
    };

    for (final line in lines) {
      final separatorIndex = line.indexOf(':');

      if (separatorIndex <= 0) {
        continue;
      }

      final rawKey = line.substring(0, separatorIndex).trim().toLowerCase();
      final value = line.substring(separatorIndex + 1).trim();

      if (value.isEmpty) {
        continue;
      }

      final label = labels[rawKey];

      if (label != null) {
        result[label] = value;
      }
    }

    if (result.isEmpty) {
      result['Location'] = text;
    }

    return result;
  }
}

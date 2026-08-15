import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Walks',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(
              Icons.pets,
              color: AppColors.primary,
            ),
            title: Text(
              'Walk Session #${index + 1}',
            ),
            subtitle: const Text(
              'Duration: 45 mins • 3.2 km',
            ),
          ),
        ),
      ),
    );
  }
}

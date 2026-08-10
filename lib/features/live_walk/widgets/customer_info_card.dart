import 'package:flutter/material.dart';

class CustomerInfoCard extends StatelessWidget {
  const CustomerInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              SizedBox(width: 12),
              Text("Rahul Sharma", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showConfirmation(context, "Call Rahul?"),
                icon: const Icon(Icons.call, color: Colors.green, size: 26),
              ),
              IconButton(
                onPressed: () => _showConfirmation(context, "Send SMS?"),
                icon: const Icon(Icons.message, color: Colors.blue, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmation(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Action"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Confirm")),
        ],
      ),
    );
  }
}

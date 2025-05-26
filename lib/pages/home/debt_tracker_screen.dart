import 'package:flutter/material.dart';

class DebtTrackerScreen extends StatelessWidget {
  const DebtTrackerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Debt Tracker',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature will be available soon',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

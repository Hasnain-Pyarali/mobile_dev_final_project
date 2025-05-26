import 'package:flutter/material.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Savings',
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

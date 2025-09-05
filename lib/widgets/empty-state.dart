import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "✨ No tasks yet.\nTap + to create your first to-do!",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}

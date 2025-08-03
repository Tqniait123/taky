import 'package:flutter/material.dart';

class EmployeeLayout extends StatelessWidget {
  const EmployeeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Layout')),
      body: const Center(child: Text('Employee Layout Page', style: TextStyle(fontSize: 24))),
    );
  }
}

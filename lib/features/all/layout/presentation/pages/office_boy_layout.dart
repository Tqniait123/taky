import 'package:flutter/material.dart';

class OfficeBoyLayout extends StatelessWidget {
  const OfficeBoyLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OfficeBoyLayout Layout')),
      body: const Center(child: Text('OfficeBoyLayout Layout Page', style: TextStyle(fontSize: 24))),
    );
  }
}

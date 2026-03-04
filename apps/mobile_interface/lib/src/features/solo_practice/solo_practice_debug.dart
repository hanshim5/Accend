import 'package:flutter/material.dart';

import 'pages/solo_practice_page.dart';

void main() {
  runApp(const SoloPracticeDebugApp());
}

class SoloPracticeDebugApp extends StatelessWidget {
  const SoloPracticeDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solo Practice Debug',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SoloPracticePage(),
    );
  }
}


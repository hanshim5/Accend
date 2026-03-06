import 'package:flutter/material.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Social")),
      body: const Center(
        child: Text("This is the social page!"),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/constants.dart';

import 'social.dart';

class SocialDebugPage extends StatelessWidget {
  const SocialDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Debug'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Run the in-progress followers/following UI in isolation.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SocialPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent2,
                      foregroundColor: AppColors.primaryBg,
                    ),
                    child: const Text('Go to Social (Debug)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
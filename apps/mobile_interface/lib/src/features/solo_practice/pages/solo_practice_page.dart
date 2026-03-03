import 'package:flutter/material.dart';

class SoloPracticePage extends StatelessWidget {
  const SoloPracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section: back button above centered progress/info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: const [
                            Text('1/20'),
                            Spacer(),
                            Text('Lesson Title'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(
                          value: 0.0, // placeholder for now
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Middle section: prompt box and text to repeat
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    // Placeholder for prompt box
                    SizedBox(
                      height: 120,
                      width: 280,
                      child: Card(
                        child: Center(
                          child: Text('Prompt box goes here'),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('This is the sentence the user will repeat out loud.'),
                  ],
                ),
              ),
            ),
            // Bottom section: controls (microphone button for now)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // TODO: handle microphone press
                      },
                      icon: const Icon(Icons.mic),
                      iconSize: 56,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

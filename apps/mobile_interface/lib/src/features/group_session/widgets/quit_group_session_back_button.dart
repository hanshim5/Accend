import 'package:flutter/material.dart';
import '../../../app/routes.dart' as routes;
import 'quit_group_session_dialog.dart';

class QuitGroupSessionBackButton extends StatelessWidget {
  const QuitGroupSessionBackButton({super.key});

  Future<void> _onPressed(BuildContext context) async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const QuitGroupSessionDialog(),
    );

    if (shouldQuit == true && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        routes.AppRoutes.groupSessionSelect,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _onPressed(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
    );
  }
}
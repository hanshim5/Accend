import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
import 'package:mobile_interface/src/features/group_session/controllers/group_session_controller.dart';


class QuitGroupSessionDialog extends StatelessWidget {
  const QuitGroupSessionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupSessionController>();
    final t = Theme.of(context);


    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Quit Group Session?',
        style: t.textTheme.titleLarge,
      ),
      content: Text(
        'Are you sure you want to quit? You will return to the group session menu.',
        style: t.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);

            ctrl.leaveLobby();
          },
          child: const Text('Quit'),
        ),
      ],
    );
  }
}
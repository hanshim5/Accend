import 'package:flutter/material.dart';
import '../../../app/constants.dart';

class PrivateCodeDisplay extends StatelessWidget {
  final String code;

  const PrivateCodeDisplay({
  super.key,
  required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: 300,
      color: AppColors.surface,
      child: Center(
        child: Text(
          code,
          style: TextStyle(fontSize: 30),
        )
      )
    );
  }
}
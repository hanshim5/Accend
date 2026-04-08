import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/constants.dart';

class HomeTopBar extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isNetworkImage;

  const HomeTopBar({
    super.key,
    required this.name,
    required this.imagePath,
    this.isNetworkImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: const BoxDecoration(
        color: AppColors.primaryBg,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E2A44), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Left text
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Welcome back,\n',
                    style: TextStyle(
                      color: Color(0xFF98A2B3),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Profile image with glow
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.6),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00D9FF),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10233F),
                ),
                child: ClipOval(
                  child: (isNetworkImage && imagePath.trim().isNotEmpty)
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/profile.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          imagePath.trim().isNotEmpty ? imagePath : 'assets/images/profile.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

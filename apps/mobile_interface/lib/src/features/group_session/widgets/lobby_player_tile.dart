import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants.dart';
import '../models/private_lobby.dart';

class LobbyPlayerTile extends StatelessWidget {
  const LobbyPlayerTile({
    super.key,
    required this.player,
    required this.isMe,
    required this.isHost,
    this.profileImageUrl,
    this.reputation = 0,
  });

  final PrivateLobby player;
  final bool isMe;
  final bool isHost;
  final String? profileImageUrl;
  final int reputation;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isMe ? AppColors.accent : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          _Avatar(
            username: player.username,
            profileImageUrl: profileImageUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.username,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isHost || isMe)
                  const SizedBox(height: 4),
                if (isHost || isMe)
                  Row(
                    children: [
                      if (isHost)
                        _Chip(
                          label: 'Host',
                          color: AppColors.action,
                        ),
                      if (isHost && isMe)
                        const SizedBox(width: 6),
                      if (isMe)
                        _Chip(
                          label: 'You',
                          color: AppColors.accent,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ReputationChip(reputation: reputation),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, this.profileImageUrl});

  final String username;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final url = profileImageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialAvatar(username: username),
        ),
      );
    }
    return _InitialAvatar(username: username);
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final initial =
        username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputFill,
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.montserrat(
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ReputationChip extends StatelessWidget {
  const _ReputationChip({required this.reputation});

  final int reputation;

  @override
  Widget build(BuildContext context) {
    final isPositive = reputation >= 0;
    const positiveColor = Color(0xFF22C55E);
    const negativeColor = Color(0xFFEF4444);
    final color = isPositive ? positiveColor : negativeColor;
    final label = isPositive ? '+$reputation' : '$reputation';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

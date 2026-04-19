import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import 'package:provider/provider.dart';

import '../controllers/social_controller.dart';
import '../models/social_user.dart';

class SearchPopup extends StatefulWidget {
  const SearchPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close search popup',
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) {
        return const SearchPopup();
      },
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SearchPopup> createState() => _SearchPopupState();
}

class _SearchPopupState extends State<SearchPopup> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<SocialUser> _results = const [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 280), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    final accessToken = context.read<AuthService>().accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      setState(() {
        _error = 'You must be logged in to search users.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await context.read<ApiClient>().getList(
        '/social/search',
        query: {
          'q': query,
          'limit': '20',
        },
        accessToken: accessToken,
      );

      if (!mounted || _controller.text.trim() != query) return;

      final users = list
          .map((e) => SocialUser.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);

      setState(() {
        _results = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _error = 'Search failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(SocialUser user) async {
    try {
      final social = context.read<SocialController>();
      if (user.iFollow) {
        await social.unfollow(user.id);
      } else {
        await social.follow(user.id);
      }

      final currentQuery = _controller.text.trim();
      if (currentQuery.isEmpty || !mounted) return;
      await _searchUsers(currentQuery);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not update follow state.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screen = MediaQuery.sizeOf(context);
    final maxPopupHeight = (screen.height - viewInsets.vertical - 48).clamp(240.0, screen.height);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: const Color(0x8A0B1220)),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 340,
                minWidth: 280,
                maxHeight: maxPopupHeight,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x7F334155)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 50,
                      offset: Offset(0, 25),
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Find User',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => Navigator.of(context).pop(),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _controller,
                        autofocus: false,
                        onChanged: _onQueryChanged,
                        onSubmitted: (value) => _searchUsers(value.trim()),
                        textAlignVertical: TextAlignVertical.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF1F5F9),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by username...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFF6B17A),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xCC1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFF6B17A)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search by username to add friends.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else if (_error != null)
                        Text(
                          _error!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFCA5A5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (_controller.text.trim().isNotEmpty && _results.isEmpty)
                        Text(
                          'No users found.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (_results.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0x661E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0x1FFFFFFF)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: const Color(0xFF334155),
                                      child: Text(
                                        user.displayName.characters.first.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            user.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFFF1F5F9),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '@${user.username}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _toggleFollow(user),
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            user.iFollow ? const Color(0x001E293B) : const Color(0xFFF6B17A),
                                        foregroundColor:
                                            user.iFollow ? const Color(0xFFF1F5F9) : Colors.white,
                                        side: user.iFollow
                                            ? const BorderSide(color: Color(0xFF334155))
                                            : BorderSide.none,
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        minimumSize: const Size(88, 34),
                                      ),
                                      child: Text(
                                        user.iFollow ? 'Following' : 'Follow',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
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

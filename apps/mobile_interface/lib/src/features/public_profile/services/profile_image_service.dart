import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/constants.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';

class ProfileImageService {
  ProfileImageService({
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

  /// Pick an image, upload to Supabase Storage, then update the backend.
  /// Returns the public URL on success, or null if the user cancelled.
  Future<String?> uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (picked == null) return null;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw Exception(
        'Unsupported image type ".$ext". Please choose a JPG, PNG, or WebP image.',
      );
    }

    final bytes = await picked.readAsBytes();
    final mimeType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };

    final userId = authService.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final client = authService.client;
    final storage = client.storage.from(AppStorage.profileImagesBucket);
    final folder = 'profiles/$userId';

    // Remove any existing avatar files so only one image is stored per user.
    try {
      final existing = await storage.list(path: folder);
      final toDelete = existing
          .map((f) => '$folder/${f.name}')
          .toList();
      if (toDelete.isNotEmpty) {
        await storage.remove(toDelete);
      }
    } catch (_) {
      // Folder may not exist yet on first upload — safe to ignore.
    }

    final objectPath = AppStorage.profileImagePath(userId, ext);

    // Upload to Supabase Storage
    await storage.uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(contentType: mimeType),
    );

    // Generate public URL
    final publicUrl = storage.getPublicUrl(objectPath);

    debugPrint('Profile image uploaded: $publicUrl');

    // Update the backend with the new URL
    final accessToken = authService.accessToken;
    await apiClient.patchJson(
      '/profile/image',
      accessToken: accessToken,
      body: {'profile_image_url': publicUrl},
    );

    return publicUrl;
  }
}

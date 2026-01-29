import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // IMAGE PICKING
  // ============================================================

  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<List<File>> pickMultipleImages({int maxImages = 5, int imageQuality = 80}) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      return pickedFiles. take(maxImages).map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images:  $e');
      return [];
    }
  }

  // ============================================================
  // AVATAR UPLOAD
  // ============================================================

  Future<String? > uploadAvatar({
    required File file,
    required String odId,
  }) async {
    try {
      final extension = path.extension(file.path);
      final filePath = 'avatars/$odId$extension';

      await _supabase.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // ============================================================
  // SHOP IMAGE UPLOAD
  // ============================================================

  Future<String?> uploadShopImage({
    required File file,
    required String shopId,
    required String imageType, // 'logo', 'cover', or 'gallery'
  }) async {
    try {
      final extension = path.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'shops/$shopId/${imageType}_$timestamp$extension';

      await _supabase.storage.from('shops').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('shops').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading shop image: $e');
      return null;
    }
  }

  // ============================================================
  // ITEM IMAGE UPLOAD
  // ============================================================

  Future<String?> uploadItemImage({
    required File file,
    required String itemId,
  }) async {
    try {
      final extension = path.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'items/$itemId/$timestamp$extension';

      await _supabase.storage.from('items').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('items').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading item image: $e');
      return null;
    }
  }

  // ============================================================
  // GENERIC IMAGE UPLOAD
  // ============================================================

  Future<String?> uploadImage(File file, String folderPath) async {
    try {
      final extension = path.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'image_$timestamp$extension';
      // FIXED: Removed unused filePath variable

      // Extract bucket from folder path (first segment)
      final pathParts = folderPath.split('/');
      final bucket = pathParts.first;
      final innerPath = pathParts.length > 1 ? pathParts.sublist(1).join('/') : '';
      final fullPath = innerPath.isNotEmpty ? '$innerPath/$fileName' : fileName;

      await _supabase.storage.from(bucket).upload(
        fullPath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // ============================================================
  // DELETE IMAGE
  // ============================================================

  Future<bool> deleteImage(String bucket, String filePath) async {
    try {
      await _supabase.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // ============================================================
  // GET SIGNED URL
  // ============================================================

  Future<String?> getSignedUrl(String bucket, String filePath, {int expiresIn = 3600}) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucket)
          .createSignedUrl(filePath, expiresIn);
      return signedUrl;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }
}
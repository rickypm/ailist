import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session?  get currentSession => _supabase.auth.currentSession;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String city = 'Shillong',
    String partnerType = 'individual',
    String? groupName,
  }) async {
    try {
      final response = await _supabase. auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
          'phone': phone,
          'city':  city,
          'partner_type': partnerType,
          'group_name': groupName,
        },
      );
      return response;
    } catch (e) {
      debugPrint('SignUp Error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('SignIn Error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('SignOut Error: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      debugPrint('Update Password Error: $e');
      rethrow;
    }
  }

  /// Get user profile from database
  Future<UserModel? > getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint('Get User Profile Error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Update User Profile Error: $e');
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount(String userId) async {
    try {
      // Delete from users table (cascade will handle related data)
      await _supabase.from('users').delete().eq('id', userId);
      
      // Sign out
      await signOut();
      return true;
    } catch (e) {
      debugPrint('Delete Account Error: $e');
      return false;
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final data = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return data != null;
    } catch (e) {
      debugPrint('Email Exists Check Error: $e');
      return false;
    }
  }
}
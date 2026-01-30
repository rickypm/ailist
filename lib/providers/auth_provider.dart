import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _supabase = Supabase.instance.client;

  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isPartner => _user?.role == 'partner';
  bool get isAdmin => _user?.role == 'admin';

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((data) async {
      if (data.session?.user != null) {
        await _loadUserProfile(data.session!.user.id);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _loadUserProfile(currentUser.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String odId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getUserProfile(odId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // UPDATED: Added captchaToken parameter
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'user',
    String? phone,
    String? referralCode,
    String city = 'Shillong',
    String partnerType = 'individual',
    String? groupName,
    String? captchaToken,  // NEW
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.welist://login-callback',
        captchaToken: captchaToken,  // NEW: Pass captcha token
        data: {
          'full_name': name,
          'role': role,
          'phone': phone,
          'city': city,
          'partner_type': partnerType,
          'group_name': groupName,
          'referral_code': referralCode,
        },
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        return true;
      }

      _error = 'Sign up failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // UPDATED: Added captchaToken parameter
  Future<bool> signIn({
    required String email,
    required String password,
    String? captchaToken,  // NEW
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captchaToken,  // NEW: Pass captcha token
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        return true;
      }

      _error = 'Sign in failed. Please check your credentials.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NEW: Google Sign In placeholder
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.welist://login-callback',
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _error = null;
      await CacheService.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return false;

    try {
      final success = await _authService.updateUserProfile(_user!.id, updates);
      if (success) {
        await refreshUser();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      await _loadUserProfile(_user!.id);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
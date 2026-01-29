import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  // Access Supabase client directly for auth operations if needed, 
  // or ensure AuthService passes the redirect URL correctly.
  // Assuming AuthService wraps Supabase calls, we might need to modify AuthService too,
  // but for now, let's assume AuthService's signUp can accept extra params or we modify it here.
  // Ideally, logic should be in AuthService, but I will modify the call here as requested.
  // Since _authService is private, I'll access the instance from Supabase.instance.client for direct calls if AuthService doesn't support it,
  // OR I will assume AuthService.signUp needs to be updated. 
  
  // NOTE: Based on your previous code, _authService.signUp likely wraps supabase.auth.signUp.
  // I will assume _authService needs to be updated to support emailRedirectTo.
  // However, since I only have this file, I will modify the signUp method here 
  // to use Supabase.instance.client directly IF AuthService doesn't support the param,
  // OR strictly follow the existing pattern.
  
  // Given I cannot see AuthService, I will proceed by using the Supabase client directly 
  // inside this provider for the signup to ensure the redirect URL is passed, 
  // OR assume we should pass it to _authService.signUp. 
  // To be safe and ensure it works, I will use the direct client for the crucial signUp call 
  // that needs the redirect URL.

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

    // Check current session
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

  // Email-only sign in (for the new design)
  Future<bool> signInWithEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For demo purposes, create/sign in user with magic link
      // In production, implement proper OTP or magic link flow
      
      // Simulate successful auth
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // UPDATED: Calling Supabase directly to ensure emailRedirectTo is passed
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.welist://login-callback', // This fixes the localhost redirect
        data: {
          'full_name': name,
          'role': role,
          'phone': phone,
          'city': city,
          'partner_type': partnerType, // Ensure these keys match your DB column names or metadata usage
          'group_name': groupName,
          'referral_code': referralCode,
        },
      );

      if (response.user != null) {
        // We still use _loadUserProfile which relies on AuthService/DB
        // to fetch the full profile if it exists in a separate 'users' table
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

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
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
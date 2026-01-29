class AppConstants {
  // App Info
  static const String appName = 'WeList';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Endpoints
  static const String baseUrl = 'https://api.welist.app';
  static const String openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_complete';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String cityKey = 'user_city';
  static const String searchHistoryKey = 'search_history';
  static const String fcmTokenKey = 'fcm_token';
  
  // Cache Service Keys (Added)
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyUserCity = 'user_city';
  static const String keyThemeMode = 'app_theme';
  
  // Supabase Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String coversBucket = 'covers';
  static const String itemsBucket = 'items';
  static const String shopsBucket = 'shops';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int searchResultsLimit = 50;
  static const int chatHistoryLimit = 100;
  static const int notificationsLimit = 50;
  
  // Unlock Expiry
  static const int unlockExpiryDays = 30;
  
  // Cache Duration
  static const Duration cacheDuration = Duration(hours:  1);
  static const Duration categoriesCacheDuration = Duration(days: 1);
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Debounce Duration
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration typingDebounce = Duration(milliseconds: 300);
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int maxBioLength = 500;
  static const int maxServiceNameLength = 100;
  static const int maxServiceDescriptionLength = 1000;
  
  // Image Constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1920;
  static const int imageQuality = 85;
  
  // AI Chat
  static const String aiModel = 'gpt-3.5-turbo';
  static const int aiMaxTokens = 500;
  static const double aiTemperature = 0.7;
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String sessionExpired = 'Your session has expired. Please login again. ';
  static const String unauthorizedError = 'You are not authorized to perform this action.';
  
  // Success Messages
  static const String profileUpdated = 'Profile updated successfully!';
  static const String passwordChanged = 'Password changed successfully!';
  static const String messageSent = 'Message sent!';
  
  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(r'^[0-9]{10}$');
  static final RegExp urlRegex = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
  );
  
  // Feature Flags
  static const bool enableAIChat = true;
  static const bool enableVoiceSearch = false;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  
  // Default Values
  static const String defaultCity = 'Shillong';
  static const String defaultCurrency = 'INR';
  static const String defaultLanguage = 'en';
}

class SubscriptionPlans {
  // User Plans
  static const String userFree = 'free';
  static const String userBasic = 'basic';
  static const String userPlus = 'plus';
  static const String userPro = 'pro';
  
  // Partner Plans
  static const String partnerFree = 'free';
  static const String partnerStarter = 'starter';
  static const String partnerBusiness = 'business';
  
  // Plan Prices (INR)
  static const Map<String, int> userPrices = {
    userFree: 0,
    userBasic: 99,
    userPlus: 199,
    userPro:  499,
  };
  
  static const Map<String, int> partnerPrices = {
    partnerFree:  0,
    partnerStarter: 199,
    partnerBusiness: 499,
  };
  
  // Unlocks per plan
  static const Map<String, int> userUnlocks = {
    userFree: 0,
    userBasic: 3,
    userPlus: 8,
    userPro: 15,
  };
}

class EventTypes {
  static const String signup = 'signup';
  static const String login = 'login';
  static const String search = 'search';
  static const String viewProfile = 'view_profile';
  static const String unlock = 'unlock';
  static const String sendMessage = 'send_message';
  static const String subscribe = 'subscribe';
  static const String referral = 'referral';
  static const String couponRedeemed = 'coupon_redeemed';
}
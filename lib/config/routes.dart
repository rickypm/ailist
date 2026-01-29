import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/conversation_model.dart';
import '../models/professional_model.dart';
import '../models/item_model.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/main_screen.dart';
import '../screens/services/category_screen.dart';
import '../screens/services/professional_detail_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/partner/partner_main_screen.dart';
import '../screens/partner/shop_editor_screen.dart';
import '../screens/partner/item_editor_screen.dart';
import '../screens/subscription/subscription_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String category = '/category';
  static const String professional = '/professional';
  static const String chat = '/chat';
  static const String editProfile = '/edit-profile';
  static const String partnerMain = '/partner-main';
  static const String shopEditor = '/shop-editor';
  static const String itemEditor = '/item-editor';
  static const String subscription = '/subscription';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
        
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
        
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
        
      case main: 
        return MaterialPageRoute(builder: (_) => const MainScreen());
        
      case category: 
        if (settings.arguments is CategoryModel) {
          return MaterialPageRoute(
            builder: (_) => CategoryScreen(category: settings.arguments as CategoryModel),
          );
        }
        return _errorRoute('Invalid Category Argument');

      case professional:
        if (settings.arguments is ProfessionalModel) {
          return MaterialPageRoute(
            builder: (_) => ProfessionalDetailScreen(professional: settings.arguments as ProfessionalModel),
          );
        }
        return _errorRoute('Invalid Professional Argument');

      case chat:
        if (settings. arguments is ConversationModel) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: settings.arguments as ConversationModel),
          );
        }
        return _errorRoute('Invalid Chat Argument');

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case partnerMain:
        return MaterialPageRoute(builder: (_) => const PartnerMainScreen());

      case shopEditor:
        return MaterialPageRoute(builder: (_) => const ShopEditorScreen());

      case itemEditor: 
        // ItemEditorScreen requires shopId, so we need arguments
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ItemEditorScreen(
              shopId: args['shopId'] as String,
              item: args['item'] as ItemModel?,
            ),
          );
        } else if (settings.arguments is String) {
          // Just shopId passed as string
          return MaterialPageRoute(
            builder: (_) => ItemEditorScreen(shopId: settings.arguments as String),
          );
        }
        return _errorRoute('ItemEditorScreen requires shopId argument');

      case subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());

      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar:  AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }

  // Navigation Helpers
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> navigateAndReplace<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, void>(context, routeName, arguments:  arguments);
  }

  static Future<T?> navigateAndClearStack<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(context, routeName, (route) => false, arguments: arguments);
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
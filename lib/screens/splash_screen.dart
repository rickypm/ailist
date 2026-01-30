import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../services/cache_service.dart';
import 'home/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final dataProvider = context.read<DataProvider>();
    
    await dataProvider.loadCategories();

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      debugPrint('✅ Session found, restoring user...');
      await dataProvider.initUser(session.user.id);
      
      if (dataProvider.currentUser?.city != null) {
        await CacheService.setString('user_city', dataProvider.currentUser!.city!);
      }
    } else {
      debugPrint('ℹ️ No session found, user not logged in');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.loginGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content - centered
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //const SizedBox(height: 64),
                          
                          // FIXED: Logo - larger size, no cropping, original color
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 180,   // Larger size
                            height: 180,  // Larger size
                            fit: BoxFit.contain,  // Prevent cropping
                          ),
                          
                          //const SizedBox(height: 2),
                          
                          // FIXED: Removed duplicate "AiList" text, only tagline now
                        Positioned(
                          bottom: -30,
                          child: Text(
                            'Find local services with AI',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                         ),
                       ],
                      ),
                          const SizedBox(height: 60),
                          
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ricky Paul Marwein',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© ${DateTime.now().year} Latynrai Creatives Pvt. Ltd.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
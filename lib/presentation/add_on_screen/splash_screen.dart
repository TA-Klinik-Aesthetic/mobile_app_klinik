import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/presentation/add_on_screen/onboarding_screen.dart';
import 'package:mobile_app_klinik/presentation/authentication_screen/login_user_screen.dart';
import 'package:mobile_app_klinik/presentation/home_screen/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  
  bool _isNavigating = false;
  String _debugMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    print('🚀 Splash Screen - initState called');
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  Future<void> _startSplashSequence() async {
    try {
      // Show splash for minimum 2.5 seconds
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted || _isNavigating) return;
      
      setState(() {
        _debugMessage = "Checking app status...";
      });
      
      await _checkAppFlow();
      
    } catch (e, stackTrace) {
      print('❌ Error in splash sequence: $e');
      print('📍 StackTrace: $stackTrace');
      
      if (mounted && !_isNavigating) {
        _navigateDirectly('/onboarding_screen');
      }
    }
  }

  Future<void> _checkAppFlow() async {
    if (!mounted || _isNavigating) return;
    
    print('🔍 Checking app flow...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ First check: Is this first time user?
      final isFirstTime = prefs.getBool('first_time_user') ?? true;
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      print('📱 App Status:');
      print('  - First time user: $isFirstTime');
      print('  - Onboarding completed: $onboardingCompleted');
      
      // ✅ If first time user or onboarding not completed -> Onboarding
      if (isFirstTime || !onboardingCompleted) {
        print('🎯 Route: Onboarding (new user)');
        _navigateDirectly('/onboarding_screen');
        return;
      }
      
      // ✅ Check if user is logged in
      final isLoggedIn = await AuthService.isLoggedIn();
      final token = await AuthService.getToken();
      final userId = await AuthService.getUserId();
      
      print('🔑 Auth Status:');
      print('  - Is logged in: $isLoggedIn');
      print('  - Has token: ${token != null}');
      print('  - Has user ID: ${userId != null}');
      
      if (isLoggedIn && token != null && userId != null) {
        print('🏠 Route: Home (logged in user)');
        _navigateDirectly('/home_screen');
      } else {
        print('🔐 Route: Login (guest user)');
        _navigateDirectly('/login_user_screen');
      }
      
    } catch (e, stackTrace) {
      print('❌ Error in _checkAppFlow: $e');
      print('📍 StackTrace: $stackTrace');
      
      // Fallback to onboarding
      if (mounted && !_isNavigating) {
        _navigateDirectly('/onboarding_screen');
      }
    }
  }

  // ✅ Use direct Navigator instead of NavigatorService
  void _navigateDirectly(String route) {
    if (!mounted || _isNavigating) return;
    
    print('🧭 Direct navigation to: $route');
    _isNavigating = true;
    
    setState(() {
      _debugMessage = "Opening app...";
    });
    
    try {
      // Use direct Navigator.pushNamedAndRemoveUntil
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('❌ Direct navigation error to $route: $e');
      
      // Fallback: Try with Navigator.pushReplacement
      try {
        Navigator.of(context).pushReplacementNamed(route);
      } catch (e2) {
        print('❌ Fallback navigation also failed: $e2');
        
        // Last resort: Manual navigation
        Widget targetWidget;
        switch (route) {
          case '/onboarding_screen':
            targetWidget = const OnboardingScreen();
            break;
          case '/login_user_screen':
            targetWidget = const LoginUserScreen();
            break;
          case '/home_screen':
            targetWidget = const HomeScreen();
            break;
          default:
            targetWidget = const OnboardingScreen();
        }
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => targetWidget),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              appTheme.lightGreen,
              appTheme.lightGreen.withOpacity(0.8),
              appTheme.lightGreen.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _logoScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 40,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        size: 80,
                        color: appTheme.lightGreen,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Animated Text
              AnimatedBuilder(
                animation: _textOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Column(
                      children: [
                        const Text(
                          'NAVYA Hub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mobile Clinic App',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 60),
              
              // Loading Section
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              
              const SizedBox(height: 20),
              
              Text(
                _debugMessage,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // ✅ Debug button for manual navigation
              ElevatedButton(
                onPressed: () {
                  if (!_isNavigating) {
                    print('🔧 Manual navigation triggered');
                    _navigateDirectly('/onboarding_screen');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue (DEBUG)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
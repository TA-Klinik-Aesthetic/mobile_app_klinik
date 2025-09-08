import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app_klinik/core/models/onboarding_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../core/widgets/language_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _floatController;
  late AnimationController _rotateController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  
  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isAnimating = false;
  Key _languageKey = UniqueKey();

  List<OnboardingModel> get _onboardingData => [
    OnboardingModel(
      title: "onboarding_title_1".tr,
      description: "onboarding_desc_1".tr,
      imagePath: "assets/images/slide_1.svg",
    ),
    OnboardingModel(
      title: "onboarding_title_2".tr,
      description: "onboarding_desc_2".tr,
      imagePath: "assets/images/slide_2.svg",
    ),
    OnboardingModel(
      title: "onboarding_title_3".tr,
      description: "onboarding_desc_3".tr,
      imagePath: "assets/images/slide_3.svg",
    ),
    OnboardingModel(
      title: "onboarding_title_4".tr,
      description: "onboarding_desc_4".tr,
      imagePath: "assets/images/slide_4.svg",
    ),
    OnboardingModel(
      title: "onboarding_title_5".tr,
      description: "onboarding_desc_5".tr,
      imagePath: "assets/images/slide_5.svg",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _pageController = PageController();
  }

  void _initializeAnimations() {
    // Fade Animation Controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Slide Animation Controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Scale Animation Controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Float Animation Controller (for continuous floating effect)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Rotate Animation Controller (for subtle rotation)
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Configure animations with advanced curves
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController, 
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController, 
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController, 
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.easeInOut,
      ),
    );

    // Start initial animations
    _startPageAnimations();
    
    // Start continuous animations
    _startContinuousAnimations();
  }

  void _startPageAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _startContinuousAnimations() {
    _floatController.repeat(reverse: true);
    _rotateController.repeat(reverse: true);
  }

  void _onLanguageChanged() {
    setState(() {
      _languageKey = UniqueKey();
    });
  }

  void _nextPage() async {
    if (_isAnimating) return;
    
    if (_currentPage < _onboardingData.length - 1) {
      setState(() {
        _isAnimating = true;
      });

      // Smooth fade out current page
      await _fadeController.reverse();
      
      // Change page
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      
      // Small delay for better visual effect
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Animate in new page
      _startPageAnimations();
      
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _skipToLogin() async {
    await _setOnboardingCompleted();
    if (mounted) {
      NavigatorService.pushNamedAndRemoveUntil(AppRoutes.loginUserScreen);
    }
  }

  void _goToLogin() async {
    await _setOnboardingCompleted();
    if (mounted) {
      NavigatorService.pushNamedAndRemoveUntil(AppRoutes.loginUserScreen);
    }
  }

  Future<void> _setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('first_time_user', false); // ✅ Mark as not first time user
    print('✅ Onboarding completed and first time user flag set to false');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
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
              Colors.white,
              appTheme.lightGreen.withOpacity(0.05),
              appTheme.lightGreen.withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Language Selector and Skip
              _buildTopBar(),
              
              // Main Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: _isAnimating 
                      ? const NeverScrollableScrollPhysics() 
                      : const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _isLastPage = index == _onboardingData.length - 1;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_onboardingData[index]);
                  },
                ),
              ),
              
              // Bottom Section
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Language Selector with subtle animation
                Transform.scale(
                  scale: 0.8 + (0.2 * _fadeAnimation.value),
                  child: LanguageSelector(
                    key: _languageKey,
                    showAsButton: true,
                    onLanguageChanged: _onLanguageChanged,
                  ),
                ),
                
                // Skip Button with slide animation
                if (!_isLastPage)
                  Transform.translate(
                    offset: Offset(50 * (1 - _fadeAnimation.value), 0),
                    child: GestureDetector(
                      onTap: _skipToLogin,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: appTheme.orange200.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.h),
                          border: Border.all(
                            color: appTheme.orange200.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: appTheme.orange200.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "btn_skip".tr,
                          style: TextStyle(
                            color: appTheme.orange200,
                            fontSize: 14.h,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnboardingPage(OnboardingModel data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with Multiple Animations
          _buildAnimatedImage(data.imagePath),
          
          SizedBox(height: 60.h),
          
          // Title and Description with Staggered Animation
          _buildAnimatedText(data),
        ],
      ),
    );
  }

  Widget _buildAnimatedImage(String imagePath) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _floatAnimation,
        _rotateAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 350.h,
                height: 450.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.h),
                  color: Colors.grey.shade100, // ✅ Debug background
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.lightGreen.withOpacity(0.1 * _scaleAnimation.value),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.h),
                  child: _buildDebugSVG(imagePath), // ✅ Use debug method
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Add debug SVG method with error handling
  Widget _buildDebugSVG(String imagePath) {
    print('🔍 Debug SVG: $imagePath');
    
    return SvgPicture.asset(
      imagePath,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      placeholderBuilder: (context) => Container(
        color: Colors.yellow.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 50, color: Colors.orange),
              SizedBox(height: 8),
              Text(
                'SVG Loading...',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              Text(
                imagePath.split('/').last,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      // ✅ Critical: Add error builder to catch SVG errors
      errorBuilder: (context, error, stackTrace) {
        print('❌ SVG Error for $imagePath: $error');
        print('❌ StackTrace: $stackTrace');
        
        return Container(
          color: Colors.red.shade50,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 50, color: Colors.red),
                SizedBox(height: 8),
                Text(
                  'SVG Error!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Text(
                  imagePath.split('/').last,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  'Using fallback...',
                  style: TextStyle(color: Colors.blue, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText(OnboardingModel data) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Title with staggered animation
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.h,
                        fontWeight: FontWeight.bold,
                        color: appTheme.black900,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 20.h),
            
            // Description with delayed animation
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final delayedProgress = (_slideAnimation.value.dy + 0.5).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - delayedProgress)),
                  child: Opacity(
                    opacity: delayedProgress,
                    child: Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.h,
                        color: appTheme.black900.withOpacity(0.7),
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.all(24.h),
              child: Column(
                children: [
                  // Page Indicator
                  _buildPageIndicator(),
                  
                  SizedBox(height: 32.h),
                  
                  // Action Button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeOutCubic)),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _isLastPage ? _buildLoginButton() : _buildNextButton(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _onboardingData.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          margin: EdgeInsets.symmetric(horizontal: 4.h),
          width: _currentPage == index ? 32.h : 8.h,
          height: 8.h,
          decoration: BoxDecoration(
            color: _currentPage == index 
                ? appTheme.orange200 
                : appTheme.orange200.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4.h),
            boxShadow: _currentPage == index
                ? [
                    BoxShadow(
                      color: appTheme.orange200.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _isAnimating ? null : _nextPage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: _isAnimating 
              ? appTheme.lightGreen.withOpacity(0.7)
              : appTheme.lightGreen,
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.lightGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isAnimating
              ? SizedBox(
                  width: 24.h,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  "btn_next".tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.h,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _goToLogin,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              appTheme.orange200,
              appTheme.orange400,
            ],
          ),
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.orange200.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "btn_get_started".tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.h,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
// lib/features/shared/presentation/screens/splash_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/static/app_assets.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _shimmerController;
  late AnimationController _backgroundController;
  late AnimationController _pulseController;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;

  // Text animations
  late Animation<double> _textFadeIn;
  late Animation<Offset> _textSlideIn;
  late Animation<double> _taglineOpacity;

  // Background animations
  late Animation<double> _backgroundGradient;
  late Animation<double> _shimmerAnimation;

  // Pulse animation for logo
  late Animation<double> _pulseAnimation;

  bool _isDisposed = false;
  bool _animationsComplete = false;
  bool _hasNavigated = false;
  AuthState? _pendingAuthState;

  // Animation duration constants
  static const Duration _totalAnimationDuration = Duration(milliseconds: 3000);
  static const Duration _minimumSplashDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Logo Animation Controller
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    // Text Animation Controller
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // Shimmer Animation Controller
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    // Background Animation Controller
    _backgroundController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    // Pulse Animation Controller
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    // Logo Animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));

    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Text Animations
    _textFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeInOut));

    _textSlideIn = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutBack));

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Background Animations
    _backgroundGradient = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    // Pulse Animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  // Safe animation helper methods
  void _safeRepeatAnimation(AnimationController controller, {bool reverse = false}) {
    if (mounted && !_isDisposed && !controller.isAnimating) {
      try {
        controller.repeat(reverse: reverse);
      } catch (e) {
        debugPrint('Animation controller repeat error: $e');
      }
    }
  }

  void _safeForwardAnimation(AnimationController controller) {
    if (mounted && !_isDisposed) {
      try {
        controller.forward();
      } catch (e) {
        debugPrint('Animation controller forward error: $e');
      }
    }
  }

  void _startAnimationSequence() async {
    try {
      // Start background animation immediately
      _safeForwardAnimation(_backgroundController);

      // Start logo animation after a short delay
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _isDisposed) return;
      _safeForwardAnimation(_logoController);

      // Start text animation after logo animation begins
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || _isDisposed) return;
      _safeForwardAnimation(_textController);

      // Start shimmer effect
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted || _isDisposed) return;
      _safeRepeatAnimation(_shimmerController);

      // Start pulse animation and repeat
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || _isDisposed) return;
      _safeRepeatAnimation(_pulseController, reverse: true);

      // Wait for minimum animation duration before allowing navigation
      await Future.delayed(_minimumSplashDuration);
      if (!mounted || _isDisposed) return;

      _animationsComplete = true;

      // If we have a pending auth state, handle it now
      if (_pendingAuthState != null) {
        _handleAuthState(_pendingAuthState!);
      } else {
        // Check auth status manually if no state received
        _checkAuthStatus();
      }
    } catch (e) {
      debugPrint('Animation sequence error: $e');
      // Fallback to check auth status immediately
      if (mounted && !_isDisposed) {
        _animationsComplete = true;
        _checkAuthStatus();
      }
    }
  }

  void _checkAuthStatus() {
    try {
      if (!mounted || _isDisposed || _hasNavigated) return;

      // Check if user is already authenticated
      final authCubit = context.read<AuthCubit>();
      final currentUser = authCubit.currentUser;

      if (currentUser != null) {
        // User is logged in, navigate to appropriate dashboard
        _navigateBasedOnRole(UserRole.fromStr(currentUser.role.toString()));
      } else {
        // User is not logged in, navigate to login
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      // Fallback to login page
      _navigateToLogin();
    }
  }

  void _handleAuthState(AuthState state) {
    if (!mounted || _isDisposed || _hasNavigated) return;

    // If animations aren't complete yet, store the state for later
    if (!_animationsComplete) {
      _pendingAuthState = state;
      return;
    }

    state.maybeWhen(
      authenticated: (user) {
        // Initialize FCM for authenticated user
        // FCMNotificationService().initialize();

        // Navigate based on user role
        _navigateBasedOnRole(user.role);
      },
      unauthenticated: () {
        _navigateToLogin();
      },
      error: (failure) {
        // Show error message and navigate to login
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure), backgroundColor: AppColors.error));
        }
        _navigateToLogin();
      },
      orElse: () {},
    );
  }

  void _navigateToLogin() {
    if (!mounted || _isDisposed || _hasNavigated) return;
    _hasNavigated = true;
    context.go(Routes.login);
  }

  void _navigateBasedOnRole(UserRole role) {
    try {
      if (!mounted || _isDisposed || _hasNavigated) return;
      _hasNavigated = true;

      switch (role) {
        case UserRole.admin:
          // context.go(Routes.adminDashboard);
          context.go(Routes.layoutAdmin); // Fallback until admin route is ready
          break;
        case UserRole.employee:
          context.go(Routes.layoutEmployee);
          break;
        case UserRole.officeBoy:
          // context.go(Routes.officeBoyDashboard);
          context.go(Routes.layoutOfficeBoy); // Fallback until office boy route is ready
          break;
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      _navigateToLogin();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Stop all animations before disposing to prevent errors
    try {
      _logoController.stop();
      _textController.stop();
      _shimmerController.stop();
      _backgroundController.stop();
      _pulseController.stop();
    } catch (e) {
      debugPrint('Error stopping animations: $e');
    }

    // Reset all animations to prevent any pending operations
    try {
      _logoController.reset();
      _textController.reset();
      _shimmerController.reset();
      _backgroundController.reset();
      _pulseController.reset();
    } catch (e) {
      debugPrint('Error resetting animations: $e');
    }

    // Now dispose of the controllers
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>()..initializeAuthStream(),
      child: Scaffold(
        body: BlocListener<AuthCubit, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (_isDisposed || !mounted) return;
            _handleAuthState(state);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _logoController,
              _textController,
              _shimmerController,
              _backgroundController,
              _pulseController,
            ]),
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8), AppColors.primary.withOpacity(0.9)],
                    stops: [0.0, _backgroundGradient.value * 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background particles/dots animation
                    _buildBackgroundParticles(),

                    // Main content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with multiple animations
                          _buildAnimatedLogo(),

                          const SizedBox(height: 30),

                          // App name with shimmer effect
                          _buildAnimatedTitle(),

                          const SizedBox(height: 15),

                          // Tagline with fade in
                          _buildAnimatedTagline(),

                          const SizedBox(height: 50),

                          // Loading indicator
                          _buildLoadingIndicator(),
                        ],
                      ),
                    ),

                    // App version at bottom
                    _buildVersionInfo(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    return Positioned.fill(child: CustomPaint(painter: ParticlesPainter(_backgroundGradient.value)));
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _logoRotation.value * 0.1, // Subtle rotation
            child: Opacity(
              opacity: _logoOpacity.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                ),
                child: ClipOval(child: Image.asset(AppImages.logo, fit: BoxFit.cover)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return SlideTransition(
      position: _textSlideIn,
      child: FadeTransition(
        opacity: _textFadeIn,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [Colors.white, Colors.white70, Colors.white],
              stops: [_shimmerAnimation.value - 0.3, _shimmerAnimation.value, _shimmerAnimation.value + 0.3],
            ).createShader(bounds);
          },
          child: const Text(
            'TaQy',
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTagline() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            'test',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w300, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.loading.tr(),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _taglineOpacity,
        child: Column(
          children: [
            Text(
              'Powered By TaQy Team',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 4),
            Text(
              'TaQy v1.0.0',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for background particles
class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw animated particles
    for (int i = 0; i < 20; i++) {
      final double x = (size.width * 0.1 * i) % size.width;
      final double y = (size.height * 0.15 * i + animationValue * 100) % size.height;
      final double radius = (i % 3 + 1) * 2.0;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw some larger floating elements
    for (int i = 0; i < 5; i++) {
      final double x = (size.width * 0.3 * i + animationValue * 50) % size.width;
      final double y = (size.height * 0.4 * i) % size.height;
      final double radius = (i % 2 + 1) * 1.5;

      paint.color = Colors.white.withOpacity(0.05);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

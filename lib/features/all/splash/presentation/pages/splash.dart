// lib/features/shared/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/static/app_assets.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
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

  void _startAnimationSequence() async {
    // Start background animation immediately
    _backgroundController.forward();

    // Start logo animation after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Start text animation after logo animation begins
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Start shimmer effect
    await Future.delayed(const Duration(milliseconds: 400));
    _shimmerController.repeat();

    // Start pulse animation and repeat
    await Future.delayed(const Duration(milliseconds: 800));
    _pulseController.repeat(reverse: true);

    // Auto login after all animations
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      context.read<AuthCubit>().autoLogin();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (BuildContext context, AuthState state) {
          if (state is AuthSuccess) {
            context.go(Routes.homeUser);
          }
          if (state is AuthError) {
            showErrorToast(context, state.message);
          }
          

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
                ],
              ),
            );
          },
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
            'Office Requests Made Simple',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w300, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
          strokeWidth: 2,
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

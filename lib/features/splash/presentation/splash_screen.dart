import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_service.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    // Start fade-in animation
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _opacity = 1.0;
      });
    }

    // Minimum display duration for the splash screen (e.g. 2.5 seconds)
    final stopwatch = Stopwatch()..start();

    // Trigger Database Seeding
    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.seedDatabase();
    } catch (e) {
      debugPrint("Error seeding database on splash: $e");
    }

    // Calculate remaining duration to ensure splash stays visible for at least 2.5s
    final elapsedMs = stopwatch.elapsedMilliseconds;
    const minSplashDurationMs = 2500;
    if (elapsedMs < minSplashDurationMs) {
      await Future.delayed(Duration(milliseconds: minSplashDurationMs - elapsedMs));
    }

    if (mounted) {
      // Navigate to Home screen and remove splash from navigation history
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo: Gold ornament frame enclosing the text
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldAccent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDarkGreen, AppColors.surfaceDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'قصيدة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldAccent,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'البردة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldAccent,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // App Title in English
              Text(
                'QASIDA BURDA SHAREEF',
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'قصيدة البردة الشريفة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  letterSpacing: 1.0,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(height: 48),
              // Subtle Loading Indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

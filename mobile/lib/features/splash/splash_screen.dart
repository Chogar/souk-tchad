import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _minDisplay = Duration(milliseconds: 180);

  late final AnimationController _logoController;
  late final AnimationController _loaderController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  bool _minTimeDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoOpacity = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoController.forward();

    Future.delayed(_minDisplay, () {
      if (!mounted) return;
      setState(() => _minTimeDone = true);
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (_navigated || !_minTimeDone) return;
    final auth = ref.read(authStateProvider);
    if (auth.isLoading) return;

    // Ne pas bloquer sur le catalogue : sync en arrière-plan.
    unawaited(refreshListingsCatalog(ref));

    if (!mounted) return;
    _navigated = true;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, __) => _tryNavigate());

    final strings = ref.watch(stringsProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003080),
              AppColors.primaryBlue,
              Color(0xFF001233),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) => Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                ),
                child: const AppLogo(size: 96),
              ),
              const SizedBox(height: 20),
              Text(
                strings.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _loaderController,
                builder: (context, _) => SizedBox(
                  width: 120,
                  height: 3,
                  child: LinearProgressIndicator(
                    value: 0.35 +
                        0.3 *
                            math.sin(_loaderController.value * math.pi * 2),
                    backgroundColor: Colors.white24,
                    color: AppColors.accentGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

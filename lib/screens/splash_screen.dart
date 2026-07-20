import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/route_transitions.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _leafController;

  final _leaves = [
    _FloatingLeaf(0.08, 0.25, 12, 0.7, 18, 0.3),
    _FloatingLeaf(0.85, 0.35, 16, 0.5, 22, 0.8),
    _FloatingLeaf(0.15, 0.70, 14, 0.9, 14, 1.2),
    _FloatingLeaf(0.90, 0.55, 10, 0.6, 20, 2.5),
    _FloatingLeaf(0.50, 0.15, 8, 1.1, 12, 0.0),
  ];

  @override
  void initState() {
    super.initState();
    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _leafController.dispose();
    super.dispose();
  }

  void _enterApp() {
    Navigator.of(context).pushReplacement(
      ScaleFadeRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  const Color(0xFFF7F1E4).withValues(alpha: 0.16),
                  const Color(0xFF4B3727).withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final logoWidth = width * 0.78;
                final mascotWidth = width * 0.62;
                final availableHeight = height - 20 - 24 - 62 - 26;
                final scale = (availableHeight / 500).clamp(0.5, 1.0);

                return Stack(
                  children: [
                    // Floating leaves
                    AnimatedBuilder(
                      animation: _leafController,
                      builder: (context, _) {
                        return Stack(
                          children: _leaves.map((leaf) {
                            final drift = math.sin(
                                    _leafController.value * math.pi * 2 *
                                            leaf.speed +
                                        leaf.phase) *
                                leaf.amplitude;
                            final rot = leaf.phase +
                                math.sin(_leafController.value * math.pi * 2 *
                                        leaf.speed *
                                        0.5 +
                                    leaf.phase) *
                                    0.3;
                            return Positioned(
                              left: width * leaf.xFraction,
                              top: height * leaf.yBase + drift,
                              child: Transform.rotate(
                                angle: rot,
                                child: Opacity(
                                  opacity: 0.35,
                                  child: Icon(
                                    Icons.eco_rounded,
                                    size: leaf.size,
                                    color: AppColors.surface,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Flexible(
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: (logoWidth * scale).clamp(160.0, 460.0),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: Center(
                              child: Image.asset(
                                'assets/images/mascot.png',
                                width: (mascotWidth * scale).clamp(140.0, 360.0),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4B3727).withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 62,
                              child: ElevatedButton(
                                onPressed: _enterApp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C8B4A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    side: const BorderSide(
                                      color: Color(0xFF4A6A33),
                                      width: 2,
                                    ),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                child: const Text('START ADVENTURE'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingLeaf {
  const _FloatingLeaf(
    this.xFraction,
    this.yBase,
    this.amplitude,
    this.speed,
    this.size,
    this.phase,
  );

  final double xFraction;
  final double yBase;
  final double amplitude;
  final double speed;
  final double size;
  final double phase;
}

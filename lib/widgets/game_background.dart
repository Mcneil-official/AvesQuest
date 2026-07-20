import 'package:flutter/material.dart';

/// Adds a soft radial-gradient vignette (or a burst effect for reveal
/// screens) behind any child content, giving screens a warmer, more
/// game-like depth.
class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    required this.child,
    this.isRevealScreen = false,
  });

  final Widget child;
  final bool isRevealScreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isRevealScreen
                  ? const RadialGradient(
                      center: Alignment(0.0, -0.2),
                      radius: 1.1,
                      colors: [
                        Color(0xFF8DA86E),
                        Color(0xFF7D9652),
                        Color(0xFF6B8545),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : const RadialGradient(
                      center: Alignment(0.0, -0.3),
                      radius: 1.3,
                      colors: [
                        Color(0xFFF7F1E4),
                        Color(0xFFF2EAD8),
                        Color(0xFFEADCC6),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
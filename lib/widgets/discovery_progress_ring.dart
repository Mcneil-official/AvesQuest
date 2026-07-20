import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The big circular "FOUND 142 OUT OF 500" progress ring on the journal
/// dashboard. Drawn with a CustomPainter so the arc thickness, sweep, and
/// rounded cap match the reference screen exactly.
class DiscoveryProgressRing extends StatefulWidget {
  const DiscoveryProgressRing({
    super.key,
    required this.found,
    required this.total,
    this.size = 220,
    this.badgeIcon = Icons.workspace_premium_outlined,
  });

  final int found;
  final int total;
  final double size;
  final IconData badgeIcon;

  @override
  State<DiscoveryProgressRing> createState() => _DiscoveryProgressRingState();
}

class _DiscoveryProgressRingState extends State<DiscoveryProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress =>
      widget.total == 0 ? 0 : (widget.found / widget.total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              return AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _RingPainter(
                      progress: animatedProgress,
                      pulseValue: _pulseAnimation.value,
                    ),
                  );
                },
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.found}',
                style: AppTypography.displayLg(color: AppColors.primary)
                    .copyWith(fontSize: 52),
              ),
              const SizedBox(height: 4),
              Text(
                'Birds Found',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          Positioned(
            top: widget.size * 0.04,
            right: widget.size * 0.04,
            child: _BadgeButton(icon: widget.badgeIcon),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    this.pulseValue = 1.0,
  });

  final double progress;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    const strokeWidth = 14.0;

    // Full track circle
    final trackPaint = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Milestone dots on the track at 25%, 50%, 75%, 100%
    const milestonePcts = [0.25, 0.50, 0.75];
    final dotPaint = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.fill;
    for (final pct in milestonePcts) {
      final angle = -math.pi / 2 + 2 * math.pi * pct;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 4, dotPaint);
    }
    // 100% milestone (slightly larger)
    final finishAngle = -math.pi / 2 + 2 * math.pi;
    final finishDx = center.dx + radius * math.cos(finishAngle);
    final finishDy = center.dy + radius * math.sin(finishAngle);
    canvas.drawCircle(Offset(finishDx, finishDy), 5, dotPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glowing leading-edge cap (only when progress > 0)
    if (progress > 0 && progress < 1.0) {
      final capAngle = -math.pi / 2 + 2 * math.pi * progress;
      final capX = center.dx + radius * math.cos(capAngle);
      final capY = center.dy + radius * math.sin(capAngle);
      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3 * pulseValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(capX, capY), strokeWidth / 2 + 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulseValue != pulseValue;
}

class _BadgeButton extends StatelessWidget {
  const _BadgeButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceContainerLowest, width: 2),
      ),
      child: Icon(icon, size: 18, color: AppColors.onSecondaryContainer),
    );
  }
}

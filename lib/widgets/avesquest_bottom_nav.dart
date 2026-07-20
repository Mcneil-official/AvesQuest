import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AvesQuestBottomNav extends StatelessWidget {
  const AvesQuestBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.pendingCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingCount;

  static const _items = [
    _NavItemData(icon: Icons.explore_rounded, label: 'Home'),
    _NavItemData(icon: Icons.add_a_photo_rounded, label: 'Catch'),
    _NavItemData(icon: Icons.auto_stories_rounded, label: 'Journal'),
    _NavItemData(icon: Icons.person, label: 'Profile'),
  ];

  static const Color _barColor = Color(0xFFF7F1E4);
  static const Color _iconColor = Color(0xFF4B3727);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            return _NavItem(
              icon: item.icon,
              label: item.label,
              active: index == currentIndex,
              badge: index == 2 ? pendingCount : null,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final int? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = badge;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 22,
                    color: active ? AppColors.primary : AvesQuestBottomNav._iconColor),
              ),
              if (b != null && b > 0)
                Positioned(
                  right: 8,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE98D42),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      b > 99 ? '99+' : b.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : AvesQuestBottomNav._iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

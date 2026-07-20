import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bird_provider.dart';
import '../providers/pending_queue_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/avesquest_bottom_nav.dart';
import '../widgets/route_transitions.dart';
import 'capture_screen.dart';
import 'journal_home_screen.dart';
import 'journal_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;

  static const _tabs = [
    JournalHomeScreen(),
    JournalScreen(),
    ProfileScreen(),
  ];

  int _bodyIndexFor(int navIndex) {
    switch (navIndex) {
      case 0:
        return 0;
      case 2:
        return 1;
      case 3:
        return 2;
      default:
        return 0;
    }
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 1) {
      _openCatchFlow();
      return;
    }
    setState(() => _tabIndex = navIndex);
  }

  Future<void> _openCatchFlow() async {
    final birdId = await Navigator.of(context).push<int>(
      ScaleFadeRoute(builder: (_) => const CaptureScreen()),
    );
    if (birdId != null && mounted) {
      final birdProvider = context.read<BirdProvider>();
      await birdProvider.loadBirds();
      birdProvider.highlightBird(birdId);
      setState(() => _tabIndex = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<PendingQueueProvider>().activeCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_bodyIndexFor(_tabIndex)),
          child: _tabs[_bodyIndexFor(_tabIndex)],
        ),
      ),
      bottomNavigationBar: AvesQuestBottomNav(
        currentIndex: _tabIndex,
        onTap: _onNavTap,
        pendingCount: pendingCount,
      ),
    );
  }
}
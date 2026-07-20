import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;
    _isOffline = result.contains(ConnectivityResult.none);
    setState(() {});

    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      _isOffline = result.contains(ConnectivityResult.none);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.sunnyYellow.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.onSurface),
          const SizedBox(width: 8),
          Text(
            'No connection — photos will sync later',
            style: AppTypography.labelSm(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

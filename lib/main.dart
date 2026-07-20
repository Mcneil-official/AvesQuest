import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/bird_provider.dart';
import 'providers/identification_provider.dart';
import 'providers/pending_queue_provider.dart';
import 'providers/quest_provider.dart';
import 'screens/splash_screen.dart';
import 'services/auto_sync_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AvesQuestApp());
}

class AvesQuestApp extends StatelessWidget {
  const AvesQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BirdProvider()),
        ChangeNotifierProvider(create: (_) => PendingQueueProvider()),
        ChangeNotifierProvider(create: (context) => QuestProvider(
          birdProvider: context.read<BirdProvider>(),
        )),
        ChangeNotifierProvider(create: (context) => IdentificationProvider(
          pendingQueueProvider: context.read<PendingQueueProvider>(),
        )),
      ],
      child: MaterialApp(
        title: 'AvesQuest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AppWithAutoSync(),
      ),
    );
  }
}

class _AppWithAutoSync extends StatefulWidget {
  const _AppWithAutoSync();

  @override
  State<_AppWithAutoSync> createState() => _AppWithAutoSyncState();
}

class _AppWithAutoSyncState extends State<_AppWithAutoSync> {
  AutoSyncService? _autoSync;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoSync == null) {
      _autoSync = AutoSyncService(
        pendingQueueProvider: context.read<PendingQueueProvider>(),
        identificationProvider: context.read<IdentificationProvider>(),
      );
      _autoSync!.start();
    }
  }

  @override
  void dispose() {
    _autoSync?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

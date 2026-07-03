import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth/auth_service.dart';
import 'battle/cubit/battle_cubit.dart';
import 'battle/screen/history_screen.dart';
import 'battle/screen/home_screen.dart';
import 'battle/screen/stats_screen.dart';
import 'battle/services/battle_service.dart';
import 'firebase_options.dart';
import 'recovery/cubit/recovery_cubit.dart';
import 'recovery/screen/recovery_screen.dart';
import 'recovery/services/recovery_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  runApp(const DisciplineApp());
}

class DisciplineApp extends StatelessWidget {
  const DisciplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discipline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Bootstrap(),
    );
  }
}

/// Silently signs the user in anonymously, then wires up the [BattleCubit].
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final AuthService _auth = AuthService();
  late final Future<String?> _signIn = _auth.ensureSignedIn();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _signIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _Centered(child: CircularProgressIndicator());
        }
        final uid = snapshot.data;
        if (snapshot.hasError || uid == null) {
          return const _Centered(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not connect. Check your internet and reopen the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => BattleCubit(service: BattleService(), uid: uid),
            ),
            BlocProvider(
              create: (_) =>
                  RecoveryCubit(service: RecoveryService(), uid: uid),
            ),
          ],
          child: const HomeShell(),
        );
      },
    );
  }
}

class _Centered extends StatelessWidget {
  final Widget child;
  const _Centered({required this.child});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: child));
}

/// Bottom-nav shell hosting the tabs: Today, Recovery, History, and Stats.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    RecoveryScreen(),
    HistoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.fire.withValues(alpha: 0.18),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today, color: AppColors.fire),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.healing_outlined),
            selectedIcon: Icon(Icons.healing, color: AppColors.fire),
            label: 'Recovery',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.fire),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.fire),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

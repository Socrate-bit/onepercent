import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'battle/cubit/battle_cubit.dart';
import 'battle/screen/history_screen.dart';
import 'battle/screen/home_screen.dart';
import 'battle/screen/stats_screen.dart';
import 'battle/services/battle_service.dart';
import 'firebase_options.dart';
import 'recovery/cubit/recovery_cubit.dart';
import 'recovery/services/recovery_service.dart';
import 'theme/app_theme.dart';
import 'tools/screen/tools_screen.dart';
import 'value/cubit/value_cubit.dart';
import 'value/services/value_service.dart';

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
    return ScreenUtilInit(
      designSize: const Size(414, 896), // iPhone 11 logical size
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) => MaterialApp(
        title: 'Discipline',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: child,
      ),
      child: const _Bootstrap(),
    );
  }
}

/// Auth gate: shows the [LoginScreen] until the user signs in with Apple,
/// then wires up the [BattleCubit]/[RecoveryCubit] for their uid.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Centered(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null ) {
          return const LoginScreen();
        }
        final uid = user.uid;
        return MultiBlocProvider(
          // Rebuild cubits when the signed-in account changes.
          key: ValueKey(uid),
          providers: [
            BlocProvider(
              create: (_) => BattleCubit(service: BattleService(), uid: uid),
            ),
            BlocProvider(
              create: (_) =>
                  RecoveryCubit(service: RecoveryService(), uid: uid),
            ),
            BlocProvider(
              create: (_) => ValueCubit(service: ValueService(), uid: uid),
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

/// Bottom-nav shell hosting the tabs: Today, Tools, History, and Stats.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    ToolsScreen(),
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
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman, color: AppColors.fire),
            label: 'Tools',
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

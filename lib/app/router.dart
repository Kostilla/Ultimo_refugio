import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/services/supabase_service.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/colony/presentation/create_or_join_colony_screen.dart';
import '../features/home/presentation/home_shell.dart';

Future<bool> hasColony() async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  final res = await supabase
      .from('colony_members')
      .select('id')
      .eq('user_id', user.id)
      .limit(1);

  return res.isNotEmpty;
}

final router = GoRouter(
  initialLocation: '/login',
  refreshListenable: GoRouterRefreshStream(
    supabase.auth.onAuthStateChange,
  ),
  redirect: (context, state) async {
    final user = supabase.auth.currentUser;
    final currentPath = state.uri.path;

    final isLogin = currentPath == '/login';
    final isRegister = currentPath == '/register';
    final isAuthRoute = isLogin || isRegister;
    final isColonyEntry = currentPath == '/colony-entry';
    final isHome = currentPath == '/home';

    // No logueado: solo puede estar en login o register
    if (user == null) {
      return isAuthRoute ? null : '/login';
    }

    final inColony = await hasColony();

    // Logueado pero sin colonia: debe ir a /colony-entry
    if (!inColony) {
      return isColonyEntry ? null : '/colony-entry';
    }

    // Logueado y con colonia: no debe quedarse en login/register/colony-entry
    if (inColony) {
      return isHome ? null : '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/colony-entry',
      builder: (context, state) => const CreateOrJoinColonyScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeShell(),
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
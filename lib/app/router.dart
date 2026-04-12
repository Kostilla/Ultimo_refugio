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

  // No logueado → login
  if (user == null) return '/login';

  final inColony = await hasColony();

  // Si está logueado y NO tiene colonia → crear
  if (!inColony && state.uri.path != '/colony') {
    return '/colony';
  }

  // Si tiene colonia → ir a home
  if (inColony && state.uri.path != '/home') {
    return '/home';
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
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

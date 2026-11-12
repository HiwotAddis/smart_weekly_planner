import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../services/auth_service.dart';

/// Routes between auth screens and the signed-in app based on session state.
/// Sessions are restored by [Supabase.initialize] before the app builds.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.signedInChild,
    this.authService,
  });

  final Widget signedInChild;
  final AuthService? authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _auth;
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
    _subscription = _auth.authStateChanges.listen((state) {
      if (state.session == null || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Drop login/register/reset routes stacked above the gate.
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Authentication error. Please restart the app.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final session = snapshot.data?.session ?? _auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting &&
            session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session != null) {
          return widget.signedInChild;
        }

        return LoginScreen(authService: _auth);
      },
    );
  }
}

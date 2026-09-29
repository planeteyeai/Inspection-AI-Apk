import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'screens/inspection_main_screen.dart';
import 'screens/login_screen.dart';
import 'ui/app_theme.dart';

void main() {
  runApp(const ThermalAIBridgeApp());
}

class ThermalAIBridgeApp extends StatelessWidget {
  const ThermalAIBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isCheckingSession = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final loggedIn = await AuthService.hasSavedSession();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = loggedIn;
      _isCheckingSession = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 14),
                const Text(
                  'Loading session...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      return InspectionMainScreen(onLogout: _logout);
    }

    return LoginScreen(onLoggedIn: () => setState(() => _isLoggedIn = true));
  }
}

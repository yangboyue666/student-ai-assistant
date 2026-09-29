import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/hub/hub_screen.dart';

class StudentAssistantApp extends ConsumerStatefulWidget {
  const StudentAssistantApp({super.key});

  @override
  ConsumerState<StudentAssistantApp> createState() => _StudentAssistantAppState();
}

class _StudentAssistantAppState extends ConsumerState<StudentAssistantApp>
    with WidgetsBindingObserver {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboarding();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (mounted) setState(() => _onboarded = done);
  }

  void _onCompleteOnboarding() {
    setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学生智能助手',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _onboarded == null
          ? const _SplashGate()
          : _onboarded == true
              ? const HubScreen()
              : WelcomeScreen(onComplete: _onCompleteOnboarding),
    );
  }
}

class _SplashGate extends StatelessWidget {
  const _SplashGate();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0B3D), Color(0xFF2D1B5E), Color(0xFF0F1A4A)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7DD3FC),
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

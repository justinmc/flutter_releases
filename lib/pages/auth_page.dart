import 'package:flutter/material.dart';
import '../widgets/link.dart';

class AuthPage extends MaterialPage {
  AuthPage({
    required final VoidCallback onNavigateHome,
    required final String authCode,
    final String? error,
  }) : super(
    key: const ValueKey('AuthPage'),
    restorationId: 'auth-page',
    child: _AuthPage(
      authCode: authCode,
      onNavigateHome: onNavigateHome,
    ),
  );
}

class _AuthPage extends StatelessWidget {
  const _AuthPage({
    Key? key,
    required this.authCode,
    required this.onNavigateHome,
  }) : super(key: key);

  final String authCode;
  final VoidCallback onNavigateHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Authenticating...'),
              Link.tap(
                text: 'Return home',
                onTap: onNavigateHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/link.dart';
import '../widgets/settings_button.dart';

class UnknownPage extends MaterialPage {
  UnknownPage({
    required final VoidCallback onNavigateHome,
    final String? error,
  }) : super(
          key: const ValueKey('UnknownPage'),
          restorationId: 'auth-page',
          child: _UnknownPage(
            onNavigateHome: onNavigateHome,
            error: error,
          ),
        );
}

class _UnknownPage extends StatelessWidget {
  const _UnknownPage({
    required this.onNavigateHome,
    this.error,
  });

  final VoidCallback onNavigateHome;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('404'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            onNavigateHome();
          },
        ),
        actions: const <Widget>[
          SettingsButton(),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (error != null)
                SelectionArea(
                  child: Text(error!),
                ),
              if (error == null)
                const SelectionArea(
                  child: Text("Sorry, this page doesn't exist!"),
                ),
              Link(
                text: 'Return home',
                uri: Uri.parse('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

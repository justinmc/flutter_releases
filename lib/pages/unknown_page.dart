import 'package:flutter/material.dart';
import '../widgets/link.dart';

class UnknownPage extends MaterialPage {
  UnknownPage({
    required final VoidCallback onNavigateHome,
    final String? error,
  }) : super(
    key: const ValueKey('UnknownPage'),
    restorationId: 'home-page',
    child: _UnknownPage(
      onNavigateHome: onNavigateHome,
      error: error,
    ),
  );
}

class _UnknownPage extends StatelessWidget {
  const _UnknownPage({
    Key? key,
    required this.onNavigateHome,
    this.error,
  }) : super(key: key);

  final VoidCallback onNavigateHome;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('404'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (error != null)
                Text(error!),
              if (error == null)
                const Text("Sorry, this page doesn't exist!"),
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

import 'package:flutter/material.dart';
import '../widgets/link.dart';

class UnknownPage extends MaterialPage {
  UnknownPage({
    required final VoidCallback onNavigateHome,
  }) : super(
    key: const ValueKey('UnknownPage'),
    restorationId: 'home-page',
    child: _UnknownPage(
      onNavigateHome: onNavigateHome,
    ),
  );
}

class _UnknownPage extends StatelessWidget {
  const _UnknownPage({
    Key? key,
    required this.onNavigateHome,
  }) : super(key: key);

  final VoidCallback onNavigateHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('404'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Sorry, this page doesn't exist!"),
            Link.tap(
              text: 'Return home',
              onTap: onNavigateHome,
            ),
          ],
        ),
      ),
    );
  }
}

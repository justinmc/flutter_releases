import 'package:flutter/material.dart';
import '../models/pr.dart';

class PRPage extends MaterialPage {
  PRPage({
    required this.pr,
  }) : super(
    key: const ValueKey('PRPage'),
    restorationId: 'home-page',
    child: _PRPage(
      pr: pr,
    ),
  );

  final PR pr;
}

class _PRPage extends StatelessWidget {
  const _PRPage({
    Key? key,
    required this.pr,
  }) : super(key: key);

  final PR pr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('This is a PR! TODO.'),
      ),
    );
  }
}


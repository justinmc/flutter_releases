import 'package:flutter/material.dart';
import '../api.dart' as api;
import '../models/pr.dart';

class HomePage extends MaterialPage {
  const HomePage() : super(
    key: const ValueKey('HomePage'),
    restorationId: 'home-page',
    child: const _HomePage(),
  );
}

class _HomePage extends StatefulWidget {
  const _HomePage({Key? key}) : super(key: key);

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  String? _error;
  PR? _pr;

  // TODO(justinmc): Accept prNumber or full URL.
  void _getPR(String prNumber) async {
    setState(() {
      _error = null;
    });

    late final PR localPR;
    try {
      localPR = await api.getPr(prNumber);
    } catch (error, stacktrace) {
      setState(() {
        _error = error.toString();
      });
      return;
    }

    setState(() {
      _pr = localPR;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Releases Info'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // TODO(justinmc): By default show info about latest releases.
            // From: https://docs.flutter.dev/development/tools/sdk/releases
            if (_pr == null)
              const Text('Enter a PR number or URL.'),
            // TODO(justinmc): Loading state.
            if (_pr == null)
              TextField(
                decoration: InputDecoration(
                  hintText: 'PR',
                  errorText: _error,
                ),
                onSubmitted: _getPR,
              ),
            if (_pr != null)
              Text("PR's merge commit is ${_pr!.mergeCommitSHA}"),
          ],
        ),
      ),
    );
  }
}


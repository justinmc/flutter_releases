import 'package:flutter/material.dart';
import '../api.dart' as api;
import '../models/branch.dart';
import '../models/pr.dart';

typedef PRCallback = void Function(PR pr);

class HomePage extends MaterialPage {
  HomePage({
    required final PRCallback onNavigateToPR,
    final Branch? stable,
    final Branch? beta,
    final Branch? master,
  }) : super(
    key: const ValueKey('HomePage'),
    restorationId: 'home-page',
    child: _HomePage(
      stable: stable,
      beta: beta,
      master: master,
      onNavigateToPR: onNavigateToPR,
    ),
  );
}

class _HomePage extends StatefulWidget {
  const _HomePage({
    Key? key,
    required final this.onNavigateToPR,
    final this.stable,
    final this.beta,
    final this.master,
  }) : super(key: key);

  final PRCallback onNavigateToPR;
  final Branch? stable;
  final Branch? beta;
  final Branch? master;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  String? _error;

  // TODO(justinmc): Accept prNumber or full URL.
  void _getPR(String prNumber) async {
    setState(() {
      _error = null;
    });

    // TODO(justinmc): Caching.
    late final PR localPR;
    try {
      localPR = await api.getPr(int.parse(prNumber));
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
      return;
    }

    widget.onNavigateToPR(localPR);
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
            // TODO(justinmc): Link to docs releases: https://docs.flutter.dev/development/tools/sdk/releases
            if (widget.stable == null)
              const Text('Loading stable release...'),
            if (widget.beta == null)
              const Text('Loading beta release...'),
            if (widget.master == null)
              const Text('Loading master release...'),
            if (widget.stable != null)
              _Branch(branch: widget.stable!),
            if (widget.beta != null)
              _Branch(branch: widget.beta!),
            if (widget.master != null)
              _Branch(branch: widget.master!),
            // From: https://docs.flutter.dev/development/tools/sdk/releases
            const Text('Enter a PR number or URL.'),
            // TODO(justinmc): Loading state.
            TextField(
              decoration: InputDecoration(
                hintText: 'PR',
                errorText: _error,
              ),
              onSubmitted: _getPR,
            ),
          ],
        ),
      ),
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({
    Key? key,
    required this.branch,
  }) : super(key: key);

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    // TODO(justinmc): Link this stuff.
    return Text('${branch.name}:  ${branch.sha} released ${branch.date}');
  }
}

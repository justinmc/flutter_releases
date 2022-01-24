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

  static const String _kEngineString = 'flutter/engine/pull/';
  static const String _kFrameworkString = 'flutter/flutter/pull/';

  // TODO(justinmc): Accept prNumber for flutter PRs too?
  void _getPR(String input) async {
    setState(() {
      _error = null;
    });

    String? enginePrUrl;
    final int engineLocation = input.lastIndexOf(_kEngineString);
    late PR localPR;

    try {
      // TODO(justinmc): Caching.
      if (engineLocation >= 0) {
        final int enginePrNumber = int.parse(input.substring(engineLocation + _kEngineString.length));
        localPR = await api.getRollPrFromEnginePr(enginePrNumber);
      } else {
        final int location = input.lastIndexOf(_kFrameworkString);
        final int prNumber = int.parse(input.substring(location + _kFrameworkString.length));
        localPR = await api.getPr(prNumber);
      }
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
      setState(() {
        _error = error.toString();
      });
      return;
    }

    // TODO(justinmc): PR page needs to actually get the engine PR and know the
    // difference.
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
            const Text('Enter a PR URL from the framework or engine.'),
            // TODO(justinmc): Loading state.
            TextField(
              decoration: InputDecoration(
                hintText: 'Github PR URL',
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

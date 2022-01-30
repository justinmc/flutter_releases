import 'package:flutter/material.dart';
import '../api.dart' as api;
import '../models/branch.dart';
import '../models/pr.dart';

typedef EnginePRCallback = void Function(EnginePR pr);
typedef PRCallback = void Function(PR pr);

class HomePage extends MaterialPage {
  HomePage({
    required final EnginePRCallback onNavigateToEnginePR,
    required final PRCallback onNavigateToFrameworkPR,
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
      onNavigateToEnginePR: onNavigateToEnginePR,
      onNavigateToFrameworkPR: onNavigateToFrameworkPR,
    ),
  );
}

class _HomePage extends StatefulWidget {
  const _HomePage({
    Key? key,
    required final this.onNavigateToEnginePR,
    required final this.onNavigateToFrameworkPR,
    final this.stable,
    final this.beta,
    final this.master,
  }) : super(key: key);

  final EnginePRCallback onNavigateToEnginePR;
  final PRCallback onNavigateToFrameworkPR;
  final Branch? stable;
  final Branch? beta;
  final Branch? master;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  String? _error;
  bool _loading = false;

  static const String _kEngineString = 'flutter/engine/pull/';
  static const String _kFrameworkString = 'flutter/flutter/pull/';

  // TODO(justinmc): Accept prNumber for flutter PRs too?
  void _onSubmittedPR(String input) async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final int engineLocation = input.lastIndexOf(_kEngineString);
    late PR localFrameworkPR;
    late EnginePR localEnginePR;
    final bool isEngine = engineLocation >= 0;

    try {
      // TODO(justinmc): Caching.
      if (isEngine) {
        final int enginePrNumber = int.parse(input.substring(engineLocation + _kEngineString.length));
        localEnginePR = await api.getEnginePR(enginePrNumber);
      } else {
        final int location = input.lastIndexOf(_kFrameworkString);
        if (location < 0) {
          throw ArgumentError('Not a valid PR URL.');
        }
        final int prNumber = int.parse(input.substring(location + _kFrameworkString.length));
        localFrameworkPR = await api.getPr(prNumber);
      }
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
      final String message = error is ArgumentError ? error.message : error.toString();
      setState(() {
        _error = message;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = false;
    });

    isEngine
        ? widget.onNavigateToEnginePR(localEnginePR)
        : widget.onNavigateToFrameworkPR(localFrameworkPR);
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
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: 'Github PR URL',
                errorText: _error,
              ),
              onSubmitted: _onSubmittedPR,
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

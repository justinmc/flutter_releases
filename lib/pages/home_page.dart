import 'package:flutter/material.dart';

import '../api.dart' as api;
import '../models/branch.dart';
import '../models/pr.dart';
import '../widgets/link.dart';

typedef EnginePRCallback = void Function(EnginePR pr);
typedef DartPRCallback = void Function(DartPR pr);
typedef DartGerritPRCallback = void Function(String url);
typedef PRCallback = void Function(PR pr);

class HomePage extends MaterialPage {
  HomePage({
    required final EnginePRCallback onNavigateToEnginePR,
    required final DartPRCallback onNavigateToDartPR,
    required final DartGerritPRCallback onNavigateToDartGerritPR,
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
      onNavigateToDartPR: onNavigateToDartPR,
      onNavigateToDartGerritPR: onNavigateToDartGerritPR,
      onNavigateToEnginePR: onNavigateToEnginePR,
      onNavigateToFrameworkPR: onNavigateToFrameworkPR,
    ),
  );
}

class _HomePage extends StatefulWidget {
  const _HomePage({
    Key? key,
    required this.onNavigateToDartPR,
    required this.onNavigateToDartGerritPR,
    required this.onNavigateToEnginePR,
    required this.onNavigateToFrameworkPR,
    this.stable,
    this.beta,
    this.master,
  }) : super(key: key);

  final DartPRCallback onNavigateToDartPR;
  final DartGerritPRCallback onNavigateToDartGerritPR;
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
  static const String _kDartString = 'dart-lang/sdk/pull/';
  static const String _kDartGerritString = 'dart-review.googlesource.com/c/sdk/+/';
  static const String _kFrameworkString = 'flutter/flutter/pull/';

  // TODO(justinmc): Accept prNumber for flutter PRs too?
  void _onSubmittedPR(String input) async {
    setState(() {
      _error = null;
      _loading = true;
    });

    late PR localFrameworkPR;

    /*
    // TODO(justinmc): Accept a plain framework PR number, not a full Github url.
    try {
      final int prNumber = int.parse(input);
      localFrameworkPR = await api.getPr(prNumber);
    } catch (error) {}
    */

    if (input.contains(_kDartGerritString)) {
      widget.onNavigateToDartGerritPR(input);
      return;
    }

    final int engineLocation = input.lastIndexOf(_kEngineString);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Latest '),
                Link(
                  text: 'releases',
                  uri: Uri.parse('https://docs.flutter.dev/development/tools/sdk/releases'),
                ),
                const Text(':'),
              ]
            ),
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
            // TODO(justinmc): Loading state.
            TextField(
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: 'Github PR URL (framework or engine)',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(branch.name),
        if (branch.tagName != null)
          Link(
            text: branch.tagName!,
            uri: branch.tagUri,
          ),
        const Text(' ('),
        Link(
          text: branch.shortSha,
          uri: branch.uri,
        ),
        const Text(') '),
        Text('released ${branch.formattedDate}'),
      ],
    );
  }
}

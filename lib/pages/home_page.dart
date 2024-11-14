import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_repo_info/widgets/settings_dialog_home.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/link.dart' as url_launcher_link;

import '../api.dart' as api;
//import '../github_oauth_credentials.dart';
import '../models/branch.dart';
import '../models/branches.dart';
import '../models/pr.dart';
import '../providers/branches_provider.dart';
//import '../widgets/github_login.dart';
import '../widgets/link.dart';
import '../widgets/settings_dialog.dart';

typedef EnginePRCallback = void Function(EnginePR pr);
typedef DartPRCallback = void Function(DartPR pr);
typedef DartGerritPRCallback = void Function(String url);
typedef PRCallback = void Function(PR pr);

class HomePage extends MaterialPage {
  HomePage({
    required BrightnessSetting brightnessSetting,
    required final EnginePRCallback onNavigateToEnginePR,
    required final DartPRCallback onNavigateToDartPR,
    required final DartGerritPRCallback onNavigateToDartGerritPR,
    required final ValueChanged<BrightnessSetting> onChangeBrightnessSetting,
    required final PRCallback onNavigateToFrameworkPR,
  }) : super(
    key: const ValueKey('HomePage'),
    restorationId: 'home-page',
    child: _HomePage(
      brightnessSetting: brightnessSetting,
      onChangeBrightnessSetting: onChangeBrightnessSetting,
      onNavigateToDartPR: onNavigateToDartPR,
      onNavigateToDartGerritPR: onNavigateToDartGerritPR,
      onNavigateToEnginePR: onNavigateToEnginePR,
      onNavigateToFrameworkPR: onNavigateToFrameworkPR,
    ),
  );
}

class _HomePage extends ConsumerStatefulWidget {
  const _HomePage({
    required this.brightnessSetting,
    required this.onChangeBrightnessSetting,
    required this.onNavigateToDartPR,
    required this.onNavigateToDartGerritPR,
    required this.onNavigateToEnginePR,
    required this.onNavigateToFrameworkPR,
  });

  final BrightnessSetting brightnessSetting;
  final ValueChanged<BrightnessSetting> onChangeBrightnessSetting;
  final DartPRCallback onNavigateToDartPR;
  final DartGerritPRCallback onNavigateToDartGerritPR;
  final EnginePRCallback onNavigateToEnginePR;
  final PRCallback onNavigateToFrameworkPR;

  @override
  ConsumerState<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<_HomePage>  {
  String? _error;
  bool _loading = false;
  final FocusNode _urlFieldFocusNode = FocusNode();

  static const String _kEngineString = 'flutter/engine/pull/';
  static const String _kDartString = 'dart-lang/sdk/pull/'; // e.g. https://github.com/dart-lang/sdk/pull/51494
  static const String _kDartGerritString = 'dart-review.googlesource.com/c/sdk/+/'; // e.g. https://dart-review.googlesource.com/c/sdk/+/284741
  static const String _kFrameworkString = 'flutter/flutter/pull/';

  // TODO(justinmc): Accept prNumber for flutter PRs too?
  void _onSubmittedPR(String input) async {
    setState(() {
      _error = null;
      _loading = true;
    });

    if (input.contains(_kDartGerritString)) {
      widget.onNavigateToDartGerritPR(input);
      return;
    }

    final int dartLocation = input.lastIndexOf(_kDartString);
    final int engineLocation = input.lastIndexOf(_kEngineString);
    late final EnginePR? localEnginePR;
    late final DartPR? localDartPR;
    late final PR? localFrameworkPR;
    final bool isEngine = engineLocation >= 0;
    final bool isDart = dartLocation >= 0;

    try {
      // TODO(justinmc): Caching.
      if (isEngine) {
        final int enginePrNumber = int.parse(input.substring(engineLocation + _kEngineString.length));
        localEnginePR = await api.getEnginePR(enginePrNumber);
      } else if (isDart) {
        final int dartPrNumber = int.parse(input.substring(dartLocation + _kDartString.length));
        localDartPR = await api.getDartPR(dartPrNumber);
      } else {
        final int location = input.lastIndexOf(_kFrameworkString);
        final int prNumber = location < 0
            // Plain PR number.
            ? int.parse(input)
            // PR URL.
            : int.parse(input.substring(location + _kFrameworkString.length));
        localFrameworkPR = await api.getPr(prNumber);
      }
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
      final String message;
      if (error is ArgumentError) {
        message = error.message;
      } else if (error is AssertionError) {
        message = error.message?.toString() ?? error.toString();
      } else {
        message = error.toString();
      }
      setState(() {
        _error = 'Not a valid PR URL or number. $message';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = false;
    });

    if (isEngine) {
      widget.onNavigateToEnginePR(localEnginePR!);
    } else if (isDart) {
      widget.onNavigateToDartPR(localDartPR!);
    } else {
      widget.onNavigateToFrameworkPR(localFrameworkPR!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Branches branches = ref.watch(branchesProvider);

    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Releases Info'),
          actions: <Widget>[
            url_launcher_link.Link(
              uri: Uri.parse('https://www.github.com/justinmc/flutter_releases'),
              target: url_launcher_link.LinkTarget.blank,
              builder: (BuildContext context, url_launcher_link.FollowLink? followLink) {
                return IconButton(
                  icon: const Icon(Icons.code),
                  tooltip: 'GitHub',
                  onPressed: followLink,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => SettingsDialog(
                    brightnessSetting: widget.brightnessSetting,
                    onChangeBrightnessSetting: widget.onChangeBrightnessSetting,
                  ),
                );
              },
            ),
            /*
             // TODO(justinmc): Disabled for prod. Do I want to do this?
            GithubLoginWidget(
              githubClientId: githubClientId,
              githubClientSecret: githubClientSecret,
              githubScopes: githubScopes,
              builder: (BuildContext context, httpClient) {
                return const SizedBox.shrink();
              },
            ),
            */
            /*
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Login to GitGub',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is a snackbar')));
              },
            ),
            */
          ],
        ),
        body: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.slash): () {
              _urlFieldFocusNode.requestFocus();
            },
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Center(
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
                  if (branches.stable == null)
                    const Text('Loading stable release...'),
                  if (branches.beta == null)
                    const Text('Loading beta release...'),
                  if (branches.master == null)
                    const Text('Loading master release...'),
                  if (branches.stable != null)
                    _Branch(branch: branches.stable!),
                  if (branches.beta != null)
                    _Branch(branch: branches.beta!),
                  if (branches.master != null)
                    _Branch(branch: branches.master!),
                  // TODO(justinmc): Loading state.
                  Shortcuts(
                    shortcuts: const <ShortcutActivator, Intent>{
                      SingleActivator(LogicalKeyboardKey.slash): DoNothingAndStopPropagationIntent(),
                    },
                    child: TextField(
                      autofocus: true,
                      focusNode: _urlFieldFocusNode,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        hintText: 'Github PR URL (framework or engine)',
                        errorText: _error,
                      ),
                      onSubmitted: _onSubmittedPR,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({
    required this.branch,
  });

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('${branch.name} '),
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

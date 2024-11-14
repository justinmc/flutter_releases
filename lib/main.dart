import 'package:flutter/material.dart';
import 'package:flutter_repo_info/widgets/settings_dialog_home.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ReleasesApp(),
    ),
  );
}

class ReleasesApp extends ConsumerStatefulWidget {
  const ReleasesApp({
    super.key,
  });

  @override
  ConsumerState<ReleasesApp> createState() => _ReleasesAppState();
}

class _ReleasesAppState extends ConsumerState<ReleasesApp> {
  late final ReleasesRouterDelegate _routerDelegate;
  final ReleasesRouteInformationParser _routeInformationParser =
      ReleasesRouteInformationParser();
      // TODO(justinmc): Save this in shared preferences.
  BrightnessSetting _brightnessSetting = BrightnessSetting.platform;

  _onChangeBrightnessSetting(BrightnessSetting value) {
    setState(() {
      _brightnessSetting = value;
      // TODO(justinmc): Should use state management instead of this hack, and
      // really all of this piping.
      _routerDelegate.brightnessSetting = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _routerDelegate = ReleasesRouterDelegate(
      brightnessSetting: _brightnessSetting,
      onChangeBrightnessSetting: _onChangeBrightnessSetting,
      ref: ref,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'root',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: switch (_brightnessSetting) {
          BrightnessSetting.platform => MediaQuery.platformBrightnessOf(context),
          BrightnessSetting.light => Brightness.light,
          BrightnessSetting.dark => Brightness.dark,
        },
        //brightness: brightness ?? MediaQuery.platformBrightnessOf(context),
      ),
      title: 'Flutter Releases',
    );
  }
}

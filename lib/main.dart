import 'package:shared_preferences/shared_preferences.dart';

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
  BrightnessSetting _brightnessSetting = BrightnessSetting.platform;

  _onChangeBrightnessSetting(BrightnessSetting value) async {
    setState(() {
      _brightnessSetting = value;
      // TODO(justinmc): Should use state management instead of this hack, and
      // really all of this piping.
      _routerDelegate.brightnessSetting = value;
    });

    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    switch (value) {
      case BrightnessSetting.dark:
        await sharedPreferences.setBool('darkMode', true);
      case BrightnessSetting.light:
        await sharedPreferences.setBool('darkMode', false);
      case BrightnessSetting.platform:
        await sharedPreferences.remove('darkMode');
    }
  }

  @override
  void initState() {
    super.initState();
    _routerDelegate = ReleasesRouterDelegate(
      brightnessSetting: _brightnessSetting,
      onChangeBrightnessSetting: _onChangeBrightnessSetting,
      ref: ref,
    );

    SharedPreferences.getInstance().then((SharedPreferences sharedPreferences) {
      setState(() {
        _brightnessSetting = switch (sharedPreferences.getBool('darkMode')) {
          true => BrightnessSetting.dark,
          false => BrightnessSetting.light,
          null => BrightnessSetting.platform,
        };
        _routerDelegate.brightnessSetting = _brightnessSetting;
      });
    });
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
      ),
      title: 'Flutter Releases',
    );
  }
}

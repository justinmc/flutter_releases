import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals_flutter.dart';

import 'router.dart';
import 'signal_model.dart';
import 'models/brightness_setting.dart';

void main() {
  runApp(
    const ReleasesApp(),
  );
}

class ReleasesApp extends StatefulWidget {
  const ReleasesApp({
    super.key,
  });

  @override
  State<ReleasesApp> createState() => _ReleasesAppState();
}

class _ReleasesAppState extends State<ReleasesApp> {
  late final ReleasesRouterDelegate _routerDelegate;
  final ReleasesRouteInformationParser _routeInformationParser =
      ReleasesRouteInformationParser();

  final FlutterSignal<BrightnessSetting> _brightnessSettingSignal =
      signal(BrightnessSetting.platform);

  void _onChangeBrightnessSetting() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    switch (_brightnessSettingSignal.value) {
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
    _routerDelegate = ReleasesRouterDelegate();
    _brightnessSettingSignal.addListener(_onChangeBrightnessSetting);

    SharedPreferences.getInstance().then((SharedPreferences sharedPreferences) {
      _brightnessSettingSignal.value =
          switch (sharedPreferences.getBool('darkMode')) {
        true => BrightnessSetting.dark,
        false => BrightnessSetting.light,
        null => BrightnessSetting.platform,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignalModel(
      branchesSignal: _routerDelegate.branchesSignal,
      brightnessSettingSignal: _brightnessSettingSignal,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        restorationScopeId: 'root',
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeInformationParser,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: switch (_brightnessSettingSignal.watch(context)) {
            BrightnessSetting.platform =>
              MediaQuery.platformBrightnessOf(context),
            BrightnessSetting.light => Brightness.light,
            BrightnessSetting.dark => Brightness.dark,
          },
        ),
        title: 'Flutter Releases',
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'router.dart';

void main() {
  runApp(const ReleasesApp());
}

class ReleasesApp extends StatefulWidget {
  const ReleasesApp({
    Key? key,
  }) : super(key: key);

  @override
  _ReleasesAppState createState() => _ReleasesAppState();
}

class _ReleasesAppState extends State<ReleasesApp> {
  final ReleasesRouterDelegate _routerDelegate = ReleasesRouterDelegate();
  final ReleasesRouteInformationParser _routeInformationParser =
      ReleasesRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: 'root',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      title: 'Flutter Releases',
    );
  }
}

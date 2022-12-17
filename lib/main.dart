import 'package:flutter/material.dart';
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
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ReleasesApp> createState() => _ReleasesAppState();
}

class _ReleasesAppState extends ConsumerState<ReleasesApp> {
  late final ReleasesRouterDelegate _routerDelegate;
  final ReleasesRouteInformationParser _routeInformationParser =
      ReleasesRouteInformationParser();

  @override
  void initState() {
    super.initState();
    _routerDelegate = ReleasesRouterDelegate(ref: ref);
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
      ),
      title: 'Flutter Releases',
    );
  }
}

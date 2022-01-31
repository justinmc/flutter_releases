import 'package:flutter/material.dart';
import 'models/pr.dart';
import 'models/branch.dart';
import 'pages/home_page.dart';
import 'pages/pr_page.dart';
import 'pages/unknown_page.dart';
import 'api.dart' as api;

enum ReleasesPage {
  unknown,
  home,
  enginePR,
  frameworkPR,
}

class ReleasesRoutePath {
  final int? prNumber;
  final ReleasesPage page;

  ReleasesRoutePath.home()
      : prNumber = null,
        page = ReleasesPage.home;

  ReleasesRoutePath.enginePR(this.prNumber)
      : page = ReleasesPage.enginePR;

  ReleasesRoutePath.frameworkPR(this.prNumber)
      : page = ReleasesPage.frameworkPR;

  ReleasesRoutePath.unknown()
      : prNumber = null,
        page = ReleasesPage.unknown;
}

class ReleasesRouteInformationParser extends RouteInformationParser<ReleasesRoutePath> {
  @override
  Future<ReleasesRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);

    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return ReleasesRoutePath.home();
    }

    // Handle '/pr/engineorframework/:prNumber'
    if (uri.pathSegments.length == 3) {
      if (uri.pathSegments[0] != 'pr') {
        return ReleasesRoutePath.unknown();
      }

      if (uri.pathSegments[1] == 'engine') {
        late final int prNumber;
        try {
          prNumber = int.parse(uri.pathSegments[2]);
        } catch (error) {
          return ReleasesRoutePath.unknown();
        }

        return ReleasesRoutePath.enginePR(prNumber);
      } else if (uri.pathSegments[1] == 'framework') {
        late final int prNumber;
        try {
          prNumber = int.parse(uri.pathSegments[1]);
        } catch (error) {
          return ReleasesRoutePath.unknown();
        }

        return ReleasesRoutePath.frameworkPR(prNumber);
      }

      return ReleasesRoutePath.unknown();
    }

    // Handle unknown routes
    return ReleasesRoutePath.unknown();
  }

  @override
  RouteInformation? restoreRouteInformation(ReleasesRoutePath configuration) {
    if (configuration.page == ReleasesPage.unknown) {
      return const RouteInformation(location: '/404');
    }
    if (configuration.page == ReleasesPage.home) {
      return const RouteInformation(location: '/');
    }
    if (configuration.page == ReleasesPage.frameworkPR) {
      return RouteInformation(location: '/pr/framework/${configuration.prNumber}');
    }
    if (configuration.page == ReleasesPage.enginePR) {
      return RouteInformation(location: '/pr/engine/${configuration.prNumber}');
    }
    return null;
  }
}

class ReleasesRouterDelegate extends RouterDelegate<ReleasesRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ReleasesRoutePath> {

  ReleasesRouterDelegate({
    this.enginePR,
    this.frameworkPR,
    this.page = ReleasesPage.home,
  }) : navigatorKey = GlobalKey<NavigatorState>();

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  ReleasesPage page;
  PR? frameworkPR;
  EnginePR? enginePR;
  Branch? stable;
  Branch? beta;
  Branch? master;

  @override
  ReleasesRoutePath get currentConfiguration {
    if (page == ReleasesPage.unknown) {
      return ReleasesRoutePath.unknown();
    }
    assert(!(page == ReleasesPage.frameworkPR && frameworkPR == null));
    assert(!(page == ReleasesPage.enginePR && enginePR == null));
    switch (page) {
      case ReleasesPage.home:
        return ReleasesRoutePath.home();
      case ReleasesPage.frameworkPR:
        return ReleasesRoutePath.frameworkPR(frameworkPR!.number);
      case ReleasesPage.enginePR:
        return ReleasesRoutePath.enginePR(enginePR!.number);
      case ReleasesPage.unknown:
        return ReleasesRoutePath.unknown();
    }
  }

  void onNavigateHome() {
    frameworkPR = null;
    enginePR = null;
    page = ReleasesPage.home;
    notifyListeners();
  }

  void onNavigateToEnginePR(EnginePR selectedPR) {
    frameworkPR = null;
    enginePR = selectedPR;
    page = ReleasesPage.enginePR;
    notifyListeners();
  }

  void onNavigateToFrameworkPR(PR selectedPR) {
    frameworkPR = selectedPR;
    enginePR = null;
    page = ReleasesPage.frameworkPR;
    notifyListeners();
  }

  // TODO(justinmc): Make sure state restoration works.
  /*
  @override
  Future<void> setInitialRoutePath(ReleasesRoutePath configuration) {
    return setNewRoutePath(configuration);
  }
  */

  @override
  Future<void> setNewRoutePath(final ReleasesRoutePath configuration) async {
    if (configuration.page == ReleasesPage.unknown) {
      enginePR = null;
      frameworkPR = null;
      page = ReleasesPage.unknown;
      return;
    }

    if (configuration.page == ReleasesPage.enginePR) {
      page = ReleasesPage.enginePR;

      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        return;
      }

      try {
        enginePR = await api.getEnginePR(configuration.prNumber!);
      } catch (error) {
        page = ReleasesPage.unknown;
      }
      frameworkPR = null;
      return;
    }

    if (configuration.page == ReleasesPage.frameworkPR) {
      page = ReleasesPage.frameworkPR;

      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        return;
      }

      try {
        frameworkPR = await api.getPr(configuration.prNumber!);
      } catch (error) {
        page = ReleasesPage.unknown;
      }
      enginePR = null;
      return;
    }

    enginePR = null;
    frameworkPR = null;
    page = ReleasesPage.home;
    try {
      // TODO(justinmc): Should fetch this for PRPages too. I need some state management.
      stable = await api.getBranch(BranchNames.stable);
      beta = await api.getBranch(BranchNames.beta);
      master = await api.getBranch(BranchNames.master);
    } catch (error) {
      print(error);
      // TODO(justinmc): Actually this should be an error on the home page.
      page = ReleasesPage.unknown;
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      restorationScopeId: 'root',
      pages: <Page>[
        HomePage(
          stable: stable,
          beta: beta,
          master: master,
          onNavigateToEnginePR: onNavigateToEnginePR,
          onNavigateToFrameworkPR: onNavigateToFrameworkPR,
        ),
        if (page == ReleasesPage.unknown)
          UnknownPage(
            onNavigateHome: onNavigateHome,
          ),
        if (page == ReleasesPage.enginePR)
          EnginePRPage(
            pr: enginePR!,
            stable: stable,
            beta: beta,
            master: master,
          ),
        if (page == ReleasesPage.frameworkPR)
          FrameworkPRPage(
            pr: frameworkPR!,
            stable: stable,
            beta: beta,
            master: master,
          ),
      ],
      onPopPage: (Route<dynamic> route, dynamic result) {
        if (!route.didPop(result)) {
          return false;
        }

        enginePR = null;
        frameworkPR = null;
        page = ReleasesPage.home;
        notifyListeners();

        return true;
      },
    );
  }
}

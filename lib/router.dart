import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/pr.dart';
import 'models/branch.dart';
import 'pages/home_page.dart';
import 'pages/pr_page.dart';
import 'pages/unknown_page.dart';
import 'providers/branches_provider.dart';
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
  SynchronousFuture<ReleasesRoutePath> parseRouteInformation(RouteInformation routeInformation) {
    final uri = Uri.parse(routeInformation.location!);

    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return SynchronousFuture(ReleasesRoutePath.home());
    }

    // Handle '/pr/engineorframework/:prNumber'
    if (uri.pathSegments.length == 3) {
      if (uri.pathSegments[0] != 'pr') {
        return SynchronousFuture(ReleasesRoutePath.unknown());
      }

      if (uri.pathSegments[1] == 'engine') {
        late final int prNumber;
        try {
          prNumber = int.parse(uri.pathSegments[2]);
        } catch (error) {
          return SynchronousFuture(ReleasesRoutePath.unknown());
        }

        return SynchronousFuture(ReleasesRoutePath.enginePR(prNumber));
      } else if (uri.pathSegments[1] == 'framework') {
        late final int prNumber;
        try {
          prNumber = int.parse(uri.pathSegments[1]);
        } catch (error) {
          return SynchronousFuture(ReleasesRoutePath.unknown());
        }

        return SynchronousFuture(ReleasesRoutePath.frameworkPR(prNumber));
      }

      return SynchronousFuture(ReleasesRoutePath.unknown());
    }

    // Handle unknown routes
    return SynchronousFuture(ReleasesRoutePath.unknown());
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
    //this.page = ReleasesPage.home,
    required this.ref,
  }) : navigatorKey = GlobalKey<NavigatorState>();

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  final WidgetRef ref;

  ReleasesPage? page;
  PR? frameworkPR;
  EnginePR? enginePR;
  Branch? stable;
  Branch? beta;
  Branch? master;
  int? loadingPRNumber;

  @override
  ReleasesRoutePath get currentConfiguration {
    if (page == ReleasesPage.unknown) {
      return ReleasesRoutePath.unknown();
    }
    switch (page) {
      case ReleasesPage.home:
        return ReleasesRoutePath.home();
      case ReleasesPage.frameworkPR:
        return ReleasesRoutePath.frameworkPR(frameworkPR?.number ?? loadingPRNumber!);
      case ReleasesPage.enginePR:
        return ReleasesRoutePath.enginePR(enginePR?.number ?? loadingPRNumber);
      case ReleasesPage.unknown:
      case null:
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

  Future<void> _getBranches() async {
    // TODO(justinmc): Do I still need the local branches variables or just use the provider?
    stable = await api.getBranch(BranchNames.stable);
    ref.read(branchesProvider.notifier).stable = stable;
    beta = await api.getBranch(BranchNames.beta);
    ref.read(branchesProvider.notifier).beta = beta;
    master = await api.getBranch(BranchNames.master);
    ref.read(branchesProvider.notifier).master = master;
  }

  @override
  Future<void> setNewRoutePath(final ReleasesRoutePath configuration) async {
    if (configuration.page == ReleasesPage.unknown) {
      enginePR = null;
      frameworkPR = null;
      page = ReleasesPage.unknown;
      return;
    }

    if (configuration.page == ReleasesPage.enginePR) {
      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        return;
      }
      page = ReleasesPage.enginePR;

      try {
        _getBranches();
        loadingPRNumber = configuration.prNumber!;
        enginePR = await api.getEnginePR(configuration.prNumber!);
        loadingPRNumber = null;
      } catch (error) {
        page = ReleasesPage.unknown;
        return;
      }
      frameworkPR = null;
      return;
    }

    if (configuration.page == ReleasesPage.frameworkPR) {
      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        return;
      }
      page = ReleasesPage.frameworkPR;

      try {
        _getBranches();
        loadingPRNumber = configuration.prNumber!;
        frameworkPR = await api.getPr(configuration.prNumber!);
        loadingPRNumber = null;
      } catch (error) {
        loadingPRNumber = null;
        page = ReleasesPage.unknown;
        return;
      }
      enginePR = null;
      return;
    }

    enginePR = null;
    frameworkPR = null;
    page = ReleasesPage.home;
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
          PRPage(
            pr: enginePR,
          ),
        if (page == ReleasesPage.frameworkPR)
          PRPage(
            pr: frameworkPR,
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

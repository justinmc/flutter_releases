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
  pr,
}

class ReleasesRoutePath {
  final int? prNumber;
  final ReleasesPage page;

  ReleasesRoutePath.home()
      : prNumber = null,
        page = ReleasesPage.home;

  ReleasesRoutePath.pr(this.prNumber)
      : page = ReleasesPage.pr;

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

    // Handle '/pr/:prNumber'
    if (uri.pathSegments.length == 2) {
      if (uri.pathSegments[0] != 'pr') {
        return ReleasesRoutePath.unknown();
      }

      late final int prNumber;
      try {
        prNumber = int.parse(uri.pathSegments[1]);
      } catch (error) {
        return ReleasesRoutePath.unknown();
      }

      return ReleasesRoutePath.pr(prNumber);
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
    if (configuration.page == ReleasesPage.pr) {
      return RouteInformation(location: '/pr/${configuration.prNumber}');
    }
    return null;
  }
}

class ReleasesRouterDelegate extends RouterDelegate<ReleasesRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ReleasesRoutePath> {

  ReleasesRouterDelegate({
    this.pr,
    this.page = ReleasesPage.home,
  }) : navigatorKey = GlobalKey<NavigatorState>();

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  ReleasesPage page;
  PR? pr;
  Branch? stable;
  Branch? beta;
  Branch? master;

  @override
  ReleasesRoutePath get currentConfiguration {
    if (page == ReleasesPage.unknown) {
      return ReleasesRoutePath.unknown();
    }
    assert(pr != null || page != ReleasesPage.pr);
    return page == ReleasesPage.pr
        ? ReleasesRoutePath.pr(pr!.number)
        : ReleasesRoutePath.home();
  }

  void onNavigateToPR(PR selectedPR) {
    pr = selectedPR;
    page = ReleasesPage.pr;
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
      pr = null;
      page = ReleasesPage.unknown;
      return;
    }

    if (configuration.page == ReleasesPage.pr) {
      page = ReleasesPage.pr;

      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        return;
      }

      try {
        pr = await api.getPr(configuration.prNumber!);
      } catch (error) {
        page = ReleasesPage.unknown;
      }
      return;
    }

    pr = null;
    page = ReleasesPage.home;
    try {
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
          onNavigateToPR: onNavigateToPR,
        ),
        if (page == ReleasesPage.unknown)
          const UnknownPage(),
        if (page == ReleasesPage.pr)
          PRPage(
            pr: pr!,
          ),
      ],
      onPopPage: (Route<dynamic> route, dynamic result) {
        if (!route.didPop(result)) {
          return false;
        }

        pr = null;
        page = ReleasesPage.home;
        notifyListeners();

        return true;
      },
    );
  }
}

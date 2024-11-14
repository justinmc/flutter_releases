import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/pr.dart';
import 'models/branch.dart';
import 'models/branches.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/pr_page.dart';
import 'pages/unknown_page.dart';
import 'providers/branches_provider.dart';
import 'widgets/github_login.dart';
import 'widgets/settings_dialog_home.dart';
import 'api.dart' as api;
import 'github_oauth_credentials.dart';

enum ReleasesPage {
  auth,
  unknown,
  home,
  dartPR,
  enginePR,
  frameworkPR,
}

class ReleasesRoutePath {
  final int? prNumber;
  final ReleasesPage page;
  final String? authCode;

  ReleasesRoutePath.home()
      : prNumber = null,
        authCode = null,
        page = ReleasesPage.home;

  ReleasesRoutePath.enginePR(this.prNumber)
      : page = ReleasesPage.enginePR,
        authCode = null;

  ReleasesRoutePath.dartPR(this.prNumber)
      : page = ReleasesPage.dartPR,
        authCode = null;

  ReleasesRoutePath.frameworkPR(this.prNumber)
      : page = ReleasesPage.frameworkPR,
        authCode = null;

  ReleasesRoutePath.auth(this.authCode)
      : prNumber = null,
        page = ReleasesPage.auth;

  ReleasesRoutePath.unknown()
      : prNumber = null,
        authCode = null,
        page = ReleasesPage.unknown;
}

class ReleasesRouteInformationParser extends RouteInformationParser<ReleasesRoutePath> {
  @override
  SynchronousFuture<ReleasesRoutePath> parseRouteInformation(RouteInformation routeInformation) {
    final Uri uri = Uri.parse(routeInformation.location!);

    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return SynchronousFuture(ReleasesRoutePath.home());
    }

    // Handle '/auth'
    if (uri.pathSegments[0] == 'auth') {
      final String? code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        return SynchronousFuture(ReleasesRoutePath.unknown());
      }
      return SynchronousFuture(ReleasesRoutePath.auth(code));
    }

    // Handle '/pr/engineorframeworkordart/:prNumber'
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
      } else if (uri.pathSegments[1] == 'dart') {
        late final int prNumber;
        try {
          prNumber = int.parse(uri.pathSegments[2]);
        } catch (error) {
          return SynchronousFuture(ReleasesRoutePath.unknown());
        }

        return SynchronousFuture(ReleasesRoutePath.dartPR(prNumber));
      } else if (uri.pathSegments[1] == 'framework') {
        late final int prNumber;
        try {
          prNumber = int.parse(uri.pathSegments[2]);
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
      return RouteInformation(uri: Uri.parse('/404'));
    }
    if (configuration.page == ReleasesPage.home) {
      return RouteInformation(uri: Uri.parse('/'));
    }
    if (configuration.page == ReleasesPage.auth) {
      return RouteInformation(uri: Uri.parse('/auth?code=${configuration.authCode}'));
    }
    if (configuration.page == ReleasesPage.frameworkPR) {
      return RouteInformation(uri: Uri.parse('/pr/framework/${configuration.prNumber}'));
    }
    if (configuration.page == ReleasesPage.enginePR) {
      return RouteInformation(uri: Uri.parse('/pr/engine/${configuration.prNumber}'));
    }
    if (configuration.page == ReleasesPage.dartPR) {
      return RouteInformation(uri: Uri.parse('/pr/dart/${configuration.prNumber}'));
    }
    return null;
  }
}

class ReleasesRouterDelegate extends RouterDelegate<ReleasesRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ReleasesRoutePath> {

  ReleasesRouterDelegate({
    this.authCode,
    this.dartPR,
    this.enginePR,
    this.frameworkPR,
    //this.page = ReleasesPage.home,
    required this.ref,
    required this.brightnessSetting,
    required this.onChangeBrightnessSetting,
  }) : navigatorKey = GlobalKey<NavigatorState>();

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  BrightnessSetting brightnessSetting;
  final WidgetRef ref;
  final ValueChanged<BrightnessSetting> onChangeBrightnessSetting;

  ReleasesPage? page;
  Object? error;
  PR? frameworkPR;
  EnginePR? enginePR;
  DartPR? dartPR;
  int? loadingPRNumber;
  String? authCode;

  // TODO(justinmc): When navigating back via the back button, where am I
  // supposed to reload the new page's state? E.g. calling getBranches for
  // navigating back to the home page from 404.

  // TODO(justinmc): If I go to a PR page and then refresh, it redirects me to
  // 404. Why?

  @override
  ReleasesRoutePath get currentConfiguration {
    if (page == ReleasesPage.unknown) {
      return ReleasesRoutePath.unknown();
    }
    switch (page) {
      case ReleasesPage.home:
        return ReleasesRoutePath.home();
      case ReleasesPage.auth:
        return ReleasesRoutePath.auth(authCode);
      case ReleasesPage.frameworkPR:
        return ReleasesRoutePath.frameworkPR(frameworkPR?.number ?? loadingPRNumber!);
      case ReleasesPage.enginePR:
        return ReleasesRoutePath.enginePR(enginePR?.number ?? loadingPRNumber);
      case ReleasesPage.dartPR:
        return ReleasesRoutePath.dartPR(dartPR?.number ?? loadingPRNumber);
      case ReleasesPage.unknown:
      case null:
        return ReleasesRoutePath.unknown();
    }
  }

  void onNavigateHome() async {
    frameworkPR = null;
    enginePR = null;
    page = ReleasesPage.home;
    final Branches branches = ref.read(branchesProvider);

    if (branches.stable == null || branches.beta == null || branches.master == null) {
      try {
        await _getBranches();
      } catch (error) {
        print(error);
        page = ReleasesPage.unknown;
        this.error = error;
        return;
      }
    }

    error = null;
    notifyListeners();
  }

  void onNavigateToDartGerritPR(String url) {
    frameworkPR = null;
    enginePR = null;
    page = ReleasesPage.unknown;
    error = "You've entered a Dart PR from Gerrit, which unfortunately isn't supported right now!  Your best bet is to find the engine Dart roll PR that contains the change you want, and paste in that URL (e.g. https://github.com/flutter/engine/pull/39767).";
    notifyListeners();
  }

  void onNavigateToDartPR(DartPR selectedPR) {
    frameworkPR = null;
    enginePR = null;
    dartPR = selectedPR;
    page = ReleasesPage.dartPR;
    error = null;
    notifyListeners();
  }

  void onNavigateToEnginePR(EnginePR selectedPR) {
    frameworkPR = null;
    enginePR = selectedPR;
    dartPR = null;
    page = ReleasesPage.enginePR;
    error = null;
    notifyListeners();
  }

  void onNavigateToFrameworkPR(PR selectedPR) {
    frameworkPR = selectedPR;
    enginePR = null;
    dartPR = null;
    page = ReleasesPage.frameworkPR;
    error = null;
    notifyListeners();
  }

  // TODO(justinmc): Make sure state restoration works.
  /*
  @override
  Future<void> setInitialRoutePath(ReleasesRoutePath configuration) {
    print('justin setInitialRoutePath $configuration');
    return super.setInitialRoutePath(configuration);
    //return setNewRoutePath(configuration);
  }
  */

  Future<void> _getBranches() async {
    ref.read(branchesProvider.notifier).stable = await api.getBranch(BranchNames.stable);
    ref.read(branchesProvider.notifier).beta = await api.getBranch(BranchNames.beta);
    ref.read(branchesProvider.notifier).master = await api.getBranch(BranchNames.master);
  }

  @override
  Future<void> setNewRoutePath(final ReleasesRoutePath configuration) async {
    // TODO(justinmc): Rewrite this with switches.
    if (configuration.page == ReleasesPage.unknown) {
      authCode = null;
      enginePR = null;
      frameworkPR = null;
      page = ReleasesPage.unknown;
      return;
    }

    if (configuration.page == ReleasesPage.auth) {
      enginePR = null;
      frameworkPR = null;
      page = ReleasesPage.auth;
      authCode = configuration.authCode;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? grantString = prefs.getString('grant');
      print('justin grantString is $grantString');
      assert(grantString != null);
      final grantJson = jsonDecode(grantString!);
      print('justin recreating AuthorizationCodeGrant with $grantJson and JsonAcceptingHttpClient');
      final oauth2.AuthorizationCodeGrant grant = oauth2.AuthorizationCodeGrant(
        grantJson['githubClientId']!,
        Uri.parse(grantJson['authorizationEndpoint']!),
        Uri.parse(grantJson['tokenEndpoint']!),
        secret: grantJson['githubClientSecret']!,
        httpClient: JsonAcceptingHttpClient(),
      );
      grant.getAuthorizationUrl(
        Uri.parse(GithubLoginWidget.redirectEndpoint),
        scopes: githubScopes,
      );
      // TODO(justinmc): Here is where you are trying to get github oauth to work.
      // TODO(justinmc): Actually, this all won't work without a server. The
      // GitHub API server doesn't support CORS. You should do a middleman
      // caching server instead...
      print('justin handleAuthorizationResponse with code $authCode');
      final oauth2.Client client = await grant.handleAuthorizationResponse(<String, String>{
        'code': authCode!,
      });
      print('justin handleAuthorizationResponse returned');
      return;
    }
    authCode = null;

    if (configuration.page == ReleasesPage.enginePR) {
      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        error = null;
        return;
      }
      page = ReleasesPage.enginePR;
      error = null;

      try {
        await _getBranches();
        loadingPRNumber = configuration.prNumber!;
        enginePR = await api.getEnginePR(configuration.prNumber!);
        loadingPRNumber = null;
      } catch (error, stacktrace) {
        print(error);
        print(stacktrace);
        page = ReleasesPage.unknown;
        this.error = error;
        return;
      }
      frameworkPR = null;
      return;
    }

    if (configuration.page == ReleasesPage.dartPR) {
      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        error = null;
        return;
      }
      page = ReleasesPage.dartPR;
      error = null;

      try {
        await _getBranches();
        loadingPRNumber = configuration.prNumber!;
        dartPR = await api.getDartPR(configuration.prNumber!);
        loadingPRNumber = null;
      } catch (error, stacktrace) {
        print(error);
        print(stacktrace);
        page = ReleasesPage.unknown;
        this.error = error;
        return;
      }
      frameworkPR = null;
      return;
    }

    if (configuration.page == ReleasesPage.frameworkPR) {
      if (configuration.prNumber == null) {
        page = ReleasesPage.unknown;
        error = 'No PR number given.';
        return;
      }
      page = ReleasesPage.frameworkPR;
      error = null;

      try {
        loadingPRNumber = configuration.prNumber!;
        await _getBranches();
        frameworkPR = await api.getPr(configuration.prNumber!);
        loadingPRNumber = null;
      } catch (error, stacktrace) {
        print(error);
        print(stacktrace);
        loadingPRNumber = null;
        page = ReleasesPage.unknown;
        this.error = error;
        return;
      }
      enginePR = null;
      return;
    }

    enginePR = null;
    frameworkPR = null;
    page = ReleasesPage.home;
    try {
      await _getBranches();
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
      page = ReleasesPage.unknown;
      this.error = error;
      return;
    }
    error = null;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      restorationScopeId: 'root',
      pages: <Page>[
        HomePage(
          brightnessSetting: brightnessSetting,
          onChangeBrightnessSetting: onChangeBrightnessSetting,
          onNavigateToDartPR: onNavigateToDartPR,
          onNavigateToDartGerritPR: onNavigateToDartGerritPR,
          onNavigateToEnginePR: onNavigateToEnginePR,
          onNavigateToFrameworkPR: onNavigateToFrameworkPR,
        ),
        if (page == ReleasesPage.unknown)
          UnknownPage(
            onNavigateHome: onNavigateHome,
            error: error?.toString(),
          ),
        if (page == ReleasesPage.auth)
          AuthPage(
            authCode: authCode!,
            onNavigateHome: onNavigateHome,
          ),
        if (page == ReleasesPage.frameworkPR)
          PRPage(
            pr: frameworkPR,
          ),
        if (page == ReleasesPage.enginePR)
          PRPage(
            pr: enginePR,
          ),
        if (page == ReleasesPage.dartPR)
          PRPage(
            pr: dartPR,
          ),
      ],
      onPopPage: (Route<dynamic> route, dynamic result) {
        if (!route.didPop(result)) {
          return false;
        }

        authCode = null;
        enginePR = null;
        frameworkPR = null;
        error = null;
        page = ReleasesPage.home;
        notifyListeners();

        return true;
      },
    );
  }
}

import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GithubLoginWidget extends StatefulWidget {
  const GithubLoginWidget({
    required this.builder,
    required this.githubClientId,
    required this.githubClientSecret,
    required this.githubScopes,
    super.key,
  });
  final AuthenticatedBuilder builder;
  final String githubClientId;
  final String githubClientSecret;
  final List<String> githubScopes;

  static const String authorizationEndpoint =
      'https://github.com/login/oauth/authorize';
  static const String tokenEndpoint =
      'https://github.com/login/oauth/access_token';
  static const String redirectEndpoint = 'http://localhost:8080/auth';

  @override
  State<GithubLoginWidget> createState() => _GithubLoginState();
}

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client);

class _GithubLoginState extends State<GithubLoginWidget> {
  oauth2.Client? _client;

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client != null) {
      return widget.builder(context, client);
    }

    return IconButton(
      icon: const Icon(Icons.login),
      tooltip: 'Login to GitHub',
      onPressed: () async {
        //oauth2.Client authenticatedHttpClient = await createClient(
        createClient(
          Uri.parse('http://localhost:8080/auth'),
        );
        /*
        oauth2.Client authenticatedHttpClient = await _getOAuth2Client(
          Uri.parse('http://localhost:8080/auth'),
        );
        setState(() {
          _client = authenticatedHttpClient;
        });
        */
      },
    );
  }

  /*
  Future<oauth2.Client> _getOAuth2Client(Uri redirectUrl) async {
    if (widget.githubClientId.isEmpty || widget.githubClientSecret.isEmpty) {
      throw const GithubLoginException(
          'githubClientId and githubClientSecret must be not empty. '
          'See `lib/github_oauth_credentials.dart` for more detail.');
    }
    var grant = oauth2.AuthorizationCodeGrant(
      widget.githubClientId,
      _authorizationEndpoint,
      _tokenEndpoint,
      secret: widget.githubClientSecret,
      httpClient: _JsonAcceptingHttpClient(),
    );
    var authorizationUrl =
        grant.getAuthorizationUrl(redirectUrl, scopes: widget.githubScopes);

    await _redirect(authorizationUrl);
    var responseQueryParameters = await _listen();
    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);
    return client;
  }
  */

  void createClient(Uri redirectUri) async {
  //Future<oauth2.Client> createClient(Uri redirectUri) async {
    /*
    var exists = await credentialsFile.exists();

    // If the OAuth2 credentials have already been saved from a previous run, we
    // just want to reload them.
    if (exists) {
      var credentials =
          oauth2.Credentials.fromJson(await credentialsFile.readAsString());
      return oauth2.Client(credentials, identifier: identifier, secret: secret);
    }
    */

    // If we don't have OAuth2 credentials yet, we need to get the resource owner
    // to authorize us. We're assuming here that we're a command-line application.
    final oauth2.AuthorizationCodeGrant grant = oauth2.AuthorizationCodeGrant(
      widget.githubClientId,
      Uri.parse(GithubLoginWidget.authorizationEndpoint),
      Uri.parse(GithubLoginWidget.tokenEndpoint),
      secret: widget.githubClientSecret,
      httpClient: JsonAcceptingHttpClient(),
    );
    Uri authorizationUrl = grant.getAuthorizationUrl(
      redirectUri,
      scopes: widget.githubScopes,
    );

    // TODO(justinmc): Using the html package is web-only. Maybe add support for
    // desktop here.

    // Redirect the resource owner to the authorization URL. Once the resource
    // owner has authorized, they'll be redirected to `redirectUrl` with an
    // authorization code. The `redirect` should cause the browser to redirect to
    // another URL which should also have a listener.
    //
    // `redirect` and `listen` are not shown implemented here. See below for the
    // details.
    //await redirect(authorizationUrl);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'grant',
      jsonEncode(<String, String>{
        'githubClientId': grant.identifier,
        'authorizationEndpoint': grant.authorizationEndpoint.toString(),
        'tokenEndpoint': grant.tokenEndpoint.toString(),
        'githubClientSecret': grant.secret!,
      }),
    );
    html.window.open(authorizationUrl.toString(), '_self');
    // TODO(justinmc): You could do this as a separate window like below. Then
    // when it redirects, send the info back to this window and close the popup.
    // But no, I think I need to figure out how to serialize the grant.
    //html.window.open(authorizationUrl.toString(), 'Auth', 'width=400, height=500, scrollbars=yes');
    // TODO(justinmc): This does a full browser redirect, as it should. Once
    // logged in, it will redirect back to thisapp/auth. Then it's up to me to
    // get the code from the query params and continue the oauth flow.
    await http.get(authorizationUrl);
    /*
    var responseUrl = await listen(redirectUrl);

    // Once the user is redirected to `redirectUrl`, pass the query parameters to
    // the AuthorizationCodeGrant. It will validate them and extract the
    // authorization code to create a new Client.
    return await grant.handleAuthorizationResponse(responseUrl.queryParameters);
    */
  }

  Future<void> _redirect(Uri authorizationUrl) async {
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl);
    } else {
      throw GithubLoginException('Could not launch $authorizationUrl');
    }
  }

  /*
  Future<Map<String, String>> _listen() async {
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln('Authenticated! You can close this tab.');
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;
    return params;
  }
  */
}

class JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class GithubLoginException implements Exception {
  const GithubLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}

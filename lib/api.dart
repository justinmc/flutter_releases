//TODO(justinmc): Check out Rody's http cached library?
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/branch.dart';
import 'models/pr.dart';

enum RepoNames {
  flutter,
  engine,
}

// Returns the SHA for the merge commit of the given PR.
//
// Returns an error if the PR doesn't exist, isn't merged, or isn't based on
// master.
Future<PR> getPR(final int prNumber) async {
  final http.Response prResponse = await _getPR(prNumber, _Repo.framework);

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the given PR \"$prNumber\".");
  }

  return PR.fromJSON(jsonDecode(prResponse.body));
  /*
  final PR pr = PR.fromJSON(jsonDecode(prResponse.body));
  if (pr.mergeCommitSHA == '' || pr.mergedAt == '') {
    throw ArgumentError('PR "$prNumber" not yet merged.');
  }
  if (pr.branch != 'master') {
    throw ArgumentError("PR \"$prNumber\"'s base isn't master.");
  }

  return pr.mergeCommitSHA;
  */
}

Future<PR?> _getEngineRollPR(int prNumber) async {
  final http.Response prResponse = await http.get(
    Uri.parse(
      '${dotenv.env['API_HOST']}/pulls/roll/${_Repo.engine.string}/$prNumber',
    ),
  );

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the related roll PR.");
  }

  final Map<String, dynamic> json = jsonDecode(prResponse.body);
  final int rollPRs = json['total_count'];
  assert(rollPRs <= 1, 'Found multiple roll PRs for engine PR $prNumber.');

  return rollPRs == 1 ? await getPR(json['items'][0]['number']) : null;
}

/// Get the [EnginePR] for the given engine PR number, which includes the roll
/// PR where it went into the framework.
Future<EnginePR> getEnginePR(int prNumber) async {
  final PR? rollPR = await _getEngineRollPR(prNumber);
  final PR enginePR = await _getEnginePROnly(prNumber);

  return EnginePR(
    rollPR: rollPR,
    enginePR: enginePR,
  );
}

Future<PR?> _getDartRollPR(int prNumber) async {
  final http.Response prResponse = await http.get(
    Uri.parse(
      '${dotenv.env['API_HOST']}/pulls/roll/${_Repo.dartsdk.string}/$prNumber',
    ),
  );

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the related roll PR.");
  }

  final Map<String, dynamic> json = jsonDecode(prResponse.body);
  final int rollPRs = json['total_count'];
  assert(rollPRs <= 1, 'Found multiple roll PRs for Dart PR $prNumber.');

  return rollPRs == 1 ? await getPR(json['items'][0]['number']) : null;
}

/// Get the [DartPR] for the given dart-lang/sdk PR number, which includes the
/// roll PR where it went into the framework.
Future<DartPR> getDartPR(int prNumber) async {
  final PR? rollPR = await _getDartRollPR(prNumber);
  final PR dartPR = await _getDartPROnly(prNumber);

  return DartPR(
    rollPR: rollPR,
    dartPR: dartPR,
  );
}

Future<Branch> getBranch(BranchNames name) async {
  final http.Response branchResponse = await _getBranch(name.name);

  if (branchResponse.statusCode == 403) {
    throw Exception(
        "${branchResponse.statusCode}: The GitHub API seems to be rate-limiting this app. Try again later, sorry!");
  } else if (branchResponse.statusCode != 200) {
    // TODO(justinmc): Capture the error message and display it on the error page.
    throw ArgumentError(
        "${branchResponse.statusCode}: Couldn't get the branch $name.");
  }

  final Branch branch = Branch.fromJSON(jsonDecode(branchResponse.body));

  // Master has no version tag. Otherwise find the version tag name.
  if (branch.branchName == BranchNames.master) {
    return branch;
  }

  // TODO(justinmc): If can't find the tag, just continue anyway without it? If
  // this ends up being reliable and you never it fail, then nevermind, keep
  // this as-is.
  final String tagName = await _getTag(branch.sha);

  return branch.copyWith(tagName: tagName);
}

// Returns true iff sha is in the branch given by isInSha.
Future<bool> isIn(String baseSHA, String headSHA) async {
  final http.Response isInResponse = await http
      .get(Uri.parse('${dotenv.env['API_HOST']}/isIn/$baseSHA/$headSHA'));

  if (isInResponse.statusCode != 200) {
    throw ArgumentError("Couldn't compare shas $baseSHA and $headSHA.");
  }

  final Map<String, dynamic> json = jsonDecode(isInResponse.body);

  if (json['isIn'] != 'true' && json['isIn'] != 'false') {
    throw ArgumentError(
        "Invalid response when comparing shas $baseSHA and $headSHA.");
  }

  return json['isIn'] == 'true';
}

// Get the PR in the engine repo, not the full EnginePR.
Future<PR> _getEnginePROnly(final int prNumber) async {
  final http.Response prResponse = await http.get(
    Uri.parse(
      '${dotenv.env['API_HOST']}/pulls/${_Repo.engine.string}/$prNumber',
    ),
  );

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the given engine PR \"$prNumber\".");
  }

  return PR.fromJSON(jsonDecode(prResponse.body));
}

// TODO(justinmc): Can I combine this with _getEnginePROnly?
// Get the PR in the dart-lang/sdk repo, not the full DartPR.
Future<PR> _getDartPROnly(final int prNumber) async {
  final http.Response prResponse = await _getPR(prNumber, _Repo.dartsdk);

  if (prResponse.statusCode != 200) {
    throw ArgumentError(
        "Couldn't find the given engine PR \"$prNumber\" in dart-lang/sdk.");
  }

  return PR.fromJSON(jsonDecode(prResponse.body));
}

Future<http.Response> _getPR(final int prNumber, _Repo repo) {
  return http.get(
      Uri.parse('${dotenv.env['API_HOST']}/pulls/${repo.string}/$prNumber'));
}

Future<http.Response> _getBranch(final String branchName) {
  return http.get(Uri.parse('${dotenv.env['API_HOST']}/branches/$branchName'));
}

Future<String> _getTag(String sha) async {
  final http.Response response =
      await http.get(Uri.parse('${dotenv.env['API_HOST']}/tag/$sha'));

  if (response.statusCode == 403) {
    throw Exception(
        "${response.statusCode}: The GitHub API seems to be rate-limiting this app. Try again later, sorry!");
  } else if (response.statusCode != 200) {
    throw ArgumentError("Couldn't get the tag for sha $sha.");
  }

  final Map<String, dynamic> json = jsonDecode(response.body);

  final String? tagName = json['name'];

  if (tagName == null) {
    throw ArgumentError('No tag found for sha $sha.');
  }
  return tagName;
}

// An enum with string constants for each value.
enum _Repo {
  framework(string: 'flutter'),
  engine(string: 'engine'),
  dartsdk(string: 'dartsdk');

  const _Repo({
    required this.string,
  });

  final String string;
}

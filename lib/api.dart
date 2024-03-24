import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/branch.dart';
import 'models/pr.dart';

const String kAPI = "https://api.github.com";
const String kAPIFramework = "$kAPI/repos/flutter/flutter";
const String kAPIEngine = "$kAPI/repos/flutter/engine";
const String kAPIDart = "$kAPI/repos/dart-lang/sdk";
const String kBranch = "master";

enum RepoNames {
  flutter,
  engine,
}

// Returns the SHA for the merge commit of the given PR.
//
// Returns an error if the PR doesn't exist, isn't merged, or isn't based on
// master.
Future<PR> getPr(final int prNumber) async {
  final http.Response prResponse = await _getPR(prNumber);

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the given PR \"$prNumber\".");
  }

  return PR.fromJSON(jsonDecode(prResponse.body));
  /*
  final PR pr = PR.fromJSON(jsonDecode(prResponse.body));
  if (pr.mergeCommitSHA == '' || pr.mergedAt == '') {
    throw ArgumentError('PR "$prNumber" not yet merged.');
  }
  if (pr.branch != kBranch) {
    throw ArgumentError("PR \"$prNumber\"'s base isn't master.");
  }

  return pr.mergeCommitSHA;
  */
}

/// Get the [EnginePR] for the given engine PR number, which includes the roll
/// PR where it went into the framework.
Future<EnginePR> getEnginePR(int prNumber) async {
  final http.Response prResponse = await http.get(Uri.parse('$kAPI/search/issues\?q\=repo:flutter/flutter+author:engine-flutter-autoroll+flutter/engine%23$prNumber'));

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the related roll PR.");
  }

  final Map<String, dynamic> json = jsonDecode(prResponse.body);
  final int rollPRs = json['total_count'];
  assert(rollPRs <= 1, 'Found multiple roll PRs for engine PR $prNumber.');

  final PR? rollPR = rollPRs == 1
      ? await getPr(json['items'][0]['number'])
      : null;
  final PR enginePr = await _getEnginePROnly(prNumber);

  return EnginePR(
    rollPR: rollPR,
    enginePr: enginePr,
  );
}

/// Get the [DartPR] for the given dart-lang/sdk PR number, which includes the
/// roll PR where it went into the framework.
Future<DartPR> getDartPR(int prNumber) async {
  final http.Response prResponse = await http.get(Uri.parse('$kAPI/search/issues\?q\=repo:flutter/flutter+author:engine-flutter-autoroll+dart-lang/sdk%23$prNumber'));

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the related roll PR.");
  }

  final Map<String, dynamic> json = jsonDecode(prResponse.body);
  final int rollPRs = json['total_count'];
  assert(rollPRs <= 1, 'Found multiple roll PRs for Dart PR $prNumber.');

  final PR? rollPR = rollPRs == 1
      ? await getPr(json['items'][0]['number'])
      : null;
  final PR dartPr = await _getDartPROnly(prNumber);

  return DartPR(
    rollPR: rollPR,
    dartPr: dartPr,
  );
}

// This page value is a hack. The latest tags happen to be on this page more or
// less because it's in alphanumeric order, and we originally tagged with
// "v1.x" and later removed the "v", so the first pages are full of old tags.
const _bestGuessTagPage = 4;

// TODO(justinmc): How do I get the latest version tag of a given branch (e.g. stable)?
Future<Branch> getBranch(BranchNames name) async {
  final http.Response branchResponse = await _getBranch(name.name);

  if (branchResponse.statusCode == 403) {
    throw Exception("${branchResponse.statusCode}: The GitHub API seems to be rate-limiting this app. Try again later, sorry!");
  } else if (branchResponse.statusCode != 200) {
    // TODO(justinmc): Capture the error message and display it on the error page.
    throw ArgumentError("${branchResponse.statusCode}: Couldn't get the branch $name.");
  }

  final Branch branch = Branch.fromJSON(jsonDecode(branchResponse.body));

  // Master has no version tag. Otherwise find the version tag name.
  if (branch.branchName == BranchNames.master) {
    return branch;
  }

  late final String tagName;
  try {
    // Try to find the tag on the most likely page.
    tagName = await _getTag(branch.sha, _bestGuessTagPage);
  } catch (e) {
    if (e.toString() != 'Invalid argument(s): No tag found for sha ${branch.sha} on page $_bestGuessTagPage.') {
      rethrow;
    }
    try {
      tagName = await _getTagFullSearch(branch.sha);
    } catch (e) {
      final String errorString = e.toString();
      const String errorMessageStart = 'Invalid argument(s): No tags';
      if (errorString.length < errorMessageStart.length || errorString.substring(0, errorMessageStart.length) != errorMessageStart) {
        rethrow;
      }
      // The tag simply doesn't exist in the API for some reason.
      return branch;
    }
  }

  return branch.copyWith(tagName: tagName);
}

// Returns true iff sha is in the branch given by isInSha.
Future<bool> isIn(String sha, String isInSha) async {
  // TODO(justinmc): This seems to give a 404 for old PRs...
  final http.Response compareResponse = await _compare(isInSha, sha);

  if (compareResponse.statusCode != 200 || compareResponse.body == '') {
    throw ArgumentError("Couldn't compare $sha and $isInSha");
  }

  final Map<String, dynamic> comparison = jsonDecode(compareResponse.body);


  if (comparison['status'] == '') {
    throw ArgumentError("Couldn't compare $sha and $isInSha");
  }

  return comparison['status'] == 'behind'
      || comparison['status'] == 'identical';
}

// Get the PR in the engine repo, not the full EnginePR.
Future<PR> _getEnginePROnly(final int prNumber) async {
  final http.Response prResponse = await _getPR(prNumber, kAPIEngine);

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the given engine PR \"$prNumber\".");
  }

  return PR.fromJSON(jsonDecode(prResponse.body));
}

// TODO(justinmc): Can I combine this with _getEnginePROnly?
// Get the PR in the dart-lang/sdk repo, not the full DartPR.
Future<PR> _getDartPROnly(final int prNumber) async {
  final http.Response prResponse = await _getPR(prNumber, kAPIDart);

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the given engine PR \"$prNumber\" in $kAPIDart.");
  }

  return PR.fromJSON(jsonDecode(prResponse.body));
}

Future<http.Response> _getPR(final int prNumber, [String url = kAPIFramework]) {
  return http.get(Uri.parse('$url/pulls/$prNumber'));
}

Future<http.Response> _getBranch(final String branchName) {
  return http.get(Uri.parse('$kAPIFramework/branches/$branchName'));
}

Future<String> _getTag(String sha, int page) async {
  // 100 is the maximum supported number of tags per page.
  final http.Response response = await http.get(Uri.parse('$kAPIFramework/tags?per_page=100&page=$page'));

  if (response.statusCode != 200) {
    throw ArgumentError("Couldn't get the tag for sha $sha.");
  }

  final List<dynamic> json = jsonDecode(response.body);

  if (json.isEmpty) {
    throw ArgumentError('No tags found for sha $sha on page $page.');
  }

  for (Map<String, dynamic> jsonTag in json) {
    final String jsonSha = jsonTag['commit']['sha'];
    if (jsonSha == sha) {
      return jsonTag['name'];
    }
  }

  throw ArgumentError('No tag found for sha $sha on page $page.');
}

Future<String> _getTagFullSearch(String sha) async {
  int page = 0;
  while (true) {
    try {
      // TODO(justinmc): Should search in parallel?
      return await _getTag(sha, page);
    } catch (e) {
      if (e.toString() != 'Invalid argument(s): No tag found for sha $sha on page $page.') {
        rethrow;
      }
      // Skip page 4, since that was probably already searched.
      page = page == 3 ? page + 2 : page + 1;
    }
  }
}

Future<http.Response> _compare(final String sha1, final String sha2) {
  return http.get(Uri.parse('$kAPIFramework/compare/$sha1...$sha2'));
}

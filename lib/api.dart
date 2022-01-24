import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/branch.dart';
import 'models/pr.dart';

const String kAPI = "https://api.github.com";
const String kAPIFramework = "$kAPI/repos/flutter/flutter";
const String kAPIEngine = "$kAPI/repos/flutter/engine";
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
  if (pr.mergeCommitSHA == '' || pr.mergedAt == '') {
    throw ArgumentError('PR "$prNumber" not yet merged.');
  }
  if (pr.branch != kBranch) {
    throw ArgumentError("PR \"$prNumber\"'s base isn't master.");
  }

  return pr.mergeCommitSHA;
  */
}

/// Get the framework roll PR for the indicated engine PR.
///
/// prNumber must be a valid number for an engine PR.
Future<PR> getRollPrFromEnginePr(int prNumber) async {
  final http.Response prResponse = await http.get(Uri.parse('$kAPI/search/issues\?q\=repo:flutter/flutter+author:engine-flutter-autoroll+flutter/engine%23$prNumber'));

  if (prResponse.statusCode != 200) {
    throw ArgumentError("Couldn't find the related roll PR.");
  }

  final Map<String, dynamic> json = jsonDecode(prResponse.body);
  assert(json['total_count'] == 1, 'Found multiple roll PRs for engine PR $prNumber.');
  final int rollPrNumber = json['items'][0]['number'];

  return getPr(rollPrNumber);
}

Future<Branch> getBranch(BranchNames name) async {
  final http.Response branchResponse = await _getBranch(name.name);

  if (branchResponse.statusCode != 200) {
    throw ArgumentError("Couldn't get the stable branch.");
  }

  return Branch.fromJSON(jsonDecode(branchResponse.body));
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

Future<http.Response> _getPR(final int prNumber) {
  return http.get(Uri.parse('$kAPIFramework/pulls/$prNumber'));
}

Future<http.Response> _getBranch(final String branchName) {
  return http.get(Uri.parse('$kAPIFramework/branches/$branchName'));
}

Future<http.Response> _compare(final String sha1, final String sha2) {
  return http.get(Uri.parse('$kAPIFramework/compare/$sha1...$sha2'));
}

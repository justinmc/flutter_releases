import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/branch.dart';
import 'models/pr.dart';

const String kAPI = "https://api.github.com/repos/flutter/flutter";
const String kBranch = "master";

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

Future<Branch> getBranch(BranchNames name) async {
  final http.Response branchResponse = await _getBranch(name.name);

  if (branchResponse.statusCode != 200) {
    throw ArgumentError("Couldn't get the stable branch.");
  }

  return Branch.fromJSON(jsonDecode(branchResponse.body));
}

Future<Branch> getStable() async {
  final http.Response branchResponse = await _getBranch('stable');

  if (branchResponse.statusCode != 200) {
    throw ArgumentError("Couldn't get the stable branch.");
  }

  return Branch.fromJSON(jsonDecode(branchResponse.body));
}

Future<http.Response> _getPR(final int prNumber) {
  return http.get(Uri.parse('$kAPI/pulls/$prNumber'));
}

Future<http.Response> _getBranch(final String branchName) {
  return http.get(Uri.parse('$kAPI/branches/$branchName'));
}

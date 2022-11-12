enum BranchNames {
  stable,
  beta,
  master,
}

class Branch {
  const Branch({
    required this.date,
    required this.name,
    required this.sha,
    required this.uri,
  });

  Branch.fromJSON(
    Map<String, dynamic> jsonMap,
  ) : sha = jsonMap['commit']['sha'],
      uri = Uri.parse(jsonMap['_links']['html']),
      date = DateTime.parse(jsonMap['commit']['commit']['author']['date']),
      name = jsonMap['name'];

  final String sha;
  final String name;
  final Uri uri;
  final DateTime date;

  BranchNames get branchName => BranchNames.values.firstWhere((BranchNames branchName) {
    return branchName.name == name;
  });

  String get shortSha => sha.substring(0, 7);

  @override
  String toString() {
    return 'Branch {name: $name, sha: $sha, date: $date, uri: $uri}';
  }
}

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
  });

  Branch.fromJSON(
    Map<String, dynamic> jsonMap,
  ) : sha = jsonMap['commit']['sha'],
      date = DateTime.parse(jsonMap['commit']['commit']['author']['date']),
      name = jsonMap['name'];

  final String sha;
  final String name;
  final DateTime date;

  @override
  String toString() {
    return 'Branch {name: $name, sha: $sha, date: $date}';
  }
}

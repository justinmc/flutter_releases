import '../constants.dart';

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
    this.tagName,
  });

  Branch.fromJSON(
    Map<String, dynamic> jsonMap,
  ) : sha = jsonMap['commit']['sha'],
      uri = Uri.parse(jsonMap['_links']['html']),
      date = DateTime.parse(jsonMap['commit']['commit']['author']['date']),
      name = jsonMap['name'],
      tagName = null;

  final String sha;
  final String name;
  final Uri uri;
  final DateTime date;
  final String? tagName;

  BranchNames get branchName => BranchNames.values.firstWhere((BranchNames branchName) {
    return branchName.name == name;
  });

  String get shortSha => sha.substring(0, 7);

  String get formattedDate {
    final DateTime localTime = date.toLocal();

    return '${localTime.year}-${localTime.month}-${localTime.day}';
  }

  Uri get tagUri {
    assert(tagName != null);

    return Uri.parse('$kGitHubFlutter/releases/tag/$tagName');
  }

  Branch copyWith({
    String? sha,
    String? name,
    Uri? uri,
    DateTime? date,
    String? tagName,
  }) {
    return Branch(
      sha: sha ?? this.sha,
      name: name ?? this.name,
      uri: uri ?? this.uri,
      date: date ?? this.date,
      tagName: tagName ?? this.tagName,
    );
  }

  @override
  String toString() {
    return 'Branch {name: $name, sha: $sha, date: $date, uri: $uri}';
  }
}

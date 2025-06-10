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
  )   : sha = jsonMap['commit']['sha'],
        // Originally I got the URI like the following, but after switching to
        // use a backend, it wasn't in the branch data for some reason.
        //Uri.parse(jsonMap['_links']['html']),
        uri = Uri.parse(
            'https://github.com/flutter/flutter/tree/${jsonMap['name']}'),
        date = DateTime.parse(jsonMap['commit']['commit']['author']['date']),
        name = jsonMap['name'],
        tagName = null;

  final String sha;
  final String name;
  final Uri uri;
  final DateTime date;
  final String? tagName;

  BranchNames get branchName =>
      BranchNames.values.firstWhere((BranchNames branchName) {
        return branchName.name == name;
      });

  String get shortSha => sha.substring(0, 7);

  String get formattedDate {
    final DateTime localTime = date.toLocal();

    return '${localTime.year}-${localTime.month}-${localTime.day}';
  }

  String get tagUrl {
    assert(tagName != null);

    return '$kGitHubFlutter/releases/tag/$tagName';
  }

  Uri get tagUri {
    return Uri.parse(tagUrl);
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

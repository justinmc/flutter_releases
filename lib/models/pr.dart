import '../constants.dart';

enum PRStatus {
  open,
  draft,
  merged,
  closed,
}

// TODO(justinmc): Add repo name to this?
class PR {
  const PR({
    required this.branch,
    required this.htmlURL,
    required this.number,
    required this.repoName,
    required this.state,
    required this.title,
    required this.user,
    this.mergeCommitSHA,
    this.mergedAt,
  });

  PR.fromJSON(
    Map<String, dynamic> jsonMap,
  ) : mergeCommitSHA = jsonMap['merge_commit_sha'],
      mergedAt = jsonMap['merged_at'] == null ? null : DateTime.parse(jsonMap['merged_at']),
      branch = jsonMap['base']['ref'],
      number = jsonMap['number'],
      state = jsonMap['state'],
      htmlURL = jsonMap['html_url'],
      repoName = jsonMap['head']['repo']['full_name'],
      title = jsonMap['title'],
      user = jsonMap['user']['login'];

  final String? mergeCommitSHA;
  final DateTime? mergedAt;
  final String branch;
  final String htmlURL;
  final int number;
  final String repoName;
  final String state;
  final String title;
  final String user;

  bool get isMerged => mergedAt != null;

  PRStatus get status {
    if (state == 'open') {
      return PRStatus.open;
    }
    if (state == 'draft') {
      return PRStatus.draft;
    }
    if (mergedAt == null) {
      return PRStatus.closed;
    }
    return PRStatus.merged;
  }

  String? get formattedMergedAt {
    if (mergedAt == null) {
      return null;
    }

    final DateTime localTime = mergedAt!.toLocal();

    return '${localTime.year}-${localTime.month}-${localTime.day}';
  }

  String? get mergeCommitShortSHA => mergeCommitSHA?.substring(0, 7);

  String get mergeCommitUrl {
    assert(mergeCommitSHA != null);
    return '$kGitHubFlutter/commit/$mergeCommitSHA';
  }

  String get repoUrl => '$kGitHub/$repoName';

  String get userUrl => '$kGitHub/$user';

  @override
  String toString() {
    return 'PR {number: $number, mergeCommitSHA: $mergeCommitSHA, mergedAt: $mergedAt, branch: $branch, htmlURL: $htmlURL}';
  }
}

/// A PR in the engine, along with its merge PR in the framework, if it exists.
class EnginePR extends PR {
  EnginePR({
    required final PR enginePr,
    this.rollPR,
  }) : super(
    branch: enginePr.branch,
    htmlURL: enginePr.htmlURL,
    number: enginePr.number,
    repoName: 'flutter/engine',
    state: enginePr.state,
    title: enginePr.title,
    user: enginePr.user,
    mergeCommitSHA: enginePr.mergeCommitSHA,
    mergedAt: enginePr.mergedAt,
  );

  final PR? rollPR;
}

// TODO(justinmc): Can I combine this and EnginePR?
/// A PR in dart-lang/sdk, along with its merge PR in the framework, if it exists.
class DartPR extends PR {
  DartPR({
    required final PR dartPr,
    this.rollPR,
  }) : super(
    branch: dartPr.branch,
    htmlURL: dartPr.htmlURL,
    number: dartPr.number,
    repoName: 'dart-lang/sdk',
    state: dartPr.state,
    title: dartPr.title,
    user: dartPr.user,
    mergeCommitSHA: dartPr.mergeCommitSHA,
    mergedAt: dartPr.mergedAt,
  );

  final PR? rollPR;
}

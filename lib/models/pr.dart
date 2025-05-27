import 'package:intl/intl.dart';

import '../constants.dart';

enum PRStatus {
  open,
  draft,
  merged,
  closed,
}

class PR {
  const PR({
    required this.branch,
    required this.draft,
    required this.htmlURL,
    required this.number,
    required this.repoName,
    required this.state,
    required this.title,
    required this.user,
    this.closedAt,
    this.createdAt,
    this.mergeCommitSHA,
    this.mergedAt,
  });

  PR.fromJSON(
    Map<String, dynamic> jsonMap,
  )   : mergeCommitSHA = jsonMap['merge_commit_sha'],
        closedAt = jsonMap['closed_at'] == null
            ? null
            : DateTime.parse(jsonMap['closed_at']),
        createdAt = jsonMap['created_at'] == null
            ? null
            : DateTime.parse(jsonMap['created_at']),
        mergedAt = jsonMap['merged_at'] == null
            ? null
            : DateTime.parse(jsonMap['merged_at']),
        branch = jsonMap['base']['ref'],
        draft = jsonMap['draft'] == true,
        number = jsonMap['number'],
        state = jsonMap['state'],
        htmlURL = jsonMap['html_url'],
        repoName = jsonMap['head']['repo']['full_name'],
        title = jsonMap['title'],
        user = jsonMap['user']['login'];

  final DateTime? closedAt;
  final DateTime? createdAt;
  final String? mergeCommitSHA;
  final DateTime? mergedAt;
  final String branch;
  final bool draft;
  final String htmlURL;
  final int number;
  final String repoName;
  final String state;
  final String title;
  final String user;

  bool get isMerged => mergedAt != null;

  static String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    final DateTime localTime = date.toLocal();

    // TODO(justinmc): Real localization.
    return DateFormat.yMMMMd('en-US').format(localTime);
  }

  PRStatus get status {
    if (mergedAt == null) {
      if (state == 'closed') {
        return PRStatus.closed;
      }
      if (draft) {
        return PRStatus.draft;
      }
      assert(true, 'Weird PR status.');
    }
    if (state == 'open') {
      return PRStatus.open;
    }
    return PRStatus.merged;
  }

  String? get formattedClosedAt => _formatDate(closedAt);

  String? get formattedCreatedAt => _formatDate(createdAt);

  String? get formattedMergedAt => _formatDate(mergedAt);

  String? get mergeCommitShortSHA => mergeCommitSHA?.substring(0, 7);

  String get mergeCommitUrl {
    assert(mergeCommitSHA != null);
    return '$kGitHub/commit/$mergeCommitSHA';
  }

  String get repoUrl => '$kGitHub/$repoName';

  String get userUrl => '$kGitHub/$user';

  @override
  String toString() {
    return 'PR {number: $number, mergeCommitSHA: $mergeCommitSHA, closedAt: $closedAt, mergedAt: $mergedAt, branch: $branch, htmlURL: $htmlURL}';
  }
}

/// A PR in the engine, along with its merge PR in the framework, if it exists.
class EnginePR extends PR {
  EnginePR({
    required final PR enginePr,
    this.rollPR,
  }) : super(
          branch: enginePr.branch,
          draft: enginePr.draft,
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
          draft: dartPr.draft,
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

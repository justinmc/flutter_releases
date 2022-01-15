class PR {
  const PR({
    required this.branch,
    required this.mergeCommitSHA,
    required this.mergedAt,
  });

  PR.fromJSON(
    Map<String, dynamic> jsonMap,
  ) : mergeCommitSHA = jsonMap['merge_commit_sha'],
      mergedAt = jsonMap['merged_at'],
      branch = jsonMap['base']['ref'];

  final String mergeCommitSHA;
  final String mergedAt;
  final String branch;

  @override
  String toString() {
    return 'PR {mergeCommitSHA: $mergeCommitSHA, mergedAt: $mergedAt, branch: $branch}';
  }
}

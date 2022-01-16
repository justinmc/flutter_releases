class PR {
  const PR({
    required this.branch,
    required this.number,
    this.mergeCommitSHA,
    this.mergedAt,
  });

  PR.fromJSON(
    Map<String, dynamic> jsonMap,
  ) : mergeCommitSHA = jsonMap['merge_commit_sha'],
      mergedAt = jsonMap['merged_at'],
      branch = jsonMap['base']['ref'],
      number = jsonMap['number'];

  final String? mergeCommitSHA;
  final String? mergedAt;
  final String branch;
  final int number;

  @override
  String toString() {
    return 'PR {number: $number, mergeCommitSHA: $mergeCommitSHA, mergedAt: $mergedAt, branch: $branch}';
  }
}

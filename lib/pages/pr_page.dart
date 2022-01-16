import 'package:flutter/material.dart';
import '../models/pr.dart';

class PRPage extends MaterialPage {
  PRPage({
    required this.pr,
  }) : super(
    key: const ValueKey('PRPage'),
    restorationId: 'home-page',
    child: _PRPage(
      pr: pr,
    ),
  );

  final PR pr;
}

class _PRPage extends StatelessWidget {
  const _PRPage({
    Key? key,
    required this.pr,
  }) : super(key: key);

  final PR pr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PR #${pr.number}'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            if (pr.status == PRStatus.open)
              const Text('Open'),
            if (pr.status == PRStatus.draft)
              const Text('Draft'),
            if (pr.status == PRStatus.merged)
              const Text('Merged'),
            if (pr.status == PRStatus.closed)
              const Text('Closed'),
            // TODO(justinmc): URL launcher Text(''),
            if (pr.status == PRStatus.merged)
              Text('${pr.mergeCommitSHA} merged at ${pr.mergedAt} into branch ${pr.branch}.'),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _onTapGithub() async {
    if (!await launch(pr.htmlURL)) throw 'Could not launch ${pr.htmlURL}';
  }

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
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: _onTapGithub,
              child: const Text('View on Github'),
            ),
            if (pr.status == PRStatus.merged)
              Text('${pr.mergeCommitSHA} merged at ${pr.mergedAt} into branch ${pr.branch}.'),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/branch.dart';
import '../models/pr.dart';
import '../api.dart' as api;

class PRPage extends MaterialPage {
  PRPage({
    required this.pr,
    final Branch? stable,
    final Branch? beta,
    final Branch? master,
  }) : super(
    key: const ValueKey('PRPage'),
    restorationId: 'home-page',
    child: _PRPage(
      pr: pr,
      stable: stable,
      beta: beta,
      master: master,
    ),
  );

  final PR pr;
}

class _PRPage extends StatefulWidget {
  const _PRPage({
    Key? key,
    required this.pr,
    final this.stable,
    final this.beta,
    final this.master,
  }) : super(key: key);

  final PR pr;
  final Branch? stable;
  final Branch? beta;
  final Branch? master;

  @override
  _PRPageState createState() => _PRPageState();
}

class _PRPageState extends State<_PRPage> {
  final Set<BranchNames> _branchesIsIn = <BranchNames>{};

  void _onTapGithub() async {
    if (!await launch(widget.pr.htmlURL)) throw 'Could not launch ${widget.pr.htmlURL}';
  }

  // Check if the PR is in the given branch and update _branchesIsIn.
  //
  // Assumes that being in an older branch implies also being in more advanced
  // branches.
  Future<bool?> _updateIsIn(BranchNames branchName) {
    return _isIn(widget.stable).then((final bool? isInBranch) {
      if (isInBranch == true && !_branchesIsIn.contains(branchName)) {
        setState(() {
          _branchesIsIn.add(branchName);
          if (branchName == BranchNames.master) {
            return;
          }
          _branchesIsIn.add(BranchNames.master);
          if (branchName == BranchNames.beta) {
            return;
          }
          _branchesIsIn.add(BranchNames.beta);
        });
      } else if (isInBranch == false && _branchesIsIn.contains(branchName)) {
        setState(() {
          _branchesIsIn.remove(branchName);
        });
      }
      return isInBranch;
    }).catchError((error) {
      print(error);
      setState(() {
        _branchesIsIn.remove(branchName);
      });
    });
  }

  void _updateIsIns() async {
    if (await _updateIsIn(BranchNames.stable) == true) {
      return;
    }
    if (await _updateIsIn(BranchNames.beta) == true) {
      return;
    }
    _updateIsIn(BranchNames.master);
  }

  Future<bool?> _isIn(final Branch? branch) async {
    if (widget.pr.status != PRStatus.merged || widget.pr.mergeCommitSHA == null) {
      return false;
    }

    if (branch == null) {
      return null;
    }
    return api.isIn(widget.pr.mergeCommitSHA!, branch.sha);
  }

  @override
  void initState() {
    // TODO(justinmc): Cache this isin data.
    _updateIsIns();
    super.initState();
  }

  @override
  void didUpdateWidget(final _PRPage oldWidget) {
    _updateIsIns();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PR ${widget.pr.title}'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text('#${widget.pr.number} by ${widget.pr.user}'),
            if (widget.pr.status == PRStatus.open)
              const Text('Open'),
            if (widget.pr.status == PRStatus.draft)
              const Text('Draft'),
            if (widget.pr.status == PRStatus.merged)
              const Text('Merged'),
            if (widget.pr.status == PRStatus.closed)
              const Text('Closed'),
            if (widget.pr.status == PRStatus.merged)
              // TODO(justinmc): More detail and prettier than just outputting the Set.
              Text('This PR is in the following release channels: $_branchesIsIn'),
            // TODO(justinmc): URL launcher Text(''),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: _onTapGithub,
              child: const Text('View on Github'),
            ),
            if (widget.pr.status == PRStatus.merged)
              Text('${widget.pr.mergeCommitSHA} merged at ${widget.pr.mergedAt} into branch ${widget.pr.branch}.'),
            // TODO(justinmc): Add a disclaimer that this doesn't consider reverts.
          ],
        ),
      ),
    );
  }
}

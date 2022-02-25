import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/branch.dart';
import '../models/branches.dart';
import '../models/pr.dart';
import '../api.dart' as api;
import '../providers/branches_provider.dart';
import '../widgets/link.dart';

class PRPage extends MaterialPage {
  PRPage({
    required this.pr,
  }) : super(
    key: const ValueKey('FrameworkPRPage'),
    restorationId: 'framework-pr-page',
    child: _PRPage(
      pr: pr,
    ),
  );

  final PR pr;
}

class _PRPage extends ConsumerStatefulWidget {
  const _PRPage({
    Key? key,
    required this.pr,
  }) : super(key: key);

  final PR pr;

  @override
  _PRPageState createState() => _PRPageState();
}

class _PRPageState extends ConsumerState<_PRPage> {
  final Set<BranchNames> _branchesIsIn = <BranchNames>{};

  void _onTapGithub() async {
    if (!await launch(widget.pr.htmlURL)) throw 'Could not launch ${widget.pr.htmlURL}';
  }

  // Check if the PR is in the given branch and update _branchesIsIn.
  //
  // Assumes that being in an older branch implies also being in more advanced
  // branches.
  //
  // A return value of null indicates that the status can't be determined.
  Future<bool?> _updateIsIn(Branch? branch) {
    if (branch == null) {
      return Future.value(null);
    }
    return _isIn(branch).then((final bool? isInBranch) {
      if (isInBranch == true && !_branchesIsIn.contains(branch.branchName)) {
        setState(() {
          _branchesIsIn.add(branch.branchName);
          if (branch.branchName == BranchNames.master) {
            return;
          }
          _branchesIsIn.add(BranchNames.master);
          if (branch.branchName == BranchNames.beta) {
            return;
          }
          _branchesIsIn.add(BranchNames.beta);
        });
      } else if (isInBranch == false && _branchesIsIn.contains(branch.branchName)) {
        setState(() {
          _branchesIsIn.remove(branch.branchName);
        });
      }
      return isInBranch;
    }).catchError((error) {
      print(error);
      setState(() {
        _branchesIsIn.remove(branch.branchName);
      });
    });
  }

  void _updateIsIns() async {
    final Branches branches = ref.read(branchesProvider);
    if (await _updateIsIn(branches.stable) == true) {
      return;
    }
    if (await _updateIsIn(branches.beta) == true) {
      return;
    }
    _updateIsIn(branches.master);
  }

  Future<bool?> _enginePRIsIn(final Branch? branch) async {
    final EnginePR pr = widget.pr as EnginePR;

    if (pr.status != PRStatus.merged || pr.mergeCommitSHA == null
        || pr.rollPR == null || pr.rollPR!.mergeCommitSHA == null) {
      return false;
    }

    if (branch == null) {
      return null;
    }
    return api.isIn(pr.rollPR!.mergeCommitSHA!, branch.sha);
  }

  Future<bool?> _isIn(final Branch? branch) async {
    if (widget.pr is EnginePR) {
      return _enginePRIsIn(branch);
    }
    return _frameworkPRIsIn(branch);
  }

  Future<bool?> _frameworkPRIsIn(final Branch? branch) async {
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
    final Branches branches = ref.watch(branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pr is EnginePR ? 'Engine' : 'Framework'} PR ${widget.pr.title}'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 200.0,
              child: Row(
                children: <Widget>[
                  Link(
                    text: '#${widget.pr.number}',
                    url: widget.pr.htmlURL,
                  ),
                  const Text(' by '),
                  Link(
                    text: widget.pr.user,
                    url: 'https://www.github.com/${widget.pr.user}',
                  ),
                ],
              ),
            ),
            if (widget.pr.status == PRStatus.open)
              const Text('Open'),
            if (widget.pr.status == PRStatus.draft)
              const Text('Draft'),
            if (widget.pr.status == PRStatus.merged)
              const Text('Merged'),
            if (widget.pr.status == PRStatus.closed)
              const Text('Closed'),
            if (widget.pr.status == PRStatus.merged)
              _BranchesIn(
                // TODO(justinmc): This isn't quite right. If the PR hasn't
                // loaded yet but the branch has, then it will think that the PR
                // isn't in the branch.
                isInStable: branches.stable == null ? null : _branchesIsIn.contains(BranchNames.stable),
                isInBeta: branches.beta == null ? null : _branchesIsIn.contains(BranchNames.beta),
                isInMaster: branches.master == null ? null : _branchesIsIn.contains(BranchNames.master),
              ),
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

class _BranchesIn extends StatelessWidget {
  const _BranchesIn({
    Key? key,
    this.isInStable,
    this.isInBeta,
    this.isInMaster,
  }) : super(key: key);

  final bool? isInStable;
  final bool? isInBeta;
  final bool? isInMaster;

  // TODO(justinmc): Need the emoji package or icons or something. Not good with
  // the default font in use.
  String _isInToEmoji(bool? isIn) {
    if (isIn == null) {
      return '⌛';
    }
    if (isIn) {
      return '✔️';
    }
    return '❌';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120.0,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const SelectableText('master: '),
              SelectableText(_isInToEmoji(isInMaster)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const SelectableText('beta: '),
              SelectableText(_isInToEmoji(isInBeta)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const SelectableText('stable: '),
              SelectableText(_isInToEmoji(isInStable)),
            ],
          ),
        ],
      ),
    );
  }
}

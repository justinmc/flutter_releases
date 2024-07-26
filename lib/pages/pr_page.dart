import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/link.dart' as url_launcher_link;
import '../models/branch.dart';
import '../models/branches.dart';
import '../models/pr.dart';
import '../api.dart' as api;
import '../providers/branches_provider.dart';
import '../widgets/link.dart';

import '../constants.dart';

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

  final PR? pr;
}

class _PRPage extends ConsumerStatefulWidget {
  const _PRPage({
    Key? key,
    required this.pr,
  }) : super(key: key);

  final PR? pr;

  @override
  _PRPageState createState() => _PRPageState();
}

class _PRPageState extends ConsumerState<_PRPage> {
  final Set<BranchNames> _branchesIsIn = <BranchNames>{};
  bool _finishedLoadingIsIns = false;

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
    return _fetchIsIn(branch).then((final bool? isInBranch) {
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
      return false;
    });
  }

  Future<void> _updateIsIns() async {
    final Branches branches = ref.read(branchesProvider);
    if (await _updateIsIn(branches.stable) == true) {
      return;
    }
    if (await _updateIsIn(branches.beta) == true) {
      return;
    }
    await _updateIsIn(branches.master);
  }

  Future<bool?> _fetchEnginePRIsIn(final Branch? branch) async {
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

  Future<bool?> _fetchIsIn(final Branch? branch) async {
    if (widget.pr is EnginePR) {
      return _fetchEnginePRIsIn(branch);
    }
    return _fetchFrameworkPRIsIn(branch);
  }

  Future<bool?> _fetchFrameworkPRIsIn(final Branch? branch) async {
    if (widget.pr == null || branch == null) {
      return null;
    }
    if (widget.pr!.status != PRStatus.merged || widget.pr!.mergeCommitSHA == null) {
      return false;
    }
    return api.isIn(widget.pr!.mergeCommitSHA!, branch.sha);
  }

  // Returns null if still loading the branch or the PR, true if the PR is in
  // the branch, and false otherwise.
  bool? _isIn(Branch? branch) {
    if (widget.pr == null || branch == null || !_finishedLoadingIsIns) {
      return null;
    }
    return _branchesIsIn.contains(branch.branchName);
  }

  String get _title {
    late final String type;
    if (widget.pr is EnginePR) {
      type = 'Engine';
    } else if (widget.pr is DartPR) {
      type = 'Dart';
    } else {
      type = 'Framework';
    }
    return '$type PR: ${widget.pr!.title}';
  }

  @override
  void initState() {
    // TODO(justinmc): Cache this isin data.
    _updateIsIns().then((_) {
      setState(() {
        _finishedLoadingIsIns = true;
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(final _PRPage oldWidget) {
    // TODO(justinmc): Does this always need to be updated?
    _updateIsIns().then((_) {
      setState(() {
        _finishedLoadingIsIns = true;
      });
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Branches branches = ref.watch(branchesProvider);

    if (widget.pr == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 200.0,
                child: Row(
                  children: <Widget>[
                    Link.fromString(
                      text: '#${widget.pr!.number}',
                      url: widget.pr!.htmlURL,
                    ),
                    const Text(' by '),
                    Link.fromString(
                      text: widget.pr!.user,
                      url: 'https://www.github.com/${widget.pr!.user}',
                    ),
                  ],
                ),
              ),
              // TODO(justinmc): Some colors for these statuses like on GitHub?
              if (widget.pr!.status == PRStatus.open)
                const Text('Open'),
              if (widget.pr!.status == PRStatus.draft)
                const Text('Draft'),
              if (widget.pr!.status == PRStatus.merged)
                const Text('Merged'),
              if (widget.pr!.status == PRStatus.closed)
                const Text('Closed'),
              if (widget.pr!.status == PRStatus.merged)
                _BranchesIn(
                  isInStable: _isIn(branches.stable),
                  isInBeta: _isIn(branches.beta),
                  isInMaster: _isIn(branches.master),
                ),
              // TODO(justinmc): URL launcher Text(''),
              url_launcher_link.Link(
                uri: Uri.parse(widget.pr!.htmlURL),
                target: url_launcher_link.LinkTarget.blank,
                builder: (BuildContext context, url_launcher_link.FollowLink? followLink) {
                  return TextButton(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    onPressed: followLink,
                    child: const Text('View PR on Github'),
                  );
                },
              ),
              if (widget.pr!.status == PRStatus.merged)
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      WidgetSpan(
                        child: Link.fromString(
                          text: widget.pr!.mergeCommitShortSHA!,
                          url: '$kGitHubFlutter/commit/${widget.pr!.mergeCommitSHA}',
                        ),
                      ),
                      TextSpan(
                        text: ' merged at ${widget.pr!.formattedMergedAt} into branch ',
                      ),
                      WidgetSpan(
                        child: Link.fromString(
                          text: widget.pr!.branch,
                          url: '$kGitHubFlutter/tree/${widget.pr!.branch}',
                        ),
                      ),
                      const TextSpan(
                        text: '.',
                      ),
                    ],
                  ),
                ),
              if (widget.pr!.status == PRStatus.merged)
                // TODO(justinmc): Can I find reverts of a PR and fix this?
                const Text('Note that this does not consider if this PR was reverted!'),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120.0,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('master: '),
              _IsIn(isIn: isInMaster),
              // TODO(justinmc): Display at what version the PR made it into
              // each channel. Can you figure that out based on the tags on the
              // merge commit?
              // Actually, won't the version number be the same for each
              // channel?
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('beta: '),
              _IsIn(isIn: isInBeta),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('stable: '),
              _IsIn(isIn: isInStable),
            ],
          ),
        ],
      ),
    );
  }
}

class _IsIn extends StatelessWidget {
  const _IsIn({
    required this.isIn,
  });

  final bool? isIn;

  @override
  Widget build(BuildContext context) {
    return switch (isIn) {
      // TODO(justinmc): Need the emoji package or icons or something. Not good with
      // the default font in use.
      true => const Text('✔️'),
      false => const Text('❌'),
      null => const SizedBox(
        width: 16.0,
        height: 16.0,
        child: CircularProgressIndicator.adaptive(),
      ),
    };
  }
}

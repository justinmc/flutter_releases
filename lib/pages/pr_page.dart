import 'package:flutter/material.dart';

import 'package:arrow_path/arrow_path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final PR? pr;
}

class _PRPage extends ConsumerStatefulWidget {
  const _PRPage({
    required this.pr,
  });

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
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Link.fromString(
                      text: '#${widget.pr!.number}',
                      url: widget.pr!.htmlURL,
                    ),
                    const Text(' by '),
                    Link.fromString(
                      text: widget.pr!.user,
                      url: widget.pr!.userUrl,
                    ),
                    const Text(' in repo '),
                    Link.fromString(
                      text: widget.pr!.repoName,
                      url: widget.pr!.repoUrl,
                    ),
                  ],
                ),
                // TODO(justinmc): Remove these once the chip covers them all.
                if (widget.pr!.status == PRStatus.open)
                  const Text('Open'),
                if (widget.pr!.status == PRStatus.draft)
                  const Text('Draft'),
                if (widget.pr!.status == PRStatus.merged)
                  const Text('Merged'),
                if (widget.pr!.status == PRStatus.closed)
                  const Text('Closed'),
                // TODO(justinmc): When refreshing page, I briefly see all branches but with yellow status. Pop-in from isIn?
                if (widget.pr!.status == PRStatus.merged)
                  _BranchesInChips(
                    master: branches.master,
                    beta: branches.beta,
                    stable: branches.stable,
                    isInMaster: _isIn(branches.master),
                    isInBeta: _isIn(branches.beta),
                    isInStable: _isIn(branches.stable),
                    pr: widget.pr!,
                  ),
                if (widget.pr!.status == PRStatus.merged)
                  // TODO(justinmc): Can I find reverts of a PR and fix this?
                  const Text('Note that this does not consider if this PR was reverted!'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchesInChips extends StatelessWidget {
  const _BranchesInChips({
    required this.master,
    required this.beta,
    required this.stable,
    required this.isInMaster,
    required this.isInBeta,
    required this.isInStable,
    required this.pr,
  });

  final Branch? master;
  final Branch? beta;
  final Branch? stable;
  final bool? isInMaster;
  final bool? isInBeta;
  final bool? isInStable;
  final PR pr;

  @override
  Widget build(BuildContext context) {
    if (master == null || beta == null || stable == null
      || isInMaster == null || isInBeta == null || isInStable == null) {
      return const CircularProgressIndicator.adaptive();
    }
    return Row(
      children: <Widget>[
        _PRChip(
          pr: pr,
        ),
        const _Arrow(),
        _BranchChip(
          branch: master!,
          isIn: isInMaster!,
          mergeDate: pr.formattedMergedAt!,
        ),
        const _Arrow(),
        _BranchChip(
          branch: beta!,
          isIn: isInBeta!,
        ),
        const _Arrow(),
        _BranchChip(
          branch: stable!,
          isIn: isInStable!,
        ),
      ],
    );
  }
}

class _PRChip extends StatelessWidget {
  const _PRChip({
    required this.pr,
  });

  final PR pr;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Card(
        color: const Color(0xffcbf0cc),
        child: ListTile(
          leading: const SizedBox(
            width: 32.0,
            child: Image(image: AssetImage('assets/images/icon_merge_128.png')),
          ),
          title: Text.rich(
            TextSpan(
              text: 'PR ',
              children: <InlineSpan>[
                WidgetSpan(
                  child: Link.fromString(
                    text: '#${pr.number.toString()}',
                    url: pr.htmlURL,
                  ),
                ),
              ],
            ),
          ),
          subtitle: Text.rich(
            TextSpan(
              text: 'Merged in commit ',
              children: <InlineSpan>[
                WidgetSpan(
                  child: Link.fromString(
                    text: pr.mergeCommitShortSHA!,
                    url: pr.mergeCommitUrl,
                  ),
                ),
                TextSpan(
                  text: ' on ${pr.formattedMergedAt}.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TODO(justinmc): Too low and too bendy.
class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        size: const Size(120.0, 100.0),
        painter: _ArrowPainter(),
      ),
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({
    required this.branch,
    required this.isIn,
    this.mergeDate,
  });

  final Branch branch;
  final bool isIn;
  final String? mergeDate;

  @override
  Widget build(BuildContext context) {
    return switch (isIn) {
      true => Flexible(
        child: Card(
          color: const Color(0xffcbf0cc),
          child: ListTile(
            leading: const SizedBox(
              width: 32.0,
              child: Image(image: AssetImage('assets/images/icon_shipped_128.png')),
            ),
            title: Text(branch.name),
            subtitle: Text.rich(
              TextSpan(
                text: 'Released on the ${branch.name} channel',
                children: <InlineSpan>[
                  if (branch.tagName != null)
                    TextSpan(
                      text: ' in ',
                      children: <InlineSpan>[
                        WidgetSpan(
                          child: Link.fromString(
                            text: 'v${branch.tagName}',
                            url: branch.tagUrl,
                          ),
                        ),
                      ],
                    ),
                  if (mergeDate != null)
                    TextSpan(
                      text: ' on $mergeDate',
                    ),
                  const TextSpan(
                    text: '.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      false => Flexible(
        child: Card(
          color: const Color(0xfff9efc7),
          child: ListTile(
            leading: const SizedBox(
              width: 32.0,
              child: Image(image: AssetImage('assets/images/icon_pending_merge_128.png')),
            ),
            title: Text(branch.name),
            // TODO(justinmc): Display at what version the PR made it into
            // each channel. Can you figure that out based on the tags on the
            // merge commit?
            // Actually, won't the version number be the same for each
            // channel?
            subtitle: Text('Not yet released on the ${branch.name} channel.'),
          ),
        ),
      ),
    };
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    Path path = Path();
    path.moveTo(size.width * 0.25, 60.0);
    path.relativeCubicTo(0, 0, size.width * 0.25, 50, size.width * 0.5, 0);
    path = ArrowPath.addTip(path);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => false;
}

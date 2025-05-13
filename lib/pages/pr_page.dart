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
    // TODO(justinmc): During this time, it says "not released on master branch", when it should be loading instead! I think I intended for the main laoding spinner to handle everything.
    await Future.delayed(const Duration(milliseconds: 5000));
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
    super.initState();
    // TODO(justinmc): Cache this isin data.
    _updateIsIns().then((_) {
      setState(() {
        _finishedLoadingIsIns = true;
      });
    });
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
                if (widget.pr!.status == PRStatus.open)
                  const Text('Open'),
                if (widget.pr!.status == PRStatus.draft)
                  const Text('Draft'),
                if (widget.pr!.status == PRStatus.merged)
                  const Text('Merged'),
                if (widget.pr!.status == PRStatus.closed)
                  const Text('Closed'),
                // TODO(justinmc): When refreshing page, I briefly see all branches but with yellow status. Pop-in from isIn?
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

  bool get _isLoading => master == null || beta == null || stable == null
      || isInMaster == null || isInBeta == null || isInStable == null;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator.adaptive();
    }
    return Row(
      children: <Widget>[
        // TODO(justinmc): If I don't have the necessary data, show a spinner.
        _PRChip(
          pr: pr,
        ),
        const _Arrow(),
        _BranchChip(
          branch: master!,
          isIn: isInMaster!,
          mergeDate: pr.formattedMergedAt,
          prClosed: pr.status == PRStatus.closed,
        ),
        const _Arrow(),
        _BranchChip(
          branch: beta!,
          isIn: isInBeta!,
          prClosed: pr.status == PRStatus.closed,
        ),
        const _Arrow(),
        _BranchChip(
          branch: stable!,
          isIn: isInStable!,
          prClosed: pr.status == PRStatus.closed,
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

  static const String _iconPathPendingMerge = 'assets/images/icon_pending_merge_128.png';
  static const String _iconPathMerge = 'assets/images/icon_merge_128.png';
  static const String _iconPathClosed = 'assets/images/icon_closed_128.png';
  static const String _iconPathShipped = 'assets/images/icon_shipped_128.png';
  static const String _iconPathNeverMerged = 'assets/images/icon_never_merged_128.png';

  Color _getColor(Brightness brightness) {
    return switch (pr.status) {
      PRStatus.open => _BranchChip._getPendingColor(brightness),
      PRStatus.draft => _BranchChip._getDraftColor(brightness),
      PRStatus.merged => _BranchChip._getDoneColor(brightness),
      PRStatus.closed => _BranchChip._getClosedColor(brightness),
    };
  }

  String get _iconPath => switch (pr.status) {
    PRStatus.open => _iconPathPendingMerge,
    PRStatus.draft => _iconPathPendingMerge,
    PRStatus.merged => _iconPathMerge,
    PRStatus.closed => _iconPathClosed,
  };

  TextSpan get _statusText => switch (pr.status) {
    PRStatus.open => const TextSpan(text: ' still open.'),
    PRStatus.draft => const TextSpan(text: ' still in draft.'),
    PRStatus.merged => TextSpan(
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
    PRStatus.closed => const TextSpan(text: ' closed without merge.'),
  };

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return Flexible(
      child: Card(
        color: _getColor(brightness),
        child: ListTile(
          leading: SizedBox(
            width: 32.0,
            child: Image(image: AssetImage(_iconPath)),
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
          subtitle: Text.rich(_statusText),
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
    final Brightness brightness = Theme.of(context).brightness;

    return ClipRect(
      child: CustomPaint(
        size: const Size(120.0, 100.0),
        painter: _ArrowPainter(brightness: brightness),
      ),
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({
    required this.branch,
    required this.isIn,
    required this.prClosed,
    this.mergeDate,
  });

  final Branch branch;
  final bool isIn;
  final String? mergeDate;
  final bool prClosed;

  static const Color _doneColor = Color(0xffcbf0cc);
  static const Color _pendingColor = Color(0xfff9efc7);
  static const Color _closedColor = Color(0xfff7c4c4);
  static const Color _draftColor = Color(0xfff7f2fa);

  static const Color _darkDoneColor = Color(0xff627362);
  static const Color _darkPendingColor = Color(0xff7a7561);
  static const Color _darkClosedColor = Color(0xff5d4a4a);
  static const Color _darkDraftColor = Color(0xff535253);

  static Color _getDoneColor(Brightness brightness) => switch (brightness) {
    Brightness.light => _doneColor,
    Brightness.dark => _darkDoneColor,
  };

  static Color _getPendingColor(Brightness brightness) => switch (brightness) {
    Brightness.light => _pendingColor,
    Brightness.dark => _darkPendingColor,
  };

  static Color _getClosedColor(Brightness brightness) => switch (brightness) {
    Brightness.light => _closedColor,
    Brightness.dark => _darkClosedColor,
  };

  static Color _getDraftColor(Brightness brightness) => switch (brightness) {
    Brightness.light => _draftColor,
    Brightness.dark => _darkDraftColor,
  };

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return switch (isIn) {
      true => Flexible(
        child: Card(
          color: _getDoneColor(brightness),
          child: ListTile(
            leading: const SizedBox(
              width: 32.0,
              child: Image(image: AssetImage(_PRChip._iconPathShipped)),
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
                            // TODO(justinmc): I see a higher version in beta than in stable, is that right??
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
          color: prClosed ? _getClosedColor(brightness) : _getPendingColor(brightness),
          child: ListTile(
            leading: SizedBox(
              width: 32.0,
              child: Image(
                image: AssetImage(prClosed ? _PRChip._iconPathNeverMerged : _PRChip._iconPathPendingMerge),
              ),
            ),
            title: Text(branch.name),
            // TODO(justinmc): Display at what version the PR made it into
            // each channel. Can you figure that out based on the tags on the
            // merge commit?
            // Actually, won't the version number be the same for each
            // channel?
            subtitle: prClosed
                ? Text('Never released on the ${branch.name} channel.')
                : Text('Not yet released on the ${branch.name} channel.'),
          ),
        ),
      ),
    };
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.brightness,
  });

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = switch (brightness) {
        Brightness.light => Colors.black,
        Brightness.dark => const Color(0xffcccccc),
      }
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

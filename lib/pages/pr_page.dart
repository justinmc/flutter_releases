import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/branch.dart';
import '../models/branches.dart';
import '../models/pr.dart';
import '../api.dart' as api;
import '../providers/branches_provider.dart';
import '../widgets/link.dart';

class FrameworkPRPage extends MaterialPage {
  FrameworkPRPage({
    required this.pr,
    final Branch? stable,
    final Branch? beta,
    final Branch? master,
  }) : super(
    key: const ValueKey('FrameworkPRPage'),
    restorationId: 'framework-pr-page',
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
    if (await _updateIsIn(widget.stable) == true) {
      return;
    }
    if (await _updateIsIn(widget.beta) == true) {
      return;
    }
    _updateIsIn(widget.master);
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
        title: Text('Framework PR ${widget.pr.title}'),
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
              Text('This PR is in the following release channels: ${_branchesIsIn.map((BranchNames name) => name.name)}'),
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

// TODO(justinmc): Code reuse, maybe move to separate files.
class EnginePRPage extends MaterialPage {
  EnginePRPage({
    required this.pr,
    final Branch? stable,
    final Branch? beta,
    final Branch? master,
  }) : super(
    key: const ValueKey('EnginePRPage'),
    restorationId: 'engine-pr-page',
    child: _EnginePRPage(
      pr: pr,
      stable: stable,
      beta: beta,
      master: master,
    ),
  );

  final EnginePR pr;
}

class _EnginePRPage extends ConsumerStatefulWidget {
  const _EnginePRPage({
    Key? key,
    required this.pr,
    final this.stable,
    final this.beta,
    final this.master,
  }) : super(key: key);

  final EnginePR pr;
  final Branch? stable;
  final Branch? beta;
  final Branch? master;

  @override
  _EnginePRPageState createState() => _EnginePRPageState();
}

class _EnginePRPageState extends ConsumerState<_EnginePRPage> {
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
    if (await _updateIsIn(widget.stable) == true) {
      return;
    }
    if (await _updateIsIn(widget.beta) == true) {
      return;
    }
    _updateIsIn(widget.master);
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
  void didUpdateWidget(final _EnginePRPage oldWidget) {
    _updateIsIns();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // TODO(justinmc): Actually I need this elsewhere, not in build...
    final Branches branches = ref.watch(branchesProvider);
    print('justin branches what $branches');

    return Scaffold(
      appBar: AppBar(
        title: Text('Engine PR ${widget.pr.title}'),
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
              Text('This PR is in the following release channels: ${_branchesIsIn.map((BranchNames name) => name.name)}'),
            // TODO(justinmc): URL launcher Text(''),
            Link(
              text: 'View on Github',
              url: widget.pr.htmlURL,
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

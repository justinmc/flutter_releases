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

  void _updateIsIns() {
    _isIn(widget.stable).then((final bool? isInStable) {
      if (isInStable == true && !_branchesIsIn.contains(BranchNames.stable)) {
        setState(() {
          _branchesIsIn.add(BranchNames.stable);
        });
      } else if (isInStable == false && _branchesIsIn.contains(BranchNames.stable)) {
        setState(() {
          _branchesIsIn.remove(BranchNames.stable);
        });
      }
    }).catchError((error) {
      print(error);
      setState(() {
        _branchesIsIn.remove(BranchNames.stable);
      });
    });
    _isIn(widget.beta).then((final bool? isInBeta) {
      if (isInBeta == true && !_branchesIsIn.contains(BranchNames.beta)) {
        setState(() {
          _branchesIsIn.add(BranchNames.beta);
        });
      } else if (isInBeta == false && _branchesIsIn.contains(BranchNames.beta)) {
        setState(() {
          _branchesIsIn.remove(BranchNames.beta);
        });
      }
    }).catchError((error) {
      print(error);
      setState(() {
        _branchesIsIn.remove(BranchNames.beta);
      });
    });
    _isIn(widget.master).then((final bool? isInMaster) {
      if (isInMaster == true && !_branchesIsIn.contains(BranchNames.master)) {
        setState(() {
          _branchesIsIn.add(BranchNames.master);
        });
      } else if (isInMaster == false && _branchesIsIn.contains(BranchNames.master)) {
        setState(() {
          _branchesIsIn.remove(BranchNames.master);
        });
      }
    }).catchError((error) {
      print(error);
      setState(() {
        _branchesIsIn.remove(BranchNames.master);
      });
    });
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

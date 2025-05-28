import 'package:flutter/widgets.dart';

import 'package:signals/signals_flutter.dart';

import '../models/branches.dart';

/// Where all Signals are inherited from.
class SignalModel extends InheritedModel<SignalAspect> {
  const SignalModel({
    super.key,
    required this.branchesSignal,
    required super.child,
  });

  final Signal<Branches> branchesSignal;

  static Signal<Branches> branchesSignalOf(BuildContext context) {
    return InheritedModel.inheritFrom<SignalModel>(
      context,
      aspect: SignalAspect.branches,
      // TODO(justinmc): Is this bang dangerous? I think I know that
      // SignalModel will always be in the tree...
    )!
        .branchesSignal;
  }

  @override
  bool updateShouldNotify(SignalModel oldWidget) {
    return branchesSignal != oldWidget.branchesSignal;
  }

  @override
  bool updateShouldNotifyDependent(
      SignalModel oldWidget, Set<SignalAspect> dependencies) {
    if (branchesSignal != oldWidget.branchesSignal &&
        dependencies.contains(SignalAspect.branches)) {
      return true;
    }
    return false;
  }
}

enum SignalAspect {
  branches,
}

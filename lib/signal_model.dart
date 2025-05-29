import 'package:flutter/widgets.dart';

import 'package:signals/signals_flutter.dart';

import '../models/branches.dart';
import '../models/brightness_setting.dart';

// TODO(justinmc): Rename to SignalInheritedModel? It's confusing with the existence of other models.
/// Where all Signals are inherited from.
class SignalModel extends InheritedModel<SignalAspect> {
  const SignalModel({
    super.key,
    required this.branchesSignal,
    required this.brightnessSettingSignal,
    required super.child,
  });

  final Signal<Branches> branchesSignal;
  final Signal<BrightnessSetting> brightnessSettingSignal;

  static Signal<Branches> branchesSignalOf(BuildContext context) {
    return InheritedModel.inheritFrom<SignalModel>(
      context,
      aspect: SignalAspect.branches,
      // TODO(justinmc): Is this bang dangerous? I think I know that
      // SignalModel will always be in the tree...
    )!
        .branchesSignal;
  }

  static Signal<BrightnessSetting> brightnessSettingSignalOf(
    BuildContext context,
  ) {
    return InheritedModel.inheritFrom<SignalModel>(
      context,
      aspect: SignalAspect.branches,
    )!
        .brightnessSettingSignal;
  }

  @override
  bool updateShouldNotify(SignalModel oldWidget) {
    return branchesSignal != oldWidget.branchesSignal ||
        brightnessSettingSignal != oldWidget.brightnessSettingSignal;
  }

  @override
  bool updateShouldNotifyDependent(
      SignalModel oldWidget, Set<SignalAspect> dependencies) {
    if (branchesSignal != oldWidget.branchesSignal &&
        dependencies.contains(SignalAspect.branches)) {
      return true;
    }
    if (brightnessSettingSignal != oldWidget.brightnessSettingSignal &&
        dependencies.contains(SignalAspect.brightnessSetting)) {
      return true;
    }
    return false;
  }
}

enum SignalAspect {
  branches,
  brightnessSetting,
}

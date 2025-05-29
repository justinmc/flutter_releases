import 'package:flutter/widgets.dart';

import 'package:signals/signals_flutter.dart';

import '../models/branches.dart';
import '../models/brightness_setting.dart';

/// Where all Signals are inherited from.
class SignalInheritedModel extends InheritedModel<_SignalAspect> {
  const SignalInheritedModel({
    super.key,
    required this.branchesSignal,
    required this.brightnessSettingSignal,
    required super.child,
  });

  final Signal<Branches> branchesSignal;
  final Signal<BrightnessSetting> brightnessSettingSignal;

  static Signal<Branches> branchesSignalOf(BuildContext context) {
    return InheritedModel.inheritFrom<SignalInheritedModel>(
      context,
      aspect: _SignalAspect.branches,
      // TODO(justinmc): Is this bang dangerous? I think I know that
      // SignalModel will always be in the tree...
    )!
        .branchesSignal;
  }

  static Signal<BrightnessSetting> brightnessSettingSignalOf(
    BuildContext context,
  ) {
    return InheritedModel.inheritFrom<SignalInheritedModel>(
      context,
      aspect: _SignalAspect.branches,
    )!
        .brightnessSettingSignal;
  }

  @override
  bool updateShouldNotify(SignalInheritedModel oldWidget) {
    return branchesSignal != oldWidget.branchesSignal ||
        brightnessSettingSignal != oldWidget.brightnessSettingSignal;
  }

  @override
  bool updateShouldNotifyDependent(
      SignalInheritedModel oldWidget, Set<_SignalAspect> dependencies) {
    if (branchesSignal != oldWidget.branchesSignal &&
        dependencies.contains(_SignalAspect.branches)) {
      return true;
    }
    if (brightnessSettingSignal != oldWidget.brightnessSettingSignal &&
        dependencies.contains(_SignalAspect.brightnessSetting)) {
      return true;
    }
    return false;
  }
}

enum _SignalAspect {
  branches,
  brightnessSetting,
}

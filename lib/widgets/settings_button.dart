import 'package:flutter/material.dart';

import 'settings_dialog_home.dart';
import 'settings_dialog.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.brightnessSetting,
    required this.onChangeBrightnessSetting,
  });

  final BrightnessSetting brightnessSetting;
  final ValueChanged<BrightnessSetting> onChangeBrightnessSetting;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) => SettingsDialog(
            brightnessSetting: brightnessSetting,
            onChangeBrightnessSetting: onChangeBrightnessSetting,
          ),
        );
      },
    );
  }
}

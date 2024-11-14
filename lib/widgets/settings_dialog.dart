import 'package:flutter/material.dart';

import './settings_dialog_about.dart';
import './settings_dialog_home.dart';

enum _SettingsDialogPage {
  home,
  about,
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.onChangeBrightnessSetting,
    required this.brightnessSetting,
  });

  final BrightnessSetting brightnessSetting;
  final ValueChanged<BrightnessSetting> onChangeBrightnessSetting;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  _SettingsDialogPage page = _SettingsDialogPage.home;

  @override
  Widget build(BuildContext context) {
    return switch (page) {
      _SettingsDialogPage.home => SettingsDialogHome(
        brightnessSetting: widget.brightnessSetting,
        onChangeBrightnessSetting: widget.onChangeBrightnessSetting,
        onClose: () {
          Navigator.of(context).pop();
        },
        onSelectAbout: () {
          setState(() {
            page = _SettingsDialogPage.about;
          });
        },
      ),
      _SettingsDialogPage.about => SettingsDialogAbout(
        onBackPressed: () {
          setState(() {
            page = _SettingsDialogPage.home;
          });
        },
      ),
    };
  }
}

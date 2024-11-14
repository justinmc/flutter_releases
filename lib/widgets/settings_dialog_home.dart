import 'package:flutter/material.dart';

class SettingsDialogHome extends StatelessWidget {
  const SettingsDialogHome({
    super.key,
    required this.onClose,
    required this.onSelectAbout,
    required this.brightnessSetting,
    required this.onChangeBrightnessSetting,
  });

  final BrightnessSetting brightnessSetting;
  final VoidCallback onClose;
  final VoidCallback onSelectAbout;
  final ValueChanged<BrightnessSetting> onChangeBrightnessSetting;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Settings'),
      contentPadding: const EdgeInsets.all(32.0),
      children: <Widget>[
        TextButton(
          onPressed: onSelectAbout,
          child: const Text('About'),
        ),
        Row(
          children: <Widget>[
            const Expanded(
              child: Text('Platform brightness'),
            ),
            Switch.adaptive(
              onChanged: (bool value) {
                onChangeBrightnessSetting(switch (value) {
                  true => BrightnessSetting.platform,
                  false => BrightnessSetting.light,
                });
              },
              value: switch (brightnessSetting) {
                BrightnessSetting.light => false,
                BrightnessSetting.dark => false,
                BrightnessSetting.platform => true,
              },
            ),
          ]
        ),
        if (brightnessSetting != BrightnessSetting.platform)
          Row(
            children: <Widget>[
              Expanded(
                child: Text('${brightnessSetting == BrightnessSetting.light ? "Light" : "Dark"} mode'),
              ),
              Switch.adaptive(
                onChanged: (bool value) {
                  onChangeBrightnessSetting(switch (value) {
                    true => BrightnessSetting.light,
                    false => BrightnessSetting.dark,
                  });
                },
                value: brightnessSetting == BrightnessSetting.light,
              ),
            ],
          ),
        TextButton(
          onPressed: onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

enum BrightnessSetting {
  light,
  dark,
  platform,
}

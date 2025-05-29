import 'package:flutter/material.dart';

import 'settings_dialog.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) => const SettingsDialog(),
        );
      },
    );
  }
}

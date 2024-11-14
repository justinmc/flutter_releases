import 'package:flutter/material.dart';

import './link.dart';

class SettingsDialogAbout extends StatelessWidget {
  const SettingsDialogAbout({
    super.key,
    required this.onBackPressed,
  });

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('About'),
      contentPadding: const EdgeInsets.all(32.0),
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 314.0),
          child: Text.rich(
            TextSpan(
              text: 'This little web app was originally built to answer the question: Is this PR in stable yet? Paste a link to a Flutter PR and you\'ll get some info about which Flutter releases it has made it into.\n\nFile any issues ',
              children: <InlineSpan>[
                WidgetSpan(
                  child: Link(
                    uri: Uri.parse('https://www.github.com/justinmc/flutter_releases'),
                    text: 'on GitHub',
                  ),
                ),
                TextSpan(
                  text: ', or reach out to me on X (',
                  children: <InlineSpan>[
                    WidgetSpan(
                      child: Link(
                        uri: Uri.parse('https://x.com/justinjmcc'),
                        text: '@justinjmcc',
                      ),
                    ),
                  ],
                ),
                const TextSpan(
                  text: ') for anything else.\n\nThis project sometimes hits GitHub\'s rate limiting due to my own lazy engineering, so coming back later might work if it appears to be down.',
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onBackPressed,
          child: const Text('Back'),
        ),
      ],
    );
  }
}

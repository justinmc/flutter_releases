import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String kGitHub = 'https://www.github.com';
const String kGitHubFlutter = '$kGitHub/flutter/flutter';

/// Just a link.
///
/// Similar to an <a> tag in HTML.
class Link extends StatelessWidget {
  const Link({
    super.key,
    required this.text,
    this.uri,
  }) : onTap = null;

  Link.fromString({
    super.key,
    required this.text,
    required String url,
  }) : onTap = null,
      uri = Uri.parse(url);

  const Link.tap({
    super.key,
    required this.text,
    required this.onTap,
  }) : uri = null;

  final String text;
  final Uri? uri;
  final VoidCallback? onTap;

  void _onTap() async {
    if (onTap != null) {
      return onTap!();
    }
    if (!await launchUrl(uri!)) throw 'Could not launch $uri.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

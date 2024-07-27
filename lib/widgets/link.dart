import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart' as url_launcher_link;

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

  @override
  Widget build(BuildContext context) {
    return url_launcher_link.Link(
      uri: uri,
      target: url_launcher_link.LinkTarget.blank,
      builder: (BuildContext context, url_launcher_link.FollowLink? followLink) {
        return GestureDetector(
          onTap: () {
            if (onTap != null) {
              return onTap!();
            }
            if (followLink != null) {
              followLink();
            }
          },
          child: DefaultSelectionStyle(
            mouseCursor: SystemMouseCursors.click,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Just a link.
///
/// Similar to an <a> tag in HTML.
class Link extends StatelessWidget {
  const Link({
    Key? key,
    required this.text,
    this.url,
    this.onTap,
  }) : assert((url == null) != (onTap == null)),
       super(key: key);

  final String text;
  final String? url;
  final VoidCallback? onTap;

  void _onTap() async {
    if (onTap != null) {
      return onTap!();
    }
    if (!await launch(url!)) throw 'Could not launch $url.';
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

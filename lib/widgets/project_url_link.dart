import 'package:flutter/material.dart';

import '../utils/link_launcher.dart';

/// Renders a project URL as a tappable link that opens in the browser
/// (a new tab on web). Shows a snackbar if the link can't be opened.
class ProjectUrlLink extends StatelessWidget {
  const ProjectUrlLink({
    super.key,
    required this.url,
    this.style,
  });

  final String url;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = (style ?? theme.textTheme.bodySmall)?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                url,
                style: linkStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final opened = openExternalUrl(url);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}

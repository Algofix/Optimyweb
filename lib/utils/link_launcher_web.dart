import 'package:web/web.dart' as web;

/// Opens [url] in a new browser tab using the DOM `window.open` API.
bool openUrl(String url) {
  final opened = web.window.open(url, '_blank');
  return opened != null;
}

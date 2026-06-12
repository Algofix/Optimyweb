import 'link_launcher_stub.dart'
    if (dart.library.js_interop) 'link_launcher_web.dart' as impl;

/// Opens [rawUrl] in the platform browser (a new tab on web).
///
/// The URL is normalised first: a bare host such as `example.com` is treated
/// as `https://example.com`. Returns `true` when the browser open was
/// attempted successfully, `false` when the URL is empty/invalid or the
/// current platform cannot open links.
bool openExternalUrl(String rawUrl) {
  final normalized = normalizeUrl(rawUrl);
  if (normalized == null) return false;
  return impl.openUrl(normalized);
}

/// Returns a launchable absolute URL, or `null` if [rawUrl] is blank/invalid.
String? normalizeUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;

  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    return parsed.toString();
  }

  final withScheme = Uri.tryParse('https://$trimmed');
  if (withScheme != null && withScheme.host.isNotEmpty) {
    return withScheme.toString();
  }
  return null;
}

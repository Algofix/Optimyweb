/// Fallback used on non-web platforms.
///
/// Opening an external browser on mobile/desktop requires a platform plugin
/// (e.g. `url_launcher`), which is not wired up here, so this is a no-op that
/// reports failure to the caller.
bool openUrl(String url) => false;

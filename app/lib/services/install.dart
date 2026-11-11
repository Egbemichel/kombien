/// "Install Kombien" (web only): whether the browser can install the app,
/// and asking it to. Off the web, nothing is offered.
library;

export 'install_stub.dart' if (dart.library.js_interop) 'install_web.dart';

/// What Settings can offer.
enum InstallOffer {
  /// Already installed, or this browser can't install apps: no row.
  none,

  /// The browser's own install prompt is ready.
  prompt,

  /// iPhone / iPad: Safari's Share → Add to Home Screen, explained.
  ios,
}

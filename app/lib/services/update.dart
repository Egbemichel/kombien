/// "Update ready" (web only): a new release has downloaded in the
/// background; restarting shows it. Off the web, app stores update apps.
library;

export 'update_stub.dart' if (dart.library.js_interop) 'update_web.dart';

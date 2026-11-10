import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'install.dart';

/// Set up by web/index.html before the app starts.
@JS('kombienInstall')
external _Install? get _install;

@JS('addEventListener')
external void _listen(String type, JSFunction callback);

extension type _Install(JSObject _) implements JSObject {
  external bool get available;
  external bool get installed;
  external bool get ios;
  external JSPromise<JSString> ask();
}

InstallOffer _read() {
  final i = _install;
  if (i == null || i.installed) return InstallOffer.none;
  if (i.available) return InstallOffer.prompt;
  if (i.ios) return InstallOffer.ios;
  return InstallOffer.none;
}

final ValueNotifier<InstallOffer> installOffer = () {
  final n = ValueNotifier(_read());
  _listen(
    'kombien-install-change',
    () {
      n.value = _read();
    }.toJS,
  );
  return n;
}();

/// Shows the browser's install prompt; true when the rider accepted.
Future<bool> askToInstall() async {
  final i = _install;
  if (i == null) return false;
  final outcome = (await i.ask().toDart).toDart;
  installOffer.value = _read();
  return outcome == 'accepted';
}

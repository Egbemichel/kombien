import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Set up by web/index.html before the app starts.
@JS('kombienUpdate')
external _Update? get _update;

@JS('addEventListener')
external void _listen(String type, JSFunction callback);

extension type _Update(JSObject _) implements JSObject {
  external bool get ready;
  external void apply();
}

final ValueNotifier<bool> updateReady = () {
  final n = ValueNotifier(_update?.ready ?? false);
  _listen(
    'kombien-update-ready',
    () {
      n.value = true;
    }.toJS,
  );
  return n;
}();

/// Restarts the app on the new release.
void applyUpdate() => _update?.apply();

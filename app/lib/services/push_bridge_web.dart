import 'dart:js_interop';

/// Set up by web/index.html (and push-config.js) before the app starts.
@JS('kombienPush')
external _Push? get _push;

extension type _Push(JSObject _) implements JSObject {
  external bool supported();
  external String permission();
  external JSPromise<JSString> enable();
  external JSPromise<JSString> disable();
}

bool supported() => _push?.supported() ?? false;

String permission() => _push?.permission() ?? 'denied';

Future<String> enable() async {
  final p = _push;
  return p == null ? '' : (await p.enable().toDart).toDart;
}

Future<String> disable() async {
  final p = _push;
  return p == null ? '' : (await p.disable().toDart).toDart;
}

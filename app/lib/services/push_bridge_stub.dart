// Off the web: no web push (store builds will use their own).
bool supported() => false;
String permission() => 'denied';
Future<String> enable() async => '';
Future<String> disable() async => '';

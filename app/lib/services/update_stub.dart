import 'package:flutter/foundation.dart';

final ValueNotifier<bool> updateReady = ValueNotifier(false);

/// Never called off the web.
void applyUpdate() {}

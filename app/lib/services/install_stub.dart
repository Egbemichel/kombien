import 'package:flutter/foundation.dart';

import 'install.dart';

final ValueNotifier<InstallOffer> installOffer = ValueNotifier(
  InstallOffer.none,
);

/// Never called off the web.
Future<bool> askToInstall() async => false;

import 'package:kombien/app/app_state.dart';
import 'package:kombien/data/city_pack.dart';
import 'package:kombien/data/fare_repository.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/data/place_requests.dart';
import 'package:kombien/services/location_service.dart';
import 'package:kombien/services/push.dart';

/// Location without a phone: starts at [current]; a request answers [answer].
class FakeLocation extends LocationService {
  FakeLocation({
    this.current = LocationAccess.denied,
    this.answer = LocationAccess.granted,
    this.at,
    this.fixResult,
  });
  LocationAccess current;
  LocationAccess answer;
  int requests = 0;

  /// What a precise fix answers (a place being added); null: none.
  PositionFix? fixResult;

  @override
  Future<PositionFix?> fix({
    Duration timeout = const Duration(seconds: 12),
  }) async => fixResult;

  /// Where the phone is; null: no fix.
  (double, double)? at;

  @override
  Future<(double, double)?> position() async => at;

  @override
  Future<LocationAccess> status() async => current;

  @override
  Future<LocationAccess> request() async {
    requests++;
    return current = answer;
  }
}

/// App state wired to a fake location service.
KAppState fakeState({
  LocationAccess current = LocationAccess.denied,
  LocationAccess answer = LocationAccess.granted,
  FareRepository? fares,
  (double, double)? at,
  CityPacks? packs,
  PushClient? push,
  PlaceRequests? placeRequests,
}) => KAppState(
  location: FakeLocation(current: current, answer: answer, at: at),
  fares: fares,
  packs: packs,
  push: push,
  placeRequests: placeRequests,
);

/// Fares that always answer [answer], or throw (offline) when [offline].
class FakeFares implements FareRepository {
  FakeFares({this.answer, this.offline = false});
  final FareRange? answer;
  final bool offline;

  /// Every route asked for.
  final asked = <(Landmark, Landmark)>[];

  @override
  Future<FareRange?> range(Landmark from, Landmark to) async {
    asked.add((from, to));
    if (offline) throw Exception('offline');
    return answer;
  }
}

/// A browser and server for notifications, recording what was asked.
class FakePush implements PushClient {
  FakePush({this.supported = true, this.permission = 'default'});
  @override
  bool supported;
  @override
  String permission;

  /// What the browser answers when asked.
  bool allow = true;
  final calls = <String>[];

  @override
  Future<bool> enable(String locale) async {
    calls.add('enable $locale');
    permission = allow ? 'granted' : 'denied';
    return allow;
  }

  @override
  Future<void> disable() async => calls.add('disable');

  @override
  Future<void> setLocale(String locale) async => calls.add('locale $locale');

  @override
  Future<void> routeReported(String fromId, String toId) async =>
      calls.add('reported $fromId→$toId');

  @override
  Future<void> flush() async => calls.add('flush');

  @override
  Future<void> thanks() async => calls.add('thanks');

  @override
  Future<String> sendTest() async {
    calls.add('test');
    return 'sent';
  }
}

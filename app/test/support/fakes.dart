import 'package:kombien/app/app_state.dart';
import 'package:kombien/data/city_pack.dart';
import 'package:kombien/data/fare_repository.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/services/location_service.dart';

/// Location without a phone: starts at [current]; a request answers [answer].
class FakeLocation extends LocationService {
  FakeLocation({
    this.current = LocationAccess.denied,
    this.answer = LocationAccess.granted,
    this.at,
  });
  LocationAccess current;
  LocationAccess answer;
  int requests = 0;

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
}) => KAppState(
  location: FakeLocation(current: current, answer: answer, at: at),
  fares: fares,
  packs: packs,
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

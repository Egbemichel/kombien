/// Which release this is, in words people remember.
///
/// Releases are named like Tony Stark's suits: Mark I, Mark II, Mark III...
/// A Mark is a milestone and holds several versions (pubspec.yaml's
/// version, passed in at build time). When a release deserves a new name,
/// change [mark] here.
abstract final class Release {
  static const mark = 'Mark I';

  /// pubspec.yaml's version (without the +build), from the build script.
  static const version = String.fromEnvironment(
    'KOMBIEN_VERSION',
    defaultValue: '0.1.0',
  );

  /// When this build was made (yymmdd.HHMM, UTC): tells phones an update
  /// exists; never shown. Empty in development.
  static const build = String.fromEnvironment('KOMBIEN_BUILD');

  /// The exact build, for problem reports (at most 20 characters).
  static const tag = build == '' ? version : '$version+$build';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageCode => 'En';

  @override
  String get menuFares => 'Je paie combien?';

  @override
  String get menuReport => 'Report';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuStyleGuide => 'Style guide';

  @override
  String get skip => 'Skip';

  @override
  String get continueAction => 'Continue';

  @override
  String get getStarted => 'Get started';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get onboardingFaresTitle => 'Je paie combien?';

  @override
  String get onboardingFaresBody =>
      'See what other riders reported for your route before you start negotiating. A range, not a guess.';

  @override
  String get onboardingFaresFootnote =>
      'Fares are reported by riders. They\'re not official.';

  @override
  String get onboardingBubbleAsk => 'Post Centrale,\nXAF 500';

  @override
  String get onboardingBubbleReply => 'Non';

  @override
  String get onboardingReportTitle => 'Paid? Say so.';

  @override
  String get onboardingReportBody =>
      'Add what you paid in a few taps. The next rider will see it.';

  @override
  String get onboardingReportFootnote => 'Help someone help you';

  @override
  String get termsLead => 'I Agree to Kombien\'s ';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get termsJoin => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsTail => '';

  @override
  String get locationPromptTitle =>
      'Hey there! Worried about what fare to propose?';

  @override
  String get locationPromptBody =>
      'Turn on location so Kombien can pinpoint your exact starting spot and match it against real fares reported by other riders nearby. Propose with confidence. No guessing, no overpaying.';

  @override
  String get locationPromptAction => 'Get started from where I am';

  @override
  String get locationPromptSkip => 'Skip for now';

  @override
  String get whereFrom => 'Where are you leaving from?';

  @override
  String get myLocation => 'My location';

  @override
  String get searchLandmark => 'Search a landmark';

  @override
  String get locationDenied =>
      'Can\'t see where you are. Search a landmark instead';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get turnOnLocation => 'Location is off. Turn it on';

  @override
  String get whereTo => 'Tu go où?';

  @override
  String get startTyping => 'Start typing...';

  @override
  String get seeAllSuggestions => 'See all suggestions';

  @override
  String get savedDestinations => 'Your saved destinations';

  @override
  String get savedEmptyHint =>
      'Pick a place, then tap Save this place to keep it here.';

  @override
  String get saveThisPlace => 'Save this place';

  @override
  String savedAs(String name) {
    return 'Saved as $name';
  }

  @override
  String saveAs(String name) {
    return 'Save as $name';
  }

  @override
  String get nameThePlace => 'Name ';

  @override
  String get otherName => 'Other name…';

  @override
  String get placeHome => 'Home';

  @override
  String get placeSchool => 'School';

  @override
  String get placeWork => 'Work';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get fareBasedOn => 'Based on past rider reports';

  @override
  String get fareDemo => 'Demo range, not real reports yet';

  @override
  String get fareDisclaimer =>
      'This range is a crowd-sourced average of what real riders recently paid on this route, not official fares. It\'s a guide to help you propose, not a fixed or guaranteed price.';

  @override
  String get fareCurrency => 'FCFA';

  @override
  String get bringCash => 'Make sure to bring cash';

  @override
  String get feedbackQuestion => 'Was this information helpful?';

  @override
  String get feedbackThanksLabel => 'Thank you!';

  @override
  String get feedbackThanksTitle => 'Feedback recorded!';

  @override
  String get feedbackThanksBody =>
      'Your answer will help us make the product even better';

  @override
  String get startMissing => 'Add where you\'re leaving from first';

  @override
  String get startPickOne => 'Pick your starting point from the suggestions';

  @override
  String get paidSomethingElse => 'Paid something else?';

  @override
  String get reportItHere => 'Report it here';

  @override
  String get noReportsTitle => 'No reports yet for this route. Be the first.';

  @override
  String get addReport => 'Add report';

  @override
  String get noMatchTitle =>
      'Couldn\'t find that place. Try a nearby landmark instead';

  @override
  String get offlineTitle => 'No connection. Showing saved fares.';

  @override
  String get offlineNoSaved => 'No connection. Check your data and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get savedFareNote =>
      'Saved fare from your last search. It may be out of date.';

  @override
  String get reportFromLabel => 'Where are you/did you leave from?';

  @override
  String get reportTo => 'To';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportingFor => 'You are reporting for the route starting...';

  @override
  String get routeFrom => 'From';

  @override
  String get routeTo => 'To';

  @override
  String get priceSuggestions => 'Some suggestions (prices in FCFA)';

  @override
  String get optional => 'Optional';

  @override
  String get timeOfDay => 'Time of day';

  @override
  String get dayMorning => 'Morning';

  @override
  String get dayDay => 'Day';

  @override
  String get dayNight => 'Night';

  @override
  String get weather => 'Weather condition';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherRainy => 'Rainy';

  @override
  String get vehicleType => 'Vehicle type';

  @override
  String get vehicleTaxi => 'Taxi';

  @override
  String get vehicleMoto => 'Moto';

  @override
  String get reportAddedLabel => 'Thanks!';

  @override
  String get reportAddedTitle => 'Report added!';

  @override
  String get reportAddedBody =>
      'Your report is now helping other riders on this route';

  @override
  String get reportQueuedTitle => 'Saved on this phone';

  @override
  String get reportQueuedBody => 'It will be sent when you\'re back online';

  @override
  String get amountRange => 'Enter an amount between 50 and 50 000 FCFA';

  @override
  String get back => 'Back';

  @override
  String get settingsLocation => 'Location';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get myCity => 'My city';

  @override
  String get myCityNote =>
      'Sets which offline pack to keep and update, data from other cities gets deleted from this device after some time';

  @override
  String get offline => 'Offline';

  @override
  String get savedFaresMap => 'Saved fares and map';

  @override
  String get savedOnPhone => 'Saved on this phone.';

  @override
  String updatedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Updated $days days ago',
      one: 'Updated yesterday',
      zero: 'Updated today',
    );
    return '$_temp0';
  }

  @override
  String get addCity => 'Add a city';

  @override
  String get chooseCity => 'Choose your city';

  @override
  String get offlineData => 'Offline data';

  @override
  String get sendingReports => 'Sending reports';

  @override
  String get wifiAndMobile => 'Wi-Fi and mobile data';

  @override
  String get mobileOnly => 'Mobile data only';

  @override
  String get wifiOnly => 'Wi-Fi Only';

  @override
  String get privacy => 'Privacy';

  @override
  String get whatKombienStores => 'What Kombien stores';

  @override
  String get whatKombienStoresBody =>
      'No account, no name, no phone number. A fare report is a route, a price, the time, and optional details (weather, vehicle). Each phone signs in anonymously so spam can be stopped, never to follow anyone. Only route averages are ever shown, and only once enough riders reported a route. Saved places, your language and your settings stay on this phone.';

  @override
  String get myReports => 'My reports';

  @override
  String get reportsFromPhone => 'Reports from this phone';

  @override
  String get aboutKombien => 'About Kombien';

  @override
  String get howFaresWork => 'How reported fares work';

  @override
  String get howFaresWorkBody =>
      'Riders report what they paid after a ride. For each route, Kombien shows the middle half of recent reports (the last 90 days) as a range, so one odd price doesn\'t move it. A route needs at least 3 reports before a range appears. It\'s a guide for negotiating, not an official fare.';

  @override
  String get contributeGithub => 'Contribute on Github';

  @override
  String get devAbout => 'About the developer';

  @override
  String get devHello => 'Hey, I\'m Mich!';

  @override
  String get devStory =>
      'Built Kombien so we all stop getting laughed at by taxi drivers. Drop your fare after your next ride to keep the community sharp!';

  @override
  String get devCoffeeAsk =>
      'Saved some cash today? Toss a coffee my way to keep the servers running.';

  @override
  String get devCoffee => 'Get the dev a coffee';

  @override
  String get devThanksLead => 'Special thanks to ';

  @override
  String get devThanksTail =>
      ' for all the wisdom and help proving once more the immense power of experience';

  @override
  String get letsConnect => 'Let\'s connect';

  @override
  String get devTagline =>
      'Curious, intentional and always chasing the next idea worth bringing to life';

  @override
  String noSavedFares(String city) {
    return 'No saved fares for $city yet. Download them to use Kombien without a connection.';
  }

  @override
  String reportsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count reports waiting for a connection. They\'ll send automatically',
      one: '1 report waiting for a connection. It\'ll send automatically',
    );
    return '$_temp0';
  }

  @override
  String deleteReportsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete the $count reports saved on this phone?',
      one: 'Delete the report saved on this phone?',
    );
    return '$_temp0';
  }

  @override
  String get deleteReportsBody =>
      'Reports already sent stay in the shared data.';

  @override
  String get deleteReportsAction => 'Delete reports from this phone';

  @override
  String get delete => 'Delete';

  @override
  String get myReportsTitle => 'My reports';

  @override
  String get myReportsEmpty =>
      'No reports from this phone yet. Paid for a ride? Report it, the next rider will thank you.';

  @override
  String get reportSent => 'Sent';

  @override
  String get reportWaiting => 'Waiting for a connection';

  @override
  String get close => 'Close';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get problemTitle => 'Something not right?';

  @override
  String get problemWhat => 'What went wrong?';

  @override
  String get problemWrongFare => 'A fare looks wrong';

  @override
  String get problemPlaceMissing => 'A place is missing';

  @override
  String get problemBug => 'Something doesn\'t work';

  @override
  String get problemOther => 'Something else';

  @override
  String get problemWhere => 'Where did it happen?';

  @override
  String get whereFares => 'Finding fares';

  @override
  String get whereReport => 'Reporting';

  @override
  String get whereSettings => 'Settings';

  @override
  String get whereOther => 'Somewhere else';

  @override
  String get problemMore => 'Tell us more (optional)';

  @override
  String get problemMoreHint => 'What happened?';

  @override
  String get send => 'Send';

  @override
  String get problemThanksLabel => 'Thank you!';

  @override
  String get problemThanksTitle => 'Problem reported';

  @override
  String get problemThanksBody =>
      'We read every report and use it to make Kombien better.';

  @override
  String get installKombien => 'Install Kombien';

  @override
  String get installIosTitle => 'Put Kombien on your home screen';

  @override
  String get installIosBody =>
      'In Safari, tap the Share button, then \"Add to Home Screen\". Kombien then opens like an app, even offline.';

  @override
  String get installedLabel => 'Installed';

  @override
  String get installedTitle => 'Kombien is on your phone';

  @override
  String get installedBody =>
      'Open it from your home screen, even without internet.';

  @override
  String get osmCredit =>
      'Places © OpenStreetMap contributors, Overture Maps Foundation, GeoNames';

  @override
  String get packFailedLabel => 'No connection';

  @override
  String get packFailedTitle => 'Couldn\'t save that city';

  @override
  String get packFailedBody =>
      'Kombien will try again when you\'re back online.';

  @override
  String get updateLabel => 'New version';

  @override
  String get updateTitle => 'Kombien has been updated';

  @override
  String get updateBody => 'Restart to use the latest version.';

  @override
  String get updateAction => 'Restart';

  @override
  String arrivedTitle(String place) {
    return 'Arrived at $place?';
  }

  @override
  String arrivedBody(String from) {
    return 'What did you pay from $from? One tap helps the next rider.';
  }

  @override
  String get arrivedOther => 'Another amount';

  @override
  String get notNow => 'Not now';

  @override
  String get arrivedThanksLabel => 'Thank you!';

  @override
  String get arrivedThanksTitle => 'Fare added';

  @override
  String get arrivedThanksBody => 'Riders on this route will see it.';

  @override
  String get unlockedLabel => 'You did that';

  @override
  String get unlockedTitle => 'Fares unlocked';

  @override
  String unlockedBody(String from, String to) {
    return 'Your report helped show a fare range for $from → $to.';
  }

  @override
  String get cityMovedLabel => 'New city';

  @override
  String cityMovedTitle(String city) {
    return 'You\'re in $city';
  }

  @override
  String cityMovedBody(String city) {
    return 'Kombien now shows $city places and fares.';
  }

  @override
  String get undo => 'Undo';

  @override
  String release(String mark, String version) {
    return '$mark · version $version';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get pushUnlockedRow => 'When my report unlocks fares';

  @override
  String get pushOfferLabel => 'Stay in the loop';

  @override
  String get pushOfferTitle => 'Want to know when it counts?';

  @override
  String get pushOfferBody =>
      'Get a notification when your report unlocks fares for a route.';

  @override
  String get pushOfferAction => 'Turn on';

  @override
  String get pushOnLabel => 'Done';

  @override
  String get pushOnTitle => 'Notifications on';

  @override
  String get pushOnBody => 'At most one a day, never at night.';

  @override
  String get pushBlockedLabel => 'Blocked';

  @override
  String get pushBlockedTitle => 'Notifications are blocked';

  @override
  String get pushBlockedBody =>
      'Allow them for Kombien in your browser or phone settings.';

  @override
  String get pushTestLabel => 'Test';

  @override
  String get pushTestSentTitle => 'Test notification sent';

  @override
  String get pushTestSentBody => 'It should arrive in a few seconds.';

  @override
  String get pushTestFailTitle => 'Couldn\'t send a test';

  @override
  String get placeMissingLink => 'Not the place? Tell us';

  @override
  String get placeMissingAction => 'Tell us about it';

  @override
  String nearPlace(String place) {
    return 'Near $place';
  }
}

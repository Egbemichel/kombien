import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Short code in the language selector.
  ///
  /// In en, this message translates to:
  /// **'En'**
  String get languageCode;

  /// Menu entry for the fare lookup. The brand phrase: same in every language.
  ///
  /// In en, this message translates to:
  /// **'Je paie combien?'**
  String get menuFares;

  /// No description provided for @menuReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get menuReport;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuStyleGuide.
  ///
  /// In en, this message translates to:
  /// **'Style guide'**
  String get menuStyleGuide;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Brand phrase: same in every language.
  ///
  /// In en, this message translates to:
  /// **'Je paie combien?'**
  String get onboardingFaresTitle;

  /// No description provided for @onboardingFaresBody.
  ///
  /// In en, this message translates to:
  /// **'See what other riders reported for your route before you start negotiating. A range, not a guess.'**
  String get onboardingFaresBody;

  /// No description provided for @onboardingFaresFootnote.
  ///
  /// In en, this message translates to:
  /// **'Fares are reported by riders. They\'re not official.'**
  String get onboardingFaresFootnote;

  /// Rider hailing a taxi: destination and offered price.
  ///
  /// In en, this message translates to:
  /// **'Post Centrale,\nXAF 500'**
  String get onboardingBubbleAsk;

  /// Driver's reply. Kept in French: it is what drivers say.
  ///
  /// In en, this message translates to:
  /// **'Non'**
  String get onboardingBubbleReply;

  /// No description provided for @onboardingReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid? Say so.'**
  String get onboardingReportTitle;

  /// No description provided for @onboardingReportBody.
  ///
  /// In en, this message translates to:
  /// **'Add what you paid in a few taps. The next rider will see it.'**
  String get onboardingReportBody;

  /// No description provided for @onboardingReportFootnote.
  ///
  /// In en, this message translates to:
  /// **'Help someone help you'**
  String get onboardingReportFootnote;

  /// No description provided for @termsLead.
  ///
  /// In en, this message translates to:
  /// **'I Agree to Kombien\'s '**
  String get termsLead;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @termsJoin.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsJoin;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsTail.
  ///
  /// In en, this message translates to:
  /// **''**
  String get termsTail;

  /// No description provided for @locationPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Hey there! Worried about what fare to propose?'**
  String get locationPromptTitle;

  /// No description provided for @locationPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on location so Kombien can pinpoint your exact starting spot and match it against real fares reported by other riders nearby. Propose with confidence. No guessing, no overpaying.'**
  String get locationPromptBody;

  /// No description provided for @locationPromptAction.
  ///
  /// In en, this message translates to:
  /// **'Get started from where I am'**
  String get locationPromptAction;

  /// No description provided for @locationPromptSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get locationPromptSkip;

  /// No description provided for @whereFrom.
  ///
  /// In en, this message translates to:
  /// **'Where are you leaving from?'**
  String get whereFrom;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @searchLandmark.
  ///
  /// In en, this message translates to:
  /// **'Search a landmark'**
  String get searchLandmark;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Can\'t see where you are. Search a landmark instead'**
  String get locationDenied;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @turnOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Turn it on'**
  String get turnOnLocation;

  /// Franglais brand phrase: same in every language.
  ///
  /// In en, this message translates to:
  /// **'Tu go où?'**
  String get whereTo;

  /// No description provided for @startTyping.
  ///
  /// In en, this message translates to:
  /// **'Start typing...'**
  String get startTyping;

  /// No description provided for @seeAllSuggestions.
  ///
  /// In en, this message translates to:
  /// **'See all suggestions'**
  String get seeAllSuggestions;

  /// No description provided for @savedDestinations.
  ///
  /// In en, this message translates to:
  /// **'Your saved destinations'**
  String get savedDestinations;

  /// No description provided for @savedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a place, then tap Save this place to keep it here.'**
  String get savedEmptyHint;

  /// No description provided for @saveThisPlace.
  ///
  /// In en, this message translates to:
  /// **'Save this place'**
  String get saveThisPlace;

  /// No description provided for @savedAs.
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String savedAs(String name);

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as {name}'**
  String saveAs(String name);

  /// Followed by the place in bold: 'Name Eyang'.
  ///
  /// In en, this message translates to:
  /// **'Name '**
  String get nameThePlace;

  /// No description provided for @otherName.
  ///
  /// In en, this message translates to:
  /// **'Other name…'**
  String get otherName;

  /// No description provided for @placeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get placeHome;

  /// No description provided for @placeSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get placeSchool;

  /// No description provided for @placeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get placeWork;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @fareBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Based on past rider reports'**
  String get fareBasedOn;

  /// No description provided for @fareDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo range, not real reports yet'**
  String get fareDemo;

  /// No description provided for @fareDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This range is a crowd-sourced average of what real riders recently paid on this route, not official fares. It\'s a guide to help you propose, not a fixed or guaranteed price.'**
  String get fareDisclaimer;

  /// No description provided for @fareCurrency.
  ///
  /// In en, this message translates to:
  /// **'FCFA'**
  String get fareCurrency;

  /// No description provided for @bringCash.
  ///
  /// In en, this message translates to:
  /// **'Make sure to bring cash'**
  String get bringCash;

  /// No description provided for @feedbackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Was this information helpful?'**
  String get feedbackQuestion;

  /// No description provided for @feedbackThanksLabel.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get feedbackThanksLabel;

  /// No description provided for @feedbackThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback recorded!'**
  String get feedbackThanksTitle;

  /// No description provided for @feedbackThanksBody.
  ///
  /// In en, this message translates to:
  /// **'Your answer will help us make the product even better'**
  String get feedbackThanksBody;

  /// No description provided for @startMissing.
  ///
  /// In en, this message translates to:
  /// **'Add where you\'re leaving from first'**
  String get startMissing;

  /// No description provided for @startPickOne.
  ///
  /// In en, this message translates to:
  /// **'Pick your starting point from the suggestions'**
  String get startPickOne;

  /// No description provided for @paidSomethingElse.
  ///
  /// In en, this message translates to:
  /// **'Paid something else?'**
  String get paidSomethingElse;

  /// No description provided for @reportItHere.
  ///
  /// In en, this message translates to:
  /// **'Report it here'**
  String get reportItHere;

  /// No description provided for @noReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet for this route. Be the first.'**
  String get noReportsTitle;

  /// No description provided for @addReport.
  ///
  /// In en, this message translates to:
  /// **'Add report'**
  String get addReport;

  /// No description provided for @noMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that place. Try a nearby landmark instead'**
  String get noMatchTitle;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection. Showing saved fares.'**
  String get offlineTitle;

  /// No description provided for @offlineNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your data and try again.'**
  String get offlineNoSaved;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @savedFareNote.
  ///
  /// In en, this message translates to:
  /// **'Saved fare from your last search. It may be out of date.'**
  String get savedFareNote;

  /// No description provided for @reportFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Where are you/did you leave from?'**
  String get reportFromLabel;

  /// No description provided for @reportTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reportTo;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// No description provided for @reportingFor.
  ///
  /// In en, this message translates to:
  /// **'You are reporting for the route starting...'**
  String get reportingFor;

  /// No description provided for @routeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get routeFrom;

  /// No description provided for @routeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get routeTo;

  /// No description provided for @priceSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Some suggestions (prices in FCFA)'**
  String get priceSuggestions;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @timeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get timeOfDay;

  /// No description provided for @dayMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get dayMorning;

  /// No description provided for @dayDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayDay;

  /// No description provided for @dayNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get dayNight;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather condition'**
  String get weather;

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherRainy.
  ///
  /// In en, this message translates to:
  /// **'Rainy'**
  String get weatherRainy;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleType;

  /// No description provided for @vehicleTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get vehicleTaxi;

  /// No description provided for @vehicleMoto.
  ///
  /// In en, this message translates to:
  /// **'Moto'**
  String get vehicleMoto;

  /// No description provided for @reportAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Thanks!'**
  String get reportAddedLabel;

  /// No description provided for @reportAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report added!'**
  String get reportAddedTitle;

  /// No description provided for @reportAddedBody.
  ///
  /// In en, this message translates to:
  /// **'Your report is now helping other riders on this route'**
  String get reportAddedBody;

  /// No description provided for @reportQueuedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get reportQueuedTitle;

  /// No description provided for @reportQueuedBody.
  ///
  /// In en, this message translates to:
  /// **'It will be sent when you\'re back online'**
  String get reportQueuedBody;

  /// No description provided for @amountRange.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount between 50 and 50 000 FCFA, in steps of 50'**
  String get amountRange;

  /// No description provided for @sameRoute.
  ///
  /// In en, this message translates to:
  /// **'Where you leave from and where you go can\'t be the same place'**
  String get sameRoute;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsLocation;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @myCity.
  ///
  /// In en, this message translates to:
  /// **'My city'**
  String get myCity;

  /// No description provided for @myCityNote.
  ///
  /// In en, this message translates to:
  /// **'Sets which offline pack to keep and update, data from other cities gets deleted from this device after some time'**
  String get myCityNote;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @savedFaresMap.
  ///
  /// In en, this message translates to:
  /// **'Saved fares and map'**
  String get savedFaresMap;

  /// No description provided for @savedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone.'**
  String get savedOnPhone;

  /// No description provided for @updatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Updated today} =1{Updated yesterday} other{Updated {days} days ago}}'**
  String updatedDaysAgo(int days);

  /// No description provided for @addCity.
  ///
  /// In en, this message translates to:
  /// **'Add a city'**
  String get addCity;

  /// No description provided for @chooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose your city'**
  String get chooseCity;

  /// No description provided for @offlineData.
  ///
  /// In en, this message translates to:
  /// **'Offline data'**
  String get offlineData;

  /// No description provided for @sendingReports.
  ///
  /// In en, this message translates to:
  /// **'Sending reports'**
  String get sendingReports;

  /// No description provided for @wifiAndMobile.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi and mobile data'**
  String get wifiAndMobile;

  /// No description provided for @mobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Mobile data only'**
  String get mobileOnly;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Only'**
  String get wifiOnly;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @whatKombienStores.
  ///
  /// In en, this message translates to:
  /// **'What Kombien stores'**
  String get whatKombienStores;

  /// No description provided for @whatKombienStoresBody.
  ///
  /// In en, this message translates to:
  /// **'No account, no name, no phone number. A fare report is a route, a price, the time, and optional details (weather, vehicle). Each phone signs in anonymously so spam can be stopped, never to follow anyone. Only route averages are ever shown, and only once enough riders reported a route. Saved places, your language and your settings stay on this phone.'**
  String get whatKombienStoresBody;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReports;

  /// No description provided for @reportsFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Reports from this phone'**
  String get reportsFromPhone;

  /// No description provided for @aboutKombien.
  ///
  /// In en, this message translates to:
  /// **'About Kombien'**
  String get aboutKombien;

  /// No description provided for @howFaresWork.
  ///
  /// In en, this message translates to:
  /// **'How reported fares work'**
  String get howFaresWork;

  /// No description provided for @howFaresWorkBody.
  ///
  /// In en, this message translates to:
  /// **'Riders report what they paid after a ride. For each route, Kombien shows the middle half of recent reports (the last 90 days) as a range, so one odd price doesn\'t move it. A route needs at least 3 reports before a range appears. It\'s a guide for negotiating, not an official fare.'**
  String get howFaresWorkBody;

  /// No description provided for @contributeGithub.
  ///
  /// In en, this message translates to:
  /// **'Contribute on Github'**
  String get contributeGithub;

  /// No description provided for @devAbout.
  ///
  /// In en, this message translates to:
  /// **'About the developer'**
  String get devAbout;

  /// No description provided for @devHello.
  ///
  /// In en, this message translates to:
  /// **'Hey, I\'m Mich!'**
  String get devHello;

  /// No description provided for @devStory.
  ///
  /// In en, this message translates to:
  /// **'Built Kombien so we all stop getting laughed at by taxi drivers. Drop your fare after your next ride to keep the community sharp!'**
  String get devStory;

  /// No description provided for @devCoffeeAsk.
  ///
  /// In en, this message translates to:
  /// **'Saved some cash today? Toss a coffee my way to keep the servers running.'**
  String get devCoffeeAsk;

  /// No description provided for @devCoffee.
  ///
  /// In en, this message translates to:
  /// **'Get the dev a coffee'**
  String get devCoffee;

  /// No description provided for @devThanksLead.
  ///
  /// In en, this message translates to:
  /// **'Special thanks to '**
  String get devThanksLead;

  /// No description provided for @devThanksTail.
  ///
  /// In en, this message translates to:
  /// **' for all the wisdom and help proving once more the immense power of experience'**
  String get devThanksTail;

  /// No description provided for @letsConnect.
  ///
  /// In en, this message translates to:
  /// **'Let\'s connect'**
  String get letsConnect;

  /// No description provided for @devTagline.
  ///
  /// In en, this message translates to:
  /// **'Curious, intentional and always chasing the next idea worth bringing to life'**
  String get devTagline;

  /// No description provided for @noSavedFares.
  ///
  /// In en, this message translates to:
  /// **'No saved fares for {city} yet. Download them to use Kombien without a connection.'**
  String noSavedFares(String city);

  /// No description provided for @reportsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report waiting for a connection. It\'ll send automatically} other{{count} reports waiting for a connection. They\'ll send automatically}}'**
  String reportsWaiting(int count);

  /// No description provided for @deleteReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete the report saved on this phone?} other{Delete the {count} reports saved on this phone?}}'**
  String deleteReportsTitle(int count);

  /// No description provided for @deleteReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Reports already sent stay in the shared data.'**
  String get deleteReportsBody;

  /// No description provided for @deleteReportsAction.
  ///
  /// In en, this message translates to:
  /// **'Delete reports from this phone'**
  String get deleteReportsAction;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @myReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReportsTitle;

  /// No description provided for @myReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports from this phone yet. Paid for a ride? Report it, the next rider will thank you.'**
  String get myReportsEmpty;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get reportSent;

  /// No description provided for @reportWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection'**
  String get reportWaiting;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @problemTitle.
  ///
  /// In en, this message translates to:
  /// **'Something not right?'**
  String get problemTitle;

  /// No description provided for @problemWhat.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get problemWhat;

  /// No description provided for @problemWrongFare.
  ///
  /// In en, this message translates to:
  /// **'A fare looks wrong'**
  String get problemWrongFare;

  /// No description provided for @problemPlaceMissing.
  ///
  /// In en, this message translates to:
  /// **'A place is missing'**
  String get problemPlaceMissing;

  /// No description provided for @problemBug.
  ///
  /// In en, this message translates to:
  /// **'Something doesn\'t work'**
  String get problemBug;

  /// No description provided for @problemOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get problemOther;

  /// No description provided for @problemWhere.
  ///
  /// In en, this message translates to:
  /// **'Where did it happen?'**
  String get problemWhere;

  /// No description provided for @whereFares.
  ///
  /// In en, this message translates to:
  /// **'Finding fares'**
  String get whereFares;

  /// No description provided for @whereReport.
  ///
  /// In en, this message translates to:
  /// **'Reporting'**
  String get whereReport;

  /// No description provided for @whereSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get whereSettings;

  /// No description provided for @whereOther.
  ///
  /// In en, this message translates to:
  /// **'Somewhere else'**
  String get whereOther;

  /// No description provided for @problemMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more (optional)'**
  String get problemMore;

  /// No description provided for @problemMoreHint.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get problemMoreHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @problemThanksLabel.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get problemThanksLabel;

  /// No description provided for @problemThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem reported'**
  String get problemThanksTitle;

  /// No description provided for @problemThanksBody.
  ///
  /// In en, this message translates to:
  /// **'We read every report and use it to make Kombien better.'**
  String get problemThanksBody;

  /// No description provided for @installKombien.
  ///
  /// In en, this message translates to:
  /// **'Install Kombien'**
  String get installKombien;

  /// No description provided for @installIosTitle.
  ///
  /// In en, this message translates to:
  /// **'Put Kombien on your home screen'**
  String get installIosTitle;

  /// No description provided for @installIosBody.
  ///
  /// In en, this message translates to:
  /// **'In Safari, tap the Share button, then \"Add to Home Screen\". Kombien then opens like an app, even offline.'**
  String get installIosBody;

  /// No description provided for @installedLabel.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedLabel;

  /// No description provided for @installedTitle.
  ///
  /// In en, this message translates to:
  /// **'Kombien is on your phone'**
  String get installedTitle;

  /// No description provided for @installedBody.
  ///
  /// In en, this message translates to:
  /// **'Open it from your home screen, even without internet.'**
  String get installedBody;

  /// No description provided for @osmCredit.
  ///
  /// In en, this message translates to:
  /// **'Places © OpenStreetMap contributors, Overture Maps Foundation, GeoNames'**
  String get osmCredit;

  /// No description provided for @packFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get packFailedLabel;

  /// No description provided for @packFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that city'**
  String get packFailedTitle;

  /// No description provided for @packFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Kombien will try again when you\'re back online.'**
  String get packFailedBody;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get updateLabel;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Kombien has been updated'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'Restart to use the latest version.'**
  String get updateBody;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get updateAction;

  /// No description provided for @arrivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {place}?'**
  String arrivedTitle(String place);

  /// No description provided for @arrivedBody.
  ///
  /// In en, this message translates to:
  /// **'What did you pay from {from}? One tap helps the next rider.'**
  String arrivedBody(String from);

  /// No description provided for @arrivedOther.
  ///
  /// In en, this message translates to:
  /// **'Another amount'**
  String get arrivedOther;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @arrivedThanksLabel.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get arrivedThanksLabel;

  /// No description provided for @arrivedThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare added'**
  String get arrivedThanksTitle;

  /// No description provided for @arrivedThanksBody.
  ///
  /// In en, this message translates to:
  /// **'Riders on this route will see it.'**
  String get arrivedThanksBody;

  /// No description provided for @unlockedLabel.
  ///
  /// In en, this message translates to:
  /// **'You did that'**
  String get unlockedLabel;

  /// No description provided for @unlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fares unlocked'**
  String get unlockedTitle;

  /// No description provided for @unlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your report helped show a fare range for {from} → {to}.'**
  String unlockedBody(String from, String to);

  /// No description provided for @cityMovedLabel.
  ///
  /// In en, this message translates to:
  /// **'New city'**
  String get cityMovedLabel;

  /// No description provided for @cityMovedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re in {city}'**
  String cityMovedTitle(String city);

  /// No description provided for @cityMovedBody.
  ///
  /// In en, this message translates to:
  /// **'Kombien now shows {city} places and fares.'**
  String cityMovedBody(String city);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @release.
  ///
  /// In en, this message translates to:
  /// **'{mark} · version {version}'**
  String release(String mark, String version);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushUnlockedRow.
  ///
  /// In en, this message translates to:
  /// **'Fares unlocked, updates, morning reminders'**
  String get pushUnlockedRow;

  /// No description provided for @pushOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Stay in the loop'**
  String get pushOfferLabel;

  /// No description provided for @pushOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to know when it counts?'**
  String get pushOfferTitle;

  /// No description provided for @pushOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Hear when your report unlocks fares, when Kombien is updated, and a morning reminder every few days.'**
  String get pushOfferBody;

  /// No description provided for @pushOfferAction.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get pushOfferAction;

  /// No description provided for @pushOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pushOnLabel;

  /// No description provided for @pushOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get pushOnTitle;

  /// No description provided for @pushOnBody.
  ///
  /// In en, this message translates to:
  /// **'At most one a day, never at night.'**
  String get pushOnBody;

  /// No description provided for @pushBlockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get pushBlockedLabel;

  /// No description provided for @pushBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get pushBlockedTitle;

  /// No description provided for @pushBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow them for Kombien in your browser or phone settings.'**
  String get pushBlockedBody;

  /// No description provided for @pushTestLabel.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get pushTestLabel;

  /// No description provided for @pushTestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent'**
  String get pushTestSentTitle;

  /// No description provided for @pushTestSentBody.
  ///
  /// In en, this message translates to:
  /// **'It should arrive in a few seconds.'**
  String get pushTestSentBody;

  /// No description provided for @pushTestFailTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send a test'**
  String get pushTestFailTitle;

  /// No description provided for @placeMissingLink.
  ///
  /// In en, this message translates to:
  /// **'Not the place? Tell us'**
  String get placeMissingLink;

  /// No description provided for @placeMissingAction.
  ///
  /// In en, this message translates to:
  /// **'Tell us about it'**
  String get placeMissingAction;

  /// No description provided for @nearPlace.
  ///
  /// In en, this message translates to:
  /// **'Near {place}'**
  String nearPlace(String place);

  /// No description provided for @googleSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Not in Kombien yet. Is it one of these?'**
  String get googleSuggestionsTitle;

  /// No description provided for @addPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this place as'**
  String get addPlaceTitle;

  /// No description provided for @addPlaceSuggested.
  ///
  /// In en, this message translates to:
  /// **'Google suggested: {name}'**
  String addPlaceSuggested(String name);

  /// No description provided for @addPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'The name riders use'**
  String get addPlaceHint;

  /// No description provided for @addPlaceAction.
  ///
  /// In en, this message translates to:
  /// **'Use this place'**
  String get addPlaceAction;

  /// No description provided for @addPlaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add that place. Check your connection and try again'**
  String get addPlaceFailed;

  /// No description provided for @addPlaceYourself.
  ///
  /// In en, this message translates to:
  /// **'Add this place'**
  String get addPlaceYourself;

  /// No description provided for @addYourselfLink.
  ///
  /// In en, this message translates to:
  /// **'Not there? Add it yourself'**
  String get addYourselfLink;

  /// No description provided for @newPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get newPlaceTitle;

  /// No description provided for @newPlaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'What riders call it'**
  String get newPlaceNameHint;

  /// No description provided for @newPlaceWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where is it?'**
  String get newPlaceWhereTitle;

  /// No description provided for @whereHere.
  ///
  /// In en, this message translates to:
  /// **'I\'m here now'**
  String get whereHere;

  /// No description provided for @whereNear.
  ///
  /// In en, this message translates to:
  /// **'It\'s near a place I know'**
  String get whereNear;

  /// No description provided for @whereUnknown.
  ///
  /// In en, this message translates to:
  /// **'I\'m not sure where'**
  String get whereUnknown;

  /// No description provided for @gpsFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding your position…'**
  String get gpsFinding;

  /// No description provided for @gpsFound.
  ///
  /// In en, this message translates to:
  /// **'Got it. Accurate to about {m} m'**
  String gpsFound(int m);

  /// No description provided for @gpsWeak.
  ///
  /// In en, this message translates to:
  /// **'Signal too weak (about {m} m off). Go outside, or choose near a place'**
  String gpsWeak(int m);

  /// No description provided for @gpsOff.
  ///
  /// In en, this message translates to:
  /// **'Can\'t see your position. Allow location, or choose near a place'**
  String get gpsOff;

  /// No description provided for @gpsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gpsRetry;

  /// No description provided for @nearSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a place you know nearby'**
  String get nearSearchHint;

  /// No description provided for @nearHowFar.
  ///
  /// In en, this message translates to:
  /// **'How far is it from there?'**
  String get nearHowFar;

  /// No description provided for @nearNext.
  ///
  /// In en, this message translates to:
  /// **'Right next to it'**
  String get nearNext;

  /// No description provided for @near200.
  ///
  /// In en, this message translates to:
  /// **'About 200 m'**
  String get near200;

  /// No description provided for @near500.
  ///
  /// In en, this message translates to:
  /// **'About 500 m'**
  String get near500;

  /// No description provided for @unknownNote.
  ///
  /// In en, this message translates to:
  /// **'Other riders will find it by its name. It won\'t show up by distance.'**
  String get unknownNote;

  /// No description provided for @newPlaceAction.
  ///
  /// In en, this message translates to:
  /// **'Add this place'**
  String get newPlaceAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageCode => 'Fr';

  @override
  String get menuFares => 'Je paie combien?';

  @override
  String get menuReport => 'Signaler';

  @override
  String get menuSettings => 'Paramètres';

  @override
  String get menuStyleGuide => 'Guide de style';

  @override
  String get skip => 'Passer';

  @override
  String get continueAction => 'Continuer';

  @override
  String get getStarted => 'Commencer';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Supprimer';

  @override
  String get onboardingFaresTitle => 'Je paie combien?';

  @override
  String get onboardingFaresBody =>
      'Vois ce que d\'autres passagers ont payé pour ton trajet avant de négocier. Une fourchette, pas une devinette.';

  @override
  String get onboardingFaresFootnote =>
      'Les prix viennent des passagers. Ils ne sont pas officiels.';

  @override
  String get onboardingBubbleAsk => 'Poste Centrale,\n500 FCFA';

  @override
  String get onboardingBubbleReply => 'Non';

  @override
  String get onboardingReportTitle => 'Payé? Dis-le.';

  @override
  String get onboardingReportBody =>
      'Ajoute ce que tu as payé en quelques touches. Le prochain passager le verra.';

  @override
  String get onboardingReportFootnote => 'Aide quelqu\'un à t\'aider';

  @override
  String get termsLead => 'J\'accepte les ';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get termsJoin => ' et la ';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsTail => ' de Kombien';

  @override
  String get locationPromptTitle => 'Salut! Tu ne sais pas quel prix proposer?';

  @override
  String get locationPromptBody =>
      'Active la localisation pour que Kombien repère ton point de départ exact et le compare aux vrais prix signalés par d\'autres passagers autour de toi. Propose en confiance. Pas de devinette, pas de surprix.';

  @override
  String get locationPromptAction => 'Commencer depuis ma position';

  @override
  String get locationPromptSkip => 'Plus tard';

  @override
  String get whereFrom => 'Tu pars d\'où?';

  @override
  String get myLocation => 'Ma position';

  @override
  String get searchLandmark => 'Cherche un repère';

  @override
  String get locationDenied => 'On ne te voit pas. Cherche plutôt un repère';

  @override
  String get useMyLocation => 'Utiliser ma position';

  @override
  String get turnOnLocation => 'Localisation désactivée. L\'activer';

  @override
  String get whereTo => 'Tu go où?';

  @override
  String get startTyping => 'Commence à taper...';

  @override
  String get seeAllSuggestions => 'Voir toutes les suggestions';

  @override
  String get savedDestinations => 'Tes destinations enregistrées';

  @override
  String get savedEmptyHint =>
      'Choisis un lieu, puis touche Enregistrer ce lieu pour le garder ici.';

  @override
  String get saveThisPlace => 'Enregistrer ce lieu';

  @override
  String savedAs(String name) {
    return 'Enregistré comme $name';
  }

  @override
  String saveAs(String name) {
    return 'Enregistrer comme $name';
  }

  @override
  String get nameThePlace => 'Nommer ';

  @override
  String get otherName => 'Autre nom…';

  @override
  String get placeHome => 'Maison';

  @override
  String get placeSchool => 'École';

  @override
  String get placeWork => 'Travail';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get fareBasedOn => 'D\'après les prix signalés par les passagers';

  @override
  String get fareDemo => 'Fourchette de démo, pas encore de vrais signalements';

  @override
  String get fareDisclaimer =>
      'Cette fourchette est une moyenne de ce que de vrais passagers ont payé récemment sur ce trajet, pas un tarif officiel. C\'est un repère pour proposer, pas un prix fixe ni garanti.';

  @override
  String get fareCurrency => 'FCFA';

  @override
  String get bringCash => 'Pense à prendre de la monnaie';

  @override
  String get feedbackQuestion => 'Cette info t\'a aidé?';

  @override
  String get feedbackThanksLabel => 'Merci!';

  @override
  String get feedbackThanksTitle => 'Avis enregistré!';

  @override
  String get feedbackThanksBody => 'Ta réponse nous aide à améliorer l\'app';

  @override
  String get startMissing => 'Dis-nous d\'abord d\'où tu pars';

  @override
  String get startPickOne => 'Choisis ton point de départ dans les suggestions';

  @override
  String get paidSomethingElse => 'T\'as payé autre chose?';

  @override
  String get reportItHere => 'Signale-le ici';

  @override
  String get noReportsTitle =>
      'Pas encore de signalement sur ce trajet. Sois le premier.';

  @override
  String get addReport => 'Ajouter mon prix';

  @override
  String get noMatchTitle => 'Lieu introuvable. Essaie plutôt un repère proche';

  @override
  String get offlineTitle => 'Pas de connexion. Prix enregistrés affichés.';

  @override
  String get offlineNoSaved =>
      'Pas de connexion. Vérifie tes données et réessaie.';

  @override
  String get retry => 'Réessayer';

  @override
  String get savedFareNote =>
      'Prix enregistré lors de ta dernière recherche. Il peut avoir changé.';

  @override
  String get reportFromLabel => 'Tu pars / es parti d\'où?';

  @override
  String get reportTo => 'Vers';

  @override
  String get reportTitle => 'Signaler';

  @override
  String get reportingFor => 'Tu signales le prix du trajet...';

  @override
  String get routeFrom => 'De';

  @override
  String get routeTo => 'Vers';

  @override
  String get priceSuggestions => 'Quelques suggestions (prix en FCFA)';

  @override
  String get optional => 'Facultatif';

  @override
  String get timeOfDay => 'Moment';

  @override
  String get dayMorning => 'Matin';

  @override
  String get dayDay => 'Journée';

  @override
  String get dayNight => 'Nuit';

  @override
  String get weather => 'Météo';

  @override
  String get weatherClear => 'Beau temps';

  @override
  String get weatherRainy => 'Pluie';

  @override
  String get vehicleType => 'Véhicule';

  @override
  String get vehicleTaxi => 'Taxi';

  @override
  String get vehicleMoto => 'Moto';

  @override
  String get reportAddedLabel => 'Merci!';

  @override
  String get reportAddedTitle => 'Prix ajouté!';

  @override
  String get reportAddedBody =>
      'Ton signalement aide déjà d\'autres passagers sur ce trajet';

  @override
  String get reportQueuedTitle => 'Enregistré sur ce téléphone';

  @override
  String get reportQueuedBody => 'Il sera envoyé dès que tu seras en ligne';

  @override
  String get amountRange => 'Entre un montant entre 50 et 50 000 FCFA';

  @override
  String get back => 'Retour';

  @override
  String get settingsLocation => 'Localisation';

  @override
  String get on => 'Oui';

  @override
  String get off => 'Non';

  @override
  String get myCity => 'Ma ville';

  @override
  String get myCityNote =>
      'Choisit le pack hors ligne à garder et mettre à jour ; les données des autres villes sont supprimées de cet appareil après un moment';

  @override
  String get offline => 'Hors ligne';

  @override
  String get savedFaresMap => 'Prix et carte enregistrés';

  @override
  String get savedOnPhone => 'Enregistré sur ce téléphone.';

  @override
  String updatedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Mis à jour il y a $days jours',
      one: 'Mis à jour hier',
      zero: 'Mis à jour aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get addCity => 'Ajouter une ville';

  @override
  String get chooseCity => 'Choisis ta ville';

  @override
  String get offlineData => 'Données hors ligne';

  @override
  String get sendingReports => 'Envoi des signalements';

  @override
  String get wifiAndMobile => 'Wi-Fi et données mobiles';

  @override
  String get mobileOnly => 'Données mobiles seulement';

  @override
  String get wifiOnly => 'Wi-Fi seulement';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get whatKombienStores => 'Ce que Kombien garde';

  @override
  String get whatKombienStoresBody =>
      'Pas de compte, pas de nom, pas de numéro. Un signalement, c\'est un trajet, un prix, l\'heure et des détails facultatifs (météo, véhicule). Chaque téléphone se connecte anonymement pour bloquer le spam, jamais pour suivre qui que ce soit. Seules les moyennes par trajet sont affichées, et seulement quand assez de passagers ont signalé ce trajet. Tes lieux enregistrés, ta langue et tes réglages restent sur ce téléphone.';

  @override
  String get myReports => 'Mes signalements';

  @override
  String get reportsFromPhone => 'Signalements depuis ce téléphone';

  @override
  String get aboutKombien => 'À propos de Kombien';

  @override
  String get howFaresWork => 'Comment marchent les prix signalés';

  @override
  String get howFaresWorkBody =>
      'Les passagers signalent ce qu\'ils ont payé après un trajet. Pour chaque trajet, Kombien affiche la moitié centrale des signalements récents (les 90 derniers jours) sous forme de fourchette, pour qu\'un prix bizarre ne la fausse pas. Il faut au moins 3 signalements pour qu\'une fourchette apparaisse. C\'est un repère pour négocier, pas un tarif officiel.';

  @override
  String get contributeGithub => 'Contribuer sur Github';

  @override
  String get devAbout => 'À propos du développeur';

  @override
  String get devHello => 'Salut, c\'est Mich!';

  @override
  String get devStory =>
      'J\'ai créé Kombien pour qu\'on arrête tous de se faire rire au nez par les taximen. Signale ton prix après ta prochaine course pour garder la communauté au top!';

  @override
  String get devCoffeeAsk =>
      'T\'as économisé aujourd\'hui? Offre-moi un café pour garder les serveurs en marche.';

  @override
  String get devCoffee => 'Offrir un café au dev';

  @override
  String get devThanksLead => 'Merci spécial à ';

  @override
  String get devThanksTail =>
      ' pour toute sa sagesse et son aide, preuve une fois de plus de l\'immense force de l\'expérience';

  @override
  String get letsConnect => 'Restons en contact';

  @override
  String get devTagline =>
      'Curieux, réfléchi et toujours à la poursuite de la prochaine idée qui mérite de voir le jour';

  @override
  String noSavedFares(String city) {
    return 'Pas encore de prix enregistrés pour $city. Télécharge-les pour utiliser Kombien sans connexion.';
  }

  @override
  String reportsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count signalements attendent une connexion. Ils partiront tout seuls',
      one: '1 signalement attend une connexion. Il partira tout seul',
    );
    return '$_temp0';
  }

  @override
  String deleteReportsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer les $count signalements enregistrés sur ce téléphone?',
      one: 'Supprimer le signalement enregistré sur ce téléphone?',
    );
    return '$_temp0';
  }

  @override
  String get deleteReportsBody =>
      'Les signalements déjà envoyés restent dans les données partagées.';

  @override
  String get deleteReportsAction =>
      'Supprimer les signalements de ce téléphone';

  @override
  String get delete => 'Supprimer';

  @override
  String get myReportsTitle => 'Mes signalements';

  @override
  String get myReportsEmpty =>
      'Aucun signalement depuis ce téléphone pour l\'instant. Tu as payé une course? Signale-la, le prochain passager te remerciera.';

  @override
  String get reportSent => 'Envoyé';

  @override
  String get reportWaiting => 'En attente de connexion';

  @override
  String get close => 'Fermer';

  @override
  String get reportProblem => 'Signaler un problème';

  @override
  String get problemTitle => 'Quelque chose cloche?';

  @override
  String get problemWhat => 'Qu\'est-ce qui ne va pas?';

  @override
  String get problemWrongFare => 'Un prix semble faux';

  @override
  String get problemPlaceMissing => 'Un lieu manque';

  @override
  String get problemBug => 'Quelque chose ne marche pas';

  @override
  String get problemOther => 'Autre chose';

  @override
  String get problemWhere => 'Où ça s\'est passé?';

  @override
  String get whereFares => 'Recherche de prix';

  @override
  String get whereReport => 'Signalement';

  @override
  String get whereSettings => 'Paramètres';

  @override
  String get whereOther => 'Ailleurs';

  @override
  String get problemMore => 'Dis-nous en plus (facultatif)';

  @override
  String get problemMoreHint => 'Que s\'est-il passé?';

  @override
  String get send => 'Envoyer';

  @override
  String get problemThanksLabel => 'Merci!';

  @override
  String get problemThanksTitle => 'Problème signalé';

  @override
  String get problemThanksBody =>
      'On lit chaque message et on s\'en sert pour améliorer Kombien.';

  @override
  String get installKombien => 'Installer Kombien';

  @override
  String get installIosTitle => 'Kombien sur votre écran d\'accueil';

  @override
  String get installIosBody =>
      'Dans Safari, touchez le bouton Partager, puis « Sur l\'écran d\'accueil ». Kombien s\'ouvre alors comme une appli, même hors ligne.';

  @override
  String get installedLabel => 'Installé';

  @override
  String get installedTitle => 'Kombien est sur votre téléphone';

  @override
  String get installedBody =>
      'Ouvrez-le depuis l\'écran d\'accueil, même sans internet.';

  @override
  String get osmCredit =>
      'Lieux © les contributeurs d’OpenStreetMap, Overture Maps Foundation, GeoNames';

  @override
  String get packFailedLabel => 'Pas de connexion';

  @override
  String get packFailedTitle => 'Impossible d\'enregistrer cette ville';

  @override
  String get packFailedBody =>
      'Kombien réessaiera quand vous serez de nouveau en ligne.';

  @override
  String get updateLabel => 'Nouvelle version';

  @override
  String get updateTitle => 'Kombien a été mis à jour';

  @override
  String get updateBody => 'Redémarrez pour utiliser la dernière version.';

  @override
  String get updateAction => 'Redémarrer';

  @override
  String arrivedTitle(String place) {
    return 'Arrivé à $place ?';
  }

  @override
  String arrivedBody(String from) {
    return 'Combien avez-vous payé depuis $from ? Un tap aide le prochain passager.';
  }

  @override
  String get arrivedOther => 'Un autre montant';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get arrivedThanksLabel => 'Merci !';

  @override
  String get arrivedThanksTitle => 'Tarif ajouté';

  @override
  String get arrivedThanksBody => 'Les passagers de ce trajet le verront.';

  @override
  String get unlockedLabel => 'Grâce à vous';

  @override
  String get unlockedTitle => 'Tarifs débloqués';

  @override
  String unlockedBody(String from, String to) {
    return 'Votre signalement a permis d\'afficher les tarifs pour $from → $to.';
  }

  @override
  String get cityMovedLabel => 'Nouvelle ville';

  @override
  String cityMovedTitle(String city) {
    return 'Vous êtes à $city';
  }

  @override
  String cityMovedBody(String city) {
    return 'Kombien affiche maintenant les lieux et tarifs de $city.';
  }

  @override
  String get undo => 'Annuler';

  @override
  String release(String mark, String version) {
    return '$mark · version $version';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get pushUnlockedRow => 'Quand mon signalement débloque des tarifs';

  @override
  String get pushOfferLabel => 'Restez informé';

  @override
  String get pushOfferTitle => 'Savoir quand ça compte ?';

  @override
  String get pushOfferBody =>
      'Recevez une notification quand votre signalement débloque les tarifs d\'un trajet.';

  @override
  String get pushOfferAction => 'Activer';

  @override
  String get pushOnLabel => 'C\'est fait';

  @override
  String get pushOnTitle => 'Notifications activées';

  @override
  String get pushOnBody => 'Une par jour au plus, jamais la nuit.';

  @override
  String get pushBlockedLabel => 'Bloquées';

  @override
  String get pushBlockedTitle => 'Les notifications sont bloquées';

  @override
  String get pushBlockedBody =>
      'Autorisez-les pour Kombien dans les réglages du navigateur ou du téléphone.';

  @override
  String get pushTestLabel => 'Test';

  @override
  String get pushTestSentTitle => 'Notification de test envoyée';

  @override
  String get pushTestSentBody => 'Elle devrait arriver dans quelques secondes.';

  @override
  String get pushTestFailTitle => 'Impossible d\'envoyer un test';

  @override
  String get placeMissingLink => 'Pas le bon lieu ? Dites-le-nous';

  @override
  String get placeMissingAction => 'Signaler ce lieu';

  @override
  String nearPlace(String place) {
    return 'Près de $place';
  }
}

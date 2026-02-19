// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'de';

  static String m0(firstName, lastName) =>
      "Wilkommen ${firstName} ${lastName}!";

  static String m1(newMessages) =>
      "Sie haben ${Intl.plural(newMessages, zero: 'Keine neuen Nachrichten', one: 'Eine neue Nachricht', two: 'zwei neue Nachrichten', other: '${newMessages} neue Nachrichten')}";

  static String m2(type) =>
      "Das Passwort muss mindestens ein ${Intl.select(type, {'uppercase': 'Großbuchstabe', 'lowercase': 'Kleinbuchstabe', 'number': 'Zahl', 'special': 'Sonderzeichen', 'other': 'gültiges Zeichen'})} enthalten";

  static String m3(state) => "Bezogen auf ${state}";

  static String m4(date) => "Gültig bis";

  static String m5(email) =>
      "Eine Bestätigungs-E-Mail wurde an ${email} gesendet";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("Über"),
    "aboutThisApp": MessageLookupByLibrary.simpleMessage("Über diese App"),
    "active": MessageLookupByLibrary.simpleMessage("Aktiv"),
    "activityHistory": MessageLookupByLibrary.simpleMessage(
      "Aktivitätsverlauf",
    ),
    "addComment": MessageLookupByLibrary.simpleMessage(
      "Einen Kommentar hinzufügen",
    ),
    "addImage": MessageLookupByLibrary.simpleMessage("Bild hinzufügen"),
    "addOption": MessageLookupByLibrary.simpleMessage("Option hinzufügen"),
    "address": MessageLookupByLibrary.simpleMessage("Anschrift"),
    "addressUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Anschrift erfolgreich aktualisiert",
    ),
    "adminDashboard": MessageLookupByLibrary.simpleMessage("Admin-Dashboard"),
    "adminInterface": MessageLookupByLibrary.simpleMessage("Admin-Oberfläche"),
    "alert": MessageLookupByLibrary.simpleMessage("Warnung"),
    "anUnexpectedErrorOccurred": MessageLookupByLibrary.simpleMessage(
      "Ein unerwarteter Fehler ist aufgetreten.",
    ),
    "anonymous": MessageLookupByLibrary.simpleMessage("Anonym"),
    "areYouSureYouWantToCancelYourProSubscription":
        MessageLookupByLibrary.simpleMessage(
          "Möchtest du dein Pro-Abo wirklich kündigen?",
        ),
    "areYouSureYouWantToClearThisDraft": MessageLookupByLibrary.simpleMessage(
      "Sind sie sicher das sie das Formular löschen wollen?",
    ),
    "areYouSureYouWantToDeleteThisPetition":
        MessageLookupByLibrary.simpleMessage(
          "Sind Sie sicher, dass Sie diese Petition löschen möchten?",
        ),
    "areYouSureYouWantToDeleteThisPoll": MessageLookupByLibrary.simpleMessage(
      "Sind Sie sicher, dass Sie diese Umfrage löschen möchten?",
    ),
    "areYouSureYouWantToDeleteThisUser": MessageLookupByLibrary.simpleMessage(
      "Sind Sie sicher, dass Sie diesen Benutzer löschen möchten?",
    ),
    "areYouSureYouWantToDeleteYourAccount":
        MessageLookupByLibrary.simpleMessage(
          "Sind Sie sicher, dass Sie Ihr Konto löschen möchten?",
        ),
    "areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible":
        MessageLookupByLibrary.simpleMessage(
          "Sind Sie sicher, dass Sie Ihr Konto löschen möchten? Diese Aktion ist unwiderruflich",
        ),
    "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
      "Sind Sie sicher, dass Sie sich abmelden möchten?",
    ),
    "backSide": MessageLookupByLibrary.simpleMessage("Rückseite"),
    "backToLogin": MessageLookupByLibrary.simpleMessage("Zurück zur Anmeldung"),
    "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
    "cancelProSubscription": MessageLookupByLibrary.simpleMessage(
      "Pro-Abo kündigen",
    ),
    "cancelRegistration": MessageLookupByLibrary.simpleMessage(
      "Registrierung abbrechen",
    ),
    "cancelSubscription": MessageLookupByLibrary.simpleMessage("Abo kündigen"),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Sprache ändern"),
    "changePassword": MessageLookupByLibrary.simpleMessage("Passwort ändern"),
    "close": MessageLookupByLibrary.simpleMessage("Schließen"),
    "closed": MessageLookupByLibrary.simpleMessage("Beended"),
    "colorMode": MessageLookupByLibrary.simpleMessage("Farbmodus"),
    "colorTheme": MessageLookupByLibrary.simpleMessage("Farbthema"),
    "comments": MessageLookupByLibrary.simpleMessage("Kommentare"),
    "confirm": MessageLookupByLibrary.simpleMessage("Bestätigen"),
    "confirmAndFinish": MessageLookupByLibrary.simpleMessage(
      "Bestätigen & Fertigstellen",
    ),
    "confirmPassword": MessageLookupByLibrary.simpleMessage(
      "Passwort bestätigen",
    ),
    "confirmationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Bestätigungs-E-Mail gesendet",
    ),
    "confirmationEmailSentDescription": MessageLookupByLibrary.simpleMessage(
      "Wir haben eine Bestätigungs-E-Mail an deine E-Mail-Adresse gesendet. Bitte prüfe deinen Posteingang und folge den Anweisungen, um die Registrierung abzuschließen.",
    ),
    "consumption": MessageLookupByLibrary.simpleMessage("Verbrauch"),
    "continueNext": MessageLookupByLibrary.simpleMessage("Weiter"),
    "continueText": MessageLookupByLibrary.simpleMessage("Weiter"),
    "couldNotOpenPaywall": MessageLookupByLibrary.simpleMessage(
      "Paywall konnte nicht geöffnet werden",
    ),
    "createNewPetitionDescription": MessageLookupByLibrary.simpleMessage(
      "Erstelle eine neue Petition",
    ),
    "createNewPollDescription": MessageLookupByLibrary.simpleMessage(
      "Erstelle eine neue Umfrage",
    ),
    "createPetition": MessageLookupByLibrary.simpleMessage(
      "Petitition erstellen",
    ),
    "createPoll": MessageLookupByLibrary.simpleMessage("Umfrage erstellen"),
    "createdPetition": MessageLookupByLibrary.simpleMessage(
      "Petition erstellt",
    ),
    "createdPoll": MessageLookupByLibrary.simpleMessage("Umfrage erstellt"),
    "creator": MessageLookupByLibrary.simpleMessage("Ersteller"),
    "currentPassword": MessageLookupByLibrary.simpleMessage(
      "Aktuelles Passwort",
    ),
    "customPetitionAndPollPictures": MessageLookupByLibrary.simpleMessage(
      "Eigene Petition- und Umfragebilder",
    ),
    "dailyCreateLimitReached": MessageLookupByLibrary.simpleMessage(
      "Du kannst pro Tag nur eine Petition und eine Umfrage veröffentlichen.",
    ),
    "dailyCreatePetitionLimitReached": MessageLookupByLibrary.simpleMessage(
      "Du kannst pro Tag nur eine Petition veröffentlichen.",
    ),
    "dailyCreatePollLimitReached": MessageLookupByLibrary.simpleMessage(
      "Du kannst pro Tag nur eine Umfrage veröffentlichen.",
    ),
    "dailyHabit": MessageLookupByLibrary.simpleMessage("Tägliche Gewohnheit"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dunkler Modus"),
    "dateOfBirth": MessageLookupByLibrary.simpleMessage("Geburtsdatum"),
    "daysLeft": MessageLookupByLibrary.simpleMessage("Verbleibende Tage"),
    "delete": MessageLookupByLibrary.simpleMessage("löschen"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Konto löschen"),
    "deleteAccountButton": MessageLookupByLibrary.simpleMessage(
      "KONTO ENDGÜLTIG LÖSCHEN",
    ),
    "deleteAccountDescription": MessageLookupByLibrary.simpleMessage(
      "Bitte melden Sie sich an, um Ihre Identität zu bestätigen. Diese Aktion löscht Ihr Konto und alle zugehörigen Daten unwiderruflich.",
    ),
    "deleteAccountSuccess": MessageLookupByLibrary.simpleMessage(
      "Konto erfolgreich gelöscht.",
    ),
    "deleteAccountTitle": MessageLookupByLibrary.simpleMessage("Konto löschen"),
    "deleteAccountUnexpectedError": MessageLookupByLibrary.simpleMessage(
      "Ein unerwarteter Fehler ist aufgetreten.",
    ),
    "deleteAccountUserNotFound": MessageLookupByLibrary.simpleMessage(
      "Kein Benutzer mit dieser E-Mail gefunden.",
    ),
    "deleteAccountWrongPassword": MessageLookupByLibrary.simpleMessage(
      "Falsches Passwort.",
    ),
    "deleteMyAccount": MessageLookupByLibrary.simpleMessage(
      "Mein Konto löschen",
    ),
    "deletePermanently": MessageLookupByLibrary.simpleMessage(
      "Endgültig löschen",
    ),
    "deletePetition": MessageLookupByLibrary.simpleMessage("Petition löschen"),
    "deletePoll": MessageLookupByLibrary.simpleMessage("Umfrage löschen"),
    "deleteUser": MessageLookupByLibrary.simpleMessage("Benutzer löschen"),
    "deleted": MessageLookupByLibrary.simpleMessage("Gelöscht"),
    "description": MessageLookupByLibrary.simpleMessage("Beschreibung"),
    "descriptionRequired": MessageLookupByLibrary.simpleMessage(
      "Beschreibung ist erforderlich",
    ),
    "descriptionTooShort": MessageLookupByLibrary.simpleMessage(
      "Beschreibung ist zu kurz",
    ),
    "devContactInformation": MessageLookupByLibrary.simpleMessage(
      "Diese App wurde von Team LeEd mit Hilfe von Yannic entwickelt",
    ),
    "developerSandbox": MessageLookupByLibrary.simpleMessage(
      "Entwickler-Sandbox",
    ),
    "displayName": MessageLookupByLibrary.simpleMessage("angezeigter Name"),
    "editPetition": MessageLookupByLibrary.simpleMessage("Petition bearbeiten"),
    "email": MessageLookupByLibrary.simpleMessage("E-Mail"),
    "emailCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "E-Mail in die Zwischenablage kopiert",
    ),
    "emailVerification": MessageLookupByLibrary.simpleMessage(
      "E-Mail-Bestätigung",
    ),
    "emailVerifiedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "E-Mail erfolgreich verifiziert!",
    ),
    "energy": MessageLookupByLibrary.simpleMessage("Energie"),
    "english": MessageLookupByLibrary.simpleMessage("Englisch"),
    "enterCode": MessageLookupByLibrary.simpleMessage("Code eingeben"),
    "enterDescription": MessageLookupByLibrary.simpleMessage(
      "Beschreibung eingeben",
    ),
    "enterSomething": MessageLookupByLibrary.simpleMessage(
      "Geben Sie etwas ein",
    ),
    "enterTitle": MessageLookupByLibrary.simpleMessage("Titel eingeben"),
    "enterVerificationCode": MessageLookupByLibrary.simpleMessage(
      "Bestätigungscode eingeben",
    ),
    "enterYourAddress": MessageLookupByLibrary.simpleMessage(
      "gib deine Wohnanschrift ein",
    ),
    "enterYourEmail": MessageLookupByLibrary.simpleMessage(
      "Geben Sie Ihre E-Mail-Adresse ein",
    ),
    "entryNotYetImplemented": MessageLookupByLibrary.simpleMessage(
      "Lexikon-Eintrag noch nicht implementiert",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Fehler"),
    "errorCreatingPetition": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Erstellen der Petition",
    ),
    "errorSendingEmail": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Senden der E-Mail",
    ),
    "errorUploadingImage": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Hochladen des Bildes",
    ),
    "errors": MessageLookupByLibrary.simpleMessage("Fehler"),
    "exercise": MessageLookupByLibrary.simpleMessage("Übung"),
    "expiredCreations": MessageLookupByLibrary.simpleMessage(
      "Abgelaufene Einträge",
    ),
    "expiredPetitions": MessageLookupByLibrary.simpleMessage(
      "Abgelaufene Petitionen",
    ),
    "expiredPolls": MessageLookupByLibrary.simpleMessage(
      "Abgelaufene Umfragen",
    ),
    "expiresOn": MessageLookupByLibrary.simpleMessage("Läuft ab am"),
    "expiryDate": MessageLookupByLibrary.simpleMessage("Ablaufdatum"),
    "explore": MessageLookupByLibrary.simpleMessage("Entdecken"),
    "exportCsv": MessageLookupByLibrary.simpleMessage("CSV exportieren"),
    "exportFailed": MessageLookupByLibrary.simpleMessage(
      "Export fehlgeschlagen",
    ),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export erstellt"),
    "failedToCreatePoll": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Erstellen der Umfrage",
    ),
    "failedToResendCode": MessageLookupByLibrary.simpleMessage(
      "Code konnte nicht erneut gesendet werden",
    ),
    "failedToUploadImage": MessageLookupByLibrary.simpleMessage(
      "Bild konnte nicht hochgeladen werden",
    ),
    "faultyInput": MessageLookupByLibrary.simpleMessage("Fehlerhafte Eingabe"),
    "finalNotice": MessageLookupByLibrary.simpleMessage("Letzter Hinweis"),
    "finishedForms": MessageLookupByLibrary.simpleMessage(
      "Abgeschlossene Formulare",
    ),
    "flutterPro": MessageLookupByLibrary.simpleMessage("Flutter Pro"),
    "flutterProEmail": MessageLookupByLibrary.simpleMessage("Flutter@pro.com"),
    "freeMember": MessageLookupByLibrary.simpleMessage("Kostenloses Mitglied"),
    "french": MessageLookupByLibrary.simpleMessage("Französisch"),
    "frontSide": MessageLookupByLibrary.simpleMessage("Vorderseite"),
    "german": MessageLookupByLibrary.simpleMessage("Deutsch"),
    "getStarted": MessageLookupByLibrary.simpleMessage("Los geht\'s"),
    "githubLinkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "GitHub-Link in die Zwischenablage kopiert",
    ),
    "givenName": MessageLookupByLibrary.simpleMessage("Vorname"),
    "goProToAccessTheseBenefits": MessageLookupByLibrary.simpleMessage(
      "Pro-Abo abschließen um diese Vorteile zu nutzen",
    ),
    "goToWelcome": MessageLookupByLibrary.simpleMessage("Zum Startbildschirm"),
    "goal": MessageLookupByLibrary.simpleMessage("Ziel"),
    "growthStartsWithin": MessageLookupByLibrary.simpleMessage(
      "Wachstum beginnt von innen",
    ),
    "height": MessageLookupByLibrary.simpleMessage("Größe"),
    "hello": MessageLookupByLibrary.simpleMessage("Hallo"),
    "helloAndWelcome": m0,
    "hintTextTags": MessageLookupByLibrary.simpleMessage(
      "z.B. umwelt, verkehr",
    ),
    "idNumber": MessageLookupByLibrary.simpleMessage("Ausweisnummer"),
    "idScan": MessageLookupByLibrary.simpleMessage("Ausweisscan"),
    "imagePreviewDescription": MessageLookupByLibrary.simpleMessage(
      "Bildvorschau",
    ),
    "inactive": MessageLookupByLibrary.simpleMessage("Inaktiv"),
    "invalidEmailEntered": MessageLookupByLibrary.simpleMessage(
      "Ungültige E-Mail-Adresse eingegeben",
    ),
    "isProMember": MessageLookupByLibrary.simpleMessage("Ist Pro-Mitglied"),
    "language": MessageLookupByLibrary.simpleMessage("Sprache"),
    "lastStep": MessageLookupByLibrary.simpleMessage("Letzter Schritt!"),
    "licenses": MessageLookupByLibrary.simpleMessage("Lizenzen"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Heller Modus"),
    "limitThisPetitionToYourState": MessageLookupByLibrary.simpleMessage(
      "Diese Petition auf Ihr Bundesland beschränken?",
    ),
    "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Link in die Zwischenablage kopiert",
    ),
    "linkedinLinkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "LinkedIn-Link in die Zwischenablage kopiert",
    ),
    "livingAddress": MessageLookupByLibrary.simpleMessage("Anschrift"),
    "loggedOutSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Erfolgreich abgemeldet",
    ),
    "login": MessageLookupByLibrary.simpleMessage("Anmelden"),
    "loginCodeSent": MessageLookupByLibrary.simpleMessage(
      "Login Code gesendet",
    ),
    "loginLinkSent": MessageLookupByLibrary.simpleMessage("Code gesendet!"),
    "logout": MessageLookupByLibrary.simpleMessage("Abmelden"),
    "membershipStatus": MessageLookupByLibrary.simpleMessage(
      "Mitgliedschaftsstatus",
    ),
    "moreBenefitsToBeAddedLater": MessageLookupByLibrary.simpleMessage(
      "Weitere Vorteile folgen",
    ),
    "myPetitions": MessageLookupByLibrary.simpleMessage("Meine Petitionen"),
    "myProfile": MessageLookupByLibrary.simpleMessage("Mein Profil"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Namensänderung fehlgeschlagen",
    ),
    "nationality": MessageLookupByLibrary.simpleMessage("Staatsangehörigkeit"),
    "newMessages": m1,
    "newPassword": MessageLookupByLibrary.simpleMessage("Neues Passwort"),
    "newUsername": MessageLookupByLibrary.simpleMessage("Neuer Benutzername"),
    "nickname": MessageLookupByLibrary.simpleMessage("Spitzname"),
    "no": MessageLookupByLibrary.simpleMessage("Nein"),
    "noActivityFound": MessageLookupByLibrary.simpleMessage(
      "Noch keine Aktivität gefunden.",
    ),
    "noAdvertisements": MessageLookupByLibrary.simpleMessage("Keine Werbung"),
    "noData": MessageLookupByLibrary.simpleMessage("Keine Daten"),
    "noEmail": MessageLookupByLibrary.simpleMessage("Keine E-Mail"),
    "noExpiredItems": MessageLookupByLibrary.simpleMessage(
      "Keine abgelaufenen Einträge",
    ),
    "noImageSelected": MessageLookupByLibrary.simpleMessage(
      "Kein Bild ausgewählt",
    ),
    "noName": MessageLookupByLibrary.simpleMessage("Kein Name"),
    "noOptions": MessageLookupByLibrary.simpleMessage("Keine Optionen"),
    "noProMember": MessageLookupByLibrary.simpleMessage(
      "Nein, kein Pro-Mitglied",
    ),
    "noTitle": MessageLookupByLibrary.simpleMessage("Kein Titel"),
    "noUserFoundForThatEmail": MessageLookupByLibrary.simpleMessage(
      "Kein dieser Email zugehöriger Nutzer gefunden.",
    ),
    "noUsernameFound": MessageLookupByLibrary.simpleMessage(
      "Kein Benutzername gefunden",
    ),
    "notAuthenticated": MessageLookupByLibrary.simpleMessage(
      "Nicht authentifiziert",
    ),
    "notAvailableOnWebApp": MessageLookupByLibrary.simpleMessage(
      "Nicht in der Web-App verfügbar",
    ),
    "notFound": MessageLookupByLibrary.simpleMessage("Nicht gefunden"),
    "notSignedUpYet": MessageLookupByLibrary.simpleMessage(
      "Noch nicht registriert? Passwort vergessen?",
    ),
    "option": MessageLookupByLibrary.simpleMessage("Option"),
    "optionRequired": MessageLookupByLibrary.simpleMessage(
      "Option ist erforderlich",
    ),
    "options": MessageLookupByLibrary.simpleMessage("Optionen"),
    "other": MessageLookupByLibrary.simpleMessage("Andere"),
    "participants": MessageLookupByLibrary.simpleMessage("Teilnehmer"),
    "participantsList": MessageLookupByLibrary.simpleMessage("Teilnehmerliste"),
    "password": MessageLookupByLibrary.simpleMessage("Passwort"),
    "passwordChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Passwortänderung fehlgeschlagen",
    ),
    "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Passwort erfolgreich geändert",
    ),
    "passwordValidation": m2,
    "passwordsDoNotMatch": MessageLookupByLibrary.simpleMessage(
      "Passwörter stimmen nicht überein",
    ),
    "paywallDescription": MessageLookupByLibrary.simpleMessage(
      "Genieße eine entspanntere und vielfätigere Oberfläche",
    ),
    "paywallSubtitle": MessageLookupByLibrary.simpleMessage(
      "Unbegrenzter Zugang zu allen Funktionen",
    ),
    "paywallTitle": MessageLookupByLibrary.simpleMessage(
      "Werde Premium-Mitglied",
    ),
    "permanentlyDeleteAccount": MessageLookupByLibrary.simpleMessage(
      "KONTO DAUERHAFT LÖSCHEN",
    ),
    "petition": MessageLookupByLibrary.simpleMessage("Petition"),
    "petitionBy": MessageLookupByLibrary.simpleMessage("Petition von"),
    "petitionDetails": MessageLookupByLibrary.simpleMessage("Petitionsdetails"),
    "petitionGuidelineDescription": MessageLookupByLibrary.simpleMessage(
      "Petitionen müssen den Richtlinien des Petitionsausschusses des Deutschen Bundestages entsprechen. Sie sollten ein Anliegen von allgemeinem Interesse behandeln und dürfen keine beleidigenden oder diskriminierenden Inhalte enthalten.",
    ),
    "petitionGuidelines": MessageLookupByLibrary.simpleMessage(
      "Petitionsrichtlinien",
    ),
    "petitionSuccessfullySigned": MessageLookupByLibrary.simpleMessage(
      "Petition erfolgreich unterzeichnet!",
    ),
    "petitionTitleInUseAlready": MessageLookupByLibrary.simpleMessage(
      "Petitionstitel bereits vergeben",
    ),
    "petitionTutorialStep1": MessageLookupByLibrary.simpleMessage(
      "Das Anliegen muss von allgemeinem Interesse sein.",
    ),
    "petitionTutorialStep2": MessageLookupByLibrary.simpleMessage(
      "Es darf keine persönlichen Bezüge enthalten.",
    ),
    "petitionTutorialStep3": MessageLookupByLibrary.simpleMessage(
      "Anliegen und Begründung müssen knapp und allgemein verständlich formuliert sein.",
    ),
    "petitionTutorialStep4": MessageLookupByLibrary.simpleMessage(
      "Es werden nur Themen veröffentlicht, bei denen eine sachliche Diskussion zu erwarten ist.",
    ),
    "petitionTutorialStep5": MessageLookupByLibrary.simpleMessage(
      "Bei Erreichen von 30.000 Unterschriften erhält der Petent das Recht, sein Anliegen in einer öffentlichen Anhörung vorzutragen.",
    ),
    "petitions": MessageLookupByLibrary.simpleMessage("Petitionen"),
    "placeOfBirth": MessageLookupByLibrary.simpleMessage("Geburtsort"),
    "pleaseCheckYourEmail": MessageLookupByLibrary.simpleMessage(
      "Bitte überprüfen Sie Ihre E-Mails",
    ),
    "pleaseCheckYourInbox": MessageLookupByLibrary.simpleMessage(
      "Bitte prüfe deinen Posteingang und klicke auf den Bestätigungslink.",
    ),
    "pleaseEnterADateOfBirth": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie ein Geburtsdatum ein",
    ),
    "pleaseEnterAValid6digitCode": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie einen gültigen 6-stelligen Code ein",
    ),
    "pleaseEnterYourCredentials": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie ihre Zugangsdaten ein.",
    ),
    "pleaseEnterYourDesiredCredentials": MessageLookupByLibrary.simpleMessage(
      "Bitte geben sie ihre gewünschten Zugangsdaten ein.",
    ),
    "pleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie Ihre Daten ein.",
    ),
    "pleaseEnterYourEmail": MessageLookupByLibrary.simpleMessage(
      "Bitte die Email eingeben",
    ),
    "pleaseEnterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie Ihr Passwort ein",
    ),
    "pleaseEnterYourSurname": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie Ihren Nachnamen ein",
    ),
    "pleaseSelectState": MessageLookupByLibrary.simpleMessage(
      "Bitte wähle dein Bundesland aus.",
    ),
    "pleaseSignInFirst": MessageLookupByLibrary.simpleMessage(
      "Bitte zuerst anmelden",
    ),
    "pleaseSignInToConfirmYourIdentity": MessageLookupByLibrary.simpleMessage(
      "Bitte melden Sie sich an, um Ihre Identität zu bestätigen.",
    ),
    "pleaseUsePhoneToRegister": MessageLookupByLibrary.simpleMessage(
      "Bitte benutze dein Telefon zur Registrierung",
    ),
    "poll": MessageLookupByLibrary.simpleMessage("Umfrage"),
    "pollDetails": MessageLookupByLibrary.simpleMessage("Umfragedetails"),
    "pollGuidelineDescription": MessageLookupByLibrary.simpleMessage(
      "Umfragen sollten neutral formuliert sein und keine suggestiven Fragen enthalten. Sie dienen dazu, Meinungen zu einem bestimmten Thema einzuholen.",
    ),
    "pollGuidelines": MessageLookupByLibrary.simpleMessage(
      "Umfragerichtlinien",
    ),
    "pollTutorialStep1Desc": MessageLookupByLibrary.simpleMessage(
      "Wisse genau, was du lernen willst – nur eine Idee.",
    ),
    "pollTutorialStep1Title": MessageLookupByLibrary.simpleMessage(
      "1. Sei kristallklar über das Ziel",
    ),
    "pollTutorialStep2Desc": MessageLookupByLibrary.simpleMessage(
      "Keine Fachwörter. Kein Jargon. Keine „klug klingenden“ Formulierungen. Wenn ein Teenager und ein Großelternteil es beide verstehen, ist es gut.",
    ),
    "pollTutorialStep2Title": MessageLookupByLibrary.simpleMessage(
      "2. Verwende Alltagssprache",
    ),
    "pollTutorialStep3Desc": MessageLookupByLibrary.simpleMessage(
      "Einfacher Satz. Einfache Struktur.",
    ),
    "pollTutorialStep3Title": MessageLookupByLibrary.simpleMessage(
      "3. Stelle eine kurze, direkte Frage",
    ),
    "pollTutorialStep4Desc": MessageLookupByLibrary.simpleMessage(
      "Keine Fangfragen. Keine emotionale Wortwahl. Kein Drängen der Leute zu einer Option. Füge „Nicht sicher“ hinzu, wenn relevant.",
    ),
    "pollTutorialStep4Title": MessageLookupByLibrary.simpleMessage(
      "4. Gib faire Auswahlmöglichkeiten",
    ),
    "pollTutorialStep5Desc": MessageLookupByLibrary.simpleMessage(
      "3–5 Auswahlmöglichkeiten sind perfekt für öffentliche Umfragen.",
    ),
    "pollTutorialStep5Title": MessageLookupByLibrary.simpleMessage(
      "5. Halte die Optionen gering",
    ),
    "pollTutorialStep6Desc": MessageLookupByLibrary.simpleMessage(
      "Die Leute sollten es in unter 10 Sekunden verstehen und abstimmen können.",
    ),
    "pollTutorialStep6Title": MessageLookupByLibrary.simpleMessage(
      "6. Mache es schnell zu beantworten",
    ),
    "pollTutorialStep7Desc": MessageLookupByLibrary.simpleMessage(
      "Die Umfrage muss sich sicher, nicht wertend und unvoreingenommen anfühlen.",
    ),
    "pollTutorialStep7Title": MessageLookupByLibrary.simpleMessage(
      "7. Respektiere Neutralität",
    ),
    "polls": MessageLookupByLibrary.simpleMessage("Umfragen"),
    "popularPetitions": MessageLookupByLibrary.simpleMessage(
      "Beliebte Petitionen",
    ),
    "prioritySupport": MessageLookupByLibrary.simpleMessage(
      "Prioritätssupport",
    ),
    "privacySettings": MessageLookupByLibrary.simpleMessage(
      "Datenschutzeinstellungen",
    ),
    "proMember": MessageLookupByLibrary.simpleMessage("Pro-Mitglied"),
    "processId": MessageLookupByLibrary.simpleMessage("Ausweis verarbeiten"),
    "products": MessageLookupByLibrary.simpleMessage("Produkte"),
    "profile": MessageLookupByLibrary.simpleMessage("Profil"),
    "profilePictureUpdated": MessageLookupByLibrary.simpleMessage(
      "Profilbild aktualisiert",
    ),
    "publishedUnderTheGnuGeneralPublicLicenseV30":
        MessageLookupByLibrary.simpleMessage(
          "veröffentlicht unter der GNU General Public License v3.0",
        ),
    "purchaseCancelled": MessageLookupByLibrary.simpleMessage(
      "Kauf abgebrochen.",
    ),
    "purchaseFailed": MessageLookupByLibrary.simpleMessage(
      "Kauf fehlgeschlagen.",
    ),
    "purchaseSuccessful": MessageLookupByLibrary.simpleMessage(
      "Kauf erfolgreich!",
    ),
    "reasonsForSigning": MessageLookupByLibrary.simpleMessage(
      "Gründe für die Unterzeichnung",
    ),
    "recentPetitions": MessageLookupByLibrary.simpleMessage(
      "Aktuelle Petitionen",
    ),
    "register": MessageLookupByLibrary.simpleMessage("Registrieren"),
    "registerAccount": MessageLookupByLibrary.simpleMessage(
      "Konto registrieren",
    ),
    "registerHere": MessageLookupByLibrary.simpleMessage("Hier registrieren"),
    "relatedToState": m3,
    "remove": MessageLookupByLibrary.simpleMessage("Entfernen"),
    "requestLoginCode": MessageLookupByLibrary.simpleMessage(
      "Login Code anfordern",
    ),
    "resendEmail": MessageLookupByLibrary.simpleMessage("E-Mail erneut senden"),
    "resendEmailCooldown": MessageLookupByLibrary.simpleMessage(
      "Bitte warte, bevor du erneut sendest",
    ),
    "resendVerificationEmail": MessageLookupByLibrary.simpleMessage(
      "Bestätigungs-E-Mail erneut senden",
    ),
    "resetPassword": MessageLookupByLibrary.simpleMessage(
      "Passwort zurücksetzen",
    ),
    "resetPasswordCodeSent": MessageLookupByLibrary.simpleMessage(
      "Code abgeschickt",
    ),
    "resetPasswordLinkSent": MessageLookupByLibrary.simpleMessage(
      "Link zum Zurücksetzen des Passworts gesendet",
    ),
    "resubscribe": MessageLookupByLibrary.simpleMessage("Erneut abonnieren"),
    "result": MessageLookupByLibrary.simpleMessage("Ergebnis"),
    "save": MessageLookupByLibrary.simpleMessage("Speichern"),
    "scanAgain": MessageLookupByLibrary.simpleMessage("Erneut scannen"),
    "scanYourId": MessageLookupByLibrary.simpleMessage(
      "Bitte scannen Sie Ihren deutschen Personalausweis",
    ),
    "scannedData": MessageLookupByLibrary.simpleMessage("Gescannte Daten"),
    "searchTextField": MessageLookupByLibrary.simpleMessage("Schlagwort"),
    "select": MessageLookupByLibrary.simpleMessage("Auswählen"),
    "selectFromCamera": MessageLookupByLibrary.simpleMessage(
      "Mit Kamera aufnehmen",
    ),
    "selectFromGallery": MessageLookupByLibrary.simpleMessage(
      "Aus Galerie wählen",
    ),
    "sendConfirmationEmail": MessageLookupByLibrary.simpleMessage(
      "Sende Bestätigungs-E-Mail",
    ),
    "sendCrashLogs": MessageLookupByLibrary.simpleMessage(
      "Absturzberichte senden",
    ),
    "sendCrashLogsDescription": MessageLookupByLibrary.simpleMessage(
      "Helfen Sie uns, die App zu verbessern, indem Sie automatisch Absturzberichte senden.",
    ),
    "setUserDetails": MessageLookupByLibrary.simpleMessage(
      "Benutzerdaten festlegen",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Einstellungen"),
    "share": MessageLookupByLibrary.simpleMessage("Teilen"),
    "sharePetition": MessageLookupByLibrary.simpleMessage("Petition teilen"),
    "shareThis": MessageLookupByLibrary.simpleMessage("Teile dies"),
    "shareThisPetition": MessageLookupByLibrary.simpleMessage(
      "Teile diese Petition",
    ),
    "sharingNotSupported": MessageLookupByLibrary.simpleMessage(
      "Teilen wird auf dieser Plattform nicht unterstützt.",
    ),
    "sign": MessageLookupByLibrary.simpleMessage("Unterzeichen"),
    "signIn": MessageLookupByLibrary.simpleMessage("Anmelden"),
    "signPetition": MessageLookupByLibrary.simpleMessage(
      "Petition unterzeichnen",
    ),
    "signUpForPro": MessageLookupByLibrary.simpleMessage("Pro-Abo abschließen"),
    "signatures": MessageLookupByLibrary.simpleMessage("Unterschriften"),
    "signed": MessageLookupByLibrary.simpleMessage("Unterzeichnet"),
    "signedOn": MessageLookupByLibrary.simpleMessage("Eingeloggt"),
    "signedPetitions": MessageLookupByLibrary.simpleMessage(
      "Unterzeichnete Petitionen",
    ),
    "source": MessageLookupByLibrary.simpleMessage("Quelle"),
    "state": MessageLookupByLibrary.simpleMessage("Bundesland"),
    "stateDependent": MessageLookupByLibrary.simpleMessage(
      "Bundeslandabhängig",
    ),
    "stateUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Bundesland erfolgreich aktualisiert",
    ),
    "stimmapp": MessageLookupByLibrary.simpleMessage("stimmapp"),
    "subscriptionCancelledAccessWillRemainUntilExpiry":
        MessageLookupByLibrary.simpleMessage(
          "Abo gekündigt. Zugriff bleibt bis zum Ablauf erhalten.",
        ),
    "successfullyLoggedIn": MessageLookupByLibrary.simpleMessage(
      "Erfolgreich angemeldet",
    ),
    "supporters": MessageLookupByLibrary.simpleMessage("Unterstützer"),
    "surname": MessageLookupByLibrary.simpleMessage("Nachname"),
    "systemDefault": MessageLookupByLibrary.simpleMessage("Systemstandard"),
    "tagAnimalWelfare": MessageLookupByLibrary.simpleMessage("Tierschutz"),
    "tagCulture": MessageLookupByLibrary.simpleMessage("Kultur"),
    "tagEconomy": MessageLookupByLibrary.simpleMessage("Wirtschaft"),
    "tagEducation": MessageLookupByLibrary.simpleMessage("Bildung"),
    "tagEnvironment": MessageLookupByLibrary.simpleMessage("Umwelt"),
    "tagHealth": MessageLookupByLibrary.simpleMessage("Gesundheit"),
    "tagHousing": MessageLookupByLibrary.simpleMessage("Wohnen"),
    "tagInfrastructure": MessageLookupByLibrary.simpleMessage("Infrastruktur"),
    "tagOther": MessageLookupByLibrary.simpleMessage("Sonstiges"),
    "tagPolitics": MessageLookupByLibrary.simpleMessage("Politik"),
    "tagSafety": MessageLookupByLibrary.simpleMessage("Sicherheit"),
    "tagSocial": MessageLookupByLibrary.simpleMessage("Soziales"),
    "tagSports": MessageLookupByLibrary.simpleMessage("Sport"),
    "tagTechnology": MessageLookupByLibrary.simpleMessage("Technologie"),
    "tagTraffic": MessageLookupByLibrary.simpleMessage("Verkehr"),
    "tags": MessageLookupByLibrary.simpleMessage("Tags"),
    "tagsHint": MessageLookupByLibrary.simpleMessage("Komma-getrennte Tags"),
    "tagsRequired": MessageLookupByLibrary.simpleMessage(
      "Mindestens ein Tag ist erforderlich",
    ),
    "testingWidgetsHere": MessageLookupByLibrary.simpleMessage(
      "Widgets testen",
    ),
    "thankYouForSigning": MessageLookupByLibrary.simpleMessage(
      "Danke für deine Unterschrift!",
    ),
    "theWelcomePhrase": MessageLookupByLibrary.simpleMessage(
      "Der ultimative Weg deine Meinung zu äußern",
    ),
    "thisActionWillPermanentlyDeleteYourAccountAndAllAssociated":
        MessageLookupByLibrary.simpleMessage(
          "Diese Aktion wird Ihr Konto und alle zugehörigen Daten dauerhaft löschen.",
        ),
    "thisAppWasDevelopedBy": MessageLookupByLibrary.simpleMessage(
      "Diese App wurde entwickelt von",
    ),
    "title": MessageLookupByLibrary.simpleMessage("Titel"),
    "titleRequired": MessageLookupByLibrary.simpleMessage(
      "Titel ist erforderlich",
    ),
    "titleTooShort": MessageLookupByLibrary.simpleMessage("Titel ist zu kurz"),
    "travel": MessageLookupByLibrary.simpleMessage("Reisen"),
    "unknownError": MessageLookupByLibrary.simpleMessage("Unbekannter Fehler"),
    "updateLivingAddress": MessageLookupByLibrary.simpleMessage(
      "Anschrift ändern",
    ),
    "updateState": MessageLookupByLibrary.simpleMessage(
      "Bundesland aktualisieren",
    ),
    "updateUsername": MessageLookupByLibrary.simpleMessage(
      "Benutzernamen aktualisieren",
    ),
    "updates": MessageLookupByLibrary.simpleMessage("Updates"),
    "userNotAvailable": MessageLookupByLibrary.simpleMessage(
      "Benutzer nicht verfügbar",
    ),
    "userNotFound": MessageLookupByLibrary.simpleMessage(
      "Benutzer nicht gefunden",
    ),
    "userProfileVerified": MessageLookupByLibrary.simpleMessage(
      "Konto verifiziert",
    ),
    "usernameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Änderung des Benutzernamens fehlgeschlagen",
    ),
    "usernameChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Benutzername erfolgreich geändert",
    ),
    "users": MessageLookupByLibrary.simpleMessage("Benutzer"),
    "validUntil": m4,
    "verificationCodeResent": MessageLookupByLibrary.simpleMessage(
      "Verifizierungscode erneut gesendet!",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Bestätigungs-E-Mail gesendet",
    ),
    "verificationEmailSentTo": m5,
    "verificationFailed": MessageLookupByLibrary.simpleMessage(
      "Verifizierung fehlgeschlagen",
    ),
    "verify": MessageLookupByLibrary.simpleMessage("Verifizieren"),
    "victory": MessageLookupByLibrary.simpleMessage("Sieg!"),
    "viewInstitutionalGuide": MessageLookupByLibrary.simpleMessage(
      "Institutionellen Leitfaden ansehen",
    ),
    "viewLicenses": MessageLookupByLibrary.simpleMessage("Lizenzen anzeigen"),
    "viewParticipants": MessageLookupByLibrary.simpleMessage(
      "Teilnehmer anzeigen",
    ),
    "vote": MessageLookupByLibrary.simpleMessage("Abstimmen"),
    "voted": MessageLookupByLibrary.simpleMessage("Abgestimmt"),
    "weCannotProvideSecureVerificationYetButWeAreWorking":
        MessageLookupByLibrary.simpleMessage(
          "Wir können noch keine sichere Verifizierung anbieten, arbeiten aber daran.",
        ),
    "weFailedToGetYourStatePleaseProofreadYourLivingaddress":
        MessageLookupByLibrary.simpleMessage(
          "Wir konnten Ihr Bundesland nicht ermitteln, bitte überprüfen Sie Ihre Wohnadresse",
        ),
    "weHaveSentA6digitCodeToYourEmailPlease": MessageLookupByLibrary.simpleMessage(
      "Wir haben einen 6-stelligen Code an Ihre E-Mail gesendet. Bitte geben Sie ihn unten ein.",
    ),
    "welcomeBackPleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Willkommen zurück! Bitte geben Sie Ihre Daten ein.",
    ),
    "welcomePleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Willkommen! Bitte geben sie ihre Daten ein.",
    ),
    "welcomeTo": MessageLookupByLibrary.simpleMessage("Willkommen bei "),
    "welcomeToPro": MessageLookupByLibrary.simpleMessage(
      "Willkommen als Pro-Mitglied!",
    ),
    "wrongPasswordProvided": MessageLookupByLibrary.simpleMessage(
      "Falsches Passwort eingegeben.",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Ja"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, kündigen"),
    "youSubscribedToFollowingBenefits": MessageLookupByLibrary.simpleMessage(
      "Du hast folgende Vorteile abonniert:",
    ),
  };
}

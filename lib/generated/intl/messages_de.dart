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

  static String m0(mode) => "Zugangsmodus: ${mode}";

  static String m1(error) =>
      "Deine Zustimmung konnte nicht gespeichert werden: ${error}";

  static String m2(code, message) => "Datenbankfehler (${code}): ${message}";

  static String m3(state) => "Erkanntes Bundesland: ${state}";

  static String m4(groupName) => "Möchtest du „${groupName}“ verlassen?";

  static String m5(date) => "Läuft ab ${date}";

  static String m6(date) => "Läuft ab: ${date}";

  static String m7(accessMode, memberCount, expiry) =>
      "Zugang: ${accessMode} • Mitglieder: ${memberCount} • ${expiry}";

  static String m8(group) => "Gruppe: ${group}";

  static String m9(firstName, lastName) =>
      "Wilkommen ${firstName} ${lastName}!";

  static String m10(count) => "${count} CSV-Zeilen importiert.";

  static String m11(count) => "Importierte Mitglieder: ${count}";

  static String m12(validRows, invalidRows) =>
      "${validRows} Zeilen importiert. ${invalidRows} fehlerhafte Zeilen übersprungen.";

  static String m13(name) => "${name} hat dich in diese Gruppe eingeladen.";

  static String m14(joinCode) => "Beitrittscode: ${joinCode}";

  static String m15(validRows, invalidRows) =>
      "Letzter Import: ${validRows} gültige Zeilen, ${invalidRows} fehlerhafte Zeilen.";

  static String m16(count) => "Maximal ${count} Optionen erlaubt";

  static String m17(newMessages) =>
      "Sie haben ${Intl.plural(newMessages, zero: 'Keine neuen Nachrichten', one: 'Eine neue Nachricht', two: 'zwei neue Nachrichten', other: '${newMessages} neue Nachrichten')}";

  static String m18(number) => "Option ${number}";

  static String m19(type) =>
      "Das Passwort muss mindestens ein ${Intl.select(type, {'uppercase': 'Großbuchstabe', 'lowercase': 'Kleinbuchstabe', 'number': 'Zahl', 'special': 'Sonderzeichen', 'other': 'gültiges Zeichen'})} enthalten";

  static String m20(state) => "Bezogen auf ${state}";

  static String m21(name) => "${name} hat Zugriff auf diese Gruppe angefragt.";

  static String m22(scope) => "Geltungsbereich: ${scope}";

  static String m23(admin, manager, user) =>
      "Unterstützte Rollen: ${admin}, ${manager}, ${user}.";

  static String m24(groupName) =>
      "Gib „${groupName}“ ein, um das Löschen zu bestätigen. Dies kann nicht rückgängig gemacht werden.";

  static String m25(error) => "Unerwarteter Fehler: ${error}";

  static String m26(date) => "Gültig bis";

  static String m27(email) =>
      "Eine Bestätigungs-E-Mail wurde an ${email} gesendet";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aUser": MessageLookupByLibrary.simpleMessage("Ein Nutzer"),
    "about": MessageLookupByLibrary.simpleMessage("Über"),
    "aboutThisApp": MessageLookupByLibrary.simpleMessage("Über diese App"),
    "accentPallette": MessageLookupByLibrary.simpleMessage("Akzent Palette"),
    "acceptCommunityRulesBeforeContinuing": MessageLookupByLibrary.simpleMessage(
      "Bitte akzeptiere die Community-Regeln und Nutzungsbedingungen, bevor du fortfährst.",
    ),
    "acceptInvite": MessageLookupByLibrary.simpleMessage("Einladung annehmen"),
    "acceptedCsvFormat": MessageLookupByLibrary.simpleMessage(
      "Akzeptiertes Format: CSV oder TSV mit email,nickname,role",
    ),
    "accessModeLabel": m0,
    "accessRequestSent": MessageLookupByLibrary.simpleMessage(
      "Zugriffsanfrage gesendet.",
    ),
    "actionNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "Diese Aktion ist nicht mehr verfügbar.",
    ),
    "active": MessageLookupByLibrary.simpleMessage("Aktiv"),
    "activityHistory": MessageLookupByLibrary.simpleMessage(
      "Aktivitätsverlauf",
    ),
    "addComment": MessageLookupByLibrary.simpleMessage(
      "Einen Kommentar hinzufügen",
    ),
    "addDomain": MessageLookupByLibrary.simpleMessage("Domain hinzufügen"),
    "addImage": MessageLookupByLibrary.simpleMessage("Bild hinzufügen"),
    "addMember": MessageLookupByLibrary.simpleMessage("Mitglied hinzufügen"),
    "addOption": MessageLookupByLibrary.simpleMessage("Option hinzufügen"),
    "additionalDetailsOptional": MessageLookupByLibrary.simpleMessage(
      "Zusätzliche Details (optional)",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Anschrift"),
    "addressUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Anschrift erfolgreich aktualisiert",
    ),
    "adminDashboard": MessageLookupByLibrary.simpleMessage("Admin-Dashboard"),
    "adminInterface": MessageLookupByLibrary.simpleMessage("Admin-Oberfläche"),
    "adminRoleLabel": MessageLookupByLibrary.simpleMessage("Admin"),
    "alert": MessageLookupByLibrary.simpleMessage("Warnung"),
    "allGroups": MessageLookupByLibrary.simpleMessage("Alle Gruppen"),
    "allowedMailDomains": MessageLookupByLibrary.simpleMessage(
      "Erlaubte Mail-Domains",
    ),
    "allowedMailDomainsDescription": MessageLookupByLibrary.simpleMessage(
      "Nützlich für Firmen: Jeder mit passender E-Mail-Domain kann mit der gewählten Standardrolle vorbereitet werden.",
    ),
    "alreadyMemberOfGroup": MessageLookupByLibrary.simpleMessage(
      "Du bist bereits Mitglied dieser Gruppe.",
    ),
    "anUnexpectedErrorOccurred": MessageLookupByLibrary.simpleMessage(
      "Ein unerwarteter Fehler ist aufgetreten.",
    ),
    "anonymous": MessageLookupByLibrary.simpleMessage("Anonym"),
    "approveRequest": MessageLookupByLibrary.simpleMessage(
      "Anfrage genehmigen",
    ),
    "areYouSureYouWantToCancelYourProSubscription":
        MessageLookupByLibrary.simpleMessage(
          "Möchtest du dein Pro-Abo wirklich kündigen?",
        ),
    "areYouSureYouWantToClearThisDraft": MessageLookupByLibrary.simpleMessage(
      "Sind sie sicher das sie das Formular löschen wollen?",
    ),
    "areYouSureYouWantToDeleteThisForm": MessageLookupByLibrary.simpleMessage(
      "Sind Sie sicher, dass Sie dieses Formular löschen möchten?",
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
    "blockUser": MessageLookupByLibrary.simpleMessage("Nutzer blockieren"),
    "blockUserDescription": MessageLookupByLibrary.simpleMessage(
      "Dadurch werden die Inhalte dieses Nutzers sofort aus deinem Feed ausgeblendet und das StimmApp-Team zur Prüfung informiert.",
    ),
    "blockedContentHidden": MessageLookupByLibrary.simpleMessage(
      "Dieser Inhalt ist ausgeblendet, weil du diesen Nutzer blockiert hast.",
    ),
    "blockedUsers": MessageLookupByLibrary.simpleMessage("Blockierte Nutzer"),
    "blockedUsersEmpty": MessageLookupByLibrary.simpleMessage(
      "Du hast bisher niemanden blockiert.",
    ),
    "blockedUsersLoadError": MessageLookupByLibrary.simpleMessage(
      "Blockierte Nutzer konnten nicht geladen werden",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
    "cancelProSubscription": MessageLookupByLibrary.simpleMessage(
      "Pro-Abo kündigen",
    ),
    "cancelRegistration": MessageLookupByLibrary.simpleMessage(
      "Registrierung abbrechen",
    ),
    "cancelSubscription": MessageLookupByLibrary.simpleMessage("Abo kündigen"),
    "cannotDeletePetitionHasSignatures": MessageLookupByLibrary.simpleMessage(
      "Kann nicht gelöscht werden: Petition hat Unterschriften.",
    ),
    "cannotDeletePollHasVotes": MessageLookupByLibrary.simpleMessage(
      "Kann nicht gelöscht werden: Umfrage hat Stimmen.",
    ),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Sprache ändern"),
    "changePassword": MessageLookupByLibrary.simpleMessage("Passwort ändern"),
    "cityScopeFallback": MessageLookupByLibrary.simpleMessage("Stadt"),
    "clearGroupFilter": MessageLookupByLibrary.simpleMessage(
      "Gruppenfilter löschen",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Schließen"),
    "closed": MessageLookupByLibrary.simpleMessage("Beended"),
    "colorMode": MessageLookupByLibrary.simpleMessage("Farbmodus"),
    "colorTheme": MessageLookupByLibrary.simpleMessage("Farbthema"),
    "comments": MessageLookupByLibrary.simpleMessage("Kommentare"),
    "communityRules": MessageLookupByLibrary.simpleMessage("Community-Regeln"),
    "communityRulesAcceptance": MessageLookupByLibrary.simpleMessage(
      "Ich stimme den Nutzungsbedingungen zu und verstehe, dass StimmApp keine anstößigen Inhalte oder missbräuchliches Verhalten toleriert.",
    ),
    "communityRulesAgreementNotice": MessageLookupByLibrary.simpleMessage(
      "Wenn du fortfährst, stimmst du den Nutzungsbedingungen zu und bestätigst, dass du nur rechtmäßige und respektvolle Inhalte veröffentlichst. Gemeldete missbräuchliche Inhalte können entfernt und missbräuchliche Nutzer gesperrt oder dauerhaft entfernt werden.",
    ),
    "communityRulesZeroTolerance": MessageLookupByLibrary.simpleMessage(
      "StimmApp toleriert keine anstößigen Inhalte, Belästigung, Hassrede, sexuelle Ausbeutung oder missbräuchliches Verhalten.",
    ),
    "completelyPrivateAccessMode": MessageLookupByLibrary.simpleMessage(
      "Vollständig privat",
    ),
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
    "copyInviteLinkTooltip": MessageLookupByLibrary.simpleMessage(
      "Einladungslink kopieren",
    ),
    "copyLinkLabel": MessageLookupByLibrary.simpleMessage("Link kopieren"),
    "couldNotOpenLink": MessageLookupByLibrary.simpleMessage(
      "Link konnte nicht geöffnet werden.",
    ),
    "couldNotOpenPaywall": MessageLookupByLibrary.simpleMessage(
      "Paywall konnte nicht geöffnet werden",
    ),
    "couldNotSaveYourAcceptance": m1,
    "countryScopeFallback": MessageLookupByLibrary.simpleMessage("Land"),
    "createGroupDescription": MessageLookupByLibrary.simpleMessage(
      "Erstelle einen nur für Mitglieder zugänglichen Abstimmungsbereich für Teams, Events und Firmen.",
    ),
    "createGroupTitle": MessageLookupByLibrary.simpleMessage(
      "Gruppe erstellen",
    ),
    "createGroupTooltip": MessageLookupByLibrary.simpleMessage(
      "Gruppe erstellen",
    ),
    "createNewGroup": MessageLookupByLibrary.simpleMessage(
      "Neue Gruppe erstellen",
    ),
    "createNewPetitionDescription": MessageLookupByLibrary.simpleMessage(
      "Erstelle eine neue Petition",
    ),
    "createNewPollDescription": MessageLookupByLibrary.simpleMessage(
      "Erstelle eine neue Umfrage",
    ),
    "createOrManageGroups": MessageLookupByLibrary.simpleMessage(
      "erstelle oder verwalte Gruppen",
    ),
    "createPetition": MessageLookupByLibrary.simpleMessage(
      "Petitition erstellen",
    ),
    "createPoll": MessageLookupByLibrary.simpleMessage("Umfrage erstellen"),
    "createdPetition": MessageLookupByLibrary.simpleMessage(
      "Petition erstellt",
    ),
    "createdPoll": MessageLookupByLibrary.simpleMessage("Umfrage erstellt"),
    "creatingGroup": MessageLookupByLibrary.simpleMessage("Erstelle..."),
    "creator": MessageLookupByLibrary.simpleMessage("Ersteller"),
    "creatorRoleLabel": MessageLookupByLibrary.simpleMessage("Ersteller"),
    "csvMembersHint": MessageLookupByLibrary.simpleMessage(
      "email,nickname,role\nanna@company.com,Anna,user",
    ),
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
    "databaseError": m2,
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
    "deleteForm": MessageLookupByLibrary.simpleMessage("Formular löschen"),
    "deleteGroup": MessageLookupByLibrary.simpleMessage("Gruppe löschen"),
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
    "denyInvite": MessageLookupByLibrary.simpleMessage("Einladung ablehnen"),
    "denyRequest": MessageLookupByLibrary.simpleMessage("Anfrage ablehnen"),
    "description": MessageLookupByLibrary.simpleMessage("Beschreibung"),
    "descriptionRequired": MessageLookupByLibrary.simpleMessage(
      "Beschreibung ist erforderlich",
    ),
    "descriptionTooShort": MessageLookupByLibrary.simpleMessage(
      "Beschreibung ist zu kurz",
    ),
    "detectedStateLabel": m3,
    "devContactInformation": MessageLookupByLibrary.simpleMessage(
      "Diese App wurde von Team LeEd mit Hilfe von Yannic entwickelt",
    ),
    "developerSandbox": MessageLookupByLibrary.simpleMessage(
      "Entwickler-Sandbox",
    ),
    "displayName": MessageLookupByLibrary.simpleMessage("angezeigter Name"),
    "displayQrCode": MessageLookupByLibrary.simpleMessage("QR Code anzeigen"),
    "doYouWantToLeaveGroup": m4,
    "domainHint": MessageLookupByLibrary.simpleMessage("company.com"),
    "domainLabel": MessageLookupByLibrary.simpleMessage("Domain"),
    "dropCsvHere": MessageLookupByLibrary.simpleMessage("CSV hier ablegen"),
    "editGroupDescription": MessageLookupByLibrary.simpleMessage(
      "Passe Zugriffsregeln, Einladungen und Einstellungen für diese Gruppe an.",
    ),
    "editGroupTitle": MessageLookupByLibrary.simpleMessage("Gruppe bearbeiten"),
    "editLabel": MessageLookupByLibrary.simpleMessage("Bearbeiten"),
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
    "enterYourReasonHere": MessageLookupByLibrary.simpleMessage(
      "Geben Sie hier Ihren Grund ein...",
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
    "euScopeOnlyForEuCountries": MessageLookupByLibrary.simpleMessage(
      "Der EU-Geltungsbereich ist nur für EU-Länder verfügbar",
    ),
    "europeScopeLabel": MessageLookupByLibrary.simpleMessage("Europa"),
    "everyoneCanJoinWithoutApproval": MessageLookupByLibrary.simpleMessage(
      "Jeder kann ohne Genehmigung beitreten.",
    ),
    "exercise": MessageLookupByLibrary.simpleMessage("Übung"),
    "expirationDateOptional": MessageLookupByLibrary.simpleMessage(
      "Ablaufdatum (optional)",
    ),
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
    "expiresOnDate": m5,
    "expiresOnShort": m6,
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
    "failedToLoadYourGroups": MessageLookupByLibrary.simpleMessage(
      "Deine Gruppen konnten nicht geladen werden.",
    ),
    "failedToResendCode": MessageLookupByLibrary.simpleMessage(
      "Code konnte nicht erneut gesendet werden",
    ),
    "failedToUploadImage": MessageLookupByLibrary.simpleMessage(
      "Bild konnte nicht hochgeladen werden",
    ),
    "faultyInput": MessageLookupByLibrary.simpleMessage("Fehlerhafte Eingabe"),
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "filterBy": MessageLookupByLibrary.simpleMessage("filtern nach"),
    "filterByGroup": MessageLookupByLibrary.simpleMessage(
      "filtern nach Gruppe",
    ),
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
    "globalScopeLabel": MessageLookupByLibrary.simpleMessage("Global"),
    "goProToAccessTheseBenefits": MessageLookupByLibrary.simpleMessage(
      "Pro-Abo abschließen um diese Vorteile zu nutzen",
    ),
    "goToWelcome": MessageLookupByLibrary.simpleMessage("Zum Startbildschirm"),
    "goal": MessageLookupByLibrary.simpleMessage("Ziel"),
    "groupAccess": MessageLookupByLibrary.simpleMessage("Gruppenzugang"),
    "groupAccessAccepted": MessageLookupByLibrary.simpleMessage(
      "Gespeichert. Gruppenzugang akzeptiert.",
    ),
    "groupAccessSummary": m7,
    "groupAccessTitle": MessageLookupByLibrary.simpleMessage("Gruppenzugang"),
    "groupCreated": MessageLookupByLibrary.simpleMessage("Gruppe erstellt."),
    "groupCreatorsCannotLeaveOwnGroup": MessageLookupByLibrary.simpleMessage(
      "Gruppenersteller können ihre eigene Gruppe nicht verlassen. Bearbeite oder lösche sie stattdessen.",
    ),
    "groupDeleted": MessageLookupByLibrary.simpleMessage("Gruppe gelöscht."),
    "groupDetailsTemporarilyUnavailable": MessageLookupByLibrary.simpleMessage(
      "Gruppendetails sind vorübergehend nicht verfügbar.",
    ),
    "groupDetailsTemporarilyUnavailableRespond":
        MessageLookupByLibrary.simpleMessage(
          "Gruppendetails sind vorübergehend nicht verfügbar, aber du kannst trotzdem auf diese Benachrichtigung reagieren.",
        ),
    "groupFilterEmpty": MessageLookupByLibrary.simpleMessage(
      "Es sind noch keine beigetretenen oder akzeptierten Gruppen verfügbar.",
    ),
    "groupHasNoActiveInviteLink": MessageLookupByLibrary.simpleMessage(
      "Diese Gruppe hat keinen aktiven Einladungslink.",
    ),
    "groupLabelWithValue": m8,
    "groupNameDidNotMatch": MessageLookupByLibrary.simpleMessage(
      "Der Gruppenname stimmt nicht überein.",
    ),
    "groupNameLabel": MessageLookupByLibrary.simpleMessage("Gruppenname"),
    "groupUpdated": MessageLookupByLibrary.simpleMessage(
      "Gruppe aktualisiert.",
    ),
    "groupsLabel": MessageLookupByLibrary.simpleMessage("Gruppen"),
    "growthStartsWithin": MessageLookupByLibrary.simpleMessage(
      "Wachstum beginnt von innen",
    ),
    "harassmentOrBullying": MessageLookupByLibrary.simpleMessage(
      "Belästigung oder Mobbing",
    ),
    "hateSpeech": MessageLookupByLibrary.simpleMessage("Hassrede"),
    "height": MessageLookupByLibrary.simpleMessage("Größe"),
    "hello": MessageLookupByLibrary.simpleMessage("Hallo"),
    "helloAndWelcome": m9,
    "hintTextTags": MessageLookupByLibrary.simpleMessage(
      "z.B. umwelt, verkehr",
    ),
    "idNumber": MessageLookupByLibrary.simpleMessage("Ausweisnummer"),
    "idScan": MessageLookupByLibrary.simpleMessage("Ausweisscan"),
    "imagePreviewDescription": MessageLookupByLibrary.simpleMessage(
      "Bildvorschau",
    ),
    "importCsvFileLabel": MessageLookupByLibrary.simpleMessage(
      "CSV-Datei importieren",
    ),
    "importLabel": MessageLookupByLibrary.simpleMessage("Importieren"),
    "importedCsvRows": m10,
    "importedMembersCount": m11,
    "importedRowsSkippedMalformed": m12,
    "inactive": MessageLookupByLibrary.simpleMessage("Inaktiv"),
    "info": MessageLookupByLibrary.simpleMessage("Info"),
    "invalidEmailEntered": MessageLookupByLibrary.simpleMessage(
      "Ungültige E-Mail-Adresse eingegeben",
    ),
    "invalidGroupInviteQrCode": MessageLookupByLibrary.simpleMessage(
      "Dieser QR-Code enthält keine gültige Gruppeneinladung.",
    ),
    "invalidProtectedInviteLink": MessageLookupByLibrary.simpleMessage(
      "Dieser Einladungslink ist für die geschützte Gruppe nicht gültig.",
    ),
    "inviteDenied": MessageLookupByLibrary.simpleMessage(
      "Einladung abgelehnt.",
    ),
    "inviteLinkOnLabel": MessageLookupByLibrary.simpleMessage(
      "Einladungslink an",
    ),
    "inviteMembersDescription": MessageLookupByLibrary.simpleMessage(
      "Plan A: Personen einzeln hinzufügen. Plan B: CSV-Zeilen importieren oder eine CSV-Datei unten ablegen. Es werden nicht automatisch E-Mails versendet.",
    ),
    "inviteMembersTitle": MessageLookupByLibrary.simpleMessage(
      "Mitglieder einladen",
    ),
    "invitedYouToThisGroup": m13,
    "isProMember": MessageLookupByLibrary.simpleMessage("Ist Pro-Mitglied"),
    "joinCodeWithValue": m14,
    "joinGroup": MessageLookupByLibrary.simpleMessage("Gruppe beitreten"),
    "keepSelected": MessageLookupByLibrary.simpleMessage("Auswahl behalten"),
    "language": MessageLookupByLibrary.simpleMessage("Sprache"),
    "lastImportSummary": m15,
    "lastStep": MessageLookupByLibrary.simpleMessage("Letzter Schritt!"),
    "leaveGroup": MessageLookupByLibrary.simpleMessage("Gruppe verlassen"),
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
    "manageGroupsTitle": MessageLookupByLibrary.simpleMessage(
      "Gruppen verwalten",
    ),
    "managerRoleLabel": MessageLookupByLibrary.simpleMessage("Manager"),
    "managersCanPrepareAccessLists": MessageLookupByLibrary.simpleMessage(
      "Manager können Zugangslisten vorbereiten",
    ),
    "maximumPollOptionsAllowed": m16,
    "memberRoleLabel": MessageLookupByLibrary.simpleMessage("Mitglied"),
    "membersCanChooseTheirOwnNickname": MessageLookupByLibrary.simpleMessage(
      "Mitglieder können ihren Spitznamen selbst wählen",
    ),
    "membershipStatus": MessageLookupByLibrary.simpleMessage(
      "Mitgliedschaftsstatus",
    ),
    "misinformationOrFraud": MessageLookupByLibrary.simpleMessage(
      "Falschinformationen oder Betrug",
    ),
    "moreBenefitsToBeAddedLater": MessageLookupByLibrary.simpleMessage(
      "Weitere Vorteile folgen",
    ),
    "myGroups": MessageLookupByLibrary.simpleMessage("Meine Gruppen"),
    "myPetitions": MessageLookupByLibrary.simpleMessage("Meine Petitionen"),
    "myProfile": MessageLookupByLibrary.simpleMessage("Mein Profil"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Namensänderung fehlgeschlagen",
    ),
    "nationality": MessageLookupByLibrary.simpleMessage("Staatsangehörigkeit"),
    "newMessages": m17,
    "newPassword": MessageLookupByLibrary.simpleMessage("Neues Passwort"),
    "newUser": MessageLookupByLibrary.simpleMessage("Neuer Benutzer"),
    "newUsername": MessageLookupByLibrary.simpleMessage("Neuer Benutzername"),
    "nickname": MessageLookupByLibrary.simpleMessage("Spitzname"),
    "no": MessageLookupByLibrary.simpleMessage("Nein"),
    "noActivityFound": MessageLookupByLibrary.simpleMessage(
      "Noch keine Aktivität gefunden.",
    ),
    "noAdvertisements": MessageLookupByLibrary.simpleMessage("Keine Werbung"),
    "noCsvRowsImported": MessageLookupByLibrary.simpleMessage(
      "Es wurden keine CSV-Zeilen importiert.",
    ),
    "noData": MessageLookupByLibrary.simpleMessage("Keine Daten"),
    "noDomainRulesYet": MessageLookupByLibrary.simpleMessage(
      "Noch keine Domain-Regeln.",
    ),
    "noEmail": MessageLookupByLibrary.simpleMessage("Keine E-Mail"),
    "noExpirationDateSet": MessageLookupByLibrary.simpleMessage(
      "Kein Ablaufdatum festgelegt.",
    ),
    "noExpiredItems": MessageLookupByLibrary.simpleMessage(
      "Keine abgelaufenen Einträge",
    ),
    "noExpiry": MessageLookupByLibrary.simpleMessage("Kein Ablaufdatum"),
    "noFittingOptions": MessageLookupByLibrary.simpleMessage(
      "Keine passenden Optionen",
    ),
    "noGroupNotificationsYet": MessageLookupByLibrary.simpleMessage(
      "Noch keine Gruppenbenachrichtigungen.",
    ),
    "noGroupsYetCreateOneAboveToStartTeamPolling":
        MessageLookupByLibrary.simpleMessage(
          "Noch keine Gruppen. Erstelle oben eine, um mit Team-Abstimmungen zu beginnen.",
        ),
    "noImageSelected": MessageLookupByLibrary.simpleMessage(
      "Kein Bild ausgewählt",
    ),
    "noName": MessageLookupByLibrary.simpleMessage("Kein Name"),
    "noOptions": MessageLookupByLibrary.simpleMessage("Keine Optionen"),
    "noProMember": MessageLookupByLibrary.simpleMessage(
      "Nein, kein Pro-Mitglied",
    ),
    "noRunningPetitionsFound": MessageLookupByLibrary.simpleMessage(
      "Keine laufenden Petitionen gefunden.",
    ),
    "noRunningPollsFound": MessageLookupByLibrary.simpleMessage(
      "Keine laufenden Umfragen gefunden.",
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
    "notificationActionInvitedYou": MessageLookupByLibrary.simpleMessage(
      "hat dich eingeladen",
    ),
    "notificationActionRequestedAccess": MessageLookupByLibrary.simpleMessage(
      "hat Zugriff angefragt",
    ),
    "notificationStatusAccepted": MessageLookupByLibrary.simpleMessage(
      "Angenommen",
    ),
    "notificationStatusDenied": MessageLookupByLibrary.simpleMessage(
      "Abgelehnt",
    ),
    "notificationStatusPending": MessageLookupByLibrary.simpleMessage(
      "Ausstehend",
    ),
    "notificationsTitle": MessageLookupByLibrary.simpleMessage(
      "Benachrichtigungen",
    ),
    "onlyPreparedMembersCanParticipate": MessageLookupByLibrary.simpleMessage(
      "Nur von Admins oder Managern vorbereitete Mitglieder können teilnehmen.",
    ),
    "openAccessMode": MessageLookupByLibrary.simpleMessage("Offen"),
    "openApp": MessageLookupByLibrary.simpleMessage("App öffnen"),
    "openGroupsCanBeJoinedImmediately": MessageLookupByLibrary.simpleMessage(
      "Offene Gruppen können sofort beigetreten werden.",
    ),
    "openPrivacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Datenschutzerklärung öffnen",
    ),
    "openTermsOfService": MessageLookupByLibrary.simpleMessage(
      "Nutzungsbedingungen öffnen",
    ),
    "option": MessageLookupByLibrary.simpleMessage("Option"),
    "optionNumber": m18,
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
    "passwordMustBeAtLeast8CharactersLong":
        MessageLookupByLibrary.simpleMessage(
          "Passwort muss mindestens 8 Character lang sein",
        ),
    "passwordValidation": m19,
    "passwordsDoNotMatch": MessageLookupByLibrary.simpleMessage(
      "Passwörter stimmen nicht überein",
    ),
    "pasteCsvLabel": MessageLookupByLibrary.simpleMessage("CSV einfügen"),
    "pasteCsvMembers": MessageLookupByLibrary.simpleMessage(
      "CSV-Mitglieder einfügen",
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
    "peopleWithInviteLinkCanRequestAccessToGroup":
        MessageLookupByLibrary.simpleMessage(
          "Personen mit dem Einladungslink können Zugang zur Gruppe anfragen.",
        ),
    "permanentlyDeleteAccount": MessageLookupByLibrary.simpleMessage(
      "KONTO DAUERHAFT LÖSCHEN",
    ),
    "petition": MessageLookupByLibrary.simpleMessage("Petition"),
    "petitionBy": MessageLookupByLibrary.simpleMessage("Petition von"),
    "petitionDeleted": MessageLookupByLibrary.simpleMessage(
      "Petition gelöscht",
    ),
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
    "pickExistingGroupToUseOrEditOrCreateNewOne":
        MessageLookupByLibrary.simpleMessage(
          "Wähle eine bestehende Gruppe zum Verwenden oder Bearbeiten aus oder erstelle eine neue.",
        ),
    "pickExpirationDate": MessageLookupByLibrary.simpleMessage(
      "Ablaufdatum auswählen",
    ),
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
    "pleaseEnterGroupName": MessageLookupByLibrary.simpleMessage(
      "Bitte gib einen Gruppennamen ein.",
    ),
    "pleaseEnterTown": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie einen Ort ein",
    ),
    "pleaseEnterValidEmailDomains": MessageLookupByLibrary.simpleMessage(
      "Bitte gib gültige E-Mail-Domains wie company.com ein.",
    ),
    "pleaseEnterValidEmailForEveryInvitedMember":
        MessageLookupByLibrary.simpleMessage(
          "Bitte gib für jedes eingeladene Mitglied eine gültige E-Mail-Adresse ein.",
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
    "pleaseSelectAddressWithTown": MessageLookupByLibrary.simpleMessage(
      "Bitte wähle eine Adresse mit Ort aus",
    ),
    "pleaseSelectState": MessageLookupByLibrary.simpleMessage(
      "Bitte wähle dein Bundesland aus.",
    ),
    "pleaseSetCountryInAddressFirst": MessageLookupByLibrary.simpleMessage(
      "Bitte hinterlegen Sie zuerst Ihr Land in Ihrer Adresse",
    ),
    "pleaseSignInFirst": MessageLookupByLibrary.simpleMessage(
      "Bitte zuerst anmelden",
    ),
    "pleaseSignInToConfirmYourIdentity": MessageLookupByLibrary.simpleMessage(
      "Bitte melden Sie sich an, um Ihre Identität zu bestätigen.",
    ),
    "pleaseSignInToManageGroups": MessageLookupByLibrary.simpleMessage(
      "Bitte melde dich an, um Gruppen zu verwalten.",
    ),
    "pleaseSignInToViewGroupInvitations": MessageLookupByLibrary.simpleMessage(
      "Bitte melde dich an, um Gruppeneinladungen zu sehen.",
    ),
    "pleaseSignInToViewYourGroups": MessageLookupByLibrary.simpleMessage(
      "Bitte melde dich an, um deine Gruppen anzuzeigen.",
    ),
    "pleaseUsePhoneToRegister": MessageLookupByLibrary.simpleMessage(
      "Bitte benutze dein Telefon zur Registrierung",
    ),
    "poll": MessageLookupByLibrary.simpleMessage("Umfrage"),
    "pollDeleted": MessageLookupByLibrary.simpleMessage("Umfrage gelöscht"),
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
    "privacy": MessageLookupByLibrary.simpleMessage("Datenschutz"),
    "privacySettings": MessageLookupByLibrary.simpleMessage(
      "Datenschutzeinstellungen",
    ),
    "privateGroupOrSignInRequired": MessageLookupByLibrary.simpleMessage(
      "Diese Gruppe ist privat oder erfordert eine Anmeldung, bevor weitere Details angezeigt werden können.",
    ),
    "privateGroupWaitForInvite": MessageLookupByLibrary.simpleMessage(
      "Diese Gruppe ist vollständig privat. Bitte warte auf eine direkte Einladung der Gruppenadmins.",
    ),
    "proMember": MessageLookupByLibrary.simpleMessage("Pro-Mitglied"),
    "processId": MessageLookupByLibrary.simpleMessage("Ausweis verarbeiten"),
    "products": MessageLookupByLibrary.simpleMessage("Produkte"),
    "profile": MessageLookupByLibrary.simpleMessage("Profil"),
    "profilePictureUpdated": MessageLookupByLibrary.simpleMessage(
      "Profilbild aktualisiert",
    ),
    "protectedAccessMode": MessageLookupByLibrary.simpleMessage("Geschützt"),
    "protectedGroupsRequireApprovalRequest": MessageLookupByLibrary.simpleMessage(
      "Geschützte Gruppen benötigen eine Genehmigungsanfrage, bevor du beitreten kannst.",
    ),
    "protectedGroupsRequireInviteLink": MessageLookupByLibrary.simpleMessage(
      "Geschützte Gruppen benötigen einen gültigen Einladungslink und eine Zugriffsanfrage.",
    ),
    "public": MessageLookupByLibrary.simpleMessage("öffentlich"),
    "publications": MessageLookupByLibrary.simpleMessage("Veröffentlichungen"),
    "publishTo": MessageLookupByLibrary.simpleMessage("zeigen in"),
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
    "reasonYourSignature": MessageLookupByLibrary.simpleMessage(
      "Begründen Sie Ihre Unterschrift",
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
    "relatedToState": m20,
    "remove": MessageLookupByLibrary.simpleMessage("Entfernen"),
    "removeAbusiveLanguageBeforePublishing": MessageLookupByLibrary.simpleMessage(
      "Bitte entferne beleidigende oder anstößige Sprache vor dem Veröffentlichen.",
    ),
    "removeAbusiveLanguageFromPublicName": MessageLookupByLibrary.simpleMessage(
      "Bitte entferne missbräuchliche oder anstößige Sprache aus deinem öffentlichen Namen.",
    ),
    "removeDomainTooltip": MessageLookupByLibrary.simpleMessage(
      "Domain entfernen",
    ),
    "removeMemberTooltip": MessageLookupByLibrary.simpleMessage(
      "Mitglied entfernen",
    ),
    "reportContent": MessageLookupByLibrary.simpleMessage("Inhalt melden"),
    "reportSubmittedReview24Hours": MessageLookupByLibrary.simpleMessage(
      "Meldung eingereicht. Wir prüfen Meldungen innerhalb von 24 Stunden.",
    ),
    "requestAccess": MessageLookupByLibrary.simpleMessage("Zugang anfragen"),
    "requestLoginCode": MessageLookupByLibrary.simpleMessage(
      "Login Code anfordern",
    ),
    "requestedAccessToThisGroup": m21,
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
    "roleLabel": MessageLookupByLibrary.simpleMessage("Rolle"),
    "runningForms": MessageLookupByLibrary.simpleMessage("Laufende Formulare"),
    "save": MessageLookupByLibrary.simpleMessage("Speichern"),
    "saveGroupLabel": MessageLookupByLibrary.simpleMessage("Gruppe speichern"),
    "saving": MessageLookupByLibrary.simpleMessage("Speichern..."),
    "savingGroup": MessageLookupByLibrary.simpleMessage("Speichere..."),
    "scanAgain": MessageLookupByLibrary.simpleMessage("Erneut scannen"),
    "scanGroupQrCode": MessageLookupByLibrary.simpleMessage(
      "QR-Code für Gruppe scannen",
    ),
    "scanQrCode": MessageLookupByLibrary.simpleMessage("QR-Code scannen"),
    "scanQrCodeTooltip": MessageLookupByLibrary.simpleMessage(
      "QR-Code scannen",
    ),
    "scanYourId": MessageLookupByLibrary.simpleMessage(
      "Bitte scannen Sie Ihren deutschen Personalausweis",
    ),
    "scannedData": MessageLookupByLibrary.simpleMessage("Gescannte Daten"),
    "scope": MessageLookupByLibrary.simpleMessage("Geltungsbereich"),
    "scopeAndGroup": MessageLookupByLibrary.simpleMessage(
      "Geltungsbereich und Gruppe",
    ),
    "scopeCity": MessageLookupByLibrary.simpleMessage("Stadt"),
    "scopeContinent": MessageLookupByLibrary.simpleMessage("Kontinent"),
    "scopeCountry": MessageLookupByLibrary.simpleMessage("Land"),
    "scopeDetails": MessageLookupByLibrary.simpleMessage(
      "Details zum Geltungsbereich",
    ),
    "scopeEu": MessageLookupByLibrary.simpleMessage("EU"),
    "scopeGlobal": MessageLookupByLibrary.simpleMessage("Global"),
    "scopeLabelWithValue": m22,
    "scopeStateRegion": MessageLookupByLibrary.simpleMessage(
      "Bundesland / Region",
    ),
    "searchPoweredByTomTom": MessageLookupByLibrary.simpleMessage(
      "Suche mit TomTom",
    ),
    "searchTextField": MessageLookupByLibrary.simpleMessage("Schlagwort"),
    "select": MessageLookupByLibrary.simpleMessage("Auswählen"),
    "selectFromCamera": MessageLookupByLibrary.simpleMessage(
      "Mit Kamera aufnehmen",
    ),
    "selectFromGallery": MessageLookupByLibrary.simpleMessage(
      "Aus Galerie wählen",
    ),
    "selectPaymentProvider": MessageLookupByLibrary.simpleMessage(
      "Zahlungsanbieter auswählen",
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
    "sendLoginLink": MessageLookupByLibrary.simpleMessage(
      "Login Link abschicken",
    ),
    "setExpirationDate": MessageLookupByLibrary.simpleMessage(
      "Ablaufdatum festlegen",
    ),
    "setTomTomApiKeyToEnableSuggestions": MessageLookupByLibrary.simpleMessage(
      "Setze TOMTOM_SEARCH_API_KEY, um Adressvorschläge zu aktivieren",
    ),
    "setUserDetails": MessageLookupByLibrary.simpleMessage(
      "Benutzerdaten festlegen",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Einstellungen"),
    "sexualOrExplicitContent": MessageLookupByLibrary.simpleMessage(
      "Sexuelle oder explizite Inhalte",
    ),
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
    "signInToJoinGroup": MessageLookupByLibrary.simpleMessage(
      "Anmelden zum Beitreten",
    ),
    "signInToJoinGroupAutomatically": MessageLookupByLibrary.simpleMessage(
      "Melde dich an, um dieser Gruppe automatisch beizutreten.",
    ),
    "signInToRequestGroupAccess": MessageLookupByLibrary.simpleMessage(
      "Anmelden, um Zugang anzufragen",
    ),
    "signPetition": MessageLookupByLibrary.simpleMessage(
      "Petition unterzeichnen",
    ),
    "signUpForPro": MessageLookupByLibrary.simpleMessage("Pro-Abo abschließen"),
    "signatureReasoning": MessageLookupByLibrary.simpleMessage(
      "Begründung der Unterschrift",
    ),
    "signatureReasoningInfo": MessageLookupByLibrary.simpleMessage(
      "Aktiviert das Kommentieren deiner Unterschriften und Meinungen vor dem Absenden.",
    ),
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
    "stateRegionScopeFallback": MessageLookupByLibrary.simpleMessage(
      "Bundesland / Region",
    ),
    "stateUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Bundesland erfolgreich aktualisiert",
    ),
    "stimmapp": MessageLookupByLibrary.simpleMessage("stimmapp"),
    "submit": MessageLookupByLibrary.simpleMessage("Senden"),
    "subscriptionCancelledAccessWillRemainUntilExpiry":
        MessageLookupByLibrary.simpleMessage(
          "Abo gekündigt. Zugriff bleibt bis zum Ablauf erhalten.",
        ),
    "successfullyLoggedIn": MessageLookupByLibrary.simpleMessage(
      "Erfolgreich angemeldet",
    ),
    "supportedRoles": m23,
    "supporters": MessageLookupByLibrary.simpleMessage("Unterstützer"),
    "surname": MessageLookupByLibrary.simpleMessage("Nachname"),
    "swipeForDelete": MessageLookupByLibrary.simpleMessage(
      "Wische zum Löschen.",
    ),
    "swipeToLeaveGroup": MessageLookupByLibrary.simpleMessage(
      "Wische, um die Gruppe zu verlassen.",
    ),
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
    "terms": MessageLookupByLibrary.simpleMessage("AGB"),
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
    "town": MessageLookupByLibrary.simpleMessage("Ort"),
    "travel": MessageLookupByLibrary.simpleMessage("Reisen"),
    "typeGroupNameToConfirmDeletion": m24,
    "unblock": MessageLookupByLibrary.simpleMessage("Blockierung aufheben"),
    "unblockedUserSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Nutzer erfolgreich entsperrt.",
    ),
    "unexpectedErrorWithDetails": m25,
    "unknownError": MessageLookupByLibrary.simpleMessage("Unbekannter Fehler"),
    "unknownUser": MessageLookupByLibrary.simpleMessage("Unbekannter Nutzer"),
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
    "useForThisPoll": MessageLookupByLibrary.simpleMessage(
      "Für diese Umfrage verwenden",
    ),
    "userBlockedContentHidden": MessageLookupByLibrary.simpleMessage(
      "Nutzer blockiert. Seine Inhalte sind jetzt ausgeblendet.",
    ),
    "userNotAvailable": MessageLookupByLibrary.simpleMessage(
      "Benutzer nicht verfügbar",
    ),
    "userNotFound": MessageLookupByLibrary.simpleMessage(
      "Benutzer nicht gefunden",
    ),
    "userProfileVerified": MessageLookupByLibrary.simpleMessage(
      "Konto verifiziert",
    ),
    "userRoleLabel": MessageLookupByLibrary.simpleMessage("Benutzer"),
    "usernameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Änderung des Benutzernamens fehlgeschlagen",
    ),
    "usernameChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Benutzername erfolgreich geändert",
    ),
    "users": MessageLookupByLibrary.simpleMessage("Benutzer"),
    "validUntil": m26,
    "verificationCodeResent": MessageLookupByLibrary.simpleMessage(
      "Verifizierungscode erneut gesendet!",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Bestätigungs-E-Mail gesendet",
    ),
    "verificationEmailSentTo": m27,
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
    "violenceOrThreats": MessageLookupByLibrary.simpleMessage(
      "Gewalt oder Drohungen",
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
    "whyAreYouSigning": MessageLookupByLibrary.simpleMessage(
      "Warum unterzeichnen Sie?",
    ),
    "wrongPasswordProvided": MessageLookupByLibrary.simpleMessage(
      "Falsches Passwort eingegeben.",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Ja"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, kündigen"),
    "youAreNotMemberOfAnyGroupsYet": MessageLookupByLibrary.simpleMessage(
      "Du bist noch in keiner Gruppe Mitglied.",
    ),
    "youJoinedTheGroup": MessageLookupByLibrary.simpleMessage(
      "Du bist der Gruppe beigetreten.",
    ),
    "youLeftTheGroup": MessageLookupByLibrary.simpleMessage(
      "Du hast die Gruppe verlassen.",
    ),
    "youSubscribedToFollowingBenefits": MessageLookupByLibrary.simpleMessage(
      "Du hast folgende Vorteile abonniert:",
    ),
    "yourGroupsTitle": MessageLookupByLibrary.simpleMessage("Deine Gruppen"),
  };
}

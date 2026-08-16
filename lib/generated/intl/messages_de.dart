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

  static String m1(count) => "${count} aktive Mitglieder";

  static String m2(email) =>
      "Erstelle ein Passwort für ${email}. Dein bestehendes StimmApp-Konto und Profil bleiben erhalten.";

  static String m3(deadline) => "Die Wahl endet am ${deadline}";

  static String m4(date) => "Endgültige Beendigung: ${date}";

  static String m5(error) =>
      "Deine Zustimmung konnte nicht gespeichert werden: ${error}";

  static String m6(code, message) => "Datenbankfehler (${code}): ${message}";

  static String m7(state) => "Erkanntes Bundesland: ${state}";

  static String m8(groupName) =>
      "Möchtest du „${groupName}“ wirklich verlassen?";

  static String m9(count) =>
      "${Intl.plural(count, one: '1 Tag', other: '${count} Tage')}";

  static String m10(date) => "Läuft ab ${date}";

  static String m11(date) => "Läuft ab: ${date}";

  static String m12(accessMode, memberCount, expiry) =>
      "Zugang: ${accessMode} • Mitglieder: ${memberCount} • ${expiry}";

  static String m13(subject) => "${subject} hat die Gruppenleitung übernommen.";

  static String m14(actor) =>
      "Nachdem ${actor} die Gruppe verlassen hat, wurde eine Admin-Wahl gestartet.";

  static String m15(actor) => "${actor} hat die Gruppe erstellt.";

  static String m16(actor, count) =>
      "${actor} hat ${count} Einladungen gesendet.";

  static String m17(actor) => "${actor} ist der Gruppe beigetreten.";

  static String m18(actor) => "${actor} hat die Gruppe verlassen.";

  static String m19(actor, subject) =>
      "${actor} hat ${subject} aus der Gruppe entfernt.";

  static String m20(actor, subject) =>
      "${actor} hat die Gruppe verlassen und die Leitung an ${subject} übertragen.";

  static String m21(actor, title) => "${actor} hat „${title}“ veröffentlicht.";

  static String m22(actor) => "${actor} hat die Gruppeneinstellungen geändert.";

  static String m23(group) => "Gruppe: ${group}";

  static String m24(firstName, lastName) =>
      "Willkommen ${firstName} ${lastName}!";

  static String m25(count) => "${count} CSV-Zeilen importiert.";

  static String m26(count) => "Importierte Mitglieder: ${count}";

  static String m27(validRows, invalidRows) =>
      "${validRows} Zeilen importiert. ${invalidRows} fehlerhafte Zeilen übersprungen.";

  static String m28(name) => "${name} hat dich in diese Gruppe eingeladen.";

  static String m29(joinCode) => "Beitrittscode: ${joinCode}";

  static String m30(validRows, invalidRows) =>
      "Letzter Import: ${validRows} gültige Zeilen, ${invalidRows} fehlerhafte Zeilen.";

  static String m31(count) => "Maximal ${count} Optionen erlaubt";

  static String m32(count) => "Maximal ${count} Fragen erlaubt";

  static String m33(count) => "${count} Einladungen gesendet.";

  static String m34(count) => "Mindestens ${count} Zeichen";

  static String m35(newMessages) =>
      "Du hast ${Intl.plural(newMessages, zero: 'keine neuen Nachrichten', one: 'eine neue Nachricht', two: 'zwei neue Nachrichten', other: '${newMessages} neue Nachrichten')}";

  static String m36(number) => "Option ${number}";

  static String m37(type) =>
      "Das Passwort muss mindestens ein ${Intl.select(type, {'uppercase': 'Großbuchstabe', 'lowercase': 'Kleinbuchstabe', 'number': 'Zahl', 'special': 'Sonderzeichen', 'other': 'gültiges Zeichen'})} enthalten";

  static String m38(number) => "Frage ${number}";

  static String m39(state) => "Bezogen auf ${state}";

  static String m40(name) => "${name} aus dieser Gruppe entfernen?";

  static String m41(count) =>
      "${Intl.plural(count, one: 'Das ausgewählte Mitglied aus dieser Gruppe entfernen?', other: 'Alle ${count} ausgewählten Mitglieder aus dieser Gruppe entfernen?')}";

  static String m42(name) => "${name} hat Zugriff auf diese Gruppe angefragt.";

  static String m43(scope) => "Geltungsbereich: ${scope}";

  static String m44(count) =>
      "${Intl.plural(count, one: '1 ausgewählt', other: '${count} ausgewählt')}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Mitglied aus der Gruppe entfernt.', other: '${count} Mitglieder aus der Gruppe entfernt.')}";

  static String m46(admin, manager, user) =>
      "Unterstützte Rollen: ${admin}, ${manager}, ${user}.";

  static String m47(groupName) =>
      "Gib „${groupName}“ ein, um das Löschen zu bestätigen. Dies kann nicht rückgängig gemacht werden.";

  static String m48(error) => "Unerwarteter Fehler: ${error}";

  static String m49(minimumLength) =>
      "Der Benutzername muss mindestens ${minimumLength} Zeichen lang sein.";

  static String m50(date) => "Gültig bis";

  static String m51(email) =>
      "Eine Bestätigungs-E-Mail wurde an ${email} gesendet";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aUser": MessageLookupByLibrary.simpleMessage("Ein Nutzer"),
    "about": MessageLookupByLibrary.simpleMessage("Über"),
    "aboutThisApp": MessageLookupByLibrary.simpleMessage("Über diese App"),
    "accentPallette": MessageLookupByLibrary.simpleMessage("Akzentpalette"),
    "accept": MessageLookupByLibrary.simpleMessage("Annehmen"),
    "acceptCommunityRulesBeforeContinuing": MessageLookupByLibrary.simpleMessage(
      "Bitte akzeptiere die Community-Regeln und Nutzungsbedingungen, bevor du fortfährst.",
    ),
    "acceptInvite": MessageLookupByLibrary.simpleMessage("Einladung annehmen"),
    "acceptedCsvFormat": MessageLookupByLibrary.simpleMessage(
      "CSV oder TSV, mit einer Person pro Zeile:",
    ),
    "accessModeLabel": m0,
    "accessRequestSent": MessageLookupByLibrary.simpleMessage(
      "Zugriffsanfrage gesendet.",
    ),
    "accountAndSecurity": MessageLookupByLibrary.simpleMessage(
      "Konto & Sicherheit",
    ),
    "accountDataExportFailed": MessageLookupByLibrary.simpleMessage(
      "Kontodaten konnten nicht exportiert werden.",
    ),
    "accountDataExportSuccess": MessageLookupByLibrary.simpleMessage(
      "Kontodaten-Export erstellt.",
    ),
    "actionNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "Diese Aktion ist nicht mehr verfügbar.",
    ),
    "active": MessageLookupByLibrary.simpleMessage("Aktiv"),
    "activeMembersCount": m1,
    "activityAndContent": MessageLookupByLibrary.simpleMessage(
      "Aktivität & Inhalte",
    ),
    "activityHistory": MessageLookupByLibrary.simpleMessage(
      "Aktivitätsverlauf",
    ),
    "addComment": MessageLookupByLibrary.simpleMessage(
      "Einen Kommentar hinzufügen",
    ),
    "addDomain": MessageLookupByLibrary.simpleMessage("Domain hinzufügen"),
    "addEmailSignIn": MessageLookupByLibrary.simpleMessage(
      "E-Mail-Anmeldung hinzufügen",
    ),
    "addEmailSignInDescription": m2,
    "addImage": MessageLookupByLibrary.simpleMessage("Bild hinzufügen"),
    "addMember": MessageLookupByLibrary.simpleMessage("Mitglied hinzufügen"),
    "addOption": MessageLookupByLibrary.simpleMessage("Option hinzufügen"),
    "addQuestion": MessageLookupByLibrary.simpleMessage("Frage hinzufügen"),
    "additionalDetailsOptional": MessageLookupByLibrary.simpleMessage(
      "Zusätzliche Details (optional)",
    ),
    "additionalGroupsRequirePro": MessageLookupByLibrary.simpleMessage(
      "Mehrere Gruppen zu erstellen ist eine Pro-Funktion. Wechsle zu Pro, um eine weitere Gruppe zu erstellen.",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Anschrift"),
    "addressUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Anschrift erfolgreich aktualisiert",
    ),
    "adminDashboard": MessageLookupByLibrary.simpleMessage("Admin-Dashboard"),
    "adminElectionDashboardDescription": MessageLookupByLibrary.simpleMessage(
      "Der bisherige Besitzer hat die Gruppe verlassen. Wählt, wer sie als Nächstes leiten soll.",
    ),
    "adminElectionDeadline": m3,
    "adminElectionDescription": MessageLookupByLibrary.simpleMessage(
      "Jedes Mitglied hat eine Stimme für den nächsten Gruppen-Admin. Du kannst deine Stimme bis zum Ende der Wahl ändern.",
    ),
    "adminElectionTitle": MessageLookupByLibrary.simpleMessage("Admin-Wahl"),
    "adminElectionVoteCanChange": MessageLookupByLibrary.simpleMessage(
      "Du kannst deine Stimme bis zum Ablauf der drei Tage ändern.",
    ),
    "adminElectionVoteSaved": MessageLookupByLibrary.simpleMessage(
      "Deine Stimme wurde gespeichert.",
    ),
    "adminElectionVotingClosed": MessageLookupByLibrary.simpleMessage(
      "Die Wahl ist beendet. Das Ergebnis wird in Kürze übernommen.",
    ),
    "adminInterface": MessageLookupByLibrary.simpleMessage("Admin-Oberfläche"),
    "adminRoleLabel": MessageLookupByLibrary.simpleMessage("Admin"),
    "alert": MessageLookupByLibrary.simpleMessage("Warnung"),
    "allGroups": MessageLookupByLibrary.simpleMessage("Alle Gruppen"),
    "allow": MessageLookupByLibrary.simpleMessage("Erlauben"),
    "allowAll": MessageLookupByLibrary.simpleMessage("Alle erlauben"),
    "allowedMailDomains": MessageLookupByLibrary.simpleMessage(
      "Erlaubte Mail-Domains",
    ),
    "allowedMailDomainsDescription": MessageLookupByLibrary.simpleMessage(
      "Nützlich für Firmen: Jeder mit passender E-Mail-Domain kann mit der gewählten Standardrolle vorbereitet werden.",
    ),
    "alreadyMemberOfGroup": MessageLookupByLibrary.simpleMessage(
      "Du bist bereits Mitglied dieser Gruppe.",
    ),
    "alreadyParticipated": MessageLookupByLibrary.simpleMessage(
      "Bereits teilgenommen",
    ),
    "anUnexpectedErrorOccurred": MessageLookupByLibrary.simpleMessage(
      "Ein unerwarteter Fehler ist aufgetreten.",
    ),
    "analyticsData": MessageLookupByLibrary.simpleMessage("Analysedaten"),
    "analyticsDataDescription": MessageLookupByLibrary.simpleMessage(
      "Erlaube anonyme Nutzungsanalysen, damit wir die App-Nutzung verstehen und Funktionen im Laufe der Zeit verbessern können.",
    ),
    "anonymous": MessageLookupByLibrary.simpleMessage("Anonym"),
    "answerAllSurveyQuestions": MessageLookupByLibrary.simpleMessage(
      "Bitte beantworte alle Fragen im Fragebogen.",
    ),
    "appleAccount": MessageLookupByLibrary.simpleMessage("Apple-Konto"),
    "appleSignInFailed": MessageLookupByLibrary.simpleMessage(
      "Die Apple-Anmeldung ist fehlgeschlagen. Bitte versuche es erneut.",
    ),
    "approveRequest": MessageLookupByLibrary.simpleMessage(
      "Anfrage genehmigen",
    ),
    "areYouSureYouWantToCancelYourProSubscription":
        MessageLookupByLibrary.simpleMessage(
          "Möchtest du dein Pro-Abo wirklich kündigen?",
        ),
    "areYouSureYouWantToClearThisDraft": MessageLookupByLibrary.simpleMessage(
      "Möchtest du diesen Entwurf wirklich löschen?",
    ),
    "areYouSureYouWantToDeleteThisForm": MessageLookupByLibrary.simpleMessage(
      "Möchtest du dieses Formular wirklich löschen?",
    ),
    "areYouSureYouWantToDeleteThisPetition":
        MessageLookupByLibrary.simpleMessage(
          "Möchtest du diese Petition wirklich löschen?",
        ),
    "areYouSureYouWantToDeleteThisPoll": MessageLookupByLibrary.simpleMessage(
      "Möchtest du diese Umfrage wirklich löschen?",
    ),
    "areYouSureYouWantToDeleteThisUser": MessageLookupByLibrary.simpleMessage(
      "Möchtest du diesen Nutzer wirklich löschen?",
    ),
    "areYouSureYouWantToDeleteYourAccount":
        MessageLookupByLibrary.simpleMessage(
          "Möchtest du dein Konto wirklich löschen?",
        ),
    "areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible":
        MessageLookupByLibrary.simpleMessage(
          "Möchtest du dein Konto wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.",
        ),
    "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
      "Möchtest du dich wirklich abmelden?",
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
    "cannotDeleteSurveyHasResponses": MessageLookupByLibrary.simpleMessage(
      "Kann nicht gelöscht werden: Fragebogen hat Antworten.",
    ),
    "cannotRemoveGroupOwner": MessageLookupByLibrary.simpleMessage(
      "Die Gruppenleitung kann nicht entfernt werden.",
    ),
    "castAdminElectionVote": MessageLookupByLibrary.simpleMessage(
      "Stimme abgeben",
    ),
    "changeAdminElectionVote": MessageLookupByLibrary.simpleMessage(
      "Stimme ändern",
    ),
    "changeEmail": MessageLookupByLibrary.simpleMessage("E-Mail ändern"),
    "changeEmailCodeSent": MessageLookupByLibrary.simpleMessage(
      "Wir haben einen Bestätigungscode an deine neue E-Mail-Adresse gesendet.",
    ),
    "changeEmailFailed": MessageLookupByLibrary.simpleMessage(
      "E-Mail-Änderung fehlgeschlagen",
    ),
    "changeEmailInstructions": MessageLookupByLibrary.simpleMessage(
      "Gib deine neue E-Mail-Adresse und dein aktuelles Passwort ein. Wir senden einen Bestätigungscode an die neue Adresse.",
    ),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Sprache ändern"),
    "changePassword": MessageLookupByLibrary.simpleMessage("Passwort ändern"),
    "checkUsernameAvailability": MessageLookupByLibrary.simpleMessage(
      "Verfügbarkeit des Benutzernamens prüfen",
    ),
    "checkingUsernameAvailability": MessageLookupByLibrary.simpleMessage(
      "Verfügbarkeit wird geprüft…",
    ),
    "cityScopeFallback": MessageLookupByLibrary.simpleMessage("Stadt"),
    "clearGroupFilter": MessageLookupByLibrary.simpleMessage(
      "Gruppenfilter löschen",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Schließen"),
    "closeForm": MessageLookupByLibrary.simpleMessage("Formular beenden"),
    "closeFormConfirmation": MessageLookupByLibrary.simpleMessage(
      "Dieses Formular jetzt stoppen? Du kannst es innerhalb der nächsten 24 Stunden unter Abgeschlossene Formulare fortsetzen. Danach wird es endgültig beendet.",
    ),
    "closed": MessageLookupByLibrary.simpleMessage("Beendet"),
    "closureFinalizesAt": m4,
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
    "completeGoogleProfile": MessageLookupByLibrary.simpleMessage(
      "Vervollständige dein Google-Profil",
    ),
    "completelyPrivateAccessMode": MessageLookupByLibrary.simpleMessage(
      "Vollständig privat",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Bestätigen"),
    "confirmAndFinish": MessageLookupByLibrary.simpleMessage(
      "Bestätigen und fertigstellen",
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
    "connect": MessageLookupByLibrary.simpleMessage("Verbinden"),
    "connected": MessageLookupByLibrary.simpleMessage("Verbunden"),
    "consumption": MessageLookupByLibrary.simpleMessage("Verbrauch"),
    "continueNext": MessageLookupByLibrary.simpleMessage("Weiter"),
    "continueText": MessageLookupByLibrary.simpleMessage("Weiter"),
    "continueToApp": MessageLookupByLibrary.simpleMessage("Zur App"),
    "continueWithApple": MessageLookupByLibrary.simpleMessage(
      "Mit Apple fortfahren",
    ),
    "continueWithGoogle": MessageLookupByLibrary.simpleMessage(
      "Mit Google fortfahren",
    ),
    "copyInviteLinkDescription": MessageLookupByLibrary.simpleMessage(
      "Teile den Einladungslink der Gruppe.",
    ),
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
    "couldNotSaveYourAcceptance": m5,
    "countryScopeFallback": MessageLookupByLibrary.simpleMessage("Land"),
    "countryUnionScopeOnlyForMembers": MessageLookupByLibrary.simpleMessage(
      "Der Länderbund-Geltungsbereich ist nur für Mitgliedsländer verfügbar",
    ),
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
    "createNewSurveyDescription": MessageLookupByLibrary.simpleMessage(
      "Erstelle einen neuen Fragebogen",
    ),
    "createOrManageGroups": MessageLookupByLibrary.simpleMessage(
      "Erstelle oder verwalte Gruppen",
    ),
    "createPetition": MessageLookupByLibrary.simpleMessage(
      "Petition erstellen",
    ),
    "createPoll": MessageLookupByLibrary.simpleMessage("Umfrage erstellen"),
    "createSurvey": MessageLookupByLibrary.simpleMessage(
      "Fragebogen erstellen",
    ),
    "createdPetition": MessageLookupByLibrary.simpleMessage(
      "Petition erstellt",
    ),
    "createdPoll": MessageLookupByLibrary.simpleMessage("Umfrage erstellt"),
    "createdSurvey": MessageLookupByLibrary.simpleMessage(
      "Fragebogen erstellt",
    ),
    "creatingGroup": MessageLookupByLibrary.simpleMessage(
      "Gruppe wird erstellt …",
    ),
    "creator": MessageLookupByLibrary.simpleMessage("Ersteller"),
    "csvColumnFormat": MessageLookupByLibrary.simpleMessage(
      "<E-Mail>,<Spitzname>,<Rolle>",
    ),
    "csvMembersHint": MessageLookupByLibrary.simpleMessage(
      "E-Mail;Spitzname;Rolle\nanna@firma.de;Anna;Benutzer",
    ),
    "currentPassword": MessageLookupByLibrary.simpleMessage(
      "Aktuelles Passwort",
    ),
    "customPetitionAndPollPictures": MessageLookupByLibrary.simpleMessage(
      "Eigene Petition- und Umfragebilder",
    ),
    "dailyCreateLimitReached": MessageLookupByLibrary.simpleMessage(
      "Kostenlose Mitglieder können pro Tag eine Petition und eine Umfrage oder einen Fragebogen veröffentlichen. Pro-Mitglieder können unbegrenzt Formulare veröffentlichen.",
    ),
    "dailyCreatePetitionLimitReached": MessageLookupByLibrary.simpleMessage(
      "Kostenlose Mitglieder können pro Tag eine Petition veröffentlichen. Pro-Mitglieder können unbegrenzt Formulare veröffentlichen.",
    ),
    "dailyCreatePollLimitReached": MessageLookupByLibrary.simpleMessage(
      "Kostenlose Mitglieder können pro Tag eine Umfrage oder einen Fragebogen veröffentlichen. Pro-Mitglieder können unbegrenzt Formulare veröffentlichen.",
    ),
    "dailyHabit": MessageLookupByLibrary.simpleMessage("Tägliche Gewohnheit"),
    "dangerZoneTitle": MessageLookupByLibrary.simpleMessage("Gefahrenbereich"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dunkler Modus"),
    "databaseError": m6,
    "dateOfBirth": MessageLookupByLibrary.simpleMessage("Geburtsdatum"),
    "daysLeft": MessageLookupByLibrary.simpleMessage("Verbleibende Tage"),
    "decline": MessageLookupByLibrary.simpleMessage("Ablehnen"),
    "delete": MessageLookupByLibrary.simpleMessage("Löschen"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Konto löschen"),
    "deleteAccountButton": MessageLookupByLibrary.simpleMessage(
      "KONTO ENDGÜLTIG LÖSCHEN",
    ),
    "deleteAccountDescription": MessageLookupByLibrary.simpleMessage(
      "Bitte melde dich an, um deine Identität zu bestätigen. Diese Aktion löscht dein Konto und alle zugehörigen Daten unwiderruflich.",
    ),
    "deleteAccountSuccess": MessageLookupByLibrary.simpleMessage(
      "Konto erfolgreich gelöscht.",
    ),
    "deleteAccountTitle": MessageLookupByLibrary.simpleMessage("Konto löschen"),
    "deleteAccountUnexpectedError": MessageLookupByLibrary.simpleMessage(
      "Ein unerwarteter Fehler ist aufgetreten.",
    ),
    "deleteAccountUserNotFound": MessageLookupByLibrary.simpleMessage(
      "Kein Nutzer mit dieser E-Mail-Adresse gefunden.",
    ),
    "deleteAccountWrongPassword": MessageLookupByLibrary.simpleMessage(
      "Falsches Passwort.",
    ),
    "deleteForm": MessageLookupByLibrary.simpleMessage("Formular löschen"),
    "deleteGroup": MessageLookupByLibrary.simpleMessage("Gruppe löschen"),
    "deleteGroupDescription": MessageLookupByLibrary.simpleMessage(
      "Lösche diese Gruppe und ihre Mitgliedsdaten dauerhaft.",
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
    "deny": MessageLookupByLibrary.simpleMessage("Ablehnen"),
    "denyInvite": MessageLookupByLibrary.simpleMessage("Einladung ablehnen"),
    "denyRequest": MessageLookupByLibrary.simpleMessage("Anfrage ablehnen"),
    "description": MessageLookupByLibrary.simpleMessage("Beschreibung"),
    "descriptionRequired": MessageLookupByLibrary.simpleMessage(
      "Beschreibung ist erforderlich",
    ),
    "design": MessageLookupByLibrary.simpleMessage("Design"),
    "detectedStateLabel": m7,
    "devContactInformation": MessageLookupByLibrary.simpleMessage(
      "Diese App wurde von Trainvent entwickelt",
    ),
    "developerSandbox": MessageLookupByLibrary.simpleMessage(
      "Entwickler-Sandbox",
    ),
    "displayName": MessageLookupByLibrary.simpleMessage("Angezeigter Name"),
    "displayQrCode": MessageLookupByLibrary.simpleMessage("QR-Code anzeigen"),
    "doYouWantToLeaveGroup": m8,
    "domainHint": MessageLookupByLibrary.simpleMessage("company.com"),
    "domainLabel": MessageLookupByLibrary.simpleMessage("Domain"),
    "dropCsvHere": MessageLookupByLibrary.simpleMessage(
      "Mehrere Mitglieder importieren",
    ),
    "duration": MessageLookupByLibrary.simpleMessage("Laufzeit"),
    "durationDays": m9,
    "editGivenName": MessageLookupByLibrary.simpleMessage(
      "Vornamen bearbeiten",
    ),
    "editGoogleProfile": MessageLookupByLibrary.simpleMessage(
      "Google-Profil öffnen",
    ),
    "editGroupDescription": MessageLookupByLibrary.simpleMessage(
      "Passe Zugriffsregeln und Einstellungen für diese Gruppe an.",
    ),
    "editGroupMemberTitle": MessageLookupByLibrary.simpleMessage(
      "Mitglied bearbeiten",
    ),
    "editGroupTitle": MessageLookupByLibrary.simpleMessage("Gruppe bearbeiten"),
    "editLabel": MessageLookupByLibrary.simpleMessage("Bearbeiten"),
    "editPetition": MessageLookupByLibrary.simpleMessage("Petition bearbeiten"),
    "editSurname": MessageLookupByLibrary.simpleMessage("Nachnamen bearbeiten"),
    "email": MessageLookupByLibrary.simpleMessage("E-Mail"),
    "emailChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "E-Mail erfolgreich geändert",
    ),
    "emailCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "E-Mail in die Zwischenablage kopiert",
    ),
    "emailOrUsername": MessageLookupByLibrary.simpleMessage(
      "E-Mail oder Benutzername",
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
    "enterSomething": MessageLookupByLibrary.simpleMessage("Gib etwas ein"),
    "enterTitle": MessageLookupByLibrary.simpleMessage("Titel eingeben"),
    "enterVerificationCode": MessageLookupByLibrary.simpleMessage(
      "Bestätigungscode eingeben",
    ),
    "enterYourAddress": MessageLookupByLibrary.simpleMessage(
      "Gib deine Wohnanschrift ein",
    ),
    "enterYourEmail": MessageLookupByLibrary.simpleMessage(
      "Gib deine E-Mail-Adresse ein",
    ),
    "enterYourReasonHere": MessageLookupByLibrary.simpleMessage(
      "Gib hier deine Begründung ein …",
    ),
    "entryNotYetImplemented": MessageLookupByLibrary.simpleMessage(
      "Lexikon-Eintrag noch nicht implementiert",
    ),
    "erroneousProfile": MessageLookupByLibrary.simpleMessage(
      "<fehlerhaftes Profil>",
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
    "europeScopeLabel": MessageLookupByLibrary.simpleMessage("Europa"),
    "everyoneCanJoinWithoutApproval": MessageLookupByLibrary.simpleMessage(
      "Jeder kann ohne Genehmigung beitreten.",
    ),
    "exercise": MessageLookupByLibrary.simpleMessage("Übung"),
    "expirationDateOptional": MessageLookupByLibrary.simpleMessage(
      "Ablaufdatum (optional)",
    ),
    "expiredCreations": MessageLookupByLibrary.simpleMessage(
      "Abgeschlossene Formulare",
    ),
    "expiredPetitions": MessageLookupByLibrary.simpleMessage(
      "Abgelaufene Petitionen",
    ),
    "expiredPolls": MessageLookupByLibrary.simpleMessage(
      "Abgelaufene Umfragen",
    ),
    "expiresOn": MessageLookupByLibrary.simpleMessage("Läuft ab am"),
    "expiresOnDate": m10,
    "expiresOnShort": m11,
    "expiryDate": MessageLookupByLibrary.simpleMessage("Ablaufdatum"),
    "explore": MessageLookupByLibrary.simpleMessage("Entdecken"),
    "exportAccountData": MessageLookupByLibrary.simpleMessage(
      "Kontodaten exportieren",
    ),
    "exportAccountDataDescription": MessageLookupByLibrary.simpleMessage(
      "Profil, Veröffentlichungen, Gruppen und deine eigenen Teilnahmedaten als JSON.",
    ),
    "exportCsv": MessageLookupByLibrary.simpleMessage("CSV exportieren"),
    "exportFailed": MessageLookupByLibrary.simpleMessage(
      "Export fehlgeschlagen",
    ),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export erstellt"),
    "failedToCreatePoll": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Erstellen der Umfrage",
    ),
    "failedToCreateSurvey": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Erstellen des Fragebogens",
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
    "filterBy": MessageLookupByLibrary.simpleMessage("Filtern nach"),
    "filterByGroup": MessageLookupByLibrary.simpleMessage(
      "Filtern nach Gruppe",
    ),
    "finalNotice": MessageLookupByLibrary.simpleMessage("Letzter Hinweis"),
    "finishedForms": MessageLookupByLibrary.simpleMessage(
      "Abgeschlossene Formulare",
    ),
    "flutterPro": MessageLookupByLibrary.simpleMessage("Flutter Pro"),
    "flutterProEmail": MessageLookupByLibrary.simpleMessage("Flutter@pro.com"),
    "formClosureScheduled": MessageLookupByLibrary.simpleMessage(
      "Formular gestoppt. Du kannst es 24 Stunden lang fortsetzen.",
    ),
    "formResumed": MessageLookupByLibrary.simpleMessage(
      "Formular fortgesetzt.",
    ),
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
      "Pro-Abo abschließen, um diese Vorteile zu nutzen",
    ),
    "goToGroupOverview": MessageLookupByLibrary.simpleMessage(
      "Zur Gruppenübersicht",
    ),
    "goToWelcome": MessageLookupByLibrary.simpleMessage("Zum Startbildschirm"),
    "goal": MessageLookupByLibrary.simpleMessage("Ziel"),
    "googleAccount": MessageLookupByLibrary.simpleMessage("Google-Konto"),
    "googleAddressImportedBirthdayUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "Anschrift importiert. Google hat kein vollständiges Geburtsdatum bereitgestellt",
        ),
    "googleBirthdayImportedAddressUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "Geburtsdatum importiert. Google hat keine Anschrift bereitgestellt; wähle einen Autofill-Vorschlag aus oder gib sie ein",
        ),
    "googleProfileHasNoBirthdayOrAddress": MessageLookupByLibrary.simpleMessage(
      "Im Google-Profil wurden weder Geburtsdatum noch Anschrift gefunden",
    ),
    "googleProfileImportFailed": MessageLookupByLibrary.simpleMessage(
      "Google-Profildaten konnten nicht importiert werden",
    ),
    "googleProfileImported": MessageLookupByLibrary.simpleMessage(
      "Google-Profildaten wurden importiert",
    ),
    "googleSignInFailed": MessageLookupByLibrary.simpleMessage(
      "Die Google-Anmeldung ist fehlgeschlagen. Bitte versuche es erneut.",
    ),
    "googleSyncAddressMustBePublic": MessageLookupByLibrary.simpleMessage(
      "Die Adresssynchronisierung erfordert eine öffentliche Google-Anschrift.",
    ),
    "googleSyncDisabled": MessageLookupByLibrary.simpleMessage(
      "Google-Synchronisierung deaktiviert",
    ),
    "googleSyncEnabled": MessageLookupByLibrary.simpleMessage(
      "Google-Synchronisierung aktiviert",
    ),
    "googleSyncFailed": MessageLookupByLibrary.simpleMessage(
      "Google-Profil konnte nicht synchronisiert werden",
    ),
    "googleSyncLocksPersonalData": MessageLookupByLibrary.simpleMessage(
      "Synchronisierte Felder können nur bei Google bearbeitet werden.",
    ),
    "googleSyncManagedFields": MessageLookupByLibrary.simpleMessage(
      "Google hält Name, Geburtsdatum und Anschrift aktuell.",
    ),
    "googleSyncRequiresCompleteProfile": MessageLookupByLibrary.simpleMessage(
      "Ergänze zuerst deinen Namen, dein Geburtsdatum und deinen aktuellen Wohnort bei Google.",
    ),
    "googleSyncSucceeded": MessageLookupByLibrary.simpleMessage(
      "Profil synchronisiert",
    ),
    "groupAccess": MessageLookupByLibrary.simpleMessage("Gruppenzugang"),
    "groupAccessAccepted": MessageLookupByLibrary.simpleMessage(
      "Gespeichert. Gruppenzugang akzeptiert.",
    ),
    "groupAccessSummary": m12,
    "groupAccessTitle": MessageLookupByLibrary.simpleMessage("Gruppenzugang"),
    "groupActivityActorFallback": MessageLookupByLibrary.simpleMessage(
      "Ein Gruppenmitglied",
    ),
    "groupActivityAdminElectionCompleted": m13,
    "groupActivityAdminElectionStarted": m14,
    "groupActivityCreated": m15,
    "groupActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Sieh wichtige Änderungen an Mitgliedern, Einstellungen und Veröffentlichungen.",
    ),
    "groupActivityInvitationsSent": m16,
    "groupActivityLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Die Gruppenaktivitäten konnten nicht geladen werden.",
    ),
    "groupActivityMemberJoined": m17,
    "groupActivityMemberLeft": m18,
    "groupActivityMemberRemoved": m19,
    "groupActivityOwnershipTransferred": m20,
    "groupActivityPublicationPublished": m21,
    "groupActivitySettingsUpdated": m22,
    "groupActivitySubjectFallback": MessageLookupByLibrary.simpleMessage(
      "ein anderes Mitglied",
    ),
    "groupActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Gruppenaktivität",
    ),
    "groupActivityUpdated": MessageLookupByLibrary.simpleMessage(
      "Die Gruppe wurde aktualisiert.",
    ),
    "groupAdminFallback": MessageLookupByLibrary.simpleMessage("Gruppenadmin"),
    "groupContentTitle": MessageLookupByLibrary.simpleMessage("Gruppeninhalte"),
    "groupCreated": MessageLookupByLibrary.simpleMessage("Gruppe erstellt."),
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
    "groupInvitationsDescription": MessageLookupByLibrary.simpleMessage(
      "Sieh, ob registrierte App-Nutzer zugesagt, abgelehnt oder noch nicht geantwortet haben.",
    ),
    "groupInvitationsTitle": MessageLookupByLibrary.simpleMessage(
      "Einladungsstatus",
    ),
    "groupLabelWithValue": m23,
    "groupManagementTitle": MessageLookupByLibrary.simpleMessage(
      "Gruppe verwalten",
    ),
    "groupMemberRemoved": MessageLookupByLibrary.simpleMessage(
      "Mitglied aus der Gruppe entfernt.",
    ),
    "groupMemberUpdated": MessageLookupByLibrary.simpleMessage(
      "Mitglied aktualisiert.",
    ),
    "groupNameDidNotMatch": MessageLookupByLibrary.simpleMessage(
      "Der Gruppenname stimmt nicht überein.",
    ),
    "groupNameLabel": MessageLookupByLibrary.simpleMessage("Gruppenname"),
    "groupOnly": MessageLookupByLibrary.simpleMessage("Nur Gruppe"),
    "groupOnlyUnavailable": MessageLookupByLibrary.simpleMessage(
      "Dieses Formular ist nur für Mitglieder der Gruppe sichtbar.",
    ),
    "groupOwnerMustRemainAdmin": MessageLookupByLibrary.simpleMessage(
      "Die Gruppenleitung muss Administrator bleiben.",
    ),
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
    "helloAndWelcome": m24,
    "hintTextTags": MessageLookupByLibrary.simpleMessage(
      "Z. B. Umwelt, Verkehr",
    ),
    "idNumber": MessageLookupByLibrary.simpleMessage("Ausweisnummer"),
    "idScan": MessageLookupByLibrary.simpleMessage("Ausweisscan"),
    "imagePreviewDescription": MessageLookupByLibrary.simpleMessage(
      "Bildvorschau",
    ),
    "importBirthdayAndAddressFromGoogle": MessageLookupByLibrary.simpleMessage(
      "Geburtsdatum und Anschrift von Google importieren",
    ),
    "importCsvFileLabel": MessageLookupByLibrary.simpleMessage(
      "CSV-Datei importieren",
    ),
    "importLabel": MessageLookupByLibrary.simpleMessage("Importieren"),
    "importedCsvRows": m25,
    "importedMembersCount": m26,
    "importedRowsSkippedMalformed": m27,
    "importingFromGoogle": MessageLookupByLibrary.simpleMessage(
      "Wird von Google importiert…",
    ),
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
    "invitationStatusAccepted": MessageLookupByLibrary.simpleMessage(
      "Angenommen",
    ),
    "invitationStatusDeclined": MessageLookupByLibrary.simpleMessage(
      "Abgelehnt",
    ),
    "invitationStatusPending": MessageLookupByLibrary.simpleMessage("Offen"),
    "invitationStatusRemoved": MessageLookupByLibrary.simpleMessage("Entfernt"),
    "inviteDenied": MessageLookupByLibrary.simpleMessage(
      "Einladung abgelehnt.",
    ),
    "inviteLinkOnLabel": MessageLookupByLibrary.simpleMessage(
      "Einladungslink an",
    ),
    "inviteMembersDescription": MessageLookupByLibrary.simpleMessage(
      "Füge Personen einzeln hinzu oder importiere unten CSV-Zeilen.",
    ),
    "inviteMembersPageDescription": MessageLookupByLibrary.simpleMessage(
      "Lade Personen einzeln ein oder importiere mehrere auf einmal.",
    ),
    "inviteMembersTitle": MessageLookupByLibrary.simpleMessage(
      "Mitglieder einladen",
    ),
    "invitedYouToThisGroup": m28,
    "isProMember": MessageLookupByLibrary.simpleMessage("Ist Pro-Mitglied"),
    "joinCodeWithValue": m29,
    "joinGroup": MessageLookupByLibrary.simpleMessage("Gruppe beitreten"),
    "keepSelected": MessageLookupByLibrary.simpleMessage("Auswahl behalten"),
    "language": MessageLookupByLibrary.simpleMessage("Sprache"),
    "lastImportSummary": m30,
    "lastStep": MessageLookupByLibrary.simpleMessage("Letzter Schritt!"),
    "leaveGroup": MessageLookupByLibrary.simpleMessage("Gruppe verlassen"),
    "licenses": MessageLookupByLibrary.simpleMessage("Lizenzen"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Heller Modus"),
    "limitThisPetitionToYourState": MessageLookupByLibrary.simpleMessage(
      "Diese Petition auf dein Bundesland beschränken?",
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
      "Login-Code gesendet",
    ),
    "loginLegalNoticeAnd": MessageLookupByLibrary.simpleMessage(
      " und unserer ",
    ),
    "loginLegalNoticePrefix": MessageLookupByLibrary.simpleMessage(
      "Indem du fortfährst, stimmst du unseren ",
    ),
    "loginLegalNoticePrivacy": MessageLookupByLibrary.simpleMessage(
      "Datenschutzerklärung",
    ),
    "loginLegalNoticeSuffix": MessageLookupByLibrary.simpleMessage(" zu."),
    "loginLegalNoticeTerms": MessageLookupByLibrary.simpleMessage(
      "Nutzungsbedingungen",
    ),
    "loginLinkSent": MessageLookupByLibrary.simpleMessage("Code gesendet!"),
    "logout": MessageLookupByLibrary.simpleMessage("Abmelden"),
    "manageGroupMembersDescription": MessageLookupByLibrary.simpleMessage(
      "Tippe auf ein Mitglied, um es zu bearbeiten. Halte es gedrückt, um ein oder mehrere Mitglieder zum Entfernen auszuwählen.",
    ),
    "manageGroupMembersTitle": MessageLookupByLibrary.simpleMessage(
      "Mitglieder verwalten",
    ),
    "manageGroupsTitle": MessageLookupByLibrary.simpleMessage(
      "Gruppen verwalten",
    ),
    "managerRoleLabel": MessageLookupByLibrary.simpleMessage("Manager"),
    "managersCanPrepareAccessLists": MessageLookupByLibrary.simpleMessage(
      "Manager können Zugangslisten vorbereiten",
    ),
    "maximumPollOptionsAllowed": m31,
    "maximumSurveyQuestionsAllowed": m32,
    "memberInvitationsSent": m33,
    "memberRoleLabel": MessageLookupByLibrary.simpleMessage("Mitglied"),
    "membersCanChooseTheirOwnNickname": MessageLookupByLibrary.simpleMessage(
      "Mitglieder können ihren Spitznamen selbst wählen",
    ),
    "membershipStatus": MessageLookupByLibrary.simpleMessage(
      "Mitgliedschaftsstatus",
    ),
    "minimumCharacterCount": m34,
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
    "newEmail": MessageLookupByLibrary.simpleMessage("Neue E-Mail"),
    "newMessages": m35,
    "newPassword": MessageLookupByLibrary.simpleMessage("Neues Passwort"),
    "newUser": MessageLookupByLibrary.simpleMessage("Neuer Benutzer"),
    "newUsername": MessageLookupByLibrary.simpleMessage("Neuer Benutzername"),
    "nickname": MessageLookupByLibrary.simpleMessage("Spitzname"),
    "no": MessageLookupByLibrary.simpleMessage("Nein"),
    "noActiveAdminElection": MessageLookupByLibrary.simpleMessage(
      "Es gibt keine aktive Admin-Wahl.",
    ),
    "noActivityFound": MessageLookupByLibrary.simpleMessage(
      "Noch keine Aktivität gefunden.",
    ),
    "noAdminElectionCandidates": MessageLookupByLibrary.simpleMessage(
      "Es gibt keine wählbaren Kandidaten.",
    ),
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
    "noGroupActivity": MessageLookupByLibrary.simpleMessage(
      "Bisher wurden keine Gruppenaktivitäten aufgezeichnet.",
    ),
    "noGroupInvitations": MessageLookupByLibrary.simpleMessage(
      "Es wurde noch kein registrierter App-Nutzer eingeladen.",
    ),
    "noGroupMembers": MessageLookupByLibrary.simpleMessage(
      "Diese Gruppe hat keine Mitglieder.",
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
    "noNewInvitationsSent": MessageLookupByLibrary.simpleMessage(
      "Es wurde keine neue Einladung gesendet. Die Person ist möglicherweise bereits Mitglied oder hat schon eine offene Einladung.",
    ),
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
    "noRunningSurveysFound": MessageLookupByLibrary.simpleMessage(
      "Keine laufenden Fragebögen gefunden.",
    ),
    "noTitle": MessageLookupByLibrary.simpleMessage("Kein Titel"),
    "noUserFoundForThatEmail": MessageLookupByLibrary.simpleMessage(
      "Kein Nutzer mit dieser E-Mail-Adresse gefunden.",
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
    "notConnected": MessageLookupByLibrary.simpleMessage("Nicht verbunden"),
    "notFound": MessageLookupByLibrary.simpleMessage("Nicht gefunden"),
    "notSignedUpYet": MessageLookupByLibrary.simpleMessage(
      "Noch nicht registriert? Passwort vergessen?",
    ),
    "notificationActionInvitedYou": MessageLookupByLibrary.simpleMessage(
      "hat dich eingeladen",
    ),
    "notificationActionRemovedYou": MessageLookupByLibrary.simpleMessage(
      "hat dich aus dieser Gruppe entfernt",
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
    "openGroupDashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "openGroupsCanBeJoinedImmediately": MessageLookupByLibrary.simpleMessage(
      "Offene Gruppen können sofort beigetreten werden.",
    ),
    "openPrivacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Datenschutzerklärung öffnen",
    ),
    "openTermsOfService": MessageLookupByLibrary.simpleMessage(
      "Nutzungsbedingungen öffnen",
    ),
    "openUntilClosed": MessageLookupByLibrary.simpleMessage(
      "Offen, bis es beendet wird",
    ),
    "openUntilClosedDescription": MessageLookupByLibrary.simpleMessage(
      "Dieses Formular bleibt offen, bis du es manuell beendest.",
    ),
    "option": MessageLookupByLibrary.simpleMessage("Option"),
    "optionNumber": m36,
    "optionRequired": MessageLookupByLibrary.simpleMessage(
      "Option ist erforderlich",
    ),
    "options": MessageLookupByLibrary.simpleMessage("Optionen"),
    "orSeparator": MessageLookupByLibrary.simpleMessage(
      "oder direkt weiter mit",
    ),
    "other": MessageLookupByLibrary.simpleMessage("Andere"),
    "outsideYourZone": MessageLookupByLibrary.simpleMessage(
      "Außerhalb deines Bereichs",
    ),
    "ownerRoleLabel": MessageLookupByLibrary.simpleMessage("Leitung"),
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
          "Das Passwort muss mindestens 8 Zeichen lang sein",
        ),
    "passwordValidation": m37,
    "passwordsDoNotMatch": MessageLookupByLibrary.simpleMessage(
      "Passwörter stimmen nicht überein",
    ),
    "pasteCsvLabel": MessageLookupByLibrary.simpleMessage("CSV einfügen"),
    "pasteCsvMembers": MessageLookupByLibrary.simpleMessage(
      "CSV-Mitglieder einfügen",
    ),
    "paywallDescription": MessageLookupByLibrary.simpleMessage(
      "Genieße eine entspanntere und vielfältigere Oberfläche",
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
    "pleaseAddMemberToInvite": MessageLookupByLibrary.simpleMessage(
      "Füge mindestens ein Mitglied zum Einladen hinzu.",
    ),
    "pleaseCheckYourEmail": MessageLookupByLibrary.simpleMessage(
      "Bitte prüfe deine E-Mails",
    ),
    "pleaseCheckYourInbox": MessageLookupByLibrary.simpleMessage(
      "Bitte prüfe deinen Posteingang und klicke auf den Bestätigungslink.",
    ),
    "pleaseEnterADateOfBirth": MessageLookupByLibrary.simpleMessage(
      "Bitte gib ein Geburtsdatum ein",
    ),
    "pleaseEnterAValid6digitCode": MessageLookupByLibrary.simpleMessage(
      "Bitte gib einen gültigen 6-stelligen Code ein",
    ),
    "pleaseEnterGroupName": MessageLookupByLibrary.simpleMessage(
      "Bitte gib einen Gruppennamen ein.",
    ),
    "pleaseEnterValidEmailDomains": MessageLookupByLibrary.simpleMessage(
      "Bitte gib gültige E-Mail-Domains wie company.com ein.",
    ),
    "pleaseEnterValidEmailForEveryInvitedMember":
        MessageLookupByLibrary.simpleMessage(
          "Bitte gib für jedes eingeladene Mitglied eine gültige E-Mail-Adresse ein.",
        ),
    "pleaseEnterValidEmailOrUsernameForEveryInvitedMember":
        MessageLookupByLibrary.simpleMessage(
          "Bitte gib für jedes eingeladene Mitglied eine gültige E-Mail-Adresse oder einen gültigen Benutzernamen ein.",
        ),
    "pleaseEnterYourCredentials": MessageLookupByLibrary.simpleMessage(
      "Bitte gib deine Zugangsdaten ein.",
    ),
    "pleaseEnterYourDesiredCredentials": MessageLookupByLibrary.simpleMessage(
      "Bitte gib deine gewünschten Zugangsdaten ein.",
    ),
    "pleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Bitte gib deine Daten ein.",
    ),
    "pleaseEnterYourEmail": MessageLookupByLibrary.simpleMessage(
      "Bitte gib deine E-Mail-Adresse ein",
    ),
    "pleaseEnterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Bitte gib dein Passwort ein",
    ),
    "pleaseEnterYourSurname": MessageLookupByLibrary.simpleMessage(
      "Bitte gib deinen Nachnamen ein",
    ),
    "pleaseSelectAddressWithTown": MessageLookupByLibrary.simpleMessage(
      "Bitte wähle eine Adresse mit Ort aus",
    ),
    "pleaseSelectState": MessageLookupByLibrary.simpleMessage(
      "Bitte wähle dein Bundesland aus.",
    ),
    "pleaseSetCountryInAddressFirst": MessageLookupByLibrary.simpleMessage(
      "Bitte hinterlege zuerst dein Land in deiner Adresse",
    ),
    "pleaseSetTownInAddressFirst": MessageLookupByLibrary.simpleMessage(
      "Hinterlege einen Ort in deiner Adresse, bevor du „Stadt“ als Geltungsbereich auswählst",
    ),
    "pleaseSignInFirst": MessageLookupByLibrary.simpleMessage(
      "Bitte zuerst anmelden",
    ),
    "pleaseSignInToConfirmYourIdentity": MessageLookupByLibrary.simpleMessage(
      "Bitte melde dich an, um deine Identität zu bestätigen.",
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
      "Lege genau fest, was du erfahren möchtest – konzentriere dich auf eine Idee.",
    ),
    "pollTutorialStep1Title": MessageLookupByLibrary.simpleMessage(
      "1. Formuliere ein klares Ziel",
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
      "Keine Fangfragen und keine emotionale Wortwahl. Dränge niemanden zu einer bestimmten Option. Füge bei Bedarf „Nicht sicher“ hinzu.",
    ),
    "pollTutorialStep4Title": MessageLookupByLibrary.simpleMessage(
      "4. Gib faire Auswahlmöglichkeiten",
    ),
    "pollTutorialStep5Desc": MessageLookupByLibrary.simpleMessage(
      "3–5 Auswahlmöglichkeiten sind perfekt für öffentliche Umfragen.",
    ),
    "pollTutorialStep5Title": MessageLookupByLibrary.simpleMessage(
      "5. Beschränke die Anzahl der Optionen",
    ),
    "pollTutorialStep6Desc": MessageLookupByLibrary.simpleMessage(
      "Die Leute sollten es in unter 10 Sekunden verstehen und abstimmen können.",
    ),
    "pollTutorialStep6Title": MessageLookupByLibrary.simpleMessage(
      "6. Halte die Beantwortung kurz",
    ),
    "pollTutorialStep7Desc": MessageLookupByLibrary.simpleMessage(
      "Die Umfrage sollte neutral, wertungsfrei und unvoreingenommen formuliert sein.",
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
    "privacyAndData": MessageLookupByLibrary.simpleMessage(
      "Datenschutz & Daten",
    ),
    "privacyPolicyEssentialDescription": MessageLookupByLibrary.simpleMessage(
      "Wesentliche Informationen darüber, wie die App personenbezogene Daten verarbeitet.",
    ),
    "privacyPolicyEssentialTitle": MessageLookupByLibrary.simpleMessage(
      "Datenschutzerklärung",
    ),
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
    "profileDetailsUpdated": MessageLookupByLibrary.simpleMessage(
      "Dein Profil wurde aktualisiert.",
    ),
    "profilePictureUpdated": MessageLookupByLibrary.simpleMessage(
      "Profilbild aktualisiert",
    ),
    "profileSaveFailed": MessageLookupByLibrary.simpleMessage(
      "Dein Profil konnte nicht gespeichert werden. Bitte versuche es erneut.",
    ),
    "protectedAccessMode": MessageLookupByLibrary.simpleMessage("Geschützt"),
    "protectedGroupsRequireApprovalRequest": MessageLookupByLibrary.simpleMessage(
      "Geschützte Gruppen benötigen eine Genehmigungsanfrage, bevor du beitreten kannst.",
    ),
    "protectedGroupsRequireInviteLink": MessageLookupByLibrary.simpleMessage(
      "Geschützte Gruppen benötigen einen gültigen Einladungslink und eine Zugriffsanfrage.",
    ),
    "public": MessageLookupByLibrary.simpleMessage("Öffentlich"),
    "publications": MessageLookupByLibrary.simpleMessage("Veröffentlichungen"),
    "publishTo": MessageLookupByLibrary.simpleMessage("Zeigen in"),
    "publishedUnderTheGnuGeneralPublicLicenseV30":
        MessageLookupByLibrary.simpleMessage(
          "Veröffentlicht unter der GNU General Public License v3.0",
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
    "questionNumber": m38,
    "questionRequired": MessageLookupByLibrary.simpleMessage(
      "Frage ist erforderlich",
    ),
    "questions": MessageLookupByLibrary.simpleMessage("Fragen"),
    "reasonYourSignature": MessageLookupByLibrary.simpleMessage(
      "Begründe deine Unterschrift",
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
    "relatedToState": m39,
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
    "removeGroupMemberConfirmation": m40,
    "removeGroupMemberTitle": MessageLookupByLibrary.simpleMessage(
      "Mitglied entfernen?",
    ),
    "removeMemberTooltip": MessageLookupByLibrary.simpleMessage(
      "Mitglied entfernen",
    ),
    "removeSelectedGroupMembersConfirmation": m41,
    "removeSelectedGroupMembersTitle": MessageLookupByLibrary.simpleMessage(
      "Ausgewählte Mitglieder entfernen?",
    ),
    "reportContent": MessageLookupByLibrary.simpleMessage("Inhalt melden"),
    "reportSubmittedReview24Hours": MessageLookupByLibrary.simpleMessage(
      "Meldung eingereicht. Wir prüfen Meldungen innerhalb von 24 Stunden.",
    ),
    "requestAccess": MessageLookupByLibrary.simpleMessage("Zugang anfragen"),
    "requestLoginCode": MessageLookupByLibrary.simpleMessage(
      "Login-Code anfordern",
    ),
    "requestedAccessToThisGroup": m42,
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
    "resumeForm": MessageLookupByLibrary.simpleMessage("Formular fortsetzen"),
    "roleLabel": MessageLookupByLibrary.simpleMessage("Rolle"),
    "runningForms": MessageLookupByLibrary.simpleMessage("Laufende Formulare"),
    "save": MessageLookupByLibrary.simpleMessage("Speichern"),
    "saveGroupLabel": MessageLookupByLibrary.simpleMessage("Gruppe speichern"),
    "saveSelection": MessageLookupByLibrary.simpleMessage("Auswahl speichern"),
    "saving": MessageLookupByLibrary.simpleMessage("Wird gespeichert …"),
    "savingGroup": MessageLookupByLibrary.simpleMessage(
      "Gruppe wird gespeichert …",
    ),
    "scanAgain": MessageLookupByLibrary.simpleMessage("Erneut scannen"),
    "scanGroupQrCode": MessageLookupByLibrary.simpleMessage(
      "QR-Code für Gruppe scannen",
    ),
    "scanQrCode": MessageLookupByLibrary.simpleMessage("QR-Code scannen"),
    "scanQrCodeTooltip": MessageLookupByLibrary.simpleMessage(
      "QR-Code scannen",
    ),
    "scanYourId": MessageLookupByLibrary.simpleMessage(
      "Bitte scanne deinen deutschen Personalausweis",
    ),
    "scannedData": MessageLookupByLibrary.simpleMessage("Gescannte Daten"),
    "scope": MessageLookupByLibrary.simpleMessage("Geltungsbereich"),
    "scopeAndGroup": MessageLookupByLibrary.simpleMessage(
      "Geltungsbereich und Gruppe",
    ),
    "scopeCity": MessageLookupByLibrary.simpleMessage("Stadt"),
    "scopeContinent": MessageLookupByLibrary.simpleMessage("Kontinent"),
    "scopeCountry": MessageLookupByLibrary.simpleMessage("Land"),
    "scopeCountryUnion": MessageLookupByLibrary.simpleMessage("Länderbund"),
    "scopeDetails": MessageLookupByLibrary.simpleMessage(
      "Details zum Geltungsbereich",
    ),
    "scopeEu": MessageLookupByLibrary.simpleMessage("EU"),
    "scopeGlobal": MessageLookupByLibrary.simpleMessage("Global"),
    "scopeLabelWithValue": m43,
    "scopeStateRegion": MessageLookupByLibrary.simpleMessage(
      "Bundesland / Region",
    ),
    "scopeUn": MessageLookupByLibrary.simpleMessage("UN"),
    "searchPoweredByTomTom": MessageLookupByLibrary.simpleMessage(
      "Suche mit TomTom",
    ),
    "searchTextField": MessageLookupByLibrary.simpleMessage("Schlagwort"),
    "select": MessageLookupByLibrary.simpleMessage("Auswählen"),
    "selectCountryUnion": MessageLookupByLibrary.simpleMessage(
      "Länderbund auswählen",
    ),
    "selectFromCamera": MessageLookupByLibrary.simpleMessage(
      "Mit Kamera aufnehmen",
    ),
    "selectFromGallery": MessageLookupByLibrary.simpleMessage(
      "Aus Galerie wählen",
    ),
    "selectPaymentProvider": MessageLookupByLibrary.simpleMessage(
      "Zahlungsanbieter auswählen",
    ),
    "selectedGroupMembersCount": m44,
    "selectedGroupMembersRemoved": m45,
    "sendConfirmationEmail": MessageLookupByLibrary.simpleMessage(
      "Bestätigungs-E-Mail senden",
    ),
    "sendCrashLogs": MessageLookupByLibrary.simpleMessage(
      "Absturzberichte senden",
    ),
    "sendCrashLogsDescription": MessageLookupByLibrary.simpleMessage(
      "Hilf uns, die App zu verbessern, indem du automatisch Absturzberichte sendest.",
    ),
    "sendInvitations": MessageLookupByLibrary.simpleMessage(
      "Einladungen senden",
    ),
    "sendLoginLink": MessageLookupByLibrary.simpleMessage(
      "Login Link abschicken",
    ),
    "sendingInvitations": MessageLookupByLibrary.simpleMessage(
      "Einladungen werden gesendet …",
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
    "shareGroupInvitation": MessageLookupByLibrary.simpleMessage(
      "Einladung teilen",
    ),
    "sharePetition": MessageLookupByLibrary.simpleMessage("Petition teilen"),
    "sharingNotSupported": MessageLookupByLibrary.simpleMessage(
      "Teilen wird auf dieser Plattform nicht unterstützt.",
    ),
    "showSurveys": MessageLookupByLibrary.simpleMessage("Fragebögen anzeigen"),
    "showSurveysInfo": MessageLookupByLibrary.simpleMessage(
      "Wenn dies aktiviert ist, erscheinen Fragebögen zusammen mit normalen Abstimmungen in der Abstimmungsliste. Deaktiviere es, wenn du nur Einzelfrage-Abstimmungen sehen möchtest.",
    ),
    "sign": MessageLookupByLibrary.simpleMessage("Unterzeichnen"),
    "signIn": MessageLookupByLibrary.simpleMessage("Anmelden"),
    "signInMethodAlreadyUsed": MessageLookupByLibrary.simpleMessage(
      "Diese Anmeldemethode ist bereits mit einem anderen Konto verbunden.",
    ),
    "signInMethodConnected": MessageLookupByLibrary.simpleMessage(
      "Anmeldemethode verbunden",
    ),
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
    "signedOn": MessageLookupByLibrary.simpleMessage("Unterzeichnet am "),
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
    "stimmapp": MessageLookupByLibrary.simpleMessage("StimmApp"),
    "submit": MessageLookupByLibrary.simpleMessage("Senden"),
    "submitSurvey": MessageLookupByLibrary.simpleMessage("Fragebogen absenden"),
    "subscriptionCancelledAccessWillRemainUntilExpiry":
        MessageLookupByLibrary.simpleMessage(
          "Abo gekündigt. Zugriff bleibt bis zum Ablauf erhalten.",
        ),
    "successfullyLoggedIn": MessageLookupByLibrary.simpleMessage(
      "Erfolgreich angemeldet",
    ),
    "supportedRoles": m46,
    "supporters": MessageLookupByLibrary.simpleMessage("Unterstützer"),
    "surname": MessageLookupByLibrary.simpleMessage("Nachname"),
    "surveyDeleted": MessageLookupByLibrary.simpleMessage(
      "Fragebogen gelöscht",
    ),
    "surveyDetails": MessageLookupByLibrary.simpleMessage("Fragebogendetails"),
    "surveyQuestion": MessageLookupByLibrary.simpleMessage(
      "Frage im Fragebogen",
    ),
    "surveySubmitted": MessageLookupByLibrary.simpleMessage(
      "Fragebogen abgesendet",
    ),
    "surveys": MessageLookupByLibrary.simpleMessage("Fragebögen"),
    "swipeForDelete": MessageLookupByLibrary.simpleMessage(
      "Wische zum Löschen.",
    ),
    "swipeForGroupActions": MessageLookupByLibrary.simpleMessage(
      "Wische für Dashboard oder Entfernen.",
    ),
    "swipeToLeaveGroup": MessageLookupByLibrary.simpleMessage(
      "Wische, um die Gruppe zu verlassen.",
    ),
    "syncNow": MessageLookupByLibrary.simpleMessage("Jetzt synchronisieren"),
    "syncRegularly": MessageLookupByLibrary.simpleMessage(
      "Automatisch synchronisieren",
    ),
    "syncedProfileData": MessageLookupByLibrary.simpleMessage(
      "Synchronisierte Profildaten",
    ),
    "synchronization": MessageLookupByLibrary.simpleMessage(
      "Google-Synchronisierung",
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
    "tagsHint": MessageLookupByLibrary.simpleMessage("Kommagetrennte Tags"),
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
      "Der ultimative Weg, deine Meinung zu äußern",
    ),
    "themePaletteAmber": MessageLookupByLibrary.simpleMessage("Amber"),
    "themePaletteForest": MessageLookupByLibrary.simpleMessage("Wald"),
    "themePaletteMint": MessageLookupByLibrary.simpleMessage("Minze"),
    "themePaletteOcean": MessageLookupByLibrary.simpleMessage("Ozean"),
    "themePalettePlum": MessageLookupByLibrary.simpleMessage("Pflaume"),
    "themePaletteRose": MessageLookupByLibrary.simpleMessage("Rose"),
    "themePaletteSky": MessageLookupByLibrary.simpleMessage("Himmel"),
    "themePaletteSlate": MessageLookupByLibrary.simpleMessage("Schiefer"),
    "themePaletteSunset": MessageLookupByLibrary.simpleMessage(
      "Sonnenuntergang",
    ),
    "themePaletteTrainvent": MessageLookupByLibrary.simpleMessage("Trainvent"),
    "thisActionWillPermanentlyDeleteYourAccountAndAllAssociated":
        MessageLookupByLibrary.simpleMessage(
          "Diese Aktion löscht dein Konto und alle zugehörigen Daten dauerhaft.",
        ),
    "thisAppWasDevelopedBy": MessageLookupByLibrary.simpleMessage(
      "Diese App wurde entwickelt von",
    ),
    "title": MessageLookupByLibrary.simpleMessage("Titel"),
    "titleRequired": MessageLookupByLibrary.simpleMessage(
      "Titel ist erforderlich",
    ),
    "town": MessageLookupByLibrary.simpleMessage("Ort"),
    "travel": MessageLookupByLibrary.simpleMessage("Reisen"),
    "typeGroupNameToConfirmDeletion": m47,
    "unblock": MessageLookupByLibrary.simpleMessage("Blockierung aufheben"),
    "unblockedUserSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Nutzer erfolgreich entsperrt.",
    ),
    "undo": MessageLookupByLibrary.simpleMessage("Rückgängig machen"),
    "unexpectedErrorWithDetails": m48,
    "unknownError": MessageLookupByLibrary.simpleMessage("Unbekannter Fehler"),
    "unknownGroupMember": MessageLookupByLibrary.simpleMessage(
      "Unbekanntes Mitglied",
    ),
    "unknownUser": MessageLookupByLibrary.simpleMessage("Unbekannter Nutzer"),
    "untitled": MessageLookupByLibrary.simpleMessage("Ohne Titel"),
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
    "uploadingProfilePicture": MessageLookupByLibrary.simpleMessage(
      "Profilbild wird hochgeladen",
    ),
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
    "usernameAvailabilityCheckFailed": MessageLookupByLibrary.simpleMessage(
      "Die Verfügbarkeit konnte gerade nicht geprüft werden. Tippe, um es erneut zu versuchen.",
    ),
    "usernameAvailable": MessageLookupByLibrary.simpleMessage(
      "Dieser Benutzername ist verfügbar.",
    ),
    "usernameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Änderung des Benutzernamens fehlgeschlagen",
    ),
    "usernameChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Benutzername erfolgreich geändert",
    ),
    "usernameTooShort": m49,
    "usernameUnavailable": MessageLookupByLibrary.simpleMessage(
      "Dieser Benutzername ist bereits vergeben. Probiere einen anderen.",
    ),
    "users": MessageLookupByLibrary.simpleMessage("Benutzer"),
    "validUntil": m50,
    "verificationCodeResent": MessageLookupByLibrary.simpleMessage(
      "Verifizierungscode erneut gesendet!",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Bestätigungs-E-Mail gesendet",
    ),
    "verificationEmailSentTo": m51,
    "verificationFailed": MessageLookupByLibrary.simpleMessage(
      "Verifizierung fehlgeschlagen",
    ),
    "verify": MessageLookupByLibrary.simpleMessage("Verifizieren"),
    "victory": MessageLookupByLibrary.simpleMessage("Sieg!"),
    "viewGroupPolls": MessageLookupByLibrary.simpleMessage(
      "Umfragen und Erhebungen",
    ),
    "viewGroupPollsDescription": MessageLookupByLibrary.simpleMessage(
      "Sieh alles, was für diese Gruppe veröffentlicht wurde.",
    ),
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
    "voteForNewGroupAdmin": MessageLookupByLibrary.simpleMessage(
      "Neuen Gruppen-Admin wählen",
    ),
    "voted": MessageLookupByLibrary.simpleMessage("Abgestimmt"),
    "weCannotProvideSecureVerificationYetButWeAreWorking":
        MessageLookupByLibrary.simpleMessage(
          "Wir können noch keine sichere Verifizierung anbieten, arbeiten aber daran.",
        ),
    "weFailedToGetYourStatePleaseProofreadYourLivingaddress":
        MessageLookupByLibrary.simpleMessage(
          "Wir konnten dein Bundesland nicht ermitteln. Bitte überprüfe deine Wohnadresse.",
        ),
    "weHaveSentA6digitCodeToYourEmailPlease": MessageLookupByLibrary.simpleMessage(
      "Wir haben einen 6-stelligen Code an deine E-Mail-Adresse gesendet. Bitte gib ihn unten ein.",
    ),
    "welcomeBackPleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Willkommen zurück! Bitte gib deine Daten ein.",
    ),
    "welcomePleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Willkommen! Bitte gib deine Daten ein.",
    ),
    "welcomeTo": MessageLookupByLibrary.simpleMessage("Willkommen bei "),
    "welcomeToPro": MessageLookupByLibrary.simpleMessage(
      "Willkommen als Pro-Mitglied!",
    ),
    "whyAreYouSigning": MessageLookupByLibrary.simpleMessage(
      "Warum unterzeichnest du?",
    ),
    "wrongPasswordProvided": MessageLookupByLibrary.simpleMessage(
      "Falsches Passwort eingegeben.",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Ja"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, kündigen"),
    "youAreNotMemberOfAnyGroupsYet": MessageLookupByLibrary.simpleMessage(
      "Du bist noch in keiner Gruppe Mitglied.",
    ),
    "youCannotRemoveYourselfHere": MessageLookupByLibrary.simpleMessage(
      "Du kannst dich auf dieser Seite nicht selbst entfernen.",
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

// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(mode) => "Access mode: ${mode}";

  static String m1(count) => "${count} active members";

  static String m2(deadline) => "Voting ends ${deadline}";

  static String m3(error) => "Could not save your acceptance: ${error}";

  static String m4(code, message) => "Database error (${code}): ${message}";

  static String m5(state) => "Detected state: ${state}";

  static String m6(groupName) => "Do you want to leave \"${groupName}\"?";

  static String m7(date) => "Expires ${date}";

  static String m8(date) => "Expires ${date}";

  static String m9(accessMode, memberCount, expiry) =>
      "Access: ${accessMode} • Members: ${memberCount} • ${expiry}";

  static String m10(group) => "Group: ${group}";

  static String m11(firstName, lastName) => "Welcome ${firstName} ${lastName}!";

  static String m12(count) => "Imported ${count} CSV rows.";

  static String m13(count) => "Imported members: ${count}";

  static String m14(validRows, invalidRows) =>
      "Imported ${validRows} rows. Skipped ${invalidRows} malformed rows.";

  static String m15(name) => "${name} invited you to this group.";

  static String m16(joinCode) => "Join code: ${joinCode}";

  static String m17(validRows, invalidRows) =>
      "Last import: ${validRows} valid rows, ${invalidRows} malformed rows.";

  static String m18(count) => "Maximum ${count} options allowed";

  static String m19(count) => "Maximum ${count} questions allowed";

  static String m20(count) => "Sent ${count} invitations.";

  static String m21(newMessages) =>
      "You have ${Intl.plural(newMessages, zero: 'No new messages', one: 'One new message', two: 'Two new messages', other: '${newMessages} new messages')}";

  static String m22(number) => "Option ${number}";

  static String m23(type) =>
      "Password must contain at least one ${Intl.select(type, {'uppercase': 'uppercase letter', 'lowercase': 'lowercase letter', 'number': 'number', 'special': 'special character', 'other': 'valid character'})}";

  static String m24(number) => "Question ${number}";

  static String m25(state) => "Related to ${state}";

  static String m26(name) => "Remove ${name} from this group?";

  static String m27(name) => "${name} requested access to this group.";

  static String m28(scope) => "Scope: ${scope}";

  static String m29(admin, manager, user) =>
      "Supported roles: ${admin}, ${manager}, ${user}.";

  static String m30(groupName) =>
      "Type \"${groupName}\" to confirm deletion. This cannot be undone.";

  static String m31(error) => "Unexpected error: ${error}";

  static String m32(date) => "Valid until: ${date}";

  static String m33(email) => "A verification email has been sent to ${email}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aUser": MessageLookupByLibrary.simpleMessage("A user"),
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "aboutThisApp": MessageLookupByLibrary.simpleMessage("About this app"),
    "accentPallette": MessageLookupByLibrary.simpleMessage("Accent Palette"),
    "acceptCommunityRulesBeforeContinuing":
        MessageLookupByLibrary.simpleMessage(
          "Please accept the community rules and terms before continuing.",
        ),
    "acceptInvite": MessageLookupByLibrary.simpleMessage("Accept invite"),
    "acceptedCsvFormat": MessageLookupByLibrary.simpleMessage(
      "Accepted format: CSV or TSV with email,nickname,role",
    ),
    "accessModeLabel": m0,
    "accessRequestSent": MessageLookupByLibrary.simpleMessage(
      "Access request sent.",
    ),
    "accountDataExportFailed": MessageLookupByLibrary.simpleMessage(
      "Could not export account data.",
    ),
    "accountDataExportSuccess": MessageLookupByLibrary.simpleMessage(
      "Account data export created.",
    ),
    "actionNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "This action is no longer available.",
    ),
    "active": MessageLookupByLibrary.simpleMessage("Active"),
    "activeMembersCount": m1,
    "activityHistory": MessageLookupByLibrary.simpleMessage("Activity History"),
    "addComment": MessageLookupByLibrary.simpleMessage("Add a comment"),
    "addDomain": MessageLookupByLibrary.simpleMessage("Add domain"),
    "addImage": MessageLookupByLibrary.simpleMessage("Add Image"),
    "addMember": MessageLookupByLibrary.simpleMessage("Add member"),
    "addOption": MessageLookupByLibrary.simpleMessage("Add option"),
    "addQuestion": MessageLookupByLibrary.simpleMessage("Add question"),
    "additionalDetailsOptional": MessageLookupByLibrary.simpleMessage(
      "Additional details (optional)",
    ),
    "additionalGroupsRequirePro": MessageLookupByLibrary.simpleMessage(
      "Creating multiple groups is a Pro feature. Upgrade to Pro to create another group.",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Address updated successfully",
    ),
    "adminDashboard": MessageLookupByLibrary.simpleMessage("Admin Dashboard"),
    "adminElectionDashboardDescription": MessageLookupByLibrary.simpleMessage(
      "The former owner left. Choose who should lead this group next.",
    ),
    "adminElectionDeadline": m2,
    "adminElectionDescription": MessageLookupByLibrary.simpleMessage(
      "Every member has one vote for the group\'s next admin. You can change your vote until voting closes.",
    ),
    "adminElectionTitle": MessageLookupByLibrary.simpleMessage(
      "Admin election",
    ),
    "adminElectionVoteCanChange": MessageLookupByLibrary.simpleMessage(
      "You can change your vote until the three-day deadline.",
    ),
    "adminElectionVoteSaved": MessageLookupByLibrary.simpleMessage(
      "Your vote was saved.",
    ),
    "adminElectionVotingClosed": MessageLookupByLibrary.simpleMessage(
      "Voting is closed. The result will be applied shortly.",
    ),
    "adminInterface": MessageLookupByLibrary.simpleMessage("Admin Interface"),
    "adminRoleLabel": MessageLookupByLibrary.simpleMessage("Admin"),
    "alert": MessageLookupByLibrary.simpleMessage("Alert"),
    "allGroups": MessageLookupByLibrary.simpleMessage("All groups"),
    "allow": MessageLookupByLibrary.simpleMessage("Allow"),
    "allowedMailDomains": MessageLookupByLibrary.simpleMessage(
      "Allowed mail domains",
    ),
    "allowedMailDomainsDescription": MessageLookupByLibrary.simpleMessage(
      "Useful for companies: everyone with a matching email domain can be prepared with the chosen default role.",
    ),
    "alreadyMemberOfGroup": MessageLookupByLibrary.simpleMessage(
      "You are already a member of this group.",
    ),
    "alreadyParticipated": MessageLookupByLibrary.simpleMessage(
      "Already participated",
    ),
    "anUnexpectedErrorOccurred": MessageLookupByLibrary.simpleMessage(
      "An unexpected error occurred.",
    ),
    "analyticsData": MessageLookupByLibrary.simpleMessage("Analytics data"),
    "analyticsDataDescription": MessageLookupByLibrary.simpleMessage(
      "Allow anonymous usage analytics so we can understand app usage and improve features over time.",
    ),
    "anonymous": MessageLookupByLibrary.simpleMessage("Anonymous"),
    "answerAllSurveyQuestions": MessageLookupByLibrary.simpleMessage(
      "Please answer all survey questions.",
    ),
    "approveRequest": MessageLookupByLibrary.simpleMessage("Approve request"),
    "areYouSureYouWantToCancelYourProSubscription":
        MessageLookupByLibrary.simpleMessage(
          "Are you sure you want to cancel your Pro subscription? You will lose Pro features.",
        ),
    "areYouSureYouWantToClearThisDraft": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear this draft?",
    ),
    "areYouSureYouWantToDeleteThisForm": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this form?",
    ),
    "areYouSureYouWantToDeleteThisPetition":
        MessageLookupByLibrary.simpleMessage(
          "Are you sure you want to delete this petition?",
        ),
    "areYouSureYouWantToDeleteThisPoll": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this poll?",
    ),
    "areYouSureYouWantToDeleteThisUser": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this user?",
    ),
    "areYouSureYouWantToDeleteYourAccount":
        MessageLookupByLibrary.simpleMessage(
          "Are you sure you want to delete your account?",
        ),
    "areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible":
        MessageLookupByLibrary.simpleMessage(
          "Are you sure you want to delete your account? This action is irreversible",
        ),
    "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to log out?",
    ),
    "backSide": MessageLookupByLibrary.simpleMessage("Back Side"),
    "backToLogin": MessageLookupByLibrary.simpleMessage("Back to Login"),
    "blockUser": MessageLookupByLibrary.simpleMessage("Block user"),
    "blockUserDescription": MessageLookupByLibrary.simpleMessage(
      "This will hide this user\'s content from your feed immediately and notify the StimmApp team for review.",
    ),
    "blockedContentHidden": MessageLookupByLibrary.simpleMessage(
      "This content is hidden because you blocked this user.",
    ),
    "blockedUsers": MessageLookupByLibrary.simpleMessage("Blocked users"),
    "blockedUsersEmpty": MessageLookupByLibrary.simpleMessage(
      "You have not blocked anyone.",
    ),
    "blockedUsersLoadError": MessageLookupByLibrary.simpleMessage(
      "Failed to load blocked users",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelProSubscription": MessageLookupByLibrary.simpleMessage(
      "Cancel Pro Subscription",
    ),
    "cancelRegistration": MessageLookupByLibrary.simpleMessage(
      "Cancel registration",
    ),
    "cancelSubscription": MessageLookupByLibrary.simpleMessage(
      "Cancel subscription",
    ),
    "cannotDeletePetitionHasSignatures": MessageLookupByLibrary.simpleMessage(
      "Cannot delete: Petition has signatures.",
    ),
    "cannotDeletePollHasVotes": MessageLookupByLibrary.simpleMessage(
      "Cannot delete: Poll has votes.",
    ),
    "cannotDeleteSurveyHasResponses": MessageLookupByLibrary.simpleMessage(
      "Cannot delete: Survey has responses.",
    ),
    "cannotRemoveGroupCreator": MessageLookupByLibrary.simpleMessage(
      "The group creator cannot be removed.",
    ),
    "castAdminElectionVote": MessageLookupByLibrary.simpleMessage("Cast vote"),
    "changeAdminElectionVote": MessageLookupByLibrary.simpleMessage(
      "Change vote",
    ),
    "changeEmail": MessageLookupByLibrary.simpleMessage("Change email"),
    "changeEmailCodeSent": MessageLookupByLibrary.simpleMessage(
      "We sent a verification code to your new email address.",
    ),
    "changeEmailFailed": MessageLookupByLibrary.simpleMessage(
      "Email change failed",
    ),
    "changeEmailInstructions": MessageLookupByLibrary.simpleMessage(
      "Enter your new email address and current password. We will send a verification code to the new address.",
    ),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Change Language"),
    "changePassword": MessageLookupByLibrary.simpleMessage("Change password"),
    "cityScopeFallback": MessageLookupByLibrary.simpleMessage("City"),
    "clearGroupFilter": MessageLookupByLibrary.simpleMessage(
      "Clear group filter",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "closed": MessageLookupByLibrary.simpleMessage("Closed"),
    "colorMode": MessageLookupByLibrary.simpleMessage("Color Mode"),
    "colorTheme": MessageLookupByLibrary.simpleMessage("Color Theme"),
    "comments": MessageLookupByLibrary.simpleMessage("Comments"),
    "communityRules": MessageLookupByLibrary.simpleMessage("Community Rules"),
    "communityRulesAcceptance": MessageLookupByLibrary.simpleMessage(
      "I agree to the Terms of Service and understand that StimmApp does not tolerate objectionable content or abusive behavior.",
    ),
    "communityRulesAgreementNotice": MessageLookupByLibrary.simpleMessage(
      "By continuing, you agree to the Terms of Service and confirm that you will only publish lawful, respectful content. Reported abusive content may be removed and abusive users may be suspended or permanently removed.",
    ),
    "communityRulesZeroTolerance": MessageLookupByLibrary.simpleMessage(
      "StimmApp has zero tolerance for objectionable content, harassment, hate speech, sexual exploitation, or abusive users.",
    ),
    "completelyPrivateAccessMode": MessageLookupByLibrary.simpleMessage(
      "Completely private",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmAndFinish": MessageLookupByLibrary.simpleMessage(
      "Confirm & Finish",
    ),
    "confirmPassword": MessageLookupByLibrary.simpleMessage("Confirm Password"),
    "confirmationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Confirmation Email Sent",
    ),
    "confirmationEmailSentDescription": MessageLookupByLibrary.simpleMessage(
      "We have sent a confirmation email to your email address. Please check your inbox and follow the instructions to complete your registration.",
    ),
    "consumption": MessageLookupByLibrary.simpleMessage("Consumption"),
    "continueNext": MessageLookupByLibrary.simpleMessage("Continue"),
    "continueText": MessageLookupByLibrary.simpleMessage("Continue"),
    "continueToApp": MessageLookupByLibrary.simpleMessage("Continue to app"),
    "continueWithGoogle": MessageLookupByLibrary.simpleMessage(
      "Continue with Google",
    ),
    "copyInviteLinkDescription": MessageLookupByLibrary.simpleMessage(
      "Share the group invitation link.",
    ),
    "copyInviteLinkTooltip": MessageLookupByLibrary.simpleMessage(
      "Copy invite link",
    ),
    "copyLinkLabel": MessageLookupByLibrary.simpleMessage("Copy link"),
    "couldNotOpenLink": MessageLookupByLibrary.simpleMessage(
      "Could not open link.",
    ),
    "couldNotOpenPaywall": MessageLookupByLibrary.simpleMessage(
      "Could not open paywall",
    ),
    "couldNotSaveYourAcceptance": m3,
    "countryScopeFallback": MessageLookupByLibrary.simpleMessage("Country"),
    "createGroupDescription": MessageLookupByLibrary.simpleMessage(
      "Create a members-only polling space for teams, events, and companies.",
    ),
    "createGroupTitle": MessageLookupByLibrary.simpleMessage("Create group"),
    "createGroupTooltip": MessageLookupByLibrary.simpleMessage("Create group"),
    "createNewGroup": MessageLookupByLibrary.simpleMessage("Create new group"),
    "createNewPetitionDescription": MessageLookupByLibrary.simpleMessage(
      "Create a new petition",
    ),
    "createNewPollDescription": MessageLookupByLibrary.simpleMessage(
      "Create a new poll",
    ),
    "createNewSurveyDescription": MessageLookupByLibrary.simpleMessage(
      "Create a new survey",
    ),
    "createOrManageGroups": MessageLookupByLibrary.simpleMessage(
      "Create or manage groups",
    ),
    "createPetition": MessageLookupByLibrary.simpleMessage("Create Petition"),
    "createPoll": MessageLookupByLibrary.simpleMessage("Create Poll"),
    "createSurvey": MessageLookupByLibrary.simpleMessage("Create Survey"),
    "createdPetition": MessageLookupByLibrary.simpleMessage("Petition created"),
    "createdPoll": MessageLookupByLibrary.simpleMessage("Poll created"),
    "createdSurvey": MessageLookupByLibrary.simpleMessage("Survey created"),
    "creatingGroup": MessageLookupByLibrary.simpleMessage("Creating..."),
    "creator": MessageLookupByLibrary.simpleMessage("Creator"),
    "creatorRoleLabel": MessageLookupByLibrary.simpleMessage("Creator"),
    "csvMembersHint": MessageLookupByLibrary.simpleMessage(
      "email,nickname,role\nanna@company.com,Anna,user",
    ),
    "currentPassword": MessageLookupByLibrary.simpleMessage("Current password"),
    "customPetitionAndPollPictures": MessageLookupByLibrary.simpleMessage(
      "Custom petition and poll pictures",
    ),
    "dailyCreateLimitReached": MessageLookupByLibrary.simpleMessage(
      "Free members can publish one petition and one poll per day. Pro members can publish unlimited forms.",
    ),
    "dailyCreatePetitionLimitReached": MessageLookupByLibrary.simpleMessage(
      "Free members can publish one petition per day. Pro members can publish unlimited forms.",
    ),
    "dailyCreatePollLimitReached": MessageLookupByLibrary.simpleMessage(
      "Free members can publish one poll or survey per day. Pro members can publish unlimited forms.",
    ),
    "dailyHabit": MessageLookupByLibrary.simpleMessage("Daily habit"),
    "dangerZoneTitle": MessageLookupByLibrary.simpleMessage("Danger zone"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "databaseError": m4,
    "dateOfBirth": MessageLookupByLibrary.simpleMessage("Date of Birth"),
    "daysLeft": MessageLookupByLibrary.simpleMessage("Days Left"),
    "decline": MessageLookupByLibrary.simpleMessage("Decline"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Delete Account"),
    "deleteAccountButton": MessageLookupByLibrary.simpleMessage(
      "PERMANENTLY DELETE ACCOUNT",
    ),
    "deleteAccountDescription": MessageLookupByLibrary.simpleMessage(
      "Please sign in to confirm your identity. This action will permanently delete your account and all associated data.",
    ),
    "deleteAccountSuccess": MessageLookupByLibrary.simpleMessage(
      "Account deleted successfully.",
    ),
    "deleteAccountTitle": MessageLookupByLibrary.simpleMessage(
      "Delete Your Account",
    ),
    "deleteAccountUnexpectedError": MessageLookupByLibrary.simpleMessage(
      "An unexpected error occurred.",
    ),
    "deleteAccountUserNotFound": MessageLookupByLibrary.simpleMessage(
      "No user found for that email.",
    ),
    "deleteAccountWrongPassword": MessageLookupByLibrary.simpleMessage(
      "Wrong password provided.",
    ),
    "deleteForm": MessageLookupByLibrary.simpleMessage("Delete Form"),
    "deleteGroup": MessageLookupByLibrary.simpleMessage("Delete group"),
    "deleteGroupDescription": MessageLookupByLibrary.simpleMessage(
      "Permanently delete this group and its membership data.",
    ),
    "deleteMyAccount": MessageLookupByLibrary.simpleMessage(
      "Delete my account",
    ),
    "deletePermanently": MessageLookupByLibrary.simpleMessage(
      "Delete Permanently",
    ),
    "deletePetition": MessageLookupByLibrary.simpleMessage("Delete Petition"),
    "deletePoll": MessageLookupByLibrary.simpleMessage("Delete Poll"),
    "deleteUser": MessageLookupByLibrary.simpleMessage("Delete User"),
    "deleted": MessageLookupByLibrary.simpleMessage("Deleted"),
    "denyInvite": MessageLookupByLibrary.simpleMessage("Deny invite"),
    "denyRequest": MessageLookupByLibrary.simpleMessage("Deny request"),
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "descriptionRequired": MessageLookupByLibrary.simpleMessage(
      "Description is required",
    ),
    "descriptionTooShort": MessageLookupByLibrary.simpleMessage(
      "Description is too short",
    ),
    "design": MessageLookupByLibrary.simpleMessage("Design"),
    "detectedStateLabel": m5,
    "devContactInformation": MessageLookupByLibrary.simpleMessage(
      "This app is developed by Trainvent",
    ),
    "developerSandbox": MessageLookupByLibrary.simpleMessage(
      "Developer Sandbox",
    ),
    "displayName": MessageLookupByLibrary.simpleMessage("Displayed Name"),
    "displayQrCode": MessageLookupByLibrary.simpleMessage("Display QR code"),
    "doYouWantToLeaveGroup": m6,
    "domainHint": MessageLookupByLibrary.simpleMessage("company.com"),
    "domainLabel": MessageLookupByLibrary.simpleMessage("Domain"),
    "dropCsvHere": MessageLookupByLibrary.simpleMessage("Drop a CSV here"),
    "editGroupDescription": MessageLookupByLibrary.simpleMessage(
      "Adjust the access rules and settings for this group.",
    ),
    "editGroupTitle": MessageLookupByLibrary.simpleMessage("Edit group"),
    "editLabel": MessageLookupByLibrary.simpleMessage("Edit"),
    "editPetition": MessageLookupByLibrary.simpleMessage("Edit Petition"),
    "eligibleForYou": MessageLookupByLibrary.simpleMessage("Eligible for you"),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "emailChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Email changed successfully",
    ),
    "emailCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Email copied to clipboard",
    ),
    "emailVerification": MessageLookupByLibrary.simpleMessage(
      "Email verification",
    ),
    "emailVerifiedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Email verified successfully!",
    ),
    "energy": MessageLookupByLibrary.simpleMessage("Energy"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "enterCode": MessageLookupByLibrary.simpleMessage("Enter Code"),
    "enterDescription": MessageLookupByLibrary.simpleMessage(
      "Enter description",
    ),
    "enterSomething": MessageLookupByLibrary.simpleMessage("Enter something"),
    "enterTitle": MessageLookupByLibrary.simpleMessage("Enter title"),
    "enterVerificationCode": MessageLookupByLibrary.simpleMessage(
      "Enter Verification Code",
    ),
    "enterYourAddress": MessageLookupByLibrary.simpleMessage(
      "Enter your address",
    ),
    "enterYourEmail": MessageLookupByLibrary.simpleMessage("Enter your email"),
    "enterYourReasonHere": MessageLookupByLibrary.simpleMessage(
      "Enter your reason here...",
    ),
    "entryNotYetImplemented": MessageLookupByLibrary.simpleMessage(
      "Lexicon entry not yet implemented",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Error: "),
    "errorCreatingPetition": MessageLookupByLibrary.simpleMessage(
      "Error creating petition",
    ),
    "errorSendingEmail": MessageLookupByLibrary.simpleMessage(
      "Error sending email",
    ),
    "errorUploadingImage": MessageLookupByLibrary.simpleMessage(
      "Error uploading image",
    ),
    "errors": MessageLookupByLibrary.simpleMessage("Errors"),
    "euScopeOnlyForEuCountries": MessageLookupByLibrary.simpleMessage(
      "EU scope is only available for EU countries",
    ),
    "europeScopeLabel": MessageLookupByLibrary.simpleMessage("Europe"),
    "everyoneCanJoinWithoutApproval": MessageLookupByLibrary.simpleMessage(
      "Everyone can join without approval.",
    ),
    "exercise": MessageLookupByLibrary.simpleMessage("Exercise"),
    "expirationDateOptional": MessageLookupByLibrary.simpleMessage(
      "Expiration date (optional)",
    ),
    "expiredCreations": MessageLookupByLibrary.simpleMessage("Finished Forms"),
    "expiredPetitions": MessageLookupByLibrary.simpleMessage(
      "Expired petitions",
    ),
    "expiredPolls": MessageLookupByLibrary.simpleMessage("Expired polls"),
    "expiresOn": MessageLookupByLibrary.simpleMessage("Expires on"),
    "expiresOnDate": m7,
    "expiresOnShort": m8,
    "expiryDate": MessageLookupByLibrary.simpleMessage("Expiry Date"),
    "explore": MessageLookupByLibrary.simpleMessage("Explore"),
    "exportAccountData": MessageLookupByLibrary.simpleMessage(
      "Export account data",
    ),
    "exportAccountDataDescription": MessageLookupByLibrary.simpleMessage(
      "Profile, publications, groups, and your own participation records as JSON.",
    ),
    "exportCsv": MessageLookupByLibrary.simpleMessage("Export CSV"),
    "exportFailed": MessageLookupByLibrary.simpleMessage("Export failed"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export created"),
    "failedToCreatePoll": MessageLookupByLibrary.simpleMessage(
      "Failed to create poll",
    ),
    "failedToCreateSurvey": MessageLookupByLibrary.simpleMessage(
      "Failed to create survey",
    ),
    "failedToLoadYourGroups": MessageLookupByLibrary.simpleMessage(
      "Failed to load your groups.",
    ),
    "failedToResendCode": MessageLookupByLibrary.simpleMessage(
      "Failed to resend code",
    ),
    "failedToUploadImage": MessageLookupByLibrary.simpleMessage(
      "Failed to upload image: ",
    ),
    "faultyInput": MessageLookupByLibrary.simpleMessage("Faulty input"),
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "filterBy": MessageLookupByLibrary.simpleMessage("Filter by"),
    "filterByGroup": MessageLookupByLibrary.simpleMessage("Filter by group"),
    "finalNotice": MessageLookupByLibrary.simpleMessage("Final notice"),
    "finishedForms": MessageLookupByLibrary.simpleMessage("Finished Forms"),
    "flutterPro": MessageLookupByLibrary.simpleMessage("Flutter Pro"),
    "flutterProEmail": MessageLookupByLibrary.simpleMessage("Flutter@pro.com"),
    "freeMember": MessageLookupByLibrary.simpleMessage("Free Member"),
    "french": MessageLookupByLibrary.simpleMessage("French"),
    "frontSide": MessageLookupByLibrary.simpleMessage("Front Side"),
    "german": MessageLookupByLibrary.simpleMessage("German"),
    "getStarted": MessageLookupByLibrary.simpleMessage("Get started"),
    "githubLinkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "GitHub link copied to clipboard",
    ),
    "givenName": MessageLookupByLibrary.simpleMessage("Given Name"),
    "globalScopeLabel": MessageLookupByLibrary.simpleMessage("Global"),
    "goProToAccessTheseBenefits": MessageLookupByLibrary.simpleMessage(
      "Go pro to access these benefits",
    ),
    "goToGroupOverview": MessageLookupByLibrary.simpleMessage(
      "Go to group overview",
    ),
    "goToWelcome": MessageLookupByLibrary.simpleMessage("Go to Welcome"),
    "goal": MessageLookupByLibrary.simpleMessage("Goal"),
    "googleAddressImportedBirthdayUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "Address imported. Google did not provide a complete birthday",
        ),
    "googleBirthdayImportedAddressUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "Birthday imported. Google did not provide an address; select an autofill suggestion or enter it",
        ),
    "googleProfileHasNoBirthdayOrAddress": MessageLookupByLibrary.simpleMessage(
      "No birthday or address was found in your Google profile",
    ),
    "googleProfileImportFailed": MessageLookupByLibrary.simpleMessage(
      "Google profile details could not be imported",
    ),
    "googleProfileImported": MessageLookupByLibrary.simpleMessage(
      "Google profile details imported",
    ),
    "googleSignInFailed": MessageLookupByLibrary.simpleMessage(
      "Google sign-in failed. Please try again.",
    ),
    "groupAccess": MessageLookupByLibrary.simpleMessage("Group access"),
    "groupAccessAccepted": MessageLookupByLibrary.simpleMessage(
      "Saved. Group access accepted.",
    ),
    "groupAccessSummary": m9,
    "groupAccessTitle": MessageLookupByLibrary.simpleMessage("Group access"),
    "groupAdminFallback": MessageLookupByLibrary.simpleMessage("Group admin"),
    "groupContentTitle": MessageLookupByLibrary.simpleMessage("Group content"),
    "groupCreated": MessageLookupByLibrary.simpleMessage("Group created."),
    "groupDeleted": MessageLookupByLibrary.simpleMessage("Group deleted."),
    "groupDetailsTemporarilyUnavailable": MessageLookupByLibrary.simpleMessage(
      "Group details are temporarily unavailable.",
    ),
    "groupDetailsTemporarilyUnavailableRespond":
        MessageLookupByLibrary.simpleMessage(
          "Group details are temporarily unavailable, but you can still respond to this notification.",
        ),
    "groupFilterEmpty": MessageLookupByLibrary.simpleMessage(
      "No joined or accepted groups available yet.",
    ),
    "groupHasNoActiveInviteLink": MessageLookupByLibrary.simpleMessage(
      "This group has no active invite link.",
    ),
    "groupInvitationsDescription": MessageLookupByLibrary.simpleMessage(
      "See whether registered app users have accepted, declined, or still need to answer.",
    ),
    "groupInvitationsTitle": MessageLookupByLibrary.simpleMessage(
      "Invitation status",
    ),
    "groupLabelWithValue": m10,
    "groupManagementTitle": MessageLookupByLibrary.simpleMessage(
      "Manage group",
    ),
    "groupMemberRemoved": MessageLookupByLibrary.simpleMessage(
      "Member removed from the group.",
    ),
    "groupNameDidNotMatch": MessageLookupByLibrary.simpleMessage(
      "Group name did not match.",
    ),
    "groupNameLabel": MessageLookupByLibrary.simpleMessage("Group name"),
    "groupOnly": MessageLookupByLibrary.simpleMessage("Group-only"),
    "groupOnlyUnavailable": MessageLookupByLibrary.simpleMessage(
      "This form is only visible to members of its group.",
    ),
    "groupUpdated": MessageLookupByLibrary.simpleMessage("Group updated."),
    "groupsLabel": MessageLookupByLibrary.simpleMessage("Groups"),
    "growthStartsWithin": MessageLookupByLibrary.simpleMessage(
      "Growth starts within",
    ),
    "harassmentOrBullying": MessageLookupByLibrary.simpleMessage(
      "Harassment or bullying",
    ),
    "hateSpeech": MessageLookupByLibrary.simpleMessage("Hate speech"),
    "height": MessageLookupByLibrary.simpleMessage("Height"),
    "hello": MessageLookupByLibrary.simpleMessage("Hello"),
    "helloAndWelcome": m11,
    "hintTextTags": MessageLookupByLibrary.simpleMessage(
      "e.g. environment, transport",
    ),
    "idNumber": MessageLookupByLibrary.simpleMessage("ID Number"),
    "idScan": MessageLookupByLibrary.simpleMessage("ID Scan"),
    "imagePreviewDescription": MessageLookupByLibrary.simpleMessage(
      "This is a preview of your new profile picture.",
    ),
    "importBirthdayAndAddressFromGoogle": MessageLookupByLibrary.simpleMessage(
      "Import birthday and address from Google",
    ),
    "importCsvFileLabel": MessageLookupByLibrary.simpleMessage(
      "Import CSV file",
    ),
    "importLabel": MessageLookupByLibrary.simpleMessage("Import"),
    "importedCsvRows": m12,
    "importedMembersCount": m13,
    "importedRowsSkippedMalformed": m14,
    "importingFromGoogle": MessageLookupByLibrary.simpleMessage(
      "Importing from Google…",
    ),
    "inactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "info": MessageLookupByLibrary.simpleMessage("Info"),
    "invalidEmailEntered": MessageLookupByLibrary.simpleMessage(
      "Invalid email entered",
    ),
    "invalidGroupInviteQrCode": MessageLookupByLibrary.simpleMessage(
      "This QR code does not contain a valid group invite.",
    ),
    "invalidProtectedInviteLink": MessageLookupByLibrary.simpleMessage(
      "This invite link is not valid for the protected group.",
    ),
    "invitationStatusAccepted": MessageLookupByLibrary.simpleMessage(
      "Accepted",
    ),
    "invitationStatusDeclined": MessageLookupByLibrary.simpleMessage(
      "Declined",
    ),
    "invitationStatusPending": MessageLookupByLibrary.simpleMessage("Pending"),
    "invitationStatusRemoved": MessageLookupByLibrary.simpleMessage("Removed"),
    "inviteDenied": MessageLookupByLibrary.simpleMessage("Invite denied."),
    "inviteLinkOnLabel": MessageLookupByLibrary.simpleMessage("Invite link on"),
    "inviteMembersDescription": MessageLookupByLibrary.simpleMessage(
      "Add people one by one or import CSV rows below.",
    ),
    "inviteMembersPageDescription": MessageLookupByLibrary.simpleMessage(
      "Invite new people to this group. Successfully submitted entries are cleared from this page.",
    ),
    "inviteMembersTitle": MessageLookupByLibrary.simpleMessage(
      "Invite members",
    ),
    "invitedYouToThisGroup": m15,
    "isProMember": MessageLookupByLibrary.simpleMessage("Is Pro Member"),
    "joinCodeWithValue": m16,
    "joinGroup": MessageLookupByLibrary.simpleMessage("Join group"),
    "keepSelected": MessageLookupByLibrary.simpleMessage("Keep selected"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "lastImportSummary": m17,
    "lastStep": MessageLookupByLibrary.simpleMessage("Last step!"),
    "leaveGroup": MessageLookupByLibrary.simpleMessage("Leave group"),
    "licenses": MessageLookupByLibrary.simpleMessage("Licenses"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Light Mode"),
    "limitThisPetitionToYourState": MessageLookupByLibrary.simpleMessage(
      "Limit this petition to your state?",
    ),
    "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Link copied to clipboard",
    ),
    "linkedinLinkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "LinkedIn link copied to clipboard",
    ),
    "livingAddress": MessageLookupByLibrary.simpleMessage("Living Address"),
    "loggedOutSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Logged out successfully",
    ),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "loginCodeSent": MessageLookupByLibrary.simpleMessage("Login code sent"),
    "loginLegalNoticeAnd": MessageLookupByLibrary.simpleMessage(" and "),
    "loginLegalNoticePrefix": MessageLookupByLibrary.simpleMessage(
      "By continuing, you agree to our ",
    ),
    "loginLegalNoticePrivacy": MessageLookupByLibrary.simpleMessage(
      "Privacy Policy",
    ),
    "loginLegalNoticeSuffix": MessageLookupByLibrary.simpleMessage("."),
    "loginLegalNoticeTerms": MessageLookupByLibrary.simpleMessage(
      "Terms of Service",
    ),
    "loginLinkSent": MessageLookupByLibrary.simpleMessage("Code sent!"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "manageGroupMembersDescription": MessageLookupByLibrary.simpleMessage(
      "View everyone in this group and remove members when needed.",
    ),
    "manageGroupMembersTitle": MessageLookupByLibrary.simpleMessage(
      "Manage members",
    ),
    "manageGroupsTitle": MessageLookupByLibrary.simpleMessage("Manage groups"),
    "managerRoleLabel": MessageLookupByLibrary.simpleMessage("Manager"),
    "managersCanPrepareAccessLists": MessageLookupByLibrary.simpleMessage(
      "Managers can prepare access lists",
    ),
    "maximumPollOptionsAllowed": m18,
    "maximumSurveyQuestionsAllowed": m19,
    "memberInvitationsSent": m20,
    "memberRoleLabel": MessageLookupByLibrary.simpleMessage("Member"),
    "membersCanChooseTheirOwnNickname": MessageLookupByLibrary.simpleMessage(
      "Members can choose their own nickname",
    ),
    "membershipStatus": MessageLookupByLibrary.simpleMessage(
      "Membership Status",
    ),
    "misinformationOrFraud": MessageLookupByLibrary.simpleMessage(
      "Misinformation or fraud",
    ),
    "moreBenefitsToBeAddedLater": MessageLookupByLibrary.simpleMessage(
      "More benefits to be added later",
    ),
    "myGroups": MessageLookupByLibrary.simpleMessage("My groups"),
    "myPetitions": MessageLookupByLibrary.simpleMessage("My Petitions"),
    "myProfile": MessageLookupByLibrary.simpleMessage("My Profile"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Name change failed",
    ),
    "nationality": MessageLookupByLibrary.simpleMessage("Nationality"),
    "newEmail": MessageLookupByLibrary.simpleMessage("New email"),
    "newMessages": m21,
    "newPassword": MessageLookupByLibrary.simpleMessage("New password"),
    "newUser": MessageLookupByLibrary.simpleMessage("New User"),
    "newUsername": MessageLookupByLibrary.simpleMessage("New username"),
    "nickname": MessageLookupByLibrary.simpleMessage("Nickname"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noActiveAdminElection": MessageLookupByLibrary.simpleMessage(
      "There is no active admin election.",
    ),
    "noActivityFound": MessageLookupByLibrary.simpleMessage(
      "No activity found yet.",
    ),
    "noAdminElectionCandidates": MessageLookupByLibrary.simpleMessage(
      "There are no eligible candidates.",
    ),
    "noCsvRowsImported": MessageLookupByLibrary.simpleMessage(
      "No CSV rows were imported.",
    ),
    "noData": MessageLookupByLibrary.simpleMessage("No data"),
    "noDomainRulesYet": MessageLookupByLibrary.simpleMessage(
      "No domain rules yet.",
    ),
    "noEmail": MessageLookupByLibrary.simpleMessage("No Email"),
    "noExpirationDateSet": MessageLookupByLibrary.simpleMessage(
      "No expiration date set.",
    ),
    "noExpiredItems": MessageLookupByLibrary.simpleMessage("No expired items"),
    "noExpiry": MessageLookupByLibrary.simpleMessage("No expiry"),
    "noFittingOptions": MessageLookupByLibrary.simpleMessage(
      "No fitting options",
    ),
    "noGroupInvitations": MessageLookupByLibrary.simpleMessage(
      "No registered app user has been invited yet.",
    ),
    "noGroupMembers": MessageLookupByLibrary.simpleMessage(
      "This group has no members.",
    ),
    "noGroupNotificationsYet": MessageLookupByLibrary.simpleMessage(
      "No group notifications yet.",
    ),
    "noGroupsYetCreateOneAboveToStartTeamPolling":
        MessageLookupByLibrary.simpleMessage(
          "No groups yet. Create one above to start team polling.",
        ),
    "noImageSelected": MessageLookupByLibrary.simpleMessage(
      "No image selected",
    ),
    "noName": MessageLookupByLibrary.simpleMessage("No Name"),
    "noNewInvitationsSent": MessageLookupByLibrary.simpleMessage(
      "No new invitation was sent. The person may already be a member or already have a pending invitation.",
    ),
    "noOptions": MessageLookupByLibrary.simpleMessage("No options"),
    "noProMember": MessageLookupByLibrary.simpleMessage(
      "Nein, kein Pro-Mitglied",
    ),
    "noRunningPetitionsFound": MessageLookupByLibrary.simpleMessage(
      "No running petitions found.",
    ),
    "noRunningPollsFound": MessageLookupByLibrary.simpleMessage(
      "No running polls found.",
    ),
    "noRunningSurveysFound": MessageLookupByLibrary.simpleMessage(
      "No running surveys found.",
    ),
    "noTitle": MessageLookupByLibrary.simpleMessage("No Title"),
    "noUserFoundForThatEmail": MessageLookupByLibrary.simpleMessage(
      "No user found for that email.",
    ),
    "noUsernameFound": MessageLookupByLibrary.simpleMessage(
      "No username found",
    ),
    "notAuthenticated": MessageLookupByLibrary.simpleMessage(
      "Not authenticated",
    ),
    "notAvailableOnWebApp": MessageLookupByLibrary.simpleMessage(
      "Not available on web, use mobile app",
    ),
    "notFound": MessageLookupByLibrary.simpleMessage("Not found"),
    "notSignedUpYet": MessageLookupByLibrary.simpleMessage(
      "Not signed up yet? Forgot password?",
    ),
    "notificationActionInvitedYou": MessageLookupByLibrary.simpleMessage(
      "invited you",
    ),
    "notificationActionRemovedYou": MessageLookupByLibrary.simpleMessage(
      "removed you from this group",
    ),
    "notificationActionRequestedAccess": MessageLookupByLibrary.simpleMessage(
      "requested access",
    ),
    "notificationStatusAccepted": MessageLookupByLibrary.simpleMessage(
      "Accepted",
    ),
    "notificationStatusDenied": MessageLookupByLibrary.simpleMessage("Denied"),
    "notificationStatusPending": MessageLookupByLibrary.simpleMessage(
      "Pending",
    ),
    "notificationsTitle": MessageLookupByLibrary.simpleMessage("Notifications"),
    "onlyPreparedMembersCanParticipate": MessageLookupByLibrary.simpleMessage(
      "Only members prepared by admins or managers can participate.",
    ),
    "openAccessMode": MessageLookupByLibrary.simpleMessage("Open"),
    "openGroupDashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "openGroupsCanBeJoinedImmediately": MessageLookupByLibrary.simpleMessage(
      "Open groups can be joined immediately.",
    ),
    "openPrivacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Open Privacy Policy",
    ),
    "openTermsOfService": MessageLookupByLibrary.simpleMessage(
      "Open Terms of Service",
    ),
    "option": MessageLookupByLibrary.simpleMessage("Option"),
    "optionNumber": m22,
    "optionRequired": MessageLookupByLibrary.simpleMessage(
      "Option is required",
    ),
    "options": MessageLookupByLibrary.simpleMessage("Options"),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "participants": MessageLookupByLibrary.simpleMessage("Participants"),
    "participantsList": MessageLookupByLibrary.simpleMessage(
      "Participants List",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "passwordChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Password change failed",
    ),
    "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Password changed successfully",
    ),
    "passwordMustBeAtLeast8CharactersLong":
        MessageLookupByLibrary.simpleMessage(
          "Password must be at least 8 characters long",
        ),
    "passwordValidation": m23,
    "passwordsDoNotMatch": MessageLookupByLibrary.simpleMessage(
      "Passwords do not match",
    ),
    "pasteCsvLabel": MessageLookupByLibrary.simpleMessage("Paste CSV"),
    "pasteCsvMembers": MessageLookupByLibrary.simpleMessage(
      "Paste CSV members",
    ),
    "paywallDescription": MessageLookupByLibrary.simpleMessage(
      "Enjoy a more relaxed and diverse interface",
    ),
    "paywallSubtitle": MessageLookupByLibrary.simpleMessage(
      "Unlimited access to all functions",
    ),
    "paywallTitle": MessageLookupByLibrary.simpleMessage(
      "Become a premium member",
    ),
    "peopleWithInviteLinkCanRequestAccessToGroup":
        MessageLookupByLibrary.simpleMessage(
          "People with the invite link can request access to the group.",
        ),
    "permanentlyDeleteAccount": MessageLookupByLibrary.simpleMessage(
      "PERMANENTLY DELETE ACCOUNT",
    ),
    "petition": MessageLookupByLibrary.simpleMessage("Petition"),
    "petitionBy": MessageLookupByLibrary.simpleMessage("Petition by"),
    "petitionDeleted": MessageLookupByLibrary.simpleMessage("Petition deleted"),
    "petitionDetails": MessageLookupByLibrary.simpleMessage("Petition details"),
    "petitionGuidelineDescription": MessageLookupByLibrary.simpleMessage(
      "Petition guideline description",
    ),
    "petitionGuidelines": MessageLookupByLibrary.simpleMessage(
      "Petition Guidelines",
    ),
    "petitionSuccessfullySigned": MessageLookupByLibrary.simpleMessage(
      "Petition successfully signed!",
    ),
    "petitionTitleInUseAlready": MessageLookupByLibrary.simpleMessage(
      "Petition title already in use",
    ),
    "petitionTutorialStep1": MessageLookupByLibrary.simpleMessage(
      "The concern must be of general interest.",
    ),
    "petitionTutorialStep2": MessageLookupByLibrary.simpleMessage(
      "It must not contain any personal references.",
    ),
    "petitionTutorialStep3": MessageLookupByLibrary.simpleMessage(
      "The concern and justification must be formulated concisely and in a generally understandable manner.",
    ),
    "petitionTutorialStep4": MessageLookupByLibrary.simpleMessage(
      "Only topics where a factual discussion is expected will be published.",
    ),
    "petitionTutorialStep5": MessageLookupByLibrary.simpleMessage(
      "Upon reaching 30,000 signatures, the petitioner is granted the right to present their request in a public hearing.",
    ),
    "petitions": MessageLookupByLibrary.simpleMessage("Petitions"),
    "pickExistingGroupToUseOrEditOrCreateNewOne":
        MessageLookupByLibrary.simpleMessage(
          "Pick an existing group to use or edit, or create a new one.",
        ),
    "pickExpirationDate": MessageLookupByLibrary.simpleMessage(
      "Pick expiration date",
    ),
    "placeOfBirth": MessageLookupByLibrary.simpleMessage("Place of Birth"),
    "pleaseAddMemberToInvite": MessageLookupByLibrary.simpleMessage(
      "Add at least one member to invite.",
    ),
    "pleaseCheckYourEmail": MessageLookupByLibrary.simpleMessage(
      "Please check your email",
    ),
    "pleaseCheckYourInbox": MessageLookupByLibrary.simpleMessage(
      "Please check your inbox and click the verification link.",
    ),
    "pleaseEnterADateOfBirth": MessageLookupByLibrary.simpleMessage(
      "Please enter a date of birth",
    ),
    "pleaseEnterAValid6digitCode": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid 6-digit code",
    ),
    "pleaseEnterGroupName": MessageLookupByLibrary.simpleMessage(
      "Please enter a group name.",
    ),
    "pleaseEnterTown": MessageLookupByLibrary.simpleMessage(
      "Please enter a town",
    ),
    "pleaseEnterValidEmailDomains": MessageLookupByLibrary.simpleMessage(
      "Please enter valid email domains like company.com.",
    ),
    "pleaseEnterValidEmailForEveryInvitedMember":
        MessageLookupByLibrary.simpleMessage(
          "Please enter a valid email for every invited member.",
        ),
    "pleaseEnterYourCredentials": MessageLookupByLibrary.simpleMessage(
      "Please enter your credentials",
    ),
    "pleaseEnterYourDesiredCredentials": MessageLookupByLibrary.simpleMessage(
      "Please enter the credentials you desire.",
    ),
    "pleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Please enter your details.",
    ),
    "pleaseEnterYourEmail": MessageLookupByLibrary.simpleMessage(
      "Please enter your email",
    ),
    "pleaseEnterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Please enter your password",
    ),
    "pleaseEnterYourSurname": MessageLookupByLibrary.simpleMessage(
      "Please enter your surname",
    ),
    "pleaseSelectAddressWithTown": MessageLookupByLibrary.simpleMessage(
      "Please select an address with a town",
    ),
    "pleaseSelectState": MessageLookupByLibrary.simpleMessage(
      "Please select a state",
    ),
    "pleaseSetCountryInAddressFirst": MessageLookupByLibrary.simpleMessage(
      "Please set your country in your address first",
    ),
    "pleaseSignInFirst": MessageLookupByLibrary.simpleMessage(
      "Please sign in first",
    ),
    "pleaseSignInToConfirmYourIdentity": MessageLookupByLibrary.simpleMessage(
      "Please sign in to confirm your identity.",
    ),
    "pleaseSignInToManageGroups": MessageLookupByLibrary.simpleMessage(
      "Please sign in to manage groups.",
    ),
    "pleaseSignInToViewGroupInvitations": MessageLookupByLibrary.simpleMessage(
      "Please sign in to view group invitations.",
    ),
    "pleaseSignInToViewYourGroups": MessageLookupByLibrary.simpleMessage(
      "Please sign in to view your groups.",
    ),
    "pleaseUsePhoneToRegister": MessageLookupByLibrary.simpleMessage(
      "Use your phone for registering, please",
    ),
    "poll": MessageLookupByLibrary.simpleMessage("Poll"),
    "pollDeleted": MessageLookupByLibrary.simpleMessage("Poll deleted"),
    "pollDetails": MessageLookupByLibrary.simpleMessage("Poll details"),
    "pollGuidelineDescription": MessageLookupByLibrary.simpleMessage(
      "Poll guideline description",
    ),
    "pollGuidelines": MessageLookupByLibrary.simpleMessage("Poll Guidelines"),
    "pollTutorialStep1Desc": MessageLookupByLibrary.simpleMessage(
      "Know exactly what you want to learn — one idea only.",
    ),
    "pollTutorialStep1Title": MessageLookupByLibrary.simpleMessage(
      "1. Be crystal clear about the goal",
    ),
    "pollTutorialStep2Desc": MessageLookupByLibrary.simpleMessage(
      "No technical words. No jargon. No “smart-sounding” phrasing. If a teenager and a grandparent both understand it, it’s good.",
    ),
    "pollTutorialStep2Title": MessageLookupByLibrary.simpleMessage(
      "2. Use everyday language",
    ),
    "pollTutorialStep3Desc": MessageLookupByLibrary.simpleMessage(
      "Simple sentence. Simple structure.",
    ),
    "pollTutorialStep3Title": MessageLookupByLibrary.simpleMessage(
      "3. Ask one short, easy to understand direct question",
    ),
    "pollTutorialStep4Desc": MessageLookupByLibrary.simpleMessage(
      "No trick answers. No emotional wording. No pushing people toward one option. Include “Not sure” if relevant.",
    ),
    "pollTutorialStep4Title": MessageLookupByLibrary.simpleMessage(
      "4. Give fair choices",
    ),
    "pollTutorialStep5Desc": MessageLookupByLibrary.simpleMessage(
      "3–5 choices is perfect for public polls.",
    ),
    "pollTutorialStep5Title": MessageLookupByLibrary.simpleMessage(
      "5. Keep options few",
    ),
    "pollTutorialStep6Desc": MessageLookupByLibrary.simpleMessage(
      "People should understand and vote in under 10 seconds.",
    ),
    "pollTutorialStep6Title": MessageLookupByLibrary.simpleMessage(
      "6. Make it fast to answer",
    ),
    "pollTutorialStep7Desc": MessageLookupByLibrary.simpleMessage(
      "The poll must feel safe, non-judgmental, and unbiased.",
    ),
    "pollTutorialStep7Title": MessageLookupByLibrary.simpleMessage(
      "7. Respect neutrality",
    ),
    "polls": MessageLookupByLibrary.simpleMessage("Polls"),
    "popularPetitions": MessageLookupByLibrary.simpleMessage(
      "Popular Petitions",
    ),
    "prioritySupport": MessageLookupByLibrary.simpleMessage("Priority support"),
    "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
    "privacyPolicyEssentialDescription": MessageLookupByLibrary.simpleMessage(
      "Essential information about how the app processes personal data.",
    ),
    "privacyPolicyEssentialTitle": MessageLookupByLibrary.simpleMessage(
      "Privacy policy",
    ),
    "privacySettings": MessageLookupByLibrary.simpleMessage("Privacy Settings"),
    "privateGroupOrSignInRequired": MessageLookupByLibrary.simpleMessage(
      "This group is private or requires sign-in before more details can be shown.",
    ),
    "privateGroupWaitForInvite": MessageLookupByLibrary.simpleMessage(
      "This group is completely private. Please wait for a direct invite from the group admins.",
    ),
    "proMember": MessageLookupByLibrary.simpleMessage("Pro Member"),
    "processId": MessageLookupByLibrary.simpleMessage("Process ID"),
    "products": MessageLookupByLibrary.simpleMessage("Products"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "profilePictureUpdated": MessageLookupByLibrary.simpleMessage(
      "Profile picture updated",
    ),
    "protectedAccessMode": MessageLookupByLibrary.simpleMessage("Protected"),
    "protectedGroupsRequireApprovalRequest":
        MessageLookupByLibrary.simpleMessage(
          "Protected groups require an approval request before you can join.",
        ),
    "protectedGroupsRequireInviteLink": MessageLookupByLibrary.simpleMessage(
      "Protected groups require a valid invite link and an approval request.",
    ),
    "public": MessageLookupByLibrary.simpleMessage("Public"),
    "publications": MessageLookupByLibrary.simpleMessage("Publications"),
    "publishTo": MessageLookupByLibrary.simpleMessage("Publish to"),
    "publishedUnderTheGnuGeneralPublicLicenseV30":
        MessageLookupByLibrary.simpleMessage(
          "Published under the GNU General Public License v3.0",
        ),
    "purchaseCancelled": MessageLookupByLibrary.simpleMessage(
      "Purchase cancelled.",
    ),
    "purchaseFailed": MessageLookupByLibrary.simpleMessage("Purchase failed."),
    "purchaseSuccessful": MessageLookupByLibrary.simpleMessage(
      "Purchase successful!",
    ),
    "questionNumber": m24,
    "questionRequired": MessageLookupByLibrary.simpleMessage(
      "Question is required",
    ),
    "questions": MessageLookupByLibrary.simpleMessage("Questions"),
    "reasonYourSignature": MessageLookupByLibrary.simpleMessage(
      "Reason your signature",
    ),
    "reasonsForSigning": MessageLookupByLibrary.simpleMessage(
      "Reasons for signing",
    ),
    "recentPetitions": MessageLookupByLibrary.simpleMessage("Recent Petitions"),
    "register": MessageLookupByLibrary.simpleMessage("Register"),
    "registerAccount": MessageLookupByLibrary.simpleMessage("Register Account"),
    "registerHere": MessageLookupByLibrary.simpleMessage("Register here"),
    "relatedToState": m25,
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "removeAbusiveLanguageBeforePublishing":
        MessageLookupByLibrary.simpleMessage(
          "Please remove abusive or objectionable language before publishing.",
        ),
    "removeAbusiveLanguageFromPublicName": MessageLookupByLibrary.simpleMessage(
      "Please remove abusive or objectionable language from your public name.",
    ),
    "removeDomainTooltip": MessageLookupByLibrary.simpleMessage(
      "Remove domain",
    ),
    "removeGroupMemberConfirmation": m26,
    "removeGroupMemberTitle": MessageLookupByLibrary.simpleMessage(
      "Remove member?",
    ),
    "removeMemberTooltip": MessageLookupByLibrary.simpleMessage(
      "Remove member",
    ),
    "reportContent": MessageLookupByLibrary.simpleMessage("Report content"),
    "reportSubmittedReview24Hours": MessageLookupByLibrary.simpleMessage(
      "Report submitted. We review reports within 24 hours.",
    ),
    "requestAccess": MessageLookupByLibrary.simpleMessage("Request access"),
    "requestLoginCode": MessageLookupByLibrary.simpleMessage(
      "Request login code",
    ),
    "requestedAccessToThisGroup": m27,
    "resendEmail": MessageLookupByLibrary.simpleMessage("Resend Email"),
    "resendEmailCooldown": MessageLookupByLibrary.simpleMessage(
      "Please wait before resending",
    ),
    "resendVerificationEmail": MessageLookupByLibrary.simpleMessage(
      "Resend verification email",
    ),
    "resetPassword": MessageLookupByLibrary.simpleMessage("Reset password"),
    "resetPasswordCodeSent": MessageLookupByLibrary.simpleMessage(
      "Reset password code sent",
    ),
    "resetPasswordLinkSent": MessageLookupByLibrary.simpleMessage(
      "Reset password link sent",
    ),
    "resubscribe": MessageLookupByLibrary.simpleMessage("Resubscribe"),
    "result": MessageLookupByLibrary.simpleMessage("Result"),
    "roleLabel": MessageLookupByLibrary.simpleMessage("Role"),
    "runningForms": MessageLookupByLibrary.simpleMessage("Running Forms"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveGroupLabel": MessageLookupByLibrary.simpleMessage("Save group"),
    "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
    "savingGroup": MessageLookupByLibrary.simpleMessage("Saving..."),
    "scanAgain": MessageLookupByLibrary.simpleMessage("Scan Again"),
    "scanGroupQrCode": MessageLookupByLibrary.simpleMessage(
      "Scan group QR code",
    ),
    "scanQrCode": MessageLookupByLibrary.simpleMessage("Scan QR code"),
    "scanQrCodeTooltip": MessageLookupByLibrary.simpleMessage("Scan QR code"),
    "scanYourId": MessageLookupByLibrary.simpleMessage(
      "Please scan your German ID card",
    ),
    "scannedData": MessageLookupByLibrary.simpleMessage("Scanned Data"),
    "scope": MessageLookupByLibrary.simpleMessage("Scope"),
    "scopeAndGroup": MessageLookupByLibrary.simpleMessage("Scope and group"),
    "scopeCity": MessageLookupByLibrary.simpleMessage("City"),
    "scopeContinent": MessageLookupByLibrary.simpleMessage("Continent"),
    "scopeCountry": MessageLookupByLibrary.simpleMessage("Country"),
    "scopeDetails": MessageLookupByLibrary.simpleMessage("Scope details"),
    "scopeEu": MessageLookupByLibrary.simpleMessage("EU"),
    "scopeGlobal": MessageLookupByLibrary.simpleMessage("Global"),
    "scopeLabelWithValue": m28,
    "scopeStateRegion": MessageLookupByLibrary.simpleMessage("State / Region"),
    "searchPoweredByTomTom": MessageLookupByLibrary.simpleMessage(
      "Search powered by TomTom",
    ),
    "searchTextField": MessageLookupByLibrary.simpleMessage("Schlagwort"),
    "select": MessageLookupByLibrary.simpleMessage("Pick"),
    "selectFromCamera": MessageLookupByLibrary.simpleMessage(
      "Select from Camera",
    ),
    "selectFromGallery": MessageLookupByLibrary.simpleMessage(
      "Select from Gallery",
    ),
    "selectPaymentProvider": MessageLookupByLibrary.simpleMessage(
      "Select Payment Provider",
    ),
    "sendConfirmationEmail": MessageLookupByLibrary.simpleMessage(
      "Send confirmation email.",
    ),
    "sendCrashLogs": MessageLookupByLibrary.simpleMessage("Send Crash Logs"),
    "sendCrashLogsDescription": MessageLookupByLibrary.simpleMessage(
      "Help us improve the app by automatically sending crash reports.",
    ),
    "sendInvitations": MessageLookupByLibrary.simpleMessage("Send invitations"),
    "sendLoginLink": MessageLookupByLibrary.simpleMessage("Log in with Code"),
    "sendingInvitations": MessageLookupByLibrary.simpleMessage(
      "Sending invitations...",
    ),
    "setExpirationDate": MessageLookupByLibrary.simpleMessage(
      "Set an expiration date",
    ),
    "setTomTomApiKeyToEnableSuggestions": MessageLookupByLibrary.simpleMessage(
      "Set TOMTOM_SEARCH_API_KEY to enable address suggestions",
    ),
    "setUserDetails": MessageLookupByLibrary.simpleMessage("Set user details"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "sexualOrExplicitContent": MessageLookupByLibrary.simpleMessage(
      "Sexual or explicit content",
    ),
    "share": MessageLookupByLibrary.simpleMessage("Share"),
    "sharePetition": MessageLookupByLibrary.simpleMessage("Share Petition"),
    "shareThis": MessageLookupByLibrary.simpleMessage("Share this"),
    "shareThisPetition": MessageLookupByLibrary.simpleMessage(
      "Share this petition",
    ),
    "sharingNotSupported": MessageLookupByLibrary.simpleMessage(
      "Sharing not supported on this platform.",
    ),
    "showSurveys": MessageLookupByLibrary.simpleMessage("Show surveys"),
    "showSurveysInfo": MessageLookupByLibrary.simpleMessage(
      "When this is on, surveys appear in the polls list alongside regular polls. Turn it off if you only want to browse single-question polls.",
    ),
    "sign": MessageLookupByLibrary.simpleMessage("Sign"),
    "signIn": MessageLookupByLibrary.simpleMessage("Sign in"),
    "signInToJoinGroup": MessageLookupByLibrary.simpleMessage(
      "Sign in to join",
    ),
    "signInToJoinGroupAutomatically": MessageLookupByLibrary.simpleMessage(
      "Sign in to join this group automatically.",
    ),
    "signInToRequestGroupAccess": MessageLookupByLibrary.simpleMessage(
      "Sign in to request access",
    ),
    "signPetition": MessageLookupByLibrary.simpleMessage("Sign Petition"),
    "signUpForPro": MessageLookupByLibrary.simpleMessage("Sign up for Pro"),
    "signatureReasoning": MessageLookupByLibrary.simpleMessage(
      "Signature reasoning",
    ),
    "signatureReasoningInfo": MessageLookupByLibrary.simpleMessage(
      "Activates commenting on your signatures and opinions before submitting.",
    ),
    "signatures": MessageLookupByLibrary.simpleMessage("Signatures"),
    "signed": MessageLookupByLibrary.simpleMessage("Signed"),
    "signedOn": MessageLookupByLibrary.simpleMessage("Signed on "),
    "signedPetitions": MessageLookupByLibrary.simpleMessage("Signed Petitions"),
    "source": MessageLookupByLibrary.simpleMessage("Source"),
    "state": MessageLookupByLibrary.simpleMessage("State"),
    "stateDependent": MessageLookupByLibrary.simpleMessage("State dependent"),
    "stateRegionScopeFallback": MessageLookupByLibrary.simpleMessage(
      "State / Region",
    ),
    "stateUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "State updated successfully",
    ),
    "stimmapp": MessageLookupByLibrary.simpleMessage("StimmApp"),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "submitSurvey": MessageLookupByLibrary.simpleMessage("Submit survey"),
    "subscriptionCancelledAccessWillRemainUntilExpiry":
        MessageLookupByLibrary.simpleMessage(
          "Subscription cancelled — access will remain until expiry",
        ),
    "successfullyLoggedIn": MessageLookupByLibrary.simpleMessage(
      "Successfully logged in",
    ),
    "supportedRoles": m29,
    "supporters": MessageLookupByLibrary.simpleMessage("Supporters"),
    "surname": MessageLookupByLibrary.simpleMessage("Surname"),
    "surveyDeleted": MessageLookupByLibrary.simpleMessage("Survey deleted"),
    "surveyDetails": MessageLookupByLibrary.simpleMessage("Survey Details"),
    "surveyQuestion": MessageLookupByLibrary.simpleMessage("Survey question"),
    "surveySubmitted": MessageLookupByLibrary.simpleMessage("Survey submitted"),
    "surveys": MessageLookupByLibrary.simpleMessage("Surveys"),
    "swipeForDelete": MessageLookupByLibrary.simpleMessage("Swipe for delete."),
    "swipeForGroupActions": MessageLookupByLibrary.simpleMessage(
      "Swipe for dashboard or removal.",
    ),
    "swipeToLeaveGroup": MessageLookupByLibrary.simpleMessage(
      "Swipe to leave the group.",
    ),
    "systemDefault": MessageLookupByLibrary.simpleMessage("System Default"),
    "tagAnimalWelfare": MessageLookupByLibrary.simpleMessage("Animal Welfare"),
    "tagCulture": MessageLookupByLibrary.simpleMessage("Culture"),
    "tagEconomy": MessageLookupByLibrary.simpleMessage("Economy"),
    "tagEducation": MessageLookupByLibrary.simpleMessage("Education"),
    "tagEnvironment": MessageLookupByLibrary.simpleMessage("Environment"),
    "tagHealth": MessageLookupByLibrary.simpleMessage("Health"),
    "tagHousing": MessageLookupByLibrary.simpleMessage("Housing"),
    "tagInfrastructure": MessageLookupByLibrary.simpleMessage("Infrastructure"),
    "tagOther": MessageLookupByLibrary.simpleMessage("Other"),
    "tagPolitics": MessageLookupByLibrary.simpleMessage("Politics"),
    "tagSafety": MessageLookupByLibrary.simpleMessage("Safety"),
    "tagSocial": MessageLookupByLibrary.simpleMessage("Social"),
    "tagSports": MessageLookupByLibrary.simpleMessage("Sports"),
    "tagTechnology": MessageLookupByLibrary.simpleMessage("Technology"),
    "tagTraffic": MessageLookupByLibrary.simpleMessage("Traffic"),
    "tags": MessageLookupByLibrary.simpleMessage("Tags"),
    "tagsHint": MessageLookupByLibrary.simpleMessage("Comma-separated tags"),
    "tagsRequired": MessageLookupByLibrary.simpleMessage(
      "At least one tag is required",
    ),
    "terms": MessageLookupByLibrary.simpleMessage("Terms"),
    "testingWidgetsHere": MessageLookupByLibrary.simpleMessage(
      "Testing widgets here",
    ),
    "thankYouForSigning": MessageLookupByLibrary.simpleMessage(
      "Thank you for signing!",
    ),
    "theWelcomePhrase": MessageLookupByLibrary.simpleMessage(
      "The ultimate way to share your opinion",
    ),
    "themePaletteAmber": MessageLookupByLibrary.simpleMessage("Amber"),
    "themePaletteForest": MessageLookupByLibrary.simpleMessage("Forest"),
    "themePaletteMint": MessageLookupByLibrary.simpleMessage("Mint"),
    "themePaletteOcean": MessageLookupByLibrary.simpleMessage("Ocean"),
    "themePalettePlum": MessageLookupByLibrary.simpleMessage("Plum"),
    "themePaletteRose": MessageLookupByLibrary.simpleMessage("Rose"),
    "themePaletteSky": MessageLookupByLibrary.simpleMessage("Sky"),
    "themePaletteSlate": MessageLookupByLibrary.simpleMessage("Slate"),
    "themePaletteSunset": MessageLookupByLibrary.simpleMessage("Sunset"),
    "themePaletteTrainvent": MessageLookupByLibrary.simpleMessage("Trainvent"),
    "thisActionWillPermanentlyDeleteYourAccountAndAllAssociated":
        MessageLookupByLibrary.simpleMessage(
          "This action will permanently delete your account and all associated data.",
        ),
    "thisAppWasDevelopedBy": MessageLookupByLibrary.simpleMessage(
      "This app was developed by",
    ),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "titleRequired": MessageLookupByLibrary.simpleMessage("Title is required"),
    "titleTooShort": MessageLookupByLibrary.simpleMessage("Title is too short"),
    "town": MessageLookupByLibrary.simpleMessage("Town"),
    "travel": MessageLookupByLibrary.simpleMessage("Travel"),
    "typeGroupNameToConfirmDeletion": m30,
    "unblock": MessageLookupByLibrary.simpleMessage("Unblock"),
    "unblockedUserSuccessfully": MessageLookupByLibrary.simpleMessage(
      "User unblocked.",
    ),
    "unexpectedErrorWithDetails": m31,
    "unknownError": MessageLookupByLibrary.simpleMessage("Unknown error"),
    "unknownGroupMember": MessageLookupByLibrary.simpleMessage(
      "Unknown member",
    ),
    "unknownUser": MessageLookupByLibrary.simpleMessage("Unknown user"),
    "updateLivingAddress": MessageLookupByLibrary.simpleMessage(
      "Change address",
    ),
    "updateState": MessageLookupByLibrary.simpleMessage("Update state"),
    "updateUsername": MessageLookupByLibrary.simpleMessage("Update username"),
    "updates": MessageLookupByLibrary.simpleMessage("Updates"),
    "useForThisPoll": MessageLookupByLibrary.simpleMessage("Use for this poll"),
    "userBlockedContentHidden": MessageLookupByLibrary.simpleMessage(
      "User blocked. Their content is now hidden.",
    ),
    "userNotAvailable": MessageLookupByLibrary.simpleMessage(
      "User not available",
    ),
    "userNotFound": MessageLookupByLibrary.simpleMessage("User not found"),
    "userProfileVerified": MessageLookupByLibrary.simpleMessage(
      "Userprofile Verified",
    ),
    "userRoleLabel": MessageLookupByLibrary.simpleMessage("User"),
    "usernameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Username change failed",
    ),
    "usernameChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Username changed successfully",
    ),
    "users": MessageLookupByLibrary.simpleMessage("Users"),
    "validUntil": m32,
    "verificationCodeResent": MessageLookupByLibrary.simpleMessage(
      "Verification code resent!",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Verification email sent",
    ),
    "verificationEmailSentTo": m33,
    "verificationFailed": MessageLookupByLibrary.simpleMessage(
      "Verification failed",
    ),
    "verify": MessageLookupByLibrary.simpleMessage("Verify"),
    "victory": MessageLookupByLibrary.simpleMessage("Victory!"),
    "viewGroupPolls": MessageLookupByLibrary.simpleMessage("Polls and surveys"),
    "viewGroupPollsDescription": MessageLookupByLibrary.simpleMessage(
      "See everything published for this group.",
    ),
    "viewInstitutionalGuide": MessageLookupByLibrary.simpleMessage(
      "View institutional guide",
    ),
    "viewLicenses": MessageLookupByLibrary.simpleMessage("View licenses"),
    "viewParticipants": MessageLookupByLibrary.simpleMessage(
      "View Participants",
    ),
    "violenceOrThreats": MessageLookupByLibrary.simpleMessage(
      "Violence or threats",
    ),
    "vote": MessageLookupByLibrary.simpleMessage("Vote"),
    "voteForNewGroupAdmin": MessageLookupByLibrary.simpleMessage(
      "Vote for a new group admin",
    ),
    "voted": MessageLookupByLibrary.simpleMessage("Voted"),
    "weCannotProvideSecureVerificationYetButWeAreWorking":
        MessageLookupByLibrary.simpleMessage(
          "We cannot provide secure verification yet, but we are working on it.",
        ),
    "weFailedToGetYourStatePleaseProofreadYourLivingaddress":
        MessageLookupByLibrary.simpleMessage(
          "We failed to get your state, please proofread your living address.",
        ),
    "weHaveSentA6digitCodeToYourEmailPlease":
        MessageLookupByLibrary.simpleMessage(
          "We have sent a 6-digit code to your email. Please enter it below.",
        ),
    "welcomeBackPleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Welcome back! Please enter your details.",
    ),
    "welcomePleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "Welcome! Please enter your details.",
    ),
    "welcomeTo": MessageLookupByLibrary.simpleMessage("Welcome to "),
    "welcomeToPro": MessageLookupByLibrary.simpleMessage("Welcome to Pro!"),
    "whyAreYouSigning": MessageLookupByLibrary.simpleMessage(
      "Why are you signing?",
    ),
    "wrongPasswordProvided": MessageLookupByLibrary.simpleMessage(
      "Wrong password provided.",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Yes, cancel"),
    "youAreNotMemberOfAnyGroupsYet": MessageLookupByLibrary.simpleMessage(
      "You are not a member of any groups yet.",
    ),
    "youCannotRemoveYourselfHere": MessageLookupByLibrary.simpleMessage(
      "You cannot remove yourself from this page.",
    ),
    "youJoinedTheGroup": MessageLookupByLibrary.simpleMessage(
      "You joined the group.",
    ),
    "youLeftTheGroup": MessageLookupByLibrary.simpleMessage(
      "You left the group.",
    ),
    "youSubscribedToFollowingBenefits": MessageLookupByLibrary.simpleMessage(
      "You subscribed to following benefits",
    ),
    "yourGroupsTitle": MessageLookupByLibrary.simpleMessage("Your groups"),
  };
}

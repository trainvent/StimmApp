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

  static String m0(firstName, lastName) => "Welcome ${firstName} ${lastName}!";

  static String m1(newMessages) =>
      "You have ${Intl.plural(newMessages, zero: 'No new messages', one: 'One new message', two: 'Two new Messages', other: '${newMessages} new messages')}";

  static String m2(type) =>
      "Password must contain at least one ${Intl.select(type, {'uppercase': 'uppercase letter', 'lowercase': 'lowercase letter', 'number': 'number', 'special': 'special character', 'other': 'valid character'})}";

  static String m3(state) => "Related to ${state}";

  static String m4(date) => "Valid until: ${date}";

  static String m5(email) => "A verification email has been sent to ${email}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "aboutThisApp": MessageLookupByLibrary.simpleMessage("About this app"),
    "active": MessageLookupByLibrary.simpleMessage("Active"),
    "activityHistory": MessageLookupByLibrary.simpleMessage("Activity History"),
    "addComment": MessageLookupByLibrary.simpleMessage("Add a comment"),
    "addImage": MessageLookupByLibrary.simpleMessage("Add Image"),
    "addOption": MessageLookupByLibrary.simpleMessage("Add option"),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Address updated successfully",
    ),
    "adminDashboard": MessageLookupByLibrary.simpleMessage("Admin Dashboard"),
    "adminInterface": MessageLookupByLibrary.simpleMessage("Admin Interface"),
    "alert": MessageLookupByLibrary.simpleMessage("Alert"),
    "anUnexpectedErrorOccurred": MessageLookupByLibrary.simpleMessage(
      "An unexpected error occurred.",
    ),
    "anonymous": MessageLookupByLibrary.simpleMessage("Anonymous"),
    "areYouSureYouWantToCancelYourProSubscription":
        MessageLookupByLibrary.simpleMessage(
          "Are you sure you want to cancel your Pro subscription? You will lose Pro features.",
        ),
    "areYouSureYouWantToClearThisDraft": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear this draft?",
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
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Change Language"),
    "changePassword": MessageLookupByLibrary.simpleMessage("Change password"),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "closed": MessageLookupByLibrary.simpleMessage("Closed"),
    "colorMode": MessageLookupByLibrary.simpleMessage("Color Mode"),
    "colorTheme": MessageLookupByLibrary.simpleMessage("Color Theme"),
    "comments": MessageLookupByLibrary.simpleMessage("Comments"),
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
    "couldNotOpenPaywall": MessageLookupByLibrary.simpleMessage(
      "Could not open paywall",
    ),
    "createNewPetitionDescription": MessageLookupByLibrary.simpleMessage(
      "Create a new petition",
    ),
    "createNewPollDescription": MessageLookupByLibrary.simpleMessage(
      "Create a new poll",
    ),
    "createPetition": MessageLookupByLibrary.simpleMessage("Create Petition"),
    "createPoll": MessageLookupByLibrary.simpleMessage("Create Poll"),
    "createdPetition": MessageLookupByLibrary.simpleMessage("Petition created"),
    "createdPoll": MessageLookupByLibrary.simpleMessage("Poll created"),
    "creator": MessageLookupByLibrary.simpleMessage("Creator"),
    "currentPassword": MessageLookupByLibrary.simpleMessage("Current password"),
    "customPetitionAndPollPictures": MessageLookupByLibrary.simpleMessage(
      "Custom petition and poll pictures",
    ),
    "dailyCreateLimitReached": MessageLookupByLibrary.simpleMessage(
      "You can only publish one petition and one poll per day.",
    ),
    "dailyCreatePetitionLimitReached": MessageLookupByLibrary.simpleMessage(
      "You can only publish one petition per day.",
    ),
    "dailyCreatePollLimitReached": MessageLookupByLibrary.simpleMessage(
      "You can only publish one poll per day.",
    ),
    "dailyHabit": MessageLookupByLibrary.simpleMessage("Daily habit"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "dateOfBirth": MessageLookupByLibrary.simpleMessage("Date of Birth"),
    "daysLeft": MessageLookupByLibrary.simpleMessage("Days Left"),
    "delete": MessageLookupByLibrary.simpleMessage("delete"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("delete Account"),
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
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "descriptionRequired": MessageLookupByLibrary.simpleMessage(
      "Description is required",
    ),
    "descriptionTooShort": MessageLookupByLibrary.simpleMessage(
      "Description is too short",
    ),
    "devContactInformation": MessageLookupByLibrary.simpleMessage(
      "This app is developed by Team LeEd with help of yannic",
    ),
    "developerSandbox": MessageLookupByLibrary.simpleMessage(
      "Developer Sandbox",
    ),
    "displayName": MessageLookupByLibrary.simpleMessage("displayed name"),
    "editPetition": MessageLookupByLibrary.simpleMessage("Edit Petition"),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
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
    "english": MessageLookupByLibrary.simpleMessage("english"),
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
      "enter Your Address",
    ),
    "enterYourEmail": MessageLookupByLibrary.simpleMessage("Enter your email"),
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
    "exercise": MessageLookupByLibrary.simpleMessage("Exercise"),
    "expiredCreations": MessageLookupByLibrary.simpleMessage(
      "Expired creations",
    ),
    "expiredPetitions": MessageLookupByLibrary.simpleMessage(
      "Expired petitions",
    ),
    "expiredPolls": MessageLookupByLibrary.simpleMessage("Expired polls"),
    "expiresOn": MessageLookupByLibrary.simpleMessage("Expires on"),
    "expiryDate": MessageLookupByLibrary.simpleMessage("Expiry Date"),
    "explore": MessageLookupByLibrary.simpleMessage("Explore"),
    "exportCsv": MessageLookupByLibrary.simpleMessage("Export CSV"),
    "exportFailed": MessageLookupByLibrary.simpleMessage("Export failed"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export created"),
    "failedToCreatePoll": MessageLookupByLibrary.simpleMessage(
      "Failed to create poll",
    ),
    "failedToResendCode": MessageLookupByLibrary.simpleMessage(
      "Failed to resend code",
    ),
    "failedToUploadImage": MessageLookupByLibrary.simpleMessage(
      "Failed to upload image: ",
    ),
    "faultyInput": MessageLookupByLibrary.simpleMessage("Faulty input"),
    "finalNotice": MessageLookupByLibrary.simpleMessage("Final notice"),
    "finishedForms": MessageLookupByLibrary.simpleMessage("Finished forms"),
    "flutterPro": MessageLookupByLibrary.simpleMessage("Flutter Pro"),
    "flutterProEmail": MessageLookupByLibrary.simpleMessage("Flutter@pro.com"),
    "freeMember": MessageLookupByLibrary.simpleMessage("Free Member"),
    "french": MessageLookupByLibrary.simpleMessage("french"),
    "frontSide": MessageLookupByLibrary.simpleMessage("Front Side"),
    "german": MessageLookupByLibrary.simpleMessage("german"),
    "getStarted": MessageLookupByLibrary.simpleMessage("Get started"),
    "githubLinkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "GitHub link copied to clipboard",
    ),
    "givenName": MessageLookupByLibrary.simpleMessage("Given Name"),
    "goProToAccessTheseBenefits": MessageLookupByLibrary.simpleMessage(
      "Go pro to access these benefits",
    ),
    "goToWelcome": MessageLookupByLibrary.simpleMessage("Go to Welcome"),
    "goal": MessageLookupByLibrary.simpleMessage("Goal"),
    "growthStartsWithin": MessageLookupByLibrary.simpleMessage(
      "Growth starts within",
    ),
    "height": MessageLookupByLibrary.simpleMessage("Height"),
    "hello": MessageLookupByLibrary.simpleMessage("hello"),
    "helloAndWelcome": m0,
    "hintTextTags": MessageLookupByLibrary.simpleMessage(
      "e.g. environment, transport",
    ),
    "idNumber": MessageLookupByLibrary.simpleMessage("ID Number"),
    "idScan": MessageLookupByLibrary.simpleMessage("ID Scan"),
    "imagePreviewDescription": MessageLookupByLibrary.simpleMessage(
      "This is a preview of your new profile picture.",
    ),
    "inactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "invalidEmailEntered": MessageLookupByLibrary.simpleMessage(
      "Invalid email entered",
    ),
    "isProMember": MessageLookupByLibrary.simpleMessage("Ist Pro-Mitglied"),
    "language": MessageLookupByLibrary.simpleMessage("language"),
    "lastStep": MessageLookupByLibrary.simpleMessage("Last step!"),
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
    "loginCodeSent": MessageLookupByLibrary.simpleMessage("login code sent"),
    "loginLinkSent": MessageLookupByLibrary.simpleMessage("Code sent!"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "membershipStatus": MessageLookupByLibrary.simpleMessage(
      "Membership Status",
    ),
    "moreBenefitsToBeAddedLater": MessageLookupByLibrary.simpleMessage(
      "More benefits to be added later",
    ),
    "myPetitions": MessageLookupByLibrary.simpleMessage("My Petitions"),
    "myProfile": MessageLookupByLibrary.simpleMessage("My Profile"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Name change failed",
    ),
    "nationality": MessageLookupByLibrary.simpleMessage("Nationality"),
    "newMessages": m1,
    "newPassword": MessageLookupByLibrary.simpleMessage("New password"),
    "newUsername": MessageLookupByLibrary.simpleMessage("New username"),
    "nickname": MessageLookupByLibrary.simpleMessage("Nickname"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noActivityFound": MessageLookupByLibrary.simpleMessage(
      "No activity found yet.",
    ),
    "noAdvertisements": MessageLookupByLibrary.simpleMessage(
      "No advertisements",
    ),
    "noData": MessageLookupByLibrary.simpleMessage("No data"),
    "noEmail": MessageLookupByLibrary.simpleMessage("No Email"),
    "noExpiredItems": MessageLookupByLibrary.simpleMessage("No expired items"),
    "noImageSelected": MessageLookupByLibrary.simpleMessage(
      "No image selected",
    ),
    "noName": MessageLookupByLibrary.simpleMessage("No Name"),
    "noOptions": MessageLookupByLibrary.simpleMessage("no options"),
    "noProMember": MessageLookupByLibrary.simpleMessage(
      "Nein, kein Pro-Mitglied",
    ),
    "noTitle": MessageLookupByLibrary.simpleMessage("No Title"),
    "noUserFoundForThatEmail": MessageLookupByLibrary.simpleMessage(
      "No user found for that email.",
    ),
    "noUsernameFound": MessageLookupByLibrary.simpleMessage(
      "no username found",
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
    "option": MessageLookupByLibrary.simpleMessage("Option"),
    "optionRequired": MessageLookupByLibrary.simpleMessage(
      "Option is required",
    ),
    "options": MessageLookupByLibrary.simpleMessage("Options"),
    "other": MessageLookupByLibrary.simpleMessage("other"),
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
    "passwordValidation": m2,
    "passwordsDoNotMatch": MessageLookupByLibrary.simpleMessage(
      "Passwords do not match",
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
    "permanentlyDeleteAccount": MessageLookupByLibrary.simpleMessage(
      "PERMANENTLY DELETE ACCOUNT",
    ),
    "petition": MessageLookupByLibrary.simpleMessage("Petition"),
    "petitionBy": MessageLookupByLibrary.simpleMessage("Petition by"),
    "petitionDetails": MessageLookupByLibrary.simpleMessage("Petition details"),
    "petitionGuidelineDescription": MessageLookupByLibrary.simpleMessage(
      "petition guideline description",
    ),
    "petitionGuidelines": MessageLookupByLibrary.simpleMessage(
      "petition guidelines",
    ),
    "petitionSuccessfullySigned": MessageLookupByLibrary.simpleMessage(
      "Petition successfully signed!",
    ),
    "petitionTitleInUseAlready": MessageLookupByLibrary.simpleMessage(
      "petition title in use already",
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
    "placeOfBirth": MessageLookupByLibrary.simpleMessage("Place of Birth"),
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
    "pleaseEnterYourCredentials": MessageLookupByLibrary.simpleMessage(
      "Please enter your Credentials",
    ),
    "pleaseEnterYourDesiredCredentials": MessageLookupByLibrary.simpleMessage(
      "Please enter the Credentials you desire.",
    ),
    "pleaseEnterYourDetails": MessageLookupByLibrary.simpleMessage(
      "please enter your details.",
    ),
    "pleaseEnterYourEmail": MessageLookupByLibrary.simpleMessage(
      "please enter your Email",
    ),
    "pleaseEnterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Please enter your password",
    ),
    "pleaseEnterYourSurname": MessageLookupByLibrary.simpleMessage(
      "Please enter your surname",
    ),
    "pleaseSelectState": MessageLookupByLibrary.simpleMessage(
      "Please select a state",
    ),
    "pleaseSignInFirst": MessageLookupByLibrary.simpleMessage(
      "Please sign in first",
    ),
    "pleaseSignInToConfirmYourIdentity": MessageLookupByLibrary.simpleMessage(
      "Please sign in to confirm your identity.",
    ),
    "pleaseUsePhoneToRegister": MessageLookupByLibrary.simpleMessage(
      "Use your phone for registering, please",
    ),
    "poll": MessageLookupByLibrary.simpleMessage("Poll"),
    "pollDetails": MessageLookupByLibrary.simpleMessage("Poll details"),
    "pollGuidelineDescription": MessageLookupByLibrary.simpleMessage(
      "poll guideline description",
    ),
    "pollGuidelines": MessageLookupByLibrary.simpleMessage("poll guidelines"),
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
    "privacySettings": MessageLookupByLibrary.simpleMessage("Privacy Settings"),
    "proMember": MessageLookupByLibrary.simpleMessage("Pro Member"),
    "processId": MessageLookupByLibrary.simpleMessage("Process ID"),
    "products": MessageLookupByLibrary.simpleMessage("Products"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "profilePictureUpdated": MessageLookupByLibrary.simpleMessage(
      "Profile picture updated",
    ),
    "publishedUnderTheGnuGeneralPublicLicenseV30":
        MessageLookupByLibrary.simpleMessage(
          "published under the GNU General Public License v3.0",
        ),
    "purchaseCancelled": MessageLookupByLibrary.simpleMessage(
      "Purchase cancelled.",
    ),
    "purchaseFailed": MessageLookupByLibrary.simpleMessage("Purchase failed."),
    "purchaseSuccessful": MessageLookupByLibrary.simpleMessage(
      "Purchase successful!",
    ),
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
    "relatedToState": m3,
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "requestLoginCode": MessageLookupByLibrary.simpleMessage(
      "Request login code",
    ),
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
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "scanAgain": MessageLookupByLibrary.simpleMessage("Scan Again"),
    "scanYourId": MessageLookupByLibrary.simpleMessage(
      "Please scan your German ID card",
    ),
    "scannedData": MessageLookupByLibrary.simpleMessage("Scanned Data"),
    "searchTextField": MessageLookupByLibrary.simpleMessage("Schlagwort"),
    "select": MessageLookupByLibrary.simpleMessage("Pick"),
    "selectFromCamera": MessageLookupByLibrary.simpleMessage(
      "Select from Camera",
    ),
    "selectFromGallery": MessageLookupByLibrary.simpleMessage(
      "Select from Gallery",
    ),
    "sendConfirmationEmail": MessageLookupByLibrary.simpleMessage(
      "Send confirmation Email.",
    ),
    "sendCrashLogs": MessageLookupByLibrary.simpleMessage("Send Crash Logs"),
    "sendCrashLogsDescription": MessageLookupByLibrary.simpleMessage(
      "Help us improve the app by automatically sending crash reports.",
    ),
    "sendLoginLink": MessageLookupByLibrary.simpleMessage("Log in with Code"),
    "setUserDetails": MessageLookupByLibrary.simpleMessage("Set user details"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "share": MessageLookupByLibrary.simpleMessage("Share"),
    "sharePetition": MessageLookupByLibrary.simpleMessage("Share Petition"),
    "shareThis": MessageLookupByLibrary.simpleMessage("Share this"),
    "shareThisPetition": MessageLookupByLibrary.simpleMessage(
      "Share this petition",
    ),
    "sharingNotSupported": MessageLookupByLibrary.simpleMessage(
      "Sharing not supported on this platform.",
    ),
    "sign": MessageLookupByLibrary.simpleMessage("Sign"),
    "signIn": MessageLookupByLibrary.simpleMessage("Sign in"),
    "signPetition": MessageLookupByLibrary.simpleMessage("Sign Petition"),
    "signUpForPro": MessageLookupByLibrary.simpleMessage("Sign up for Pro"),
    "signatures": MessageLookupByLibrary.simpleMessage("Signatures"),
    "signed": MessageLookupByLibrary.simpleMessage("Signed"),
    "signedOn": MessageLookupByLibrary.simpleMessage("Signed on "),
    "signedPetitions": MessageLookupByLibrary.simpleMessage("Signed Petitions"),
    "source": MessageLookupByLibrary.simpleMessage("Source"),
    "state": MessageLookupByLibrary.simpleMessage("State"),
    "stateDependent": MessageLookupByLibrary.simpleMessage("State dependent"),
    "stateUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "State updated successfully",
    ),
    "stimmapp": MessageLookupByLibrary.simpleMessage("stimmapp"),
    "subscriptionCancelledAccessWillRemainUntilExpiry":
        MessageLookupByLibrary.simpleMessage(
          "Subscription cancelled — access will remain until expiry",
        ),
    "successfullyLoggedIn": MessageLookupByLibrary.simpleMessage(
      "Successfully logged in",
    ),
    "supporters": MessageLookupByLibrary.simpleMessage("Supporters"),
    "surname": MessageLookupByLibrary.simpleMessage("Surname"),
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
    "testingWidgetsHere": MessageLookupByLibrary.simpleMessage(
      "Testing widgets here",
    ),
    "thankYouForSigning": MessageLookupByLibrary.simpleMessage(
      "Thank you for signing!",
    ),
    "theWelcomePhrase": MessageLookupByLibrary.simpleMessage(
      "The ultimate way to share your opinion",
    ),
    "thisActionWillPermanentlyDeleteYourAccountAndAllAssociated":
        MessageLookupByLibrary.simpleMessage(
          "This action will permanently delete your account and all associated data.",
        ),
    "thisAppWasDevelopedBy": MessageLookupByLibrary.simpleMessage(
      "this app was developed by",
    ),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "titleRequired": MessageLookupByLibrary.simpleMessage("Title is required"),
    "titleTooShort": MessageLookupByLibrary.simpleMessage("Title is too short"),
    "travel": MessageLookupByLibrary.simpleMessage("Travel"),
    "unknownError": MessageLookupByLibrary.simpleMessage("Unknown error"),
    "updateLivingAddress": MessageLookupByLibrary.simpleMessage(
      "Change address",
    ),
    "updateState": MessageLookupByLibrary.simpleMessage("Update state"),
    "updateUsername": MessageLookupByLibrary.simpleMessage("Update username"),
    "updates": MessageLookupByLibrary.simpleMessage("Updates"),
    "userNotAvailable": MessageLookupByLibrary.simpleMessage(
      "User not available",
    ),
    "userNotFound": MessageLookupByLibrary.simpleMessage("User not found"),
    "userProfileVerified": MessageLookupByLibrary.simpleMessage(
      "Userprofile Verified",
    ),
    "usernameChangeFailed": MessageLookupByLibrary.simpleMessage(
      "Username change failed",
    ),
    "usernameChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Username changed successfully",
    ),
    "users": MessageLookupByLibrary.simpleMessage("Users"),
    "validUntil": m4,
    "verificationCodeResent": MessageLookupByLibrary.simpleMessage(
      "Verification code resent!",
    ),
    "verificationEmailSent": MessageLookupByLibrary.simpleMessage(
      "Verification email sent",
    ),
    "verificationEmailSentTo": m5,
    "verificationFailed": MessageLookupByLibrary.simpleMessage(
      "Verification failed",
    ),
    "verify": MessageLookupByLibrary.simpleMessage("Verify"),
    "victory": MessageLookupByLibrary.simpleMessage("Victory!"),
    "viewInstitutionalGuide": MessageLookupByLibrary.simpleMessage(
      "View institutional guide",
    ),
    "viewLicenses": MessageLookupByLibrary.simpleMessage("View licenses"),
    "viewParticipants": MessageLookupByLibrary.simpleMessage(
      "View Participants",
    ),
    "vote": MessageLookupByLibrary.simpleMessage("Vote"),
    "voted": MessageLookupByLibrary.simpleMessage("Voted"),
    "weCannotProvideSecureVerificationYetButWeAreWorking":
        MessageLookupByLibrary.simpleMessage(
          "We cannot provide secure verification yet, but we are working on it.",
        ),
    "weFailedToGetYourStatePleaseProofreadYourLivingaddress":
        MessageLookupByLibrary.simpleMessage(
          "we failed to get your state, please proofread your living-address",
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
    "wrongPasswordProvided": MessageLookupByLibrary.simpleMessage(
      "Wrong password provided.",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Ja"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Yes, cancel"),
    "youSubscribedToFollowingBenefits": MessageLookupByLibrary.simpleMessage(
      "You subscribed to following benefits",
    ),
  };
}

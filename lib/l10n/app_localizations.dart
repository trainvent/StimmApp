import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @pleaseEnterYourSurname.
  ///
  /// In en, this message translates to:
  /// **'Please enter your surname'**
  String get pleaseEnterYourSurname;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Displayed Name'**
  String get displayName;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutThisApp;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activityHistory;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addComment;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addOption;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Address updated successfully'**
  String get addressUpdatedSuccessfully;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminInterface.
  ///
  /// In en, this message translates to:
  /// **'Admin Interface'**
  String get adminInterface;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @areYouSureYouWantToCancelYourProSubscription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your Pro subscription? You will lose Pro features.'**
  String get areYouSureYouWantToCancelYourProSubscription;

  /// No description provided for @areYouSureYouWantToDeleteThisPetition.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this petition?'**
  String get areYouSureYouWantToDeleteThisPetition;

  /// No description provided for @areYouSureYouWantToDeleteThisPoll.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this poll?'**
  String get areYouSureYouWantToDeleteThisPoll;

  /// No description provided for @areYouSureYouWantToDeleteThisUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get areYouSureYouWantToDeleteThisUser;

  /// No description provided for @areYouSureYouWantToDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get areYouSureYouWantToDeleteYourAccount;

  /// No description provided for @areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action is irreversible'**
  String get areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @backSide.
  ///
  /// In en, this message translates to:
  /// **'Back Side'**
  String get backSide;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsers;

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not blocked anyone.'**
  String get blockedUsersEmpty;

  /// No description provided for @blockedUsersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blocked users'**
  String get blockedUsersLoadError;

  /// No description provided for @blockedContentHidden.
  ///
  /// In en, this message translates to:
  /// **'This content is hidden because you blocked this user.'**
  String get blockedContentHidden;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reportContent.
  ///
  /// In en, this message translates to:
  /// **'Report content'**
  String get reportContent;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @blockUserDescription.
  ///
  /// In en, this message translates to:
  /// **'This will hide this user\'s content from your feed immediately and notify the StimmApp team for review.'**
  String get blockUserDescription;

  /// No description provided for @additionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get additionalDetailsOptional;

  /// No description provided for @reportSubmittedReview24Hours.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. We review reports within 24 hours.'**
  String get reportSubmittedReview24Hours;

  /// No description provided for @userBlockedContentHidden.
  ///
  /// In en, this message translates to:
  /// **'User blocked. Their content is now hidden.'**
  String get userBlockedContentHidden;

  /// No description provided for @harassmentOrBullying.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get harassmentOrBullying;

  /// No description provided for @hateSpeech.
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get hateSpeech;

  /// No description provided for @sexualOrExplicitContent.
  ///
  /// In en, this message translates to:
  /// **'Sexual or explicit content'**
  String get sexualOrExplicitContent;

  /// No description provided for @violenceOrThreats.
  ///
  /// In en, this message translates to:
  /// **'Violence or threats'**
  String get violenceOrThreats;

  /// No description provided for @misinformationOrFraud.
  ///
  /// In en, this message translates to:
  /// **'Misinformation or fraud'**
  String get misinformationOrFraud;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancelProSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Pro Subscription'**
  String get cancelProSubscription;

  /// No description provided for @cancelRegistration.
  ///
  /// In en, this message translates to:
  /// **'Cancel registration'**
  String get cancelRegistration;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscription;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @colorMode.
  ///
  /// In en, this message translates to:
  /// **'Color Mode'**
  String get colorMode;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get colorTheme;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Finish'**
  String get confirmAndFinish;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Email Sent'**
  String get confirmationEmailSent;

  /// No description provided for @confirmationEmailSentDescription.
  ///
  /// In en, this message translates to:
  /// **'We have sent a confirmation email to your email address. Please check your inbox and follow the instructions to complete your registration.'**
  String get confirmationEmailSentDescription;

  /// No description provided for @consumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get consumption;

  /// No description provided for @continueNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueNext;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @couldNotOpenPaywall.
  ///
  /// In en, this message translates to:
  /// **'Could not open paywall'**
  String get couldNotOpenPaywall;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get couldNotOpenLink;

  /// No description provided for @createNewPetitionDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new petition'**
  String get createNewPetitionDescription;

  /// No description provided for @createNewPollDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new poll'**
  String get createNewPollDescription;

  /// No description provided for @createPetition.
  ///
  /// In en, this message translates to:
  /// **'Create Petition'**
  String get createPetition;

  /// No description provided for @createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get createPoll;

  /// No description provided for @createdPetition.
  ///
  /// In en, this message translates to:
  /// **'Petition created'**
  String get createdPetition;

  /// No description provided for @createdPoll.
  ///
  /// In en, this message translates to:
  /// **'Poll created'**
  String get createdPoll;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @customPetitionAndPollPictures.
  ///
  /// In en, this message translates to:
  /// **'Custom petition and poll pictures'**
  String get customPetitionAndPollPictures;

  /// No description provided for @dailyCreateLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can only publish one petition and one poll per day.'**
  String get dailyCreateLimitReached;

  /// No description provided for @dailyCreatePetitionLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can only publish one petition per day.'**
  String get dailyCreatePetitionLimitReached;

  /// No description provided for @dailyCreatePollLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can only publish one poll per day.'**
  String get dailyCreatePollLimitReached;

  /// No description provided for @dailyHabit.
  ///
  /// In en, this message translates to:
  /// **'Daily habit'**
  String get dailyHabit;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days Left'**
  String get daysLeft;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'PERMANENTLY DELETE ACCOUNT'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to confirm your identity. This action will permanently delete your account and all associated data.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Your Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get deleteAccountUnexpectedError;

  /// No description provided for @deleteAccountUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found for that email.'**
  String get deleteAccountUserNotFound;

  /// No description provided for @deleteAccountWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password provided.'**
  String get deleteAccountWrongPassword;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @deletePetition.
  ///
  /// In en, this message translates to:
  /// **'Delete Petition'**
  String get deletePetition;

  /// No description provided for @deletePoll.
  ///
  /// In en, this message translates to:
  /// **'Delete Poll'**
  String get deletePoll;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Description is too short'**
  String get descriptionTooShort;

  /// No description provided for @devContactInformation.
  ///
  /// In en, this message translates to:
  /// **'This app is developed by Trainvent'**
  String get devContactInformation;

  /// No description provided for @developerSandbox.
  ///
  /// In en, this message translates to:
  /// **'Developer Sandbox'**
  String get developerSandbox;

  /// No description provided for @editPetition.
  ///
  /// In en, this message translates to:
  /// **'Edit Petition'**
  String get editPetition;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get emailVerification;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCode;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @enterSomething.
  ///
  /// In en, this message translates to:
  /// **'Enter something'**
  String get enterSomething;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterYourAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @entryNotYetImplemented.
  ///
  /// In en, this message translates to:
  /// **'Lexicon entry not yet implemented'**
  String get entryNotYetImplemented;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get error;

  /// No description provided for @errorCreatingPetition.
  ///
  /// In en, this message translates to:
  /// **'Error creating petition'**
  String get errorCreatingPetition;

  /// No description provided for @errorSendingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error sending email'**
  String get errorSendingEmail;

  /// No description provided for @errorUploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error uploading image'**
  String get errorUploadingImage;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @expiredCreations.
  ///
  /// In en, this message translates to:
  /// **'Expired creations'**
  String get expiredCreations;

  /// No description provided for @expiredPetitions.
  ///
  /// In en, this message translates to:
  /// **'Expired petitions'**
  String get expiredPetitions;

  /// No description provided for @expiredPolls.
  ///
  /// In en, this message translates to:
  /// **'Expired polls'**
  String get expiredPolls;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get expiresOn;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export created'**
  String get exportSuccess;

  /// No description provided for @failedToCreatePoll.
  ///
  /// In en, this message translates to:
  /// **'Failed to create poll'**
  String get failedToCreatePoll;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: '**
  String get failedToUploadImage;

  /// No description provided for @finalNotice.
  ///
  /// In en, this message translates to:
  /// **'Final notice'**
  String get finalNotice;

  /// No description provided for @finishedForms.
  ///
  /// In en, this message translates to:
  /// **'Finished forms'**
  String get finishedForms;

  /// No description provided for @flutterPro.
  ///
  /// In en, this message translates to:
  /// **'Flutter Pro'**
  String get flutterPro;

  /// No description provided for @flutterProEmail.
  ///
  /// In en, this message translates to:
  /// **'Flutter@pro.com'**
  String get flutterProEmail;

  /// No description provided for @freeMember.
  ///
  /// In en, this message translates to:
  /// **'Free Member'**
  String get freeMember;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @frontSide.
  ///
  /// In en, this message translates to:
  /// **'Front Side'**
  String get frontSide;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @givenName.
  ///
  /// In en, this message translates to:
  /// **'Given Name'**
  String get givenName;

  /// No description provided for @goProToAccessTheseBenefits.
  ///
  /// In en, this message translates to:
  /// **'Go pro to access these benefits'**
  String get goProToAccessTheseBenefits;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @growthStartsWithin.
  ///
  /// In en, this message translates to:
  /// **'Growth starts within'**
  String get growthStartsWithin;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// Initial welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome {firstName} {lastName}!'**
  String helloAndWelcome(String firstName, String lastName);

  /// No description provided for @hintTextTags.
  ///
  /// In en, this message translates to:
  /// **'e.g. environment, transport'**
  String get hintTextTags;

  /// No description provided for @idNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get idNumber;

  /// No description provided for @idScan.
  ///
  /// In en, this message translates to:
  /// **'ID Scan'**
  String get idScan;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// No description provided for @filterByGroup.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get filterByGroup;

  /// No description provided for @publishTo.
  ///
  /// In en, this message translates to:
  /// **'Publish to'**
  String get publishTo;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @createOrManageGroups.
  ///
  /// In en, this message translates to:
  /// **'Create or manage groups'**
  String get createOrManageGroups;

  /// No description provided for @displayQrCode.
  ///
  /// In en, this message translates to:
  /// **'Display QR code'**
  String get displayQrCode;

  /// No description provided for @accentPallette.
  ///
  /// In en, this message translates to:
  /// **'Accent Palette'**
  String get accentPallette;

  /// No description provided for @themePaletteForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themePaletteForest;

  /// No description provided for @themePaletteOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themePaletteOcean;

  /// No description provided for @themePaletteSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get themePaletteSunset;

  /// No description provided for @themePaletteRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get themePaletteRose;

  /// No description provided for @themePaletteAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themePaletteAmber;

  /// No description provided for @themePalettePlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get themePalettePlum;

  /// No description provided for @themePaletteSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get themePaletteSlate;

  /// No description provided for @themePaletteMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get themePaletteMint;

  /// No description provided for @themePaletteSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get themePaletteSky;

  /// No description provided for @themePaletteTrainvent.
  ///
  /// In en, this message translates to:
  /// **'Trainvent'**
  String get themePaletteTrainvent;

  /// No description provided for @imagePreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a preview of your new profile picture.'**
  String get imagePreviewDescription;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @invalidEmailEntered.
  ///
  /// In en, this message translates to:
  /// **'Invalid email entered'**
  String get invalidEmailEntered;

  /// No description provided for @isProMember.
  ///
  /// In en, this message translates to:
  /// **'Is Pro Member'**
  String get isProMember;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lastStep.
  ///
  /// In en, this message translates to:
  /// **'Last step!'**
  String get lastStep;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @livingAddress.
  ///
  /// In en, this message translates to:
  /// **'Living Address'**
  String get livingAddress;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Login code sent'**
  String get loginCodeSent;

  /// No description provided for @loginLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent!'**
  String get loginLinkSent;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @membershipStatus.
  ///
  /// In en, this message translates to:
  /// **'Membership Status'**
  String get membershipStatus;

  /// No description provided for @moreBenefitsToBeAddedLater.
  ///
  /// In en, this message translates to:
  /// **'More benefits to be added later'**
  String get moreBenefitsToBeAddedLater;

  /// No description provided for @myPetitions.
  ///
  /// In en, this message translates to:
  /// **'My Petitions'**
  String get myPetitions;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Name change failed'**
  String get nameChangeFailed;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// Number of new messages in inbox.
  ///
  /// In en, this message translates to:
  /// **'You have {newMessages, plural, =0{No new messages} =1 {One new message} two{Two new messages} other {{newMessages} new messages}}'**
  String newMessages(int newMessages);

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newUsername.
  ///
  /// In en, this message translates to:
  /// **'New username'**
  String get newUsername;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noActivityFound.
  ///
  /// In en, this message translates to:
  /// **'No activity found yet.'**
  String get noActivityFound;

  /// No description provided for @noAdvertisements.
  ///
  /// In en, this message translates to:
  /// **'No advertisements'**
  String get noAdvertisements;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noExpiredItems.
  ///
  /// In en, this message translates to:
  /// **'No expired items'**
  String get noExpiredItems;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @noOptions.
  ///
  /// In en, this message translates to:
  /// **'No options'**
  String get noOptions;

  /// No description provided for @noFittingOptions.
  ///
  /// In en, this message translates to:
  /// **'No fitting options'**
  String get noFittingOptions;

  /// No description provided for @noProMember.
  ///
  /// In en, this message translates to:
  /// **'Nein, kein Pro-Mitglied'**
  String get noProMember;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get noTitle;

  /// No description provided for @noUsernameFound.
  ///
  /// In en, this message translates to:
  /// **'No username found'**
  String get noUsernameFound;

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @notAvailableOnWebApp.
  ///
  /// In en, this message translates to:
  /// **'Not available on web, use mobile app'**
  String get notAvailableOnWebApp;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @notSignedUpYet.
  ///
  /// In en, this message translates to:
  /// **'Not signed up yet? Forgot password?'**
  String get notSignedUpYet;

  /// No description provided for @goToWelcome.
  ///
  /// In en, this message translates to:
  /// **'Go to Welcome'**
  String get goToWelcome;

  /// No description provided for @option.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get option;

  /// No description provided for @optionNumber.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String optionNumber(int number);

  /// No description provided for @optionRequired.
  ///
  /// In en, this message translates to:
  /// **'Option is required'**
  String get optionRequired;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @participantsList.
  ///
  /// In en, this message translates to:
  /// **'Participants List'**
  String get participantsList;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Password change failed'**
  String get passwordChangeFailed;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @paywallDescription.
  ///
  /// In en, this message translates to:
  /// **'Enjoy a more relaxed and diverse interface'**
  String get paywallDescription;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access to all functions'**
  String get paywallSubtitle;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a premium member'**
  String get paywallTitle;

  /// No description provided for @petition.
  ///
  /// In en, this message translates to:
  /// **'Petition'**
  String get petition;

  /// No description provided for @petitionBy.
  ///
  /// In en, this message translates to:
  /// **'Petition by'**
  String get petitionBy;

  /// No description provided for @petitionDetails.
  ///
  /// In en, this message translates to:
  /// **'Petition details'**
  String get petitionDetails;

  /// No description provided for @petitionSuccessfullySigned.
  ///
  /// In en, this message translates to:
  /// **'Petition successfully signed!'**
  String get petitionSuccessfullySigned;

  /// No description provided for @petitions.
  ///
  /// In en, this message translates to:
  /// **'Petitions'**
  String get petitions;

  /// No description provided for @placeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Place of Birth'**
  String get placeOfBirth;

  /// No description provided for @pleaseCheckYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please check your email'**
  String get pleaseCheckYourEmail;

  /// No description provided for @pleaseCheckYourInbox.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox and click the verification link.'**
  String get pleaseCheckYourInbox;

  /// No description provided for @pleaseSelectState.
  ///
  /// In en, this message translates to:
  /// **'Please select a state'**
  String get pleaseSelectState;

  /// No description provided for @pleaseSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get pleaseSignInFirst;

  /// No description provided for @pleaseUsePhoneToRegister.
  ///
  /// In en, this message translates to:
  /// **'Use your phone for registering, please'**
  String get pleaseUsePhoneToRegister;

  /// No description provided for @poll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// No description provided for @pollDetails.
  ///
  /// In en, this message translates to:
  /// **'Poll details'**
  String get pollDetails;

  /// No description provided for @polls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get polls;

  /// No description provided for @popularPetitions.
  ///
  /// In en, this message translates to:
  /// **'Popular Petitions'**
  String get popularPetitions;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get prioritySupport;

  /// No description provided for @removeAbusiveLanguageBeforePublishing.
  ///
  /// In en, this message translates to:
  /// **'Please remove abusive or objectionable language before publishing.'**
  String get removeAbusiveLanguageBeforePublishing;

  /// No description provided for @maximumPollOptionsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} options allowed'**
  String maximumPollOptionsAllowed(int count);

  /// No description provided for @communityRulesAcceptance.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and understand that StimmApp does not tolerate objectionable content or abusive behavior.'**
  String get communityRulesAcceptance;

  /// No description provided for @proMember.
  ///
  /// In en, this message translates to:
  /// **'Pro Member'**
  String get proMember;

  /// No description provided for @processId.
  ///
  /// In en, this message translates to:
  /// **'Process ID'**
  String get processId;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated'**
  String get profilePictureUpdated;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get purchaseCancelled;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed.'**
  String get purchaseFailed;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful!'**
  String get purchaseSuccessful;

  /// No description provided for @reasonsForSigning.
  ///
  /// In en, this message translates to:
  /// **'Reasons for signing'**
  String get reasonsForSigning;

  /// No description provided for @recentPetitions.
  ///
  /// In en, this message translates to:
  /// **'Recent Petitions'**
  String get recentPetitions;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerAccount.
  ///
  /// In en, this message translates to:
  /// **'Register Account'**
  String get registerAccount;

  /// No description provided for @registerHere.
  ///
  /// In en, this message translates to:
  /// **'Register here'**
  String get registerHere;

  /// No description provided for @relatedToState.
  ///
  /// In en, this message translates to:
  /// **'Related to {state}'**
  String relatedToState(String state);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @resendEmailCooldown.
  ///
  /// In en, this message translates to:
  /// **'Please wait before resending'**
  String get resendEmailCooldown;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Reset password code sent'**
  String get resetPasswordCodeSent;

  /// No description provided for @resetPasswordLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset password link sent'**
  String get resetPasswordLinkSent;

  /// No description provided for @resubscribe.
  ///
  /// In en, this message translates to:
  /// **'Resubscribe'**
  String get resubscribe;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @scanYourId.
  ///
  /// In en, this message translates to:
  /// **'Please scan your German ID card'**
  String get scanYourId;

  /// No description provided for @scannedData.
  ///
  /// In en, this message translates to:
  /// **'Scanned Data'**
  String get scannedData;

  /// No description provided for @searchTextField.
  ///
  /// In en, this message translates to:
  /// **'Schlagwort'**
  String get searchTextField;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get select;

  /// No description provided for @selectFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Select from Camera'**
  String get selectFromCamera;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @sendLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Log in with Code'**
  String get sendLoginLink;

  /// No description provided for @setUserDetails.
  ///
  /// In en, this message translates to:
  /// **'Set user details'**
  String get setUserDetails;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sharePetition.
  ///
  /// In en, this message translates to:
  /// **'Share Petition'**
  String get sharePetition;

  /// No description provided for @shareThisPetition.
  ///
  /// In en, this message translates to:
  /// **'Share this petition'**
  String get shareThisPetition;

  /// No description provided for @shareThis.
  ///
  /// In en, this message translates to:
  /// **'Share this'**
  String get shareThis;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @sign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get sign;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signPetition.
  ///
  /// In en, this message translates to:
  /// **'Sign Petition'**
  String get signPetition;

  /// No description provided for @signUpForPro.
  ///
  /// In en, this message translates to:
  /// **'Sign up for Pro'**
  String get signUpForPro;

  /// No description provided for @signatures.
  ///
  /// In en, this message translates to:
  /// **'Signatures'**
  String get signatures;

  /// No description provided for @signed.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get signed;

  /// No description provided for @signedOn.
  ///
  /// In en, this message translates to:
  /// **'Signed on '**
  String get signedOn;

  /// No description provided for @signedPetitions.
  ///
  /// In en, this message translates to:
  /// **'Signed Petitions'**
  String get signedPetitions;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scope;

  /// No description provided for @scopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get scopeGlobal;

  /// No description provided for @scopeEu.
  ///
  /// In en, this message translates to:
  /// **'EU'**
  String get scopeEu;

  /// No description provided for @scopeContinent.
  ///
  /// In en, this message translates to:
  /// **'Continent'**
  String get scopeContinent;

  /// No description provided for @scopeCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get scopeCountry;

  /// No description provided for @scopeStateRegion.
  ///
  /// In en, this message translates to:
  /// **'State / Region'**
  String get scopeStateRegion;

  /// No description provided for @scopeCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get scopeCity;

  /// No description provided for @town.
  ///
  /// In en, this message translates to:
  /// **'Town'**
  String get town;

  /// No description provided for @pleaseEnterTown.
  ///
  /// In en, this message translates to:
  /// **'Please enter a town'**
  String get pleaseEnterTown;

  /// No description provided for @euScopeOnlyForEuCountries.
  ///
  /// In en, this message translates to:
  /// **'EU scope is only available for EU countries'**
  String get euScopeOnlyForEuCountries;

  /// No description provided for @pleaseSetCountryInAddressFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set your country in your address first'**
  String get pleaseSetCountryInAddressFirst;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @stateDependent.
  ///
  /// In en, this message translates to:
  /// **'State dependent'**
  String get stateDependent;

  /// No description provided for @stateUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'State updated successfully'**
  String get stateUpdatedSuccessfully;

  /// No description provided for @stimmapp.
  ///
  /// In en, this message translates to:
  /// **'StimmApp'**
  String get stimmapp;

  /// No description provided for @subscriptionCancelledAccessWillRemainUntilExpiry.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled — access will remain until expiry'**
  String get subscriptionCancelledAccessWillRemainUntilExpiry;

  /// No description provided for @successfullyLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in'**
  String get successfullyLoggedIn;

  /// No description provided for @supporters.
  ///
  /// In en, this message translates to:
  /// **'Supporters'**
  String get supporters;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated tags'**
  String get tagsHint;

  /// No description provided for @tagsRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one tag is required'**
  String get tagsRequired;

  /// No description provided for @testingWidgetsHere.
  ///
  /// In en, this message translates to:
  /// **'Testing widgets here'**
  String get testingWidgetsHere;

  /// No description provided for @thankYouForSigning.
  ///
  /// In en, this message translates to:
  /// **'Thank you for signing!'**
  String get thankYouForSigning;

  /// No description provided for @theWelcomePhrase.
  ///
  /// In en, this message translates to:
  /// **'The ultimate way to share your opinion'**
  String get theWelcomePhrase;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @titleTooShort.
  ///
  /// In en, this message translates to:
  /// **'Title is too short'**
  String get titleTooShort;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @updateLivingAddress.
  ///
  /// In en, this message translates to:
  /// **'Change address'**
  String get updateLivingAddress;

  /// No description provided for @updateState.
  ///
  /// In en, this message translates to:
  /// **'Update state'**
  String get updateState;

  /// No description provided for @updateUsername.
  ///
  /// In en, this message translates to:
  /// **'Update username'**
  String get updateUsername;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @userNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'User not available'**
  String get userNotAvailable;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @userProfileVerified.
  ///
  /// In en, this message translates to:
  /// **'Userprofile Verified'**
  String get userProfileVerified;

  /// No description provided for @usernameChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Username change failed'**
  String get usernameChangeFailed;

  /// No description provided for @usernameChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Username changed successfully'**
  String get usernameChangedSuccessfully;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until: {date}'**
  String validUntil(String date);

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSent;

  /// No description provided for @verificationEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to {email}'**
  String verificationEmailSentTo(String email);

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victory;

  /// No description provided for @viewLicenses.
  ///
  /// In en, this message translates to:
  /// **'View licenses'**
  String get viewLicenses;

  /// No description provided for @viewParticipants.
  ///
  /// In en, this message translates to:
  /// **'View Participants'**
  String get viewParticipants;

  /// No description provided for @vote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get vote;

  /// No description provided for @voted.
  ///
  /// In en, this message translates to:
  /// **'Voted'**
  String get voted;

  /// No description provided for @requestLoginCode.
  ///
  /// In en, this message translates to:
  /// **'Request login code'**
  String get requestLoginCode;

  /// No description provided for @welcomeBackPleaseEnterYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please enter your details.'**
  String get welcomeBackPleaseEnterYourDetails;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to '**
  String get welcomeTo;

  /// No description provided for @welcomeToPro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pro!'**
  String get welcomeToPro;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get yesCancel;

  /// No description provided for @youSubscribedToFollowingBenefits.
  ///
  /// In en, this message translates to:
  /// **'You subscribed to following benefits'**
  String get youSubscribedToFollowingBenefits;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @welcomePleaseEnterYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Please enter your details.'**
  String get welcomePleaseEnterYourDetails;

  /// No description provided for @noUserFoundForThatEmail.
  ///
  /// In en, this message translates to:
  /// **'No user found for that email.'**
  String get noUserFoundForThatEmail;

  /// No description provided for @wrongPasswordProvided.
  ///
  /// In en, this message translates to:
  /// **'Wrong password provided.'**
  String get wrongPasswordProvided;

  /// No description provided for @anUnexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get anUnexpectedErrorOccurred;

  /// No description provided for @pleaseSignInToConfirmYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to confirm your identity.'**
  String get pleaseSignInToConfirmYourIdentity;

  /// No description provided for @thisActionWillPermanentlyDeleteYourAccountAndAllAssociated.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete your account and all associated data.'**
  String get thisActionWillPermanentlyDeleteYourAccountAndAllAssociated;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @permanentlyDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'PERMANENTLY DELETE ACCOUNT'**
  String get permanentlyDeleteAccount;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @pleaseEnterADateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please enter a date of birth'**
  String get pleaseEnterADateOfBirth;

  /// No description provided for @linkedinLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn link copied to clipboard'**
  String get linkedinLinkCopiedToClipboard;

  /// No description provided for @githubLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'GitHub link copied to clipboard'**
  String get githubLinkCopiedToClipboard;

  /// No description provided for @emailCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Email copied to clipboard'**
  String get emailCopiedToClipboard;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get noName;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @petitionTitleInUseAlready.
  ///
  /// In en, this message translates to:
  /// **'Petition title already in use'**
  String get petitionTitleInUseAlready;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @pleaseEnterAValid6digitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit code'**
  String get pleaseEnterAValid6digitCode;

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @verificationCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent!'**
  String get verificationCodeResent;

  /// No description provided for @failedToResendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code'**
  String get failedToResendCode;

  /// No description provided for @weHaveSentA6digitCodeToYourEmailPlease.
  ///
  /// In en, this message translates to:
  /// **'We have sent a 6-digit code to your email. Please enter it below.'**
  String get weHaveSentA6digitCodeToYourEmailPlease;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @unblockedUserSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get unblockedUserSuccessfully;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @faultyInput.
  ///
  /// In en, this message translates to:
  /// **'Faulty input'**
  String get faultyInput;

  /// No description provided for @weFailedToGetYourStatePleaseProofreadYourLivingaddress.
  ///
  /// In en, this message translates to:
  /// **'We failed to get your state, please proofread your living address.'**
  String get weFailedToGetYourStatePleaseProofreadYourLivingaddress;

  /// No description provided for @petitionGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Petition Guidelines'**
  String get petitionGuidelines;

  /// No description provided for @petitionGuidelineDescription.
  ///
  /// In en, this message translates to:
  /// **'Petition guideline description'**
  String get petitionGuidelineDescription;

  /// No description provided for @pollGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Poll Guidelines'**
  String get pollGuidelines;

  /// No description provided for @pollGuidelineDescription.
  ///
  /// In en, this message translates to:
  /// **'Poll guideline description'**
  String get pollGuidelineDescription;

  /// No description provided for @pleaseEnterYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter your details.'**
  String get pleaseEnterYourDetails;

  /// No description provided for @thisAppWasDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'This app was developed by'**
  String get thisAppWasDevelopedBy;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @publishedUnderTheGnuGeneralPublicLicenseV30.
  ///
  /// In en, this message translates to:
  /// **'Published under the GNU General Public License v3.0'**
  String get publishedUnderTheGnuGeneralPublicLicenseV30;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @tagEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get tagEnvironment;

  /// No description provided for @tagPolitics.
  ///
  /// In en, this message translates to:
  /// **'Politics'**
  String get tagPolitics;

  /// No description provided for @tagEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get tagEducation;

  /// No description provided for @tagHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get tagHealth;

  /// No description provided for @tagInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure'**
  String get tagInfrastructure;

  /// No description provided for @tagEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get tagEconomy;

  /// No description provided for @tagSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get tagSocial;

  /// No description provided for @tagTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get tagTechnology;

  /// No description provided for @tagCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get tagCulture;

  /// No description provided for @tagSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get tagSports;

  /// No description provided for @tagAnimalWelfare.
  ///
  /// In en, this message translates to:
  /// **'Animal Welfare'**
  String get tagAnimalWelfare;

  /// No description provided for @tagSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get tagSafety;

  /// No description provided for @tagTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get tagTraffic;

  /// No description provided for @tagHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get tagHousing;

  /// No description provided for @tagOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tagOther;

  /// No description provided for @pollTutorialStep1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Be crystal clear about the goal'**
  String get pollTutorialStep1Title;

  /// No description provided for @pollTutorialStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Know exactly what you want to learn — one idea only.'**
  String get pollTutorialStep1Desc;

  /// No description provided for @pollTutorialStep2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Use everyday language'**
  String get pollTutorialStep2Title;

  /// No description provided for @pollTutorialStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'No technical words. No jargon. No “smart-sounding” phrasing. If a teenager and a grandparent both understand it, it’s good.'**
  String get pollTutorialStep2Desc;

  /// No description provided for @pollTutorialStep3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Ask one short, easy to understand direct question'**
  String get pollTutorialStep3Title;

  /// No description provided for @pollTutorialStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Simple sentence. Simple structure.'**
  String get pollTutorialStep3Desc;

  /// No description provided for @pollTutorialStep4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Give fair choices'**
  String get pollTutorialStep4Title;

  /// No description provided for @pollTutorialStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'No trick answers. No emotional wording. No pushing people toward one option. Include “Not sure” if relevant.'**
  String get pollTutorialStep4Desc;

  /// No description provided for @pollTutorialStep5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Keep options few'**
  String get pollTutorialStep5Title;

  /// No description provided for @pollTutorialStep5Desc.
  ///
  /// In en, this message translates to:
  /// **'3–5 choices is perfect for public polls.'**
  String get pollTutorialStep5Desc;

  /// No description provided for @pollTutorialStep6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Make it fast to answer'**
  String get pollTutorialStep6Title;

  /// No description provided for @pollTutorialStep6Desc.
  ///
  /// In en, this message translates to:
  /// **'People should understand and vote in under 10 seconds.'**
  String get pollTutorialStep6Desc;

  /// No description provided for @pollTutorialStep7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Respect neutrality'**
  String get pollTutorialStep7Title;

  /// No description provided for @pollTutorialStep7Desc.
  ///
  /// In en, this message translates to:
  /// **'The poll must feel safe, non-judgmental, and unbiased.'**
  String get pollTutorialStep7Desc;

  /// No description provided for @petitionTutorialStep1.
  ///
  /// In en, this message translates to:
  /// **'The concern must be of general interest.'**
  String get petitionTutorialStep1;

  /// No description provided for @petitionTutorialStep2.
  ///
  /// In en, this message translates to:
  /// **'It must not contain any personal references.'**
  String get petitionTutorialStep2;

  /// No description provided for @petitionTutorialStep3.
  ///
  /// In en, this message translates to:
  /// **'The concern and justification must be formulated concisely and in a generally understandable manner.'**
  String get petitionTutorialStep3;

  /// No description provided for @petitionTutorialStep4.
  ///
  /// In en, this message translates to:
  /// **'Only topics where a factual discussion is expected will be published.'**
  String get petitionTutorialStep4;

  /// No description provided for @petitionTutorialStep5.
  ///
  /// In en, this message translates to:
  /// **'Upon reaching 30,000 signatures, the petitioner is granted the right to present their request in a public hearing.'**
  String get petitionTutorialStep5;

  /// No description provided for @limitThisPetitionToYourState.
  ///
  /// In en, this message translates to:
  /// **'Limit this petition to your state?'**
  String get limitThisPetitionToYourState;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @viewInstitutionalGuide.
  ///
  /// In en, this message translates to:
  /// **'View institutional guide'**
  String get viewInstitutionalGuide;

  /// No description provided for @pleaseEnterYourCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials'**
  String get pleaseEnterYourCredentials;

  /// No description provided for @pleaseEnterYourDesiredCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter the credentials you desire.'**
  String get pleaseEnterYourDesiredCredentials;

  /// No description provided for @sendConfirmationEmail.
  ///
  /// In en, this message translates to:
  /// **'Send confirmation email.'**
  String get sendConfirmationEmail;

  /// No description provided for @weCannotProvideSecureVerificationYetButWeAreWorking.
  ///
  /// In en, this message translates to:
  /// **'We cannot provide secure verification yet, but we are working on it.'**
  String get weCannotProvideSecureVerificationYetButWeAreWorking;

  /// No description provided for @passwordMustBeAtLeast8CharactersLong.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordMustBeAtLeast8CharactersLong;

  /// Password validation messages
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one {type, select, uppercase{uppercase letter} lowercase{lowercase letter} number{number} special{special character} other{valid character}}'**
  String passwordValidation(String type);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @areYouSureYouWantToClearThisDraft.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear this draft?'**
  String get areYouSureYouWantToClearThisDraft;

  /// No description provided for @sharingNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Sharing not supported on this platform.'**
  String get sharingNotSupported;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @privacyPolicyEssentialTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicyEssentialTitle;

  /// No description provided for @privacyPolicyEssentialDescription.
  ///
  /// In en, this message translates to:
  /// **'Essential information about how the app processes personal data.'**
  String get privacyPolicyEssentialDescription;

  /// No description provided for @adsConsentPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad consent for free use'**
  String get adsConsentPromptTitle;

  /// No description provided for @adsConsentPromptDescription.
  ///
  /// In en, this message translates to:
  /// **'StimmApp shows ads only to non-Pro users. In the EU, UK, and Switzerland, the free version is paused until you make the ad privacy choice required there. In other regions, ad privacy or consent choices may still apply depending on local law and provider requirements. You can change this choice later on the ad privacy page.'**
  String get adsConsentPromptDescription;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @neededForAds.
  ///
  /// In en, this message translates to:
  /// **'Needed for ads'**
  String get neededForAds;

  /// No description provided for @neededForAdsEnabledForFreeDescription.
  ///
  /// In en, this message translates to:
  /// **'Active for free accounts because ad-supported features may use cookies, local storage, or similar technologies.'**
  String get neededForAdsEnabledForFreeDescription;

  /// No description provided for @neededForAdsDisabledForProDescription.
  ///
  /// In en, this message translates to:
  /// **'Inactive while Pro is active because ads are disabled for Pro members.'**
  String get neededForAdsDisabledForProDescription;

  /// No description provided for @personalizedAds.
  ///
  /// In en, this message translates to:
  /// **'Ad consent for free use'**
  String get personalizedAds;

  /// No description provided for @personalizedAdsDescription.
  ///
  /// In en, this message translates to:
  /// **'Required for free users in the EU, UK, and Switzerland so the free tier can stay active there. In other regions, ad privacy or consent choices may still apply depending on local law and provider requirements. Turning this off logs you out and you will be asked again the next time you sign in.'**
  String get personalizedAdsDescription;

  /// No description provided for @adsCurrentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Ads are currently disabled'**
  String get adsCurrentlyDisabled;

  /// No description provided for @adsCurrentlyDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'We keep the free tier locked until you choose whether ad-related consent is allowed.'**
  String get adsCurrentlyDisabledDescription;

  /// No description provided for @adsDisabledForProDescription.
  ///
  /// In en, this message translates to:
  /// **'Pro members do not see ads, so ad consent is not required while Pro is active.'**
  String get adsDisabledForProDescription;

  /// No description provided for @adsConsentManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices'**
  String get adsConsentManagementTitle;

  /// No description provided for @adsConsentManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage whether the free version may use ad-related consent and cookies. Revoking this will lock the free app until you allow it again or switch to Pro.'**
  String get adsConsentManagementDescription;

  /// No description provided for @adsConsentRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent required for free use'**
  String get adsConsentRequiredTitle;

  /// No description provided for @adsConsentRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'To use the free version, you need to allow the ad-related consent described in our ads privacy policy.'**
  String get adsConsentRequiredDescription;

  /// No description provided for @adsConsentGrantedStatus.
  ///
  /// In en, this message translates to:
  /// **'Consent is currently granted.'**
  String get adsConsentGrantedStatus;

  /// No description provided for @adsConsentRevokedStatus.
  ///
  /// In en, this message translates to:
  /// **'Consent is currently revoked.'**
  String get adsConsentRevokedStatus;

  /// No description provided for @adsConsentStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Your decision is still pending.'**
  String get adsConsentStatusUnknown;

  /// No description provided for @adsConsentGrantedDetails.
  ///
  /// In en, this message translates to:
  /// **'You can revoke your choice here at any time. Revoking will immediately disable the free version until consent is granted again.'**
  String get adsConsentGrantedDetails;

  /// No description provided for @adsConsentRevokedDetails.
  ///
  /// In en, this message translates to:
  /// **'The free version stays locked until you allow ad-related consent again or subscribe to Pro.'**
  String get adsConsentRevokedDetails;

  /// No description provided for @adsConsentPendingDetails.
  ///
  /// In en, this message translates to:
  /// **'Please choose whether the free version may use ad-related consent before continuing.'**
  String get adsConsentPendingDetails;

  /// No description provided for @adsConsentRevokeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable free tier access?'**
  String get adsConsentRevokeDialogTitle;

  /// No description provided for @adsConsentRevokeDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'This consent is necessary for the free tier to function. If you disagree, you will be logged out now and asked again the next time you sign in.'**
  String get adsConsentRevokeDialogDescription;

  /// No description provided for @adsManagedInMobileAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy in mobile app'**
  String get adsManagedInMobileAppTitle;

  /// No description provided for @adsManagedInMobileAppDescription.
  ///
  /// In en, this message translates to:
  /// **'AdMob consent and ad-supported free-tier settings are managed only in the Android and iOS app, not on the web version.'**
  String get adsManagedInMobileAppDescription;

  /// No description provided for @openAdsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Open ads privacy policy'**
  String get openAdsPrivacyPolicy;

  /// No description provided for @allowCookiesAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Allow ad consent and continue'**
  String get allowCookiesAndContinue;

  /// No description provided for @revokeAdsConsent.
  ///
  /// In en, this message translates to:
  /// **'Revoke consent'**
  String get revokeAdsConsent;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to app'**
  String get continueToApp;

  /// No description provided for @analyticsData.
  ///
  /// In en, this message translates to:
  /// **'Analytics data'**
  String get analyticsData;

  /// No description provided for @analyticsDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow anonymous usage analytics so we can understand app usage and improve features over time.'**
  String get analyticsDataDescription;

  /// No description provided for @sendCrashLogs.
  ///
  /// In en, this message translates to:
  /// **'Send Crash Logs'**
  String get sendCrashLogs;

  /// No description provided for @sendCrashLogsDescription.
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app by automatically sending crash reports.'**
  String get sendCrashLogsDescription;

  /// No description provided for @reasonYourSignature.
  ///
  /// In en, this message translates to:
  /// **'Reason your signature'**
  String get reasonYourSignature;

  /// No description provided for @signatureReasoning.
  ///
  /// In en, this message translates to:
  /// **'Signature reasoning'**
  String get signatureReasoning;

  /// No description provided for @signatureReasoningInfo.
  ///
  /// In en, this message translates to:
  /// **'Activates commenting on your signatures and opinions before submitting.'**
  String get signatureReasoningInfo;

  /// No description provided for @whyAreYouSigning.
  ///
  /// In en, this message translates to:
  /// **'Why are you signing?'**
  String get whyAreYouSigning;

  /// No description provided for @enterYourReasonHere.
  ///
  /// In en, this message translates to:
  /// **'Enter your reason here...'**
  String get enterYourReasonHere;

  /// No description provided for @runningForms.
  ///
  /// In en, this message translates to:
  /// **'Running Forms'**
  String get runningForms;

  /// No description provided for @publications.
  ///
  /// In en, this message translates to:
  /// **'Publications'**
  String get publications;

  /// No description provided for @cannotDeletePetitionHasSignatures.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: Petition has signatures.'**
  String get cannotDeletePetitionHasSignatures;

  /// No description provided for @petitionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Petition deleted'**
  String get petitionDeleted;

  /// No description provided for @cannotDeletePollHasVotes.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: Poll has votes.'**
  String get cannotDeletePollHasVotes;

  /// No description provided for @pollDeleted.
  ///
  /// In en, this message translates to:
  /// **'Poll deleted'**
  String get pollDeleted;

  /// No description provided for @deleteForm.
  ///
  /// In en, this message translates to:
  /// **'Delete Form'**
  String get deleteForm;

  /// No description provided for @areYouSureYouWantToDeleteThisForm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this form?'**
  String get areYouSureYouWantToDeleteThisForm;

  /// No description provided for @noRunningPetitionsFound.
  ///
  /// In en, this message translates to:
  /// **'No running petitions found.'**
  String get noRunningPetitionsFound;

  /// No description provided for @noRunningPollsFound.
  ///
  /// In en, this message translates to:
  /// **'No running polls found.'**
  String get noRunningPollsFound;

  /// No description provided for @selectPaymentProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Provider'**
  String get selectPaymentProvider;

  /// No description provided for @communityRules.
  ///
  /// In en, this message translates to:
  /// **'Community Rules'**
  String get communityRules;

  /// No description provided for @communityRulesZeroTolerance.
  ///
  /// In en, this message translates to:
  /// **'StimmApp has zero tolerance for objectionable content, harassment, hate speech, sexual exploitation, or abusive users.'**
  String get communityRulesZeroTolerance;

  /// No description provided for @communityRulesAgreementNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the Terms of Service and confirm that you will only publish lawful, respectful content. Reported abusive content may be removed and abusive users may be suspended or permanently removed.'**
  String get communityRulesAgreementNotice;

  /// No description provided for @acceptCommunityRulesBeforeContinuing.
  ///
  /// In en, this message translates to:
  /// **'Please accept the community rules and terms before continuing.'**
  String get acceptCommunityRulesBeforeContinuing;

  /// No description provided for @openTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Open Terms of Service'**
  String get openTermsOfService;

  /// No description provided for @openPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Open Privacy Policy'**
  String get openPrivacyPolicy;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @removeAbusiveLanguageFromPublicName.
  ///
  /// In en, this message translates to:
  /// **'Please remove abusive or objectionable language from your public name.'**
  String get removeAbusiveLanguageFromPublicName;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get newUser;

  /// No description provided for @databaseError.
  ///
  /// In en, this message translates to:
  /// **'Database error ({code}): {message}'**
  String databaseError(String code, String message);

  /// No description provided for @unexpectedErrorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedErrorWithDetails(String error);

  /// No description provided for @couldNotSaveYourAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Could not save your acceptance: {error}'**
  String couldNotSaveYourAcceptance(String error);

  /// No description provided for @searchPoweredByTomTom.
  ///
  /// In en, this message translates to:
  /// **'Search powered by TomTom'**
  String get searchPoweredByTomTom;

  /// No description provided for @setTomTomApiKeyToEnableSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Set TOMTOM_SEARCH_API_KEY to enable address suggestions'**
  String get setTomTomApiKeyToEnableSuggestions;

  /// No description provided for @pleaseSelectAddressWithTown.
  ///
  /// In en, this message translates to:
  /// **'Please select an address with a town'**
  String get pleaseSelectAddressWithTown;

  /// No description provided for @detectedStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Detected state: {state}'**
  String detectedStateLabel(String state);

  /// No description provided for @scopeLabelWithValue.
  ///
  /// In en, this message translates to:
  /// **'Scope: {scope}'**
  String scopeLabelWithValue(String scope);

  /// No description provided for @groupLabelWithValue.
  ///
  /// In en, this message translates to:
  /// **'Group: {group}'**
  String groupLabelWithValue(String group);

  /// No description provided for @globalScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get globalScopeLabel;

  /// No description provided for @europeScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get europeScopeLabel;

  /// No description provided for @countryScopeFallback.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryScopeFallback;

  /// No description provided for @stateRegionScopeFallback.
  ///
  /// In en, this message translates to:
  /// **'State / Region'**
  String get stateRegionScopeFallback;

  /// No description provided for @cityScopeFallback.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityScopeFallback;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @scopeDetails.
  ///
  /// In en, this message translates to:
  /// **'Scope details'**
  String get scopeDetails;

  /// No description provided for @scopeAndGroup.
  ///
  /// In en, this message translates to:
  /// **'Scope and group'**
  String get scopeAndGroup;

  /// No description provided for @groupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsLabel;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroups;

  /// No description provided for @pleaseSignInToViewYourGroups.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your groups.'**
  String get pleaseSignInToViewYourGroups;

  /// No description provided for @failedToLoadYourGroups.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your groups.'**
  String get failedToLoadYourGroups;

  /// No description provided for @youAreNotMemberOfAnyGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'You are not a member of any groups yet.'**
  String get youAreNotMemberOfAnyGroupsYet;

  /// No description provided for @noExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get noExpiry;

  /// No description provided for @expiresOnDate.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOnDate(String date);

  /// No description provided for @creatorRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creatorRoleLabel;

  /// No description provided for @adminRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleLabel;

  /// No description provided for @memberRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberRoleLabel;

  /// No description provided for @groupAccessSummary.
  ///
  /// In en, this message translates to:
  /// **'Access: {accessMode} • Members: {memberCount} • {expiry}'**
  String groupAccessSummary(String accessMode, int memberCount, String expiry);

  /// No description provided for @swipeForDelete.
  ///
  /// In en, this message translates to:
  /// **'Swipe for delete.'**
  String get swipeForDelete;

  /// No description provided for @swipeToLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Swipe to leave the group.'**
  String get swipeToLeaveGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @doYouWantToLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave \"{groupName}\"?'**
  String doYouWantToLeaveGroup(String groupName);

  /// No description provided for @youLeftTheGroup.
  ///
  /// In en, this message translates to:
  /// **'You left the group.'**
  String get youLeftTheGroup;

  /// No description provided for @groupCreatorsCannotLeaveOwnGroup.
  ///
  /// In en, this message translates to:
  /// **'Group creators cannot leave their own group. Edit or delete it instead.'**
  String get groupCreatorsCannotLeaveOwnGroup;

  /// No description provided for @typeGroupNameToConfirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Type \"{groupName}\" to confirm deletion. This cannot be undone.'**
  String typeGroupNameToConfirmDeletion(String groupName);

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// No description provided for @groupNameDidNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Group name did not match.'**
  String get groupNameDidNotMatch;

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group deleted.'**
  String get groupDeleted;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @scanGroupQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan group QR code'**
  String get scanGroupQrCode;

  /// No description provided for @invalidGroupInviteQrCode.
  ///
  /// In en, this message translates to:
  /// **'This QR code does not contain a valid group invite.'**
  String get invalidGroupInviteQrCode;

  /// No description provided for @groupFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No joined or accepted groups available yet.'**
  String get groupFilterEmpty;

  /// No description provided for @allGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get allGroups;

  /// No description provided for @clearGroupFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear group filter'**
  String get clearGroupFilter;

  /// No description provided for @protectedAccessMode.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protectedAccessMode;

  /// No description provided for @openAccessMode.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAccessMode;

  /// No description provided for @completelyPrivateAccessMode.
  ///
  /// In en, this message translates to:
  /// **'Completely private'**
  String get completelyPrivateAccessMode;

  /// No description provided for @groupAccess.
  ///
  /// In en, this message translates to:
  /// **'Group access'**
  String get groupAccess;

  /// No description provided for @actionNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This action is no longer available.'**
  String get actionNoLongerAvailable;

  /// No description provided for @groupAccessAccepted.
  ///
  /// In en, this message translates to:
  /// **'Saved. Group access accepted.'**
  String get groupAccessAccepted;

  /// No description provided for @inviteDenied.
  ///
  /// In en, this message translates to:
  /// **'Invite denied.'**
  String get inviteDenied;

  /// No description provided for @aUser.
  ///
  /// In en, this message translates to:
  /// **'A user'**
  String get aUser;

  /// No description provided for @accessRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Access request sent.'**
  String get accessRequestSent;

  /// No description provided for @youJoinedTheGroup.
  ///
  /// In en, this message translates to:
  /// **'You joined the group.'**
  String get youJoinedTheGroup;

  /// No description provided for @approveRequest.
  ///
  /// In en, this message translates to:
  /// **'Approve request'**
  String get approveRequest;

  /// No description provided for @acceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Accept invite'**
  String get acceptInvite;

  /// No description provided for @denyRequest.
  ///
  /// In en, this message translates to:
  /// **'Deny request'**
  String get denyRequest;

  /// No description provided for @denyInvite.
  ///
  /// In en, this message translates to:
  /// **'Deny invite'**
  String get denyInvite;

  /// No description provided for @alreadyMemberOfGroup.
  ///
  /// In en, this message translates to:
  /// **'You are already a member of this group.'**
  String get alreadyMemberOfGroup;

  /// No description provided for @privateGroupWaitForInvite.
  ///
  /// In en, this message translates to:
  /// **'This group is completely private. Please wait for a direct invite from the group admins.'**
  String get privateGroupWaitForInvite;

  /// No description provided for @invalidProtectedInviteLink.
  ///
  /// In en, this message translates to:
  /// **'This invite link is not valid for the protected group.'**
  String get invalidProtectedInviteLink;

  /// No description provided for @requestAccess.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get requestAccess;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get joinGroup;

  /// No description provided for @groupAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Group access'**
  String get groupAccessTitle;

  /// No description provided for @invitedYouToThisGroup.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to this group.'**
  String invitedYouToThisGroup(String name);

  /// No description provided for @requestedAccessToThisGroup.
  ///
  /// In en, this message translates to:
  /// **'{name} requested access to this group.'**
  String requestedAccessToThisGroup(String name);

  /// No description provided for @accessModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Access mode: {mode}'**
  String accessModeLabel(String mode);

  /// No description provided for @protectedGroupsRequireInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Protected groups require a valid invite link and an approval request.'**
  String get protectedGroupsRequireInviteLink;

  /// No description provided for @openGroupsCanBeJoinedImmediately.
  ///
  /// In en, this message translates to:
  /// **'Open groups can be joined immediately.'**
  String get openGroupsCanBeJoinedImmediately;

  /// No description provided for @groupDetailsTemporarilyUnavailableRespond.
  ///
  /// In en, this message translates to:
  /// **'Group details are temporarily unavailable, but you can still respond to this notification.'**
  String get groupDetailsTemporarilyUnavailableRespond;

  /// No description provided for @groupDetailsTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Group details are temporarily unavailable.'**
  String get groupDetailsTemporarilyUnavailable;

  /// No description provided for @manageGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage groups'**
  String get manageGroupsTitle;

  /// No description provided for @pleaseSignInToManageGroups.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to manage groups.'**
  String get pleaseSignInToManageGroups;

  /// No description provided for @pickExistingGroupToUseOrEditOrCreateNewOne.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing group to use or edit, or create a new one.'**
  String get pickExistingGroupToUseOrEditOrCreateNewOne;

  /// No description provided for @createNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create new group'**
  String get createNewGroup;

  /// No description provided for @yourGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your groups'**
  String get yourGroupsTitle;

  /// No description provided for @noGroupsYetCreateOneAboveToStartTeamPolling.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Create one above to start team polling.'**
  String get noGroupsYetCreateOneAboveToStartTeamPolling;

  /// No description provided for @joinCodeWithValue.
  ///
  /// In en, this message translates to:
  /// **'Join code: {joinCode}'**
  String joinCodeWithValue(Object joinCode);

  /// No description provided for @expiresOnShort.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOnShort(Object date);

  /// No description provided for @importedMembersCount.
  ///
  /// In en, this message translates to:
  /// **'Imported members: {count}'**
  String importedMembersCount(Object count);

  /// No description provided for @inviteLinkOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link on'**
  String get inviteLinkOnLabel;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @keepSelected.
  ///
  /// In en, this message translates to:
  /// **'Keep selected'**
  String get keepSelected;

  /// No description provided for @useForThisPoll.
  ///
  /// In en, this message translates to:
  /// **'Use for this poll'**
  String get useForThisPoll;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @pleaseSignInToViewGroupInvitations.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view group invitations.'**
  String get pleaseSignInToViewGroupInvitations;

  /// No description provided for @noGroupNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No group notifications yet.'**
  String get noGroupNotificationsYet;

  /// No description provided for @notificationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get notificationStatusPending;

  /// No description provided for @notificationStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get notificationStatusAccepted;

  /// No description provided for @notificationStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get notificationStatusDenied;

  /// No description provided for @notificationActionInvitedYou.
  ///
  /// In en, this message translates to:
  /// **'invited you'**
  String get notificationActionInvitedYou;

  /// No description provided for @notificationActionRequestedAccess.
  ///
  /// In en, this message translates to:
  /// **'requested access'**
  String get notificationActionRequestedAccess;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get openApp;

  /// No description provided for @signInToJoinGroup.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join'**
  String get signInToJoinGroup;

  /// No description provided for @signInToRequestGroupAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign in to request access'**
  String get signInToRequestGroupAccess;

  /// No description provided for @protectedGroupsRequireApprovalRequest.
  ///
  /// In en, this message translates to:
  /// **'Protected groups require an approval request before you can join.'**
  String get protectedGroupsRequireApprovalRequest;

  /// No description provided for @signInToJoinGroupAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join this group automatically.'**
  String get signInToJoinGroupAutomatically;

  /// No description provided for @privateGroupOrSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'This group is private or requires sign-in before more details can be shown.'**
  String get privateGroupOrSignInRequired;

  /// No description provided for @createGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupTooltip;

  /// No description provided for @groupHasNoActiveInviteLink.
  ///
  /// In en, this message translates to:
  /// **'This group has no active invite link.'**
  String get groupHasNoActiveInviteLink;

  /// No description provided for @copyLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLinkLabel;

  /// No description provided for @copyInviteLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy invite link'**
  String get copyInviteLinkTooltip;

  /// No description provided for @pasteCsvMembers.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV members'**
  String get pasteCsvMembers;

  /// No description provided for @csvMembersHint.
  ///
  /// In en, this message translates to:
  /// **'email,nickname,role\nanna@company.com,Anna,user'**
  String get csvMembersHint;

  /// No description provided for @importLabel.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importLabel;

  /// No description provided for @noCsvRowsImported.
  ///
  /// In en, this message translates to:
  /// **'No CSV rows were imported.'**
  String get noCsvRowsImported;

  /// No description provided for @importedCsvRows.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} CSV rows.'**
  String importedCsvRows(Object count);

  /// No description provided for @importedRowsSkippedMalformed.
  ///
  /// In en, this message translates to:
  /// **'Imported {validRows} rows. Skipped {invalidRows} malformed rows.'**
  String importedRowsSkippedMalformed(Object validRows, Object invalidRows);

  /// No description provided for @pleaseEnterValidEmailForEveryInvitedMember.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email for every invited member.'**
  String get pleaseEnterValidEmailForEveryInvitedMember;

  /// No description provided for @pleaseEnterValidEmailDomains.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid email domains like company.com.'**
  String get pleaseEnterValidEmailDomains;

  /// No description provided for @pleaseEnterGroupName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a group name.'**
  String get pleaseEnterGroupName;

  /// No description provided for @groupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group updated.'**
  String get groupUpdated;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created.'**
  String get groupCreated;

  /// No description provided for @managerRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get managerRoleLabel;

  /// No description provided for @userRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userRoleLabel;

  /// No description provided for @onlyPreparedMembersCanParticipate.
  ///
  /// In en, this message translates to:
  /// **'Only members prepared by admins or managers can participate.'**
  String get onlyPreparedMembersCanParticipate;

  /// No description provided for @peopleWithInviteLinkCanRequestAccessToGroup.
  ///
  /// In en, this message translates to:
  /// **'People with the invite link can request access to the group.'**
  String get peopleWithInviteLinkCanRequestAccessToGroup;

  /// No description provided for @everyoneCanJoinWithoutApproval.
  ///
  /// In en, this message translates to:
  /// **'Everyone can join without approval.'**
  String get everyoneCanJoinWithoutApproval;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @removeMemberTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMemberTooltip;

  /// No description provided for @inviteMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get inviteMembersTitle;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @inviteMembersDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan A: add people one by one. Plan B: import CSV rows or drop a CSV file below. No emails are sent automatically.'**
  String get inviteMembersDescription;

  /// No description provided for @pasteCsvLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV'**
  String get pasteCsvLabel;

  /// No description provided for @importCsvFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Import CSV file'**
  String get importCsvFileLabel;

  /// No description provided for @dropCsvHere.
  ///
  /// In en, this message translates to:
  /// **'Drop a CSV here'**
  String get dropCsvHere;

  /// No description provided for @acceptedCsvFormat.
  ///
  /// In en, this message translates to:
  /// **'Accepted format: CSV or TSV with email,nickname,role'**
  String get acceptedCsvFormat;

  /// No description provided for @lastImportSummary.
  ///
  /// In en, this message translates to:
  /// **'Last import: {validRows} valid rows, {invalidRows} malformed rows.'**
  String lastImportSummary(Object validRows, Object invalidRows);

  /// No description provided for @allowedMailDomains.
  ///
  /// In en, this message translates to:
  /// **'Allowed mail domains'**
  String get allowedMailDomains;

  /// No description provided for @addDomain.
  ///
  /// In en, this message translates to:
  /// **'Add domain'**
  String get addDomain;

  /// No description provided for @allowedMailDomainsDescription.
  ///
  /// In en, this message translates to:
  /// **'Useful for companies: everyone with a matching email domain can be prepared with the chosen default role.'**
  String get allowedMailDomainsDescription;

  /// No description provided for @noDomainRulesYet.
  ///
  /// In en, this message translates to:
  /// **'No domain rules yet.'**
  String get noDomainRulesYet;

  /// No description provided for @domainLabel.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domainLabel;

  /// No description provided for @domainHint.
  ///
  /// In en, this message translates to:
  /// **'company.com'**
  String get domainHint;

  /// No description provided for @removeDomainTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove domain'**
  String get removeDomainTooltip;

  /// No description provided for @editGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroupTitle;

  /// No description provided for @createGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupTitle;

  /// No description provided for @editGroupDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust the access rules, invites, and settings for this group.'**
  String get editGroupDescription;

  /// No description provided for @createGroupDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a members-only polling space for teams, events, and companies.'**
  String get createGroupDescription;

  /// No description provided for @membersCanChooseTheirOwnNickname.
  ///
  /// In en, this message translates to:
  /// **'Members can choose their own nickname'**
  String get membersCanChooseTheirOwnNickname;

  /// No description provided for @managersCanPrepareAccessLists.
  ///
  /// In en, this message translates to:
  /// **'Managers can prepare access lists'**
  String get managersCanPrepareAccessLists;

  /// No description provided for @expirationDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Expiration date (optional)'**
  String get expirationDateOptional;

  /// No description provided for @noExpirationDateSet.
  ///
  /// In en, this message translates to:
  /// **'No expiration date set.'**
  String get noExpirationDateSet;

  /// No description provided for @setExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Set an expiration date'**
  String get setExpirationDate;

  /// No description provided for @pickExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Pick expiration date'**
  String get pickExpirationDate;

  /// No description provided for @savingGroup.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingGroup;

  /// No description provided for @creatingGroup.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingGroup;

  /// No description provided for @saveGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Save group'**
  String get saveGroupLabel;

  /// No description provided for @supportedRoles.
  ///
  /// In en, this message translates to:
  /// **'Supported roles: {admin}, {manager}, {user}.'**
  String supportedRoles(Object admin, Object manager, Object user);

  /// No description provided for @scanQrCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCodeTooltip;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

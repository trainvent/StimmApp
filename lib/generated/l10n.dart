// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Please enter your surname`
  String get pleaseEnterYourSurname {
    return Intl.message(
      'Please enter your surname',
      name: 'pleaseEnterYourSurname',
      desc: '',
      args: [],
    );
  }

  /// `displayed name`
  String get displayName {
    return Intl.message(
      'displayed name',
      name: 'displayName',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }

  /// `About this app`
  String get aboutThisApp {
    return Intl.message(
      'About this app',
      name: 'aboutThisApp',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get active {
    return Intl.message('Active', name: 'active', desc: '', args: []);
  }

  /// `Activity History`
  String get activityHistory {
    return Intl.message(
      'Activity History',
      name: 'activityHistory',
      desc: '',
      args: [],
    );
  }

  /// `Add a comment`
  String get addComment {
    return Intl.message(
      'Add a comment',
      name: 'addComment',
      desc: '',
      args: [],
    );
  }

  /// `Add Image`
  String get addImage {
    return Intl.message('Add Image', name: 'addImage', desc: '', args: []);
  }

  /// `Add option`
  String get addOption {
    return Intl.message('Add option', name: 'addOption', desc: '', args: []);
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `Address updated successfully`
  String get addressUpdatedSuccessfully {
    return Intl.message(
      'Address updated successfully',
      name: 'addressUpdatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Admin Dashboard`
  String get adminDashboard {
    return Intl.message(
      'Admin Dashboard',
      name: 'adminDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Admin Interface`
  String get adminInterface {
    return Intl.message(
      'Admin Interface',
      name: 'adminInterface',
      desc: '',
      args: [],
    );
  }

  /// `Alert`
  String get alert {
    return Intl.message('Alert', name: 'alert', desc: '', args: []);
  }

  /// `Anonymous`
  String get anonymous {
    return Intl.message('Anonymous', name: 'anonymous', desc: '', args: []);
  }

  /// `Are you sure you want to cancel your Pro subscription? You will lose Pro features.`
  String get areYouSureYouWantToCancelYourProSubscription {
    return Intl.message(
      'Are you sure you want to cancel your Pro subscription? You will lose Pro features.',
      name: 'areYouSureYouWantToCancelYourProSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this petition?`
  String get areYouSureYouWantToDeleteThisPetition {
    return Intl.message(
      'Are you sure you want to delete this petition?',
      name: 'areYouSureYouWantToDeleteThisPetition',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this poll?`
  String get areYouSureYouWantToDeleteThisPoll {
    return Intl.message(
      'Are you sure you want to delete this poll?',
      name: 'areYouSureYouWantToDeleteThisPoll',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this user?`
  String get areYouSureYouWantToDeleteThisUser {
    return Intl.message(
      'Are you sure you want to delete this user?',
      name: 'areYouSureYouWantToDeleteThisUser',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete your account?`
  String get areYouSureYouWantToDeleteYourAccount {
    return Intl.message(
      'Are you sure you want to delete your account?',
      name: 'areYouSureYouWantToDeleteYourAccount',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete your account? This action is irreversible`
  String get areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible {
    return Intl.message(
      'Are you sure you want to delete your account? This action is irreversible',
      name: 'areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to log out?`
  String get areYouSureYouWantToLogout {
    return Intl.message(
      'Are you sure you want to log out?',
      name: 'areYouSureYouWantToLogout',
      desc: '',
      args: [],
    );
  }

  /// `Back Side`
  String get backSide {
    return Intl.message('Back Side', name: 'backSide', desc: '', args: []);
  }

  /// `Back to Login`
  String get backToLogin {
    return Intl.message(
      'Back to Login',
      name: 'backToLogin',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Cancel Pro Subscription`
  String get cancelProSubscription {
    return Intl.message(
      'Cancel Pro Subscription',
      name: 'cancelProSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Cancel registration`
  String get cancelRegistration {
    return Intl.message(
      'Cancel registration',
      name: 'cancelRegistration',
      desc: '',
      args: [],
    );
  }

  /// `Cancel subscription`
  String get cancelSubscription {
    return Intl.message(
      'Cancel subscription',
      name: 'cancelSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Change Language`
  String get changeLanguage {
    return Intl.message(
      'Change Language',
      name: 'changeLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Change password`
  String get changePassword {
    return Intl.message(
      'Change password',
      name: 'changePassword',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message('Close', name: 'close', desc: '', args: []);
  }

  /// `Closed`
  String get closed {
    return Intl.message('Closed', name: 'closed', desc: '', args: []);
  }

  /// `Color Mode`
  String get colorMode {
    return Intl.message('Color Mode', name: 'colorMode', desc: '', args: []);
  }

  /// `Color Theme`
  String get colorTheme {
    return Intl.message('Color Theme', name: 'colorTheme', desc: '', args: []);
  }

  /// `Comments`
  String get comments {
    return Intl.message('Comments', name: 'comments', desc: '', args: []);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `Confirm & Finish`
  String get confirmAndFinish {
    return Intl.message(
      'Confirm & Finish',
      name: 'confirmAndFinish',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Password`
  String get confirmPassword {
    return Intl.message(
      'Confirm Password',
      name: 'confirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Confirmation Email Sent`
  String get confirmationEmailSent {
    return Intl.message(
      'Confirmation Email Sent',
      name: 'confirmationEmailSent',
      desc: '',
      args: [],
    );
  }

  /// `We have sent a confirmation email to your email address. Please check your inbox and follow the instructions to complete your registration.`
  String get confirmationEmailSentDescription {
    return Intl.message(
      'We have sent a confirmation email to your email address. Please check your inbox and follow the instructions to complete your registration.',
      name: 'confirmationEmailSentDescription',
      desc: '',
      args: [],
    );
  }

  /// `Consumption`
  String get consumption {
    return Intl.message('Consumption', name: 'consumption', desc: '', args: []);
  }

  /// `Continue`
  String get continueNext {
    return Intl.message('Continue', name: 'continueNext', desc: '', args: []);
  }

  /// `Continue`
  String get continueText {
    return Intl.message('Continue', name: 'continueText', desc: '', args: []);
  }

  /// `Could not open paywall`
  String get couldNotOpenPaywall {
    return Intl.message(
      'Could not open paywall',
      name: 'couldNotOpenPaywall',
      desc: '',
      args: [],
    );
  }

  /// `Create a new petition`
  String get createNewPetitionDescription {
    return Intl.message(
      'Create a new petition',
      name: 'createNewPetitionDescription',
      desc: '',
      args: [],
    );
  }

  /// `Create a new poll`
  String get createNewPollDescription {
    return Intl.message(
      'Create a new poll',
      name: 'createNewPollDescription',
      desc: '',
      args: [],
    );
  }

  /// `Create Petition`
  String get createPetition {
    return Intl.message(
      'Create Petition',
      name: 'createPetition',
      desc: '',
      args: [],
    );
  }

  /// `Create Poll`
  String get createPoll {
    return Intl.message('Create Poll', name: 'createPoll', desc: '', args: []);
  }

  /// `Petition created`
  String get createdPetition {
    return Intl.message(
      'Petition created',
      name: 'createdPetition',
      desc: '',
      args: [],
    );
  }

  /// `Poll created`
  String get createdPoll {
    return Intl.message(
      'Poll created',
      name: 'createdPoll',
      desc: '',
      args: [],
    );
  }

  /// `Creator`
  String get creator {
    return Intl.message('Creator', name: 'creator', desc: '', args: []);
  }

  /// `Current password`
  String get currentPassword {
    return Intl.message(
      'Current password',
      name: 'currentPassword',
      desc: '',
      args: [],
    );
  }

  /// `Custom petition and poll pictures`
  String get customPetitionAndPollPictures {
    return Intl.message(
      'Custom petition and poll pictures',
      name: 'customPetitionAndPollPictures',
      desc: '',
      args: [],
    );
  }

  /// `You can only publish one petition and one poll per day.`
  String get dailyCreateLimitReached {
    return Intl.message(
      'You can only publish one petition and one poll per day.',
      name: 'dailyCreateLimitReached',
      desc: '',
      args: [],
    );
  }

  /// `You can only publish one petition per day.`
  String get dailyCreatePetitionLimitReached {
    return Intl.message(
      'You can only publish one petition per day.',
      name: 'dailyCreatePetitionLimitReached',
      desc: '',
      args: [],
    );
  }

  /// `You can only publish one poll per day.`
  String get dailyCreatePollLimitReached {
    return Intl.message(
      'You can only publish one poll per day.',
      name: 'dailyCreatePollLimitReached',
      desc: '',
      args: [],
    );
  }

  /// `Daily habit`
  String get dailyHabit {
    return Intl.message('Daily habit', name: 'dailyHabit', desc: '', args: []);
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message('Dark Mode', name: 'darkMode', desc: '', args: []);
  }

  /// `Date of Birth`
  String get dateOfBirth {
    return Intl.message(
      'Date of Birth',
      name: 'dateOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `Days Left`
  String get daysLeft {
    return Intl.message('Days Left', name: 'daysLeft', desc: '', args: []);
  }

  /// `delete Account`
  String get deleteAccount {
    return Intl.message(
      'delete Account',
      name: 'deleteAccount',
      desc: '',
      args: [],
    );
  }

  /// `PERMANENTLY DELETE ACCOUNT`
  String get deleteAccountButton {
    return Intl.message(
      'PERMANENTLY DELETE ACCOUNT',
      name: 'deleteAccountButton',
      desc: '',
      args: [],
    );
  }

  /// `Please sign in to confirm your identity. This action will permanently delete your account and all associated data.`
  String get deleteAccountDescription {
    return Intl.message(
      'Please sign in to confirm your identity. This action will permanently delete your account and all associated data.',
      name: 'deleteAccountDescription',
      desc: '',
      args: [],
    );
  }

  /// `Account deleted successfully.`
  String get deleteAccountSuccess {
    return Intl.message(
      'Account deleted successfully.',
      name: 'deleteAccountSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Delete Your Account`
  String get deleteAccountTitle {
    return Intl.message(
      'Delete Your Account',
      name: 'deleteAccountTitle',
      desc: '',
      args: [],
    );
  }

  /// `An unexpected error occurred.`
  String get deleteAccountUnexpectedError {
    return Intl.message(
      'An unexpected error occurred.',
      name: 'deleteAccountUnexpectedError',
      desc: '',
      args: [],
    );
  }

  /// `No user found for that email.`
  String get deleteAccountUserNotFound {
    return Intl.message(
      'No user found for that email.',
      name: 'deleteAccountUserNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Wrong password provided.`
  String get deleteAccountWrongPassword {
    return Intl.message(
      'Wrong password provided.',
      name: 'deleteAccountWrongPassword',
      desc: '',
      args: [],
    );
  }

  /// `Delete my account`
  String get deleteMyAccount {
    return Intl.message(
      'Delete my account',
      name: 'deleteMyAccount',
      desc: '',
      args: [],
    );
  }

  /// `Delete Permanently`
  String get deletePermanently {
    return Intl.message(
      'Delete Permanently',
      name: 'deletePermanently',
      desc: '',
      args: [],
    );
  }

  /// `Delete Petition`
  String get deletePetition {
    return Intl.message(
      'Delete Petition',
      name: 'deletePetition',
      desc: '',
      args: [],
    );
  }

  /// `Delete Poll`
  String get deletePoll {
    return Intl.message('Delete Poll', name: 'deletePoll', desc: '', args: []);
  }

  /// `Delete User`
  String get deleteUser {
    return Intl.message('Delete User', name: 'deleteUser', desc: '', args: []);
  }

  /// `Deleted`
  String get deleted {
    return Intl.message('Deleted', name: 'deleted', desc: '', args: []);
  }

  /// `Description is required`
  String get descriptionRequired {
    return Intl.message(
      'Description is required',
      name: 'descriptionRequired',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message('Description', name: 'description', desc: '', args: []);
  }

  /// `Description is too short`
  String get descriptionTooShort {
    return Intl.message(
      'Description is too short',
      name: 'descriptionTooShort',
      desc: '',
      args: [],
    );
  }

  /// `This app is developed by Team LeEd with help of yannic`
  String get devContactInformation {
    return Intl.message(
      'This app is developed by Team LeEd with help of yannic',
      name: 'devContactInformation',
      desc: '',
      args: [],
    );
  }

  /// `Developer Sandbox`
  String get developerSandbox {
    return Intl.message(
      'Developer Sandbox',
      name: 'developerSandbox',
      desc: '',
      args: [],
    );
  }

  /// `Edit Petition`
  String get editPetition {
    return Intl.message(
      'Edit Petition',
      name: 'editPetition',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Email verification`
  String get emailVerification {
    return Intl.message(
      'Email verification',
      name: 'emailVerification',
      desc: '',
      args: [],
    );
  }

  /// `Email verified successfully!`
  String get emailVerifiedSuccessfully {
    return Intl.message(
      'Email verified successfully!',
      name: 'emailVerifiedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Energy`
  String get energy {
    return Intl.message('Energy', name: 'energy', desc: '', args: []);
  }

  /// `english`
  String get english {
    return Intl.message('english', name: 'english', desc: '', args: []);
  }

  /// `Enter Code`
  String get enterCode {
    return Intl.message('Enter Code', name: 'enterCode', desc: '', args: []);
  }

  /// `Enter description`
  String get enterDescription {
    return Intl.message(
      'Enter description',
      name: 'enterDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter something`
  String get enterSomething {
    return Intl.message(
      'Enter something',
      name: 'enterSomething',
      desc: '',
      args: [],
    );
  }

  /// `Enter title`
  String get enterTitle {
    return Intl.message('Enter title', name: 'enterTitle', desc: '', args: []);
  }

  /// `enter Your Address`
  String get enterYourAddress {
    return Intl.message(
      'enter Your Address',
      name: 'enterYourAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get enterYourEmail {
    return Intl.message(
      'Enter your email',
      name: 'enterYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Lexicon entry not yet implemented`
  String get entryNotYetImplemented {
    return Intl.message(
      'Lexicon entry not yet implemented',
      name: 'entryNotYetImplemented',
      desc: '',
      args: [],
    );
  }

  /// `Error: `
  String get error {
    return Intl.message('Error: ', name: 'error', desc: '', args: []);
  }

  /// `Error creating petition`
  String get errorCreatingPetition {
    return Intl.message(
      'Error creating petition',
      name: 'errorCreatingPetition',
      desc: '',
      args: [],
    );
  }

  /// `Error sending email`
  String get errorSendingEmail {
    return Intl.message(
      'Error sending email',
      name: 'errorSendingEmail',
      desc: '',
      args: [],
    );
  }

  /// `Error uploading image`
  String get errorUploadingImage {
    return Intl.message(
      'Error uploading image',
      name: 'errorUploadingImage',
      desc: '',
      args: [],
    );
  }

  /// `Errors`
  String get errors {
    return Intl.message('Errors', name: 'errors', desc: '', args: []);
  }

  /// `Exercise`
  String get exercise {
    return Intl.message('Exercise', name: 'exercise', desc: '', args: []);
  }

  /// `Expired creations`
  String get expiredCreations {
    return Intl.message(
      'Expired creations',
      name: 'expiredCreations',
      desc: '',
      args: [],
    );
  }

  /// `Expired petitions`
  String get expiredPetitions {
    return Intl.message(
      'Expired petitions',
      name: 'expiredPetitions',
      desc: '',
      args: [],
    );
  }

  /// `Expired polls`
  String get expiredPolls {
    return Intl.message(
      'Expired polls',
      name: 'expiredPolls',
      desc: '',
      args: [],
    );
  }

  /// `Expires on`
  String get expiresOn {
    return Intl.message('Expires on', name: 'expiresOn', desc: '', args: []);
  }

  /// `Expiry Date`
  String get expiryDate {
    return Intl.message('Expiry Date', name: 'expiryDate', desc: '', args: []);
  }

  /// `Explore`
  String get explore {
    return Intl.message('Explore', name: 'explore', desc: '', args: []);
  }

  /// `Export CSV`
  String get exportCsv {
    return Intl.message('Export CSV', name: 'exportCsv', desc: '', args: []);
  }

  /// `Export failed`
  String get exportFailed {
    return Intl.message(
      'Export failed',
      name: 'exportFailed',
      desc: '',
      args: [],
    );
  }

  /// `Export created`
  String get exportSuccess {
    return Intl.message(
      'Export created',
      name: 'exportSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Failed to create poll`
  String get failedToCreatePoll {
    return Intl.message(
      'Failed to create poll',
      name: 'failedToCreatePoll',
      desc: '',
      args: [],
    );
  }

  /// `Failed to upload image: `
  String get failedToUploadImage {
    return Intl.message(
      'Failed to upload image: ',
      name: 'failedToUploadImage',
      desc: '',
      args: [],
    );
  }

  /// `Final notice`
  String get finalNotice {
    return Intl.message(
      'Final notice',
      name: 'finalNotice',
      desc: '',
      args: [],
    );
  }

  /// `Finished forms`
  String get finishedForms {
    return Intl.message(
      'Finished forms',
      name: 'finishedForms',
      desc: '',
      args: [],
    );
  }

  /// `Flutter Pro`
  String get flutterPro {
    return Intl.message('Flutter Pro', name: 'flutterPro', desc: '', args: []);
  }

  /// `Flutter@pro.com`
  String get flutterProEmail {
    return Intl.message(
      'Flutter@pro.com',
      name: 'flutterProEmail',
      desc: '',
      args: [],
    );
  }

  /// `Free Member`
  String get freeMember {
    return Intl.message('Free Member', name: 'freeMember', desc: '', args: []);
  }

  /// `french`
  String get french {
    return Intl.message('french', name: 'french', desc: '', args: []);
  }

  /// `Front Side`
  String get frontSide {
    return Intl.message('Front Side', name: 'frontSide', desc: '', args: []);
  }

  /// `german`
  String get german {
    return Intl.message('german', name: 'german', desc: '', args: []);
  }

  /// `Get started`
  String get getStarted {
    return Intl.message('Get started', name: 'getStarted', desc: '', args: []);
  }

  /// `Given Name`
  String get givenName {
    return Intl.message('Given Name', name: 'givenName', desc: '', args: []);
  }

  /// `Go pro to access these benefits`
  String get goProToAccessTheseBenefits {
    return Intl.message(
      'Go pro to access these benefits',
      name: 'goProToAccessTheseBenefits',
      desc: '',
      args: [],
    );
  }

  /// `Goal`
  String get goal {
    return Intl.message('Goal', name: 'goal', desc: '', args: []);
  }

  /// `Growth starts within`
  String get growthStartsWithin {
    return Intl.message(
      'Growth starts within',
      name: 'growthStartsWithin',
      desc: '',
      args: [],
    );
  }

  /// `Height`
  String get height {
    return Intl.message('Height', name: 'height', desc: '', args: []);
  }

  /// `Welcome {firstName} {lastName}!`
  String helloAndWelcome(String firstName, String lastName) {
    return Intl.message(
      'Welcome $firstName $lastName!',
      name: 'helloAndWelcome',
      desc: 'Initial welcome message',
      args: [firstName, lastName],
    );
  }

  /// `e.g. environment, transport`
  String get hintTextTags {
    return Intl.message(
      'e.g. environment, transport',
      name: 'hintTextTags',
      desc: '',
      args: [],
    );
  }

  /// `ID Number`
  String get idNumber {
    return Intl.message('ID Number', name: 'idNumber', desc: '', args: []);
  }

  /// `ID Scan`
  String get idScan {
    return Intl.message('ID Scan', name: 'idScan', desc: '', args: []);
  }

  /// `This is a preview of your new profile picture.`
  String get imagePreviewDescription {
    return Intl.message(
      'This is a preview of your new profile picture.',
      name: 'imagePreviewDescription',
      desc: '',
      args: [],
    );
  }

  /// `Inactive`
  String get inactive {
    return Intl.message('Inactive', name: 'inactive', desc: '', args: []);
  }

  /// `Invalid email entered`
  String get invalidEmailEntered {
    return Intl.message(
      'Invalid email entered',
      name: 'invalidEmailEntered',
      desc: '',
      args: [],
    );
  }

  /// `Ist Pro-Mitglied`
  String get isProMember {
    return Intl.message(
      'Ist Pro-Mitglied',
      name: 'isProMember',
      desc: '',
      args: [],
    );
  }

  /// `language`
  String get language {
    return Intl.message('language', name: 'language', desc: '', args: []);
  }

  /// `Last step!`
  String get lastStep {
    return Intl.message('Last step!', name: 'lastStep', desc: '', args: []);
  }

  /// `Light Mode`
  String get lightMode {
    return Intl.message('Light Mode', name: 'lightMode', desc: '', args: []);
  }

  /// `Living Address`
  String get livingAddress {
    return Intl.message(
      'Living Address',
      name: 'livingAddress',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `login code sent`
  String get loginCodeSent {
    return Intl.message(
      'login code sent',
      name: 'loginCodeSent',
      desc: '',
      args: [],
    );
  }

  /// `Code sent!`
  String get loginLinkSent {
    return Intl.message(
      'Code sent!',
      name: 'loginLinkSent',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Membership Status`
  String get membershipStatus {
    return Intl.message(
      'Membership Status',
      name: 'membershipStatus',
      desc: '',
      args: [],
    );
  }

  /// `More benefits to be added later`
  String get moreBenefitsToBeAddedLater {
    return Intl.message(
      'More benefits to be added later',
      name: 'moreBenefitsToBeAddedLater',
      desc: '',
      args: [],
    );
  }

  /// `My Petitions`
  String get myPetitions {
    return Intl.message(
      'My Petitions',
      name: 'myPetitions',
      desc: '',
      args: [],
    );
  }

  /// `My Profile`
  String get myProfile {
    return Intl.message('My Profile', name: 'myProfile', desc: '', args: []);
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `Name change failed`
  String get nameChangeFailed {
    return Intl.message(
      'Name change failed',
      name: 'nameChangeFailed',
      desc: '',
      args: [],
    );
  }

  /// `Nationality`
  String get nationality {
    return Intl.message('Nationality', name: 'nationality', desc: '', args: []);
  }

  /// `You have {newMessages, plural, =0{No new messages} =1 {One new message} two{Two new Messages} other {{newMessages} new messages}}`
  String newMessages(int newMessages) {
    return Intl.message(
      'You have ${Intl.plural(newMessages, zero: 'No new messages', one: 'One new message', two: 'Two new Messages', other: '$newMessages new messages')}',
      name: 'newMessages',
      desc: 'Number of new messages in inbox.',
      args: [newMessages],
    );
  }

  /// `New password`
  String get newPassword {
    return Intl.message(
      'New password',
      name: 'newPassword',
      desc: '',
      args: [],
    );
  }

  /// `New username`
  String get newUsername {
    return Intl.message(
      'New username',
      name: 'newUsername',
      desc: '',
      args: [],
    );
  }

  /// `Nickname`
  String get nickname {
    return Intl.message('Nickname', name: 'nickname', desc: '', args: []);
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `No activity found yet.`
  String get noActivityFound {
    return Intl.message(
      'No activity found yet.',
      name: 'noActivityFound',
      desc: '',
      args: [],
    );
  }

  /// `No advertisements`
  String get noAdvertisements {
    return Intl.message(
      'No advertisements',
      name: 'noAdvertisements',
      desc: '',
      args: [],
    );
  }

  /// `No data`
  String get noData {
    return Intl.message('No data', name: 'noData', desc: '', args: []);
  }

  /// `No expired items`
  String get noExpiredItems {
    return Intl.message(
      'No expired items',
      name: 'noExpiredItems',
      desc: '',
      args: [],
    );
  }

  /// `No image selected`
  String get noImageSelected {
    return Intl.message(
      'No image selected',
      name: 'noImageSelected',
      desc: '',
      args: [],
    );
  }

  /// `no options`
  String get noOptions {
    return Intl.message('no options', name: 'noOptions', desc: '', args: []);
  }

  /// `Nein, kein Pro-Mitglied`
  String get noProMember {
    return Intl.message(
      'Nein, kein Pro-Mitglied',
      name: 'noProMember',
      desc: '',
      args: [],
    );
  }

  /// `No Title`
  String get noTitle {
    return Intl.message('No Title', name: 'noTitle', desc: '', args: []);
  }

  /// `no username found`
  String get noUsernameFound {
    return Intl.message(
      'no username found',
      name: 'noUsernameFound',
      desc: '',
      args: [],
    );
  }

  /// `Not authenticated`
  String get notAuthenticated {
    return Intl.message(
      'Not authenticated',
      name: 'notAuthenticated',
      desc: '',
      args: [],
    );
  }

  /// `Not available on web, use mobile app`
  String get notAvailableOnWebApp {
    return Intl.message(
      'Not available on web, use mobile app',
      name: 'notAvailableOnWebApp',
      desc: '',
      args: [],
    );
  }

  /// `Not found`
  String get notFound {
    return Intl.message('Not found', name: 'notFound', desc: '', args: []);
  }

  /// `Option`
  String get option {
    return Intl.message('Option', name: 'option', desc: '', args: []);
  }

  /// `Option is required`
  String get optionRequired {
    return Intl.message(
      'Option is required',
      name: 'optionRequired',
      desc: '',
      args: [],
    );
  }

  /// `Options`
  String get options {
    return Intl.message('Options', name: 'options', desc: '', args: []);
  }

  /// `other`
  String get other {
    return Intl.message('other', name: 'other', desc: '', args: []);
  }

  /// `Participants`
  String get participants {
    return Intl.message(
      'Participants',
      name: 'participants',
      desc: '',
      args: [],
    );
  }

  /// `Participants List`
  String get participantsList {
    return Intl.message(
      'Participants List',
      name: 'participantsList',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Password change failed`
  String get passwordChangeFailed {
    return Intl.message(
      'Password change failed',
      name: 'passwordChangeFailed',
      desc: '',
      args: [],
    );
  }

  /// `Password changed successfully`
  String get passwordChangedSuccessfully {
    return Intl.message(
      'Password changed successfully',
      name: 'passwordChangedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match`
  String get passwordsDoNotMatch {
    return Intl.message(
      'Passwords do not match',
      name: 'passwordsDoNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `Enjoy a more relaxed and diverse interface`
  String get paywallDescription {
    return Intl.message(
      'Enjoy a more relaxed and diverse interface',
      name: 'paywallDescription',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited access to all functions`
  String get paywallSubtitle {
    return Intl.message(
      'Unlimited access to all functions',
      name: 'paywallSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Become a premium member`
  String get paywallTitle {
    return Intl.message(
      'Become a premium member',
      name: 'paywallTitle',
      desc: '',
      args: [],
    );
  }

  /// `Petition`
  String get petition {
    return Intl.message('Petition', name: 'petition', desc: '', args: []);
  }

  /// `Petition by`
  String get petitionBy {
    return Intl.message('Petition by', name: 'petitionBy', desc: '', args: []);
  }

  /// `Petition details`
  String get petitionDetails {
    return Intl.message(
      'Petition details',
      name: 'petitionDetails',
      desc: '',
      args: [],
    );
  }

  /// `Petition successfully signed!`
  String get petitionSuccessfullySigned {
    return Intl.message(
      'Petition successfully signed!',
      name: 'petitionSuccessfullySigned',
      desc: '',
      args: [],
    );
  }

  /// `Petitions`
  String get petitions {
    return Intl.message('Petitions', name: 'petitions', desc: '', args: []);
  }

  /// `Place of Birth`
  String get placeOfBirth {
    return Intl.message(
      'Place of Birth',
      name: 'placeOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `Please check your email`
  String get pleaseCheckYourEmail {
    return Intl.message(
      'Please check your email',
      name: 'pleaseCheckYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Please check your inbox and click the verification link.`
  String get pleaseCheckYourInbox {
    return Intl.message(
      'Please check your inbox and click the verification link.',
      name: 'pleaseCheckYourInbox',
      desc: '',
      args: [],
    );
  }

  /// `Please select a state`
  String get pleaseSelectState {
    return Intl.message(
      'Please select a state',
      name: 'pleaseSelectState',
      desc: '',
      args: [],
    );
  }

  /// `Please sign in first`
  String get pleaseSignInFirst {
    return Intl.message(
      'Please sign in first',
      name: 'pleaseSignInFirst',
      desc: '',
      args: [],
    );
  }

  /// `Use your phone for registering, please`
  String get pleaseUsePhoneToRegister {
    return Intl.message(
      'Use your phone for registering, please',
      name: 'pleaseUsePhoneToRegister',
      desc: '',
      args: [],
    );
  }

  /// `Poll`
  String get poll {
    return Intl.message('Poll', name: 'poll', desc: '', args: []);
  }

  /// `Poll details`
  String get pollDetails {
    return Intl.message(
      'Poll details',
      name: 'pollDetails',
      desc: '',
      args: [],
    );
  }

  /// `Polls`
  String get polls {
    return Intl.message('Polls', name: 'polls', desc: '', args: []);
  }

  /// `Popular Petitions`
  String get popularPetitions {
    return Intl.message(
      'Popular Petitions',
      name: 'popularPetitions',
      desc: '',
      args: [],
    );
  }

  /// `Priority support`
  String get prioritySupport {
    return Intl.message(
      'Priority support',
      name: 'prioritySupport',
      desc: '',
      args: [],
    );
  }

  /// `Pro Member`
  String get proMember {
    return Intl.message('Pro Member', name: 'proMember', desc: '', args: []);
  }

  /// `Process ID`
  String get processId {
    return Intl.message('Process ID', name: 'processId', desc: '', args: []);
  }

  /// `Products`
  String get products {
    return Intl.message('Products', name: 'products', desc: '', args: []);
  }

  /// `Profile`
  String get profile {
    return Intl.message('Profile', name: 'profile', desc: '', args: []);
  }

  /// `Profile picture updated`
  String get profilePictureUpdated {
    return Intl.message(
      'Profile picture updated',
      name: 'profilePictureUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Purchase cancelled.`
  String get purchaseCancelled {
    return Intl.message(
      'Purchase cancelled.',
      name: 'purchaseCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Purchase failed.`
  String get purchaseFailed {
    return Intl.message(
      'Purchase failed.',
      name: 'purchaseFailed',
      desc: '',
      args: [],
    );
  }

  /// `Purchase successful!`
  String get purchaseSuccessful {
    return Intl.message(
      'Purchase successful!',
      name: 'purchaseSuccessful',
      desc: '',
      args: [],
    );
  }

  /// `Reasons for signing`
  String get reasonsForSigning {
    return Intl.message(
      'Reasons for signing',
      name: 'reasonsForSigning',
      desc: '',
      args: [],
    );
  }

  /// `Recent Petitions`
  String get recentPetitions {
    return Intl.message(
      'Recent Petitions',
      name: 'recentPetitions',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message('Register', name: 'register', desc: '', args: []);
  }

  /// `Register Account`
  String get registerAccount {
    return Intl.message(
      'Register Account',
      name: 'registerAccount',
      desc: '',
      args: [],
    );
  }

  /// `Register here`
  String get registerHere {
    return Intl.message(
      'Register here',
      name: 'registerHere',
      desc: '',
      args: [],
    );
  }

  /// `Related to {state}`
  String relatedToState(String state) {
    return Intl.message(
      'Related to $state',
      name: 'relatedToState',
      desc: '',
      args: [state],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message('Remove', name: 'remove', desc: '', args: []);
  }

  /// `Resend Email`
  String get resendEmail {
    return Intl.message(
      'Resend Email',
      name: 'resendEmail',
      desc: '',
      args: [],
    );
  }

  /// `Please wait before resending`
  String get resendEmailCooldown {
    return Intl.message(
      'Please wait before resending',
      name: 'resendEmailCooldown',
      desc: '',
      args: [],
    );
  }

  /// `Resend verification email`
  String get resendVerificationEmail {
    return Intl.message(
      'Resend verification email',
      name: 'resendVerificationEmail',
      desc: '',
      args: [],
    );
  }

  /// `Reset password`
  String get resetPassword {
    return Intl.message(
      'Reset password',
      name: 'resetPassword',
      desc: '',
      args: [],
    );
  }

  /// `Reset password code sent`
  String get resetPasswordCodeSent {
    return Intl.message(
      'Reset password code sent',
      name: 'resetPasswordCodeSent',
      desc: '',
      args: [],
    );
  }

  /// `Reset password link sent`
  String get resetPasswordLinkSent {
    return Intl.message(
      'Reset password link sent',
      name: 'resetPasswordLinkSent',
      desc: '',
      args: [],
    );
  }

  /// `Resubscribe`
  String get resubscribe {
    return Intl.message('Resubscribe', name: 'resubscribe', desc: '', args: []);
  }

  /// `Result`
  String get result {
    return Intl.message('Result', name: 'result', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Scan Again`
  String get scanAgain {
    return Intl.message('Scan Again', name: 'scanAgain', desc: '', args: []);
  }

  /// `Please scan your German ID card`
  String get scanYourId {
    return Intl.message(
      'Please scan your German ID card',
      name: 'scanYourId',
      desc: '',
      args: [],
    );
  }

  /// `Scanned Data`
  String get scannedData {
    return Intl.message(
      'Scanned Data',
      name: 'scannedData',
      desc: '',
      args: [],
    );
  }

  /// `Schlagwort`
  String get searchTextField {
    return Intl.message(
      'Schlagwort',
      name: 'searchTextField',
      desc: '',
      args: [],
    );
  }

  /// `Pick`
  String get select {
    return Intl.message('Pick', name: 'select', desc: '', args: []);
  }

  /// `Select from Camera`
  String get selectFromCamera {
    return Intl.message(
      'Select from Camera',
      name: 'selectFromCamera',
      desc: '',
      args: [],
    );
  }

  /// `Select from Gallery`
  String get selectFromGallery {
    return Intl.message(
      'Select from Gallery',
      name: 'selectFromGallery',
      desc: '',
      args: [],
    );
  }

  /// `Log in with Code`
  String get sendLoginLink {
    return Intl.message(
      'Log in with Code',
      name: 'sendLoginLink',
      desc: '',
      args: [],
    );
  }

  /// `Set user details`
  String get setUserDetails {
    return Intl.message(
      'Set user details',
      name: 'setUserDetails',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Share Petition`
  String get sharePetition {
    return Intl.message(
      'Share Petition',
      name: 'sharePetition',
      desc: '',
      args: [],
    );
  }

  /// `Share this petition`
  String get shareThisPetition {
    return Intl.message(
      'Share this petition',
      name: 'shareThisPetition',
      desc: '',
      args: [],
    );
  }

  /// `Sign`
  String get sign {
    return Intl.message('Sign', name: 'sign', desc: '', args: []);
  }

  /// `Sign in`
  String get signIn {
    return Intl.message('Sign in', name: 'signIn', desc: '', args: []);
  }

  /// `Sign Petition`
  String get signPetition {
    return Intl.message(
      'Sign Petition',
      name: 'signPetition',
      desc: '',
      args: [],
    );
  }

  /// `Sign up for Pro`
  String get signUpForPro {
    return Intl.message(
      'Sign up for Pro',
      name: 'signUpForPro',
      desc: '',
      args: [],
    );
  }

  /// `Signatures`
  String get signatures {
    return Intl.message('Signatures', name: 'signatures', desc: '', args: []);
  }

  /// `Signed`
  String get signed {
    return Intl.message('Signed', name: 'signed', desc: '', args: []);
  }

  /// `Signed on `
  String get signedOn {
    return Intl.message('Signed on ', name: 'signedOn', desc: '', args: []);
  }

  /// `Signed Petitions`
  String get signedPetitions {
    return Intl.message(
      'Signed Petitions',
      name: 'signedPetitions',
      desc: '',
      args: [],
    );
  }

  /// `State`
  String get state {
    return Intl.message('State', name: 'state', desc: '', args: []);
  }

  /// `State dependent`
  String get stateDependent {
    return Intl.message(
      'State dependent',
      name: 'stateDependent',
      desc: '',
      args: [],
    );
  }

  /// `State updated successfully`
  String get stateUpdatedSuccessfully {
    return Intl.message(
      'State updated successfully',
      name: 'stateUpdatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `stimmapp`
  String get stimmapp {
    return Intl.message('stimmapp', name: 'stimmapp', desc: '', args: []);
  }

  /// `Subscription cancelled — access will remain until expiry`
  String get subscriptionCancelledAccessWillRemainUntilExpiry {
    return Intl.message(
      'Subscription cancelled — access will remain until expiry',
      name: 'subscriptionCancelledAccessWillRemainUntilExpiry',
      desc: '',
      args: [],
    );
  }

  /// `Successfully logged in`
  String get successfullyLoggedIn {
    return Intl.message(
      'Successfully logged in',
      name: 'successfullyLoggedIn',
      desc: '',
      args: [],
    );
  }

  /// `Supporters`
  String get supporters {
    return Intl.message('Supporters', name: 'supporters', desc: '', args: []);
  }

  /// `Surname`
  String get surname {
    return Intl.message('Surname', name: 'surname', desc: '', args: []);
  }

  /// `System Default`
  String get systemDefault {
    return Intl.message(
      'System Default',
      name: 'systemDefault',
      desc: '',
      args: [],
    );
  }

  /// `Tags`
  String get tags {
    return Intl.message('Tags', name: 'tags', desc: '', args: []);
  }

  /// `Comma-separated tags`
  String get tagsHint {
    return Intl.message(
      'Comma-separated tags',
      name: 'tagsHint',
      desc: '',
      args: [],
    );
  }

  /// `At least one tag is required`
  String get tagsRequired {
    return Intl.message(
      'At least one tag is required',
      name: 'tagsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Testing widgets here`
  String get testingWidgetsHere {
    return Intl.message(
      'Testing widgets here',
      name: 'testingWidgetsHere',
      desc: '',
      args: [],
    );
  }

  /// `Thank you for signing!`
  String get thankYouForSigning {
    return Intl.message(
      'Thank you for signing!',
      name: 'thankYouForSigning',
      desc: '',
      args: [],
    );
  }

  /// `The ultimate way to share your opinion`
  String get theWelcomePhrase {
    return Intl.message(
      'The ultimate way to share your opinion',
      name: 'theWelcomePhrase',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message('Title', name: 'title', desc: '', args: []);
  }

  /// `Title is required`
  String get titleRequired {
    return Intl.message(
      'Title is required',
      name: 'titleRequired',
      desc: '',
      args: [],
    );
  }

  /// `Title is too short`
  String get titleTooShort {
    return Intl.message(
      'Title is too short',
      name: 'titleTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Travel`
  String get travel {
    return Intl.message('Travel', name: 'travel', desc: '', args: []);
  }

  /// `Change address`
  String get updateLivingAddress {
    return Intl.message(
      'Change address',
      name: 'updateLivingAddress',
      desc: '',
      args: [],
    );
  }

  /// `Update state`
  String get updateState {
    return Intl.message(
      'Update state',
      name: 'updateState',
      desc: '',
      args: [],
    );
  }

  /// `Update username`
  String get updateUsername {
    return Intl.message(
      'Update username',
      name: 'updateUsername',
      desc: '',
      args: [],
    );
  }

  /// `Updates`
  String get updates {
    return Intl.message('Updates', name: 'updates', desc: '', args: []);
  }

  /// `User not available`
  String get userNotAvailable {
    return Intl.message(
      'User not available',
      name: 'userNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `User not found`
  String get userNotFound {
    return Intl.message(
      'User not found',
      name: 'userNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Userprofile Verified`
  String get userProfileVerified {
    return Intl.message(
      'Userprofile Verified',
      name: 'userProfileVerified',
      desc: '',
      args: [],
    );
  }

  /// `Username change failed`
  String get usernameChangeFailed {
    return Intl.message(
      'Username change failed',
      name: 'usernameChangeFailed',
      desc: '',
      args: [],
    );
  }

  /// `Username changed successfully`
  String get usernameChangedSuccessfully {
    return Intl.message(
      'Username changed successfully',
      name: 'usernameChangedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Users`
  String get users {
    return Intl.message('Users', name: 'users', desc: '', args: []);
  }

  /// `Valid until: {date}`
  String validUntil(String date) {
    return Intl.message(
      'Valid until: $date',
      name: 'validUntil',
      desc: '',
      args: [date],
    );
  }

  /// `Verification email sent`
  String get verificationEmailSent {
    return Intl.message(
      'Verification email sent',
      name: 'verificationEmailSent',
      desc: '',
      args: [],
    );
  }

  /// `A verification email has been sent to {email}`
  String verificationEmailSentTo(String email) {
    return Intl.message(
      'A verification email has been sent to $email',
      name: 'verificationEmailSentTo',
      desc: '',
      args: [email],
    );
  }

  /// `Victory!`
  String get victory {
    return Intl.message('Victory!', name: 'victory', desc: '', args: []);
  }

  /// `View licenses`
  String get viewLicenses {
    return Intl.message(
      'View licenses',
      name: 'viewLicenses',
      desc: '',
      args: [],
    );
  }

  /// `View Participants`
  String get viewParticipants {
    return Intl.message(
      'View Participants',
      name: 'viewParticipants',
      desc: '',
      args: [],
    );
  }

  /// `Vote`
  String get vote {
    return Intl.message('Vote', name: 'vote', desc: '', args: []);
  }

  /// `Voted`
  String get voted {
    return Intl.message('Voted', name: 'voted', desc: '', args: []);
  }

  /// `Request login code`
  String get requestLoginCode {
    return Intl.message(
      'Request login code',
      name: 'requestLoginCode',
      desc: '',
      args: [],
    );
  }

  /// `Welcome back! Please enter your details.`
  String get welcomeBackPleaseEnterYourDetails {
    return Intl.message(
      'Welcome back! Please enter your details.',
      name: 'welcomeBackPleaseEnterYourDetails',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to `
  String get welcomeTo {
    return Intl.message('Welcome to ', name: 'welcomeTo', desc: '', args: []);
  }

  /// `Welcome to Pro!`
  String get welcomeToPro {
    return Intl.message(
      'Welcome to Pro!',
      name: 'welcomeToPro',
      desc: '',
      args: [],
    );
  }

  /// `Ja`
  String get yes {
    return Intl.message('Ja', name: 'yes', desc: '', args: []);
  }

  /// `Yes, cancel`
  String get yesCancel {
    return Intl.message('Yes, cancel', name: 'yesCancel', desc: '', args: []);
  }

  /// `You subscribed to following benefits`
  String get youSubscribedToFollowingBenefits {
    return Intl.message(
      'You subscribed to following benefits',
      name: 'youSubscribedToFollowingBenefits',
      desc: '',
      args: [],
    );
  }

  /// `please enter your Email`
  String get pleaseEnterYourEmail {
    return Intl.message(
      'please enter your Email',
      name: 'pleaseEnterYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Welcome! Please enter your details.`
  String get welcomePleaseEnterYourDetails {
    return Intl.message(
      'Welcome! Please enter your details.',
      name: 'welcomePleaseEnterYourDetails',
      desc: '',
      args: [],
    );
  }

  /// `No user found for that email.`
  String get noUserFoundForThatEmail {
    return Intl.message(
      'No user found for that email.',
      name: 'noUserFoundForThatEmail',
      desc: '',
      args: [],
    );
  }

  /// `Wrong password provided.`
  String get wrongPasswordProvided {
    return Intl.message(
      'Wrong password provided.',
      name: 'wrongPasswordProvided',
      desc: '',
      args: [],
    );
  }

  /// `An unexpected error occurred.`
  String get anUnexpectedErrorOccurred {
    return Intl.message(
      'An unexpected error occurred.',
      name: 'anUnexpectedErrorOccurred',
      desc: '',
      args: [],
    );
  }

  /// `Please sign in to confirm your identity.`
  String get pleaseSignInToConfirmYourIdentity {
    return Intl.message(
      'Please sign in to confirm your identity.',
      name: 'pleaseSignInToConfirmYourIdentity',
      desc: '',
      args: [],
    );
  }

  /// `This action will permanently delete your account and all associated data.`
  String get thisActionWillPermanentlyDeleteYourAccountAndAllAssociated {
    return Intl.message(
      'This action will permanently delete your account and all associated data.',
      name: 'thisActionWillPermanentlyDeleteYourAccountAndAllAssociated',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your password`
  String get pleaseEnterYourPassword {
    return Intl.message(
      'Please enter your password',
      name: 'pleaseEnterYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `PERMANENTLY DELETE ACCOUNT`
  String get permanentlyDeleteAccount {
    return Intl.message(
      'PERMANENTLY DELETE ACCOUNT',
      name: 'permanentlyDeleteAccount',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error`
  String get unknownError {
    return Intl.message(
      'Unknown error',
      name: 'unknownError',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a date of birth`
  String get pleaseEnterADateOfBirth {
    return Intl.message(
      'Please enter a date of birth',
      name: 'pleaseEnterADateOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `LinkedIn link copied to clipboard`
  String get linkedinLinkCopiedToClipboard {
    return Intl.message(
      'LinkedIn link copied to clipboard',
      name: 'linkedinLinkCopiedToClipboard',
      desc: '',
      args: [],
    );
  }

  /// `GitHub link copied to clipboard`
  String get githubLinkCopiedToClipboard {
    return Intl.message(
      'GitHub link copied to clipboard',
      name: 'githubLinkCopiedToClipboard',
      desc: '',
      args: [],
    );
  }

  /// `Email copied to clipboard`
  String get emailCopiedToClipboard {
    return Intl.message(
      'Email copied to clipboard',
      name: 'emailCopiedToClipboard',
      desc: '',
      args: [],
    );
  }

  /// `No Name`
  String get noName {
    return Intl.message('No Name', name: 'noName', desc: '', args: []);
  }

  /// `No Email`
  String get noEmail {
    return Intl.message('No Email', name: 'noEmail', desc: '', args: []);
  }

  /// `petition title in use already`
  String get petitionTitleInUseAlready {
    return Intl.message(
      'petition title in use already',
      name: 'petitionTitleInUseAlready',
      desc: '',
      args: [],
    );
  }

  /// `Logged out successfully`
  String get loggedOutSuccessfully {
    return Intl.message(
      'Logged out successfully',
      name: 'loggedOutSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid 6-digit code`
  String get pleaseEnterAValid6digitCode {
    return Intl.message(
      'Please enter a valid 6-digit code',
      name: 'pleaseEnterAValid6digitCode',
      desc: '',
      args: [],
    );
  }

  /// `Verification failed`
  String get verificationFailed {
    return Intl.message(
      'Verification failed',
      name: 'verificationFailed',
      desc: '',
      args: [],
    );
  }

  /// `Verification code resent!`
  String get verificationCodeResent {
    return Intl.message(
      'Verification code resent!',
      name: 'verificationCodeResent',
      desc: '',
      args: [],
    );
  }

  /// `Failed to resend code`
  String get failedToResendCode {
    return Intl.message(
      'Failed to resend code',
      name: 'failedToResendCode',
      desc: '',
      args: [],
    );
  }

  /// `We have sent a 6-digit code to your email. Please enter it below.`
  String get weHaveSentA6digitCodeToYourEmailPlease {
    return Intl.message(
      'We have sent a 6-digit code to your email. Please enter it below.',
      name: 'weHaveSentA6digitCodeToYourEmailPlease',
      desc: '',
      args: [],
    );
  }

  /// `Verify`
  String get verify {
    return Intl.message('Verify', name: 'verify', desc: '', args: []);
  }

  /// `hello`
  String get hello {
    return Intl.message('hello', name: 'hello', desc: '', args: []);
  }

  /// `Faulty input`
  String get faultyInput {
    return Intl.message(
      'Faulty input',
      name: 'faultyInput',
      desc: '',
      args: [],
    );
  }

  /// `we failed to get your state, please proofread your living-address`
  String get weFailedToGetYourStatePleaseProofreadYourLivingaddress {
    return Intl.message(
      'we failed to get your state, please proofread your living-address',
      name: 'weFailedToGetYourStatePleaseProofreadYourLivingaddress',
      desc: '',
      args: [],
    );
  }

  /// `petition guidelines`
  String get petitionGuidelines {
    return Intl.message(
      'petition guidelines',
      name: 'petitionGuidelines',
      desc: '',
      args: [],
    );
  }

  /// `petition guideline description`
  String get petitionGuidelineDescription {
    return Intl.message(
      'petition guideline description',
      name: 'petitionGuidelineDescription',
      desc: '',
      args: [],
    );
  }

  /// `poll guidelines`
  String get pollGuidelines {
    return Intl.message(
      'poll guidelines',
      name: 'pollGuidelines',
      desc: '',
      args: [],
    );
  }

  /// `poll guideline description`
  String get pollGuidelineDescription {
    return Intl.message(
      'poll guideline description',
      name: 'pollGuidelineDescription',
      desc: '',
      args: [],
    );
  }

  /// `please enter your details.`
  String get pleaseEnterYourDetails {
    return Intl.message(
      'please enter your details.',
      name: 'pleaseEnterYourDetails',
      desc: '',
      args: [],
    );
  }

  /// `this app was developed by`
  String get thisAppWasDevelopedBy {
    return Intl.message(
      'this app was developed by',
      name: 'thisAppWasDevelopedBy',
      desc: '',
      args: [],
    );
  }

  /// `Licenses`
  String get licenses {
    return Intl.message('Licenses', name: 'licenses', desc: '', args: []);
  }

  /// `published under the GNU General Public License v3.0`
  String get publishedUnderTheGnuGeneralPublicLicenseV30 {
    return Intl.message(
      'published under the GNU General Public License v3.0',
      name: 'publishedUnderTheGnuGeneralPublicLicenseV30',
      desc: '',
      args: [],
    );
  }

  /// `Enter Verification Code`
  String get enterVerificationCode {
    return Intl.message(
      'Enter Verification Code',
      name: 'enterVerificationCode',
      desc: '',
      args: [],
    );
  }

  /// `Environment`
  String get tagEnvironment {
    return Intl.message(
      'Environment',
      name: 'tagEnvironment',
      desc: '',
      args: [],
    );
  }

  /// `Politics`
  String get tagPolitics {
    return Intl.message('Politics', name: 'tagPolitics', desc: '', args: []);
  }

  /// `Education`
  String get tagEducation {
    return Intl.message('Education', name: 'tagEducation', desc: '', args: []);
  }

  /// `Health`
  String get tagHealth {
    return Intl.message('Health', name: 'tagHealth', desc: '', args: []);
  }

  /// `Infrastructure`
  String get tagInfrastructure {
    return Intl.message(
      'Infrastructure',
      name: 'tagInfrastructure',
      desc: '',
      args: [],
    );
  }

  /// `Economy`
  String get tagEconomy {
    return Intl.message('Economy', name: 'tagEconomy', desc: '', args: []);
  }

  /// `Social`
  String get tagSocial {
    return Intl.message('Social', name: 'tagSocial', desc: '', args: []);
  }

  /// `Technology`
  String get tagTechnology {
    return Intl.message(
      'Technology',
      name: 'tagTechnology',
      desc: '',
      args: [],
    );
  }

  /// `Culture`
  String get tagCulture {
    return Intl.message('Culture', name: 'tagCulture', desc: '', args: []);
  }

  /// `Sports`
  String get tagSports {
    return Intl.message('Sports', name: 'tagSports', desc: '', args: []);
  }

  /// `Animal Welfare`
  String get tagAnimalWelfare {
    return Intl.message(
      'Animal Welfare',
      name: 'tagAnimalWelfare',
      desc: '',
      args: [],
    );
  }

  /// `Safety`
  String get tagSafety {
    return Intl.message('Safety', name: 'tagSafety', desc: '', args: []);
  }

  /// `Traffic`
  String get tagTraffic {
    return Intl.message('Traffic', name: 'tagTraffic', desc: '', args: []);
  }

  /// `Housing`
  String get tagHousing {
    return Intl.message('Housing', name: 'tagHousing', desc: '', args: []);
  }

  /// `Other`
  String get tagOther {
    return Intl.message('Other', name: 'tagOther', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}

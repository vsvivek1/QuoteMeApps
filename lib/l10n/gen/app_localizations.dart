import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es'), Locale('hi')];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Tell shops what you want. Get quotes. Pick the best.'**
  String get appTagline;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing saved data.'**
  String get offlineBanner;

  /// No description provided for @demoModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: sample data, OTP 123456'**
  String get demoModeBanner;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get languageSubtitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Get quotes from local shops'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody1.
  ///
  /// In en, this message translates to:
  /// **'Post what you need in seconds.'**
  String get welcomeBody1;

  /// No description provided for @welcomeBody2.
  ///
  /// In en, this message translates to:
  /// **'Shops and service pros send you prices.'**
  String get welcomeBody2;

  /// No description provided for @welcomeBody3.
  ///
  /// In en, this message translates to:
  /// **'Compare, chat and pick the best deal.'**
  String get welcomeBody3;

  /// No description provided for @signInPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get signInPhone;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInGoogle;

  /// No description provided for @signInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInApple;

  /// No description provided for @signInLegal.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our {terms} and {privacy}.'**
  String signInLegal(String terms, String privacy);

  /// No description provided for @termsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsLink;

  /// No description provided for @privacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyLink;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a one-time code by SMS.'**
  String get phoneSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get phoneInvalid;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpLabel;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work. Check it and try again.'**
  String get otpInvalid;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get authFailed;

  /// No description provided for @authCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get authCancelled;

  /// No description provided for @otpRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes.'**
  String get otpRateLimited;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get consentTitle;

  /// No description provided for @consentAccept.
  ///
  /// In en, this message translates to:
  /// **'I agree to the {terms} and {privacy}'**
  String consentAccept(String terms, String privacy);

  /// No description provided for @consentMarketing.
  ///
  /// In en, this message translates to:
  /// **'Send me offers and tips (optional)'**
  String get consentMarketing;

  /// No description provided for @consentAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app with anonymous usage data (optional)'**
  String get consentAnalytics;

  /// No description provided for @consentAge.
  ///
  /// In en, this message translates to:
  /// **'I am {age} or older'**
  String consentAge(int age);

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get profileSetupTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// No description provided for @addPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your mobile number'**
  String get addPhoneTitle;

  /// No description provided for @addPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Sellers need a verified phone number. Buyers can add one to get SMS updates.'**
  String get addPhoneBody;

  /// No description provided for @modeBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buying'**
  String get modeBuyer;

  /// No description provided for @modeSeller.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get modeSeller;

  /// No description provided for @switchToSelling.
  ///
  /// In en, this message translates to:
  /// **'Switch to selling'**
  String get switchToSelling;

  /// No description provided for @switchToBuying.
  ///
  /// In en, this message translates to:
  /// **'Switch to buying'**
  String get switchToBuying;

  /// No description provided for @becomeSeller.
  ///
  /// In en, this message translates to:
  /// **'I\'m a business'**
  String get becomeSeller;

  /// No description provided for @becomeSellerBody.
  ///
  /// In en, this message translates to:
  /// **'Get leads from buyers near you and send quotes. Free for founding partners.'**
  String get becomeSellerBody;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get tabRequests;

  /// No description provided for @tabChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tabChats;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @tabLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get tabLeads;

  /// No description provided for @tabMyQuotes.
  ///
  /// In en, this message translates to:
  /// **'My quotes'**
  String get tabMyQuotes;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingAnon.
  ///
  /// In en, this message translates to:
  /// **'Hi there'**
  String get homeGreetingAnon;

  /// No description provided for @whatDoYouNeed.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get whatDoYouNeed;

  /// No description provided for @whatDoYouNeedHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Double-door fridge, delivered by Friday'**
  String get whatDoYouNeedHint;

  /// No description provided for @activeRequests.
  ///
  /// In en, this message translates to:
  /// **'Your active requests'**
  String get activeRequests;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular categories'**
  String get browseCategories;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @noActiveRequests.
  ///
  /// In en, this message translates to:
  /// **'Nothing posted yet. Tell local shops what you want and get quotes.'**
  String get noActiveRequests;

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get postTitle;

  /// No description provided for @postStepWhat.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get postStepWhat;

  /// No description provided for @postStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get postStepDetails;

  /// No description provided for @postStepWhere.
  ///
  /// In en, this message translates to:
  /// **'When and where'**
  String get postStepWhere;

  /// No description provided for @postDescribeHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you want. Brand, size, quantity…'**
  String get postDescribeHint;

  /// No description provided for @postSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get postSpeak;

  /// No description provided for @postListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get postListening;

  /// No description provided for @postSuggestedCategory.
  ///
  /// In en, this message translates to:
  /// **'Suggested category'**
  String get postSuggestedCategory;

  /// No description provided for @postPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get postPickCategory;

  /// No description provided for @postChangeCategory.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get postChangeCategory;

  /// No description provided for @postAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get postAddPhotos;

  /// No description provided for @postPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photos'**
  String postPhotosCount(int count);

  /// No description provided for @postReferenceLink.
  ///
  /// In en, this message translates to:
  /// **'Reference link (product page)'**
  String get postReferenceLink;

  /// No description provided for @postBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get postBudget;

  /// No description provided for @postBudgetMin.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get postBudgetMin;

  /// No description provided for @postBudgetMax.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get postBudgetMax;

  /// No description provided for @postBudgetHidden.
  ///
  /// In en, this message translates to:
  /// **'Hide my budget from sellers'**
  String get postBudgetHidden;

  /// No description provided for @postNeededBy.
  ///
  /// In en, this message translates to:
  /// **'Needed by'**
  String get postNeededBy;

  /// No description provided for @postPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get postPickDate;

  /// No description provided for @postLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery or service location'**
  String get postLocation;

  /// No description provided for @postUseGps.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get postUseGps;

  /// No description provided for @postPostalCode.
  ///
  /// In en, this message translates to:
  /// **'{codeLabel}'**
  String postPostalCode(String codeLabel);

  /// No description provided for @postLocality.
  ///
  /// In en, this message translates to:
  /// **'Area / locality'**
  String get postLocality;

  /// No description provided for @postFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address (shared only with the seller you accept)'**
  String get postFullAddress;

  /// No description provided for @postQuoteWindow.
  ///
  /// In en, this message translates to:
  /// **'Accept quotes for'**
  String get postQuoteWindow;

  /// No description provided for @quoteWindow24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get quoteWindow24h;

  /// No description provided for @quoteWindow48h.
  ///
  /// In en, this message translates to:
  /// **'48 hours'**
  String get quoteWindow48h;

  /// No description provided for @quoteWindow7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get quoteWindow7d;

  /// No description provided for @postWhoCanQuote.
  ///
  /// In en, this message translates to:
  /// **'Who can quote'**
  String get postWhoCanQuote;

  /// No description provided for @audienceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local shops'**
  String get audienceLocal;

  /// No description provided for @audienceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online sellers'**
  String get audienceOnline;

  /// No description provided for @audienceBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get audienceBoth;

  /// No description provided for @postReview.
  ///
  /// In en, this message translates to:
  /// **'Review and post'**
  String get postReview;

  /// No description provided for @postSubmit.
  ///
  /// In en, this message translates to:
  /// **'Post request'**
  String get postSubmit;

  /// No description provided for @postSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Request posted'**
  String get postSuccessTitle;

  /// No description provided for @postSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{We\'ll notify sellers as they join your area.} =1{We\'ve notified 1 seller near you.} other{We\'ve notified {count} sellers near you.}}'**
  String postSuccessBody(int count);

  /// No description provided for @postBlockedCategory.
  ///
  /// In en, this message translates to:
  /// **'We can\'t take requests for {category} in this app. {reason}'**
  String postBlockedCategory(String category, String reason);

  /// No description provided for @postBlockedReason.
  ///
  /// In en, this message translates to:
  /// **'This category is regulated and isn\'t allowed here.'**
  String get postBlockedReason;

  /// No description provided for @postRestrictedNotice.
  ///
  /// In en, this message translates to:
  /// **'Only licensed sellers can quote in this category.'**
  String get postRestrictedNotice;

  /// No description provided for @postRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit for new requests. Try again tomorrow.'**
  String get postRateLimited;

  /// No description provided for @postDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already posted this request in the last 24 hours.'**
  String get postDuplicate;

  /// No description provided for @postDescribeRequired.
  ///
  /// In en, this message translates to:
  /// **'Tell sellers what you need'**
  String get postDescribeRequired;

  /// No description provided for @postCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get postCategoryRequired;

  /// No description provided for @postLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a location'**
  String get postLocationRequired;

  /// No description provided for @postCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {codeLabel}'**
  String postCodeInvalid(String codeLabel);

  /// No description provided for @postalCodeLabelIndia.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get postalCodeLabelIndia;

  /// No description provided for @postalCodeLabelUsa.
  ///
  /// In en, this message translates to:
  /// **'ZIP code'**
  String get postalCodeLabelUsa;

  /// No description provided for @requestsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get requestsOpen;

  /// No description provided for @requestsAwarded.
  ///
  /// In en, this message translates to:
  /// **'Awarded'**
  String get requestsAwarded;

  /// No description provided for @requestsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get requestsPast;

  /// No description provided for @requestsEmptyOpen.
  ///
  /// In en, this message translates to:
  /// **'No open requests. Post one and get quotes from local shops.'**
  String get requestsEmptyOpen;

  /// No description provided for @requestsEmptyAwarded.
  ///
  /// In en, this message translates to:
  /// **'Requests where you accepted a quote show up here.'**
  String get requestsEmptyAwarded;

  /// No description provided for @requestsEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'Expired and cancelled requests show up here.'**
  String get requestsEmptyPast;

  /// No description provided for @quotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No quotes yet} =1{1 quote} other{{count} quotes}}'**
  String quotesCount(int count);

  /// No description provided for @quotesOfMax.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} quotes'**
  String quotesOfMax(int count, int max);

  /// No description provided for @closesIn.
  ///
  /// In en, this message translates to:
  /// **'Closes in {time}'**
  String closesIn(String time);

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusAwarded.
  ///
  /// In en, this message translates to:
  /// **'Awarded'**
  String get statusAwarded;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @noQuotesYet.
  ///
  /// In en, this message translates to:
  /// **'No quotes yet. Sellers usually respond within 2 hours.'**
  String get noQuotesYet;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @cancelRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request? Sellers won\'t be able to quote any more.'**
  String get cancelRequestConfirm;

  /// No description provided for @shareRequest.
  ///
  /// In en, this message translates to:
  /// **'Share request'**
  String get shareRequest;

  /// No description provided for @shareRequestWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Ask friends on WhatsApp'**
  String get shareRequestWhatsapp;

  /// No description provided for @shareRequestText.
  ///
  /// In en, this message translates to:
  /// **'Which one should I pick? {link}'**
  String shareRequestText(String link);

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @compareSelect.
  ///
  /// In en, this message translates to:
  /// **'Select up to 3 quotes to compare'**
  String get compareSelect;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sortPrice;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sortRating;

  /// No description provided for @sortDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get sortDelivery;

  /// No description provided for @sortDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get sortDistance;

  /// No description provided for @quoteTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get quoteTotal;

  /// No description provided for @quoteSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get quoteSubtotal;

  /// No description provided for @quoteTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get quoteTax;

  /// No description provided for @quoteDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery / installation'**
  String get quoteDelivery;

  /// No description provided for @quoteFreeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get quoteFreeDelivery;

  /// No description provided for @quoteOffered.
  ///
  /// In en, this message translates to:
  /// **'Offered'**
  String get quoteOffered;

  /// No description provided for @quoteDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get quoteDeliveryDate;

  /// No description provided for @quoteWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get quoteWarranty;

  /// No description provided for @quoteValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String quoteValidUntil(String date);

  /// No description provided for @quoteNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get quoteNotes;

  /// No description provided for @quoteResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Replied in {time}'**
  String quoteResponseTime(String time);

  /// No description provided for @quoteVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get quoteVerified;

  /// No description provided for @quoteFoundingPartner.
  ///
  /// In en, this message translates to:
  /// **'Founding partner'**
  String get quoteFoundingPartner;

  /// No description provided for @quoteNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get quoteNew;

  /// No description provided for @gstIntra.
  ///
  /// In en, this message translates to:
  /// **'CGST {rate}% + SGST {rate}%'**
  String gstIntra(String rate);

  /// No description provided for @gstInter.
  ///
  /// In en, this message translates to:
  /// **'IGST {rate}%'**
  String gstInter(String rate);

  /// No description provided for @salesTax.
  ///
  /// In en, this message translates to:
  /// **'Sales tax {rate}%'**
  String salesTax(String rate);

  /// No description provided for @taxIncludedNote.
  ///
  /// In en, this message translates to:
  /// **'Prices include GST'**
  String get taxIncludedNote;

  /// No description provided for @salesTaxNote.
  ///
  /// In en, this message translates to:
  /// **'Sales tax may apply'**
  String get salesTaxNote;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @shortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get shortlist;

  /// No description provided for @shortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get shortlisted;

  /// No description provided for @counterOffer.
  ///
  /// In en, this message translates to:
  /// **'Ask for a better price'**
  String get counterOffer;

  /// No description provided for @counterOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a revised quote'**
  String get counterOfferTitle;

  /// No description provided for @counterOfferTarget.
  ///
  /// In en, this message translates to:
  /// **'Your target price'**
  String get counterOfferTarget;

  /// No description provided for @counterOfferNote.
  ///
  /// In en, this message translates to:
  /// **'Message to the seller'**
  String get counterOfferNote;

  /// No description provided for @counterOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. The seller can revise the quote.'**
  String get counterOfferSent;

  /// No description provided for @counterOfferFrom.
  ///
  /// In en, this message translates to:
  /// **'Buyer asked for {price}'**
  String counterOfferFrom(String price);

  /// No description provided for @acceptConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this quote?'**
  String get acceptConfirmTitle;

  /// No description provided for @acceptConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{seller} will get your contact details and address. Other sellers will be told politely that you chose another offer.'**
  String acceptConfirmBody(String seller);

  /// No description provided for @acceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote accepted'**
  String get acceptedTitle;

  /// No description provided for @acceptedBody.
  ///
  /// In en, this message translates to:
  /// **'{seller} has been notified. You can call or chat with them now.'**
  String acceptedBody(String seller);

  /// No description provided for @declineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline quote'**
  String get declineTitle;

  /// No description provided for @declineReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional, shared with the seller)'**
  String get declineReason;

  /// No description provided for @declineReasonPrice.
  ///
  /// In en, this message translates to:
  /// **'Price too high'**
  String get declineReasonPrice;

  /// No description provided for @declineReasonDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery too late'**
  String get declineReasonDelivery;

  /// No description provided for @declineReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Chose another offer'**
  String get declineReasonOther;

  /// No description provided for @quoteStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get quoteStatusSent;

  /// No description provided for @quoteStatusRevised.
  ///
  /// In en, this message translates to:
  /// **'Revised'**
  String get quoteStatusRevised;

  /// No description provided for @quoteStatusShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get quoteStatusShortlisted;

  /// No description provided for @quoteStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get quoteStatusDeclined;

  /// No description provided for @quoteStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get quoteStatusAccepted;

  /// No description provided for @quoteStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get quoteStatusWithdrawn;

  /// No description provided for @quoteStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get quoteStatusExpired;

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderTitle;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// No description provided for @orderTimeline.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get orderTimeline;

  /// No description provided for @orderStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get orderStatusAccepted;

  /// No description provided for @orderStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get orderStatusScheduled;

  /// No description provided for @orderStatusDispatched.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get orderStatusDispatched;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderMarkAs.
  ///
  /// In en, this message translates to:
  /// **'Mark as {status}'**
  String orderMarkAs(String status);

  /// No description provided for @orderContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get orderContact;

  /// No description provided for @orderAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orderAddress;

  /// No description provided for @orderPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get orderPayment;

  /// No description provided for @orderPaymentOffPlatform.
  ///
  /// In en, this message translates to:
  /// **'Pay the seller directly. Record it here for your records.'**
  String get orderPaymentOffPlatform;

  /// No description provided for @orderRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get orderRecordPayment;

  /// No description provided for @orderPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'{amount} paid by {method}'**
  String orderPaymentRecorded(String amount, String method);

  /// No description provided for @paymentMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get paymentMethodUpi;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodSellerLink.
  ///
  /// In en, this message translates to:
  /// **'Seller\'s payment link'**
  String get paymentMethodSellerLink;

  /// No description provided for @paymentMethodZelle.
  ///
  /// In en, this message translates to:
  /// **'Zelle'**
  String get paymentMethodZelle;

  /// No description provided for @paymentMethodCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get paymentMethodCheck;

  /// No description provided for @rateSeller.
  ///
  /// In en, this message translates to:
  /// **'Rate the seller'**
  String get rateSeller;

  /// No description provided for @rateBuyer.
  ///
  /// In en, this message translates to:
  /// **'Rate the buyer'**
  String get rateBuyer;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get reviewTitle;

  /// No description provided for @reviewTextHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about your experience'**
  String get reviewTextHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get reviewSubmit;

  /// No description provided for @reviewThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review!'**
  String get reviewThanks;

  /// No description provided for @reviewTagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get reviewTagOnTime;

  /// No description provided for @reviewTagGoodPrice.
  ///
  /// In en, this message translates to:
  /// **'Good price'**
  String get reviewTagGoodPrice;

  /// No description provided for @reviewTagProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get reviewTagProfessional;

  /// No description provided for @reviewTagQuality.
  ///
  /// In en, this message translates to:
  /// **'Great quality'**
  String get reviewTagQuality;

  /// No description provided for @reviewTagResponsive.
  ///
  /// In en, this message translates to:
  /// **'Responsive'**
  String get reviewTagResponsive;

  /// No description provided for @reviewReply.
  ///
  /// In en, this message translates to:
  /// **'Reply publicly'**
  String get reviewReply;

  /// No description provided for @reviewSellerReply.
  ///
  /// In en, this message translates to:
  /// **'Response from the seller'**
  String get reviewSellerReply;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get reviewsEmpty;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Chats with sellers about your requests show up here.'**
  String get chatsEmpty;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatHint;

  /// No description provided for @chatContactWarning.
  ///
  /// In en, this message translates to:
  /// **'For your safety, keep contact details in the app until you accept a quote.'**
  String get chatContactWarning;

  /// No description provided for @chatAboutRequest.
  ///
  /// In en, this message translates to:
  /// **'About: {title}'**
  String chatAboutRequest(String title);

  /// No description provided for @chatRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatRead;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get chatTyping;

  /// No description provided for @chatFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Tap to retry.'**
  String get chatFailed;

  /// No description provided for @chatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsEmpty;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notifNewQuote.
  ///
  /// In en, this message translates to:
  /// **'New quote from {seller}'**
  String notifNewQuote(String seller);

  /// No description provided for @notifQuoteRevised.
  ///
  /// In en, this message translates to:
  /// **'A seller revised their quote'**
  String get notifQuoteRevised;

  /// No description provided for @notifMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notifMessage;

  /// No description provided for @notifNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request: {title}'**
  String notifNewRequest(String title);

  /// No description provided for @notifQuoteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your quote was accepted!'**
  String get notifQuoteAccepted;

  /// No description provided for @notifQuoteDeclined.
  ///
  /// In en, this message translates to:
  /// **'A buyer chose another offer'**
  String get notifQuoteDeclined;

  /// No description provided for @notifQuoteShortlisted.
  ///
  /// In en, this message translates to:
  /// **'A buyer shortlisted your quote'**
  String get notifQuoteShortlisted;

  /// No description provided for @notifCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'A buyer asked for a better price'**
  String get notifCounterOffer;

  /// No description provided for @notifOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order update'**
  String get notifOrderStatus;

  /// No description provided for @notifGeneric.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get notifGeneric;

  /// No description provided for @sellerOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your business'**
  String get sellerOnboardingTitle;

  /// No description provided for @sellerStepBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get sellerStepBusiness;

  /// No description provided for @sellerStepCategories.
  ///
  /// In en, this message translates to:
  /// **'What you sell'**
  String get sellerStepCategories;

  /// No description provided for @sellerStepArea.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get sellerStepArea;

  /// No description provided for @sellerStepNotify.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get sellerStepNotify;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @businessDescription.
  ///
  /// In en, this message translates to:
  /// **'About your business'**
  String get businessDescription;

  /// No description provided for @yearsInBusiness.
  ///
  /// In en, this message translates to:
  /// **'Years in business'**
  String get yearsInBusiness;

  /// No description provided for @brandsCarried.
  ///
  /// In en, this message translates to:
  /// **'Brands you carry (comma separated)'**
  String get brandsCarried;

  /// No description provided for @addLogo.
  ///
  /// In en, this message translates to:
  /// **'Add logo'**
  String get addLogo;

  /// No description provided for @addShopPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add shop photos'**
  String get addShopPhotos;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select the categories you can quote for'**
  String get selectCategories;

  /// No description provided for @categoriesRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one category'**
  String get categoriesRequired;

  /// No description provided for @areaRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius around my shop'**
  String get areaRadius;

  /// No description provided for @areaCodes.
  ///
  /// In en, this message translates to:
  /// **'List of {codeLabel}s'**
  String areaCodes(String codeLabel);

  /// No description provided for @areaNationwide.
  ///
  /// In en, this message translates to:
  /// **'Ship nationwide'**
  String get areaNationwide;

  /// No description provided for @radiusValue.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String radiusValue(int value);

  /// No description provided for @radiusValueMiles.
  ///
  /// In en, this message translates to:
  /// **'{value} mi'**
  String radiusValueMiles(int value);

  /// No description provided for @shopLocation.
  ///
  /// In en, this message translates to:
  /// **'Shop location'**
  String get shopLocation;

  /// No description provided for @serviceCodesHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. {example}'**
  String serviceCodesHint(String example);

  /// No description provided for @sellerState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get sellerState;

  /// No description provided for @notifyInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant alerts'**
  String get notifyInstant;

  /// No description provided for @notifyHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly digest'**
  String get notifyHourly;

  /// No description provided for @notifyQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifyQuiet;

  /// No description provided for @quietHoursRange.
  ///
  /// In en, this message translates to:
  /// **'Quiet from {start} to {end}'**
  String quietHoursRange(String start, String end);

  /// No description provided for @sellerProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Your business is live. New leads will show up in your feed.'**
  String get sellerProfileSaved;

  /// No description provided for @foundingPartnerBadge.
  ///
  /// In en, this message translates to:
  /// **'Founding partner: free until {date}'**
  String foundingPartnerBadge(String date);

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Get verified'**
  String get verificationTitle;

  /// No description provided for @verificationBody.
  ///
  /// In en, this message translates to:
  /// **'Verified sellers get a badge and see new requests first.'**
  String get verificationBody;

  /// No description provided for @verificationStatusNone.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get verificationStatusNone;

  /// No description provided for @verificationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get verificationStatusPending;

  /// No description provided for @verificationStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationStatusVerified;

  /// No description provided for @verificationStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String verificationStatusRejected(String reason);

  /// No description provided for @docGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get docGstin;

  /// No description provided for @docUdyam.
  ///
  /// In en, this message translates to:
  /// **'Udyam registration number'**
  String get docUdyam;

  /// No description provided for @docShopPhoto.
  ///
  /// In en, this message translates to:
  /// **'Shop photo'**
  String get docShopPhoto;

  /// No description provided for @docEin.
  ///
  /// In en, this message translates to:
  /// **'EIN'**
  String get docEin;

  /// No description provided for @docStateLicence.
  ///
  /// In en, this message translates to:
  /// **'State business licence number'**
  String get docStateLicence;

  /// No description provided for @docBusinessAddress.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get docBusinessAddress;

  /// No description provided for @docWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get docWebsite;

  /// No description provided for @docInvalid.
  ///
  /// In en, this message translates to:
  /// **'This number doesn\'t look right. Check it and try again.'**
  String get docInvalid;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadFile;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;

  /// No description provided for @submittedForReview.
  ///
  /// In en, this message translates to:
  /// **'Submitted. We\'ll review it shortly.'**
  String get submittedForReview;

  /// No description provided for @licencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licencesTitle;

  /// No description provided for @licencesBody.
  ///
  /// In en, this message translates to:
  /// **'Required to quote in restricted categories.'**
  String get licencesBody;

  /// No description provided for @addLicence.
  ///
  /// In en, this message translates to:
  /// **'Add licence'**
  String get addLicence;

  /// No description provided for @licenceType.
  ///
  /// In en, this message translates to:
  /// **'Licence type'**
  String get licenceType;

  /// No description provided for @licenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Licence number'**
  String get licenceNumber;

  /// No description provided for @licenceIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuing body'**
  String get licenceIssuer;

  /// No description provided for @licenceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get licenceExpiry;

  /// No description provided for @leadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get leadsTitle;

  /// No description provided for @leadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching requests right now. We\'ll alert you when buyers near you post.'**
  String get leadsEmpty;

  /// No description provided for @leadsNoSellerProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your business profile to start getting leads.'**
  String get leadsNoSellerProfile;

  /// No description provided for @leadFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get leadFilters;

  /// No description provided for @leadFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get leadFilterCategory;

  /// No description provided for @leadFilterDistance.
  ///
  /// In en, this message translates to:
  /// **'Within'**
  String get leadFilterDistance;

  /// No description provided for @leadFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get leadFilterAny;

  /// No description provided for @leadAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String leadAway(String distance);

  /// No description provided for @leadQuotesSent.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} quotes sent'**
  String leadQuotesSent(int count, int max);

  /// No description provided for @leadFull.
  ///
  /// In en, this message translates to:
  /// **'Quote limit reached'**
  String get leadFull;

  /// No description provided for @leadNeededBy.
  ///
  /// In en, this message translates to:
  /// **'Needed by {date}'**
  String leadNeededBy(String date);

  /// No description provided for @leadBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget {range}'**
  String leadBudget(String range);

  /// No description provided for @leadBudgetHidden.
  ///
  /// In en, this message translates to:
  /// **'Budget not shared'**
  String get leadBudgetHidden;

  /// No description provided for @leadDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get leadDismiss;

  /// No description provided for @leadSendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send quote'**
  String get leadSendQuote;

  /// No description provided for @leadAlreadyQuoted.
  ///
  /// In en, this message translates to:
  /// **'You\'ve quoted'**
  String get leadAlreadyQuoted;

  /// No description provided for @leadPriorityNote.
  ///
  /// In en, this message translates to:
  /// **'Verified sellers see new requests first.'**
  String get leadPriorityNote;

  /// No description provided for @leadLocalityOnly.
  ///
  /// In en, this message translates to:
  /// **'Exact address is shared after the buyer accepts your quote.'**
  String get leadLocalityOnly;

  /// No description provided for @quoteFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Your quote'**
  String get quoteFormTitle;

  /// No description provided for @quoteItem.
  ///
  /// In en, this message translates to:
  /// **'Item / service'**
  String get quoteItem;

  /// No description provided for @quoteQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quoteQty;

  /// No description provided for @quoteUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get quoteUnitPrice;

  /// No description provided for @quoteAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get quoteAddLine;

  /// No description provided for @quoteTaxRate.
  ///
  /// In en, this message translates to:
  /// **'GST rate'**
  String get quoteTaxRate;

  /// No description provided for @quoteSalesTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Sales tax rate (%)'**
  String get quoteSalesTaxRate;

  /// No description provided for @quoteBrandModel.
  ///
  /// In en, this message translates to:
  /// **'Brand / model offered'**
  String get quoteBrandModel;

  /// No description provided for @quoteValidity.
  ///
  /// In en, this message translates to:
  /// **'Quote valid for'**
  String get quoteValidity;

  /// No description provided for @quoteValidityDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String quoteValidityDays(int count);

  /// No description provided for @quoteAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get quoteAttachments;

  /// No description provided for @quoteSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get quoteSaveTemplate;

  /// No description provided for @quoteUseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get quoteUseTemplate;

  /// No description provided for @quoteTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get quoteTemplateName;

  /// No description provided for @quoteSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send quote'**
  String get quoteSubmit;

  /// No description provided for @quoteRevise.
  ///
  /// In en, this message translates to:
  /// **'Send revised quote'**
  String get quoteRevise;

  /// No description provided for @quoteWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw quote'**
  String get quoteWithdraw;

  /// No description provided for @quoteSent.
  ///
  /// In en, this message translates to:
  /// **'Quote sent'**
  String get quoteSent;

  /// No description provided for @quotePriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a price'**
  String get quotePriceRequired;

  /// No description provided for @quoteCapReached.
  ///
  /// In en, this message translates to:
  /// **'This request already has the maximum number of quotes.'**
  String get quoteCapReached;

  /// No description provided for @quoteRequestClosed.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer open.'**
  String get quoteRequestClosed;

  /// No description provided for @quoteNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can\'t quote on this request.'**
  String get quoteNotAllowed;

  /// No description provided for @quoteLicenceRequired.
  ///
  /// In en, this message translates to:
  /// **'A valid licence is required for this category.'**
  String get quoteLicenceRequired;

  /// No description provided for @quoteNoCredits.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of free quotes this month. See plans.'**
  String get quoteNoCredits;

  /// No description provided for @quotePriorityWindow.
  ///
  /// In en, this message translates to:
  /// **'Verified sellers get the first 15 minutes on new requests.'**
  String get quotePriorityWindow;

  /// No description provided for @quoteAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already quoted on this request.'**
  String get quoteAlreadySent;

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote templates'**
  String get templatesTitle;

  /// No description provided for @templatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save a quote as a template to reuse it.'**
  String get templatesEmpty;

  /// No description provided for @myQuotesActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get myQuotesActive;

  /// No description provided for @myQuotesWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get myQuotesWon;

  /// No description provided for @myQuotesLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get myQuotesLost;

  /// No description provided for @myQuotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No quotes here yet.'**
  String get myQuotesEmpty;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashActive.
  ///
  /// In en, this message translates to:
  /// **'Active quotes'**
  String get dashActive;

  /// No description provided for @dashWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get dashWon;

  /// No description provided for @dashWinRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get dashWinRate;

  /// No description provided for @dashResponse.
  ///
  /// In en, this message translates to:
  /// **'Avg. response'**
  String get dashResponse;

  /// No description provided for @dashRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue logged'**
  String get dashRevenue;

  /// No description provided for @dashRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get dashRating;

  /// No description provided for @dashQuotesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Quotes this month'**
  String get dashQuotesThisMonth;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String hoursShort(int count);

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan and billing'**
  String get planTitle;

  /// No description provided for @planFreeLaunch.
  ///
  /// In en, this message translates to:
  /// **'Everything is free during launch.'**
  String get planFreeLaunch;

  /// No description provided for @planFoundingPartner.
  ///
  /// In en, this message translates to:
  /// **'As a founding partner you keep free access until {date}.'**
  String planFoundingPartner(String date);

  /// No description provided for @planCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current plan: {tier}'**
  String planCurrent(String tier);

  /// No description provided for @planFreeTier.
  ///
  /// In en, this message translates to:
  /// **'Free: {count} quotes a month'**
  String planFreeTier(int count);

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get planAnnual;

  /// No description provided for @planSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get planSubscribe;

  /// No description provided for @planCredits.
  ///
  /// In en, this message translates to:
  /// **'Quote credits'**
  String get planCredits;

  /// No description provided for @planCreditsBalance.
  ///
  /// In en, this message translates to:
  /// **'{count} credits left'**
  String planCreditsBalance(int count);

  /// No description provided for @planBuyCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy credits'**
  String get planBuyCredits;

  /// No description provided for @planRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get planRestore;

  /// No description provided for @planManage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get planManage;

  /// No description provided for @planFixPayment.
  ///
  /// In en, this message translates to:
  /// **'There\'s a problem with your payment. Update it to keep your plan.'**
  String get planFixPayment;

  /// No description provided for @planRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically. Cancel anytime in {store}.'**
  String planRenewal(String store);

  /// No description provided for @planBuyOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Buy on our website'**
  String get planBuyOnWeb;

  /// No description provided for @planNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Plans aren\'t available in the app yet.'**
  String get planNotAvailable;

  /// No description provided for @sellerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get sellerProfileTitle;

  /// No description provided for @sellerViewPublic.
  ///
  /// In en, this message translates to:
  /// **'View as buyers see it'**
  String get sellerViewPublic;

  /// No description provided for @sellerDirectoryOptIn.
  ///
  /// In en, this message translates to:
  /// **'Show my business on the {app} website'**
  String sellerDirectoryOptIn(String app);

  /// No description provided for @sellerDirectoryOptInBody.
  ///
  /// In en, this message translates to:
  /// **'Shows your business name, categories, city, rating and response time on a public page. Never your phone number or address.'**
  String get sellerDirectoryOptInBody;

  /// No description provided for @sellerDirectoryOptInOn.
  ///
  /// In en, this message translates to:
  /// **'You\'re listed. Your page appears on the website after the next nightly update.'**
  String get sellerDirectoryOptInOn;

  /// No description provided for @sellerDirectoryOptInOff.
  ///
  /// In en, this message translates to:
  /// **'Hidden. Your page is removed from the website at the next nightly update.'**
  String get sellerDirectoryOptInOff;

  /// No description provided for @sellerShareShop.
  ///
  /// In en, this message translates to:
  /// **'Share my shop'**
  String get sellerShareShop;

  /// No description provided for @sellerShareText.
  ///
  /// In en, this message translates to:
  /// **'Get quotes from {shop} and other local shops on {app}: {link}'**
  String sellerShareText(String shop, String app, String link);

  /// No description provided for @sellerYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year in business} other{{count} years in business}}'**
  String sellerYears(int count);

  /// No description provided for @sellerRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count})'**
  String sellerRating(String rating, int count);

  /// No description provided for @sellerResponds.
  ///
  /// In en, this message translates to:
  /// **'Usually replies in {time}'**
  String sellerResponds(String time);

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

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

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help and FAQ'**
  String get settingsHelp;

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegal;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicenses;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlocked;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @notifPrefNewQuotes.
  ///
  /// In en, this message translates to:
  /// **'New quotes'**
  String get notifPrefNewQuotes;

  /// No description provided for @notifPrefMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifPrefMessages;

  /// No description provided for @notifPrefLeads.
  ///
  /// In en, this message translates to:
  /// **'New leads'**
  String get notifPrefLeads;

  /// No description provided for @notifPrefMarketing.
  ///
  /// In en, this message translates to:
  /// **'Offers and tips'**
  String get notifPrefMarketing;

  /// No description provided for @privacyAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage data'**
  String get privacyAnalytics;

  /// No description provided for @privacyDoNotSell.
  ///
  /// In en, this message translates to:
  /// **'Do Not Sell or Share My Personal Information'**
  String get privacyDoNotSell;

  /// No description provided for @privacyDownload.
  ///
  /// In en, this message translates to:
  /// **'Request a copy of my data'**
  String get privacyDownload;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, requests, quotes, chats and photos. Some records, such as completed orders and tax invoices, are kept as required by law and then deleted.'**
  String get deleteBody;

  /// No description provided for @deleteConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteConfirmLabel;

  /// No description provided for @deleteConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteConfirmWord;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteButton;

  /// No description provided for @deleteReauth.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again before deleting.'**
  String get deleteReauth;

  /// No description provided for @deleteDone.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteDone;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help and FAQ'**
  String get helpTitle;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'Is it free for buyers?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Yes. Posting requests and receiving quotes is always free.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I pay the seller?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'You pay the seller directly, by the methods they accept. Record the payment in the order for your records.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'When does the seller see my phone and address?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'Only after you accept their quote. Before that, you can chat in the app.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'How do sellers get verified?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'They submit business documents that our team reviews.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I report a problem?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'Use Report on any chat, quote or profile, or contact support.'**
  String get faqA5;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abusive or offensive'**
  String get reportReasonAbuse;

  /// No description provided for @reportReasonFake.
  ///
  /// In en, this message translates to:
  /// **'Fake business or request'**
  String get reportReasonFake;

  /// No description provided for @reportReasonProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited item'**
  String get reportReasonProhibited;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetails;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Our team will review it.'**
  String get reportSent;

  /// No description provided for @blockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block {name}? You won\'t see their quotes or messages.'**
  String blockConfirm(String name);

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @inAppReviewAsk.
  ///
  /// In en, this message translates to:
  /// **'Enjoying {app}?'**
  String inAppReviewAsk(String app);

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please update the app to continue.'**
  String get updateRequired;

  /// No description provided for @permissionLocationRationale.
  ///
  /// In en, this message translates to:
  /// **'We use your location to find sellers near you. It is only shared as your area until you accept a quote.'**
  String get permissionLocationRationale;

  /// No description provided for @permissionNotificationsRationale.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to hear about new quotes and messages right away.'**
  String get permissionNotificationsRationale;

  /// No description provided for @permissionMicRationale.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone to describe your request by voice.'**
  String get permissionMicRationale;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account unavailable'**
  String get accountBlockedTitle;

  /// No description provided for @accountSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended until {date}. You can still read our policies or contact support.'**
  String accountSuspendedBody(String date);

  /// No description provided for @accountSuspendedBodyNoDate.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended. You can still read our policies or contact support.'**
  String get accountSuspendedBodyNoDate;

  /// No description provided for @accountBannedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been closed for breaking our rules. If you think this is a mistake, contact support.'**
  String get accountBannedBody;

  /// No description provided for @accountDeletedBody.
  ///
  /// In en, this message translates to:
  /// **'This account has been deleted.'**
  String get accountDeletedBody;

  /// No description provided for @tabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tabCommunity;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @communitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'See what people nearby need, comment, and team up for bulk prices.'**
  String get communitySubtitle;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @feedFilterGroupBuys.
  ///
  /// In en, this message translates to:
  /// **'Group buys'**
  String get feedFilterGroupBuys;

  /// No description provided for @feedFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get feedFilterOpen;

  /// No description provided for @feedFilterMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get feedFilterMine;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Post what you need and share it on the feed.'**
  String get feedEmpty;

  /// No description provided for @feedPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get feedPostTitle;

  /// No description provided for @feedPostGone.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer on the feed.'**
  String get feedPostGone;

  /// No description provided for @feedLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get feedLike;

  /// No description provided for @feedComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get feedComment;

  /// No description provided for @feedLikes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No likes} =1{1 like} other{{count} likes}}'**
  String feedLikes(int count);

  /// No description provided for @feedCommentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No comments} =1{1 comment} other{{count} comments}}'**
  String feedCommentsCount(int count);

  /// No description provided for @feedQuotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No quotes yet} =1{1 quote} other{{count} quotes}}'**
  String feedQuotesCount(int count);

  /// No description provided for @feedYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get feedYou;

  /// No description provided for @feedOnFeed.
  ///
  /// In en, this message translates to:
  /// **'On community feed'**
  String get feedOnFeed;

  /// No description provided for @feedPublish.
  ///
  /// In en, this message translates to:
  /// **'Share on community feed'**
  String get feedPublish;

  /// No description provided for @feedUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Remove from community feed'**
  String get feedUnpublish;

  /// No description provided for @feedOpenPost.
  ///
  /// In en, this message translates to:
  /// **'View community post'**
  String get feedOpenPost;

  /// No description provided for @feedPublished.
  ///
  /// In en, this message translates to:
  /// **'Shared on the community feed'**
  String get feedPublished;

  /// No description provided for @feedUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Removed from the community feed'**
  String get feedUnpublished;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation.'**
  String get commentsEmpty;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get commentHint;

  /// No description provided for @commentReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentReply;

  /// No description provided for @commentReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String commentReplyingTo(String name);

  /// No description provided for @commentAsBusiness.
  ///
  /// In en, this message translates to:
  /// **'Post as my business'**
  String get commentAsBusiness;

  /// No description provided for @commentSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commentSend;

  /// No description provided for @commentAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get commentAuthor;

  /// No description provided for @commentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get commentDeleteConfirm;

  /// No description provided for @commentBlockedContent.
  ///
  /// In en, this message translates to:
  /// **'That mentions something that is not allowed here.'**
  String get commentBlockedContent;

  /// No description provided for @commentTooLong.
  ///
  /// In en, this message translates to:
  /// **'That comment is too long.'**
  String get commentTooLong;

  /// No description provided for @communityRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You are doing that too often. Try again in a few minutes.'**
  String get communityRateLimited;

  /// No description provided for @groupBuyBadge.
  ///
  /// In en, this message translates to:
  /// **'Group buy'**
  String get groupBuyBadge;

  /// No description provided for @groupBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Group buy'**
  String get groupBuyTitle;

  /// No description provided for @groupBuyExplainer.
  ///
  /// In en, this message translates to:
  /// **'More people joining means a bigger order, so sellers offer a lower price per unit.'**
  String get groupBuyExplainer;

  /// No description provided for @groupJoinedSummary.
  ///
  /// In en, this message translates to:
  /// **'{members, plural, =1{1 person} other{{members} people}} · {qty} {unit}'**
  String groupJoinedSummary(int members, String qty, String unit);

  /// No description provided for @groupPriceEach.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String groupPriceEach(String price);

  /// No description provided for @groupBestNow.
  ///
  /// In en, this message translates to:
  /// **'Best price now'**
  String get groupBestNow;

  /// No description provided for @groupNextTier.
  ///
  /// In en, this message translates to:
  /// **'{qty} more {unit} unlocks {price} each'**
  String groupNextTier(String qty, String unit, String price);

  /// No description provided for @groupNoOffers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sellers\' bulk offers'**
  String get groupNoOffers;

  /// No description provided for @groupLadderTitle.
  ///
  /// In en, this message translates to:
  /// **'Price as the group grows'**
  String get groupLadderTitle;

  /// No description provided for @groupTierFrom.
  ///
  /// In en, this message translates to:
  /// **'{qty}+ {unit}'**
  String groupTierFrom(String qty, String unit);

  /// No description provided for @groupCurrentTier.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get groupCurrentTier;

  /// No description provided for @groupJoin.
  ///
  /// In en, this message translates to:
  /// **'Join group buy'**
  String get groupJoin;

  /// No description provided for @groupChangeQty.
  ///
  /// In en, this message translates to:
  /// **'Change quantity'**
  String get groupChangeQty;

  /// No description provided for @groupLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupLeave;

  /// No description provided for @groupJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'How many {unit} do you need?'**
  String groupJoinTitle(String unit);

  /// No description provided for @groupQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get groupQtyLabel;

  /// No description provided for @groupNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the group (optional)'**
  String get groupNoteLabel;

  /// No description provided for @groupJoinPrivacy.
  ///
  /// In en, this message translates to:
  /// **'If the organiser accepts an offer, that seller gets your name and phone number to arrange your order.'**
  String get groupJoinPrivacy;

  /// No description provided for @groupYouJoined.
  ///
  /// In en, this message translates to:
  /// **'You\'re in for {qty} {unit}'**
  String groupYouJoined(String qty, String unit);

  /// No description provided for @groupJoinedToast.
  ///
  /// In en, this message translates to:
  /// **'You joined the group buy'**
  String get groupJoinedToast;

  /// No description provided for @groupLeftToast.
  ///
  /// In en, this message translates to:
  /// **'You left the group buy'**
  String get groupLeftToast;

  /// No description provided for @groupClosed.
  ///
  /// In en, this message translates to:
  /// **'This group buy is closed'**
  String get groupClosed;

  /// No description provided for @groupWinner.
  ///
  /// In en, this message translates to:
  /// **'Accepted offer: {seller}'**
  String groupWinner(String seller);

  /// No description provided for @groupWinnerContact.
  ///
  /// In en, this message translates to:
  /// **'The seller will contact you to arrange your order.'**
  String get groupWinnerContact;

  /// No description provided for @groupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembersTitle;

  /// No description provided for @groupOrganiser.
  ///
  /// In en, this message translates to:
  /// **'Organiser'**
  String get groupOrganiser;

  /// No description provided for @groupHasMembers.
  ///
  /// In en, this message translates to:
  /// **'People have joined this group buy, so it has to stay on the feed.'**
  String get groupHasMembers;

  /// No description provided for @groupInvalidQty.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity between 1 and 1000'**
  String get groupInvalidQty;

  /// No description provided for @postToFeed.
  ///
  /// In en, this message translates to:
  /// **'Share on the community feed'**
  String get postToFeed;

  /// No description provided for @postToFeedHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone can see it and comment. Your phone number and address stay private.'**
  String get postToFeedHint;

  /// No description provided for @postGroupBuy.
  ///
  /// In en, this message translates to:
  /// **'Make it a group buy'**
  String get postGroupBuy;

  /// No description provided for @postGroupBuyHint.
  ///
  /// In en, this message translates to:
  /// **'Others can join with their quantity, and sellers offer lower prices for bigger orders.'**
  String get postGroupBuyHint;

  /// No description provided for @postGroupUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get postGroupUnit;

  /// No description provided for @postGroupUnitHint.
  ///
  /// In en, this message translates to:
  /// **'fans, kg, boxes…'**
  String get postGroupUnitHint;

  /// No description provided for @postGroupMyQty.
  ///
  /// In en, this message translates to:
  /// **'How many do you need?'**
  String get postGroupMyQty;

  /// No description provided for @quoteTiersTitle.
  ///
  /// In en, this message translates to:
  /// **'Group price tiers'**
  String get quoteTiersTitle;

  /// No description provided for @quoteTiersHint.
  ///
  /// In en, this message translates to:
  /// **'This is a group buy. Offer a lower price per unit as the group grows (before tax).'**
  String get quoteTiersHint;

  /// No description provided for @quoteTiersGroupNow.
  ///
  /// In en, this message translates to:
  /// **'Group so far: {qty} {unit}'**
  String quoteTiersGroupNow(String qty, String unit);

  /// No description provided for @quoteTierMinQty.
  ///
  /// In en, this message translates to:
  /// **'From qty'**
  String get quoteTierMinQty;

  /// No description provided for @quoteTierUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Price each'**
  String get quoteTierUnitPrice;

  /// No description provided for @quoteTierAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tier'**
  String get quoteTierAdd;

  /// No description provided for @quoteTiersInvalid.
  ///
  /// In en, this message translates to:
  /// **'Each tier needs a bigger quantity and a lower price than the one before.'**
  String get quoteTiersInvalid;

  /// No description provided for @notifFeedComment.
  ///
  /// In en, this message translates to:
  /// **'New comment on \"{title}\"'**
  String notifFeedComment(String title);

  /// No description provided for @notifFeedReply.
  ///
  /// In en, this message translates to:
  /// **'New reply on \"{title}\"'**
  String notifFeedReply(String title);

  /// No description provided for @notifGroupJoined.
  ///
  /// In en, this message translates to:
  /// **'Someone joined your group buy \"{title}\"'**
  String notifGroupJoined(String title);

  /// No description provided for @notifGroupGrew.
  ///
  /// In en, this message translates to:
  /// **'The group buy \"{title}\" grew'**
  String notifGroupGrew(String title);

  /// No description provided for @notifGroupPriceDrop.
  ///
  /// In en, this message translates to:
  /// **'Price dropped on \"{title}\"'**
  String notifGroupPriceDrop(String title);

  /// No description provided for @notifGroupAwarded.
  ///
  /// In en, this message translates to:
  /// **'The organiser picked a seller for \"{title}\"'**
  String notifGroupAwarded(String title);

  /// No description provided for @notifQuoteTiers.
  ///
  /// In en, this message translates to:
  /// **'A seller added group prices'**
  String get notifQuoteTiers;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

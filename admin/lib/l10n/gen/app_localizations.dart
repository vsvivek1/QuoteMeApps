import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'{app} Admin'**
  String adminTitle(String app);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'DEMO DATA'**
  String get demoMode;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Administrators only. Sign in with your admin email and password.'**
  String get loginSubtitle;

  /// No description provided for @loginNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'This account does not have the admin role. Access refused.'**
  String get loginNotAdmin;

  /// No description provided for @loginInvalid.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get loginInvalid;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @demoLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: sign in with {email} / {password}. Nothing is sent anywhere.'**
  String demoLoginHint(String email, String password);

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get navVerification;

  /// No description provided for @navModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get navModeration;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get navFlags;

  /// No description provided for @navOutreach.
  ///
  /// In en, this message translates to:
  /// **'Outreach CRM'**
  String get navOutreach;

  /// No description provided for @navBrochures.
  ///
  /// In en, this message translates to:
  /// **'Brochures'**
  String get navBrochures;

  /// No description provided for @dashQueues.
  ///
  /// In en, this message translates to:
  /// **'Queues'**
  String get dashQueues;

  /// No description provided for @dashMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace (Section 13)'**
  String get dashMarketplace;

  /// No description provided for @dashRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get dashRetention;

  /// No description provided for @dashOutreach.
  ///
  /// In en, this message translates to:
  /// **'Seller acquisition'**
  String get dashOutreach;

  /// No description provided for @kpiPendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'Pending verifications'**
  String get kpiPendingVerifications;

  /// No description provided for @kpiPendingLicences.
  ///
  /// In en, this message translates to:
  /// **'Pending licences'**
  String get kpiPendingLicences;

  /// No description provided for @kpiOpenReports.
  ///
  /// In en, this message translates to:
  /// **'Open reports'**
  String get kpiOpenReports;

  /// No description provided for @kpiTimeToFirstQuote.
  ///
  /// In en, this message translates to:
  /// **'Time to first quote (median)'**
  String get kpiTimeToFirstQuote;

  /// No description provided for @kpiTimeToFirstQuoteHint.
  ///
  /// In en, this message translates to:
  /// **'Target: under 2 h in metros'**
  String get kpiTimeToFirstQuoteHint;

  /// No description provided for @kpiRequests3Quotes.
  ///
  /// In en, this message translates to:
  /// **'Requests with 3+ quotes'**
  String get kpiRequests3Quotes;

  /// No description provided for @kpiRequestToAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Request to acceptance'**
  String get kpiRequestToAcceptance;

  /// No description provided for @kpiSellerResponseRate.
  ///
  /// In en, this message translates to:
  /// **'Seller response rate'**
  String get kpiSellerResponseRate;

  /// No description provided for @kpiFreeToPaid.
  ///
  /// In en, this message translates to:
  /// **'Seller free-to-paid'**
  String get kpiFreeToPaid;

  /// No description provided for @kpiRevenuePerSeller.
  ///
  /// In en, this message translates to:
  /// **'Revenue per seller'**
  String get kpiRevenuePerSeller;

  /// No description provided for @kpiRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds (30 days)'**
  String get kpiRefunds;

  /// No description provided for @kpiOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get kpiOpenRequests;

  /// No description provided for @kpiRequests7d.
  ///
  /// In en, this message translates to:
  /// **'Requests (7 days)'**
  String get kpiRequests7d;

  /// No description provided for @kpiQuotes7d.
  ///
  /// In en, this message translates to:
  /// **'Quotes (7 days)'**
  String get kpiQuotes7d;

  /// No description provided for @kpiOrders7d.
  ///
  /// In en, this message translates to:
  /// **'Orders (7 days)'**
  String get kpiOrders7d;

  /// No description provided for @kpiUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get kpiUsers;

  /// No description provided for @kpiSellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get kpiSellers;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get verified;

  /// No description provided for @kpiReplyRate.
  ///
  /// In en, this message translates to:
  /// **'Reply rate'**
  String get kpiReplyRate;

  /// No description provided for @kpiSignupRate.
  ///
  /// In en, this message translates to:
  /// **'Signup rate'**
  String get kpiSignupRate;

  /// No description provided for @kpiSentToday.
  ///
  /// In en, this message translates to:
  /// **'Sent today / daily cap'**
  String get kpiSentToday;

  /// No description provided for @kpiQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue (sourced, enrolled)'**
  String get kpiQueue;

  /// No description provided for @kpiQueueDays.
  ///
  /// In en, this message translates to:
  /// **'about {days} days at current cap'**
  String kpiQueueDays(int days);

  /// No description provided for @verificationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents waiting for review.'**
  String get verificationEmpty;

  /// No description provided for @docNotAvailableDemo.
  ///
  /// In en, this message translates to:
  /// **'Documents are not available in demo mode.'**
  String get docNotAvailableDemo;

  /// No description provided for @rejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject: reason'**
  String get rejectTitle;

  /// No description provided for @rejectHint.
  ///
  /// In en, this message translates to:
  /// **'Tell the seller what to fix (they will see this).'**
  String get rejectHint;

  /// No description provided for @approveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveTitle;

  /// No description provided for @approveBody.
  ///
  /// In en, this message translates to:
  /// **'Approve this document for {business}? The seller gets the verified badge.'**
  String approveBody(String business);

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @licence.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get licence;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @issuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuer;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'submitted'**
  String get submitted;

  /// No description provided for @sellerStatus.
  ///
  /// In en, this message translates to:
  /// **'Seller status'**
  String get sellerStatus;

  /// No description provided for @noFile.
  ///
  /// In en, this message translates to:
  /// **'No file'**
  String get noFile;

  /// No description provided for @viewDocument.
  ///
  /// In en, this message translates to:
  /// **'View document'**
  String get viewDocument;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @tabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tabReports;

  /// No description provided for @tabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get tabUsers;

  /// No description provided for @tabAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get tabAuditLog;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open reports.'**
  String get reportsEmpty;

  /// No description provided for @resolveTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve report'**
  String get resolveTitle;

  /// No description provided for @resolveNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note for the audit log'**
  String get resolveNoteHint;

  /// No description provided for @reportsResolved.
  ///
  /// In en, this message translates to:
  /// **'{count} report(s) resolved'**
  String reportsResolved(int count);

  /// No description provided for @banTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban user: reason'**
  String get banTitle;

  /// No description provided for @banHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (kept in the audit log)'**
  String get banHint;

  /// No description provided for @userBanned.
  ///
  /// In en, this message translates to:
  /// **'User banned'**
  String get userBanned;

  /// No description provided for @reportCount.
  ///
  /// In en, this message translates to:
  /// **'{count} report(s)'**
  String reportCount(int count);

  /// No description provided for @reporterSays.
  ///
  /// In en, this message translates to:
  /// **'Reporter says'**
  String get reporterSays;

  /// No description provided for @hideContent.
  ///
  /// In en, this message translates to:
  /// **'Hide content'**
  String get hideContent;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @banUser.
  ///
  /// In en, this message translates to:
  /// **'Ban user'**
  String get banUser;

  /// No description provided for @suspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend for 7 days: reason'**
  String get suspendTitle;

  /// No description provided for @userStatusSet.
  ///
  /// In en, this message translates to:
  /// **'User status set to {status}'**
  String userStatusSet(String status);

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, email or phone, then press Enter'**
  String get searchUsersHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// No description provided for @suspend7d.
  ///
  /// In en, this message translates to:
  /// **'Suspend 7 days'**
  String get suspend7d;

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No admin actions logged yet.'**
  String get auditEmpty;

  /// No description provided for @categoriesIntro.
  ///
  /// In en, this message translates to:
  /// **'Category policy for {app}. Restricted categories need a licence type; anything uncertain stays blocked until legal sign-off.'**
  String categoriesIntro(String app);

  /// No description provided for @policyAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get policyAllowed;

  /// No description provided for @policyRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get policyRestricted;

  /// No description provided for @policyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get policyBlocked;

  /// No description provided for @licenceType.
  ///
  /// In en, this message translates to:
  /// **'Required licence type'**
  String get licenceType;

  /// No description provided for @licenceTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'e.g. state_contractor_licence, rera, nmc_registration'**
  String get licenceTypeHelp;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get inactive;

  /// No description provided for @policyReasonEn.
  ///
  /// In en, this message translates to:
  /// **'Reason shown to users (English)'**
  String get policyReasonEn;

  /// No description provided for @disclaimerEn.
  ///
  /// In en, this message translates to:
  /// **'Regulatory disclaimer (English)'**
  String get disclaimerEn;

  /// No description provided for @names.
  ///
  /// In en, this message translates to:
  /// **'Names'**
  String get names;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @unblockWarning.
  ///
  /// In en, this message translates to:
  /// **'Make sure a lawyer has confirmed this category may be quoted in this country.'**
  String get unblockWarning;

  /// No description provided for @outreachFlag.
  ///
  /// In en, this message translates to:
  /// **'Seller outreach engine (Section 21)'**
  String get outreachFlag;

  /// No description provided for @outreachFlagHelp.
  ///
  /// In en, this message translates to:
  /// **'Off stops every outreach send. Sending is always manual.'**
  String get outreachFlagHelp;

  /// No description provided for @remoteFlags.
  ///
  /// In en, this message translates to:
  /// **'Remote flags and limits'**
  String get remoteFlags;

  /// No description provided for @remoteFlagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Stored in app_settings for this country project. Public flags are read by the apps and mirrored to Remote Config by the backend.'**
  String get remoteFlagsHelp;

  /// No description provided for @publicFlag.
  ///
  /// In en, this message translates to:
  /// **'public'**
  String get publicFlag;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get invalidNumber;

  /// No description provided for @monetizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Monetization switch'**
  String get monetizationTitle;

  /// No description provided for @monetizationOn.
  ///
  /// In en, this message translates to:
  /// **'On: paid plans and paywalls are live.'**
  String get monetizationOn;

  /// No description provided for @monetizationOff.
  ///
  /// In en, this message translates to:
  /// **'Off: everything is free for sellers and no paywall is shown.'**
  String get monetizationOff;

  /// No description provided for @monetizationOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn monetization on?'**
  String get monetizationOnTitle;

  /// No description provided for @monetizationOnBody.
  ///
  /// In en, this message translates to:
  /// **'Paywalls go live for new sellers. Early partners stay free until {date} (6 months from today if not set).'**
  String monetizationOnBody(String date);

  /// No description provided for @monetizationOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn monetization off?'**
  String get monetizationOffTitle;

  /// No description provided for @monetizationOffBody.
  ///
  /// In en, this message translates to:
  /// **'All seller features become free again and paywalls are hidden.'**
  String get monetizationOffBody;

  /// No description provided for @earlyPartnerUntil.
  ///
  /// In en, this message translates to:
  /// **'Early partners free until'**
  String get earlyPartnerUntil;

  /// No description provided for @notSetYet.
  ///
  /// In en, this message translates to:
  /// **'not set yet'**
  String get notSetYet;

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get changeDate;

  /// No description provided for @earlyPartnerHelp.
  ///
  /// In en, this message translates to:
  /// **'Outreach and brochures always state this end date. Never promise free for life.'**
  String get earlyPartnerHelp;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @tabBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get tabBoard;

  /// No description provided for @tabSuppression.
  ///
  /// In en, this message translates to:
  /// **'Suppression'**
  String get tabSuppression;

  /// No description provided for @tabCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get tabCampaigns;

  /// No description provided for @tabCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get tabCoverage;

  /// No description provided for @enrolTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrol {count} lead(s) in a campaign'**
  String enrolTitle(int count);

  /// No description provided for @enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled. Each send still needs a person.'**
  String get enrolled;

  /// No description provided for @moveSelected.
  ///
  /// In en, this message translates to:
  /// **'Move {count} lead(s) to'**
  String moveSelected(int count);

  /// No description provided for @movedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lead(s) moved'**
  String movedCount(int count);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @enrolInCampaign.
  ///
  /// In en, this message translates to:
  /// **'Enrol in campaign'**
  String get enrolInCampaign;

  /// No description provided for @moveStage.
  ///
  /// In en, this message translates to:
  /// **'Move stage'**
  String get moveStage;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportAllCsv.
  ///
  /// In en, this message translates to:
  /// **'Export all (CSV)'**
  String get exportAllCsv;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @leadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} leads'**
  String leadCount(int count);

  /// No description provided for @searchLeads.
  ///
  /// In en, this message translates to:
  /// **'Search leads'**
  String get searchLeads;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @noMatchedCategory.
  ///
  /// In en, this message translates to:
  /// **'No matched category (not contactable)'**
  String get noMatchedCategory;

  /// No description provided for @touches.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 touches'**
  String touches(int count);

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'due'**
  String get due;

  /// No description provided for @addSuppression.
  ///
  /// In en, this message translates to:
  /// **'Add to suppression list'**
  String get addSuppression;

  /// No description provided for @domain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domain;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @suppressionPermanent.
  ///
  /// In en, this message translates to:
  /// **'Suppression is shared across all inboxes and channels and is permanent.'**
  String get suppressionPermanent;

  /// No description provided for @suppressionIntro.
  ///
  /// In en, this message translates to:
  /// **'Every send checks this list. Unsubscribes, hard bounces, complaints and negative replies land here automatically.'**
  String get suppressionIntro;

  /// No description provided for @suppressionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing suppressed yet.'**
  String get suppressionEmpty;

  /// No description provided for @sendCapacity.
  ///
  /// In en, this message translates to:
  /// **'Sent today: {sent} of {cap} (global daily ceiling)'**
  String sendCapacity(int sent, int cap);

  /// No description provided for @sendCapacityHelp.
  ///
  /// In en, this message translates to:
  /// **'Per recipient domain: {domain}/day. Brakes pause a campaign above {bounce}% bounces, {complaint}% complaints or {negative}% negative replies.'**
  String sendCapacityHelp(
    int domain,
    String bounce,
    String complaint,
    String negative,
  );

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @dailyCap.
  ///
  /// In en, this message translates to:
  /// **'Daily cap'**
  String get dailyCap;

  /// No description provided for @pausedReason.
  ///
  /// In en, this message translates to:
  /// **'Paused because'**
  String get pausedReason;

  /// No description provided for @campaignHealth.
  ///
  /// In en, this message translates to:
  /// **'30 days: {sent} sent, bounces {bounce}, complaints {complaint}, negative {negative}'**
  String campaignHealth(
    int sent,
    String bounce,
    String complaint,
    String negative,
  );

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume campaign?'**
  String get resumeTitle;

  /// No description provided for @resumeBody.
  ///
  /// In en, this message translates to:
  /// **'Sending stays manual and every cap still applies.'**
  String get resumeBody;

  /// No description provided for @resumeBrakeBody.
  ///
  /// In en, this message translates to:
  /// **'This campaign was paused by an automatic brake. Fix the cause (list quality, content) before resuming.'**
  String get resumeBrakeBody;

  /// No description provided for @coverageIntro.
  ///
  /// In en, this message translates to:
  /// **'Sellers per city and category. Areas with fewer than 5 sellers need outreach first.'**
  String get coverageIntro;

  /// No description provided for @sellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get sellers;

  /// No description provided for @liquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get liquidity;

  /// No description provided for @needsSellers.
  ///
  /// In en, this message translates to:
  /// **'Needs sellers'**
  String get needsSellers;

  /// No description provided for @stageSourced.
  ///
  /// In en, this message translates to:
  /// **'Sourced'**
  String get stageSourced;

  /// No description provided for @stageContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get stageContacted;

  /// No description provided for @stageReplied.
  ///
  /// In en, this message translates to:
  /// **'Replied'**
  String get stageReplied;

  /// No description provided for @stageOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get stageOnboarding;

  /// No description provided for @stageLiveSeller.
  ///
  /// In en, this message translates to:
  /// **'Live seller'**
  String get stageLiveSeller;

  /// No description provided for @stageActive.
  ///
  /// In en, this message translates to:
  /// **'Active (first quote)'**
  String get stageActive;

  /// No description provided for @stageNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get stageNotInterested;

  /// No description provided for @stageDoNotContact.
  ///
  /// In en, this message translates to:
  /// **'Do not contact'**
  String get stageDoNotContact;

  /// No description provided for @trNoChange.
  ///
  /// In en, this message translates to:
  /// **'The lead is already in that stage.'**
  String get trNoChange;

  /// No description provided for @trNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'That move is not allowed: the pipeline only moves forward, so a finished conversation is never restarted.'**
  String get trNotAllowed;

  /// No description provided for @trTerminal.
  ///
  /// In en, this message translates to:
  /// **'Do not contact is permanent.'**
  String get trTerminal;

  /// No description provided for @trNeedsSellerLink.
  ///
  /// In en, this message translates to:
  /// **'Link the lead to a seller account first (it happens when they sign up).'**
  String get trNeedsSellerLink;

  /// No description provided for @trNeedsLoggedContact.
  ///
  /// In en, this message translates to:
  /// **'Log the call, visit or 1:1 message first.'**
  String get trNeedsLoggedContact;

  /// No description provided for @rule0.
  ///
  /// In en, this message translates to:
  /// **'A person confirms every send'**
  String get rule0;

  /// No description provided for @rule1.
  ///
  /// In en, this message translates to:
  /// **'Relevance only'**
  String get rule1;

  /// No description provided for @rule2.
  ///
  /// In en, this message translates to:
  /// **'One conversation per business, max 3 touches'**
  String get rule2;

  /// No description provided for @rule3.
  ///
  /// In en, this message translates to:
  /// **'Verified, business-published address'**
  String get rule3;

  /// No description provided for @rule4.
  ///
  /// In en, this message translates to:
  /// **'Short, plain, personal, honest'**
  String get rule4;

  /// No description provided for @rule5.
  ///
  /// In en, this message translates to:
  /// **'Easy, respected opt-out'**
  String get rule5;

  /// No description provided for @rule6.
  ///
  /// In en, this message translates to:
  /// **'Volume caps and business hours'**
  String get rule6;

  /// No description provided for @rule7.
  ///
  /// In en, this message translates to:
  /// **'Automatic brakes'**
  String get rule7;

  /// No description provided for @rule8.
  ///
  /// In en, this message translates to:
  /// **'Honest identity'**
  String get rule8;

  /// No description provided for @rule9.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp/SMS only after opt-in'**
  String get rule9;

  /// No description provided for @rule10.
  ///
  /// In en, this message translates to:
  /// **'Businesses only, never consumers'**
  String get rule10;

  /// No description provided for @rule11.
  ///
  /// In en, this message translates to:
  /// **'Audit trail'**
  String get rule11;

  /// No description provided for @logContactFirst.
  ///
  /// In en, this message translates to:
  /// **'Moving to Contacted by hand needs a logged contact.'**
  String get logContactFirst;

  /// No description provided for @logContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Log contact'**
  String get logContactTitle;

  /// No description provided for @dncTitle.
  ///
  /// In en, this message translates to:
  /// **'Do not contact {business}?'**
  String dncTitle(String business);

  /// No description provided for @dncBody.
  ///
  /// In en, this message translates to:
  /// **'The business is added to the shared suppression list and will never be contacted again on any channel.'**
  String get dncBody;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {stage}'**
  String moveTo(String stage);

  /// No description provided for @movedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to {stage}'**
  String movedTo(String stage);

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get optionalNote;

  /// No description provided for @contactCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get contactCall;

  /// No description provided for @contactVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get contactVisit;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp 1:1'**
  String get contactWhatsApp;

  /// No description provided for @contactNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get contactNote;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappened;

  /// No description provided for @lead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get lead;

  /// No description provided for @whatsAppPitch.
  ///
  /// In en, this message translates to:
  /// **'Hello {business}, I am from {app}. Buyers in {city} post {category} requests and local businesses send quotes. Founding partners join free. Can I set up your shop? {link} (Reply STOP and I won\'t message again.)'**
  String whatsAppPitch(
    String business,
    String app,
    String category,
    String city,
    String link,
  );

  /// No description provided for @whatsAppManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Message on WhatsApp'**
  String get whatsAppManualTitle;

  /// No description provided for @whatsAppManualBody.
  ///
  /// In en, this message translates to:
  /// **'This opens WhatsApp with a pre-filled message for you to send personally, at a human pace. It is logged in the CRM.'**
  String get whatsAppManualBody;

  /// No description provided for @whatsAppManual.
  ///
  /// In en, this message translates to:
  /// **'Message on WhatsApp'**
  String get whatsAppManual;

  /// No description provided for @recordOptIn.
  ///
  /// In en, this message translates to:
  /// **'Record WhatsApp opt-in'**
  String get recordOptIn;

  /// No description provided for @optInProofHint.
  ///
  /// In en, this message translates to:
  /// **'How did they opt in? (replied, QR scan, signup form, in person)'**
  String get optInProofHint;

  /// No description provided for @prepareSend.
  ///
  /// In en, this message translates to:
  /// **'Prepare step {step}'**
  String prepareSend(int step);

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @sourceCategories.
  ///
  /// In en, this message translates to:
  /// **'Source tags'**
  String get sourceCategories;

  /// No description provided for @compliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get compliance;

  /// No description provided for @lawfulBasis.
  ///
  /// In en, this message translates to:
  /// **'Lawful basis'**
  String get lawfulBasis;

  /// No description provided for @addressSource.
  ///
  /// In en, this message translates to:
  /// **'Address published at'**
  String get addressSource;

  /// No description provided for @reasonChosen.
  ///
  /// In en, this message translates to:
  /// **'Why chosen'**
  String get reasonChosen;

  /// No description provided for @optIn.
  ///
  /// In en, this message translates to:
  /// **'Opt-in'**
  String get optIn;

  /// No description provided for @sequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get sequence;

  /// No description provided for @campaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaign;

  /// No description provided for @sellerAccount.
  ///
  /// In en, this message translates to:
  /// **'Seller account'**
  String get sellerAccount;

  /// No description provided for @notesAndNextAction.
  ///
  /// In en, this message translates to:
  /// **'Notes and next action'**
  String get notesAndNextAction;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next action'**
  String get nextAction;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Message history'**
  String get history;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noHistory;

  /// No description provided for @stepN.
  ///
  /// In en, this message translates to:
  /// **'step {step}'**
  String stepN(int step);

  /// No description provided for @sendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to {business} (step {step})'**
  String sendTitle(String business, int step);

  /// No description provided for @neverAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent automatically. Review the message; the checks below run here, again in the Edge Function and again in the database.'**
  String get neverAutomatic;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @approvedTemplate.
  ///
  /// In en, this message translates to:
  /// **'Approved WhatsApp template name'**
  String get approvedTemplate;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get body;

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{words} / {max} words'**
  String wordCount(int words, int max);

  /// No description provided for @footerPreview.
  ///
  /// In en, this message translates to:
  /// **'Footer added to every email'**
  String get footerPreview;

  /// No description provided for @confirmPersonalSend.
  ///
  /// In en, this message translates to:
  /// **'I reviewed this message and I am sending it to this business now.'**
  String get confirmPersonalSend;

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendNow;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @antiSpamChecks.
  ///
  /// In en, this message translates to:
  /// **'Anti-spam checks (Section 21.8)'**
  String get antiSpamChecks;

  /// No description provided for @serverRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused by the server: {reason}'**
  String serverRefused(String reason);

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 5 MB)'**
  String get fileTooLarge;

  /// No description provided for @importRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Compliant sources only'**
  String get importRulesTitle;

  /// No description provided for @importRules.
  ///
  /// In en, this message translates to:
  /// **'Allowed sources: osm, places (Google Places API), registry (public licence lists), website (the business\'s own contact page), inbound, referral, manual, field. Never scraped Google Maps, Yelp, YellowPages, Justdial or IndiaMART pages, bought lists, or consumer data. Rows that break these rules are rejected. Emails need the page where the business published them (address_source).'**
  String get importRules;

  /// No description provided for @importColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns: {columns}'**
  String importColumns(String columns);

  /// No description provided for @chooseCsv.
  ///
  /// In en, this message translates to:
  /// **'Choose CSV'**
  String get chooseCsv;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download template'**
  String get downloadTemplate;

  /// No description provided for @importReady.
  ///
  /// In en, this message translates to:
  /// **'{count} ready'**
  String importReady(int count);

  /// No description provided for @importRejected.
  ///
  /// In en, this message translates to:
  /// **'{count} rejected'**
  String importRejected(int count);

  /// No description provided for @importDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count} duplicates in file'**
  String importDuplicates(int count);

  /// No description provided for @importNoCategory.
  ///
  /// In en, this message translates to:
  /// **'{count} without a matched category'**
  String importNoCategory(int count);

  /// No description provided for @rejectedRows.
  ///
  /// In en, this message translates to:
  /// **'Rejected rows'**
  String get rejectedRows;

  /// No description provided for @rowReason.
  ///
  /// In en, this message translates to:
  /// **'Row {line}: {reason}'**
  String rowReason(int line, String reason);

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessName;

  /// No description provided for @importAttestation.
  ///
  /// In en, this message translates to:
  /// **'I confirm these are businesses from the compliant sources above, with no consumer data.'**
  String get importAttestation;

  /// No description provided for @importNow.
  ///
  /// In en, this message translates to:
  /// **'Import {count} leads'**
  String importNow(int count);

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {inserted}; {duplicates} already known (deduplicated).'**
  String importDone(int inserted, int duplicates);

  /// No description provided for @anyCityHelp.
  ///
  /// In en, this message translates to:
  /// **'Any city or town: outreach is nationwide.'**
  String get anyCityHelp;

  /// No description provided for @formatA4.
  ///
  /// In en, this message translates to:
  /// **'A4 PDF'**
  String get formatA4;

  /// No description provided for @formatA5.
  ///
  /// In en, this message translates to:
  /// **'A5 one-pager'**
  String get formatA5;

  /// No description provided for @formatImage.
  ///
  /// In en, this message translates to:
  /// **'1080x1350 image'**
  String get formatImage;

  /// No description provided for @foundingUntil.
  ///
  /// In en, this message translates to:
  /// **'Founding partner offer ends'**
  String get foundingUntil;

  /// No description provided for @foundingUntilRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a date: the offer always states its end date.'**
  String get foundingUntilRequired;

  /// No description provided for @fromSettings.
  ///
  /// In en, this message translates to:
  /// **'from settings'**
  String get fromSettings;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @saveToStorage.
  ///
  /// In en, this message translates to:
  /// **'Save to Storage'**
  String get saveToStorage;

  /// No description provided for @brochureSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String brochureSaved(String path);

  /// No description provided for @savedBrochures.
  ///
  /// In en, this message translates to:
  /// **'Saved brochures'**
  String get savedBrochures;

  /// No description provided for @noBrochures.
  ///
  /// In en, this message translates to:
  /// **'None yet.'**
  String get noBrochures;

  /// No description provided for @brochureIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Choose a city, category and offer end date.'**
  String get brochureIncomplete;

  /// No description provided for @navSellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get navSellers;

  /// No description provided for @sellersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Business name or phone number'**
  String get sellersSearchHint;

  /// No description provided for @sellersSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search sellers by business name (at least 2 letters) or phone number (at least 4 digits).'**
  String get sellersSearchPrompt;

  /// No description provided for @sellersNone.
  ///
  /// In en, this message translates to:
  /// **'No sellers match.'**
  String get sellersNone;

  /// No description provided for @openSeller.
  ///
  /// In en, this message translates to:
  /// **'Open seller'**
  String get openSeller;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerName;

  /// No description provided for @businessPhone.
  ///
  /// In en, this message translates to:
  /// **'Business phone'**
  String get businessPhone;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationStatus;

  /// No description provided for @foundingPartnerFreeUntil.
  ///
  /// In en, this message translates to:
  /// **'Founding partner, free until {date}'**
  String foundingPartnerFreeUntil(String date);

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @planNone.
  ///
  /// In en, this message translates to:
  /// **'No paid plan'**
  String get planNone;

  /// No description provided for @planProUntil.
  ///
  /// In en, this message translates to:
  /// **'Pro until {date}'**
  String planProUntil(String date);

  /// No description provided for @planProOpenEnded.
  ///
  /// In en, this message translates to:
  /// **'Pro (no end date)'**
  String get planProOpenEnded;

  /// No description provided for @creditsBalance.
  ///
  /// In en, this message translates to:
  /// **'Quote credits: {count}'**
  String creditsBalance(int count);

  /// No description provided for @planHistory.
  ///
  /// In en, this message translates to:
  /// **'Plan history'**
  String get planHistory;

  /// No description provided for @planHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plans granted or bought yet.'**
  String get planHistoryEmpty;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record manual payment'**
  String get recordPayment;

  /// No description provided for @recordPaymentIntro.
  ///
  /// In en, this message translates to:
  /// **'Only for a payment received outside the app (UPI or bank transfer). The seller gets the plan at once and the grant is written to the audit log.'**
  String get recordPaymentIntro;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @planProMonthly.
  ///
  /// In en, this message translates to:
  /// **'Pro monthly (30 days)'**
  String get planProMonthly;

  /// No description provided for @planProAnnual.
  ///
  /// In en, this message translates to:
  /// **'Pro annual (365 days)'**
  String get planProAnnual;

  /// No description provided for @planCredits10.
  ///
  /// In en, this message translates to:
  /// **'10 quote credits'**
  String get planCredits10;

  /// No description provided for @planCredits50.
  ///
  /// In en, this message translates to:
  /// **'50 quote credits'**
  String get planCredits50;

  /// No description provided for @planValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until the end of {date}'**
  String planValidUntil(String date);

  /// No description provided for @creditsNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'Credits do not expire.'**
  String get creditsNoExpiry;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @methodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get methodUpi;

  /// No description provided for @methodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get methodBankTransfer;

  /// No description provided for @methodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get methodOther;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received ({currency})'**
  String amountReceived(String currency);

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like 499 or 499.50'**
  String get amountInvalid;

  /// No description provided for @paymentReference.
  ///
  /// In en, this message translates to:
  /// **'Payment reference (UTR / transaction id)'**
  String get paymentReference;

  /// No description provided for @referenceInvalid.
  ///
  /// In en, this message translates to:
  /// **'4 to 64 letters or digits (. _ / - allowed)'**
  String get referenceInvalid;

  /// No description provided for @referenceUsed.
  ///
  /// In en, this message translates to:
  /// **'This reference was already used for a grant on {date}. One payment, one grant.'**
  String referenceUsed(String date);

  /// No description provided for @payerName.
  ///
  /// In en, this message translates to:
  /// **'Payer name (as on the bank statement)'**
  String get payerName;

  /// No description provided for @bankChecked.
  ///
  /// In en, this message translates to:
  /// **'I have checked this payment arrived in the company bank account'**
  String get bankChecked;

  /// No description provided for @grantPlan.
  ///
  /// In en, this message translates to:
  /// **'Grant plan'**
  String get grantPlan;

  /// No description provided for @grantDone.
  ///
  /// In en, this message translates to:
  /// **'Plan granted. {summary}'**
  String grantDone(String summary);

  /// No description provided for @manualPaymentLine.
  ///
  /// In en, this message translates to:
  /// **'{method} {currency} {amount}, ref {reference}'**
  String manualPaymentLine(
    String method,
    String currency,
    String amount,
    String reference,
  );

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'paid by {name}'**
  String paidBy(String name);

  /// No description provided for @navSeo.
  ///
  /// In en, this message translates to:
  /// **'SEO pages'**
  String get navSeo;

  /// No description provided for @seoTabPages.
  ///
  /// In en, this message translates to:
  /// **'Price pages'**
  String get seoTabPages;

  /// No description provided for @seoTabGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get seoTabGuides;

  /// No description provided for @seoRunExport.
  ///
  /// In en, this message translates to:
  /// **'Run export now'**
  String get seoRunExport;

  /// No description provided for @seoRunExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Run the SEO export now?'**
  String get seoRunExportTitle;

  /// No description provided for @seoRunExportBody.
  ///
  /// In en, this message translates to:
  /// **'Recomputes every city x category page from real quotes, uploads the anonymised data file to the public bucket and triggers the website rebuild when the Vercel Deploy Hook is configured. It also runs every night.'**
  String get seoRunExportBody;

  /// No description provided for @seoExportDone.
  ///
  /// In en, this message translates to:
  /// **'Export done: {pages} pages, {priced} with prices, {guides} guides. Deploy hook: {hook}.'**
  String seoExportDone(int pages, int priced, int guides, String hook);

  /// No description provided for @seoLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last export {when} by {by}: {indexable} indexable, {noindex} noindex, {waiting} waiting for data. Deploy hook: {hook}.'**
  String seoLastRun(
    String when,
    String by,
    int indexable,
    int noindex,
    int waiting,
    String hook,
  );

  /// No description provided for @seoLastRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Last export {when} failed: {error}'**
  String seoLastRunFailed(String when, String error);

  /// No description provided for @seoNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No export has run yet.'**
  String get seoNoRuns;

  /// No description provided for @seoStatusIndexable.
  ///
  /// In en, this message translates to:
  /// **'Indexable'**
  String get seoStatusIndexable;

  /// No description provided for @seoStatusNoindex.
  ///
  /// In en, this message translates to:
  /// **'Noindex'**
  String get seoStatusNoindex;

  /// No description provided for @seoStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data'**
  String get seoStatusWaiting;

  /// No description provided for @seoThresholds.
  ///
  /// In en, this message translates to:
  /// **'Quality gates'**
  String get seoThresholds;

  /// No description provided for @seoThresholdsHelp.
  ///
  /// In en, this message translates to:
  /// **'A city x category page is indexable with at least {quotes} quotes from {sellers} different sellers in the last {window} days and a quote within {stale} days. Below that it is noindex and left out of the sitemap. Prices are medians, never single quotes.'**
  String seoThresholdsHelp(int quotes, int sellers, int window, int stale);

  /// No description provided for @seoMinQuotes.
  ///
  /// In en, this message translates to:
  /// **'Min quotes'**
  String get seoMinQuotes;

  /// No description provided for @seoMinSellers.
  ///
  /// In en, this message translates to:
  /// **'Min sellers'**
  String get seoMinSellers;

  /// No description provided for @seoWindowDays.
  ///
  /// In en, this message translates to:
  /// **'Window (days)'**
  String get seoWindowDays;

  /// No description provided for @seoStaleDays.
  ///
  /// In en, this message translates to:
  /// **'Stale after (days)'**
  String get seoStaleDays;

  /// No description provided for @seoRange.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max}'**
  String seoRange(int min, int max);

  /// No description provided for @seoThresholdsTakeEffect.
  ///
  /// In en, this message translates to:
  /// **'New gates apply at the next export.'**
  String get seoThresholdsTakeEffect;

  /// No description provided for @seoColPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get seoColPage;

  /// No description provided for @seoColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get seoColStatus;

  /// No description provided for @seoColQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get seoColQuotes;

  /// No description provided for @seoColSellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get seoColSellers;

  /// No description provided for @seoColLocal.
  ///
  /// In en, this message translates to:
  /// **'Local sellers'**
  String get seoColLocal;

  /// No description provided for @seoColLastQuote.
  ///
  /// In en, this message translates to:
  /// **'Last quote'**
  String get seoColLastQuote;

  /// No description provided for @seoColUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get seoColUpdated;

  /// No description provided for @seoColReasons.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get seoColReasons;

  /// No description provided for @seoForceNoindex.
  ///
  /// In en, this message translates to:
  /// **'Force noindex'**
  String get seoForceNoindex;

  /// No description provided for @seoNoPages.
  ///
  /// In en, this message translates to:
  /// **'No price pages yet. Pages appear here after the first export once real quotes exist.'**
  String get seoNoPages;

  /// No description provided for @seoGuidesAiQuota.
  ///
  /// In en, this message translates to:
  /// **'New AI-assisted guides this week: {used} of {cap}'**
  String seoGuidesAiQuota(int used, int cap);

  /// No description provided for @seoGuideCap.
  ///
  /// In en, this message translates to:
  /// **'Weekly AI guide cap'**
  String get seoGuideCap;

  /// No description provided for @seoGuideNew.
  ///
  /// In en, this message translates to:
  /// **'New guide'**
  String get seoGuideNew;

  /// No description provided for @seoGuideEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit guide'**
  String get seoGuideEdit;

  /// No description provided for @seoGuideSlug.
  ///
  /// In en, this message translates to:
  /// **'Slug (URL)'**
  String get seoGuideSlug;

  /// No description provided for @seoGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get seoGuideTitle;

  /// No description provided for @seoGuideDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get seoGuideDescription;

  /// No description provided for @seoGuideCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get seoGuideCategory;

  /// No description provided for @seoGuideCity.
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get seoGuideCity;

  /// No description provided for @seoGuideNoCity.
  ///
  /// In en, this message translates to:
  /// **'No city'**
  String get seoGuideNoCity;

  /// No description provided for @seoGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Body (Markdown)'**
  String get seoGuideBody;

  /// No description provided for @seoGuideAi.
  ///
  /// In en, this message translates to:
  /// **'AI-assisted draft'**
  String get seoGuideAi;

  /// No description provided for @seoGuideAiHelp.
  ///
  /// In en, this message translates to:
  /// **'AI drafts must be reviewed and approved by a person before they go live. At most {cap} new AI-assisted guides per week.'**
  String seoGuideAiHelp(int cap);

  /// No description provided for @seoGuideEditResets.
  ///
  /// In en, this message translates to:
  /// **'Saving sends an approved or published guide back to draft: it needs a new review.'**
  String get seoGuideEditResets;

  /// No description provided for @seoGuideApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get seoGuideApprove;

  /// No description provided for @seoGuidePublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get seoGuidePublish;

  /// No description provided for @seoGuideUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get seoGuideUnpublish;

  /// No description provided for @seoGuideReject.
  ///
  /// In en, this message translates to:
  /// **'Back to draft'**
  String get seoGuideReject;

  /// No description provided for @seoGuideReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {date}'**
  String seoGuideReviewed(String date);

  /// No description provided for @seoGuideStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get seoGuideStatusDraft;

  /// No description provided for @seoGuideStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get seoGuideStatusApproved;

  /// No description provided for @seoGuideStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get seoGuideStatusPublished;

  /// No description provided for @seoGuideAiBadge.
  ///
  /// In en, this message translates to:
  /// **'AI-assisted'**
  String get seoGuideAiBadge;

  /// No description provided for @seoGuideReviewOverdue.
  ///
  /// In en, this message translates to:
  /// **'Review overdue: re-review at least twice a year'**
  String get seoGuideReviewOverdue;

  /// No description provided for @seoGuidesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No guides yet.'**
  String get seoGuidesEmpty;

  /// No description provided for @seoGuideSite.
  ///
  /// In en, this message translates to:
  /// **'On the site: {visibility}'**
  String seoGuideSite(String visibility);

  /// No description provided for @seoGuideInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid guide: {code}'**
  String seoGuideInvalid(String code);

  /// No description provided for @navTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get navTrends;

  /// No description provided for @trendsCountryUsa.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get trendsCountryUsa;

  /// No description provided for @trendsCountryIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get trendsCountryIndia;

  /// No description provided for @trendsTabBoard.
  ///
  /// In en, this message translates to:
  /// **'Live board'**
  String get trendsTabBoard;

  /// No description provided for @trendsTabTopics.
  ///
  /// In en, this message translates to:
  /// **'Fired topics'**
  String get trendsTabTopics;

  /// No description provided for @trendsTabDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get trendsTabDrafts;

  /// No description provided for @trendsTabReview.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get trendsTabReview;

  /// No description provided for @trendsTabControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get trendsTabControls;

  /// No description provided for @trendsTopicWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get trendsTopicWatching;

  /// No description provided for @trendsTopicFired.
  ///
  /// In en, this message translates to:
  /// **'Fired'**
  String get trendsTopicFired;

  /// No description provided for @trendsTopicReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get trendsTopicReview;

  /// No description provided for @trendsTopicDrafted.
  ///
  /// In en, this message translates to:
  /// **'Drafted'**
  String get trendsTopicDrafted;

  /// No description provided for @trendsTopicPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get trendsTopicPublished;

  /// No description provided for @trendsTopicWaitingSources.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sources'**
  String get trendsTopicWaitingSources;

  /// No description provided for @trendsTopicDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get trendsTopicDropped;

  /// No description provided for @trendsTopicEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get trendsTopicEnded;

  /// No description provided for @trendsDraftQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get trendsDraftQueued;

  /// No description provided for @trendsDraftReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get trendsDraftReview;

  /// No description provided for @trendsDraftRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get trendsDraftRejected;

  /// No description provided for @trendsDraftPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get trendsDraftPublished;

  /// No description provided for @trendsDraftNoindex.
  ///
  /// In en, this message translates to:
  /// **'Noindex'**
  String get trendsDraftNoindex;

  /// No description provided for @trendsQueuedCaps.
  ///
  /// In en, this message translates to:
  /// **'waiting for the caps'**
  String get trendsQueuedCaps;

  /// No description provided for @trendsQueuedDraft.
  ///
  /// In en, this message translates to:
  /// **'waiting for the draft'**
  String get trendsQueuedDraft;

  /// No description provided for @trendsStageTopic.
  ///
  /// In en, this message translates to:
  /// **'topic stage'**
  String get trendsStageTopic;

  /// No description provided for @trendsStageContent.
  ///
  /// In en, this message translates to:
  /// **'final text stage'**
  String get trendsStageContent;

  /// No description provided for @trendsActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get trendsActionReject;

  /// No description provided for @trendsActionNoindex.
  ///
  /// In en, this message translates to:
  /// **'Set noindex'**
  String get trendsActionNoindex;

  /// No description provided for @trendsActionIndex.
  ///
  /// In en, this message translates to:
  /// **'Make indexable again'**
  String get trendsActionIndex;

  /// No description provided for @trendsActionUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get trendsActionUnpublish;

  /// No description provided for @trendsActionTitle.
  ///
  /// In en, this message translates to:
  /// **'{action}: {headline}'**
  String trendsActionTitle(String action, String headline);

  /// No description provided for @trendsActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get trendsActions;

  /// No description provided for @trendsOpenDraft.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get trendsOpenDraft;

  /// No description provided for @trendsGateSources.
  ///
  /// In en, this message translates to:
  /// **'2+ sources'**
  String get trendsGateSources;

  /// No description provided for @trendsGateSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get trendsGateSensitive;

  /// No description provided for @trendsGateOriginality.
  ///
  /// In en, this message translates to:
  /// **'Originality'**
  String get trendsGateOriginality;

  /// No description provided for @trendsGateFacts.
  ///
  /// In en, this message translates to:
  /// **'Facts'**
  String get trendsGateFacts;

  /// No description provided for @trendsGateValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get trendsGateValue;

  /// No description provided for @trendsGateBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get trendsGateBalance;

  /// No description provided for @trendsGateCaps.
  ///
  /// In en, this message translates to:
  /// **'Caps'**
  String get trendsGateCaps;

  /// No description provided for @trendsGates.
  ///
  /// In en, this message translates to:
  /// **'Quality gates'**
  String get trendsGates;

  /// No description provided for @trendsNoGates.
  ///
  /// In en, this message translates to:
  /// **'No gate has run yet.'**
  String get trendsNoGates;

  /// No description provided for @trendsRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Run now is limited to {limit} runs per hour for each function. Try again in {minutes} min.'**
  String trendsRateLimited(int limit, int minutes);

  /// No description provided for @trendsErrNotInReview.
  ///
  /// In en, this message translates to:
  /// **'Someone else already decided this one. The queue has been refreshed.'**
  String get trendsErrNotInReview;

  /// No description provided for @trendsErrAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'This needs the admin role.'**
  String get trendsErrAdminOnly;

  /// No description provided for @trendsAddCorrection.
  ///
  /// In en, this message translates to:
  /// **'Add correction'**
  String get trendsAddCorrection;

  /// No description provided for @trendsCorrectionHint.
  ///
  /// In en, this message translates to:
  /// **'What was wrong and what is correct (at least 10 characters)'**
  String get trendsCorrectionHint;

  /// No description provided for @trendsCorrectionTooShort.
  ///
  /// In en, this message translates to:
  /// **'A correction needs at least 10 characters.'**
  String get trendsCorrectionTooShort;

  /// No description provided for @trendsCorrectionAdded.
  ///
  /// In en, this message translates to:
  /// **'Correction added. The article is re-published within 5 minutes.'**
  String get trendsCorrectionAdded;

  /// No description provided for @trendsRecordTraffic.
  ///
  /// In en, this message translates to:
  /// **'Record traffic'**
  String get trendsRecordTraffic;

  /// No description provided for @trendsRecordTrafficTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits to /{slug} in the 14 days after the trend ended'**
  String trendsRecordTrafficTitle(String slug);

  /// No description provided for @trendsVisitsHint.
  ///
  /// In en, this message translates to:
  /// **'Visits in the 14 days after the trend ended'**
  String get trendsVisitsHint;

  /// No description provided for @trendsInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get trendsInvalidNumber;

  /// No description provided for @trendsSupersede.
  ///
  /// In en, this message translates to:
  /// **'Mark superseded'**
  String get trendsSupersede;

  /// No description provided for @trendsSupersedeTitle.
  ///
  /// In en, this message translates to:
  /// **'Supersede /{slug}'**
  String trendsSupersedeTitle(String slug);

  /// No description provided for @trendsSupersedeHint.
  ///
  /// In en, this message translates to:
  /// **'Slug of the newer article (it gets the canonical)'**
  String get trendsSupersedeHint;

  /// No description provided for @trendsPausedBanner.
  ///
  /// In en, this message translates to:
  /// **'Publishing and drafting are paused (by {who}: {reason}, since {at}). Polling continues.'**
  String trendsPausedBanner(String who, String reason, String at);

  /// No description provided for @trendsPausedByAuto.
  ///
  /// In en, this message translates to:
  /// **'automatic pause'**
  String get trendsPausedByAuto;

  /// No description provided for @trendsLastHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String trendsLastHours(int hours);

  /// No description provided for @trendsPlaceFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter places'**
  String get trendsPlaceFilter;

  /// No description provided for @trendsGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {at}. Refreshes every minute.'**
  String trendsGeneratedAt(String at);

  /// No description provided for @trendsNoTopics.
  ///
  /// In en, this message translates to:
  /// **'No topics in this period.'**
  String get trendsNoTopics;

  /// No description provided for @trendsFailingSources.
  ///
  /// In en, this message translates to:
  /// **'{count} feed(s) failing: blind spots on the board'**
  String trendsFailingSources(int count);

  /// No description provided for @trendsSignalsDomains.
  ///
  /// In en, this message translates to:
  /// **'{signals} signals, {domains} publishers'**
  String trendsSignalsDomains(int signals, int domains);

  /// No description provided for @trendsFiredAt.
  ///
  /// In en, this message translates to:
  /// **'fired {at}'**
  String trendsFiredAt(String at);

  /// No description provided for @trendsSources.
  ///
  /// In en, this message translates to:
  /// **'Polled sources'**
  String get trendsSources;

  /// No description provided for @trendsAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get trendsAddSource;

  /// No description provided for @trendsColKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get trendsColKind;

  /// No description provided for @trendsColCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get trendsColCountry;

  /// No description provided for @trendsColGeo.
  ///
  /// In en, this message translates to:
  /// **'Geo'**
  String get trendsColGeo;

  /// No description provided for @trendsColPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get trendsColPlace;

  /// No description provided for @trendsColQuery.
  ///
  /// In en, this message translates to:
  /// **'Query / subreddit'**
  String get trendsColQuery;

  /// No description provided for @trendsColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get trendsColStatus;

  /// No description provided for @trendsColItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get trendsColItems;

  /// No description provided for @trendsColPolled.
  ///
  /// In en, this message translates to:
  /// **'Last polled'**
  String get trendsColPolled;

  /// No description provided for @trendsColEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get trendsColEnabled;

  /// No description provided for @trendsColTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get trendsColTopic;

  /// No description provided for @trendsColVelocity.
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get trendsColVelocity;

  /// No description provided for @trendsColSignals.
  ///
  /// In en, this message translates to:
  /// **'Signals'**
  String get trendsColSignals;

  /// No description provided for @trendsColDomains.
  ///
  /// In en, this message translates to:
  /// **'Publishers'**
  String get trendsColDomains;

  /// No description provided for @trendsColFired.
  ///
  /// In en, this message translates to:
  /// **'Fired'**
  String get trendsColFired;

  /// No description provided for @trendsColReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get trendsColReason;

  /// No description provided for @trendsDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get trendsDisabled;

  /// No description provided for @trendsLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get trendsLevel;

  /// No description provided for @trendsPlaceSlug.
  ///
  /// In en, this message translates to:
  /// **'Place slug'**
  String get trendsPlaceSlug;

  /// No description provided for @trendsPlaceName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get trendsPlaceName;

  /// No description provided for @trendsState.
  ///
  /// In en, this message translates to:
  /// **'State (optional)'**
  String get trendsState;

  /// No description provided for @trendsQueryHelp.
  ///
  /// In en, this message translates to:
  /// **'Google News search or subreddit name (not used for Google Trends)'**
  String get trendsQueryHelp;

  /// No description provided for @trendsFiredHelp.
  ///
  /// In en, this message translates to:
  /// **'Fired topics are waiting for the drafting run (gates 1 and 2 run before any model call).'**
  String get trendsFiredHelp;

  /// No description provided for @trendsNoDrafts.
  ///
  /// In en, this message translates to:
  /// **'No drafts with this status.'**
  String get trendsNoDrafts;

  /// No description provided for @trendsVelocity.
  ///
  /// In en, this message translates to:
  /// **'velocity {value}'**
  String trendsVelocity(int value);

  /// No description provided for @trendsPublishedAt.
  ///
  /// In en, this message translates to:
  /// **'published {at}'**
  String trendsPublishedAt(String at);

  /// No description provided for @trendsCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'created {at}'**
  String trendsCreatedAt(String at);

  /// No description provided for @trendsVisits.
  ///
  /// In en, this message translates to:
  /// **'{visits} visits after the trend'**
  String trendsVisits(int visits);

  /// No description provided for @trendsSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get trendsSensitive;

  /// No description provided for @trendsDirty.
  ///
  /// In en, this message translates to:
  /// **'Re-upload pending'**
  String get trendsDirty;

  /// No description provided for @trendsFailedGate.
  ///
  /// In en, this message translates to:
  /// **'failed gate {gate}'**
  String trendsFailedGate(String gate);

  /// No description provided for @trendsNoindexReason.
  ///
  /// In en, this message translates to:
  /// **'noindex: {reason}'**
  String trendsNoindexReason(String reason);

  /// No description provided for @trendsTopicReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Topic approved by {who} on {at}'**
  String trendsTopicReviewedBy(String who, String at);

  /// No description provided for @trendsReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Final text reviewed by {who} on {at}'**
  String trendsReviewedBy(String who, String at);

  /// No description provided for @trendsReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Sensitive topics never publish without a person. Topic stage: nothing has been drafted yet; approving lets the pipeline draft it. Final text stage: the finished article passed gates 3 to 5; approving queues it for publishing (caps still apply). Your name and the date are stored.'**
  String get trendsReviewHelp;

  /// No description provided for @trendsReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for review.'**
  String get trendsReviewEmpty;

  /// No description provided for @trendsApproveTopicTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this topic for drafting?'**
  String get trendsApproveTopicTitle;

  /// No description provided for @trendsApproveContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve the final text for publishing?'**
  String get trendsApproveContentTitle;

  /// No description provided for @trendsRejectTopicTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this topic'**
  String get trendsRejectTopicTitle;

  /// No description provided for @trendsRejectContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this article'**
  String get trendsRejectContentTitle;

  /// No description provided for @trendsReviewNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (required to reject)'**
  String get trendsReviewNoteHint;

  /// No description provided for @trendsApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved. Reviewer and date recorded.'**
  String get trendsApproved;

  /// No description provided for @trendsRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected.'**
  String get trendsRejected;

  /// No description provided for @trendsWaitingSince.
  ///
  /// In en, this message translates to:
  /// **'waiting since {at}'**
  String trendsWaitingSince(String at);

  /// No description provided for @trendsSensitiveReasons.
  ///
  /// In en, this message translates to:
  /// **'Why it is sensitive: {reasons}'**
  String trendsSensitiveReasons(String reasons);

  /// No description provided for @trendsTopicStageHelp.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been drafted yet: sensitive topics never reach the model before a person approves them. Check the topic and its headlines.'**
  String get trendsTopicStageHelp;

  /// No description provided for @trendsContentStageHelp.
  ///
  /// In en, this message translates to:
  /// **'The finished article passed originality, fact and value checks. Read it in full before approving.'**
  String get trendsContentStageHelp;

  /// No description provided for @trendsShowHeadlines.
  ///
  /// In en, this message translates to:
  /// **'Topic and headlines'**
  String get trendsShowHeadlines;

  /// No description provided for @trendsReadArticle.
  ///
  /// In en, this message translates to:
  /// **'Read the article'**
  String get trendsReadArticle;

  /// No description provided for @trendsApproveTopic.
  ///
  /// In en, this message translates to:
  /// **'Approve topic'**
  String get trendsApproveTopic;

  /// No description provided for @trendsApproveContent.
  ///
  /// In en, this message translates to:
  /// **'Approve final text'**
  String get trendsApproveContent;

  /// No description provided for @trendsOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get trendsOptional;

  /// No description provided for @trendsKillSwitch.
  ///
  /// In en, this message translates to:
  /// **'Kill switch'**
  String get trendsKillSwitch;

  /// No description provided for @trendsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get trendsResume;

  /// No description provided for @trendsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause now'**
  String get trendsPause;

  /// No description provided for @trendsPausedNow.
  ///
  /// In en, this message translates to:
  /// **'Paused: no drafting, no publishing'**
  String get trendsPausedNow;

  /// No description provided for @trendsRunningNow.
  ///
  /// In en, this message translates to:
  /// **'Running: drafting and publishing are allowed'**
  String get trendsRunningNow;

  /// No description provided for @trendsPausedDetail.
  ///
  /// In en, this message translates to:
  /// **'Paused by {who}: {reason} (since {at})'**
  String trendsPausedDetail(String who, String reason, String at);

  /// No description provided for @trendsResumedDetail.
  ///
  /// In en, this message translates to:
  /// **'Last resumed by {who}: {reason}'**
  String trendsResumedDetail(String who, String reason);

  /// No description provided for @trendsKillSwitchHelp.
  ///
  /// In en, this message translates to:
  /// **'Pausing stops model spend and publishing at once; polling continues so the board stays live. The site build also refuses articles published after the pause.'**
  String get trendsKillSwitchHelp;

  /// No description provided for @trendsPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause drafting and publishing?'**
  String get trendsPauseTitle;

  /// No description provided for @trendsPauseBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is drafted or published until someone resumes. Say why (shown to other admins).'**
  String get trendsPauseBody;

  /// No description provided for @trendsResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume drafting and publishing?'**
  String get trendsResumeTitle;

  /// No description provided for @trendsResumeBody.
  ///
  /// In en, this message translates to:
  /// **'Drafting (Claude spend) and publishing start again on the next run, within the caps. Make sure the reason for the pause is resolved.'**
  String get trendsResumeBody;

  /// No description provided for @trendsPausedToast.
  ///
  /// In en, this message translates to:
  /// **'Paused.'**
  String get trendsPausedToast;

  /// No description provided for @trendsResumedToast.
  ///
  /// In en, this message translates to:
  /// **'Resumed.'**
  String get trendsResumedToast;

  /// No description provided for @trendsPipeline.
  ///
  /// In en, this message translates to:
  /// **'Pipeline (cron jobs)'**
  String get trendsPipeline;

  /// No description provided for @trendsPipelineEnabled.
  ///
  /// In en, this message translates to:
  /// **'On: poll, draft and publish run every 5 minutes'**
  String get trendsPipelineEnabled;

  /// No description provided for @trendsPipelineDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off: no scheduled runs'**
  String get trendsPipelineDisabled;

  /// No description provided for @trendsPipelineHelp.
  ///
  /// In en, this message translates to:
  /// **'Run the pipeline in ONE project only: it covers both countries.'**
  String get trendsPipelineHelp;

  /// No description provided for @trendsPipelineOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn the pipeline on?'**
  String get trendsPipelineOnTitle;

  /// No description provided for @trendsPipelineOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn the pipeline off?'**
  String get trendsPipelineOffTitle;

  /// No description provided for @trendsPipelineOnBody.
  ///
  /// In en, this message translates to:
  /// **'Starts the poll, draft and publish cron jobs in this project. Only do this in the one project that runs the trends site.'**
  String get trendsPipelineOnBody;

  /// No description provided for @trendsPipelineOffBody.
  ///
  /// In en, this message translates to:
  /// **'Stops all scheduled polling, drafting and publishing. The board stops updating.'**
  String get trendsPipelineOffBody;

  /// No description provided for @trendsPipelineOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get trendsPipelineOn;

  /// No description provided for @trendsPipelineOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get trendsPipelineOff;

  /// No description provided for @trendsRunNowSection.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get trendsRunNowSection;

  /// No description provided for @trendsRunNowHelp.
  ///
  /// In en, this message translates to:
  /// **'Runs one step immediately with your admin session. Limited to 6 runs per hour per function so repeated clicks cannot run up model spend.'**
  String get trendsRunNowHelp;

  /// No description provided for @trendsRunPollHelp.
  ///
  /// In en, this message translates to:
  /// **'Polls Google Trends, Google News and Reddit feeds and updates the board.'**
  String get trendsRunPollHelp;

  /// No description provided for @trendsRunDraftHelp.
  ///
  /// In en, this message translates to:
  /// **'Drafts fired topics with Claude and runs the quality gates (uses model spend).'**
  String get trendsRunDraftHelp;

  /// No description provided for @trendsRunPublishHelp.
  ///
  /// In en, this message translates to:
  /// **'Applies the caps and ramp, uploads articles and the index, and triggers the site rebuild.'**
  String get trendsRunPublishHelp;

  /// No description provided for @trendsRunNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Run {fn} now?'**
  String trendsRunNowTitle(String fn);

  /// No description provided for @trendsRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get trendsRunNow;

  /// No description provided for @trendsRunDryRun.
  ///
  /// In en, this message translates to:
  /// **'{fn}: dry run ({reason}). {stats}'**
  String trendsRunDryRun(String fn, String reason, String stats);

  /// No description provided for @trendsRunDone.
  ///
  /// In en, this message translates to:
  /// **'{fn} done: {stats}'**
  String trendsRunDone(String fn, String stats);

  /// No description provided for @trendsNoRunYet.
  ///
  /// In en, this message translates to:
  /// **'No run yet.'**
  String get trendsNoRunYet;

  /// No description provided for @trendsLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last run {at} ({trigger}): {result}. {stats}'**
  String trendsLastRun(String at, String trigger, String result, String stats);

  /// No description provided for @trendsRunning.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get trendsRunning;

  /// No description provided for @trendsDryRun.
  ///
  /// In en, this message translates to:
  /// **'dry run'**
  String get trendsDryRun;

  /// No description provided for @trendsRunNowLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} of {limit} admin runs left this hour'**
  String trendsRunNowLeft(int left, int limit);

  /// No description provided for @trendsRunNowExhausted.
  ///
  /// In en, this message translates to:
  /// **'{limit} admin runs used this hour; next in {minutes} min'**
  String trendsRunNowExhausted(int limit, int minutes);

  /// No description provided for @trendsRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp and daily caps'**
  String get trendsRamp;

  /// No description provided for @trendsRampHelp.
  ///
  /// In en, this message translates to:
  /// **'Per country per day: {levels}. Step up one level at a time, at least {days} days apart, only with a healthy snapshot from the last week. The pipeline steps down by itself when health drops.'**
  String trendsRampHelp(String levels, int days);

  /// No description provided for @trendsPerDay.
  ///
  /// In en, this message translates to:
  /// **'{perDay} per day'**
  String trendsPerDay(int perDay);

  /// No description provided for @trendsRampLevel.
  ///
  /// In en, this message translates to:
  /// **'level {level} of {total}'**
  String trendsRampLevel(int level, int total);

  /// No description provided for @trendsPublished24h.
  ///
  /// In en, this message translates to:
  /// **'{count} published in 24 h'**
  String trendsPublished24h(int count);

  /// No description provided for @trendsRampChanged.
  ///
  /// In en, this message translates to:
  /// **'last change {at}'**
  String trendsRampChanged(String at);

  /// No description provided for @trendsRampTop.
  ///
  /// In en, this message translates to:
  /// **'already at the top level'**
  String get trendsRampTop;

  /// No description provided for @trendsRampTooSoon.
  ///
  /// In en, this message translates to:
  /// **'less than {days} days since the last step'**
  String trendsRampTooSoon(int days);

  /// No description provided for @trendsRampUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'not healthy: {problem}'**
  String trendsRampUnhealthy(String problem);

  /// No description provided for @trendsRampUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Step {country} up one level?'**
  String trendsRampUpTitle(String country);

  /// No description provided for @trendsRampDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Step {country} down one level?'**
  String trendsRampDownTitle(String country);

  /// No description provided for @trendsRampBody.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to} articles per day. Remember: the site config caps are a ceiling, raise them in the repo when ramping up.'**
  String trendsRampBody(int from, int to);

  /// No description provided for @trendsRampUp.
  ///
  /// In en, this message translates to:
  /// **'Step up'**
  String get trendsRampUp;

  /// No description provided for @trendsRampDown.
  ///
  /// In en, this message translates to:
  /// **'Step down'**
  String get trendsRampDown;

  /// No description provided for @trendsSiteCeiling.
  ///
  /// In en, this message translates to:
  /// **'The site build never publishes more than the lower of these caps and web/trends_site/data/config.json.'**
  String get trendsSiteCeiling;

  /// No description provided for @trendsHealthy.
  ///
  /// In en, this message translates to:
  /// **'healthy'**
  String get trendsHealthy;

  /// No description provided for @trendsProblemNoRecent.
  ///
  /// In en, this message translates to:
  /// **'no snapshot in the last week'**
  String get trendsProblemNoRecent;

  /// No description provided for @trendsProblemManualAction.
  ///
  /// In en, this message translates to:
  /// **'Search Console manual action'**
  String get trendsProblemManualAction;

  /// No description provided for @trendsProblemErrorReports.
  ///
  /// In en, this message translates to:
  /// **'error reports spike'**
  String get trendsProblemErrorReports;

  /// No description provided for @trendsProblemScWarnings.
  ///
  /// In en, this message translates to:
  /// **'Search Console warnings'**
  String get trendsProblemScWarnings;

  /// No description provided for @trendsProblemLowIndexed.
  ///
  /// In en, this message translates to:
  /// **'low indexed share'**
  String get trendsProblemLowIndexed;

  /// No description provided for @trendsProblemTrafficDrop.
  ///
  /// In en, this message translates to:
  /// **'traffic drop'**
  String get trendsProblemTrafficDrop;

  /// No description provided for @trendsHealth.
  ///
  /// In en, this message translates to:
  /// **'Health inputs (Search Console and analytics)'**
  String get trendsHealth;

  /// No description provided for @trendsHealthHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the figures weekly until an integration exists. A manual action or an error-report spike pauses publishing immediately.'**
  String get trendsHealthHelp;

  /// No description provided for @trendsHealthLatest.
  ///
  /// In en, this message translates to:
  /// **'{at}: indexed {share}, clicks {clicks} (prev. {prev}), {warnings} warnings, {errors} error reports'**
  String trendsHealthLatest(
    String at,
    String share,
    String clicks,
    String prev,
    int warnings,
    int errors,
  );

  /// No description provided for @trendsManualAction.
  ///
  /// In en, this message translates to:
  /// **'Manual action'**
  String get trendsManualAction;

  /// No description provided for @trendsManualActionHelp.
  ///
  /// In en, this message translates to:
  /// **'Pauses publishing immediately'**
  String get trendsManualActionHelp;

  /// No description provided for @trendsRecordHealth.
  ///
  /// In en, this message translates to:
  /// **'Record health snapshot'**
  String get trendsRecordHealth;

  /// No description provided for @trendsHealthAutoPaused.
  ///
  /// In en, this message translates to:
  /// **'Snapshot recorded. Publishing was paused automatically ({reason}).'**
  String trendsHealthAutoPaused(String reason);

  /// No description provided for @trendsHealthRecorded.
  ///
  /// In en, this message translates to:
  /// **'Snapshot recorded. Health: {problem}.'**
  String trendsHealthRecorded(String problem);

  /// No description provided for @trendsIndexedShare.
  ///
  /// In en, this message translates to:
  /// **'Indexed share (%)'**
  String get trendsIndexedShare;

  /// No description provided for @trendsIndexedShareHelp.
  ///
  /// In en, this message translates to:
  /// **'Indexed pages / submitted pages in Search Console, 0 to 100'**
  String get trendsIndexedShareHelp;

  /// No description provided for @trendsClicks7d.
  ///
  /// In en, this message translates to:
  /// **'Clicks, last 7 days'**
  String get trendsClicks7d;

  /// No description provided for @trendsClicksPrev7d.
  ///
  /// In en, this message translates to:
  /// **'Clicks, previous 7 days'**
  String get trendsClicksPrev7d;

  /// No description provided for @trendsScWarnings.
  ///
  /// In en, this message translates to:
  /// **'Search Console warnings'**
  String get trendsScWarnings;

  /// No description provided for @trendsErrorReports.
  ///
  /// In en, this message translates to:
  /// **'Error reports, last 24 h'**
  String get trendsErrorReports;

  /// No description provided for @trendsHealthIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in every number.'**
  String get trendsHealthIncomplete;

  /// No description provided for @trendsSlug.
  ///
  /// In en, this message translates to:
  /// **'Article slug'**
  String get trendsSlug;

  /// No description provided for @trendsSettings.
  ///
  /// In en, this message translates to:
  /// **'Caps, thresholds and lists'**
  String get trendsSettings;

  /// No description provided for @trendsSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'The server refuses values below the brief\'s floors: at least 2 sources, at least 250 words, similarity at most 0.5, at most 1 rewrite, at most 3 per hour, at most 20 per day, at least 30 days between ramp steps.'**
  String get trendsSettingsHelp;

  /// No description provided for @trendsEditSetting.
  ///
  /// In en, this message translates to:
  /// **'Edit {key}'**
  String trendsEditSetting(String key);

  /// No description provided for @trendsJsonHelp.
  ///
  /// In en, this message translates to:
  /// **'JSON array'**
  String get trendsJsonHelp;

  /// No description provided for @trendsListHelp.
  ///
  /// In en, this message translates to:
  /// **'One entry per line'**
  String get trendsListHelp;

  /// No description provided for @trendsCommaHelp.
  ///
  /// In en, this message translates to:
  /// **'Comma separated'**
  String get trendsCommaHelp;

  /// No description provided for @trendsFloor.
  ///
  /// In en, this message translates to:
  /// **'Not allowed: {problem}'**
  String trendsFloor(String problem);

  /// No description provided for @trendsServerRefused.
  ///
  /// In en, this message translates to:
  /// **'The server refused the change: {error}'**
  String trendsServerRefused(String error);

  /// No description provided for @trendsDecisionLog.
  ///
  /// In en, this message translates to:
  /// **'Decision log'**
  String get trendsDecisionLog;

  /// No description provided for @trendsNoLog.
  ///
  /// In en, this message translates to:
  /// **'No decisions yet.'**
  String get trendsNoLog;

  /// No description provided for @trendsPipelineActor.
  ///
  /// In en, this message translates to:
  /// **'pipeline'**
  String get trendsPipelineActor;

  /// No description provided for @trendsDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get trendsDraft;

  /// No description provided for @trendsSensitiveReasonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sensitive because'**
  String get trendsSensitiveReasonsLabel;

  /// No description provided for @trendsFailedGateLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed gate'**
  String get trendsFailedGateLabel;

  /// No description provided for @trendsTopicReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic review'**
  String get trendsTopicReviewLabel;

  /// No description provided for @trendsContentReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Final text review'**
  String get trendsContentReviewLabel;

  /// No description provided for @trendsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get trendsModel;

  /// No description provided for @trendsRewrites.
  ///
  /// In en, this message translates to:
  /// **'{rewrites} rewrite(s)'**
  String trendsRewrites(int rewrites);

  /// No description provided for @trendsPublishedLabel.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get trendsPublishedLabel;

  /// No description provided for @trendsLastUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get trendsLastUpdateLabel;

  /// No description provided for @trendsNoindexLabel.
  ///
  /// In en, this message translates to:
  /// **'Noindex reason'**
  String get trendsNoindexLabel;

  /// No description provided for @trendsSupersededLabel.
  ///
  /// In en, this message translates to:
  /// **'Superseded by'**
  String get trendsSupersededLabel;

  /// No description provided for @trendsVisitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Visits after the trend'**
  String get trendsVisitsLabel;

  /// No description provided for @trendsStorageLabel.
  ///
  /// In en, this message translates to:
  /// **'Bucket path'**
  String get trendsStorageLabel;

  /// No description provided for @trendsNoArticle.
  ///
  /// In en, this message translates to:
  /// **'No article text yet.'**
  String get trendsNoArticle;

  /// No description provided for @trendsArticle.
  ///
  /// In en, this message translates to:
  /// **'Article (as on the site)'**
  String get trendsArticle;

  /// No description provided for @trendsFraming.
  ///
  /// In en, this message translates to:
  /// **'Framing'**
  String get trendsFraming;

  /// No description provided for @trendsWhereAgree.
  ///
  /// In en, this message translates to:
  /// **'Where they agree'**
  String get trendsWhereAgree;

  /// No description provided for @trendsLocalAngle.
  ///
  /// In en, this message translates to:
  /// **'What it means locally'**
  String get trendsLocalAngle;

  /// No description provided for @trendsContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get trendsContext;

  /// No description provided for @trendsWatchNext.
  ///
  /// In en, this message translates to:
  /// **'What to watch'**
  String get trendsWatchNext;

  /// No description provided for @trendsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get trendsUpdates;

  /// No description provided for @trendsCorrections.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get trendsCorrections;

  /// No description provided for @trendsSourcesSection.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get trendsSourcesSection;

  /// No description provided for @trendsAppLink.
  ///
  /// In en, this message translates to:
  /// **'App link'**
  String get trendsAppLink;

  /// No description provided for @trendsReviewStamp.
  ///
  /// In en, this message translates to:
  /// **'Review stamp'**
  String get trendsReviewStamp;

  /// No description provided for @trendsSignals.
  ///
  /// In en, this message translates to:
  /// **'Headlines behind it ({count})'**
  String trendsSignals(int count);

  /// No description provided for @trendsNoSignals.
  ///
  /// In en, this message translates to:
  /// **'No signals.'**
  String get trendsNoSignals;

  /// No description provided for @trendsNotCitable.
  ///
  /// In en, this message translates to:
  /// **'not citable'**
  String get trendsNotCitable;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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

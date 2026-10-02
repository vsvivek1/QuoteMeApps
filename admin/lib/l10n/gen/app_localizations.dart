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

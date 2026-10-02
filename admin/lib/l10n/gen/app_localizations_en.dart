// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String adminTitle(String app) {
    return '$app Admin';
  }

  @override
  String get loadFailed => 'Could not load';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get all => 'All';

  @override
  String get any => 'Any';

  @override
  String get ok => 'OK';

  @override
  String get required => 'Required';

  @override
  String get warning => 'Warning';

  @override
  String get demoMode => 'DEMO DATA';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get loginSubtitle =>
      'Administrators only. Sign in with your admin email and password.';

  @override
  String get loginNotAdmin =>
      'This account does not have the admin role. Access refused.';

  @override
  String get loginInvalid => 'Wrong email or password.';

  @override
  String loginFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String demoLoginHint(String email, String password) {
    return 'Demo mode: sign in with $email / $password. Nothing is sent anywhere.';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navVerification => 'Verification';

  @override
  String get navModeration => 'Moderation';

  @override
  String get navCategories => 'Categories';

  @override
  String get navFlags => 'Flags';

  @override
  String get navOutreach => 'Outreach CRM';

  @override
  String get navBrochures => 'Brochures';

  @override
  String get dashQueues => 'Queues';

  @override
  String get dashMarketplace => 'Marketplace (Section 13)';

  @override
  String get dashRetention => 'Retention';

  @override
  String get dashOutreach => 'Seller acquisition';

  @override
  String get kpiPendingVerifications => 'Pending verifications';

  @override
  String get kpiPendingLicences => 'Pending licences';

  @override
  String get kpiOpenReports => 'Open reports';

  @override
  String get kpiTimeToFirstQuote => 'Time to first quote (median)';

  @override
  String get kpiTimeToFirstQuoteHint => 'Target: under 2 h in metros';

  @override
  String get kpiRequests3Quotes => 'Requests with 3+ quotes';

  @override
  String get kpiRequestToAcceptance => 'Request to acceptance';

  @override
  String get kpiSellerResponseRate => 'Seller response rate';

  @override
  String get kpiFreeToPaid => 'Seller free-to-paid';

  @override
  String get kpiRevenuePerSeller => 'Revenue per seller';

  @override
  String get kpiRefunds => 'Refunds (30 days)';

  @override
  String get kpiOpenRequests => 'Open requests';

  @override
  String get kpiRequests7d => 'Requests (7 days)';

  @override
  String get kpiQuotes7d => 'Quotes (7 days)';

  @override
  String get kpiOrders7d => 'Orders (7 days)';

  @override
  String get kpiUsers => 'Users';

  @override
  String get kpiSellers => 'Sellers';

  @override
  String get verified => 'verified';

  @override
  String get kpiReplyRate => 'Reply rate';

  @override
  String get kpiSignupRate => 'Signup rate';

  @override
  String get kpiSentToday => 'Sent today / daily cap';

  @override
  String get kpiQueue => 'Queue (sourced, enrolled)';

  @override
  String kpiQueueDays(int days) {
    return 'about $days days at current cap';
  }

  @override
  String get verificationEmpty => 'No documents waiting for review.';

  @override
  String get docNotAvailableDemo => 'Documents are not available in demo mode.';

  @override
  String get rejectTitle => 'Reject: reason';

  @override
  String get rejectHint => 'Tell the seller what to fix (they will see this).';

  @override
  String get approveTitle => 'Approve';

  @override
  String approveBody(String business) {
    return 'Approve this document for $business? The seller gets the verified badge.';
  }

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get licence => 'Licence';

  @override
  String get document => 'Document';

  @override
  String get issuer => 'Issuer';

  @override
  String get expires => 'Expires';

  @override
  String get categories => 'Categories';

  @override
  String get submitted => 'submitted';

  @override
  String get sellerStatus => 'Seller status';

  @override
  String get noFile => 'No file';

  @override
  String get viewDocument => 'View document';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get tabReports => 'Reports';

  @override
  String get tabUsers => 'Users';

  @override
  String get tabAuditLog => 'Audit log';

  @override
  String get reportsEmpty => 'No open reports.';

  @override
  String get resolveTitle => 'Resolve report';

  @override
  String get resolveNoteHint => 'Optional note for the audit log';

  @override
  String reportsResolved(int count) {
    return '$count report(s) resolved';
  }

  @override
  String get banTitle => 'Ban user: reason';

  @override
  String get banHint => 'Reason (kept in the audit log)';

  @override
  String get userBanned => 'User banned';

  @override
  String reportCount(int count) {
    return '$count report(s)';
  }

  @override
  String get reporterSays => 'Reporter says';

  @override
  String get hideContent => 'Hide content';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get restore => 'Restore';

  @override
  String get banUser => 'Ban user';

  @override
  String get suspendTitle => 'Suspend for 7 days: reason';

  @override
  String userStatusSet(String status) {
    return 'User status set to $status';
  }

  @override
  String get searchUsersHint => 'Search name, email or phone, then press Enter';

  @override
  String get noResults => 'No results';

  @override
  String get reason => 'Reason';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get suspend7d => 'Suspend 7 days';

  @override
  String get auditEmpty => 'No admin actions logged yet.';

  @override
  String categoriesIntro(String app) {
    return 'Category policy for $app. Restricted categories need a licence type; anything uncertain stays blocked until legal sign-off.';
  }

  @override
  String get policyAllowed => 'Allowed';

  @override
  String get policyRestricted => 'Restricted';

  @override
  String get policyBlocked => 'Blocked';

  @override
  String get licenceType => 'Required licence type';

  @override
  String get licenceTypeHelp =>
      'e.g. state_contractor_licence, rera, nmc_registration';

  @override
  String get inactive => 'inactive';

  @override
  String get policyReasonEn => 'Reason shown to users (English)';

  @override
  String get disclaimerEn => 'Regulatory disclaimer (English)';

  @override
  String get names => 'Names';

  @override
  String get activeLabel => 'Active';

  @override
  String get unblockWarning =>
      'Make sure a lawyer has confirmed this category may be quoted in this country.';

  @override
  String get outreachFlag => 'Seller outreach engine (Section 21)';

  @override
  String get outreachFlagHelp =>
      'Off stops every outreach send. Sending is always manual.';

  @override
  String get remoteFlags => 'Remote flags and limits';

  @override
  String get remoteFlagsHelp =>
      'Stored in app_settings for this country project. Public flags are read by the apps and mirrored to Remote Config by the backend.';

  @override
  String get publicFlag => 'public';

  @override
  String get invalidNumber => 'Enter a number';

  @override
  String get monetizationTitle => 'Monetization switch';

  @override
  String get monetizationOn => 'On: paid plans and paywalls are live.';

  @override
  String get monetizationOff =>
      'Off: everything is free for sellers and no paywall is shown.';

  @override
  String get monetizationOnTitle => 'Turn monetization on?';

  @override
  String monetizationOnBody(String date) {
    return 'Paywalls go live for new sellers. Early partners stay free until $date (6 months from today if not set).';
  }

  @override
  String get monetizationOffTitle => 'Turn monetization off?';

  @override
  String get monetizationOffBody =>
      'All seller features become free again and paywalls are hidden.';

  @override
  String get earlyPartnerUntil => 'Early partners free until';

  @override
  String get notSetYet => 'not set yet';

  @override
  String get changeDate => 'Change date';

  @override
  String get earlyPartnerHelp =>
      'Outreach and brochures always state this end date. Never promise free for life.';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get tabBoard => 'Board';

  @override
  String get tabSuppression => 'Suppression';

  @override
  String get tabCampaigns => 'Campaigns';

  @override
  String get tabCoverage => 'Coverage';

  @override
  String enrolTitle(int count) {
    return 'Enrol $count lead(s) in a campaign';
  }

  @override
  String get enrolled => 'Enrolled. Each send still needs a person.';

  @override
  String moveSelected(int count) {
    return 'Move $count lead(s) to';
  }

  @override
  String movedCount(int count) {
    return '$count lead(s) moved';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get enrolInCampaign => 'Enrol in campaign';

  @override
  String get moveStage => 'Move stage';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportAllCsv => 'Export all (CSV)';

  @override
  String get clearSelection => 'Clear';

  @override
  String leadCount(int count) {
    return '$count leads';
  }

  @override
  String get searchLeads => 'Search leads';

  @override
  String get state => 'State';

  @override
  String get city => 'City';

  @override
  String get category => 'Category';

  @override
  String get source => 'Source';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get noMatchedCategory => 'No matched category (not contactable)';

  @override
  String touches(int count) {
    return '$count/3 touches';
  }

  @override
  String get due => 'due';

  @override
  String get addSuppression => 'Add to suppression list';

  @override
  String get domain => 'Domain';

  @override
  String get phone => 'Phone';

  @override
  String get value => 'Value';

  @override
  String get note => 'Note';

  @override
  String get suppressionPermanent =>
      'Suppression is shared across all inboxes and channels and is permanent.';

  @override
  String get suppressionIntro =>
      'Every send checks this list. Unsubscribes, hard bounces, complaints and negative replies land here automatically.';

  @override
  String get suppressionEmpty => 'Nothing suppressed yet.';

  @override
  String sendCapacity(int sent, int cap) {
    return 'Sent today: $sent of $cap (global daily ceiling)';
  }

  @override
  String sendCapacityHelp(
    int domain,
    String bounce,
    String complaint,
    String negative,
  ) {
    return 'Per recipient domain: $domain/day. Brakes pause a campaign above $bounce% bounces, $complaint% complaints or $negative% negative replies.';
  }

  @override
  String get status => 'Status';

  @override
  String get dailyCap => 'Daily cap';

  @override
  String get pausedReason => 'Paused because';

  @override
  String campaignHealth(
    int sent,
    String bounce,
    String complaint,
    String negative,
  ) {
    return '30 days: $sent sent, bounces $bounce, complaints $complaint, negative $negative';
  }

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get resumeTitle => 'Resume campaign?';

  @override
  String get resumeBody => 'Sending stays manual and every cap still applies.';

  @override
  String get resumeBrakeBody =>
      'This campaign was paused by an automatic brake. Fix the cause (list quality, content) before resuming.';

  @override
  String get coverageIntro =>
      'Sellers per city and category. Areas with fewer than 5 sellers need outreach first.';

  @override
  String get sellers => 'Sellers';

  @override
  String get liquidity => 'Liquidity';

  @override
  String get needsSellers => 'Needs sellers';

  @override
  String get stageSourced => 'Sourced';

  @override
  String get stageContacted => 'Contacted';

  @override
  String get stageReplied => 'Replied';

  @override
  String get stageOnboarding => 'Onboarding';

  @override
  String get stageLiveSeller => 'Live seller';

  @override
  String get stageActive => 'Active (first quote)';

  @override
  String get stageNotInterested => 'Not interested';

  @override
  String get stageDoNotContact => 'Do not contact';

  @override
  String get trNoChange => 'The lead is already in that stage.';

  @override
  String get trNotAllowed =>
      'That move is not allowed: the pipeline only moves forward, so a finished conversation is never restarted.';

  @override
  String get trTerminal => 'Do not contact is permanent.';

  @override
  String get trNeedsSellerLink =>
      'Link the lead to a seller account first (it happens when they sign up).';

  @override
  String get trNeedsLoggedContact =>
      'Log the call, visit or 1:1 message first.';

  @override
  String get rule0 => 'A person confirms every send';

  @override
  String get rule1 => 'Relevance only';

  @override
  String get rule2 => 'One conversation per business, max 3 touches';

  @override
  String get rule3 => 'Verified, business-published address';

  @override
  String get rule4 => 'Short, plain, personal, honest';

  @override
  String get rule5 => 'Easy, respected opt-out';

  @override
  String get rule6 => 'Volume caps and business hours';

  @override
  String get rule7 => 'Automatic brakes';

  @override
  String get rule8 => 'Honest identity';

  @override
  String get rule9 => 'WhatsApp/SMS only after opt-in';

  @override
  String get rule10 => 'Businesses only, never consumers';

  @override
  String get rule11 => 'Audit trail';

  @override
  String get logContactFirst =>
      'Moving to Contacted by hand needs a logged contact.';

  @override
  String get logContactTitle => 'Log contact';

  @override
  String dncTitle(String business) {
    return 'Do not contact $business?';
  }

  @override
  String get dncBody =>
      'The business is added to the shared suppression list and will never be contacted again on any channel.';

  @override
  String moveTo(String stage) {
    return 'Move to $stage';
  }

  @override
  String movedTo(String stage) {
    return 'Moved to $stage';
  }

  @override
  String get optionalNote => 'Optional note';

  @override
  String get contactCall => 'Call';

  @override
  String get contactVisit => 'Visit';

  @override
  String get contactWhatsApp => 'WhatsApp 1:1';

  @override
  String get contactNote => 'Note';

  @override
  String get whatHappened => 'What happened?';

  @override
  String get lead => 'Lead';

  @override
  String whatsAppPitch(
    String business,
    String app,
    String category,
    String city,
    String link,
  ) {
    return 'Hello $business, I am from $app. Buyers in $city post $category requests and local businesses send quotes. Founding partners join free. Can I set up your shop? $link (Reply STOP and I won\'t message again.)';
  }

  @override
  String get whatsAppManualTitle => 'Message on WhatsApp';

  @override
  String get whatsAppManualBody =>
      'This opens WhatsApp with a pre-filled message for you to send personally, at a human pace. It is logged in the CRM.';

  @override
  String get whatsAppManual => 'Message on WhatsApp';

  @override
  String get recordOptIn => 'Record WhatsApp opt-in';

  @override
  String get optInProofHint =>
      'How did they opt in? (replied, QR scan, signup form, in person)';

  @override
  String prepareSend(int step) {
    return 'Prepare step $step';
  }

  @override
  String get contact => 'Contact';

  @override
  String get website => 'Website';

  @override
  String get address => 'Address';

  @override
  String get rating => 'Rating';

  @override
  String get sourceCategories => 'Source tags';

  @override
  String get compliance => 'Compliance';

  @override
  String get lawfulBasis => 'Lawful basis';

  @override
  String get addressSource => 'Address published at';

  @override
  String get reasonChosen => 'Why chosen';

  @override
  String get optIn => 'Opt-in';

  @override
  String get sequence => 'Sequence';

  @override
  String get campaign => 'Campaign';

  @override
  String get sellerAccount => 'Seller account';

  @override
  String get notesAndNextAction => 'Notes and next action';

  @override
  String get notes => 'Notes';

  @override
  String get nextAction => 'Next action';

  @override
  String get dueDate => 'Due date';

  @override
  String get history => 'Message history';

  @override
  String get noHistory => 'No messages yet.';

  @override
  String stepN(int step) {
    return 'step $step';
  }

  @override
  String sendTitle(String business, int step) {
    return 'Send to $business (step $step)';
  }

  @override
  String get neverAutomatic =>
      'Nothing is sent automatically. Review the message; the checks below run here, again in the Edge Function and again in the database.';

  @override
  String get inbox => 'Inbox';

  @override
  String get approvedTemplate => 'Approved WhatsApp template name';

  @override
  String get subject => 'Subject';

  @override
  String get body => 'Message';

  @override
  String wordCount(int words, int max) {
    return '$words / $max words';
  }

  @override
  String get footerPreview => 'Footer added to every email';

  @override
  String get confirmPersonalSend =>
      'I reviewed this message and I am sending it to this business now.';

  @override
  String get sendNow => 'Send';

  @override
  String get sent => 'Sent';

  @override
  String get antiSpamChecks => 'Anti-spam checks (Section 21.8)';

  @override
  String serverRefused(String reason) {
    return 'Refused by the server: $reason';
  }

  @override
  String get fileTooLarge => 'File too large (max 5 MB)';

  @override
  String get importRulesTitle => 'Compliant sources only';

  @override
  String get importRules =>
      'Allowed sources: osm, places (Google Places API), registry (public licence lists), website (the business\'s own contact page), inbound, referral, manual, field. Never scraped Google Maps, Yelp, YellowPages, Justdial or IndiaMART pages, bought lists, or consumer data. Rows that break these rules are rejected. Emails need the page where the business published them (address_source).';

  @override
  String importColumns(String columns) {
    return 'Columns: $columns';
  }

  @override
  String get chooseCsv => 'Choose CSV';

  @override
  String get downloadTemplate => 'Download template';

  @override
  String importReady(int count) {
    return '$count ready';
  }

  @override
  String importRejected(int count) {
    return '$count rejected';
  }

  @override
  String importDuplicates(int count) {
    return '$count duplicates in file';
  }

  @override
  String importNoCategory(int count) {
    return '$count without a matched category';
  }

  @override
  String get rejectedRows => 'Rejected rows';

  @override
  String rowReason(int line, String reason) {
    return 'Row $line: $reason';
  }

  @override
  String get businessName => 'Business';

  @override
  String get importAttestation =>
      'I confirm these are businesses from the compliant sources above, with no consumer data.';

  @override
  String importNow(int count) {
    return 'Import $count leads';
  }

  @override
  String importDone(int inserted, int duplicates) {
    return 'Imported $inserted; $duplicates already known (deduplicated).';
  }

  @override
  String get anyCityHelp => 'Any city or town: outreach is nationwide.';

  @override
  String get formatA4 => 'A4 PDF';

  @override
  String get formatA5 => 'A5 one-pager';

  @override
  String get formatImage => '1080x1350 image';

  @override
  String get foundingUntil => 'Founding partner offer ends';

  @override
  String get foundingUntilRequired =>
      'Pick a date: the offer always states its end date.';

  @override
  String get fromSettings => 'from settings';

  @override
  String get download => 'Download';

  @override
  String get print => 'Print';

  @override
  String get saveToStorage => 'Save to Storage';

  @override
  String brochureSaved(String path) {
    return 'Saved: $path';
  }

  @override
  String get savedBrochures => 'Saved brochures';

  @override
  String get noBrochures => 'None yet.';

  @override
  String get brochureIncomplete =>
      'Choose a city, category and offer end date.';
}

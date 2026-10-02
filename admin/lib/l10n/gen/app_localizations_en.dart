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

  @override
  String get navSellers => 'Sellers';

  @override
  String get sellersSearchHint => 'Business name or phone number';

  @override
  String get sellersSearchPrompt =>
      'Search sellers by business name (at least 2 letters) or phone number (at least 4 digits).';

  @override
  String get sellersNone => 'No sellers match.';

  @override
  String get openSeller => 'Open seller';

  @override
  String get seller => 'Seller';

  @override
  String get ownerName => 'Owner';

  @override
  String get businessPhone => 'Business phone';

  @override
  String get verificationStatus => 'Verification';

  @override
  String foundingPartnerFreeUntil(String date) {
    return 'Founding partner, free until $date';
  }

  @override
  String get currentPlan => 'Current plan';

  @override
  String get planNone => 'No paid plan';

  @override
  String planProUntil(String date) {
    return 'Pro until $date';
  }

  @override
  String get planProOpenEnded => 'Pro (no end date)';

  @override
  String creditsBalance(int count) {
    return 'Quote credits: $count';
  }

  @override
  String get planHistory => 'Plan history';

  @override
  String get planHistoryEmpty => 'No plans granted or bought yet.';

  @override
  String get recordPayment => 'Record manual payment';

  @override
  String get recordPaymentIntro =>
      'Only for a payment received outside the app (UPI or bank transfer). The seller gets the plan at once and the grant is written to the audit log.';

  @override
  String get plan => 'Plan';

  @override
  String get planProMonthly => 'Pro monthly (30 days)';

  @override
  String get planProAnnual => 'Pro annual (365 days)';

  @override
  String get planCredits10 => '10 quote credits';

  @override
  String get planCredits50 => '50 quote credits';

  @override
  String planValidUntil(String date) {
    return 'Valid until the end of $date';
  }

  @override
  String get creditsNoExpiry => 'Credits do not expire.';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodBankTransfer => 'Bank transfer';

  @override
  String get methodOther => 'Other';

  @override
  String amountReceived(String currency) {
    return 'Amount received ($currency)';
  }

  @override
  String get amountInvalid => 'Enter an amount like 499 or 499.50';

  @override
  String get paymentReference => 'Payment reference (UTR / transaction id)';

  @override
  String get referenceInvalid => '4 to 64 letters or digits (. _ / - allowed)';

  @override
  String referenceUsed(String date) {
    return 'This reference was already used for a grant on $date. One payment, one grant.';
  }

  @override
  String get payerName => 'Payer name (as on the bank statement)';

  @override
  String get bankChecked =>
      'I have checked this payment arrived in the company bank account';

  @override
  String get grantPlan => 'Grant plan';

  @override
  String grantDone(String summary) {
    return 'Plan granted. $summary';
  }

  @override
  String manualPaymentLine(
    String method,
    String currency,
    String amount,
    String reference,
  ) {
    return '$method $currency $amount, ref $reference';
  }

  @override
  String paidBy(String name) {
    return 'paid by $name';
  }

  @override
  String get navSeo => 'SEO pages';

  @override
  String get seoTabPages => 'Price pages';

  @override
  String get seoTabGuides => 'Guides';

  @override
  String get seoRunExport => 'Run export now';

  @override
  String get seoRunExportTitle => 'Run the SEO export now?';

  @override
  String get seoRunExportBody =>
      'Recomputes every city x category page from real quotes, uploads the anonymised data file to the public bucket and triggers the website rebuild when the Vercel Deploy Hook is configured. It also runs every night.';

  @override
  String seoExportDone(int pages, int priced, int guides, String hook) {
    return 'Export done: $pages pages, $priced with prices, $guides guides. Deploy hook: $hook.';
  }

  @override
  String seoLastRun(
    String when,
    String by,
    int indexable,
    int noindex,
    int waiting,
    String hook,
  ) {
    return 'Last export $when by $by: $indexable indexable, $noindex noindex, $waiting waiting for data. Deploy hook: $hook.';
  }

  @override
  String seoLastRunFailed(String when, String error) {
    return 'Last export $when failed: $error';
  }

  @override
  String get seoNoRuns => 'No export has run yet.';

  @override
  String get seoStatusIndexable => 'Indexable';

  @override
  String get seoStatusNoindex => 'Noindex';

  @override
  String get seoStatusWaiting => 'Waiting for data';

  @override
  String get seoThresholds => 'Quality gates';

  @override
  String seoThresholdsHelp(int quotes, int sellers, int window, int stale) {
    return 'A city x category page is indexable with at least $quotes quotes from $sellers different sellers in the last $window days and a quote within $stale days. Below that it is noindex and left out of the sitemap. Prices are medians, never single quotes.';
  }

  @override
  String get seoMinQuotes => 'Min quotes';

  @override
  String get seoMinSellers => 'Min sellers';

  @override
  String get seoWindowDays => 'Window (days)';

  @override
  String get seoStaleDays => 'Stale after (days)';

  @override
  String seoRange(int min, int max) {
    return '$min to $max';
  }

  @override
  String get seoThresholdsTakeEffect => 'New gates apply at the next export.';

  @override
  String get seoColPage => 'Page';

  @override
  String get seoColStatus => 'Status';

  @override
  String get seoColQuotes => 'Quotes';

  @override
  String get seoColSellers => 'Sellers';

  @override
  String get seoColLocal => 'Local sellers';

  @override
  String get seoColLastQuote => 'Last quote';

  @override
  String get seoColUpdated => 'Updated';

  @override
  String get seoColReasons => 'Why';

  @override
  String get seoForceNoindex => 'Force noindex';

  @override
  String get seoNoPages =>
      'No price pages yet. Pages appear here after the first export once real quotes exist.';

  @override
  String seoGuidesAiQuota(int used, int cap) {
    return 'New AI-assisted guides this week: $used of $cap';
  }

  @override
  String get seoGuideCap => 'Weekly AI guide cap';

  @override
  String get seoGuideNew => 'New guide';

  @override
  String get seoGuideEdit => 'Edit guide';

  @override
  String get seoGuideSlug => 'Slug (URL)';

  @override
  String get seoGuideTitle => 'Title';

  @override
  String get seoGuideDescription => 'Short description';

  @override
  String get seoGuideCategory => 'Category';

  @override
  String get seoGuideCity => 'City (optional)';

  @override
  String get seoGuideNoCity => 'No city';

  @override
  String get seoGuideBody => 'Body (Markdown)';

  @override
  String get seoGuideAi => 'AI-assisted draft';

  @override
  String seoGuideAiHelp(int cap) {
    return 'AI drafts must be reviewed and approved by a person before they go live. At most $cap new AI-assisted guides per week.';
  }

  @override
  String get seoGuideEditResets =>
      'Saving sends an approved or published guide back to draft: it needs a new review.';

  @override
  String get seoGuideApprove => 'Approve';

  @override
  String get seoGuidePublish => 'Publish';

  @override
  String get seoGuideUnpublish => 'Unpublish';

  @override
  String get seoGuideReject => 'Back to draft';

  @override
  String seoGuideReviewed(String date) {
    return 'Reviewed $date';
  }

  @override
  String get seoGuideStatusDraft => 'Draft';

  @override
  String get seoGuideStatusApproved => 'Approved';

  @override
  String get seoGuideStatusPublished => 'Published';

  @override
  String get seoGuideAiBadge => 'AI-assisted';

  @override
  String get seoGuideReviewOverdue =>
      'Review overdue: re-review at least twice a year';

  @override
  String get seoGuidesEmpty => 'No guides yet.';

  @override
  String seoGuideSite(String visibility) {
    return 'On the site: $visibility';
  }

  @override
  String seoGuideInvalid(String code) {
    return 'Invalid guide: $code';
  }

  @override
  String get navTrends => 'Trends';

  @override
  String get trendsCountryUsa => 'USA';

  @override
  String get trendsCountryIndia => 'India';

  @override
  String get trendsTabBoard => 'Live board';

  @override
  String get trendsTabTopics => 'Fired topics';

  @override
  String get trendsTabDrafts => 'Drafts';

  @override
  String get trendsTabReview => 'Review queue';

  @override
  String get trendsTabControls => 'Controls';

  @override
  String get trendsTopicWatching => 'Watching';

  @override
  String get trendsTopicFired => 'Fired';

  @override
  String get trendsTopicReview => 'In review';

  @override
  String get trendsTopicDrafted => 'Drafted';

  @override
  String get trendsTopicPublished => 'Published';

  @override
  String get trendsTopicWaitingSources => 'Waiting for sources';

  @override
  String get trendsTopicDropped => 'Dropped';

  @override
  String get trendsTopicEnded => 'Ended';

  @override
  String get trendsDraftQueued => 'Queued';

  @override
  String get trendsDraftReview => 'Review';

  @override
  String get trendsDraftRejected => 'Rejected';

  @override
  String get trendsDraftPublished => 'Published';

  @override
  String get trendsDraftNoindex => 'Noindex';

  @override
  String get trendsQueuedCaps => 'waiting for the caps';

  @override
  String get trendsQueuedDraft => 'waiting for the draft';

  @override
  String get trendsStageTopic => 'topic stage';

  @override
  String get trendsStageContent => 'final text stage';

  @override
  String get trendsActionReject => 'Reject';

  @override
  String get trendsActionNoindex => 'Set noindex';

  @override
  String get trendsActionIndex => 'Make indexable again';

  @override
  String get trendsActionUnpublish => 'Unpublish';

  @override
  String trendsActionTitle(String action, String headline) {
    return '$action: $headline';
  }

  @override
  String get trendsActions => 'Actions';

  @override
  String get trendsOpenDraft => 'Open';

  @override
  String get trendsGateSources => '2+ sources';

  @override
  String get trendsGateSensitive => 'Sensitive';

  @override
  String get trendsGateOriginality => 'Originality';

  @override
  String get trendsGateFacts => 'Facts';

  @override
  String get trendsGateValue => 'Value';

  @override
  String get trendsGateBalance => 'Balance';

  @override
  String get trendsGateCaps => 'Caps';

  @override
  String get trendsGates => 'Quality gates';

  @override
  String get trendsNoGates => 'No gate has run yet.';

  @override
  String trendsRateLimited(int limit, int minutes) {
    return 'Run now is limited to $limit runs per hour for each function. Try again in $minutes min.';
  }

  @override
  String get trendsErrNotInReview =>
      'Someone else already decided this one. The queue has been refreshed.';

  @override
  String get trendsErrAdminOnly => 'This needs the admin role.';

  @override
  String get trendsAddCorrection => 'Add correction';

  @override
  String get trendsCorrectionHint =>
      'What was wrong and what is correct (at least 10 characters)';

  @override
  String get trendsCorrectionTooShort =>
      'A correction needs at least 10 characters.';

  @override
  String get trendsCorrectionAdded =>
      'Correction added. The article is re-published within 5 minutes.';

  @override
  String get trendsRecordTraffic => 'Record traffic';

  @override
  String trendsRecordTrafficTitle(String slug) {
    return 'Visits to /$slug in the 14 days after the trend ended';
  }

  @override
  String get trendsVisitsHint => 'Visits in the 14 days after the trend ended';

  @override
  String get trendsInvalidNumber => 'Enter a valid number.';

  @override
  String get trendsSupersede => 'Mark superseded';

  @override
  String trendsSupersedeTitle(String slug) {
    return 'Supersede /$slug';
  }

  @override
  String get trendsSupersedeHint =>
      'Slug of the newer article (it gets the canonical)';

  @override
  String trendsPausedBanner(String who, String reason, String at) {
    return 'Publishing and drafting are paused (by $who: $reason, since $at). Polling continues.';
  }

  @override
  String get trendsPausedByAuto => 'automatic pause';

  @override
  String trendsLastHours(int hours) {
    return '$hours h';
  }

  @override
  String get trendsPlaceFilter => 'Filter places';

  @override
  String trendsGeneratedAt(String at) {
    return 'Updated $at. Refreshes every minute.';
  }

  @override
  String get trendsNoTopics => 'No topics in this period.';

  @override
  String trendsFailingSources(int count) {
    return '$count feed(s) failing: blind spots on the board';
  }

  @override
  String trendsSignalsDomains(int signals, int domains) {
    return '$signals signals, $domains publishers';
  }

  @override
  String trendsFiredAt(String at) {
    return 'fired $at';
  }

  @override
  String get trendsSources => 'Polled sources';

  @override
  String get trendsAddSource => 'Add source';

  @override
  String get trendsColKind => 'Kind';

  @override
  String get trendsColCountry => 'Country';

  @override
  String get trendsColGeo => 'Geo';

  @override
  String get trendsColPlace => 'Place';

  @override
  String get trendsColQuery => 'Query / subreddit';

  @override
  String get trendsColStatus => 'Status';

  @override
  String get trendsColItems => 'Items';

  @override
  String get trendsColPolled => 'Last polled';

  @override
  String get trendsColEnabled => 'Enabled';

  @override
  String get trendsColTopic => 'Topic';

  @override
  String get trendsColVelocity => 'Velocity';

  @override
  String get trendsColSignals => 'Signals';

  @override
  String get trendsColDomains => 'Publishers';

  @override
  String get trendsColFired => 'Fired';

  @override
  String get trendsColReason => 'Reason';

  @override
  String get trendsDisabled => 'disabled';

  @override
  String get trendsLevel => 'Level';

  @override
  String get trendsPlaceSlug => 'Place slug';

  @override
  String get trendsPlaceName => 'Place name';

  @override
  String get trendsState => 'State (optional)';

  @override
  String get trendsQueryHelp =>
      'Google News search or subreddit name (not used for Google Trends)';

  @override
  String get trendsFiredHelp =>
      'Fired topics are waiting for the drafting run (gates 1 and 2 run before any model call).';

  @override
  String get trendsNoDrafts => 'No drafts with this status.';

  @override
  String trendsVelocity(int value) {
    return 'velocity $value';
  }

  @override
  String trendsPublishedAt(String at) {
    return 'published $at';
  }

  @override
  String trendsCreatedAt(String at) {
    return 'created $at';
  }

  @override
  String trendsVisits(int visits) {
    return '$visits visits after the trend';
  }

  @override
  String get trendsSensitive => 'Sensitive';

  @override
  String get trendsDirty => 'Re-upload pending';

  @override
  String trendsFailedGate(String gate) {
    return 'failed gate $gate';
  }

  @override
  String trendsNoindexReason(String reason) {
    return 'noindex: $reason';
  }

  @override
  String trendsTopicReviewedBy(String who, String at) {
    return 'Topic approved by $who on $at';
  }

  @override
  String trendsReviewedBy(String who, String at) {
    return 'Final text reviewed by $who on $at';
  }

  @override
  String get trendsReviewHelp =>
      'Sensitive topics never publish without a person. Topic stage: nothing has been drafted yet; approving lets the pipeline draft it. Final text stage: the finished article passed gates 3 to 5; approving queues it for publishing (caps still apply). Your name and the date are stored.';

  @override
  String get trendsReviewEmpty => 'Nothing waiting for review.';

  @override
  String get trendsApproveTopicTitle => 'Approve this topic for drafting?';

  @override
  String get trendsApproveContentTitle =>
      'Approve the final text for publishing?';

  @override
  String get trendsRejectTopicTitle => 'Reject this topic';

  @override
  String get trendsRejectContentTitle => 'Reject this article';

  @override
  String get trendsReviewNoteHint => 'Note (required to reject)';

  @override
  String get trendsApproved => 'Approved. Reviewer and date recorded.';

  @override
  String get trendsRejected => 'Rejected.';

  @override
  String trendsWaitingSince(String at) {
    return 'waiting since $at';
  }

  @override
  String trendsSensitiveReasons(String reasons) {
    return 'Why it is sensitive: $reasons';
  }

  @override
  String get trendsTopicStageHelp =>
      'Nothing has been drafted yet: sensitive topics never reach the model before a person approves them. Check the topic and its headlines.';

  @override
  String get trendsContentStageHelp =>
      'The finished article passed originality, fact and value checks. Read it in full before approving.';

  @override
  String get trendsShowHeadlines => 'Topic and headlines';

  @override
  String get trendsReadArticle => 'Read the article';

  @override
  String get trendsApproveTopic => 'Approve topic';

  @override
  String get trendsApproveContent => 'Approve final text';

  @override
  String get trendsOptional => 'Optional';

  @override
  String get trendsKillSwitch => 'Kill switch';

  @override
  String get trendsResume => 'Resume';

  @override
  String get trendsPause => 'Pause now';

  @override
  String get trendsPausedNow => 'Paused: no drafting, no publishing';

  @override
  String get trendsRunningNow => 'Running: drafting and publishing are allowed';

  @override
  String trendsPausedDetail(String who, String reason, String at) {
    return 'Paused by $who: $reason (since $at)';
  }

  @override
  String trendsResumedDetail(String who, String reason) {
    return 'Last resumed by $who: $reason';
  }

  @override
  String get trendsKillSwitchHelp =>
      'Pausing stops model spend and publishing at once; polling continues so the board stays live. The site build also refuses articles published after the pause.';

  @override
  String get trendsPauseTitle => 'Pause drafting and publishing?';

  @override
  String get trendsPauseBody =>
      'Nothing is drafted or published until someone resumes. Say why (shown to other admins).';

  @override
  String get trendsResumeTitle => 'Resume drafting and publishing?';

  @override
  String get trendsResumeBody =>
      'Drafting (Claude spend) and publishing start again on the next run, within the caps. Make sure the reason for the pause is resolved.';

  @override
  String get trendsPausedToast => 'Paused.';

  @override
  String get trendsResumedToast => 'Resumed.';

  @override
  String get trendsPipeline => 'Pipeline (cron jobs)';

  @override
  String get trendsPipelineEnabled =>
      'On: poll, draft and publish run every 5 minutes';

  @override
  String get trendsPipelineDisabled => 'Off: no scheduled runs';

  @override
  String get trendsPipelineHelp =>
      'Run the pipeline in ONE project only: it covers both countries.';

  @override
  String get trendsPipelineOnTitle => 'Turn the pipeline on?';

  @override
  String get trendsPipelineOffTitle => 'Turn the pipeline off?';

  @override
  String get trendsPipelineOnBody =>
      'Starts the poll, draft and publish cron jobs in this project. Only do this in the one project that runs the trends site.';

  @override
  String get trendsPipelineOffBody =>
      'Stops all scheduled polling, drafting and publishing. The board stops updating.';

  @override
  String get trendsPipelineOn => 'Turn on';

  @override
  String get trendsPipelineOff => 'Turn off';

  @override
  String get trendsRunNowSection => 'Run now';

  @override
  String get trendsRunNowHelp =>
      'Runs one step immediately with your admin session. Limited to 6 runs per hour per function so repeated clicks cannot run up model spend.';

  @override
  String get trendsRunPollHelp =>
      'Polls Google Trends, Google News and Reddit feeds and updates the board.';

  @override
  String get trendsRunDraftHelp =>
      'Drafts fired topics with Claude and runs the quality gates (uses model spend).';

  @override
  String get trendsRunPublishHelp =>
      'Applies the caps and ramp, uploads articles and the index, and triggers the site rebuild.';

  @override
  String trendsRunNowTitle(String fn) {
    return 'Run $fn now?';
  }

  @override
  String get trendsRunNow => 'Run now';

  @override
  String trendsRunDryRun(String fn, String reason, String stats) {
    return '$fn: dry run ($reason). $stats';
  }

  @override
  String trendsRunDone(String fn, String stats) {
    return '$fn done: $stats';
  }

  @override
  String get trendsNoRunYet => 'No run yet.';

  @override
  String trendsLastRun(String at, String trigger, String result, String stats) {
    return 'Last run $at ($trigger): $result. $stats';
  }

  @override
  String get trendsRunning => 'running';

  @override
  String get trendsDryRun => 'dry run';

  @override
  String trendsRunNowLeft(int left, int limit) {
    return '$left of $limit admin runs left this hour';
  }

  @override
  String trendsRunNowExhausted(int limit, int minutes) {
    return '$limit admin runs used this hour; next in $minutes min';
  }

  @override
  String get trendsRamp => 'Ramp and daily caps';

  @override
  String trendsRampHelp(String levels, int days) {
    return 'Per country per day: $levels. Step up one level at a time, at least $days days apart, only with a healthy snapshot from the last week. The pipeline steps down by itself when health drops.';
  }

  @override
  String trendsPerDay(int perDay) {
    return '$perDay per day';
  }

  @override
  String trendsRampLevel(int level, int total) {
    return 'level $level of $total';
  }

  @override
  String trendsPublished24h(int count) {
    return '$count published in 24 h';
  }

  @override
  String trendsRampChanged(String at) {
    return 'last change $at';
  }

  @override
  String get trendsRampTop => 'already at the top level';

  @override
  String trendsRampTooSoon(int days) {
    return 'less than $days days since the last step';
  }

  @override
  String trendsRampUnhealthy(String problem) {
    return 'not healthy: $problem';
  }

  @override
  String trendsRampUpTitle(String country) {
    return 'Step $country up one level?';
  }

  @override
  String trendsRampDownTitle(String country) {
    return 'Step $country down one level?';
  }

  @override
  String trendsRampBody(int from, int to) {
    return 'From $from to $to articles per day. Remember: the site config caps are a ceiling, raise them in the repo when ramping up.';
  }

  @override
  String get trendsRampUp => 'Step up';

  @override
  String get trendsRampDown => 'Step down';

  @override
  String get trendsSiteCeiling =>
      'The site build never publishes more than the lower of these caps and web/trends_site/data/config.json.';

  @override
  String get trendsHealthy => 'healthy';

  @override
  String get trendsProblemNoRecent => 'no snapshot in the last week';

  @override
  String get trendsProblemManualAction => 'Search Console manual action';

  @override
  String get trendsProblemErrorReports => 'error reports spike';

  @override
  String get trendsProblemScWarnings => 'Search Console warnings';

  @override
  String get trendsProblemLowIndexed => 'low indexed share';

  @override
  String get trendsProblemTrafficDrop => 'traffic drop';

  @override
  String get trendsHealth => 'Health inputs (Search Console and analytics)';

  @override
  String get trendsHealthHelp =>
      'Enter the figures weekly until an integration exists. A manual action or an error-report spike pauses publishing immediately.';

  @override
  String trendsHealthLatest(
    String at,
    String share,
    String clicks,
    String prev,
    int warnings,
    int errors,
  ) {
    return '$at: indexed $share, clicks $clicks (prev. $prev), $warnings warnings, $errors error reports';
  }

  @override
  String get trendsManualAction => 'Manual action';

  @override
  String get trendsManualActionHelp => 'Pauses publishing immediately';

  @override
  String get trendsRecordHealth => 'Record health snapshot';

  @override
  String trendsHealthAutoPaused(String reason) {
    return 'Snapshot recorded. Publishing was paused automatically ($reason).';
  }

  @override
  String trendsHealthRecorded(String problem) {
    return 'Snapshot recorded. Health: $problem.';
  }

  @override
  String get trendsIndexedShare => 'Indexed share (%)';

  @override
  String get trendsIndexedShareHelp =>
      'Indexed pages / submitted pages in Search Console, 0 to 100';

  @override
  String get trendsClicks7d => 'Clicks, last 7 days';

  @override
  String get trendsClicksPrev7d => 'Clicks, previous 7 days';

  @override
  String get trendsScWarnings => 'Search Console warnings';

  @override
  String get trendsErrorReports => 'Error reports, last 24 h';

  @override
  String get trendsHealthIncomplete => 'Fill in every number.';

  @override
  String get trendsSlug => 'Article slug';

  @override
  String get trendsSettings => 'Caps, thresholds and lists';

  @override
  String get trendsSettingsHelp =>
      'The server refuses values below the brief\'s floors: at least 2 sources, at least 250 words, similarity at most 0.5, at most 1 rewrite, at most 3 per hour, at most 20 per day, at least 30 days between ramp steps.';

  @override
  String trendsEditSetting(String key) {
    return 'Edit $key';
  }

  @override
  String get trendsJsonHelp => 'JSON array';

  @override
  String get trendsListHelp => 'One entry per line';

  @override
  String get trendsCommaHelp => 'Comma separated';

  @override
  String trendsFloor(String problem) {
    return 'Not allowed: $problem';
  }

  @override
  String trendsServerRefused(String error) {
    return 'The server refused the change: $error';
  }

  @override
  String get trendsDecisionLog => 'Decision log';

  @override
  String get trendsNoLog => 'No decisions yet.';

  @override
  String get trendsPipelineActor => 'pipeline';

  @override
  String get trendsDraft => 'Draft';

  @override
  String get trendsSensitiveReasonsLabel => 'Sensitive because';

  @override
  String get trendsFailedGateLabel => 'Failed gate';

  @override
  String get trendsTopicReviewLabel => 'Topic review';

  @override
  String get trendsContentReviewLabel => 'Final text review';

  @override
  String get trendsModel => 'Model';

  @override
  String trendsRewrites(int rewrites) {
    return '$rewrites rewrite(s)';
  }

  @override
  String get trendsPublishedLabel => 'Published';

  @override
  String get trendsLastUpdateLabel => 'Last update';

  @override
  String get trendsNoindexLabel => 'Noindex reason';

  @override
  String get trendsSupersededLabel => 'Superseded by';

  @override
  String get trendsVisitsLabel => 'Visits after the trend';

  @override
  String get trendsStorageLabel => 'Bucket path';

  @override
  String get trendsNoArticle => 'No article text yet.';

  @override
  String get trendsArticle => 'Article (as on the site)';

  @override
  String get trendsFraming => 'Framing';

  @override
  String get trendsWhereAgree => 'Where they agree';

  @override
  String get trendsLocalAngle => 'What it means locally';

  @override
  String get trendsContext => 'Context';

  @override
  String get trendsWatchNext => 'What to watch';

  @override
  String get trendsUpdates => 'Updates';

  @override
  String get trendsCorrections => 'Corrections';

  @override
  String get trendsSourcesSection => 'Sources';

  @override
  String get trendsAppLink => 'App link';

  @override
  String get trendsReviewStamp => 'Review stamp';

  @override
  String trendsSignals(int count) {
    return 'Headlines behind it ($count)';
  }

  @override
  String get trendsNoSignals => 'No signals.';

  @override
  String get trendsNotCitable => 'not citable';
}

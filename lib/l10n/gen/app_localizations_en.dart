// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Tell shops what you want. Get quotes. Pick the best.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get send => 'Send';

  @override
  String get skip => 'Skip';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get loading => 'Loading…';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get offlineBanner => 'You\'re offline. Showing saved data.';

  @override
  String get demoModeBanner => 'Demo mode: sample data, OTP 123456';

  @override
  String get seeAll => 'See all';

  @override
  String get share => 'Share';

  @override
  String get report => 'Report';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get call => 'Call';

  @override
  String get chat => 'Chat';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this later in Settings.';

  @override
  String get welcomeTitle => 'Get quotes from local shops';

  @override
  String get welcomeBody1 => 'Post what you need in seconds.';

  @override
  String get welcomeBody2 => 'Shops and service pros send you prices.';

  @override
  String get welcomeBody3 => 'Compare, chat and pick the best deal.';

  @override
  String get signInPhone => 'Continue with phone';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get signInEmail => 'Continue with email';

  @override
  String get signInApple => 'Sign in with Apple';

  @override
  String signInLegal(String terms, String privacy) {
    return 'By continuing you agree to our $terms and $privacy.';
  }

  @override
  String get termsLink => 'Terms of Service';

  @override
  String get privacyLink => 'Privacy Policy';

  @override
  String get phoneTitle => 'Your mobile number';

  @override
  String get phoneSubtitle => 'We\'ll send a one-time code by SMS.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneInvalid => 'Enter a valid mobile number';

  @override
  String get emailTitle => 'Your email address';

  @override
  String get emailSubtitle => 'We\'ll email you a 6-digit sign-in code.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get sendCode => 'Send code';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'Sent to $phone';
  }

  @override
  String emailOtpSubtitle(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get otpLabel => '6-digit code';

  @override
  String get otpInvalid => 'That code didn\'t work. Check it and try again.';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authFailed => 'Sign-in failed. Please try again.';

  @override
  String get authCancelled => 'Sign-in was cancelled.';

  @override
  String get otpRateLimited => 'Too many attempts. Please wait a few minutes.';

  @override
  String get consentTitle => 'Before you start';

  @override
  String consentAccept(String terms, String privacy) {
    return 'I agree to the $terms and $privacy';
  }

  @override
  String get consentMarketing => 'Send me offers and tips (optional)';

  @override
  String get consentAnalytics => 'Help improve the app with anonymous usage data (optional)';

  @override
  String consentAge(int age) {
    return 'I am $age or older';
  }

  @override
  String get profileSetupTitle => 'What should we call you?';

  @override
  String get nameLabel => 'Your name';

  @override
  String get nameRequired => 'Please enter your name';

  @override
  String get addPhoneTitle => 'Add your mobile number';

  @override
  String get addPhoneBody => 'Sellers need a verified phone number. Buyers can add one to get SMS updates.';

  @override
  String get modeBuyer => 'Buying';

  @override
  String get modeSeller => 'Selling';

  @override
  String get switchToSelling => 'Switch to selling';

  @override
  String get switchToBuying => 'Switch to buying';

  @override
  String get becomeSeller => 'I\'m a business';

  @override
  String get becomeSellerBody => 'Get leads from buyers near you and send quotes. Free for founding partners.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabRequests => 'My requests';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabAccount => 'Account';

  @override
  String get tabLeads => 'Leads';

  @override
  String get tabMyQuotes => 'My quotes';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String homeGreeting(String name) {
    return 'Hi $name';
  }

  @override
  String get homeGreetingAnon => 'Hi there';

  @override
  String get whatDoYouNeed => 'What do you need?';

  @override
  String get whatDoYouNeedHint => 'e.g. Double-door fridge, delivered by Friday';

  @override
  String get activeRequests => 'Your active requests';

  @override
  String get browseCategories => 'Popular categories';

  @override
  String get howItWorks => 'How it works';

  @override
  String get noActiveRequests => 'Nothing posted yet. Tell local shops what you want and get quotes.';

  @override
  String get postTitle => 'New request';

  @override
  String get postStepWhat => 'What';

  @override
  String get postStepDetails => 'Details';

  @override
  String get postStepWhere => 'When and where';

  @override
  String get postDescribeHint => 'Describe what you want. Brand, size, quantity…';

  @override
  String get postSpeak => 'Speak';

  @override
  String get postListening => 'Listening…';

  @override
  String get postSuggestedCategory => 'Suggested category';

  @override
  String get postPickCategory => 'Pick a category';

  @override
  String get postChangeCategory => 'Change';

  @override
  String get postAddPhotos => 'Add photos';

  @override
  String postPhotosCount(int count) {
    return '$count/6 photos';
  }

  @override
  String get postReferenceLink => 'Reference link (product page)';

  @override
  String get postBudget => 'Budget';

  @override
  String get postBudgetMin => 'From';

  @override
  String get postBudgetMax => 'To';

  @override
  String get postBudgetHidden => 'Hide my budget from sellers';

  @override
  String get postNeededBy => 'Needed by';

  @override
  String get postPickDate => 'Pick a date';

  @override
  String get postLocation => 'Delivery or service location';

  @override
  String get postUseGps => 'Use my location';

  @override
  String postPostalCode(String codeLabel) {
    return '$codeLabel';
  }

  @override
  String get postLocality => 'Area / locality';

  @override
  String get postFullAddress => 'Full address (shared only with the seller you accept)';

  @override
  String get postQuoteWindow => 'Accept quotes for';

  @override
  String get quoteWindow24h => '24 hours';

  @override
  String get quoteWindow48h => '48 hours';

  @override
  String get quoteWindow7d => '7 days';

  @override
  String get postWhoCanQuote => 'Who can quote';

  @override
  String get audienceLocal => 'Local shops';

  @override
  String get audienceOnline => 'Online sellers';

  @override
  String get audienceBoth => 'Both';

  @override
  String get postReview => 'Review and post';

  @override
  String get postSubmit => 'Post request';

  @override
  String get postSuccessTitle => 'Request posted';

  @override
  String postSuccessBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'We\'ve notified $count sellers near you.',
      one: 'We\'ve notified 1 seller near you.',
      zero: 'We\'ll notify sellers as they join your area.',
    );
    return '$_temp0';
  }

  @override
  String postBlockedCategory(String category, String reason) {
    return 'We can\'t take requests for $category in this app. $reason';
  }

  @override
  String get postBlockedReason => 'This category is regulated and isn\'t allowed here.';

  @override
  String get postRestrictedNotice => 'Only licensed sellers can quote in this category.';

  @override
  String get postRateLimited => 'You\'ve reached today\'s limit for new requests. Try again tomorrow.';

  @override
  String get postDuplicate => 'You already posted this request in the last 24 hours.';

  @override
  String get postDescribeRequired => 'Tell sellers what you need';

  @override
  String get postCategoryRequired => 'Pick a category';

  @override
  String get postLocationRequired => 'Add a location';

  @override
  String postCodeInvalid(String codeLabel) {
    return 'Enter a valid $codeLabel';
  }

  @override
  String get postalCodeLabelIndia => 'PIN code';

  @override
  String get postalCodeLabelUsa => 'ZIP code';

  @override
  String get requestsOpen => 'Open';

  @override
  String get requestsAwarded => 'Awarded';

  @override
  String get requestsPast => 'Past';

  @override
  String get requestsEmptyOpen => 'No open requests. Post one and get quotes from local shops.';

  @override
  String get requestsEmptyAwarded => 'Requests where you accepted a quote show up here.';

  @override
  String get requestsEmptyPast => 'Expired and cancelled requests show up here.';

  @override
  String quotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quotes',
      one: '1 quote',
      zero: 'No quotes yet',
    );
    return '$_temp0';
  }

  @override
  String quotesOfMax(int count, int max) {
    return '$count of $max quotes';
  }

  @override
  String closesIn(String time) {
    return 'Closes in $time';
  }

  @override
  String get closed => 'Closed';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusAwarded => 'Awarded';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get noQuotesYet => 'No quotes yet. Sellers usually respond within 2 hours.';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get cancelRequestConfirm => 'Cancel this request? Sellers won\'t be able to quote any more.';

  @override
  String get shareRequest => 'Share request';

  @override
  String get shareRequestWhatsapp => 'Ask friends on WhatsApp';

  @override
  String shareRequestText(String link) {
    return 'Which one should I pick? $link';
  }

  @override
  String get compare => 'Compare';

  @override
  String get compareSelect => 'Select up to 3 quotes to compare';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortPrice => 'Price';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortDelivery => 'Delivery date';

  @override
  String get sortDistance => 'Distance';

  @override
  String get quoteTotal => 'Total';

  @override
  String get quoteSubtotal => 'Subtotal';

  @override
  String get quoteTax => 'Tax';

  @override
  String get quoteDelivery => 'Delivery / installation';

  @override
  String get quoteFreeDelivery => 'Free';

  @override
  String get quoteOffered => 'Offered';

  @override
  String get quoteDeliveryDate => 'Delivery date';

  @override
  String get quoteWarranty => 'Warranty';

  @override
  String quoteValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get quoteNotes => 'Notes';

  @override
  String quoteResponseTime(String time) {
    return 'Replied in $time';
  }

  @override
  String get quoteVerified => 'Verified';

  @override
  String get quoteFoundingPartner => 'Founding partner';

  @override
  String get quoteNew => 'New';

  @override
  String gstIntra(String rate) {
    return 'CGST $rate% + SGST $rate%';
  }

  @override
  String gstInter(String rate) {
    return 'IGST $rate%';
  }

  @override
  String salesTax(String rate) {
    return 'Sales tax $rate%';
  }

  @override
  String get taxIncludedNote => 'Prices include GST';

  @override
  String get salesTaxNote => 'Sales tax may apply';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get shortlist => 'Shortlist';

  @override
  String get shortlisted => 'Shortlisted';

  @override
  String get counterOffer => 'Ask for a better price';

  @override
  String get counterOfferTitle => 'Request a revised quote';

  @override
  String get counterOfferTarget => 'Your target price';

  @override
  String get counterOfferNote => 'Message to the seller';

  @override
  String get counterOfferSent => 'Sent. The seller can revise the quote.';

  @override
  String counterOfferFrom(String price) {
    return 'Buyer asked for $price';
  }

  @override
  String get acceptConfirmTitle => 'Accept this quote?';

  @override
  String acceptConfirmBody(String seller) {
    return '$seller will get your contact details and address. Other sellers will be told politely that you chose another offer.';
  }

  @override
  String get acceptedTitle => 'Quote accepted';

  @override
  String acceptedBody(String seller) {
    return '$seller has been notified. You can call or chat with them now.';
  }

  @override
  String get declineTitle => 'Decline quote';

  @override
  String get declineReason => 'Reason (optional, shared with the seller)';

  @override
  String get declineReasonPrice => 'Price too high';

  @override
  String get declineReasonDelivery => 'Delivery too late';

  @override
  String get declineReasonOther => 'Chose another offer';

  @override
  String get quoteStatusSent => 'Sent';

  @override
  String get quoteStatusRevised => 'Revised';

  @override
  String get quoteStatusShortlisted => 'Shortlisted';

  @override
  String get quoteStatusDeclined => 'Declined';

  @override
  String get quoteStatusAccepted => 'Accepted';

  @override
  String get quoteStatusWithdrawn => 'Withdrawn';

  @override
  String get quoteStatusExpired => 'Expired';

  @override
  String get orderTitle => 'Order';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get orderTimeline => 'Progress';

  @override
  String get orderStatusAccepted => 'Accepted';

  @override
  String get orderStatusScheduled => 'Scheduled';

  @override
  String get orderStatusDispatched => 'Dispatched';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String orderMarkAs(String status) {
    return 'Mark as $status';
  }

  @override
  String get orderContact => 'Contact';

  @override
  String get orderAddress => 'Address';

  @override
  String get orderPayment => 'Payment';

  @override
  String get orderPaymentOffPlatform => 'Pay the seller directly. Record it here for your records.';

  @override
  String get orderRecordPayment => 'Record payment';

  @override
  String orderPaymentRecorded(String amount, String method) {
    return '$amount paid by $method';
  }

  @override
  String get paymentMethodUpi => 'UPI';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodBankTransfer => 'Bank transfer';

  @override
  String get paymentMethodSellerLink => 'Seller\'s payment link';

  @override
  String get paymentMethodZelle => 'Zelle';

  @override
  String get paymentMethodCheck => 'Check';

  @override
  String get rateSeller => 'Rate the seller';

  @override
  String get rateBuyer => 'Rate the buyer';

  @override
  String get reviewTitle => 'How did it go?';

  @override
  String get reviewTextHint => 'Tell others about your experience';

  @override
  String get reviewSubmit => 'Submit review';

  @override
  String get reviewThanks => 'Thanks for your review!';

  @override
  String get reviewTagOnTime => 'On time';

  @override
  String get reviewTagGoodPrice => 'Good price';

  @override
  String get reviewTagProfessional => 'Professional';

  @override
  String get reviewTagQuality => 'Great quality';

  @override
  String get reviewTagResponsive => 'Responsive';

  @override
  String get reviewReply => 'Reply publicly';

  @override
  String get reviewSellerReply => 'Response from the seller';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewsEmpty => 'No reviews yet.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Chats with sellers about your requests show up here.';

  @override
  String get chatHint => 'Message';

  @override
  String get chatContactWarning => 'For your safety, keep contact details in the app until you accept a quote.';

  @override
  String chatAboutRequest(String title) {
    return 'About: $title';
  }

  @override
  String get chatRead => 'Read';

  @override
  String get chatTyping => 'typing…';

  @override
  String get chatFailed => 'Not sent. Tap to retry.';

  @override
  String get chatPhoto => 'Photo';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'You\'re all caught up.';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String notifNewQuote(String seller) {
    return 'New quote from $seller';
  }

  @override
  String get notifQuoteRevised => 'A seller revised their quote';

  @override
  String get notifMessage => 'New message';

  @override
  String notifNewRequest(String title) {
    return 'New request: $title';
  }

  @override
  String get notifQuoteAccepted => 'Your quote was accepted!';

  @override
  String get notifQuoteDeclined => 'A buyer chose another offer';

  @override
  String get notifQuoteShortlisted => 'A buyer shortlisted your quote';

  @override
  String get notifCounterOffer => 'A buyer asked for a better price';

  @override
  String get notifOrderStatus => 'Order update';

  @override
  String get notifGeneric => 'Update';

  @override
  String get sellerOnboardingTitle => 'Set up your business';

  @override
  String get sellerStepBusiness => 'Business';

  @override
  String get sellerStepCategories => 'What you sell';

  @override
  String get sellerStepArea => 'Service area';

  @override
  String get sellerStepNotify => 'Alerts';

  @override
  String get businessName => 'Business name';

  @override
  String get businessDescription => 'About your business';

  @override
  String get yearsInBusiness => 'Years in business';

  @override
  String get brandsCarried => 'Brands you carry (comma separated)';

  @override
  String get addLogo => 'Add logo';

  @override
  String get addShopPhotos => 'Add shop photos';

  @override
  String get selectCategories => 'Select the categories you can quote for';

  @override
  String get categoriesRequired => 'Select at least one category';

  @override
  String get areaRadius => 'Radius around my shop';

  @override
  String areaCodes(String codeLabel) {
    return 'List of ${codeLabel}s';
  }

  @override
  String get areaNationwide => 'Ship nationwide';

  @override
  String radiusValue(int value) {
    return '$value km';
  }

  @override
  String radiusValueMiles(int value) {
    return '$value mi';
  }

  @override
  String get shopLocation => 'Shop location';

  @override
  String serviceCodesHint(String example) {
    return 'Comma separated, e.g. $example';
  }

  @override
  String get sellerState => 'State';

  @override
  String get notifyInstant => 'Instant alerts';

  @override
  String get notifyHourly => 'Hourly digest';

  @override
  String get notifyQuiet => 'Quiet hours';

  @override
  String quietHoursRange(String start, String end) {
    return 'Quiet from $start to $end';
  }

  @override
  String get sellerProfileSaved => 'Your business is live. New leads will show up in your feed.';

  @override
  String foundingPartnerBadge(String date) {
    return 'Founding partner: free until $date';
  }

  @override
  String get verificationTitle => 'Get verified';

  @override
  String get verificationBody => 'Verified sellers get a badge and see new requests first.';

  @override
  String get verificationStatusNone => 'Not verified';

  @override
  String get verificationStatusPending => 'Under review';

  @override
  String get verificationStatusVerified => 'Verified';

  @override
  String verificationStatusRejected(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get docGstin => 'GSTIN';

  @override
  String get docUdyam => 'Udyam registration number';

  @override
  String get docShopPhoto => 'Shop photo';

  @override
  String get docEin => 'EIN';

  @override
  String get docStateLicence => 'State business licence number';

  @override
  String get docBusinessAddress => 'Business address';

  @override
  String get docWebsite => 'Website';

  @override
  String get docInvalid => 'This number doesn\'t look right. Check it and try again.';

  @override
  String get uploadFile => 'Upload';

  @override
  String get submitForReview => 'Submit for review';

  @override
  String get submittedForReview => 'Submitted. We\'ll review it shortly.';

  @override
  String get licencesTitle => 'Licences';

  @override
  String get licencesBody => 'Required to quote in restricted categories.';

  @override
  String get addLicence => 'Add licence';

  @override
  String get licenceType => 'Licence type';

  @override
  String get licenceNumber => 'Licence number';

  @override
  String get licenceIssuer => 'Issuing body';

  @override
  String get licenceExpiry => 'Expiry date';

  @override
  String get leadsTitle => 'Leads';

  @override
  String get leadsEmpty => 'No matching requests right now. We\'ll alert you when buyers near you post.';

  @override
  String get leadsNoSellerProfile => 'Set up your business profile to start getting leads.';

  @override
  String get leadFilters => 'Filters';

  @override
  String get leadFilterCategory => 'Category';

  @override
  String get leadFilterDistance => 'Within';

  @override
  String get leadFilterAny => 'Any';

  @override
  String leadAway(String distance) {
    return '$distance away';
  }

  @override
  String leadQuotesSent(int count, int max) {
    return '$count of $max quotes sent';
  }

  @override
  String get leadFull => 'Quote limit reached';

  @override
  String leadNeededBy(String date) {
    return 'Needed by $date';
  }

  @override
  String leadBudget(String range) {
    return 'Budget $range';
  }

  @override
  String get leadBudgetHidden => 'Budget not shared';

  @override
  String get leadDismiss => 'Not interested';

  @override
  String get leadSendQuote => 'Send quote';

  @override
  String get leadAlreadyQuoted => 'You\'ve quoted';

  @override
  String get leadPriorityNote => 'Verified sellers see new requests first.';

  @override
  String get leadLocalityOnly => 'Exact address is shared after the buyer accepts your quote.';

  @override
  String get quoteFormTitle => 'Your quote';

  @override
  String get quoteItem => 'Item / service';

  @override
  String get quoteQty => 'Qty';

  @override
  String get quoteUnitPrice => 'Unit price';

  @override
  String get quoteAddLine => 'Add line';

  @override
  String get quoteTaxRate => 'GST rate';

  @override
  String get quoteSalesTaxRate => 'Sales tax rate (%)';

  @override
  String get quoteBrandModel => 'Brand / model offered';

  @override
  String get quoteValidity => 'Quote valid for';

  @override
  String quoteValidityDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get quoteAttachments => 'Attachments';

  @override
  String get quoteSaveTemplate => 'Save as template';

  @override
  String get quoteUseTemplate => 'Use template';

  @override
  String get quoteTemplateName => 'Template name';

  @override
  String get quoteSubmit => 'Send quote';

  @override
  String get quoteRevise => 'Send revised quote';

  @override
  String get quoteWithdraw => 'Withdraw quote';

  @override
  String get quoteSent => 'Quote sent';

  @override
  String get quotePriceRequired => 'Enter a price';

  @override
  String get quoteCapReached => 'This request already has the maximum number of quotes.';

  @override
  String get quoteRequestClosed => 'This request is no longer open.';

  @override
  String get quoteNotAllowed => 'You can\'t quote on this request.';

  @override
  String get quoteLicenceRequired => 'A valid licence is required for this category.';

  @override
  String get quoteNoCredits => 'You\'re out of free quotes this month. See plans.';

  @override
  String get quoteOnboardingFee => 'Pay the one-time onboarding fee to start quoting. See plans.';

  @override
  String get quotePriorityWindow => 'Verified sellers get the first 15 minutes on new requests.';

  @override
  String get quoteAlreadySent => 'You\'ve already quoted on this request.';

  @override
  String get templatesTitle => 'Quote templates';

  @override
  String get templatesEmpty => 'Save a quote as a template to reuse it.';

  @override
  String get myQuotesActive => 'Active';

  @override
  String get myQuotesWon => 'Won';

  @override
  String get myQuotesLost => 'Lost';

  @override
  String get myQuotesEmpty => 'No quotes here yet.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashActive => 'Active quotes';

  @override
  String get dashWon => 'Won';

  @override
  String get dashWinRate => 'Win rate';

  @override
  String get dashResponse => 'Avg. response';

  @override
  String get dashRevenue => 'Revenue logged';

  @override
  String get dashRating => 'Rating';

  @override
  String get dashQuotesThisMonth => 'Quotes this month';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String hoursShort(int count) {
    return '$count h';
  }

  @override
  String get planTitle => 'Plan and billing';

  @override
  String get planFreeLaunch => 'Everything is free during launch.';

  @override
  String planFoundingPartner(String date) {
    return 'As a founding partner you keep free access until $date.';
  }

  @override
  String planCurrent(String tier) {
    return 'Current plan: $tier';
  }

  @override
  String planFreeTier(int count) {
    return 'Free: $count quotes a month';
  }

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planAnnual => 'Annual';

  @override
  String get planSubscribe => 'Subscribe';

  @override
  String get planCredits => 'Quote credits';

  @override
  String planCreditsBalance(int count) {
    return '$count credits left';
  }

  @override
  String get planBuyCredits => 'Buy credits';

  @override
  String get onboardingFeeTitle => 'One-time onboarding fee';

  @override
  String get onboardingFeeBody => 'Pay once to start sending quotes. Founding partners don\'t pay this.';

  @override
  String onboardingFeePay(String amount) {
    return 'Pay $amount';
  }

  @override
  String get onboardingFeePaid => 'Onboarding fee paid. Thank you!';

  @override
  String get planRestore => 'Restore purchases';

  @override
  String get planManage => 'Manage subscription';

  @override
  String get planFixPayment => 'There\'s a problem with your payment. Update it to keep your plan.';

  @override
  String planRenewal(String store) {
    return 'Renews automatically. Cancel anytime in $store.';
  }

  @override
  String get planBuyOnWeb => 'Buy on our website';

  @override
  String get planNotAvailable => 'Plans aren\'t available in the app yet.';

  @override
  String get sellerProfileTitle => 'Business profile';

  @override
  String get sellerViewPublic => 'View as buyers see it';

  @override
  String sellerDirectoryOptIn(String app) {
    return 'Show my business on the $app website';
  }

  @override
  String get sellerDirectoryOptInBody =>
      'Shows your business name, categories, city, rating and response time on a public page. Never your phone number or address.';

  @override
  String get sellerDirectoryOptInOn =>
      'You\'re listed. Your page appears on the website after the next nightly update.';

  @override
  String get sellerDirectoryOptInOff => 'Hidden. Your page is removed from the website at the next nightly update.';

  @override
  String get sellerShareShop => 'Share my shop';

  @override
  String sellerShareText(String shop, String app, String link) {
    return 'Get quotes from $shop and other local shops on $app: $link';
  }

  @override
  String sellerYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years in business',
      one: '1 year in business',
    );
    return '$_temp0';
  }

  @override
  String sellerRating(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String sellerResponds(String time) {
    return 'Usually replies in $time';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsHelp => 'Help and FAQ';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get settingsLicenses => 'Open-source licences';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsBlocked => 'Blocked users';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get notifPrefNewQuotes => 'New quotes';

  @override
  String get notifPrefMessages => 'Messages';

  @override
  String get notifPrefLeads => 'New leads';

  @override
  String get notifPrefMarketing => 'Offers and tips';

  @override
  String get privacyAnalytics => 'Share anonymous usage data';

  @override
  String get privacyDoNotSell => 'Do Not Sell or Share My Personal Information';

  @override
  String get privacyDownload => 'Request a copy of my data';

  @override
  String get deleteTitle => 'Delete your account';

  @override
  String get deleteBody =>
      'This permanently deletes your profile, requests, quotes, chats and photos. Some records, such as completed orders and tax invoices, are kept as required by law and then deleted.';

  @override
  String get deleteConfirmLabel => 'Type DELETE to confirm';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String get deleteButton => 'Delete my account';

  @override
  String get deleteReauth => 'For your security, sign in again before deleting.';

  @override
  String get deleteDone => 'Your account has been deleted.';

  @override
  String get helpTitle => 'Help and FAQ';

  @override
  String get faqQ1 => 'Is it free for buyers?';

  @override
  String get faqA1 => 'Yes. Posting requests and receiving quotes is always free.';

  @override
  String get faqQ2 => 'How do I pay the seller?';

  @override
  String get faqA2 =>
      'You pay the seller directly, by the methods they accept. Record the payment in the order for your records.';

  @override
  String get faqQ3 => 'When does the seller see my phone and address?';

  @override
  String get faqA3 => 'Only after you accept their quote. Before that, you can chat in the app.';

  @override
  String get faqQ4 => 'How do sellers get verified?';

  @override
  String get faqA4 => 'They submit business documents that our team reviews.';

  @override
  String get faqQ5 => 'How do I report a problem?';

  @override
  String get faqA5 => 'Use Report on any chat, quote or profile, or contact support.';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get legalTitle => 'Legal';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportReasonSpam => 'Spam or scam';

  @override
  String get reportReasonAbuse => 'Abusive or offensive';

  @override
  String get reportReasonFake => 'Fake business or request';

  @override
  String get reportReasonProhibited => 'Prohibited item';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String get reportSent => 'Thanks. Our team will review it.';

  @override
  String blockConfirm(String name) {
    return 'Block $name? You won\'t see their quotes or messages.';
  }

  @override
  String get blocked => 'Blocked';

  @override
  String inAppReviewAsk(String app) {
    return 'Enjoying $app?';
  }

  @override
  String get updateRequired => 'Please update the app to continue.';

  @override
  String get permissionLocationRationale =>
      'We use your location to find sellers near you. It is only shared as your area until you accept a quote.';

  @override
  String get permissionNotificationsRationale =>
      'Turn on notifications to hear about new quotes and messages right away.';

  @override
  String get permissionMicRationale => 'Allow the microphone to describe your request by voice.';

  @override
  String get allow => 'Allow';

  @override
  String get notNow => 'Not now';

  @override
  String get accountBlockedTitle => 'Account unavailable';

  @override
  String accountSuspendedBody(String date) {
    return 'Your account is suspended until $date. You can still read our policies or contact support.';
  }

  @override
  String get accountSuspendedBodyNoDate =>
      'Your account is suspended. You can still read our policies or contact support.';

  @override
  String get accountBannedBody =>
      'Your account has been closed for breaking our rules. If you think this is a mistake, contact support.';

  @override
  String get accountDeletedBody => 'This account has been deleted.';

  @override
  String get tabCommunity => 'Community';

  @override
  String get communityTitle => 'Community';

  @override
  String get communitySubtitle => 'See what people nearby need, comment, and team up for bulk prices.';

  @override
  String get feedFilterAll => 'All';

  @override
  String get feedFilterGroupBuys => 'Group buys';

  @override
  String get feedFilterOpen => 'Open';

  @override
  String get feedFilterMine => 'Mine';

  @override
  String get feedEmpty => 'Nothing here yet. Post what you need and share it on the feed.';

  @override
  String get feedPostTitle => 'Post';

  @override
  String get feedPostGone => 'This post is no longer on the feed.';

  @override
  String get feedLike => 'Like';

  @override
  String get feedComment => 'Comment';

  @override
  String feedLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'No likes',
    );
    return '$_temp0';
  }

  @override
  String feedCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'No comments',
    );
    return '$_temp0';
  }

  @override
  String feedQuotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quotes',
      one: '1 quote',
      zero: 'No quotes yet',
    );
    return '$_temp0';
  }

  @override
  String get feedYou => 'You';

  @override
  String get feedOnFeed => 'On community feed';

  @override
  String get feedPublish => 'Share on community feed';

  @override
  String get feedUnpublish => 'Remove from community feed';

  @override
  String get feedOpenPost => 'View community post';

  @override
  String get feedPublished => 'Shared on the community feed';

  @override
  String get feedUnpublished => 'Removed from the community feed';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsEmpty => 'No comments yet. Start the conversation.';

  @override
  String get commentHint => 'Write a comment…';

  @override
  String get commentReply => 'Reply';

  @override
  String commentReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get commentAsBusiness => 'Post as my business';

  @override
  String get commentSend => 'Send';

  @override
  String get commentAuthor => 'Author';

  @override
  String get commentDeleteConfirm => 'Delete this comment?';

  @override
  String get commentBlockedContent => 'That mentions something that is not allowed here.';

  @override
  String get commentTooLong => 'That comment is too long.';

  @override
  String get communityRateLimited => 'You are doing that too often. Try again in a few minutes.';

  @override
  String get groupBuyBadge => 'Group buy';

  @override
  String get groupBuyTitle => 'Group buy';

  @override
  String get groupBuyExplainer => 'More people joining means a bigger order, so sellers offer a lower price per unit.';

  @override
  String groupJoinedSummary(int members, String qty, String unit) {
    String _temp0 = intl.Intl.pluralLogic(members, locale: localeName, other: '$members people', one: '1 person');
    return '$_temp0 · $qty $unit';
  }

  @override
  String groupPriceEach(String price) {
    return '$price each';
  }

  @override
  String get groupBestNow => 'Best price now';

  @override
  String groupNextTier(String qty, String unit, String price) {
    return '$qty more $unit unlocks $price each';
  }

  @override
  String get groupNoOffers => 'Waiting for sellers\' bulk offers';

  @override
  String get groupLadderTitle => 'Price as the group grows';

  @override
  String groupTierFrom(String qty, String unit) {
    return '$qty+ $unit';
  }

  @override
  String get groupCurrentTier => 'Now';

  @override
  String get groupJoin => 'Join group buy';

  @override
  String get groupChangeQty => 'Change quantity';

  @override
  String get groupLeave => 'Leave';

  @override
  String groupJoinTitle(String unit) {
    return 'How many $unit do you need?';
  }

  @override
  String get groupQtyLabel => 'Quantity';

  @override
  String get groupNoteLabel => 'Note for the group (optional)';

  @override
  String get groupJoinPrivacy =>
      'If the organiser accepts an offer, that seller gets your name and phone number to arrange your order.';

  @override
  String groupYouJoined(String qty, String unit) {
    return 'You\'re in for $qty $unit';
  }

  @override
  String get groupJoinedToast => 'You joined the group buy';

  @override
  String get groupLeftToast => 'You left the group buy';

  @override
  String get groupClosed => 'This group buy is closed';

  @override
  String groupWinner(String seller) {
    return 'Accepted offer: $seller';
  }

  @override
  String get groupWinnerContact => 'The seller will contact you to arrange your order.';

  @override
  String get groupMembersTitle => 'Members';

  @override
  String get groupOrganiser => 'Organiser';

  @override
  String get groupHasMembers => 'People have joined this group buy, so it has to stay on the feed.';

  @override
  String get groupInvalidQty => 'Enter a quantity between 1 and 1000';

  @override
  String get postToFeed => 'Share on the community feed';

  @override
  String get postToFeedHint => 'Anyone can see it and comment. Your phone number and address stay private.';

  @override
  String get postGroupBuy => 'Make it a group buy';

  @override
  String get postGroupBuyHint =>
      'Others can join with their quantity, and sellers offer lower prices for bigger orders.';

  @override
  String get postGroupUnit => 'Unit';

  @override
  String get postGroupUnitHint => 'fans, kg, boxes…';

  @override
  String get postGroupMyQty => 'How many do you need?';

  @override
  String get quoteTiersTitle => 'Group price tiers';

  @override
  String get quoteTiersHint => 'This is a group buy. Offer a lower price per unit as the group grows (before tax).';

  @override
  String quoteTiersGroupNow(String qty, String unit) {
    return 'Group so far: $qty $unit';
  }

  @override
  String get quoteTierMinQty => 'From qty';

  @override
  String get quoteTierUnitPrice => 'Price each';

  @override
  String get quoteTierAdd => 'Add tier';

  @override
  String get quoteTiersInvalid => 'Each tier needs a bigger quantity and a lower price than the one before.';

  @override
  String notifFeedComment(String title) {
    return 'New comment on \"$title\"';
  }

  @override
  String notifFeedReply(String title) {
    return 'New reply on \"$title\"';
  }

  @override
  String notifGroupJoined(String title) {
    return 'Someone joined your group buy \"$title\"';
  }

  @override
  String notifGroupGrew(String title) {
    return 'The group buy \"$title\" grew';
  }

  @override
  String notifGroupPriceDrop(String title) {
    return 'Price dropped on \"$title\"';
  }

  @override
  String notifGroupAwarded(String title) {
    return 'The organiser picked a seller for \"$title\"';
  }

  @override
  String get notifQuoteTiers => 'A seller added group prices';
}

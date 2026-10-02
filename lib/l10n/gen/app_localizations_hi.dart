// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTagline => 'दुकानों को बताइए आपको क्या चाहिए। कोटेशन पाइए। सबसे अच्छा चुनिए।';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get next => 'आगे';

  @override
  String get back => 'वापस';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get done => 'हो गया';

  @override
  String get edit => 'बदलें';

  @override
  String get delete => 'हटाएं';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get close => 'बंद करें';

  @override
  String get send => 'भेजें';

  @override
  String get skip => 'छोड़ें';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get optional => 'वैकल्पिक';

  @override
  String get required => 'ज़रूरी';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get somethingWentWrong => 'कुछ गड़बड़ हो गई। कृपया फिर से कोशिश करें।';

  @override
  String get offlineBanner => 'आप ऑफ़लाइन हैं। सेव किया हुआ डेटा दिखाया जा रहा है।';

  @override
  String get demoModeBanner => 'डेमो मोड: सैंपल डेटा, OTP 123456';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get share => 'शेयर करें';

  @override
  String get report => 'रिपोर्ट करें';

  @override
  String get block => 'ब्लॉक करें';

  @override
  String get unblock => 'अनब्लॉक करें';

  @override
  String get call => 'कॉल करें';

  @override
  String get chat => 'चैट';

  @override
  String get languageTitle => 'अपनी भाषा चुनें';

  @override
  String get languageSubtitle => 'आप इसे बाद में सेटिंग्स में बदल सकते हैं।';

  @override
  String get welcomeTitle => 'आस-पास की दुकानों से कोटेशन पाएं';

  @override
  String get welcomeBody1 => 'कुछ ही सेकंड में बताएं आपको क्या चाहिए।';

  @override
  String get welcomeBody2 => 'दुकानें और सर्विस देने वाले आपको अपने दाम भेजते हैं।';

  @override
  String get welcomeBody3 => 'तुलना करें, चैट करें और सबसे अच्छी डील चुनें।';

  @override
  String get signInPhone => 'फ़ोन नंबर से आगे बढ़ें';

  @override
  String get signInGoogle => 'Google से आगे बढ़ें';

  @override
  String get signInApple => 'Apple से साइन इन करें';

  @override
  String signInLegal(String terms, String privacy) {
    return 'आगे बढ़कर आप हमारी $terms और $privacy से सहमत होते हैं।';
  }

  @override
  String get termsLink => 'सेवा की शर्तें';

  @override
  String get privacyLink => 'प्राइवेसी पॉलिसी';

  @override
  String get phoneTitle => 'आपका मोबाइल नंबर';

  @override
  String get phoneSubtitle => 'हम SMS से एक बार इस्तेमाल होने वाला कोड भेजेंगे।';

  @override
  String get phoneLabel => 'मोबाइल नंबर';

  @override
  String get phoneInvalid => 'सही मोबाइल नंबर डालें';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get otpTitle => 'कोड डालें';

  @override
  String otpSubtitle(String phone) {
    return '$phone पर भेजा गया';
  }

  @override
  String get otpLabel => '6 अंकों का कोड';

  @override
  String get otpInvalid => 'यह कोड काम नहीं किया। जांचकर फिर से कोशिश करें।';

  @override
  String get verify => 'वेरिफ़ाई करें';

  @override
  String get resendCode => 'कोड दोबारा भेजें';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकंड में दोबारा भेजें';
  }

  @override
  String get authFailed => 'साइन इन नहीं हो पाया। कृपया फिर से कोशिश करें।';

  @override
  String get authCancelled => 'साइन इन रद्द कर दिया गया।';

  @override
  String get otpRateLimited => 'बहुत ज़्यादा कोशिशें हो गईं। कृपया कुछ मिनट रुकें।';

  @override
  String get consentTitle => 'शुरू करने से पहले';

  @override
  String consentAccept(String terms, String privacy) {
    return 'मैं $terms और $privacy से सहमत हूं';
  }

  @override
  String get consentMarketing => 'मुझे ऑफ़र और टिप्स भेजें (वैकल्पिक)';

  @override
  String get consentAnalytics => 'बिना पहचान वाले इस्तेमाल के डेटा से app को बेहतर बनाने में मदद करें (वैकल्पिक)';

  @override
  String consentAge(int age) {
    return 'मेरी उम्र $age साल या उससे ज़्यादा है';
  }

  @override
  String get profileSetupTitle => 'हम आपको किस नाम से बुलाएं?';

  @override
  String get nameLabel => 'आपका नाम';

  @override
  String get nameRequired => 'कृपया अपना नाम डालें';

  @override
  String get addPhoneTitle => 'अपना मोबाइल नंबर जोड़ें';

  @override
  String get addPhoneBody =>
      'सेलर्स के लिए वेरिफ़ाइड फ़ोन नंबर ज़रूरी है। खरीदार SMS अपडेट पाने के लिए नंबर जोड़ सकते हैं।';

  @override
  String get modeBuyer => 'खरीदारी';

  @override
  String get modeSeller => 'बिक्री';

  @override
  String get switchToSelling => 'बिक्री पर जाएं';

  @override
  String get switchToBuying => 'खरीदारी पर जाएं';

  @override
  String get becomeSeller => 'मेरा बिज़नेस है';

  @override
  String get becomeSellerBody => 'आस-पास के खरीदारों से लीड पाएं और कोटेशन भेजें। फ़ाउंडिंग पार्टनर्स के लिए मुफ़्त।';

  @override
  String get tabHome => 'होम';

  @override
  String get tabRequests => 'मेरी रिक्वेस्ट';

  @override
  String get tabChats => 'चैट';

  @override
  String get tabAccount => 'अकाउंट';

  @override
  String get tabLeads => 'लीड';

  @override
  String get tabMyQuotes => 'मेरे कोटेशन';

  @override
  String get tabDashboard => 'डैशबोर्ड';

  @override
  String homeGreeting(String name) {
    return 'नमस्ते $name';
  }

  @override
  String get homeGreetingAnon => 'नमस्ते';

  @override
  String get whatDoYouNeed => 'आपको क्या चाहिए?';

  @override
  String get whatDoYouNeedHint => 'जैसे: डबल-डोर फ्रिज, शुक्रवार तक डिलीवरी';

  @override
  String get activeRequests => 'आपकी चालू रिक्वेस्ट';

  @override
  String get browseCategories => 'लोकप्रिय कैटेगरी';

  @override
  String get howItWorks => 'यह कैसे काम करता है';

  @override
  String get noActiveRequests =>
      'अभी तक कुछ पोस्ट नहीं किया। आस-पास की दुकानों को बताइए आपको क्या चाहिए और कोटेशन पाइए।';

  @override
  String get postTitle => 'नई रिक्वेस्ट';

  @override
  String get postStepWhat => 'क्या';

  @override
  String get postStepDetails => 'जानकारी';

  @override
  String get postStepWhere => 'कब और कहां';

  @override
  String get postDescribeHint => 'बताइए आपको क्या चाहिए। ब्रांड, साइज़, मात्रा…';

  @override
  String get postSpeak => 'बोलें';

  @override
  String get postListening => 'सुन रहे हैं…';

  @override
  String get postSuggestedCategory => 'सुझाई गई कैटेगरी';

  @override
  String get postPickCategory => 'कैटेगरी चुनें';

  @override
  String get postChangeCategory => 'बदलें';

  @override
  String get postAddPhotos => 'फ़ोटो जोड़ें';

  @override
  String postPhotosCount(int count) {
    return '$count/6 फ़ोटो';
  }

  @override
  String get postReferenceLink => 'रेफ़रेंस लिंक (प्रोडक्ट पेज)';

  @override
  String get postBudget => 'बजट';

  @override
  String get postBudgetMin => 'से';

  @override
  String get postBudgetMax => 'तक';

  @override
  String get postBudgetHidden => 'मेरा बजट सेलर्स से छिपाएं';

  @override
  String get postNeededBy => 'कब तक चाहिए';

  @override
  String get postPickDate => 'तारीख चुनें';

  @override
  String get postLocation => 'डिलीवरी या सर्विस की जगह';

  @override
  String get postUseGps => 'मेरी लोकेशन इस्तेमाल करें';

  @override
  String postPostalCode(String codeLabel) {
    return '$codeLabel';
  }

  @override
  String get postLocality => 'इलाका / मोहल्ला';

  @override
  String get postFullAddress => 'पूरा पता (सिर्फ़ उसी सेलर को दिखेगा जिसका कोटेशन आप स्वीकार करेंगे)';

  @override
  String get postQuoteWindow => 'कोटेशन कब तक लें';

  @override
  String get quoteWindow24h => '24 घंटे';

  @override
  String get quoteWindow48h => '48 घंटे';

  @override
  String get quoteWindow7d => '7 दिन';

  @override
  String get postWhoCanQuote => 'कौन कोटेशन भेज सकता है';

  @override
  String get audienceLocal => 'आस-पास की दुकानें';

  @override
  String get audienceOnline => 'ऑनलाइन सेलर्स';

  @override
  String get audienceBoth => 'दोनों';

  @override
  String get postReview => 'जांचें और पोस्ट करें';

  @override
  String get postSubmit => 'रिक्वेस्ट पोस्ट करें';

  @override
  String get postSuccessTitle => 'रिक्वेस्ट पोस्ट हो गई';

  @override
  String postSuccessBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हमने आपके पास के $count सेलर्स को बता दिया है।',
      one: 'हमने आपके पास के 1 सेलर को बता दिया है।',
      zero: 'आपके इलाके में सेलर्स जुड़ते ही हम उन्हें बता देंगे।',
    );
    return '$_temp0';
  }

  @override
  String postBlockedCategory(String category, String reason) {
    return 'इस app में $category के लिए रिक्वेस्ट नहीं ली जा सकती। $reason';
  }

  @override
  String get postBlockedReason => 'यह कैटेगरी नियमों के दायरे में है और यहां इसकी अनुमति नहीं है।';

  @override
  String get postRestrictedNotice => 'इस कैटेगरी में सिर्फ़ लाइसेंस वाले सेलर्स ही कोटेशन भेज सकते हैं।';

  @override
  String get postRateLimited => 'आज की नई रिक्वेस्ट की सीमा पूरी हो गई है। कल फिर कोशिश करें।';

  @override
  String get postDuplicate => 'आप पिछले 24 घंटों में यह रिक्वेस्ट पहले ही पोस्ट कर चुके हैं।';

  @override
  String get postDescribeRequired => 'सेलर्स को बताइए आपको क्या चाहिए';

  @override
  String get postCategoryRequired => 'कैटेगरी चुनें';

  @override
  String get postLocationRequired => 'लोकेशन जोड़ें';

  @override
  String postCodeInvalid(String codeLabel) {
    return 'सही $codeLabel डालें';
  }

  @override
  String get postalCodeLabelIndia => 'पिन कोड';

  @override
  String get postalCodeLabelUsa => 'ZIP कोड';

  @override
  String get requestsOpen => 'खुली';

  @override
  String get requestsAwarded => 'तय हुई';

  @override
  String get requestsPast => 'पुरानी';

  @override
  String get requestsEmptyOpen => 'कोई खुली रिक्वेस्ट नहीं है। एक पोस्ट करें और आस-पास की दुकानों से कोटेशन पाएं।';

  @override
  String get requestsEmptyAwarded => 'जिन रिक्वेस्ट पर आपने कोटेशन स्वीकार किया है, वे यहां दिखेंगी।';

  @override
  String get requestsEmptyPast => 'खत्म हुई और रद्द की गई रिक्वेस्ट यहां दिखेंगी।';

  @override
  String quotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कोटेशन',
      one: '1 कोटेशन',
      zero: 'अभी कोई कोटेशन नहीं',
    );
    return '$_temp0';
  }

  @override
  String quotesOfMax(int count, int max) {
    return '$max में से $count कोटेशन';
  }

  @override
  String closesIn(String time) {
    return '$time में बंद होगी';
  }

  @override
  String get closed => 'बंद';

  @override
  String get statusOpen => 'खुली';

  @override
  String get statusAwarded => 'तय हुई';

  @override
  String get statusClosed => 'बंद';

  @override
  String get statusExpired => 'समय खत्म';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get noQuotesYet => 'अभी कोई कोटेशन नहीं आया। सेलर्स आमतौर पर 2 घंटे में जवाब देते हैं।';

  @override
  String get cancelRequest => 'रिक्वेस्ट रद्द करें';

  @override
  String get cancelRequestConfirm => 'यह रिक्वेस्ट रद्द करें? इसके बाद सेलर्स कोटेशन नहीं भेज पाएंगे।';

  @override
  String get shareRequest => 'रिक्वेस्ट शेयर करें';

  @override
  String get shareRequestWhatsapp => 'WhatsApp पर दोस्तों से पूछें';

  @override
  String shareRequestText(String link) {
    return 'मुझे कौन-सा चुनना चाहिए? $link';
  }

  @override
  String get compare => 'तुलना करें';

  @override
  String get compareSelect => 'तुलना के लिए 3 तक कोटेशन चुनें';

  @override
  String get sortBy => 'इसके हिसाब से लगाएं';

  @override
  String get sortPrice => 'दाम';

  @override
  String get sortRating => 'रेटिंग';

  @override
  String get sortDelivery => 'डिलीवरी की तारीख';

  @override
  String get sortDistance => 'दूरी';

  @override
  String get quoteTotal => 'कुल';

  @override
  String get quoteSubtotal => 'उप-योग';

  @override
  String get quoteTax => 'टैक्स';

  @override
  String get quoteDelivery => 'डिलीवरी / इंस्टॉलेशन';

  @override
  String get quoteFreeDelivery => 'मुफ़्त';

  @override
  String get quoteOffered => 'ऑफ़र किया गया';

  @override
  String get quoteDeliveryDate => 'डिलीवरी की तारीख';

  @override
  String get quoteWarranty => 'वारंटी';

  @override
  String quoteValidUntil(String date) {
    return '$date तक मान्य';
  }

  @override
  String get quoteNotes => 'नोट्स';

  @override
  String quoteResponseTime(String time) {
    return '$time में जवाब दिया';
  }

  @override
  String get quoteVerified => 'वेरिफ़ाइड';

  @override
  String get quoteFoundingPartner => 'फ़ाउंडिंग पार्टनर';

  @override
  String get quoteNew => 'नया';

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
    return 'सेल्स टैक्स $rate%';
  }

  @override
  String get taxIncludedNote => 'दामों में GST शामिल है';

  @override
  String get salesTaxNote => 'सेल्स टैक्स लग सकता है';

  @override
  String get accept => 'स्वीकार करें';

  @override
  String get decline => 'मना करें';

  @override
  String get shortlist => 'शॉर्टलिस्ट करें';

  @override
  String get shortlisted => 'शॉर्टलिस्ट किया';

  @override
  String get counterOffer => 'कम दाम के लिए पूछें';

  @override
  String get counterOfferTitle => 'नया कोटेशन मांगें';

  @override
  String get counterOfferTarget => 'आपका पसंदीदा दाम';

  @override
  String get counterOfferNote => 'सेलर के लिए मैसेज';

  @override
  String get counterOfferSent => 'भेज दिया। सेलर कोटेशन बदल सकता है।';

  @override
  String counterOfferFrom(String price) {
    return 'खरीदार ने $price मांगा';
  }

  @override
  String get acceptConfirmTitle => 'यह कोटेशन स्वीकार करें?';

  @override
  String acceptConfirmBody(String seller) {
    return '$seller को आपका संपर्क और पता मिल जाएगा। बाकी सेलर्स को विनम्रता से बता दिया जाएगा कि आपने दूसरा ऑफ़र चुना है।';
  }

  @override
  String get acceptedTitle => 'कोटेशन स्वीकार हो गया';

  @override
  String acceptedBody(String seller) {
    return '$seller को बता दिया गया है। अब आप उनसे कॉल या चैट कर सकते हैं।';
  }

  @override
  String get declineTitle => 'कोटेशन मना करें';

  @override
  String get declineReason => 'वजह (वैकल्पिक, सेलर को दिखेगी)';

  @override
  String get declineReasonPrice => 'दाम बहुत ज़्यादा है';

  @override
  String get declineReasonDelivery => 'डिलीवरी बहुत देर से है';

  @override
  String get declineReasonOther => 'दूसरा ऑफ़र चुना';

  @override
  String get quoteStatusSent => 'भेजा गया';

  @override
  String get quoteStatusRevised => 'बदला गया';

  @override
  String get quoteStatusShortlisted => 'शॉर्टलिस्ट किया';

  @override
  String get quoteStatusDeclined => 'मना किया';

  @override
  String get quoteStatusAccepted => 'स्वीकार किया';

  @override
  String get quoteStatusWithdrawn => 'वापस लिया';

  @override
  String get quoteStatusExpired => 'समय खत्म';

  @override
  String get orderTitle => 'ऑर्डर';

  @override
  String get ordersTitle => 'ऑर्डर';

  @override
  String get orderTimeline => 'प्रगति';

  @override
  String get orderStatusAccepted => 'स्वीकार किया';

  @override
  String get orderStatusScheduled => 'समय तय';

  @override
  String get orderStatusDispatched => 'भेज दिया गया';

  @override
  String get orderStatusDelivered => 'डिलीवर हो गया';

  @override
  String get orderStatusCompleted => 'पूरा हुआ';

  @override
  String get orderStatusCancelled => 'रद्द';

  @override
  String orderMarkAs(String status) {
    return '$status मार्क करें';
  }

  @override
  String get orderContact => 'संपर्क';

  @override
  String get orderAddress => 'पता';

  @override
  String get orderPayment => 'पेमेंट';

  @override
  String get orderPaymentOffPlatform => 'सेलर को सीधे पेमेंट करें। अपने रिकॉर्ड के लिए इसे यहां दर्ज करें।';

  @override
  String get orderRecordPayment => 'पेमेंट दर्ज करें';

  @override
  String orderPaymentRecorded(String amount, String method) {
    return '$method से $amount का पेमेंट हुआ';
  }

  @override
  String get paymentMethodUpi => 'UPI';

  @override
  String get paymentMethodCash => 'कैश';

  @override
  String get paymentMethodCard => 'कार्ड';

  @override
  String get paymentMethodBankTransfer => 'बैंक ट्रांसफ़र';

  @override
  String get paymentMethodSellerLink => 'सेलर का पेमेंट लिंक';

  @override
  String get paymentMethodZelle => 'Zelle';

  @override
  String get paymentMethodCheck => 'चेक';

  @override
  String get rateSeller => 'सेलर को रेटिंग दें';

  @override
  String get rateBuyer => 'खरीदार को रेटिंग दें';

  @override
  String get reviewTitle => 'आपका अनुभव कैसा रहा?';

  @override
  String get reviewTextHint => 'दूसरों को अपने अनुभव के बारे में बताएं';

  @override
  String get reviewSubmit => 'रिव्यू भेजें';

  @override
  String get reviewThanks => 'आपके रिव्यू के लिए धन्यवाद!';

  @override
  String get reviewTagOnTime => 'समय पर';

  @override
  String get reviewTagGoodPrice => 'अच्छा दाम';

  @override
  String get reviewTagProfessional => 'प्रोफ़ेशनल';

  @override
  String get reviewTagQuality => 'बढ़िया क्वालिटी';

  @override
  String get reviewTagResponsive => 'जल्दी जवाब';

  @override
  String get reviewReply => 'सबके सामने जवाब दें';

  @override
  String get reviewSellerReply => 'सेलर का जवाब';

  @override
  String get reviewsTitle => 'रिव्यू';

  @override
  String get reviewsEmpty => 'अभी तक कोई रिव्यू नहीं।';

  @override
  String get chatsTitle => 'चैट';

  @override
  String get chatsEmpty => 'आपकी रिक्वेस्ट के बारे में सेलर्स के साथ चैट यहां दिखेंगी।';

  @override
  String get chatHint => 'मैसेज';

  @override
  String get chatContactWarning => 'आपकी सुरक्षा के लिए, कोटेशन स्वीकार करने तक संपर्क की बातें app में ही रखें।';

  @override
  String chatAboutRequest(String title) {
    return 'इसके बारे में: $title';
  }

  @override
  String get chatRead => 'पढ़ लिया';

  @override
  String get chatTyping => 'टाइप कर रहे हैं…';

  @override
  String get chatFailed => 'नहीं भेजा गया। दोबारा भेजने के लिए टैप करें।';

  @override
  String get chatPhoto => 'फ़ोटो';

  @override
  String get notificationsTitle => 'नोटिफ़िकेशन';

  @override
  String get notificationsEmpty => 'कोई नया नोटिफ़िकेशन नहीं है।';

  @override
  String get markAllRead => 'सभी को पढ़ा हुआ मार्क करें';

  @override
  String notifNewQuote(String seller) {
    return '$seller से नया कोटेशन';
  }

  @override
  String get notifQuoteRevised => 'एक सेलर ने अपना कोटेशन बदला';

  @override
  String get notifMessage => 'नया मैसेज';

  @override
  String notifNewRequest(String title) {
    return 'नई रिक्वेस्ट: $title';
  }

  @override
  String get notifQuoteAccepted => 'आपका कोटेशन स्वीकार हो गया!';

  @override
  String get notifQuoteDeclined => 'एक खरीदार ने दूसरा ऑफ़र चुना';

  @override
  String get notifQuoteShortlisted => 'एक खरीदार ने आपका कोटेशन शॉर्टलिस्ट किया';

  @override
  String get notifCounterOffer => 'एक खरीदार ने कम दाम के लिए पूछा';

  @override
  String get notifOrderStatus => 'ऑर्डर अपडेट';

  @override
  String get notifGeneric => 'अपडेट';

  @override
  String get sellerOnboardingTitle => 'अपना बिज़नेस सेट करें';

  @override
  String get sellerStepBusiness => 'बिज़नेस';

  @override
  String get sellerStepCategories => 'आप क्या बेचते हैं';

  @override
  String get sellerStepArea => 'सर्विस एरिया';

  @override
  String get sellerStepNotify => 'अलर्ट';

  @override
  String get businessName => 'बिज़नेस का नाम';

  @override
  String get businessDescription => 'आपके बिज़नेस के बारे में';

  @override
  String get yearsInBusiness => 'बिज़नेस में कितने साल';

  @override
  String get brandsCarried => 'आपके पास कौन-से ब्रांड हैं (कॉमा से अलग करें)';

  @override
  String get addLogo => 'लोगो जोड़ें';

  @override
  String get addShopPhotos => 'दुकान की फ़ोटो जोड़ें';

  @override
  String get selectCategories => 'वे कैटेगरी चुनें जिनके लिए आप कोटेशन दे सकते हैं';

  @override
  String get categoriesRequired => 'कम से कम एक कैटेगरी चुनें';

  @override
  String get areaRadius => 'मेरी दुकान के आस-पास की दूरी';

  @override
  String areaCodes(String codeLabel) {
    return '$codeLabel की लिस्ट';
  }

  @override
  String get areaNationwide => 'पूरे देश में डिलीवरी';

  @override
  String radiusValue(int value) {
    return '$value किमी';
  }

  @override
  String radiusValueMiles(int value) {
    return '$value मील';
  }

  @override
  String get shopLocation => 'दुकान की लोकेशन';

  @override
  String serviceCodesHint(String example) {
    return 'कॉमा से अलग करें, जैसे $example';
  }

  @override
  String get sellerState => 'राज्य';

  @override
  String get notifyInstant => 'तुरंत अलर्ट';

  @override
  String get notifyHourly => 'हर घंटे का सारांश';

  @override
  String get notifyQuiet => 'शांत समय';

  @override
  String quietHoursRange(String start, String end) {
    return '$start से $end तक शांत';
  }

  @override
  String get sellerProfileSaved => 'आपका बिज़नेस लाइव हो गया है। नई लीड आपकी फ़ीड में दिखेंगी।';

  @override
  String foundingPartnerBadge(String date) {
    return 'फ़ाउंडिंग पार्टनर: $date तक मुफ़्त';
  }

  @override
  String get verificationTitle => 'वेरिफ़ाइड बनें';

  @override
  String get verificationBody => 'वेरिफ़ाइड सेलर्स को बैज मिलता है और वे नई रिक्वेस्ट सबसे पहले देखते हैं।';

  @override
  String get verificationStatusNone => 'वेरिफ़ाइड नहीं';

  @override
  String get verificationStatusPending => 'जांच चल रही है';

  @override
  String get verificationStatusVerified => 'वेरिफ़ाइड';

  @override
  String verificationStatusRejected(String reason) {
    return 'अस्वीकार: $reason';
  }

  @override
  String get docGstin => 'GSTIN';

  @override
  String get docUdyam => 'उद्यम रजिस्ट्रेशन नंबर';

  @override
  String get docShopPhoto => 'दुकान की फ़ोटो';

  @override
  String get docEin => 'EIN';

  @override
  String get docStateLicence => 'राज्य बिज़नेस लाइसेंस नंबर';

  @override
  String get docBusinessAddress => 'बिज़नेस का पता';

  @override
  String get docWebsite => 'वेबसाइट';

  @override
  String get docInvalid => 'यह नंबर सही नहीं लग रहा। जांचकर फिर से कोशिश करें।';

  @override
  String get uploadFile => 'अपलोड करें';

  @override
  String get submitForReview => 'जांच के लिए भेजें';

  @override
  String get submittedForReview => 'भेज दिया। हम जल्द ही इसकी जांच करेंगे।';

  @override
  String get licencesTitle => 'लाइसेंस';

  @override
  String get licencesBody => 'पाबंदी वाली कैटेगरी में कोटेशन देने के लिए ज़रूरी।';

  @override
  String get addLicence => 'लाइसेंस जोड़ें';

  @override
  String get licenceType => 'लाइसेंस का प्रकार';

  @override
  String get licenceNumber => 'लाइसेंस नंबर';

  @override
  String get licenceIssuer => 'जारी करने वाली संस्था';

  @override
  String get licenceExpiry => 'खत्म होने की तारीख';

  @override
  String get leadsTitle => 'लीड';

  @override
  String get leadsEmpty => 'अभी कोई मिलती-जुलती रिक्वेस्ट नहीं है। आपके पास के खरीदार पोस्ट करेंगे तो हम आपको बताएंगे।';

  @override
  String get leadsNoSellerProfile => 'लीड पाने के लिए अपनी बिज़नेस प्रोफ़ाइल सेट करें।';

  @override
  String get leadFilters => 'फ़िल्टर';

  @override
  String get leadFilterCategory => 'कैटेगरी';

  @override
  String get leadFilterDistance => 'दूरी के अंदर';

  @override
  String get leadFilterAny => 'कोई भी';

  @override
  String leadAway(String distance) {
    return '$distance दूर';
  }

  @override
  String leadQuotesSent(int count, int max) {
    return '$max में से $count कोटेशन भेजे गए';
  }

  @override
  String get leadFull => 'कोटेशन की सीमा पूरी';

  @override
  String leadNeededBy(String date) {
    return '$date तक चाहिए';
  }

  @override
  String leadBudget(String range) {
    return 'बजट $range';
  }

  @override
  String get leadBudgetHidden => 'बजट नहीं बताया गया';

  @override
  String get leadDismiss => 'दिलचस्पी नहीं';

  @override
  String get leadSendQuote => 'कोटेशन भेजें';

  @override
  String get leadAlreadyQuoted => 'आप कोटेशन भेज चुके हैं';

  @override
  String get leadPriorityNote => 'वेरिफ़ाइड सेलर्स नई रिक्वेस्ट सबसे पहले देखते हैं।';

  @override
  String get leadLocalityOnly => 'खरीदार के आपका कोटेशन स्वीकार करने के बाद पूरा पता दिखेगा।';

  @override
  String get quoteFormTitle => 'आपका कोटेशन';

  @override
  String get quoteItem => 'सामान / सर्विस';

  @override
  String get quoteQty => 'मात्रा';

  @override
  String get quoteUnitPrice => 'एक यूनिट का दाम';

  @override
  String get quoteAddLine => 'लाइन जोड़ें';

  @override
  String get quoteTaxRate => 'GST दर';

  @override
  String get quoteSalesTaxRate => 'सेल्स टैक्स दर (%)';

  @override
  String get quoteBrandModel => 'ऑफ़र किया गया ब्रांड / मॉडल';

  @override
  String get quoteValidity => 'कोटेशन कितने दिन मान्य';

  @override
  String quoteValidityDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count दिन', one: '1 दिन');
    return '$_temp0';
  }

  @override
  String get quoteAttachments => 'अटैचमेंट';

  @override
  String get quoteSaveTemplate => 'टेम्पलेट के रूप में सेव करें';

  @override
  String get quoteUseTemplate => 'टेम्पलेट इस्तेमाल करें';

  @override
  String get quoteTemplateName => 'टेम्पलेट का नाम';

  @override
  String get quoteSubmit => 'कोटेशन भेजें';

  @override
  String get quoteRevise => 'बदला हुआ कोटेशन भेजें';

  @override
  String get quoteWithdraw => 'कोटेशन वापस लें';

  @override
  String get quoteSent => 'कोटेशन भेज दिया';

  @override
  String get quotePriceRequired => 'दाम डालें';

  @override
  String get quoteCapReached => 'इस रिक्वेस्ट पर पहले से ही ज़्यादा से ज़्यादा कोटेशन आ चुके हैं।';

  @override
  String get quoteRequestClosed => 'यह रिक्वेस्ट अब खुली नहीं है।';

  @override
  String get quoteNotAllowed => 'आप इस रिक्वेस्ट पर कोटेशन नहीं भेज सकते।';

  @override
  String get quoteLicenceRequired => 'इस कैटेगरी के लिए मान्य लाइसेंस ज़रूरी है।';

  @override
  String get quoteNoCredits => 'इस महीने के आपके मुफ़्त कोटेशन खत्म हो गए। प्लान देखें।';

  @override
  String get quotePriorityWindow => 'नई रिक्वेस्ट पर पहले 15 मिनट सिर्फ़ वेरिफ़ाइड सेलर्स के लिए होते हैं।';

  @override
  String get quoteAlreadySent => 'आप इस रिक्वेस्ट पर पहले ही कोटेशन भेज चुके हैं।';

  @override
  String get templatesTitle => 'कोटेशन टेम्पलेट';

  @override
  String get templatesEmpty => 'किसी कोटेशन को दोबारा इस्तेमाल करने के लिए उसे टेम्पलेट के रूप में सेव करें।';

  @override
  String get myQuotesActive => 'चालू';

  @override
  String get myQuotesWon => 'जीते';

  @override
  String get myQuotesLost => 'हारे';

  @override
  String get myQuotesEmpty => 'यहां अभी कोई कोटेशन नहीं है।';

  @override
  String get dashboardTitle => 'डैशबोर्ड';

  @override
  String get dashActive => 'चालू कोटेशन';

  @override
  String get dashWon => 'जीते';

  @override
  String get dashWinRate => 'जीत की दर';

  @override
  String get dashResponse => 'औसत जवाब का समय';

  @override
  String get dashRevenue => 'दर्ज की गई कमाई';

  @override
  String get dashRating => 'रेटिंग';

  @override
  String get dashQuotesThisMonth => 'इस महीने के कोटेशन';

  @override
  String minutesShort(int count) {
    return '$count मिनट';
  }

  @override
  String hoursShort(int count) {
    return '$count घंटे';
  }

  @override
  String get planTitle => 'प्लान और बिलिंग';

  @override
  String get planFreeLaunch => 'लॉन्च के दौरान सब कुछ मुफ़्त है।';

  @override
  String planFoundingPartner(String date) {
    return 'फ़ाउंडिंग पार्टनर होने के नाते आपको $date तक मुफ़्त एक्सेस मिलता रहेगा।';
  }

  @override
  String planCurrent(String tier) {
    return 'मौजूदा प्लान: $tier';
  }

  @override
  String planFreeTier(int count) {
    return 'मुफ़्त: हर महीने $count कोटेशन';
  }

  @override
  String get planMonthly => 'मासिक';

  @override
  String get planAnnual => 'सालाना';

  @override
  String get planSubscribe => 'सब्सक्राइब करें';

  @override
  String get planCredits => 'कोटेशन क्रेडिट';

  @override
  String planCreditsBalance(int count) {
    return '$count क्रेडिट बाकी';
  }

  @override
  String get planBuyCredits => 'क्रेडिट खरीदें';

  @override
  String get planRestore => 'पिछली खरीदारी वापस लाएं';

  @override
  String get planManage => 'सब्सक्रिप्शन मैनेज करें';

  @override
  String get planFixPayment => 'आपके पेमेंट में कोई समस्या है। अपना प्लान जारी रखने के लिए इसे अपडेट करें।';

  @override
  String planRenewal(String store) {
    return 'अपने-आप रिन्यू होता है। $store में कभी भी रद्द करें।';
  }

  @override
  String get planBuyOnWeb => 'हमारी वेबसाइट पर खरीदें';

  @override
  String get planNotAvailable => 'प्लान अभी app में उपलब्ध नहीं हैं।';

  @override
  String get sellerProfileTitle => 'बिज़नेस प्रोफ़ाइल';

  @override
  String get sellerViewPublic => 'खरीदारों को कैसा दिखता है, देखें';

  @override
  String get sellerShareShop => 'मेरी दुकान शेयर करें';

  @override
  String sellerShareText(String shop, String app, String link) {
    return '$app पर $shop और दूसरी आस-पास की दुकानों से कोटेशन पाएं: $link';
  }

  @override
  String sellerYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'बिज़नेस में $count साल',
      one: 'बिज़नेस में 1 साल',
    );
    return '$_temp0';
  }

  @override
  String sellerRating(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String sellerResponds(String time) {
    return 'आमतौर पर $time में जवाब देते हैं';
  }

  @override
  String get accountTitle => 'अकाउंट';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsNotifications => 'नोटिफ़िकेशन';

  @override
  String get settingsPrivacy => 'प्राइवेसी';

  @override
  String get settingsHelp => 'मदद और FAQ';

  @override
  String get settingsLegal => 'कानूनी जानकारी';

  @override
  String get settingsLicenses => 'ओपन-सोर्स लाइसेंस';

  @override
  String get settingsSignOut => 'साइन आउट करें';

  @override
  String get settingsDeleteAccount => 'अकाउंट डिलीट करें';

  @override
  String get settingsBlocked => 'ब्लॉक किए गए यूज़र';

  @override
  String settingsVersion(String version) {
    return 'वर्शन $version';
  }

  @override
  String get settingsTheme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get notifPrefNewQuotes => 'नए कोटेशन';

  @override
  String get notifPrefMessages => 'मैसेज';

  @override
  String get notifPrefLeads => 'नई लीड';

  @override
  String get notifPrefMarketing => 'ऑफ़र और टिप्स';

  @override
  String get privacyAnalytics => 'बिना पहचान वाला इस्तेमाल का डेटा शेयर करें';

  @override
  String get privacyDoNotSell => 'मेरी निजी जानकारी न बेचें और न शेयर करें';

  @override
  String get privacyDownload => 'मेरे डेटा की कॉपी मांगें';

  @override
  String get deleteTitle => 'अपना अकाउंट डिलीट करें';

  @override
  String get deleteBody =>
      'इससे आपकी प्रोफ़ाइल, रिक्वेस्ट, कोटेशन, चैट और फ़ोटो हमेशा के लिए डिलीट हो जाएंगी। कुछ रिकॉर्ड, जैसे पूरे हो चुके ऑर्डर और टैक्स इनवॉइस, कानून के अनुसार रखे जाते हैं और फिर डिलीट कर दिए जाते हैं।';

  @override
  String get deleteConfirmLabel => 'पुष्टि के लिए DELETE टाइप करें';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String get deleteButton => 'मेरा अकाउंट डिलीट करें';

  @override
  String get deleteReauth => 'आपकी सुरक्षा के लिए, डिलीट करने से पहले फिर से साइन इन करें।';

  @override
  String get deleteDone => 'आपका अकाउंट डिलीट कर दिया गया है।';

  @override
  String get helpTitle => 'मदद और FAQ';

  @override
  String get faqQ1 => 'क्या खरीदारों के लिए यह मुफ़्त है?';

  @override
  String get faqA1 => 'हां। रिक्वेस्ट पोस्ट करना और कोटेशन पाना हमेशा मुफ़्त है।';

  @override
  String get faqQ2 => 'मैं सेलर को पेमेंट कैसे करूं?';

  @override
  String get faqA2 =>
      'आप सेलर को सीधे पेमेंट करते हैं, उन तरीकों से जो वे लेते हैं। अपने रिकॉर्ड के लिए ऑर्डर में पेमेंट दर्ज करें।';

  @override
  String get faqQ3 => 'सेलर को मेरा फ़ोन नंबर और पता कब दिखता है?';

  @override
  String get faqA3 => 'सिर्फ़ तब, जब आप उनका कोटेशन स्वीकार करते हैं। उससे पहले आप app में चैट कर सकते हैं।';

  @override
  String get faqQ4 => 'सेलर्स वेरिफ़ाइड कैसे होते हैं?';

  @override
  String get faqA4 => 'वे बिज़नेस के दस्तावेज़ भेजते हैं, जिनकी हमारी टीम जांच करती है।';

  @override
  String get faqQ5 => 'मैं किसी समस्या की रिपोर्ट कैसे करूं?';

  @override
  String get faqA5 => 'किसी भी चैट, कोटेशन या प्रोफ़ाइल पर \'रिपोर्ट करें\' दबाएं, या सपोर्ट से संपर्क करें।';

  @override
  String get contactSupport => 'सपोर्ट से संपर्क करें';

  @override
  String get legalTitle => 'कानूनी जानकारी';

  @override
  String get reportTitle => 'रिपोर्ट करें';

  @override
  String get reportReasonSpam => 'स्पैम या धोखाधड़ी';

  @override
  String get reportReasonAbuse => 'गाली-गलौज या आपत्तिजनक';

  @override
  String get reportReasonFake => 'नकली बिज़नेस या रिक्वेस्ट';

  @override
  String get reportReasonProhibited => 'प्रतिबंधित सामान';

  @override
  String get reportReasonOther => 'कुछ और';

  @override
  String get reportDetails => 'जानकारी (वैकल्पिक)';

  @override
  String get reportSent => 'धन्यवाद। हमारी टीम इसकी जांच करेगी।';

  @override
  String blockConfirm(String name) {
    return '$name को ब्लॉक करें? आपको उनके कोटेशन या मैसेज नहीं दिखेंगे।';
  }

  @override
  String get blocked => 'ब्लॉक किया गया';

  @override
  String inAppReviewAsk(String app) {
    return 'क्या आपको $app पसंद आ रहा है?';
  }

  @override
  String get updateRequired => 'आगे बढ़ने के लिए कृपया app अपडेट करें।';

  @override
  String get permissionLocationRationale =>
      'हम आपके पास के सेलर्स ढूंढने के लिए आपकी लोकेशन का इस्तेमाल करते हैं। कोटेशन स्वीकार करने तक सिर्फ़ आपका इलाका ही दिखाया जाता है।';

  @override
  String get permissionNotificationsRationale =>
      'नए कोटेशन और मैसेज की जानकारी तुरंत पाने के लिए नोटिफ़िकेशन चालू करें।';

  @override
  String get permissionMicRationale => 'अपनी रिक्वेस्ट बोलकर बताने के लिए माइक्रोफ़ोन की अनुमति दें।';

  @override
  String get allow => 'अनुमति दें';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get accountBlockedTitle => 'अकाउंट उपलब्ध नहीं है';

  @override
  String accountSuspendedBody(String date) {
    return 'आपका अकाउंट $date तक निलंबित है। आप हमारी नीतियाँ पढ़ सकते हैं या सपोर्ट से संपर्क कर सकते हैं।';
  }

  @override
  String get accountSuspendedBodyNoDate =>
      'आपका अकाउंट निलंबित है। आप हमारी नीतियाँ पढ़ सकते हैं या सपोर्ट से संपर्क कर सकते हैं।';

  @override
  String get accountBannedBody =>
      'नियम तोड़ने के कारण आपका अकाउंट बंद कर दिया गया है। अगर आपको लगता है कि यह गलती है, तो सपोर्ट से संपर्क करें।';

  @override
  String get accountDeletedBody => 'यह अकाउंट डिलीट कर दिया गया है।';
}

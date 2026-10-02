import '../../../core/config/admin_country.dart';
import 'outreach_models.dart';

/// One message the admin is about to send (email or opted-in WhatsApp).
class OutreachMessage {
  const OutreachMessage({
    required this.channel,
    required this.step,
    required this.subject,
    required this.body,
    required this.footer,
    this.variantIndex = 0,
    this.categoryId,
    this.categoryName,
    this.inboxId,
    this.campaignId,
    this.hasAttachment = false,
    this.whatsappTemplate,
    this.confirmedByAdmin = false,
  });

  /// `email` or `whatsapp`.
  final String channel;

  /// 1..3 within the sequence.
  final int step;
  final String subject;

  /// The part the admin wrote / the template rendered (content rules apply).
  final String body;

  /// Identity + opt-out footer added by [OutreachComposer.footer] (rules 5, 8).
  final String footer;
  final int variantIndex;
  final int? categoryId;
  final String? categoryName;
  final String? inboxId;
  final String? campaignId;
  final bool hasAttachment;

  /// Meta-approved WhatsApp template name (rule 9).
  final String? whatsappTemplate;

  /// Sending is never automatic: an admin confirms every send.
  final bool confirmedByAdmin;

  OutreachMessage copyWith({
    String? subject,
    String? body,
    String? footer,
    bool? hasAttachment,
    bool? confirmedByAdmin,
    String? inboxId,
    String? whatsappTemplate,
    int? step,
    int? categoryId,
    String? categoryName,
  }) =>
      OutreachMessage(
        channel: channel,
        step: step ?? this.step,
        subject: subject ?? this.subject,
        body: body ?? this.body,
        footer: footer ?? this.footer,
        variantIndex: variantIndex,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        inboxId: inboxId ?? this.inboxId,
        campaignId: campaignId,
        hasAttachment: hasAttachment ?? this.hasAttachment,
        whatsappTemplate: whatsappTemplate ?? this.whatsappTemplate,
        confirmedByAdmin: confirmedByAdmin ?? this.confirmedByAdmin,
      );
}

/// Renders sequence templates for one lead. Placeholders:
/// `{{business_name}} {{city}} {{category}} {{rating}} {{signup_link}}
/// {{brochure_link}} {{founding_until}} {{sender_name}}`.
class OutreachComposer {
  const OutreachComposer(this.config);
  final AdminCountryConfig config;

  /// Template rotation (rule 4): the same lead always gets the same variant
  /// for a step, different leads get different ones.
  int variantFor(OutreachLead lead, int step, int variants) {
    if (variants <= 1) return 0;
    var h = step;
    for (final c in lead.id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h % variants;
  }

  String render(
    String template,
    OutreachLead lead, {
    required String categoryName,
    required String senderName,
    String? brochureLink,
    String? foundingUntil,
    String? campaign,
  }) {
    final signup = config.signupUrl(
      source: 'outreach',
      medium: 'email',
      campaign: campaign,
      city: lead.city,
      category: categoryName,
      token: lead.signupToken,
    );
    final values = <String, String?>{
      'business_name': lead.businessName,
      'city': lead.city,
      'category': categoryName,
      'rating': lead.rating?.toStringAsFixed(1),
      'signup_link': signup.toString(),
      'brochure_link': brochureLink,
      'founding_until': foundingUntil,
      'sender_name': senderName,
    };
    return template.replaceAllMapped(RegExp(r'\{\{\s*([a-z_]+)\s*\}\}'), (m) {
      final v = values[m.group(1)];
      return (v == null || v.isEmpty) ? m.group(0)! : v;
    });
  }

  /// Footer with honest identity (rule 8) and opt-out (rule 5). The Edge
  /// Function also adds one-click List-Unsubscribe headers.
  String footer({
    required String senderName,
    required String businessAddress,
    String? unsubscribeToken,
  }) {
    final unsub = unsubscribeToken == null
        ? null
        : Uri.https(config.webDomain, '/u/$unsubscribeToken').toString();
    return [
      config.optOutLine,
      '--',
      senderName,
      config.legalEntity,
      businessAddress,
      '${config.websiteUrl} | Privacy: ${config.privacyUrl}',
      if (unsub != null) 'Unsubscribe: $unsub',
    ].join('\n');
  }

  /// Pre-filled text for the manual 1:1 WhatsApp first contact (21.3).
  Uri whatsAppLink(OutreachLead lead, String text) {
    final digits = (lead.phone ?? '').replaceAll(RegExp(r'\D'), '');
    return Uri.https('wa.me', '/$digits', {'text': text});
  }
}

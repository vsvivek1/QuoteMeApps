import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/config/admin_country.dart';

/// Output formats stored in `brochures.format`.
enum BrochureFormat {
  /// A4 printable brochure.
  pdf,

  /// A5 one-page flyer for the field kit and email (21.3, 21.4).
  onepager,

  /// 1080x1350 image for WhatsApp / Instagram (rasterised from the PDF).
  image;

  PdfPageFormat get pageFormat => switch (this) {
        BrochureFormat.pdf => PdfPageFormat.a4,
        BrochureFormat.onepager => PdfPageFormat.a5,
        BrochureFormat.image => const PdfPageFormat(1080, 1350),
      };
}

class BrochureSpec {
  const BrochureSpec({
    required this.config,
    required this.city,
    this.state,
    required this.categoryName,
    required this.language,
    required this.foundingUntil,
    required this.signupUrl,
    required this.format,
    this.logoPng,
  });

  final AdminCountryConfig config;
  final String city;
  final String? state;
  final String categoryName;
  final String language;

  /// Formatted end date of the founding-partner offer (never "for life").
  final String foundingUntil;
  final Uri signupUrl;
  final BrochureFormat format;
  final Uint8List? logoPng;
}

/// Brochure copy per language. Honest claims only: no buyer-volume numbers,
/// no "free for life", the offer always has an end date.
class BrochureCopy {
  const BrochureCopy._(this._m);
  final Map<String, String> _m;

  static BrochureCopy of(String lang) => BrochureCopy._(_copy[lang] ?? _copy['en']!);

  String get(String key, [Map<String, String> args = const {}]) {
    var s = _m[key] ?? _copy['en']![key]!;
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  static const _copy = {
    'en': {
      'headline': 'Get {category} requests from {city}',
      'tagline': 'On {app}, people post what they need. Local businesses like yours send them a quote.',
      'how': 'How it works',
      'how1': 'Buyers in {city} post a request for {category}.',
      'how2': 'You see matching requests and send a quote in a minute.',
      'how3': 'Chat with the buyer, win the job, collect reviews.',
      'offer': 'Founding partner offer',
      'offerBody': 'Free for founding partners until {date}. No card needed to join.',
      'join': 'Join in 3 steps',
      'join1': 'Scan the QR code',
      'join2': 'Add your business and what you sell',
      'join3': 'Start getting matching requests',
      'scan': 'Scan to set up your shop',
      'contact': 'Questions? {web}',
      'legal': '{entity} · Privacy: {privacy}',
    },
    'es': {
      'headline': 'Reciba solicitudes de {category} en {city}',
      'tagline': 'En {app}, las personas publican lo que necesitan. Negocios locales como el suyo les envían una cotización.',
      'how': 'Cómo funciona',
      'how1': 'Compradores en {city} publican una solicitud de {category}.',
      'how2': 'Usted ve solicitudes que coinciden y envía una cotización en un minuto.',
      'how3': 'Converse con el comprador, gane el trabajo y reciba reseñas.',
      'offer': 'Oferta para socios fundadores',
      'offerBody': 'Gratis para socios fundadores hasta el {date}. No se necesita tarjeta.',
      'join': 'Únase en 3 pasos',
      'join1': 'Escanee el código QR',
      'join2': 'Agregue su negocio y lo que vende',
      'join3': 'Empiece a recibir solicitudes',
      'scan': 'Escanee para crear su tienda',
      'contact': '¿Preguntas? {web}',
      'legal': '{entity} · Privacidad: {privacy}',
    },
  };
}

/// Builds a branded brochure PDF with the `pdf` package (Section 21.4).
Future<Uint8List> buildBrochurePdf(BrochureSpec spec) async {
  final c = spec.config;
  final copy = BrochureCopy.of(spec.language);
  final brand = PdfColor.fromInt(c.brandPrimary.toARGB32());
  // 10 % tint of the brand colour on white (no transparency needed).
  double tint(double v) => v * 0.1 + 0.9;
  final brandLight = PdfColor(tint(brand.red), tint(brand.green), tint(brand.blue));
  final format = spec.format.pageFormat;
  final scale = format.width / PdfPageFormat.a4.width;
  double fs(double v) => v * scale;
  final args = {
    'category': spec.categoryName,
    'city': spec.city,
    'app': c.appName,
    'date': spec.foundingUntil,
    'web': c.websiteUrl.toString(),
    'entity': c.legalEntity,
    'privacy': c.privacyUrl.toString(),
  };
  final logo = spec.logoPng == null ? null : pw.MemoryImage(spec.logoPng!);
  final doc = pw.Document(title: copy.get('headline', args), author: c.legalEntity, creator: '${c.appName} admin');

  pw.Widget step(String n, String text) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: fs(8)),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            width: fs(22),
            height: fs(22),
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(color: brand, shape: pw.BoxShape.circle),
            child: pw.Text(n, style: pw.TextStyle(color: PdfColors.white, fontSize: fs(11), fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(width: fs(10)),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: fs(12)))),
        ]),
      );

  final compact = spec.format == BrochureFormat.onepager;
  doc.addPage(
    pw.Page(
      pageFormat: format,
      margin: pw.EdgeInsets.all(fs(36)),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          if (logo != null) pw.Image(logo, width: fs(44), height: fs(44)),
          if (logo != null) pw.SizedBox(width: fs(10)),
          pw.Text(c.appName, style: pw.TextStyle(fontSize: fs(20), fontWeight: pw.FontWeight.bold, color: brand)),
        ]),
        pw.SizedBox(height: fs(18)),
        pw.Text(copy.get('headline', args), style: pw.TextStyle(fontSize: fs(28), fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: fs(8)),
        pw.Text(copy.get('tagline', args), style: pw.TextStyle(fontSize: fs(13), color: PdfColors.grey800)),
        pw.SizedBox(height: fs(18)),
        if (!compact) ...[
          pw.Text(copy.get('how'), style: pw.TextStyle(fontSize: fs(15), fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: fs(8)),
          step('1', copy.get('how1', args)),
          step('2', copy.get('how2', args)),
          step('3', copy.get('how3', args)),
          pw.SizedBox(height: fs(12)),
        ],
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(fs(14)),
          decoration: pw.BoxDecoration(color: brandLight, borderRadius: pw.BorderRadius.circular(fs(10))),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(copy.get('offer'), style: pw.TextStyle(fontSize: fs(14), fontWeight: pw.FontWeight.bold, color: brand)),
            pw.SizedBox(height: fs(4)),
            pw.Text(copy.get('offerBody', args), style: pw.TextStyle(fontSize: fs(12))),
          ]),
        ),
        pw.SizedBox(height: fs(18)),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(copy.get('join'), style: pw.TextStyle(fontSize: fs(15), fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: fs(8)),
              step('1', copy.get('join1')),
              step('2', copy.get('join2')),
              step('3', copy.get('join3')),
            ]),
          ),
          pw.SizedBox(width: fs(16)),
          pw.Column(children: [
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: spec.signupUrl.toString(),
              width: fs(compact ? 150 : 130),
              height: fs(compact ? 150 : 130),
              color: PdfColors.black,
            ),
            pw.SizedBox(height: fs(6)),
            pw.Text(copy.get('scan'), style: pw.TextStyle(fontSize: fs(10))),
          ]),
        ]),
        pw.Spacer(),
        pw.Divider(color: PdfColors.grey400),
        pw.Text(copy.get('contact', args), style: pw.TextStyle(fontSize: fs(10))),
        pw.SizedBox(height: fs(2)),
        pw.Text(copy.get('legal', args), style: pw.TextStyle(fontSize: fs(9), color: PdfColors.grey700)),
      ]),
    ),
  );
  return doc.save();
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTagline => 'Dile a las tiendas lo que quieres. Recibe cotizaciones. Elige la mejor.';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get done => 'Listo';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get retry => 'Reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get send => 'Enviar';

  @override
  String get skip => 'Omitir';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get optional => 'Opcional';

  @override
  String get required => 'Obligatorio';

  @override
  String get loading => 'Cargando…';

  @override
  String get somethingWentWrong => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get offlineBanner => 'No tienes conexión. Mostrando datos guardados.';

  @override
  String get demoModeBanner => 'Modo demo: datos de ejemplo, código 123456';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get share => 'Compartir';

  @override
  String get report => 'Reportar';

  @override
  String get block => 'Bloquear';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get call => 'Llamar';

  @override
  String get chat => 'Chat';

  @override
  String get languageTitle => 'Elige tu idioma';

  @override
  String get languageSubtitle => 'Puedes cambiarlo más tarde en Configuración.';

  @override
  String get welcomeTitle => 'Recibe cotizaciones de tiendas locales';

  @override
  String get welcomeBody1 => 'Publica lo que necesitas en segundos.';

  @override
  String get welcomeBody2 => 'Tiendas y profesionales de servicios te envían sus precios.';

  @override
  String get welcomeBody3 => 'Compara, chatea y elige la mejor oferta.';

  @override
  String get signInPhone => 'Continuar con teléfono';

  @override
  String get signInGoogle => 'Continuar con Google';

  @override
  String get signInApple => 'Iniciar sesión con Apple';

  @override
  String signInLegal(String terms, String privacy) {
    return 'Al continuar, aceptas nuestros $terms y nuestra $privacy.';
  }

  @override
  String get termsLink => 'Términos del servicio';

  @override
  String get privacyLink => 'Política de privacidad';

  @override
  String get phoneTitle => 'Tu número de celular';

  @override
  String get phoneSubtitle => 'Te enviaremos un código de un solo uso por SMS.';

  @override
  String get phoneLabel => 'Número de celular';

  @override
  String get phoneInvalid => 'Ingresa un número de celular válido';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get otpTitle => 'Ingresa el código';

  @override
  String otpSubtitle(String phone) {
    return 'Enviado a $phone';
  }

  @override
  String get otpLabel => 'Código de 6 dígitos';

  @override
  String get otpInvalid => 'Ese código no funcionó. Revísalo e inténtalo de nuevo.';

  @override
  String get verify => 'Verificar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String resendIn(int seconds) {
    return 'Reenviar en $seconds s';
  }

  @override
  String get authFailed => 'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get authCancelled => 'Se canceló el inicio de sesión.';

  @override
  String get otpRateLimited => 'Demasiados intentos. Espera unos minutos.';

  @override
  String get consentTitle => 'Antes de empezar';

  @override
  String consentAccept(String terms, String privacy) {
    return 'Acepto los $terms y la $privacy';
  }

  @override
  String get consentMarketing => 'Envíenme ofertas y consejos (opcional)';

  @override
  String get consentAnalytics => 'Ayudar a mejorar la app con datos de uso anónimos (opcional)';

  @override
  String consentAge(int age) {
    return 'Tengo $age años o más';
  }

  @override
  String get profileSetupTitle => '¿Cómo te llamamos?';

  @override
  String get nameLabel => 'Tu nombre';

  @override
  String get nameRequired => 'Ingresa tu nombre';

  @override
  String get addPhoneTitle => 'Agrega tu número de celular';

  @override
  String get addPhoneBody =>
      'Los vendedores necesitan un número de teléfono verificado. Los compradores pueden agregar uno para recibir avisos por SMS.';

  @override
  String get modeBuyer => 'Comprar';

  @override
  String get modeSeller => 'Vender';

  @override
  String get switchToSelling => 'Cambiar a vender';

  @override
  String get switchToBuying => 'Cambiar a comprar';

  @override
  String get becomeSeller => 'Tengo un negocio';

  @override
  String get becomeSellerBody =>
      'Recibe clientes potenciales cerca de ti y envía cotizaciones. Gratis para socios fundadores.';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabRequests => 'Mis solicitudes';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabAccount => 'Cuenta';

  @override
  String get tabLeads => 'Clientes';

  @override
  String get tabMyQuotes => 'Mis cotizaciones';

  @override
  String get tabDashboard => 'Panel';

  @override
  String homeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeGreetingAnon => 'Hola';

  @override
  String get whatDoYouNeed => '¿Qué necesitas?';

  @override
  String get whatDoYouNeedHint => 'p. ej., refrigerador de dos puertas, entregado antes del viernes';

  @override
  String get activeRequests => 'Tus solicitudes activas';

  @override
  String get browseCategories => 'Categorías populares';

  @override
  String get howItWorks => 'Cómo funciona';

  @override
  String get noActiveRequests =>
      'Aún no has publicado nada. Dile a las tiendas locales lo que quieres y recibe cotizaciones.';

  @override
  String get postTitle => 'Nueva solicitud';

  @override
  String get postStepWhat => 'Qué';

  @override
  String get postStepDetails => 'Detalles';

  @override
  String get postStepWhere => 'Cuándo y dónde';

  @override
  String get postDescribeHint => 'Describe lo que quieres. Marca, tamaño, cantidad…';

  @override
  String get postSpeak => 'Hablar';

  @override
  String get postListening => 'Escuchando…';

  @override
  String get postSuggestedCategory => 'Categoría sugerida';

  @override
  String get postPickCategory => 'Elige una categoría';

  @override
  String get postChangeCategory => 'Cambiar';

  @override
  String get postAddPhotos => 'Agregar fotos';

  @override
  String postPhotosCount(int count) {
    return '$count/6 fotos';
  }

  @override
  String get postReferenceLink => 'Enlace de referencia (página del producto)';

  @override
  String get postBudget => 'Presupuesto';

  @override
  String get postBudgetMin => 'Desde';

  @override
  String get postBudgetMax => 'Hasta';

  @override
  String get postBudgetHidden => 'Ocultar mi presupuesto a los vendedores';

  @override
  String get postNeededBy => 'Lo necesito para';

  @override
  String get postPickDate => 'Elige una fecha';

  @override
  String get postLocation => 'Lugar de entrega o del servicio';

  @override
  String get postUseGps => 'Usar mi ubicación';

  @override
  String postPostalCode(String codeLabel) {
    return '$codeLabel';
  }

  @override
  String get postLocality => 'Zona / colonia';

  @override
  String get postFullAddress => 'Dirección completa (solo se comparte con el vendedor que aceptes)';

  @override
  String get postQuoteWindow => 'Aceptar cotizaciones durante';

  @override
  String get quoteWindow24h => '24 horas';

  @override
  String get quoteWindow48h => '48 horas';

  @override
  String get quoteWindow7d => '7 días';

  @override
  String get postWhoCanQuote => 'Quién puede cotizar';

  @override
  String get audienceLocal => 'Tiendas locales';

  @override
  String get audienceOnline => 'Vendedores en línea';

  @override
  String get audienceBoth => 'Ambos';

  @override
  String get postReview => 'Revisar y publicar';

  @override
  String get postSubmit => 'Publicar solicitud';

  @override
  String get postSuccessTitle => 'Solicitud publicada';

  @override
  String postSuccessBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Avisamos a $count vendedores cerca de ti.',
      one: 'Avisamos a 1 vendedor cerca de ti.',
      zero: 'Avisaremos a los vendedores a medida que se unan en tu zona.',
    );
    return '$_temp0';
  }

  @override
  String postBlockedCategory(String category, String reason) {
    return 'No podemos aceptar solicitudes de $category en esta app. $reason';
  }

  @override
  String get postBlockedReason => 'Esta categoría está regulada y no se permite aquí.';

  @override
  String get postRestrictedNotice => 'Solo los vendedores con licencia pueden cotizar en esta categoría.';

  @override
  String get postRateLimited => 'Llegaste al límite de solicitudes nuevas de hoy. Inténtalo mañana.';

  @override
  String get postDuplicate => 'Ya publicaste esta solicitud en las últimas 24 horas.';

  @override
  String get postDescribeRequired => 'Dile a los vendedores lo que necesitas';

  @override
  String get postCategoryRequired => 'Elige una categoría';

  @override
  String get postLocationRequired => 'Agrega una ubicación';

  @override
  String postCodeInvalid(String codeLabel) {
    return 'Ingresa un $codeLabel válido';
  }

  @override
  String get postalCodeLabelIndia => 'Código PIN';

  @override
  String get postalCodeLabelUsa => 'Código postal';

  @override
  String get requestsOpen => 'Abiertas';

  @override
  String get requestsAwarded => 'Adjudicadas';

  @override
  String get requestsPast => 'Anteriores';

  @override
  String get requestsEmptyOpen =>
      'No tienes solicitudes abiertas. Publica una y recibe cotizaciones de tiendas locales.';

  @override
  String get requestsEmptyAwarded => 'Aquí aparecen las solicitudes en las que aceptaste una cotización.';

  @override
  String get requestsEmptyPast => 'Aquí aparecen las solicitudes vencidas y canceladas.';

  @override
  String quotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cotizaciones',
      one: '1 cotización',
      zero: 'Aún no hay cotizaciones',
    );
    return '$_temp0';
  }

  @override
  String quotesOfMax(int count, int max) {
    return '$count de $max cotizaciones';
  }

  @override
  String closesIn(String time) {
    return 'Cierra en $time';
  }

  @override
  String get closed => 'Cerrada';

  @override
  String get statusOpen => 'Abierta';

  @override
  String get statusAwarded => 'Adjudicada';

  @override
  String get statusClosed => 'Cerrada';

  @override
  String get statusExpired => 'Vencida';

  @override
  String get statusCancelled => 'Cancelada';

  @override
  String get noQuotesYet => 'Aún no hay cotizaciones. Los vendedores suelen responder en menos de 2 horas.';

  @override
  String get cancelRequest => 'Cancelar solicitud';

  @override
  String get cancelRequestConfirm => '¿Cancelar esta solicitud? Los vendedores ya no podrán cotizar.';

  @override
  String get shareRequest => 'Compartir solicitud';

  @override
  String get shareRequestWhatsapp => 'Preguntar a amigos por WhatsApp';

  @override
  String shareRequestText(String link) {
    return '¿Cuál debería elegir? $link';
  }

  @override
  String get compare => 'Comparar';

  @override
  String get compareSelect => 'Selecciona hasta 3 cotizaciones para comparar';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortPrice => 'Precio';

  @override
  String get sortRating => 'Calificación';

  @override
  String get sortDelivery => 'Fecha de entrega';

  @override
  String get sortDistance => 'Distancia';

  @override
  String get quoteTotal => 'Total';

  @override
  String get quoteSubtotal => 'Subtotal';

  @override
  String get quoteTax => 'Impuestos';

  @override
  String get quoteDelivery => 'Entrega / instalación';

  @override
  String get quoteFreeDelivery => 'Gratis';

  @override
  String get quoteOffered => 'Ofrecido';

  @override
  String get quoteDeliveryDate => 'Fecha de entrega';

  @override
  String get quoteWarranty => 'Garantía';

  @override
  String quoteValidUntil(String date) {
    return 'Válida hasta el $date';
  }

  @override
  String get quoteNotes => 'Notas';

  @override
  String quoteResponseTime(String time) {
    return 'Respondió en $time';
  }

  @override
  String get quoteVerified => 'Verificado';

  @override
  String get quoteFoundingPartner => 'Socio fundador';

  @override
  String get quoteNew => 'Nueva';

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
    return 'Impuesto sobre las ventas $rate%';
  }

  @override
  String get taxIncludedNote => 'Los precios incluyen GST';

  @override
  String get salesTaxNote => 'Puede aplicarse impuesto sobre las ventas';

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String get shortlist => 'Preseleccionar';

  @override
  String get shortlisted => 'Preseleccionada';

  @override
  String get counterOffer => 'Pedir un mejor precio';

  @override
  String get counterOfferTitle => 'Pedir una cotización revisada';

  @override
  String get counterOfferTarget => 'Tu precio objetivo';

  @override
  String get counterOfferNote => 'Mensaje para el vendedor';

  @override
  String get counterOfferSent => 'Enviado. El vendedor puede revisar la cotización.';

  @override
  String counterOfferFrom(String price) {
    return 'El comprador pidió $price';
  }

  @override
  String get acceptConfirmTitle => '¿Aceptar esta cotización?';

  @override
  String acceptConfirmBody(String seller) {
    return '$seller recibirá tus datos de contacto y tu dirección. A los demás vendedores se les avisará amablemente que elegiste otra oferta.';
  }

  @override
  String get acceptedTitle => 'Cotización aceptada';

  @override
  String acceptedBody(String seller) {
    return 'Le avisamos a $seller. Ya puedes llamarle o chatear.';
  }

  @override
  String get declineTitle => 'Rechazar cotización';

  @override
  String get declineReason => 'Motivo (opcional, se comparte con el vendedor)';

  @override
  String get declineReasonPrice => 'Precio demasiado alto';

  @override
  String get declineReasonDelivery => 'Entrega demasiado tarde';

  @override
  String get declineReasonOther => 'Elegí otra oferta';

  @override
  String get quoteStatusSent => 'Enviada';

  @override
  String get quoteStatusRevised => 'Revisada';

  @override
  String get quoteStatusShortlisted => 'Preseleccionada';

  @override
  String get quoteStatusDeclined => 'Rechazada';

  @override
  String get quoteStatusAccepted => 'Aceptada';

  @override
  String get quoteStatusWithdrawn => 'Retirada';

  @override
  String get quoteStatusExpired => 'Vencida';

  @override
  String get orderTitle => 'Pedido';

  @override
  String get ordersTitle => 'Pedidos';

  @override
  String get orderTimeline => 'Progreso';

  @override
  String get orderStatusAccepted => 'Aceptado';

  @override
  String get orderStatusScheduled => 'Programado';

  @override
  String get orderStatusDispatched => 'Enviado';

  @override
  String get orderStatusDelivered => 'Entregado';

  @override
  String get orderStatusCompleted => 'Completado';

  @override
  String get orderStatusCancelled => 'Cancelado';

  @override
  String orderMarkAs(String status) {
    return 'Marcar como $status';
  }

  @override
  String get orderContact => 'Contacto';

  @override
  String get orderAddress => 'Dirección';

  @override
  String get orderPayment => 'Pago';

  @override
  String get orderPaymentOffPlatform => 'Paga directamente al vendedor. Regístralo aquí para tus registros.';

  @override
  String get orderRecordPayment => 'Registrar pago';

  @override
  String orderPaymentRecorded(String amount, String method) {
    return '$amount pagado con $method';
  }

  @override
  String get paymentMethodUpi => 'UPI';

  @override
  String get paymentMethodCash => 'Efectivo';

  @override
  String get paymentMethodCard => 'Tarjeta';

  @override
  String get paymentMethodBankTransfer => 'Transferencia bancaria';

  @override
  String get paymentMethodSellerLink => 'Enlace de pago del vendedor';

  @override
  String get paymentMethodZelle => 'Zelle';

  @override
  String get paymentMethodCheck => 'Cheque';

  @override
  String get rateSeller => 'Califica al vendedor';

  @override
  String get rateBuyer => 'Califica al comprador';

  @override
  String get reviewTitle => '¿Cómo te fue?';

  @override
  String get reviewTextHint => 'Cuéntales a otros sobre tu experiencia';

  @override
  String get reviewSubmit => 'Enviar reseña';

  @override
  String get reviewThanks => '¡Gracias por tu reseña!';

  @override
  String get reviewTagOnTime => 'Puntual';

  @override
  String get reviewTagGoodPrice => 'Buen precio';

  @override
  String get reviewTagProfessional => 'Profesional';

  @override
  String get reviewTagQuality => 'Excelente calidad';

  @override
  String get reviewTagResponsive => 'Responde rápido';

  @override
  String get reviewReply => 'Responder públicamente';

  @override
  String get reviewSellerReply => 'Respuesta del vendedor';

  @override
  String get reviewsTitle => 'Reseñas';

  @override
  String get reviewsEmpty => 'Aún no hay reseñas.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Aquí aparecen tus chats con vendedores sobre tus solicitudes.';

  @override
  String get chatHint => 'Mensaje';

  @override
  String get chatContactWarning =>
      'Por tu seguridad, no compartas datos de contacto fuera de la app hasta que aceptes una cotización.';

  @override
  String chatAboutRequest(String title) {
    return 'Sobre: $title';
  }

  @override
  String get chatRead => 'Leído';

  @override
  String get chatTyping => 'escribiendo…';

  @override
  String get chatFailed => 'No se envió. Toca para reintentar.';

  @override
  String get chatPhoto => 'Foto';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Estás al día.';

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String notifNewQuote(String seller) {
    return 'Nueva cotización de $seller';
  }

  @override
  String get notifQuoteRevised => 'Un vendedor revisó su cotización';

  @override
  String get notifMessage => 'Mensaje nuevo';

  @override
  String notifNewRequest(String title) {
    return 'Nueva solicitud: $title';
  }

  @override
  String get notifQuoteAccepted => '¡Aceptaron tu cotización!';

  @override
  String get notifQuoteDeclined => 'Un comprador eligió otra oferta';

  @override
  String get notifQuoteShortlisted => 'Un comprador preseleccionó tu cotización';

  @override
  String get notifCounterOffer => 'Un comprador pidió un mejor precio';

  @override
  String get notifOrderStatus => 'Actualización del pedido';

  @override
  String get notifGeneric => 'Actualización';

  @override
  String get sellerOnboardingTitle => 'Configura tu negocio';

  @override
  String get sellerStepBusiness => 'Negocio';

  @override
  String get sellerStepCategories => 'Qué vendes';

  @override
  String get sellerStepArea => 'Zona de servicio';

  @override
  String get sellerStepNotify => 'Alertas';

  @override
  String get businessName => 'Nombre del negocio';

  @override
  String get businessDescription => 'Acerca de tu negocio';

  @override
  String get yearsInBusiness => 'Años en el negocio';

  @override
  String get brandsCarried => 'Marcas que manejas (separadas por comas)';

  @override
  String get addLogo => 'Agregar logotipo';

  @override
  String get addShopPhotos => 'Agregar fotos de la tienda';

  @override
  String get selectCategories => 'Selecciona las categorías en las que puedes cotizar';

  @override
  String get categoriesRequired => 'Selecciona al menos una categoría';

  @override
  String get areaRadius => 'Radio alrededor de mi tienda';

  @override
  String areaCodes(String codeLabel) {
    return 'Lista de $codeLabel';
  }

  @override
  String get areaNationwide => 'Envíos a todo el país';

  @override
  String radiusValue(int value) {
    return '$value km';
  }

  @override
  String radiusValueMiles(int value) {
    return '$value mi';
  }

  @override
  String get shopLocation => 'Ubicación de la tienda';

  @override
  String serviceCodesHint(String example) {
    return 'Separados por comas, p. ej., $example';
  }

  @override
  String get sellerState => 'Estado';

  @override
  String get notifyInstant => 'Alertas al instante';

  @override
  String get notifyHourly => 'Resumen cada hora';

  @override
  String get notifyQuiet => 'Horas de silencio';

  @override
  String quietHoursRange(String start, String end) {
    return 'Silencio de $start a $end';
  }

  @override
  String get sellerProfileSaved => 'Tu negocio ya está activo. Los nuevos clientes potenciales aparecerán en tu feed.';

  @override
  String foundingPartnerBadge(String date) {
    return 'Socio fundador: gratis hasta el $date';
  }

  @override
  String get verificationTitle => 'Verifícate';

  @override
  String get verificationBody =>
      'Los vendedores verificados reciben una insignia y ven primero las nuevas solicitudes.';

  @override
  String get verificationStatusNone => 'No verificado';

  @override
  String get verificationStatusPending => 'En revisión';

  @override
  String get verificationStatusVerified => 'Verificado';

  @override
  String verificationStatusRejected(String reason) {
    return 'Rechazado: $reason';
  }

  @override
  String get docGstin => 'GSTIN';

  @override
  String get docUdyam => 'Número de registro Udyam';

  @override
  String get docShopPhoto => 'Foto de la tienda';

  @override
  String get docEin => 'EIN';

  @override
  String get docStateLicence => 'Número de licencia comercial estatal';

  @override
  String get docBusinessAddress => 'Dirección del negocio';

  @override
  String get docWebsite => 'Sitio web';

  @override
  String get docInvalid => 'Este número no parece correcto. Revísalo e inténtalo de nuevo.';

  @override
  String get uploadFile => 'Subir';

  @override
  String get submitForReview => 'Enviar a revisión';

  @override
  String get submittedForReview => 'Enviado. Lo revisaremos pronto.';

  @override
  String get licencesTitle => 'Licencias';

  @override
  String get licencesBody => 'Obligatorias para cotizar en categorías restringidas.';

  @override
  String get addLicence => 'Agregar licencia';

  @override
  String get licenceType => 'Tipo de licencia';

  @override
  String get licenceNumber => 'Número de licencia';

  @override
  String get licenceIssuer => 'Entidad emisora';

  @override
  String get licenceExpiry => 'Fecha de vencimiento';

  @override
  String get leadsTitle => 'Clientes potenciales';

  @override
  String get leadsEmpty =>
      'No hay solicitudes que coincidan por ahora. Te avisaremos cuando publiquen compradores cerca de ti.';

  @override
  String get leadsNoSellerProfile => 'Configura el perfil de tu negocio para empezar a recibir clientes potenciales.';

  @override
  String get leadFilters => 'Filtros';

  @override
  String get leadFilterCategory => 'Categoría';

  @override
  String get leadFilterDistance => 'A menos de';

  @override
  String get leadFilterAny => 'Cualquiera';

  @override
  String leadAway(String distance) {
    return 'a $distance';
  }

  @override
  String leadQuotesSent(int count, int max) {
    return '$count de $max cotizaciones enviadas';
  }

  @override
  String get leadFull => 'Se alcanzó el límite de cotizaciones';

  @override
  String leadNeededBy(String date) {
    return 'Lo necesita para el $date';
  }

  @override
  String leadBudget(String range) {
    return 'Presupuesto $range';
  }

  @override
  String get leadBudgetHidden => 'Presupuesto no compartido';

  @override
  String get leadDismiss => 'No me interesa';

  @override
  String get leadSendQuote => 'Enviar cotización';

  @override
  String get leadAlreadyQuoted => 'Ya cotizaste';

  @override
  String get leadPriorityNote => 'Los vendedores verificados ven primero las nuevas solicitudes.';

  @override
  String get leadLocalityOnly => 'La dirección exacta se comparte cuando el comprador acepta tu cotización.';

  @override
  String get quoteFormTitle => 'Tu cotización';

  @override
  String get quoteItem => 'Artículo / servicio';

  @override
  String get quoteQty => 'Cant.';

  @override
  String get quoteUnitPrice => 'Precio unitario';

  @override
  String get quoteAddLine => 'Agregar línea';

  @override
  String get quoteTaxRate => 'Tasa de GST';

  @override
  String get quoteSalesTaxRate => 'Tasa de impuesto sobre las ventas (%)';

  @override
  String get quoteBrandModel => 'Marca / modelo ofrecido';

  @override
  String get quoteValidity => 'Cotización válida por';

  @override
  String quoteValidityDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count días', one: '1 día');
    return '$_temp0';
  }

  @override
  String get quoteAttachments => 'Archivos adjuntos';

  @override
  String get quoteSaveTemplate => 'Guardar como plantilla';

  @override
  String get quoteUseTemplate => 'Usar plantilla';

  @override
  String get quoteTemplateName => 'Nombre de la plantilla';

  @override
  String get quoteSubmit => 'Enviar cotización';

  @override
  String get quoteRevise => 'Enviar cotización revisada';

  @override
  String get quoteWithdraw => 'Retirar cotización';

  @override
  String get quoteSent => 'Cotización enviada';

  @override
  String get quotePriceRequired => 'Ingresa un precio';

  @override
  String get quoteCapReached => 'Esta solicitud ya tiene el número máximo de cotizaciones.';

  @override
  String get quoteRequestClosed => 'Esta solicitud ya no está abierta.';

  @override
  String get quoteNotAllowed => 'No puedes cotizar en esta solicitud.';

  @override
  String get quoteLicenceRequired => 'Se requiere una licencia válida para esta categoría.';

  @override
  String get quoteNoCredits => 'Ya usaste tus cotizaciones gratis de este mes. Consulta los planes.';

  @override
  String get quotePriorityWindow =>
      'Los vendedores verificados tienen los primeros 15 minutos en las nuevas solicitudes.';

  @override
  String get quoteAlreadySent => 'Ya enviaste una cotización para esta solicitud.';

  @override
  String get templatesTitle => 'Plantillas de cotización';

  @override
  String get templatesEmpty => 'Guarda una cotización como plantilla para volver a usarla.';

  @override
  String get myQuotesActive => 'Activas';

  @override
  String get myQuotesWon => 'Ganadas';

  @override
  String get myQuotesLost => 'Perdidas';

  @override
  String get myQuotesEmpty => 'Aún no hay cotizaciones aquí.';

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get dashActive => 'Cotizaciones activas';

  @override
  String get dashWon => 'Ganadas';

  @override
  String get dashWinRate => 'Tasa de éxito';

  @override
  String get dashResponse => 'Respuesta prom.';

  @override
  String get dashRevenue => 'Ingresos registrados';

  @override
  String get dashRating => 'Calificación';

  @override
  String get dashQuotesThisMonth => 'Cotizaciones este mes';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String hoursShort(int count) {
    return '$count h';
  }

  @override
  String get planTitle => 'Plan y facturación';

  @override
  String get planFreeLaunch => 'Todo es gratis durante el lanzamiento.';

  @override
  String planFoundingPartner(String date) {
    return 'Como socio fundador, mantienes el acceso gratis hasta el $date.';
  }

  @override
  String planCurrent(String tier) {
    return 'Plan actual: $tier';
  }

  @override
  String planFreeTier(int count) {
    return 'Gratis: $count cotizaciones al mes';
  }

  @override
  String get planMonthly => 'Mensual';

  @override
  String get planAnnual => 'Anual';

  @override
  String get planSubscribe => 'Suscribirse';

  @override
  String get planCredits => 'Créditos de cotización';

  @override
  String planCreditsBalance(int count) {
    return 'Te quedan $count créditos';
  }

  @override
  String get planBuyCredits => 'Comprar créditos';

  @override
  String get planRestore => 'Restaurar compras';

  @override
  String get planManage => 'Administrar suscripción';

  @override
  String get planFixPayment => 'Hay un problema con tu pago. Actualízalo para conservar tu plan.';

  @override
  String planRenewal(String store) {
    return 'Se renueva automáticamente. Cancela cuando quieras en $store.';
  }

  @override
  String get planBuyOnWeb => 'Comprar en nuestro sitio web';

  @override
  String get planNotAvailable => 'Los planes aún no están disponibles en la app.';

  @override
  String get sellerProfileTitle => 'Perfil del negocio';

  @override
  String get sellerViewPublic => 'Ver como lo ven los compradores';

  @override
  String sellerDirectoryOptIn(String app) {
    return 'Mostrar mi negocio en el sitio web de $app';
  }

  @override
  String get sellerDirectoryOptInBody =>
      'Muestra el nombre de tu negocio, categorías, ciudad, calificación y tiempo de respuesta en una página pública. Nunca tu teléfono ni tu dirección.';

  @override
  String get sellerDirectoryOptInOn =>
      'Ya apareces. Tu página se publica en el sitio web tras la próxima actualización nocturna.';

  @override
  String get sellerDirectoryOptInOff =>
      'Oculto. Tu página se quita del sitio web en la próxima actualización nocturna.';

  @override
  String get sellerShareShop => 'Compartir mi tienda';

  @override
  String sellerShareText(String shop, String app, String link) {
    return 'Recibe cotizaciones de $shop y otras tiendas locales en $app: $link';
  }

  @override
  String sellerYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count años en el negocio',
      one: '1 año en el negocio',
    );
    return '$_temp0';
  }

  @override
  String sellerRating(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String sellerResponds(String time) {
    return 'Suele responder en $time';
  }

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsHelp => 'Ayuda y preguntas frecuentes';

  @override
  String get settingsLegal => 'Información legal';

  @override
  String get settingsLicenses => 'Licencias de código abierto';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get settingsBlocked => 'Usuarios bloqueados';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get notifPrefNewQuotes => 'Cotizaciones nuevas';

  @override
  String get notifPrefMessages => 'Mensajes';

  @override
  String get notifPrefLeads => 'Clientes potenciales nuevos';

  @override
  String get notifPrefMarketing => 'Ofertas y consejos';

  @override
  String get privacyAnalytics => 'Compartir datos de uso anónimos';

  @override
  String get privacyDoNotSell => 'No vender ni compartir mi información personal';

  @override
  String get privacyDownload => 'Solicitar una copia de mis datos';

  @override
  String get deleteTitle => 'Eliminar tu cuenta';

  @override
  String get deleteBody =>
      'Esto elimina de forma permanente tu perfil, solicitudes, cotizaciones, chats y fotos. Algunos registros, como los pedidos completados y las facturas fiscales, se conservan según lo exige la ley y luego se eliminan.';

  @override
  String get deleteConfirmLabel => 'Escribe DELETE para confirmar';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String get deleteButton => 'Eliminar mi cuenta';

  @override
  String get deleteReauth => 'Por tu seguridad, vuelve a iniciar sesión antes de eliminarla.';

  @override
  String get deleteDone => 'Tu cuenta se eliminó.';

  @override
  String get helpTitle => 'Ayuda y preguntas frecuentes';

  @override
  String get faqQ1 => '¿Es gratis para los compradores?';

  @override
  String get faqA1 => 'Sí. Publicar solicitudes y recibir cotizaciones siempre es gratis.';

  @override
  String get faqQ2 => '¿Cómo le pago al vendedor?';

  @override
  String get faqA2 =>
      'Le pagas directamente al vendedor, con los métodos que acepte. Registra el pago en el pedido para tus registros.';

  @override
  String get faqQ3 => '¿Cuándo ve el vendedor mi teléfono y mi dirección?';

  @override
  String get faqA3 => 'Solo después de que aceptes su cotización. Antes de eso, pueden chatear en la app.';

  @override
  String get faqQ4 => '¿Cómo se verifican los vendedores?';

  @override
  String get faqA4 => 'Envían documentos de su negocio que nuestro equipo revisa.';

  @override
  String get faqQ5 => '¿Cómo reporto un problema?';

  @override
  String get faqA5 => 'Usa Reportar en cualquier chat, cotización o perfil, o comunícate con soporte.';

  @override
  String get contactSupport => 'Contactar a soporte';

  @override
  String get legalTitle => 'Información legal';

  @override
  String get reportTitle => 'Reportar';

  @override
  String get reportReasonSpam => 'Spam o estafa';

  @override
  String get reportReasonAbuse => 'Abusivo u ofensivo';

  @override
  String get reportReasonFake => 'Negocio o solicitud falsa';

  @override
  String get reportReasonProhibited => 'Artículo prohibido';

  @override
  String get reportReasonOther => 'Otra cosa';

  @override
  String get reportDetails => 'Detalles (opcional)';

  @override
  String get reportSent => 'Gracias. Nuestro equipo lo revisará.';

  @override
  String blockConfirm(String name) {
    return '¿Bloquear a $name? No verás sus cotizaciones ni sus mensajes.';
  }

  @override
  String get blocked => 'Bloqueado';

  @override
  String inAppReviewAsk(String app) {
    return '¿Te gusta $app?';
  }

  @override
  String get updateRequired => 'Actualiza la app para continuar.';

  @override
  String get permissionLocationRationale =>
      'Usamos tu ubicación para encontrar vendedores cerca de ti. Solo se comparte tu zona hasta que aceptes una cotización.';

  @override
  String get permissionNotificationsRationale =>
      'Activa las notificaciones para enterarte al instante de nuevas cotizaciones y mensajes.';

  @override
  String get permissionMicRationale => 'Permite el acceso al micrófono para describir tu solicitud por voz.';

  @override
  String get allow => 'Permitir';

  @override
  String get notNow => 'Ahora no';

  @override
  String get accountBlockedTitle => 'Cuenta no disponible';

  @override
  String accountSuspendedBody(String date) {
    return 'Tu cuenta está suspendida hasta el $date. Aún puedes leer nuestras políticas o contactar a soporte.';
  }

  @override
  String get accountSuspendedBodyNoDate =>
      'Tu cuenta está suspendida. Aún puedes leer nuestras políticas o contactar a soporte.';

  @override
  String get accountBannedBody =>
      'Tu cuenta fue cerrada por incumplir nuestras reglas. Si crees que es un error, contacta a soporte.';

  @override
  String get accountDeletedBody => 'Esta cuenta fue eliminada.';
}

import '../constants/api_constants.dart';
import '../providers/locale_provider.dart';

class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  bool get isArabic => locale == AppLocale.ar;

  String tr({required String ar, required String fr, required String en}) {
    switch (locale) {
      case AppLocale.ar:
        return ar;
      case AppLocale.fr:
        return fr;
      case AppLocale.en:
        return en;
    }
  }

  // App
  String get appName => 'Souk Tchad';
  String get appTagline => tr(
        ar: 'سوق التشاد الإلكتروني',
        fr: 'Le marketplace du Tchad',
        en: 'The Chad marketplace',
      );
  String get splashLoading => tr(
        ar: 'جاري التحميل...',
        fr: 'Chargement...',
        en: 'Loading...',
      );

  // Navigation
  String get home => tr(ar: 'الرئيسية', fr: 'Accueil', en: 'Home');
  String get back => tr(ar: 'رجوع', fr: 'Retour', en: 'Back');
  String get favorites => tr(ar: 'المفضلة', fr: 'Favoris', en: 'Favorites');
  String get favorite => tr(ar: 'مفضلة', fr: 'Favori', en: 'Favorite');
  String get messages => tr(ar: 'الرسائل', fr: 'Messages', en: 'Messages');
  String get profile => tr(ar: 'الملف الشخصي', fr: 'Profil', en: 'Profile');
  String get myProfile =>
      tr(ar: 'ملفي الشخصي', fr: 'Mon profil', en: 'My profile');

  // Auth
  String get email => tr(ar: 'البريد الإلكتروني', fr: 'E-mail', en: 'Email');
  String get password =>
      tr(ar: 'كلمة المرور', fr: 'Mot de passe', en: 'Password');
  String get login =>
      tr(ar: 'تسجيل الدخول', fr: 'Se connecter', en: 'Log in');
  String get register =>
      tr(ar: 'إنشاء حساب', fr: "S'inscrire", en: 'Sign up');
  String get createAccount =>
      tr(ar: 'إنشاء حساب', fr: 'Créer un compte', en: 'Create account');
  String get fullName =>
      tr(ar: 'الاسم الكامل', fr: 'Nom complet', en: 'Full name');
  String get displayName =>
      tr(ar: 'الاسم المعروض', fr: 'Nom affiché', en: 'Display name');
  String get rememberMe => tr(
        ar: 'تذكر بيانات الدخول',
        fr: 'Se souvenir de mes identifiants',
        en: 'Remember my credentials',
      );
  String get googleLogin => tr(
        ar: 'المتابعة مع Google',
        fr: 'Continuer avec Google',
        en: 'Continue with Google',
      );
  String get googleRegister => tr(
        ar: 'التسجيل بحساب Google',
        fr: 'Créer un compte avec Google',
        en: 'Sign up with Google',
      );
  String get registerEmailHint => tr(
        ar: 'أدخل Gmail الخاص بك. سنرسل رمزاً من 6 أرقام للتحقق.',
        fr: 'Saisissez votre Gmail. Un code à 6 chiffres vous sera envoyé.',
        en: 'Enter your Gmail. A 6-digit code will be sent to you.',
      );
  String get continueLabel =>
      tr(ar: 'متابعة', fr: 'Continuer', en: 'Continue');
  String get verifyEmailTitle => tr(
        ar: 'التحقق من البريد',
        fr: 'Vérification e-mail',
        en: 'Email verification',
      );
  String get otpSentTo => tr(
        ar: 'تم إرسال رمز من 6 أرقام إلى',
        fr: 'Un code à 6 chiffres a été envoyé à',
        en: 'A 6-digit code was sent to',
      );
  String get otpCode =>
      tr(ar: 'رمز التحقق', fr: 'Code de validation', en: 'Verification code');
  String get otpCodeHint => tr(
        ar: '000000',
        fr: '000000',
        en: '000000',
      );
  String get verifyCode =>
      tr(ar: 'تحقق', fr: 'Valider le code', en: 'Verify code');
  String get resendOtp => tr(
        ar: 'إعادة إرسال الرمز',
        fr: 'Renvoyer le code',
        en: 'Resend code',
      );
  String get devOtpHint => tr(
        ar: 'وضع التطوير — الرمز:',
        fr: 'Mode dev — code :',
        en: 'Dev mode — code:',
      );
  String get completeProfileTitle => tr(
        ar: 'معلوماتك الشخصية',
        fr: 'Vos informations personnelles',
        en: 'Your personal information',
      );
  String get completeProfileSubtitle => tr(
        ar: 'أكمل ملفك لإنهاء إنشاء الحساب.',
        fr: 'Complétez votre profil pour finaliser votre compte.',
        en: 'Complete your profile to finish creating your account.',
      );
  String get finishRegistration => tr(
        ar: 'إنهاء التسجيل',
        fr: 'Terminer l\'inscription',
        en: 'Finish sign-up',
      );
  String get invalidOtp => tr(
        ar: 'رمز غير صالح (6 أرقام)',
        fr: 'Code invalide (6 chiffres)',
        en: 'Invalid code (6 digits)',
      );
  String get emailNotVerifiedLogin => tr(
        ar: 'يرجى تأكيد بريدك عبر الرابط المرسل على Gmail.',
        fr: 'Vérifiez votre e-mail : un lien a été envoyé sur Gmail.',
        en: 'Please verify your email using the link sent to Gmail.',
      );
  String get resendVerification => tr(
        ar: 'إعادة إرسال بريد التأكيد',
        fr: 'Renvoyer l\'e-mail de validation',
        en: 'Resend verification email',
      );
  String get verificationEmailSent => tr(
        ar: 'تم إرسال بريد التأكيد. تحقق من Gmail.',
        fr: 'E-mail de validation envoyé. Consultez votre boîte Gmail.',
        en: 'Verification email sent. Check your Gmail inbox.',
      );
  String get emailAlreadyUsed => tr(
        ar: 'هذا البريد مستخدم مسبقاً. سجّل الدخول أو استخدم Google.',
        fr: 'Cet e-mail est déjà utilisé. Connectez-vous ou utilisez Google.',
        en: 'This email is already in use. Log in or use Google.',
      );
  String get googleNotConfigured => tr(
        ar: 'تسجيل Google غير مُعدّ. أضف معرّفات OAuth الحقيقية في mobile/.env ثم أعد تثبيت التطبيق.',
        fr: 'Google Sign-In non configuré. Ajoutez vos vrais identifiants OAuth dans mobile/.env puis réinstallez l\'app.',
        en: 'Google Sign-In is not configured. Add your real OAuth IDs in mobile/.env, then reinstall the app.',
      );
  String get googleInvalidClient => tr(
        ar: 'معرّف Google OAuth غير صالح. أنشئ عميل iOS + Web في Google Cloud ثم نفّذ apply-google-config.sh',
        fr: 'Identifiant Google OAuth invalide. Créez un client iOS + Web sur Google Cloud, puis : bash apply-google-config.sh <ID_iOS> <ID_Web>',
        en: 'Invalid Google OAuth client. Create iOS + Web clients on Google Cloud, then run apply-google-config.sh',
      );
  String get googleUseWebButton => tr(
        ar: 'على الويب استخدم زر Google الرسمي أدناه.',
        fr: 'Sur le web, utilisez le bouton Google officiel ci-dessous.',
        en: 'On the web, use the official Google button below.',
      );
  String get alreadyHaveAccount => tr(
        ar: 'لديك حساب؟ سجّل الدخول',
        fr: 'Déjà un compte ? Se connecter',
        en: 'Already have an account? Log in',
      );
  String get invalidEmail => tr(
        ar: 'بريد إلكتروني غير صالح',
        fr: 'E-mail invalide',
        en: 'Invalid email',
      );
  String get minPassword => tr(
        ar: '6 أحرف على الأقل',
        fr: 'Minimum 6 caractères',
        en: 'At least 6 characters',
      );
  String get nameRequired =>
      tr(ar: 'الاسم مطلوب', fr: 'Nom requis', en: 'Name required');
  String get showPassword => tr(
        ar: 'إظهار كلمة المرور',
        fr: 'Afficher le mot de passe',
        en: 'Show password',
      );
  String get hidePassword => tr(
        ar: 'إخفاء كلمة المرور',
        fr: 'Masquer le mot de passe',
        en: 'Hide password',
      );
  String get loginRequired => tr(
        ar: 'سجّل الدخول للمتابعة',
        fr: 'Connectez-vous pour continuer',
        en: 'Log in to continue',
      );
  String get browseWithoutAccount => tr(
        ar: 'متابعة بدون حساب',
        fr: 'Continuer sans compte',
        en: 'Continue without account',
      );
  String get loginToPublish => tr(
        ar: 'سجّل الدخول أو أنشئ حساباً لنشر إعلان',
        fr: 'Connectez-vous ou créez un compte pour publier une annonce',
        en: 'Log in or sign up to publish a listing',
      );
  String get guestProfileTitle => tr(
        ar: 'مرحباً بك في سوق تشاد',
        fr: 'Bienvenue sur Souk Tchad',
        en: 'Welcome to Souk Tchad',
      );
  String get guestProfileCardSubtitle => tr(
        ar: 'سجّل الدخول للوصول إلى حسابك ومفضلاتك وإعلاناتك.',
        fr: 'Connectez-vous pour accéder à votre compte, vos favoris et vos annonces.',
        en: 'Log in to access your account, your favorites, and your listings.',
      );
  String get guestProfileHint => tr(
        ar: 'تصفّح الإعلانات مجاناً. لنشر إعلان أو حفظ المفضلة، أنشئ حساباً.',
        fr: 'Parcourez les annonces gratuitement. Pour publier, ajouter aux favoris ou envoyer un message, connectez-vous.',
        en: 'Browse listings for free. To publish, save favorites or message sellers, sign in.',
      );
  String get loginOrRegister => tr(
        ar: 'تسجيل الدخول / إنشاء حساب',
        fr: 'Se connecter / S\'inscrire',
        en: 'Log in / Sign up',
      );
  String get appSettings => tr(
        ar: 'إعدادات التطبيق',
        fr: 'Paramètres de l\'application',
        en: 'App settings',
      );
  String get defaultLanguage => tr(
        ar: 'اللغة الافتراضية',
        fr: 'Langue par défaut',
        en: 'Default language',
      );
  String get lightMode => tr(
        ar: 'الوضع الفاتح',
        fr: 'Mode clair',
        en: 'Light mode',
      );
  String get darkMode => tr(
        ar: 'الوضع الداكن',
        fr: 'Mode sombre',
        en: 'Dark mode',
      );
  String get aboutAndSupport => tr(
        ar: 'حول التطبيق والدعم',
        fr: 'À propos & support',
        en: 'About & support',
      );
  String get privacyPolicy => tr(
        ar: 'سياسة الخصوصية',
        fr: 'Politique de confidentialité',
        en: 'Privacy policy',
      );
  String get termsOfUse => tr(
        ar: 'شروط الاستخدام',
        fr: 'Conditions d\'utilisation',
        en: 'Terms of use',
      );
  String get contactUs => tr(
        ar: 'اتصل بنا',
        fr: 'Nous contacter',
        en: 'Contact us',
      );
  String get aboutApp => tr(
        ar: 'حول التطبيق',
        fr: 'À propos',
        en: 'About',
      );
  String profileHeroLoggedIn(int listings, String plan) => tr(
        ar: '$listings إعلان · $plan',
        fr: '$listings annonce(s) · Forfait $plan',
        en: '$listings listing(s) · $plan plan',
      );
  String get supportEmail => 'support@experiencetech-td.com';
  String get experienceTechWebsite => 'https://www.experiencetech-td.com/';
  String get privacyPolicyUrl => ApiConstants.privacyPolicyUrl;
  String get termsOfUseUrl => ApiConstants.termsOfUseUrl;
  String get openWebsite => tr(
        ar: 'فتح الموقع',
        fr: 'Ouvrir le site',
        en: 'Open website',
      );

  String get experienceTechCompanyName => 'Expérience Tech Sarl';

  String get privacyPolicyBody => tr(
        ar: '''سياسة الخصوصية — سوق تشاد

سوق تشاد يلتزم بحماية خصوصيتك.

البيانات المجمّعة:
• الاسم، البريد الإلكتروني، رقم الهاتف (اختياري)
• صور الإعلانات والملف الشخصي
• الرسائل بين المستخدمين
• معرّف الجهاز للإشعارات

استخدام البيانات:
• إنشاء حسابك وإدارة إعلاناتك
• تمكين المراسلة بين المشترين والبائعين
• تحسين الأمان ومنع الاحتيال
• إرسال إشعارات متعلقة بحسابك

لا نبيع بياناتك الشخصية لأطراف ثالثة.

الاحتفاظ بالبيانات:
تُحفظ بياناتك طالما حسابك نشط. يمكنك طلب الحذف عبر البريد: support@experiencetech-td.com

حقوقك:
الوصول، التصحيح، الحذف وإلغاء الاشتراك في الإشعارات.

آخر تحديث: 2026''',
        fr: '''Politique de confidentialité — Souk Tchad

Souk Tchad s'engage à protéger votre vie privée.

Données collectées :
• Nom, e-mail, téléphone (optionnel)
• Photos de profil et d'annonces
• Messages échangés entre utilisateurs
• Identifiant d'appareil pour les notifications

Utilisation des données :
• Créer et gérer votre compte et vos annonces
• Permettre la messagerie entre acheteurs et vendeurs
• Sécuriser la plateforme et lutter contre la fraude
• Vous envoyer des notifications liées à votre compte

Nous ne vendons pas vos données personnelles à des tiers.

Conservation :
Vos données sont conservées tant que votre compte est actif. Vous pouvez demander la suppression à : support@experiencetech-td.com

Vos droits :
Accès, rectification, suppression et désabonnement des notifications.

Dernière mise à jour : 2026''',
        en: '''Privacy policy — Souk Tchad

Souk Tchad is committed to protecting your privacy.

Data we collect:
• Name, email, phone (optional)
• Profile and listing photos
• Messages between users
• Device identifier for push notifications

How we use your data:
• Create and manage your account and listings
• Enable messaging between buyers and sellers
• Secure the platform and prevent fraud
• Send account-related notifications

We do not sell your personal data to third parties.

Retention:
Your data is kept while your account is active. You may request deletion at: support@experiencetech-td.com

Your rights:
Access, correction, deletion, and opt-out of notifications.

Last updated: 2026''',
      );
  String get termsBody => tr(
        ar: '''شروط الاستخدام — سوق تشاد

باستخدام سوق تشاد، فإنك توافق على:

الحساب:
• تقديم معلومات صحيحة
• الحفاظ على سرية كلمة المرور
• مسؤولية النشاط على حسابك

الإعلانات:
• نشر منتجات وخدمات قانونية فقط
• صور وأسعار صادقة
• عدم نشر محتوى مسيء أو مضلل أو مسروق

محظور:
• الاحتيال، التحرش، المحتوى غير القانوني
• إعادة نشر إعلانات الآخرين دون إذن
• إساءة استخدام نظام المراسلة

المسؤولية:
سوق تشاد منصة للربط بين المستخدمين. المعاملات تتم مباشرة بين الطرفين.

التعليق أو الحذف:
نحتفظ بحق تعليق الحسابات أو الإعلانات المخالفة.

الدعم: support@experiencetech-td.com''',
        fr: '''Conditions d'utilisation — Souk Tchad

En utilisant Souk Tchad, vous acceptez :

Compte :
• Fournir des informations exactes
• Garder votre mot de passe confidentiel
• Être responsable de l'activité sur votre compte

Annonces :
• Publier uniquement des biens et services légaux
• Des photos et prix honnêtes
• Ne pas publier de contenu offensant, trompeur ou volé

Interdit :
• Fraude, harcèlement, contenu illégal
• Republier les annonces d'autrui sans autorisation
• Abus du système de messagerie

Responsabilité :
Souk Tchad met en relation acheteurs et vendeurs. Les transactions se font directement entre les parties.

Suspension :
Nous pouvons suspendre un compte ou une annonce en cas de violation.

Support : support@experiencetech-td.com''',
        en: '''Terms of use — Souk Tchad

By using Souk Tchad, you agree to:

Account:
• Provide accurate information
• Keep your password confidential
• Be responsible for activity on your account

Listings:
• Post only legal goods and services
• Use honest photos and prices
• Do not post offensive, misleading, or stolen content

Prohibited:
• Fraud, harassment, illegal content
• Reposting others' listings without permission
• Abuse of the messaging system

Liability:
Souk Tchad connects buyers and sellers. Transactions are made directly between parties.

Suspension:
We may suspend accounts or listings that violate these terms.

Support: support@experiencetech-td.com''',
      );
  String get contactBody => tr(
        ar: '''تواصل معنا

فريق سوق تشاد يرافقك في استخدام التطبيق.

البريد الإلكتروني:
support@experiencetech-td.com

يمكنك الكتابة لنا بخصوص:
• مشكلة تقنية في التطبيق
• حسابك أو إعلاناتك
• اقتراح تحسين أو شراكة
• طلب حذف بياناتك

نرد عادة خلال 24 إلى 48 ساعة عمل.

اضغط على « إرسال بريد » لفتح تطبيق البريد مباشرة.''',
        fr: '''Nous contacter

L'équipe Souk Tchad vous accompagne au quotidien.

E-mail de support :
support@experiencetech-td.com

Vous pouvez nous écrire pour :
• Un problème technique dans l'application
• Votre compte ou vos annonces
• Une suggestion d'amélioration ou un partenariat
• Une demande de suppression de vos données

Réponse habituelle sous 24 à 48 h ouvrées.

Appuyez sur « Envoyer un e-mail » pour ouvrir votre messagerie directement.''',
        en: '''Contact us

The Souk Tchad team is here to help you.

Support email:
support@experiencetech-td.com

You can write to us about:
• A technical issue in the app
• Your account or listings
• A feature suggestion or partnership
• A request to delete your data

We usually reply within 24–48 business hours.

Tap "Send email" to open your mail app directly.''',
      );
  String get sendSupportEmail => tr(
        ar: 'إرسال بريد',
        fr: 'Envoyer un e-mail',
        en: 'Send email',
      );
  String get aboutAppBody => tr(
        ar: '''PLATEFORME MOBILE N°1 AU TCHAD
سوق تشاد — Souk Tchad

تطبيق Flutter عالمي المستوى مصمم لهواتف تشاد الذكية:
سريع · متعدد اللغات · مرن

اشترِ، بع وتواصل محلياً بسهولة وأمان.

تطوير: Expérience Tech Sarl
الدعم: support@experiencetech-td.com
الإصدار: 0.1.0''',
        fr: '''PLATEFORME MOBILE N°1 AU TCHAD
Souk Tchad

Une application Flutter de classe mondiale conçue pour les smartphones tchadiens : Rapide, Multilingue et Résiliente.

Achetez, vendez et échangez localement en toute simplicité.

Développé par Expérience Tech Sarl
Support : support@experiencetech-td.com
Version : 0.1.0''',
        en: '''#1 MOBILE PLATFORM IN CHAD
Souk Tchad

A world-class Flutter app built for Chadian smartphones: Fast, Multilingual, and Resilient.

Buy, sell, and connect locally with ease.

Developed by Expérience Tech Sarl
Support: support@experiencetech-td.com
Version: 0.1.0''',
      );
  String languageName(AppLocale locale) {
    switch (locale) {
      case AppLocale.fr:
        return french;
      case AppLocale.ar:
        return arabic;
      case AppLocale.en:
        return english;
    }
  }
  String get guestFavoritesTitle => tr(
        ar: 'المفضلة',
        fr: 'Favoris',
        en: 'Favorites',
      );
  String get guestFavoritesHint => tr(
        ar: 'سجّل الدخول لحفظ الإعلانات المفضلة',
        fr: 'Connectez-vous pour enregistrer vos annonces favorites',
        en: 'Sign in to save your favorite listings',
      );
  String get guestMessagesTitle => tr(
        ar: 'الرسائل',
        fr: 'Messages',
        en: 'Messages',
      );
  String get guestMessagesHint => tr(
        ar: 'سجّل الدخول للتواصل مع البائعين',
        fr: 'Connectez-vous pour contacter les vendeurs',
        en: 'Sign in to contact sellers',
      );
  String get wrongCredentials => tr(
        ar: 'بيانات الدخول غير صحيحة. أعد إدخال كلمة المرور.',
        fr: 'Identifiants incorrects. Retapez votre mot de passe.',
        en: 'Incorrect credentials. Re-enter your password.',
      );
  String get clearCredentials => tr(
        ar: 'مسح البيانات المحفوظة',
        fr: 'Effacer les identifiants sauvegardés',
        en: 'Clear saved credentials',
      );
  String get credentialsCleared => tr(
        ar: 'تم مسح البيانات المحفوظة',
        fr: 'Identifiants sauvegardés effacés',
        en: 'Saved credentials cleared',
      );

  // Chat
  String get noConversations => tr(
        ar: 'لا توجد محادثات بعد.\nتواصل مع بائع!',
        fr: 'Aucune conversation.\nContactez un vendeur !',
        en: 'No conversations yet.\nContact a seller!',
      );
  String get browseListings => tr(
        ar: 'تصفح الإعلانات',
        fr: 'Parcourir les annonces',
        en: 'Browse listings',
      );
  String get noMessagesYet =>
      tr(ar: 'لا توجد رسائل', fr: 'Aucun message', en: 'No messages');
  String get voiceMessage =>
      tr(ar: 'رسالة صوتية', fr: 'Message vocal', en: 'Voice message');
  String get chatTitle =>
      tr(ar: 'المحادثة', fr: 'Messagerie', en: 'Messaging');
  String get discussion =>
      tr(ar: 'محادثة', fr: 'Discussion', en: 'Chat');
  String get chatEmptyHint => tr(
        ar: 'اكتب رسالة أو اضغط على الميكروفون\nلإرسال رسالة صوتية',
        fr: 'Écrivez un message ou appuyez sur le micro\npour envoyer un vocal',
        en: 'Type a message or tap the mic\nto send a voice message',
      );
  String get yourMessage =>
      tr(ar: 'رسالتك...', fr: 'Votre message...', en: 'Your message...');
  String get recordingHint => tr(
        ar: 'جاري التسجيل... اضغط للإيقاف والإرسال',
        fr: 'Enregistrement… Appuyez pour arrêter et envoyer',
        en: 'Recording… Tap to stop and send',
      );
  String get micPermission => tr(
        ar: 'اسمح بالميكروفون لإرسال رسالة صوتية',
        fr: 'Autorisez le micro pour envoyer un vocal',
        en: 'Allow microphone access to send voice messages',
      );
  String get voiceError =>
      tr(ar: 'خطأ في الرسالة الصوتية', fr: 'Erreur vocal', en: 'Voice error');
  String get attachImage => tr(
        ar: 'إرسال صورة',
        fr: 'Envoyer une image',
        en: 'Send an image',
      );
  String get attachDocument => tr(
        ar: 'إرسال مستند',
        fr: 'Envoyer un document',
        en: 'Send a document',
      );
  String get documentMessage =>
      tr(ar: 'مستند', fr: 'Document', en: 'Document');
  String get attachmentError => tr(
        ar: 'خطأ في إرسال المرفق',
        fr: "Erreur d'envoi du fichier",
        en: 'Attachment upload error',
      );
  String get openDocument => tr(
        ar: 'فتح المستند',
        fr: 'Ouvrir le document',
        en: 'Open document',
      );
  String get viewListing =>
      tr(ar: 'عرض الإعلان', fr: 'Voir l\'annonce', en: 'View listing');
  String get you => tr(ar: 'أنت', fr: 'Vous', en: 'You');

  // Favorites
  String get myFavorites =>
      tr(ar: 'مفضلتي', fr: 'Mes favoris', en: 'My favorites');
  String get noFavorites => tr(
        ar: 'لا توجد مفضلات بعد',
        fr: 'Aucun favori pour le moment',
        en: 'No favorites yet',
      );
  String get noFavoritesHint => tr(
        ar: 'اضغط على القلب في الإعلانات لحفظها هنا',
        fr: 'Appuyez sur le cœur sur une annonce pour l\'enregistrer ici',
        en: 'Tap the heart on a listing to save it here',
      );
  String get removeFavorite => tr(
        ar: 'إزالة من المفضلة',
        fr: 'Retirer des favoris',
        en: 'Remove from favorites',
      );
  String get addToFavorites => tr(
        ar: 'إضافة إلى المفضلة',
        fr: 'Ajouter aux favoris',
        en: 'Add to favorites',
      );
  String get addedToFavorites => tr(
        ar: 'تمت الإضافة إلى المفضلة',
        fr: 'Ajouté aux favoris',
        en: 'Added to favorites',
      );
  String get removedFromFavorites => tr(
        ar: 'تمت الإزالة من المفضلة',
        fr: 'Retiré des favoris',
        en: 'Removed from favorites',
      );
  String favoriteCount(int n) {
    if (locale == AppLocale.ar) return '$n إعلان';
    if (locale == AppLocale.en) return '$n listing${n == 1 ? '' : 's'}';
    return '$n annonce${n > 1 ? 's' : ''}';
  }

  // Listings
  String get listingDetail =>
      tr(ar: 'تفاصيل الإعلان', fr: 'Détail annonce', en: 'Listing details');
  String get description =>
      tr(ar: 'الوصف', fr: 'Description', en: 'Description');
  String get seller => tr(ar: 'البائع', fr: 'Vendeur', en: 'Seller');
  String publishedOn(String date) => tr(
        ar: 'نُشر في $date',
        fr: 'Publié le $date',
        en: 'Published on $date',
      );
  String get call => tr(ar: 'اتصال', fr: 'Appeler', en: 'Call');
  String get noPhoneUseChat => tr(
        ar: 'لم يُدخل البائع رقماً. استخدم المحادثة.',
        fr: 'Le vendeur n\'a pas renseigné de numéro. Utilisez la discussion.',
        en: 'Seller has no phone number. Use chat.',
      );
  String get cannotCall => tr(
        ar: 'تعذر إجراء الاتصال',
        fr: 'Impossible de lancer l\'appel',
        en: 'Unable to start call',
      );
  String get ownListingHint => tr(
        ar: 'هذا إعلانك. سيتواصل معك المشترون هنا.',
        fr: 'C\'est votre annonce. Les acheteurs vous contacteront ici.',
        en: 'This is your listing. Buyers will contact you here.',
      );
  String get myListings =>
      tr(ar: 'إعلاناتي', fr: 'Mes annonces', en: 'My listings');
  String get createListing => tr(
        ar: 'نشر إعلان',
        fr: 'Publier une annonce',
        en: 'Post a listing',
      );
  String get editListing => tr(
        ar: 'تعديل الإعلان',
        fr: 'Modifier l\'annonce',
        en: 'Edit listing',
      );
  String get edit => tr(ar: 'تعديل', fr: 'Modifier', en: 'Edit');
  String get deleteListing => tr(
        ar: 'حذف الإعلان',
        fr: 'Supprimer l\'annonce',
        en: 'Delete listing',
      );
  String get delete => tr(ar: 'حذف', fr: 'Supprimer', en: 'Delete');
  String get deleteListingTitle => tr(
        ar: 'حذف الإعلان؟',
        fr: 'Supprimer l\'annonce ?',
        en: 'Delete listing?',
      );
  String deleteListingMessage(String title) => tr(
        ar: 'هل تريد حذف "$title" نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
        fr: 'Voulez-vous supprimer définitivement « $title » ? Cette action est irréversible.',
        en: 'Delete "$title" permanently? This cannot be undone.',
      );
  String get listingDeleted => tr(
        ar: 'تم حذف الإعلان',
        fr: 'Annonce supprimée',
        en: 'Listing deleted',
      );
  String deleteListingError(String msg) => tr(
        ar: 'تعذر الحذف : $msg',
        fr: 'Suppression impossible : $msg',
        en: 'Delete failed: $msg',
      );
  String get noMyListingsYet => tr(
        ar: 'لم تنشر أي إعلان بعد',
        fr: 'Vous n\'avez pas encore publié d\'annonce',
        en: 'You haven\'t posted any listings yet',
      );
  String get noListingsYet => tr(
        ar: 'لا توجد إعلانات بعد',
        fr: 'Aucune annonce pour le moment',
        en: 'No listings yet',
      );
  String get publishFirstListing => tr(
        ar: 'انشر منتجك أو خدمتك الأولى',
        fr: 'Publiez votre premier produit ou service',
        en: 'Post your first product or service',
      );
  String seeAll(int n) =>
      tr(ar: 'عرض الكل ($n)', fr: 'Tout voir ($n)', en: 'See all ($n)');
  String listingsStat(int n) {
    if (locale == AppLocale.ar) return '$n إعلان';
    if (locale == AppLocale.en) return '$n listing${n == 1 ? '' : 's'}';
    return '$n annonce${n > 1 ? 's' : ''}';
  }

  String activeStat(int n) {
    if (locale == AppLocale.ar) return '$n نشط';
    if (locale == AppLocale.en) return '$n active';
    return '$n active${n > 1 ? 's' : ''}';
  }

  // Profile
  String get language => tr(ar: 'اللغة', fr: 'Langue', en: 'Language');
  String get serverConnection => tr(
        ar: 'اتصال الخادم (بدون كابل)',
        fr: 'Connexion serveur (sans câble)',
        en: 'Server connection (no cable)',
      );
  String get serverUrl =>
      tr(ar: 'عنوان الخادم', fr: 'Adresse du serveur', en: 'Server address');
  String get serverUrlHint => 'http://192.168.1.10:3000/api';
  String get serverUrlHelper => tr(
        ar: 'Mac et iPhone sur le même Wi‑Fi. Backend actif sur le port 3000.',
        fr: 'Mac et iPhone sur le même Wi‑Fi. Backend actif sur le port 3000.',
        en: 'Mac and iPhone on the same Wi‑Fi. Backend running on port 3000.',
      );
  String get serverLocalhostWarning => tr(
        ar: 'على iPhone، استخدم عنوان IP لجهاز Mac (مثل 192.168.1.227:3000) وليس 127.0.0.1.',
        fr: 'Sur iPhone, utilisez l’adresse IP de votre Mac (ex. 192.168.1.227:3000), pas 127.0.0.1.',
        en: 'On iPhone, use your Mac’s IP address (e.g. 192.168.1.227:3000), not 127.0.0.1.',
      );
  String get testConnection => tr(
        ar: 'اختبار الاتصال',
        fr: 'Tester la connexion',
        en: 'Test connection',
      );
  String get connectionOk => tr(
        ar: 'تم الاتصال بنجاح',
        fr: 'Connexion réussie',
        en: 'Connection successful',
      );
  String connectionFailed(String msg) => tr(
        ar: 'فشل الاتصال : $msg',
        fr: 'Connexion impossible : $msg',
        en: 'Connection failed: $msg',
      );
  String get serverUrlSaved => tr(
        ar: 'تم حفظ عنوان الخادم',
        fr: 'Adresse du serveur enregistrée',
        en: 'Server address saved',
      );
  String get french => 'Français';
  String get arabic => 'العربية';
  String get english => 'English';
  String get personalInfo => tr(
        ar: 'المعلومات الشخصية',
        fr: 'Informations personnelles',
        en: 'Personal information',
      );
  String get phone => tr(ar: 'الهاتف', fr: 'Téléphone', en: 'Phone');
  String get phoneHint => '+23566000000';
  String get phoneHelper => tr(
        ar: 'يظهر على إعلاناتك للاتصال',
        fr: 'Visible sur vos annonces pour les appels',
        en: 'Shown on your listings for calls',
      );
  String get emailVerified =>
      tr(ar: 'البريد موثّق', fr: 'E-mail vérifié', en: 'Email verified');
  String get emailNotVerified => tr(
        ar: 'البريد غير موثّق',
        fr: 'E-mail non vérifié',
        en: 'Email not verified',
      );
  String get save => tr(ar: 'حفظ', fr: 'Enregistrer', en: 'Save');
  String get subscription =>
      tr(ar: 'الاشتراك', fr: 'Abonnement', en: 'Subscription');
  String get currentPlan =>
      tr(ar: 'الخطة الحالية', fr: 'Plan actuel', en: 'Current plan');
  String planLabel(String plan) {
    if (locale == AppLocale.ar) return 'الخطة $plan';
    if (locale == AppLocale.en) return 'Plan $plan';
    return 'Plan $plan';
  }

  String get security => tr(ar: 'الأمان', fr: 'Sécurité', en: 'Security');
  String get currentPassword => tr(
        ar: 'كلمة المرور الحالية',
        fr: 'Mot de passe actuel',
        en: 'Current password',
      );
  String get newPassword => tr(
        ar: 'كلمة المرور الجديدة',
        fr: 'Nouveau mot de passe',
        en: 'New password',
      );
  String get updatePassword => tr(
        ar: 'تحديث كلمة المرور',
        fr: 'Mettre à jour le mot de passe',
        en: 'Update password',
      );
  String get logout =>
      tr(ar: 'تسجيل الخروج', fr: 'Se déconnecter', en: 'Log out');
  String get logoutConfirm => tr(
        ar: 'هل تريد تسجيل الخروج؟',
        fr: 'Voulez-vous vraiment vous déconnecter ?',
        en: 'Do you really want to log out?',
      );
  String get deleteAccount => tr(
        ar: 'حذف الحساب',
        fr: 'Supprimer mon compte',
        en: 'Delete my account',
      );
  String get deleteAccountTitle => tr(
        ar: 'حذف الحساب؟',
        fr: 'Supprimer le compte ?',
        en: 'Delete account?',
      );
  String get deleteAccountMessage => tr(
        ar: 'سيتم حذف حسابك وإعلاناتك ورسائلك نهائياً. لا يمكن التراجع عن هذا الإجراء.',
        fr: 'Votre compte, vos annonces et vos messages seront supprimés définitivement. Cette action est irréversible.',
        en: 'Your account, listings and messages will be permanently deleted. This cannot be undone.',
      );
  String get accountDeleted => tr(
        ar: 'تم حذف الحساب',
        fr: 'Compte supprimé',
        en: 'Account deleted',
      );
  String get profilePhotoUpdated => tr(
        ar: 'تم تحديث صورة الملف الشخصي',
        fr: 'Photo de profil mise à jour',
        en: 'Profile photo updated',
      );
  String get profileUpdated => tr(
        ar: 'تم تحديث الملف الشخصي',
        fr: 'Profil mis à jour',
        en: 'Profile updated',
      );
  String get passwordUpdated => tr(
        ar: 'تم تغيير كلمة المرور',
        fr: 'Mot de passe modifié',
        en: 'Password updated',
      );
  String get loadingFailed => tr(
        ar: 'تعذر التحميل',
        fr: 'Chargement impossible',
        en: 'Loading failed',
      );
  String get unlimitedListings => tr(
        ar: 'إعلانات غير محدودة',
        fr: 'Annonces illimitées',
        en: 'Unlimited listings',
      );
  String maxListings(int n) => tr(
        ar: '$n إعلانات كحد أقصى',
        fr: '$n annonces max',
        en: 'Up to $n listings',
      );
  String pricePerMonth(int price) => tr(
        ar: '${(price / 5).round()} ريال/شهر',
        fr: '$price FCFA/mois',
        en: '$price FCFA/month',
      );
  String get noAds =>
      tr(ar: 'بدون إعلانات', fr: 'Sans publicité', en: 'No ads');
  String get current => tr(ar: 'الحالية', fr: 'Actuel', en: 'Current');
  String get choose => tr(ar: 'اختيار', fr: 'Choisir', en: 'Choose');
  String plansError(String e) => tr(
        ar: 'خطأ في الخطط : $e',
        fr: 'Erreur plans : $e',
        en: 'Plans error: $e',
      );

  // Home / search
  String get searchHint => tr(
        ar: 'ابحث عن إعلان...',
        fr: 'Rechercher une annonce...',
        en: 'Search listings...',
      );
  String get search => tr(ar: 'بحث', fr: 'Rechercher', en: 'Search');
  String get searchByPhoto => tr(
        ar: 'بحث بالصورة',
        fr: 'Rechercher par photo',
        en: 'Search by photo',
      );
  String get takePhoto =>
      tr(ar: 'التقاط صورة', fr: 'Prendre une photo', en: 'Take photo');
  String get chooseFromGallery => tr(
        ar: 'اختيار من المعرض',
        fr: 'Choisir dans la galerie',
        en: 'Choose from gallery',
      );
  String get analyzingPhoto => tr(
        ar: 'تحليل الصورة...',
        fr: 'Analyse de la photo...',
        en: 'Analyzing photo...',
      );
  String get preparingPhoto => tr(
        ar: 'تحضير الصورة...',
        fr: 'Préparation de la photo...',
        en: 'Preparing photo...',
      );
  String get sendingPhoto => tr(
        ar: 'إرسال إلى الذكاء الاصطناعي...',
        fr: 'Envoi à l\'IA...',
        en: 'Sending to AI...',
      );
  String get matchingListings => tr(
        ar: 'مطابقة الإعلانات...',
        fr: 'Correspondance des annonces...',
        en: 'Matching listings...',
      );
  String get noListingsFound => tr(
        ar: 'لم يتم العثور على إعلانات',
        fr: 'Aucune annonce trouvée',
        en: 'No listings found',
      );
  String get checkServerConnection => tr(
        ar: 'تحقق من أن الخادم يعمل وأن الهاتف على نفس شبكة الواي فاي.',
        fr: 'Vérifiez que le serveur est démarré et que l\'iPhone est sur le même Wi‑Fi.',
        en: 'Check that the server is running and your phone is on the same Wi‑Fi.',
      );
  String get retryLoad => tr(
        ar: 'إعادة التحميل',
        fr: 'Recharger les annonces',
        en: 'Reload listings',
      );
  String get allCategories => tr(ar: 'الكل', fr: 'Tout', en: 'All');
  String get publish => tr(ar: 'نشر', fr: 'Publier', en: 'Post');
  String hello(String name) {
    if (locale == AppLocale.ar) return 'مرحباً، $name 👋';
    if (locale == AppLocale.en) return 'Hello, $name 👋';
    return 'Bonjour, $name 👋';
  }

  String get photoSearchError => tr(
        ar: 'تعذر تحليل الصورة',
        fr: 'Impossible d\'analyser la photo',
        en: 'Unable to analyze photo',
      );
  String get geminiNotConfigured => tr(
        ar: 'الذكاء الاصطناعي غير مفعّل على الخادم',
        fr: 'IA non activée sur le serveur',
        en: 'AI not enabled on server',
      );
  String get manualSearchTitle => tr(
        ar: 'وصف المنتج',
        fr: 'Décrire le produit',
        en: 'Describe the product',
      );
  String get manualSearchHint => tr(
        ar: 'مثال: آيفون 13، تويوتا هايلوكس...',
        fr: 'Ex : iPhone 13, Toyota Hilux, canapé...',
        en: 'E.g. iPhone 13, Toyota Hilux, sofa...',
      );
  String get manualSearchAction => tr(
        ar: 'بحث يدوي',
        fr: 'Rechercher manuellement',
        en: 'Search manually',
      );
  String get cancel => tr(ar: 'إلغاء', fr: 'Annuler', en: 'Cancel');
  String get photoPermissionDenied => tr(
        ar: 'اسمح بالوصول إلى الكاميرا أو الصور في الإعدادات',
        fr: 'Autorisez l\'accès à la caméra ou aux photos dans Réglages',
        en: 'Allow camera or photo access in Settings',
      );
  String photoSearchDone(String keywords) => tr(
        ar: 'بحث: $keywords',
        fr: 'Recherche : $keywords',
        en: 'Search: $keywords',
      );
  String photoSearchNoMatch(String keywords) => tr(
        ar: 'لا نتائج لـ "$keywords"',
        fr: 'Aucun résultat pour "$keywords"',
        en: 'No results for "$keywords"',
      );

  // Listing form
  String get title => tr(ar: 'العنوان', fr: 'Titre', en: 'Title');
  String get titleRequired =>
      tr(ar: 'العنوان مطلوب', fr: 'Titre requis', en: 'Title required');
  String get descriptionRequired => tr(
        ar: 'الوصف مطلوب',
        fr: 'Description requise',
        en: 'Description required',
      );
  String get priceLabel =>
      tr(ar: 'السعر (ريال)', fr: 'Prix (FCFA)', en: 'Price (FCFA)');

  String categoryLabel(String slug) {
    switch (slug) {
      case 'automobiles':
        return tr(
          ar: 'السيارات والمركبات',
          fr: 'Automobiles & Véhicules',
          en: 'Vehicles',
        );
      case 'immobilier':
        return tr(ar: 'العقارات', fr: 'Immobilier', en: 'Real estate');
      case 'electronique':
        return tr(
          ar: 'الهواتف والإلكترونيات',
          fr: 'Téléphones & Électronique',
          en: 'Phones & Electronics',
        );
      case 'emplois':
        return tr(ar: 'الوظائف', fr: 'Emplois', en: 'Jobs');
      case 'services':
        return tr(ar: 'الخدمات', fr: 'Services', en: 'Services');
      case 'meubles':
        return tr(
          ar: 'الأثاث والمنزل',
          fr: 'Meubles & Maison',
          en: 'Furniture & Home',
        );
      case 'mode':
        return tr(
          ar: 'الملابس والأزياء',
          fr: 'Vêtements & Mode',
          en: 'Clothing & Fashion',
        );
      case 'animaux':
        return tr(
          ar: 'الحيوانات والتربية',
          fr: 'Animaux & Élevage',
          en: 'Animals & Livestock',
        );
      case 'autre':
        return tr(ar: 'أخرى', fr: 'Autre', en: 'Other');
      default:
        return slug;
    }
  }

  String listingCategoryLabel({
    required String slug,
    String? customCategoryName,
  }) {
    if (slug == 'autre' &&
        customCategoryName != null &&
        customCategoryName.trim().isNotEmpty) {
      return customCategoryName.trim();
    }
    return categoryLabel(slug);
  }

  String shortCategoryLabel(String slug) {
    final label = categoryLabel(slug);
    if (locale == AppLocale.ar) return label;
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return label;
    final first = parts.first;
    return first.length > 12 ? '${first.substring(0, 10)}…' : first;
  }
  String get priceRequired =>
      tr(ar: 'السعر مطلوب', fr: 'Prix requis', en: 'Price required');
  String get invalidPrice =>
      tr(ar: 'سعر غير صالح', fr: 'Prix invalide', en: 'Invalid price');
  String get city => tr(ar: 'المدينة', fr: 'Ville', en: 'City');
  String get defaultCity => "N'Djamena";
  String get category =>
      tr(ar: 'الفئة', fr: 'Catégorie', en: 'Category');
  String get categoryRequired => tr(
        ar: 'الفئة مطلوبة',
        fr: 'Catégorie requise',
        en: 'Category required',
      );
  String get customCategory => tr(
        ar: 'فئة مخصصة',
        fr: 'Catégorie personnalisée',
        en: 'Custom category',
      );
  String get customCategoryHint => tr(
        ar: 'مثال: دراجات، أدوات بناء...',
        fr: 'Ex. : Bicycles, Matériaux...',
        en: 'E.g. Bicycles, Building materials...',
      );
  String get customCategoryRequired => tr(
        ar: 'أدخل فئة مخصصة (حرفان على الأقل)',
        fr: 'Indiquez une catégorie (min. 2 caractères)',
        en: 'Enter a category (min. 2 characters)',
      );
  String get improveWithAi => tr(
        ar: 'تحسين بالذكاء الاصطناعي',
        fr: 'Améliorer avec IA',
        en: 'Improve with AI',
      );
  String get dictateListing => tr(
        ar: 'إملاء صوتي',
        fr: 'Dictée vocale',
        en: 'Voice dictation',
      );
  String get listening => tr(
        ar: 'جاري الاستماع...',
        fr: 'Écoute en cours...',
        en: 'Listening...',
      );
  String get speechUnavailable => tr(
        ar: 'التعرف على الصوت غير متاح',
        fr: 'Reconnaissance vocale indisponible',
        en: 'Speech recognition unavailable',
      );
  String addPhotos(int current, int max) => tr(
        ar: 'إضافة صور ($current/$max)',
        fr: 'Ajouter des photos ($current/$max)',
        en: 'Add photos ($current/$max)',
      );
  String get addVideo => tr(
        ar: 'إضافة فيديو (دقيقة واحدة كحد أقصى)',
        fr: 'Ajouter une vidéo (max 1 min)',
        en: 'Add video (max 1 min)',
      );
  String get recordVideo => tr(
        ar: 'تصوير فيديو',
        fr: 'Filmer une vidéo',
        en: 'Record a video',
      );
  String get chooseVideoFromGallery => tr(
        ar: 'اختيار فيديو من المعرض',
        fr: 'Choisir une vidéo dans la galerie',
        en: 'Choose video from gallery',
      );
  String get videoTooLong => tr(
        ar: 'الفيديو يجب ألا يتجاوز دقيقة واحدة',
        fr: 'La vidéo ne doit pas dépasser 1 minute',
        en: 'Video must not exceed 1 minute',
      );
  String get removeVideo => tr(
        ar: 'إزالة الفيديو',
        fr: 'Retirer la vidéo',
        en: 'Remove video',
      );
  String get replaceVideo => tr(
        ar: 'استبدال الفيديو',
        fr: 'Remplacer la vidéo',
        en: 'Replace video',
      );
  String get videoAttached => tr(
        ar: 'فيديو مرفق',
        fr: 'Vidéo jointe',
        en: 'Video attached',
      );
  String get aiUnavailable => tr(
        ar: 'الذكاء الاصطناعي غير متاح',
        fr: 'IA indisponible',
        en: 'AI unavailable',
      );
  String get listingPublished => tr(
        ar: 'تم نشر الإعلان — مرئي على سوق تشاد',
        fr: 'Annonce publiée — visible sur Souk Tchad',
        en: 'Listing published — visible on Souk Tchad',
      );
  String get listingModeratedHidden => tr(
        ar: 'تم حفظ الإعلان لكنه مخفي (المراجعة). تحقق من السعر أو المحتوى ثم عدّل الإعلان.',
        fr: 'Annonce enregistrée mais masquée (modération). Vérifiez le prix ou le contenu, puis modifiez l\'annonce.',
        en: 'Listing saved but hidden (moderation). Check price or content, then edit the listing.',
      );
  String get listingUpdatedSuccess => tr(
        ar: 'تم تعديل الإعلان',
        fr: 'Annonce modifiée',
        en: 'Listing updated',
      );
  String get listingUpdatedHidden => tr(
        ar: 'تم التعديل لكن الإعلان مخفي (المراجعة). تحقق من السعر أو المحتوى.',
        fr: 'Annonce modifiée mais masquée (modération). Vérifiez le prix ou le contenu.',
        en: 'Updated but hidden (moderation). Check price or content.',
      );

  // Subscriptions screen
  String get subscriptions =>
      tr(ar: 'الاشتراكات', fr: 'Abonnements', en: 'Subscriptions');
  String currentPlanValue(String plan) => tr(
        ar: 'الخطة الحالية : $plan',
        fr: 'Plan actuel : $plan',
        en: 'Current plan: $plan',
      );
  String get free => tr(ar: 'مجاني', fr: 'Gratuit', en: 'Free');
  String pricePerMonthUsd(int price) => tr(
        ar: '$price \$/شهر',
        fr: '$price \$/mois',
        en: '\$$price/month',
      );
  String activeListingsCount(int n) => tr(
        ar: '$n إعلانات نشطة',
        fr: '$n annonces actives',
        en: '$n active listings',
      );
  String get containsAds => tr(
        ar: 'يحتوي على إعلانات',
        fr: 'Contient des publicités',
        en: 'Contains ads',
      );
  String planActivated(String plan) => tr(
        ar: 'تم تفعيل خطة $plan',
        fr: 'Plan $plan activé',
        en: 'Plan $plan activated',
      );
  String get paymentNote => tr(
        ar: 'ادفع عبر موبايل موني ثم أكّد مع الدعم لتفعيل الخطة.',
        fr:
            'Payez par Mobile Money ; le support active votre plan après vérification.',
        en:
            'Pay via Mobile Money; support activates your plan after verification.',
      );
  String get checkoutStarted => tr(
        ar: 'تم إنشاء طلب الدفع',
        fr: 'Demande de paiement créée',
        en: 'Payment request created',
      );
  String paymentInstructions(String amount, String number) => tr(
        ar: 'أرسل $amount إلى $number ثم راسل الدعم برقم العملية.',
        fr:
            'Envoyez $amount FCFA au $number, puis contactez le support avec la référence de commande.',
        en:
            'Send $amount XAF to $number, then contact support with the order reference.',
      );
  String get paymentModalTitle => tr(
        ar: 'الدفع عبر موبايل موني',
        fr: 'Paiement Mobile Money',
        en: 'Mobile Money payment',
      );
  String paymentModalSubtitle(String plan) => tr(
        ar: 'تفعيل خطة $plan',
        fr: 'Activer le plan $plan',
        en: 'Activate the $plan plan',
      );
  String get payerReferenceLabel => tr(
        ar: 'رقم هاتفك',
        fr: 'Votre numéro Mobile Money',
        en: 'Your Mobile Money number',
      );
  String get payerPhoneLabel => tr(
        ar: 'رقم Airtel Money أو Moov Money',
        fr: 'Numéro Airtel Money ou Moov Money',
        en: 'Airtel Money or Moov Money number',
      );
  String get payerPhoneRequired => tr(
        ar: 'أدخل رقم الدفع المستخدم',
        fr: 'Indiquez le numéro utilisé pour payer',
        en: 'Enter the number used to pay',
      );
  String get payerReferenceHint => tr(
        ar: '+235...',
        fr: '+235...',
        en: '+235...',
      );
  String get momoOperatorLabel => tr(
        ar: 'المشغّل',
        fr: 'Opérateur',
        en: 'Operator',
      );
  String get airtelMoney =>
      tr(ar: 'Airtel Money', fr: 'Airtel Money', en: 'Airtel Money');
  String get moovMoney =>
      tr(ar: 'Moov Money', fr: 'Moov Money', en: 'Moov Money');
  String get paymentProofLabel => tr(
        ar: 'إثبات الدفع (لقطة شاشة)',
        fr: 'Preuve de paiement (capture d’écran)',
        en: 'Payment proof (screenshot)',
      );
  String get paymentProofHint => tr(
        ar: 'أرفق لقطة شاشة لتأكيد التحويل. سيتحقق المشرف ثم يفعّل الاشتراك.',
        fr:
            'Joignez la capture d’écran du transfert. L’administrateur vérifiera puis activera l’abonnement.',
        en:
            'Attach a screenshot of the transfer. An admin will verify then activate the subscription.',
      );
  String get paymentProofRequired => tr(
        ar: 'لقطة شاشة الدفع مطلوبة',
        fr: 'La capture d’écran du paiement est obligatoire',
        en: 'Payment screenshot is required',
      );
  String get addPaymentScreenshot => tr(
        ar: 'إضافة لقطة شاشة',
        fr: 'Ajouter une capture d’écran',
        en: 'Add a screenshot',
      );
  String get submitPaymentRequest => tr(
        ar: 'إرسال طلب الدفع',
        fr: 'Envoyer la demande',
        en: 'Submit payment request',
      );
  String get payNow => tr(
        ar: 'إرسال طلب الدفع',
        fr: 'Envoyer la demande',
        en: 'Submit payment request',
      );
  String get amountToSend =>
      tr(ar: 'المبلغ', fr: 'Montant', en: 'Amount');
  String paymentSendTo(String amount, String number) => tr(
        ar: 'أرسل $amount فرنك إلى $number ثم أرفق لقطة الشاشة أدناه.',
        fr:
            'Envoyez $amount FCFA au $number, puis joignez la capture d’écran ci-dessous.',
        en:
            'Send $amount XAF to $number, then attach the screenshot below.',
      );
  String get paymentNumberCopied => tr(
        ar: 'تم نسخ الرقم',
        fr: 'Numéro copié',
        en: 'Number copied',
      );
  String get paymentNumberNotConfigured => tr(
        ar: 'لم يتم ضبط رقم الدفع بعد. تواصل مع الدعم.',
        fr:
            'Aucun numéro de paiement configuré pour cet opérateur. Contactez le support.',
        en:
            'No payment number configured for this operator. Contact support.',
      );
  String get paymentRequestSentTitle => tr(
        ar: 'تم إرسال الطلب',
        fr: 'Demande envoyée',
        en: 'Request sent',
      );
  String get paymentRequestSentBody => tr(
        ar:
            'سيتحقق المشرف من الدفع عبر لقطة الشاشة ثم يفعّل اشتراكك.',
        fr:
            'L’administrateur vérifiera votre paiement via la capture d’écran, puis activera votre abonnement.',
        en:
            'An admin will verify your payment via the screenshot, then activate your subscription.',
      );
  String get momoNumberLabel => tr(
        ar: 'رقم موبايل موني',
        fr: 'Numéro Mobile Money',
        en: 'Mobile Money number',
      );
  String get adminPaymentSettingsTitle => tr(
        ar: 'إعدادات الدفع',
        fr: 'Paramètres de paiement',
        en: 'Payment settings',
      );
  String get adminPaymentSettingsProfileSubtitle => tr(
        ar: 'أرقام Airtel و Moov وإشعارات البريد',
        fr: 'Numéros Airtel/Moov et notifications e-mail',
        en: 'Airtel/Moov numbers and email notifications',
      );
  String get adminPaymentSettingsSubtitle => tr(
        ar:
            'هذه الأرقام تظهر تلقائياً للعملاء عند الاشتراك. أرفق لقطة الشاشة للتحقق.',
        fr:
            'Ces numéros s’affichent automatiquement aux clients lors de l’abonnement. Ils joignent une capture d’écran pour validation.',
        en:
            'These numbers are shown automatically to clients when subscribing. They attach a screenshot for verification.',
      );
  String get airtelMoneyNumberLabel => tr(
        ar: 'رقم Airtel Money (للاستلام)',
        fr: 'Numéro Airtel Money (réception)',
        en: 'Airtel Money number (receive)',
      );
  String get moovMoneyNumberLabel => tr(
        ar: 'رقم Moov Money (للاستلام)',
        fr: 'Numéro Moov Money (réception)',
        en: 'Moov Money number (receive)',
      );
  String get adminPaymentNumbersHint => tr(
        ar: 'يظهر كل رقم للعميل حسب المشغّل الذي يختاره.',
        fr:
            'Chaque numéro s’affiche chez le client selon l’opérateur choisi.',
        en: 'Each number is shown to the client based on the operator they pick.',
      );
  String get adminPaymentNotificationsTitle => tr(
        ar: 'إشعارات الدفع',
        fr: 'Notifications de paiement',
        en: 'Payment notifications',
      );
  String get adminPaymentNotificationEmail => tr(
        ar: 'البريد لاستلام طلبات الدفع',
        fr: 'E-mail pour recevoir les demandes de paiement',
        en: 'Email to receive payment requests',
      );
  String get adminPaymentNotifyOnPayment => tr(
        ar: 'إشعار بريد عند كل طلب دفع',
        fr: 'E-mail à chaque nouvelle demande de paiement',
        en: 'Email on each new payment request',
      );
  String get adminPaymentNotifyOnPaymentHint => tr(
        ar: 'ستصلك رسالة عند إرسال عميل طلب اشتراك مع لقطة الشاشة.',
        fr:
            'Vous recevrez un e-mail quand un client envoie une demande d’abonnement avec capture.',
        en:
            'You will receive an email when a client submits a subscription request with a screenshot.',
      );
  String get adminPaymentSettingsSaved => tr(
        ar: 'تم حفظ إعدادات الدفع',
        fr: 'Paramètres de paiement enregistrés',
        en: 'Payment settings saved',
      );
  String get adminPaymentPreviewTitle => tr(
        ar: 'ما يراه العملاء',
        fr: 'Aperçu client',
        en: 'Client preview',
      );
  String get adminPaymentFlowHint => tr(
        ar: 'يختار العميل المشغّل، يرسل المبلغ إلى الرقم المناسب، ثم يرفق لقطة الشاشة.',
        fr:
            'Le client choisit l’opérateur, envoie le montant au numéro affiché, puis joint une capture d’écran.',
        en:
            'The client picks an operator, sends the amount to the shown number, then attaches a screenshot.',
      );
  String get adminPaymentNumbersSection => tr(
        ar: 'أرقام الاستلام',
        fr: 'Numéros de réception',
        en: 'Receiving numbers',
      );
  String get adminPaymentPhoneRequired => tr(
        ar: 'أدخل رقماً صالحاً (8 أرقام على الأقل)',
        fr: 'Indiquez un numéro valide (8 chiffres minimum)',
        en: 'Enter a valid number (at least 8 digits)',
      );
  String get adminPaymentTapToConfigure => tr(
        ar: 'اضغط للتعديل',
        fr: 'Appuyez pour modifier',
        en: 'Tap to edit',
      );
  String get adminPaymentTapToCollapse => tr(
        ar: 'اضغط للطي',
        fr: 'Appuyez pour replier',
        en: 'Tap to collapse',
      );
  String get adminDashboardLink => tr(
        ar: 'لوحة الإدارة',
        fr: 'Tableau de bord admin',
        en: 'Admin dashboard',
      );
  String get adminSectionTitle => tr(
        ar: 'الإدارة',
        fr: 'Administration',
        en: 'Administration',
      );
  String get adminDashboardSubtitle => tr(
        ar: 'الإحصائيات والمدفوعات والإشراف',
        fr: 'Stats, paiements et modération',
        en: 'Stats, payments and moderation',
      );
  String get adminBadge => tr(ar: 'مسؤول', fr: 'Admin', en: 'Admin');
  String get adminOverviewTab =>
      tr(ar: 'نظرة عامة', fr: 'Vue d’ensemble', en: 'Overview');
  String get adminPaymentsTab =>
      tr(ar: 'المدفوعات', fr: 'Paiements', en: 'Payments');
  String get adminListingsTab =>
      tr(ar: 'الإعلانات', fr: 'Annonces', en: 'Listings');
  String get adminRefresh =>
      tr(ar: 'تحديث', fr: 'Actualiser', en: 'Refresh');
  String get adminSpaceLabel => tr(
        ar: 'مساحة المسؤول',
        fr: 'Espace administrateur',
        en: 'Admin area',
      );
  String adminHello(String name) => tr(
        ar: 'مرحباً، $name',
        fr: 'Bonjour, $name',
        en: 'Hello, $name',
      );
  String get adminAccessDeniedTitle =>
      tr(ar: 'وصول مقيد', fr: 'Accès réservé', en: 'Access restricted');
  String get adminAccessDeniedBody => tr(
        ar: 'يمكن للمسؤولين فقط فتح هذه المساحة.',
        fr: 'Seuls les administrateurs peuvent ouvrir cet espace.',
        en: 'Only administrators can open this area.',
      );
  String get adminConfirmPaymentTitle => tr(
        ar: 'تأكيد الدفع؟',
        fr: 'Confirmer le paiement ?',
        en: 'Confirm payment?',
      );
  String adminConfirmPaymentBody(String plan, String user) => tr(
        ar: 'سيتم تفعيل خطة $plan لـ $user.',
        fr: 'Le plan $plan sera activé pour $user.',
        en: 'Plan $plan will be activated for $user.',
      );
  String get adminThisUser =>
      tr(ar: 'هذا المستخدم', fr: 'cet utilisateur', en: 'this user');
  String get adminConfirm =>
      tr(ar: 'تأكيد', fr: 'Confirmer', en: 'Confirm');
  String get adminPaymentConfirmed => tr(
        ar: 'تم تأكيد الدفع وتفعيل الخطة.',
        fr: 'Paiement confirmé, plan activé.',
        en: 'Payment confirmed, plan activated.',
      );
  String get adminRejectPaymentTitle => tr(
        ar: 'رفض هذا الدفع؟',
        fr: 'Refuser ce paiement ?',
        en: 'Reject this payment?',
      );
  String get adminRejectPaymentBody => tr(
        ar: 'سيتم وضع علامة على الدفع كمرفوض.',
        fr: 'Le paiement sera marqué comme refusé.',
        en: 'The payment will be marked as rejected.',
      );
  String get adminReject =>
      tr(ar: 'رفض', fr: 'Refuser', en: 'Reject');
  String get adminUser =>
      tr(ar: 'مستخدم', fr: 'Utilisateur', en: 'User');
  String get adminPlan => tr(ar: 'الخطة', fr: 'Plan', en: 'Plan');
  String get adminAmount =>
      tr(ar: 'المبلغ', fr: 'Montant', en: 'Amount');
  String get adminDate => tr(ar: 'التاريخ', fr: 'Date', en: 'Date');
  String get adminDetails =>
      tr(ar: 'التفاصيل', fr: 'Détails', en: 'Details');
  String get adminViewDetails =>
      tr(ar: 'عرض التفاصيل', fr: 'Voir les détails', en: 'View details');
  String get adminStatUsers =>
      tr(ar: 'المستخدمون', fr: 'Utilisateurs', en: 'Users');
  String adminStatVerified(int n) => tr(
        ar: '$n مُتحقق',
        fr: '$n vérifiés',
        en: '$n verified',
      );
  String get adminStatActiveListings =>
      tr(ar: 'إعلانات نشطة', fr: 'Annonces actives', en: 'Active listings');
  String adminStatTotalListings(int n) => tr(
        ar: '$n إجمالاً',
        fr: '$n au total',
        en: '$n total',
      );
  String get adminStatToConfirm =>
      tr(ar: 'بانتظار التأكيد', fr: 'À confirmer', en: 'To confirm');
  String adminStatAlreadyPaid(int n) => tr(
        ar: '$n مدفوع مسبقاً',
        fr: '$n déjà payés',
        en: '$n already paid',
      );
  String get adminStatRevenue =>
      tr(ar: 'الإيرادات', fr: 'Revenus', en: 'Revenue');
  String get adminStatConfirmedSubs => tr(
        ar: 'اشتراكات مؤكدة',
        fr: 'Abonnements confirmés',
        en: 'Confirmed subscriptions',
      );
  String get adminStatConversations =>
      tr(ar: 'المحادثات', fr: 'Conversations', en: 'Conversations');
  String adminStatMessages(int n) => tr(
        ar: '$n رسالة',
        fr: '$n messages',
        en: '$n messages',
      );
  String get adminStatModerated =>
      tr(ar: 'قيد المراجعة', fr: 'Modérées', en: 'Moderated');
  String get adminStatUnderReview => tr(
        ar: 'إعلانات قيد المراجعة',
        fr: 'Annonces en revue',
        en: 'Listings under review',
      );
  String get adminPlansBreakdown => tr(
        ar: 'توزيع الخطط',
        fr: 'Répartition des plans',
        en: 'Plan breakdown',
      );
  String get adminPlansBreakdownSub => tr(
        ar: 'الاشتراكات النشطة حسب الصيغة',
        fr: 'Abonnements actifs par formule',
        en: 'Active subscriptions by plan',
      );
  String get adminNoPlanData => tr(
        ar: 'لا توجد بيانات خطط حالياً.',
        fr: 'Aucune donnée de plan pour le moment.',
        en: 'No plan data yet.',
      );
  String get adminPlanFree =>
      tr(ar: 'مجاني', fr: 'Gratuit', en: 'Free');
  String get adminPlanBasic =>
      tr(ar: 'أساسي', fr: 'Basique', en: 'Basic');
  String get adminPlanProfessional =>
      tr(ar: 'احترافي', fr: 'Professionnel', en: 'Professional');
  String get adminPlanBusiness =>
      tr(ar: 'أعمال', fr: 'Business', en: 'Business');
  String get adminFilterPending =>
      tr(ar: 'قيد الانتظار', fr: 'En attente', en: 'Pending');
  String get adminFilterConfirmed =>
      tr(ar: 'مؤكدة', fr: 'Confirmés', en: 'Confirmed');
  String get adminFilterRejected =>
      tr(ar: 'مرفوضة', fr: 'Refusés', en: 'Rejected');
  String get adminFilterAll =>
      tr(ar: 'الكل', fr: 'Tous', en: 'All');
  String get adminNoPayments =>
      tr(ar: 'لا مدفوعات', fr: 'Aucun paiement', en: 'No payments');
  String get adminNoPaymentsPending => tr(
        ar: 'كل شيء محدّث — لا مدفوعات معلّقة.',
        fr: 'Tout est à jour — aucun paiement en attente.',
        en: 'All clear — no pending payments.',
      );
  String get adminNoFilterResults => tr(
        ar: 'لا نتائج لهذا التصفية.',
        fr: 'Aucun résultat pour ce filtre.',
        en: 'No results for this filter.',
      );
  String get adminPaymentDetails => tr(
        ar: 'تفاصيل الدفع',
        fr: 'Détails du paiement',
        en: 'Payment details',
      );
  String get adminClient =>
      tr(ar: 'العميل', fr: 'Client', en: 'Client');
  String get adminOperator =>
      tr(ar: 'المشغّل', fr: 'Opérateur', en: 'Operator');
  String get adminMobileMoney =>
      tr(ar: 'موبايل موني', fr: 'Mobile Money', en: 'Mobile Money');
  String get adminPhone =>
      tr(ar: 'الهاتف', fr: 'Téléphone', en: 'Phone');
  String get adminEmailLabel =>
      tr(ar: 'البريد', fr: 'E-mail', en: 'Email');
  String get adminRef => tr(ar: 'المرجع', fr: 'Réf.', en: 'Ref.');
  String get adminImageUnavailable => tr(
        ar: 'الصورة غير متاحة',
        fr: 'Image indisponible',
        en: 'Image unavailable',
      );
  String get adminNoProof => tr(
        ar: 'لم تُرفق أي لقطة شاشة.',
        fr: 'Aucune capture fournie.',
        en: 'No screenshot provided.',
      );
  String get adminFilterAllListings =>
      tr(ar: 'الكل', fr: 'Toutes', en: 'All');
  String get adminFilterActive =>
      tr(ar: 'نشطة', fr: 'Actives', en: 'Active');
  String get adminFilterModerated =>
      tr(ar: 'مُراجعة', fr: 'Modérées', en: 'Moderated');
  String get adminFilterSold =>
      tr(ar: 'مُباعة', fr: 'Vendues', en: 'Sold');
  String get adminFilterDrafts =>
      tr(ar: 'مسودات', fr: 'Brouillons', en: 'Drafts');
  String get adminNoListings =>
      tr(ar: 'لا إعلانات', fr: 'Aucune annonce', en: 'No listings');
  String get adminNoListingsFilter => tr(
        ar: 'لا إعلان يطابق هذا التصفية.',
        fr: 'Aucune annonce ne correspond à ce filtre.',
        en: 'No listing matches this filter.',
      );
  String get adminChangeStatus => tr(
        ar: 'تغيير الحالة',
        fr: 'Changer le statut',
        en: 'Change status',
      );
  String get adminActivate =>
      tr(ar: 'تفعيل', fr: 'Activer', en: 'Activate');
  String get adminModerate =>
      tr(ar: 'مراجعة', fr: 'Modérer', en: 'Moderate');
  String get adminMarkSold =>
      tr(ar: 'وضع كمباع', fr: 'Marquer vendue', en: 'Mark as sold');
  String get adminDraft =>
      tr(ar: 'مسودة', fr: 'Brouillon', en: 'Draft');
  String get adminNoSeller =>
      tr(ar: 'بدون بائع', fr: 'Sans vendeur', en: 'No seller');
  String get adminStatusPending =>
      tr(ar: 'قيد الانتظار', fr: 'En attente', en: 'Pending');
  String get adminStatusConfirmed =>
      tr(ar: 'مؤكد', fr: 'Confirmé', en: 'Confirmed');
  String get adminStatusRejected =>
      tr(ar: 'مرفوض', fr: 'Refusé', en: 'Rejected');
  String get adminStatusModerated =>
      tr(ar: 'مُراجعة', fr: 'Modérée', en: 'Moderated');
  String get adminStatusActive =>
      tr(ar: 'نشطة', fr: 'Active', en: 'Active');
  String get adminStatusSold =>
      tr(ar: 'مُباعة', fr: 'Vendue', en: 'Sold');
  String get adminStatusDraft =>
      tr(ar: 'مسودة', fr: 'Brouillon', en: 'Draft');
  String get supportEmailSubject => tr(
        ar: 'دعم سوق تشاد',
        fr: 'Support Souk Tchad',
        en: 'Souk Tchad Support',
      );
  String get emailExampleHint =>
      tr(ar: 'exemple@gmail.com', fr: 'exemple@gmail.com', en: 'example@gmail.com');
  String get orderReferenceLabel => tr(
        ar: 'مرجع الطلب',
        fr: 'Référence de commande',
        en: 'Order reference',
      );
  String get close => tr(ar: 'إغلاق', fr: 'Fermer', en: 'Close');
  String get copied =>
      tr(ar: 'تم النسخ', fr: 'Copié', en: 'Copied');

  // Network errors
  String get serverUnreachable => tr(
        ar: 'تعذر الوصول إلى الخادم. تحقق من Wi‑Fi، تشغيل الخادم، ونفس الشبكة بين iPhone والMac.',
        fr: 'Impossible de joindre le serveur. Vérifiez le Wi‑Fi, que le backend tourne, et que l\'iPhone et le Mac sont sur le même réseau.',
        en: 'Cannot reach server. Check Wi‑Fi, backend is running, and iPhone and Mac are on the same network.',
      );
  String serverUnreachableDetail(String url) => tr(
        ar: 'تعذر الوصول إلى $url\n• شغّل: cd backend && npm run start:dev\n• نفس شبكة Wi‑Fi\n• iPhone: الإعدادات → Souk Tchad → الشبكة المحلية = مفعّل',
        fr: 'Impossible de joindre $url\n• Backend : cd backend && npm run start:dev\n• Même Wi‑Fi Mac/iPhone\n• iPhone : Réglages → Souk Tchad → Réseau local = activé',
        en: 'Cannot reach $url\n• Backend: cd backend && npm run start:dev\n• Same Wi‑Fi for Mac/iPhone\n• iPhone: Settings → Souk Tchad → Local Network = on',
      );
  String get photoUploadSlow => tr(
        ar: 'إرسال الصورة بطيء. جرّب اتصال Wi‑Fi أفضل.',
        fr: 'Envoi de la photo trop lent. Réessayez avec une connexion Wi‑Fi plus stable.',
        en: 'Photo upload too slow. Try a more stable Wi‑Fi connection.',
      );

  // Push notifications
  String get pushNewMessage =>
      tr(ar: 'رسالة جديدة', fr: 'Nouveau message', en: 'New message');
  String get pushNotificationsEnabled => tr(
        ar: 'الإشعارات مفعّلة',
        fr: 'Notifications activées',
        en: 'Notifications enabled',
      );

  // Common
  String get error => tr(ar: 'خطأ', fr: 'Erreur', en: 'Error');
  String errorWith(String msg) => '$error : $msg';
  String get loading =>
      tr(ar: 'جاري التحميل...', fr: 'Chargement...', en: 'Loading...');
  String get today => tr(ar: 'اليوم', fr: 'Aujourd\'hui', en: 'Today');
  String get yesterday => tr(ar: 'أمس', fr: 'Hier', en: 'Yesterday');
  String get retry =>
      tr(ar: 'إعادة المحاولة', fr: 'Réessayer', en: 'Retry');

  String get dateLocale {
    switch (locale) {
      case AppLocale.ar:
        return 'ar';
      case AppLocale.fr:
        return 'fr_FR';
      case AppLocale.en:
        return 'en';
    }
  }
}

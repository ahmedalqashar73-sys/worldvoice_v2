class AppStrings {
  const AppStrings._(this.code);
  final String code;

  static const _values = <String, List<String>>{
    'ar': ['اختر لغة التطبيق','يمكنك تغيير اللغة في أي وقت من إعدادات WorldVoice.','ابحث عن لغة'],
    'en': ['Choose your language','You can change this anytime in WorldVoice settings.','Search languages'],
    'es': ['Elige tu idioma','Puedes cambiarlo en cualquier momento en los ajustes de WorldVoice.','Buscar idiomas'],
    'fr': ['Choisissez votre langue','Vous pouvez la modifier à tout moment dans les paramètres de WorldVoice.','Rechercher une langue'],
    'zh': ['选择你的语言','你可以随时在 WorldVoice 设置中更改语言。','搜索语言'],
    'ko': ['언어를 선택하세요','WorldVoice 설정에서 언제든지 변경할 수 있습니다.','언어 검색'],
    'ja': ['言語を選択','WorldVoiceの設定からいつでも変更できます。','言語を検索'],
    'ru': ['Выберите язык','Язык можно изменить в любое время в настройках WorldVoice.','Поиск языка'],
    'tr': ['Dilini seç','WorldVoice ayarlarından istediğin zaman değiştirebilirsin.','Dil ara'],
    'ur': ['اپنی زبان منتخب کریں','آپ WorldVoice کی ترتیبات میں کسی بھی وقت زبان بدل سکتے ہیں۔','زبان تلاش کریں'],
    'de': ['Wähle deine Sprache','Du kannst sie jederzeit in den WorldVoice-Einstellungen ändern.','Sprachen suchen'],
    'pt': ['Escolha seu idioma','Você pode alterá-lo a qualquer momento nas configurações do WorldVoice.','Buscar idiomas'],
    'fa': ['زبان خود را انتخاب کنید','می‌توانید هر زمان در تنظیمات WorldVoice زبان را تغییر دهید.','جستجوی زبان'],
    'id': ['Pilih bahasa Anda','Anda dapat mengubahnya kapan saja di pengaturan WorldVoice.','Cari bahasa'],
    'th': ['เลือกภาษาของคุณ','คุณสามารถเปลี่ยนได้ทุกเมื่อในการตั้งค่า WorldVoice','ค้นหาภาษา'],
    'hi': ['अपनी भाषा चुनें','आप WorldVoice सेटिंग में इसे कभी भी बदल सकते हैं।','भाषा खोजें'],
    'it': ['Scegli la tua lingua','Puoi cambiarla in qualsiasi momento nelle impostazioni di WorldVoice.','Cerca lingue'],
  };

  List<String> get _text => _values[code] ?? _values['en']!;
  String get chooseLanguage => _text[0];
  String get changeAnytime => _text[1];
  String get searchLanguages => _text[2];

  static AppStrings of(String? code) => AppStrings._(code ?? 'en');
}

import Foundation

enum AppUILanguage: String, CaseIterable, Identifiable {
    case system
    case ru
    case en
    case es
    case de
    case fr
    case it
    case pt
    case zh
    case ja
    case ko
    case tr
    case uk

    var id: String { rawValue }

    static func stored(_ rawValue: String?) -> AppUILanguage {
        AppUILanguage(rawValue: rawValue ?? "") ?? .system
    }

    var displayName: String {
        switch self {
        case .system: return L10n.t("language.system")
        case .ru: return "Русский"
        case .en: return "English"
        case .es: return "Español"
        case .de: return "Deutsch"
        case .fr: return "Français"
        case .it: return "Italiano"
        case .pt: return "Português"
        case .zh: return "中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .tr: return "Türkçe"
        case .uk: return "Українська"
        }
    }
}

enum L10n {
    static var currentCode: String {
        let selected = AppUILanguage.stored(UserDefaults.standard.string(forKey: "appLanguage"))
        if selected != .system {
            return selected.rawValue
        }
        return systemCode
    }

    static var systemCode: String {
        for identifier in Locale.preferredLanguages {
            let code = identifier.lowercased()
            if code.hasPrefix("zh") { return "zh" }
            if code.hasPrefix("pt") { return "pt" }
            if let match = AppUILanguage.allCases.first(where: { $0 != .system && code.hasPrefix($0.rawValue) }) {
                return match.rawValue
            }
        }
        return "en"
    }

    static func t(_ key: String) -> String {
        translations[key]?[currentCode]
            ?? translations[key]?["en"]
            ?? translations[key]?["ru"]
            ?? key
    }

    static func format(_ key: String, _ values: CVarArg...) -> String {
        String(format: t(key), locale: Locale(identifier: currentCode), arguments: values)
    }

    static func languageName(_ googleCode: String) -> String {
        let normalized = googleCode == "zh-CN" ? "zh" : googleCode
        return languageNames[normalized]?[currentCode]
            ?? languageNames[normalized]?["en"]
            ?? googleCode
    }

    private static let languageNames: [String: [String: String]] = [
        "ru": ["ru": "Русский", "en": "Russian", "es": "Ruso", "de": "Russisch", "fr": "Russe", "it": "Russo", "pt": "Russo", "zh": "俄语", "ja": "ロシア語", "ko": "러시아어", "tr": "Rusça", "uk": "Російська"],
        "en": ["ru": "Английский", "en": "English", "es": "Inglés", "de": "Englisch", "fr": "Anglais", "it": "Inglese", "pt": "Inglês", "zh": "英语", "ja": "英語", "ko": "영어", "tr": "İngilizce", "uk": "Англійська"],
        "es": ["ru": "Испанский", "en": "Spanish", "es": "Español", "de": "Spanisch", "fr": "Espagnol", "it": "Spagnolo", "pt": "Espanhol", "zh": "西班牙语", "ja": "スペイン語", "ko": "스페인어", "tr": "İspanyolca", "uk": "Іспанська"],
        "de": ["ru": "Немецкий", "en": "German", "es": "Alemán", "de": "Deutsch", "fr": "Allemand", "it": "Tedesco", "pt": "Alemão", "zh": "德语", "ja": "ドイツ語", "ko": "독일어", "tr": "Almanca", "uk": "Німецька"],
        "fr": ["ru": "Французский", "en": "French", "es": "Francés", "de": "Französisch", "fr": "Français", "it": "Francese", "pt": "Francês", "zh": "法语", "ja": "フランス語", "ko": "프랑스어", "tr": "Fransızca", "uk": "Французька"],
        "it": ["ru": "Итальянский", "en": "Italian", "es": "Italiano", "de": "Italienisch", "fr": "Italien", "it": "Italiano", "pt": "Italiano", "zh": "意大利语", "ja": "イタリア語", "ko": "이탈리아어", "tr": "İtalyanca", "uk": "Італійська"],
        "pt": ["ru": "Португальский", "en": "Portuguese", "es": "Portugués", "de": "Portugiesisch", "fr": "Portugais", "it": "Portoghese", "pt": "Português", "zh": "葡萄牙语", "ja": "ポルトガル語", "ko": "포르투갈어", "tr": "Portekizce", "uk": "Португальська"],
        "zh": ["ru": "Китайский", "en": "Chinese", "es": "Chino", "de": "Chinesisch", "fr": "Chinois", "it": "Cinese", "pt": "Chinês", "zh": "中文", "ja": "中国語", "ko": "중국어", "tr": "Çince", "uk": "Китайська"],
        "ja": ["ru": "Японский", "en": "Japanese", "es": "Japonés", "de": "Japanisch", "fr": "Japonais", "it": "Giapponese", "pt": "Japonês", "zh": "日语", "ja": "日本語", "ko": "일본어", "tr": "Japonca", "uk": "Японська"],
        "ko": ["ru": "Корейский", "en": "Korean", "es": "Coreano", "de": "Koreanisch", "fr": "Coréen", "it": "Coreano", "pt": "Coreano", "zh": "韩语", "ja": "韓国語", "ko": "한국어", "tr": "Korece", "uk": "Корейська"],
        "tr": ["ru": "Турецкий", "en": "Turkish", "es": "Turco", "de": "Türkisch", "fr": "Turc", "it": "Turco", "pt": "Turco", "zh": "土耳其语", "ja": "トルコ語", "ko": "터키어", "tr": "Türkçe", "uk": "Турецька"],
        "uk": ["ru": "Украинский", "en": "Ukrainian", "es": "Ucraniano", "de": "Ukrainisch", "fr": "Ukrainien", "it": "Ucraino", "pt": "Ucraniano", "zh": "乌克兰语", "ja": "ウクライナ語", "ko": "우크라이나어", "tr": "Ukraynaca", "uk": "Українська"]
    ]

    private static let translations: [String: [String: String]] = [
        "app.title": ["ru": "Переводчик", "en": "Translator", "es": "Traductor", "de": "Übersetzer", "fr": "Traducteur", "it": "Traduttore", "pt": "Tradutor", "zh": "翻译器", "ja": "翻訳", "ko": "번역기", "tr": "Çevirmen", "uk": "Перекладач"],
        "app.subtitle": ["ru": "12 языков · онлайн и офлайн", "en": "12 languages · online and offline", "es": "12 idiomas · en línea y sin conexión", "de": "12 Sprachen · online und offline", "fr": "12 langues · en ligne et hors ligne", "it": "12 lingue · online e offline", "pt": "12 idiomas · online e offline", "zh": "12 种语言 · 在线和离线", "ja": "12言語 · オンラインとオフライン", "ko": "12개 언어 · 온라인 및 오프라인", "tr": "12 dil · çevrimiçi ve çevrimdışı", "uk": "12 мов · онлайн і офлайн"],
        "engine.google.privacy": ["ru": "Google онлайн: текст отправлен в интернет", "en": "Google online: text was sent to the internet", "es": "Google en línea: el texto se envió a internet", "de": "Google online: Text wurde ins Internet gesendet", "fr": "Google en ligne : texte envoyé sur internet", "it": "Google online: testo inviato a internet", "pt": "Google online: texto enviado à internet", "zh": "Google 在线：文本已发送到互联网", "ja": "Googleオンライン：テキストはネットに送信されました", "ko": "Google 온라인: 텍스트가 인터넷으로 전송됨", "tr": "Google çevrimiçi: metin internete gönderildi", "uk": "Google онлайн: текст надіслано в інтернет"],
        "engine.apple.privacy": ["ru": "Apple офлайн: текст обработан на устройстве", "en": "Apple offline: text was processed on device", "es": "Apple sin conexión: texto procesado en el dispositivo", "de": "Apple offline: Text wurde auf dem Gerät verarbeitet", "fr": "Apple hors ligne : texte traité sur l’appareil", "it": "Apple offline: testo elaborato sul dispositivo", "pt": "Apple offline: texto processado no dispositivo", "zh": "Apple 离线：文本已在设备上处理", "ja": "Appleオフライン：テキストはデバイス上で処理", "ko": "Apple 오프라인: 기기에서 텍스트 처리", "tr": "Apple çevrimdışı: metin aygıtta işlendi", "uk": "Apple офлайн: текст оброблено на пристрої"],
        "engine.offline.only": ["ru": "Только офлайн: Google отключён", "en": "Offline only: Google is disabled", "es": "Solo sin conexión: Google desactivado", "de": "Nur offline: Google ist deaktiviert", "fr": "Hors ligne uniquement : Google désactivé", "it": "Solo offline: Google disattivato", "pt": "Somente offline: Google desativado", "zh": "仅离线：Google 已关闭", "ja": "オフラインのみ：Googleは無効", "ko": "오프라인 전용: Google 비활성화", "tr": "Yalnızca çevrimdışı: Google kapalı", "uk": "Лише офлайн: Google вимкнено"],
        "engine.pending": ["ru": "Движок будет выбран при переводе", "en": "Engine will be selected on translation", "es": "El motor se elegirá al traducir", "de": "Engine wird beim Übersetzen gewählt", "fr": "Le moteur sera choisi à la traduction", "it": "Il motore sarà scelto alla traduzione", "pt": "O motor será escolhido na tradução", "zh": "翻译时将选择引擎", "ja": "翻訳時にエンジンを選択", "ko": "번역 시 엔진 선택", "tr": "Motor çeviri sırasında seçilir", "uk": "Рушій буде вибрано під час перекладу"],
        "auto": ["ru": "Авто", "en": "Auto", "es": "Auto", "de": "Auto", "fr": "Auto", "it": "Auto", "pt": "Auto", "zh": "自动", "ja": "自動", "ko": "자동", "tr": "Otomatik", "uk": "Авто"],
        "translate": ["ru": "Перевести", "en": "Translate", "es": "Traducir", "de": "Übersetzen", "fr": "Traduire", "it": "Traduci", "pt": "Traduzir", "zh": "翻译", "ja": "翻訳", "ko": "번역", "tr": "Çevir", "uk": "Перекласти"],
        "input.placeholder": ["ru": "Введите текст — или выделите его в любой программе и нажмите ⌃⌥T", "en": "Enter text — or select it in any app and press ⌃⌥T", "es": "Escribe texto — o selecciónalo en cualquier app y pulsa ⌃⌥T", "de": "Text eingeben — oder in einer App markieren und ⌃⌥T drücken", "fr": "Saisissez du texte — ou sélectionnez-le dans une app et appuyez sur ⌃⌥T", "it": "Inserisci testo — oppure selezionalo in un'app e premi ⌃⌥T", "pt": "Digite texto — ou selecione em qualquer app e pressione ⌃⌥T", "zh": "输入文本，或在任意应用中选择文本并按 ⌃⌥T", "ja": "テキストを入力、または任意のアプリで選択して ⌃⌥T", "ko": "텍스트를 입력하거나 앱에서 선택한 뒤 ⌃⌥T를 누르세요", "tr": "Metin girin ya da herhangi bir uygulamada seçip ⌃⌥T basın", "uk": "Введіть текст або виділіть його в будь-якій програмі й натисніть ⌃⌥T"],
        "result.placeholder": ["ru": "Здесь появится перевод", "en": "Translation will appear here", "es": "La traducción aparecerá aquí", "de": "Die Übersetzung erscheint hier", "fr": "La traduction apparaîtra ici", "it": "La traduzione apparirà qui", "pt": "A tradução aparecerá aqui", "zh": "译文将显示在这里", "ja": "翻訳がここに表示されます", "ko": "번역이 여기에 표시됩니다", "tr": "Çeviri burada görünecek", "uk": "Переклад з’явиться тут"],
        "offline.languages": ["ru": "Офлайн-языки…", "en": "Offline languages…", "es": "Idiomas sin conexión…", "de": "Offline-Sprachen…", "fr": "Langues hors ligne…", "it": "Lingue offline…", "pt": "Idiomas offline…", "zh": "离线语言…", "ja": "オフライン言語…", "ko": "오프라인 언어…", "tr": "Çevrimdışı diller…", "uk": "Офлайн-мови…"],
        "base.language": ["ru": "опорный язык", "en": "base language", "es": "idioma base", "de": "Basissprache", "fr": "langue de base", "it": "lingua base", "pt": "idioma base", "zh": "基础语言", "ja": "基準言語", "ko": "기준 언어", "tr": "temel dil", "uk": "опорна мова"],
        "offline.intro": ["ru": "Английский используется как опорный язык. Остальные языки скачиваются один раз и дальше переводятся без интернета.", "en": "English is used as the base language. Other languages are downloaded once and then work without internet.", "es": "El inglés se usa como idioma base. Los demás idiomas se descargan una vez y luego funcionan sin internet.", "de": "Englisch ist die Basissprache. Andere Sprachen werden einmal geladen und funktionieren dann ohne Internet.", "fr": "L’anglais sert de langue de base. Les autres langues sont téléchargées une fois puis fonctionnent sans internet.", "it": "L’inglese è la lingua base. Le altre lingue si scaricano una volta e poi funzionano senza internet.", "pt": "O inglês é o idioma base. Outros idiomas são baixados uma vez e depois funcionam sem internet.", "zh": "英语用作基础语言。其他语言下载一次后即可离线使用。", "ja": "英語を基準言語として使用します。他の言語は一度ダウンロードするとオフラインで使えます。", "ko": "영어가 기준 언어입니다. 다른 언어는 한 번 다운로드하면 인터넷 없이 작동합니다.", "tr": "İngilizce temel dil olarak kullanılır. Diğer diller bir kez indirilir ve sonra internetsiz çalışır.", "uk": "Англійська використовується як опорна мова. Інші мови завантажуються один раз і далі працюють без інтернету."],
        "offline.disk.note": ["ru": "Офлайн-модели занимают место на диске, а перевод длинных текстов без интернета работает медленнее и нагружает процессор.", "en": "Offline models use disk space, and long offline translations are slower and CPU-intensive.", "es": "Los modelos sin conexión ocupan espacio, y los textos largos se traducen más lento y cargan el procesador.", "de": "Offline-Modelle belegen Speicherplatz; lange Offline-Übersetzungen sind langsamer und CPU-intensiv.", "fr": "Les modèles hors ligne utilisent de l’espace disque, et les longs textes sont plus lents et sollicitent le processeur.", "it": "I modelli offline occupano spazio; i testi lunghi sono più lenti e usano più CPU.", "pt": "Modelos offline usam espaço em disco; textos longos são mais lentos e usam mais CPU.", "zh": "离线模型会占用磁盘空间，长文本离线翻译较慢且占用处理器。", "ja": "オフラインモデルは容量を使い、長文のオフライン翻訳は遅くCPU負荷が高くなります。", "ko": "오프라인 모델은 디스크 공간을 사용하며 긴 텍스트 번역은 느리고 CPU를 많이 사용합니다.", "tr": "Çevrimdışı modeller disk alanı kullanır; uzun metin çevirileri daha yavaş ve işlemci yoğundur.", "uk": "Офлайн-моделі займають місце на диску, а довгі тексти перекладаються повільніше й навантажують процесор."],
        "later": ["ru": "Позже", "en": "Later", "es": "Más tarde", "de": "Später", "fr": "Plus tard", "it": "Più tardi", "pt": "Depois", "zh": "稍后", "ja": "後で", "ko": "나중에", "tr": "Sonra", "uk": "Пізніше"],
        "copy.translation": ["ru": "Копировать перевод", "en": "Copy translation", "es": "Copiar traducción", "de": "Übersetzung kopieren", "fr": "Copier la traduction", "it": "Copia traduzione", "pt": "Copiar tradução", "zh": "复制翻译", "ja": "翻訳をコピー", "ko": "번역 복사", "tr": "Çeviriyi kopyala", "uk": "Копіювати переклад"],
        "speak.source": ["ru": "Озвучить исходный текст", "en": "Speak source text", "es": "Leer texto original", "de": "Ausgangstext vorlesen", "fr": "Lire le texte source", "it": "Leggi testo originale", "pt": "Falar texto original", "zh": "朗读原文", "ja": "原文を読み上げ", "ko": "원문 읽기", "tr": "Kaynak metni seslendir", "uk": "Озвучити вихідний текст"],
        "speak.translation": ["ru": "Озвучить перевод", "en": "Speak translation", "es": "Leer traducción", "de": "Übersetzung vorlesen", "fr": "Lire la traduction", "it": "Leggi traduzione", "pt": "Falar tradução", "zh": "朗读译文", "ja": "翻訳を読み上げ", "ko": "번역 읽기", "tr": "Çeviriyi seslendir", "uk": "Озвучити переклад"],
        "clear": ["ru": "Очистить", "en": "Clear", "es": "Borrar", "de": "Leeren", "fr": "Effacer", "it": "Cancella", "pt": "Limpar", "zh": "清除", "ja": "消去", "ko": "지우기", "tr": "Temizle", "uk": "Очистити"],
        "history": ["ru": "История переводов", "en": "Translation history", "es": "Historial de traducciones", "de": "Übersetzungsverlauf", "fr": "Historique des traductions", "it": "Cronologia traduzioni", "pt": "Histórico de traduções", "zh": "翻译历史", "ja": "翻訳履歴", "ko": "번역 기록", "tr": "Çeviri geçmişi", "uk": "Історія перекладів"],
        "history.subtitle": ["ru": "хранятся последние %d", "en": "latest %d are stored", "es": "se guardan los últimos %d", "de": "die letzten %d werden gespeichert", "fr": "les %d derniers sont conservés", "it": "vengono salvati gli ultimi %d", "pt": "os últimos %d são salvos", "zh": "保存最近 %d 条", "ja": "最新%d件を保存", "ko": "최근 %d개 저장", "tr": "son %d kayıt saklanır", "uk": "зберігаються останні %d"],
        "history.empty": ["ru": "Пока пусто — переводы будут появляться здесь", "en": "Empty for now — translations will appear here", "es": "Vacío por ahora — las traducciones aparecerán aquí", "de": "Noch leer — Übersetzungen erscheinen hier", "fr": "Vide pour l’instant — les traductions apparaîtront ici", "it": "Ancora vuoto — le traduzioni appariranno qui", "pt": "Vazio por enquanto — traduções aparecerão aqui", "zh": "暂时为空，翻译会显示在这里", "ja": "まだ空です。翻訳はここに表示されます", "ko": "아직 비어 있습니다. 번역이 여기에 표시됩니다", "tr": "Şimdilik boş — çeviriler burada görünecek", "uk": "Поки порожньо — переклади з’являться тут"],
        "replace": ["ru": "Заменить", "en": "Replace", "es": "Reemplazar", "de": "Ersetzen", "fr": "Remplacer", "it": "Sostituisci", "pt": "Substituir", "zh": "替换", "ja": "置換", "ko": "바꾸기", "tr": "Değiştir", "uk": "Замінити"],
        "replace.help": ["ru": "Вставить перевод вместо выделенного текста", "en": "Insert translation instead of selected text", "es": "Insertar traducción en lugar del texto seleccionado", "de": "Übersetzung statt markiertem Text einsetzen", "fr": "Insérer la traduction à la place du texte sélectionné", "it": "Inserisci traduzione al posto del testo selezionato", "pt": "Inserir tradução no lugar do texto selecionado", "zh": "用译文替换所选文本", "ja": "選択テキストを翻訳で置換", "ko": "선택한 텍스트를 번역으로 바꾸기", "tr": "Seçili metin yerine çeviriyi ekle", "uk": "Вставити переклад замість виділеного тексту"],
        "expand.panel": ["ru": "Открыть в большой панели", "en": "Open in large panel", "es": "Abrir en panel grande", "de": "In großem Panel öffnen", "fr": "Ouvrir dans le grand panneau", "it": "Apri nel pannello grande", "pt": "Abrir no painel grande", "zh": "在大面板中打开", "ja": "大きなパネルで開く", "ko": "큰 패널에서 열기", "tr": "Büyük panelde aç", "uk": "Відкрити у великій панелі"],
        "translating": ["ru": "Перевожу…", "en": "Translating…", "es": "Traduciendo…", "de": "Übersetze…", "fr": "Traduction…", "it": "Traduzione…", "pt": "Traduzindo…", "zh": "正在翻译…", "ja": "翻訳中…", "ko": "번역 중…", "tr": "Çevriliyor…", "uk": "Перекладаю…"],
        "settings": ["ru": "Настройки", "en": "Settings", "es": "Ajustes", "de": "Einstellungen", "fr": "Réglages", "it": "Impostazioni", "pt": "Configurações", "zh": "设置", "ja": "設定", "ko": "설정", "tr": "Ayarlar", "uk": "Налаштування"],
        "quit": ["ru": "Выход", "en": "Quit", "es": "Salir", "de": "Beenden", "fr": "Quitter", "it": "Esci", "pt": "Sair", "zh": "退出", "ja": "終了", "ko": "종료", "tr": "Çıkış", "uk": "Вийти"],
        "swap.languages": ["ru": "Поменять языки местами", "en": "Swap languages", "es": "Intercambiar idiomas", "de": "Sprachen tauschen", "fr": "Inverser les langues", "it": "Scambia lingue", "pt": "Trocar idiomas", "zh": "交换语言", "ja": "言語を入れ替え", "ko": "언어 바꾸기", "tr": "Dilleri değiştir", "uk": "Поміняти мови місцями"],
        "settings.subtitle": ["ru": "быстрые клавиши и поведение", "en": "hotkeys and behavior", "es": "atajos y comportamiento", "de": "Kurzbefehle und Verhalten", "fr": "raccourcis et comportement", "it": "scorciatoie e comportamento", "pt": "atalhos e comportamento", "zh": "快捷键和行为", "ja": "ショートカットと動作", "ko": "단축키와 동작", "tr": "kısayollar ve davranış", "uk": "гарячі клавіші та поведінка"],
        "section.language": ["ru": "Язык", "en": "Language", "es": "Idioma", "de": "Sprache", "fr": "Langue", "it": "Lingua", "pt": "Idioma", "zh": "语言", "ja": "言語", "ko": "언어", "tr": "Dil", "uk": "Мова"],
        "section.theme": ["ru": "Тема", "en": "Theme", "es": "Tema", "de": "Design", "fr": "Thème", "it": "Tema", "pt": "Tema", "zh": "主题", "ja": "テーマ", "ko": "테마", "tr": "Tema", "uk": "Тема"],
        "section.panel": ["ru": "Панель", "en": "Panel", "es": "Panel", "de": "Panel", "fr": "Panneau", "it": "Pannello", "pt": "Painel", "zh": "面板", "ja": "パネル", "ko": "패널", "tr": "Panel", "uk": "Панель"],
        "section.hotkeys": ["ru": "Быстрые клавиши", "en": "Hotkeys", "es": "Atajos", "de": "Kurzbefehle", "fr": "Raccourcis", "it": "Scorciatoie", "pt": "Atalhos", "zh": "快捷键", "ja": "ショートカット", "ko": "단축키", "tr": "Kısayollar", "uk": "Гарячі клавіші"],
        "section.behavior": ["ru": "Поведение", "en": "Behavior", "es": "Comportamiento", "de": "Verhalten", "fr": "Comportement", "it": "Comportamento", "pt": "Comportamento", "zh": "行为", "ja": "動作", "ko": "동작", "tr": "Davranış", "uk": "Поведінка"],
        "section.updates": ["ru": "Обновления", "en": "Updates", "es": "Actualizaciones", "de": "Updates", "fr": "Mises à jour", "it": "Aggiornamenti", "pt": "Atualizações", "zh": "更新", "ja": "アップデート", "ko": "업데이트", "tr": "Güncellemeler", "uk": "Оновлення"],
        "hotkey.selection": ["ru": "Перевести выделенный текст", "en": "Translate selected text", "es": "Traducir texto seleccionado", "de": "Markierten Text übersetzen", "fr": "Traduire le texte sélectionné", "it": "Traduci testo selezionato", "pt": "Traduzir texto selecionado", "zh": "翻译所选文本", "ja": "選択したテキストを翻訳", "ko": "선택한 텍스트 번역", "tr": "Seçili metni çevir", "uk": "Перекласти виділений текст"],
        "hotkey.clipboard": ["ru": "Перевести из буфера обмена", "en": "Translate clipboard", "es": "Traducir portapapeles", "de": "Zwischenablage übersetzen", "fr": "Traduire le presse-papiers", "it": "Traduci appunti", "pt": "Traduzir área de transferência", "zh": "翻译剪贴板", "ja": "クリップボードを翻訳", "ko": "클립보드 번역", "tr": "Panoyu çevir", "uk": "Перекласти з буфера обміну"],
        "language.system": ["ru": "Как в системе", "en": "System", "es": "Sistema", "de": "System", "fr": "Système", "it": "Sistema", "pt": "Sistema", "zh": "系统", "ja": "システム", "ko": "시스템", "tr": "Sistem", "uk": "Як у системі"],
        "language.caption": ["ru": "Автоматически берётся из macOS или выбирается вручную", "en": "Uses macOS automatically or a manual choice", "es": "Usa macOS automáticamente o una elección manual", "de": "Nutzt macOS automatisch oder eine manuelle Auswahl", "fr": "Utilise macOS automatiquement ou un choix manuel", "it": "Usa macOS automaticamente o una scelta manuale", "pt": "Usa o macOS automaticamente ou uma escolha manual", "zh": "自动使用 macOS 语言或手动选择", "ja": "macOSに合わせるか手動で選択", "ko": "macOS 언어를 자동 사용하거나 직접 선택", "tr": "macOS dilini otomatik kullanır veya elle seçilir", "uk": "Автоматично бере мову macOS або ручний вибір"],
        "auto.translate": ["ru": "Переводить автоматически при вводе", "en": "Translate automatically while typing", "es": "Traducir automáticamente al escribir", "de": "Beim Tippen automatisch übersetzen", "fr": "Traduire automatiquement pendant la saisie", "it": "Traduci automaticamente durante la digitazione", "pt": "Traduzir automaticamente ao digitar", "zh": "输入时自动翻译", "ja": "入力中に自動翻訳", "ko": "입력 중 자동 번역", "tr": "Yazarken otomatik çevir", "uk": "Перекладати автоматично під час введення"],
        "offline.only": ["ru": "Только офлайн", "en": "Offline only", "es": "Solo sin conexión", "de": "Nur offline", "fr": "Hors ligne uniquement", "it": "Solo offline", "pt": "Somente offline", "zh": "仅离线", "ja": "オフラインのみ", "ko": "오프라인 전용", "tr": "Yalnızca çevrimdışı", "uk": "Лише офлайн"],
        "offline.only.caption": ["ru": "Google отключён, текст не отправляется в интернет", "en": "Google is disabled; text is not sent online", "es": "Google está desactivado; el texto no se envía a internet", "de": "Google ist deaktiviert; Text wird nicht online gesendet", "fr": "Google est désactivé ; le texte n’est pas envoyé en ligne", "it": "Google è disattivato; il testo non viene inviato online", "pt": "Google desativado; o texto não é enviado online", "zh": "Google 已关闭，文本不会发送到网络", "ja": "Googleは無効、テキストはオンライン送信されません", "ko": "Google 비활성화, 텍스트를 온라인으로 보내지 않음", "tr": "Google kapalı; metin internete gönderilmez", "uk": "Google вимкнено, текст не надсилається в інтернет"],
        "launch.login": ["ru": "Запускать при входе в систему", "en": "Launch at login", "es": "Abrir al iniciar sesión", "de": "Beim Anmelden starten", "fr": "Ouvrir à la connexion", "it": "Avvia al login", "pt": "Abrir ao iniciar sessão", "zh": "登录时启动", "ja": "ログイン時に起動", "ko": "로그인 시 실행", "tr": "Girişte başlat", "uk": "Запускати при вході в систему"],
        "version.footer": ["ru": "Переводчик 1.0 · Google (онлайн) + Apple Translation (офлайн)", "en": "Translator 1.0 · Google (online) + Apple Translation (offline)", "es": "Traductor 1.0 · Google (en línea) + Apple Translation (sin conexión)", "de": "Übersetzer 1.0 · Google (online) + Apple Translation (offline)", "fr": "Traducteur 1.0 · Google (en ligne) + Apple Translation (hors ligne)", "it": "Traduttore 1.0 · Google (online) + Apple Translation (offline)", "pt": "Tradutor 1.0 · Google (online) + Apple Translation (offline)", "zh": "翻译器 1.0 · Google（在线）+ Apple Translation（离线）", "ja": "翻訳 1.0 · Google（オンライン）+ Apple Translation（オフライン）", "ko": "번역기 1.0 · Google(온라인) + Apple Translation(오프라인)", "tr": "Çevirmen 1.0 · Google (çevrimiçi) + Apple Translation (çevrimdışı)", "uk": "Перекладач 1.0 · Google (онлайн) + Apple Translation (офлайн)"],
        "check.version": ["ru": "Проверить версию", "en": "Check version", "es": "Comprobar versión", "de": "Version prüfen", "fr": "Vérifier la version", "it": "Controlla versione", "pt": "Verificar versão", "zh": "检查版本", "ja": "バージョン確認", "ko": "버전 확인", "tr": "Sürümü kontrol et", "uk": "Перевірити версію"],
        "checking": ["ru": "Проверяю…", "en": "Checking…", "es": "Comprobando…", "de": "Prüfe…", "fr": "Vérification…", "it": "Controllo…", "pt": "Verificando…", "zh": "正在检查…", "ja": "確認中…", "ko": "확인 중…", "tr": "Kontrol ediliyor…", "uk": "Перевіряю…"],
        "check": ["ru": "Проверить", "en": "Check", "es": "Comprobar", "de": "Prüfen", "fr": "Vérifier", "it": "Controlla", "pt": "Verificar", "zh": "检查", "ja": "確認", "ko": "확인", "tr": "Kontrol et", "uk": "Перевірити"],
        "update.caption": ["ru": "Проверка выполняется только вручную и использует URL релизов из Info.plist", "en": "Manual only; uses the releases URL from Info.plist", "es": "Solo manual; usa el URL de releases de Info.plist", "de": "Nur manuell; nutzt die Release-URL aus Info.plist", "fr": "Manuel uniquement ; utilise l’URL des releases dans Info.plist", "it": "Solo manuale; usa l’URL release da Info.plist", "pt": "Somente manual; usa a URL de releases do Info.plist", "zh": "仅手动检查；使用 Info.plist 中的发布 URL", "ja": "手動のみ。Info.plistのリリースURLを使用", "ko": "수동 전용; Info.plist의 릴리스 URL 사용", "tr": "Yalnızca elle; Info.plist release URL kullanılır", "uk": "Лише вручну; використовує URL релізів з Info.plist"],
        "panel.compact": ["ru": "Компактная", "en": "Compact", "es": "Compacta", "de": "Kompakt", "fr": "Compact", "it": "Compatta", "pt": "Compacta", "zh": "紧凑", "ja": "コンパクト", "ko": "컴팩트", "tr": "Kompakt", "uk": "Компактна"],
        "panel.standard": ["ru": "Стандартная", "en": "Standard", "es": "Estándar", "de": "Standard", "fr": "Standard", "it": "Standard", "pt": "Padrão", "zh": "标准", "ja": "標準", "ko": "표준", "tr": "Standart", "uk": "Стандартна"],
        "panel.wide": ["ru": "Широкая", "en": "Wide", "es": "Amplia", "de": "Breit", "fr": "Large", "it": "Ampia", "pt": "Larga", "zh": "宽", "ja": "ワイド", "ko": "넓게", "tr": "Geniş", "uk": "Широка"],
        "panel.compact.caption": ["ru": "быстрый перевод", "en": "quick translation", "es": "traducción rápida", "de": "schnelle Übersetzung", "fr": "traduction rapide", "it": "traduzione rapida", "pt": "tradução rápida", "zh": "快速翻译", "ja": "素早い翻訳", "ko": "빠른 번역", "tr": "hızlı çeviri", "uk": "швидкий переклад"],
        "panel.standard.caption": ["ru": "баланс места и чтения", "en": "balanced size and reading", "es": "equilibrio de espacio y lectura", "de": "Balance aus Platz und Lesen", "fr": "équilibre entre espace et lecture", "it": "spazio e lettura bilanciati", "pt": "equilíbrio entre espaço e leitura", "zh": "空间和阅读平衡", "ja": "サイズと読みやすさのバランス", "ko": "공간과 읽기 균형", "tr": "alan ve okuma dengesi", "uk": "баланс місця і читання"],
        "panel.wide.caption": ["ru": "длинные фразы и абзацы", "en": "long phrases and paragraphs", "es": "frases y párrafos largos", "de": "lange Sätze und Absätze", "fr": "phrases et paragraphes longs", "it": "frasi e paragrafi lunghi", "pt": "frases e parágrafos longos", "zh": "长句和段落", "ja": "長い文と段落", "ko": "긴 문장과 단락", "tr": "uzun ifadeler ve paragraflar", "uk": "довгі фрази й абзаци"],
        "first.title": ["ru": "Первый запуск", "en": "First launch", "es": "Primer inicio", "de": "Erster Start", "fr": "Premier lancement", "it": "Primo avvio", "pt": "Primeira abertura", "zh": "首次启动", "ja": "初回起動", "ko": "첫 실행", "tr": "İlk açılış", "uk": "Перший запуск"],
        "first.subtitle": ["ru": "настройте переводчик под свою работу", "en": "set up the translator for your workflow", "es": "configura el traductor para tu trabajo", "de": "Übersetzer für deinen Workflow einrichten", "fr": "configurez le traducteur pour votre usage", "it": "configura il traduttore per il tuo flusso", "pt": "configure o tradutor para seu fluxo", "zh": "按你的工作方式设置翻译器", "ja": "作業に合わせて翻訳を設定", "ko": "작업 방식에 맞게 번역기 설정", "tr": "çevirmeni çalışma düzenine göre ayarla", "uk": "налаштуйте перекладач під свою роботу"],
        "selected.text": ["ru": "Выделенный текст", "en": "Selected text", "es": "Texto seleccionado", "de": "Markierter Text", "fr": "Texte sélectionné", "it": "Testo selezionato", "pt": "Texto selecionado", "zh": "所选文本", "ja": "選択テキスト", "ko": "선택한 텍스트", "tr": "Seçili metin", "uk": "Виділений текст"],
        "access.granted": ["ru": "Доступ «Универсальный доступ» выдан", "en": "Accessibility access granted", "es": "Acceso de accesibilidad concedido", "de": "Bedienungshilfen-Zugriff gewährt", "fr": "Accès Accessibilité accordé", "it": "Accesso Accessibilità concesso", "pt": "Acesso de acessibilidade concedido", "zh": "已授予辅助功能权限", "ja": "アクセシビリティ権限が許可済み", "ko": "손쉬운 사용 권한 허용됨", "tr": "Erişilebilirlik izni verildi", "uk": "Доступ «Універсальний доступ» надано"],
        "access.needed": ["ru": "Для хоткея ⌃⌥T нужен «Универсальный доступ»", "en": "The ⌃⌥T hotkey needs Accessibility", "es": "El atajo ⌃⌥T necesita accesibilidad", "de": "⌃⌥T benötigt Bedienungshilfen", "fr": "Le raccourci ⌃⌥T nécessite Accessibilité", "it": "La scorciatoia ⌃⌥T richiede Accessibilità", "pt": "O atalho ⌃⌥T precisa de acessibilidade", "zh": "⌃⌥T 快捷键需要辅助功能权限", "ja": "⌃⌥Tにはアクセシビリティ権限が必要", "ko": "⌃⌥T 단축키에는 손쉬운 사용 권한이 필요", "tr": "⌃⌥T kısayolu Erişilebilirlik ister", "uk": "Для ⌃⌥T потрібен «Універсальний доступ»"],
        "grant.access": ["ru": "Выдать доступ…", "en": "Grant access…", "es": "Dar acceso…", "de": "Zugriff erlauben…", "fr": "Accorder l’accès…", "it": "Concedi accesso…", "pt": "Conceder acesso…", "zh": "授予权限…", "ja": "アクセスを許可…", "ko": "권한 부여…", "tr": "Erişim ver…", "uk": "Надати доступ…"],
        "offline.download.caption": ["ru": "Скачайте нужные пары для перевода без интернета", "en": "Download needed pairs for translation without internet", "es": "Descarga pares necesarios para traducir sin internet", "de": "Benötigte Paare für Übersetzung ohne Internet laden", "fr": "Téléchargez les paires pour traduire sans internet", "it": "Scarica le coppie necessarie per tradurre senza internet", "pt": "Baixe pares necessários para traduzir sem internet", "zh": "下载所需语言对以便离线翻译", "ja": "オフライン翻訳に必要なペアをダウンロード", "ko": "오프라인 번역에 필요한 언어 쌍 다운로드", "tr": "İnternetsiz çeviri için gerekli çiftleri indir", "uk": "Завантажте потрібні пари для перекладу без інтернету"],
        "open": ["ru": "Открыть…", "en": "Open…", "es": "Abrir…", "de": "Öffnen…", "fr": "Ouvrir…", "it": "Apri…", "pt": "Abrir…", "zh": "打开…", "ja": "開く…", "ko": "열기…", "tr": "Aç…", "uk": "Відкрити…"],
        "downloaded": ["ru": "скачан", "en": "downloaded", "es": "descargado", "de": "geladen", "fr": "téléchargé", "it": "scaricato", "pt": "baixado", "zh": "已下载", "ja": "ダウンロード済み", "ko": "다운로드됨", "tr": "indirildi", "uk": "завантажено"],
        "unsupported": ["ru": "недоступен", "en": "unsupported", "es": "no disponible", "de": "nicht verfügbar", "fr": "indisponible", "it": "non disponibile", "pt": "indisponível", "zh": "不支持", "ja": "非対応", "ko": "지원 안 됨", "tr": "desteklenmiyor", "uk": "недоступно"],
        "download": ["ru": "Скачать", "en": "Download", "es": "Descargar", "de": "Laden", "fr": "Télécharger", "it": "Scarica", "pt": "Baixar", "zh": "下载", "ja": "ダウンロード", "ko": "다운로드", "tr": "İndir", "uk": "Завантажити"],
        "update": ["ru": "Обновить", "en": "Update", "es": "Actualizar", "de": "Aktualisieren", "fr": "Mettre à jour", "it": "Aggiorna", "pt": "Atualizar", "zh": "更新", "ja": "更新", "ko": "업데이트", "tr": "Güncelle", "uk": "Оновити"],
        "close": ["ru": "Закрыть", "en": "Close", "es": "Cerrar", "de": "Schließen", "fr": "Fermer", "it": "Chiudi", "pt": "Fechar", "zh": "关闭", "ja": "閉じる", "ko": "닫기", "tr": "Kapat", "uk": "Закрити"],
        "done": ["ru": "Готово", "en": "Done", "es": "Listo", "de": "Fertig", "fr": "Terminé", "it": "Fine", "pt": "Pronto", "zh": "完成", "ja": "完了", "ko": "완료", "tr": "Bitti", "uk": "Готово"]
    ]
}

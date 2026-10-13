import { getPrefs, usePrefs, type Language } from './prefs';

/*
 * The app's words in six languages, chosen in Settings › Language. These are the menus, buttons and
 * labels; the hymns, their titles and the stories behind them are in English.
 * t('key', { n: 5 }) fills {n}. A key missing in a language falls back to English.
 */

const en = {
  'tab.hymnal': 'Hymnal',
  'tab.discover': 'Discover',
  'tab.favourites': 'Favourites',
  'tab.settings': 'Settings',

  'home.subtitle': 'Seventh-day Adventist Hymnal',
  'home.search': 'Number, title or first line',
  'home.searchLabel': 'Search the hymnal',
  'home.recent': 'Recently opened',
  'home.favourites': 'Favourites',
  'home.openHymn': 'Open hymn {n}',
  'home.noMatch': 'No hymn matches',
  'home.elsewhere': 'By writer or first line',
  'home.footer': 'Numbered as in the Seventh-day Adventist Hymnal (1985)',
  'home.goTo': 'Go to hymn number',

  'hymn.back': 'Back',
  'hymn.like': 'Add to favourites',
  'hymn.unlike': 'Remove from favourites',
  'hymn.liked': 'Added to favourites',
  'hymn.unliked': 'Removed from favourites',
  'hymn.share': 'Share',
  'hymn.smaller': 'Smaller text',
  'hymn.larger': 'Larger text',
  'hymn.refrain': 'Refrain',
  'hymn.noWords': "The words of this hymn are under copyright, so they aren't in the app. You'll find them in the printed hymnal at number {n}.",
  'hymn.hymnary': 'See it on Hymnary.org',
  'hymn.goTo': 'Hymn {n}. Go to another number',
  'hymn.prev': 'Previous hymn',
  'hymn.next': 'Next hymn',
  'hymn.story': 'The story behind it',

  'share.hymn': 'Share hymn {n}',
  'share.verse': 'Share verse {n}',
  'share.refrain': 'Share the refrain',
  'share.picture': 'Share as a picture',
  'share.pictureSub': 'With the first verse',
  'share.words': 'Share the words',
  'share.copy': 'Copy the words',
  'share.link': 'Copy link to Hymnary.org',
  'share.linkSub': 'Its number, title and a link',
  'share.copied': 'Copied',
  'share.linkCopied': 'Link copied',
  'share.failed': "Couldn't make the picture",
  'share.unavailable': "Sharing isn't available here",

  'number.title': 'Go to hymn',
  'number.range': '1 to {n}',
  'number.open': 'Open',
  'number.openN': 'Open hymn {n}',
  'number.delete': 'Delete',

  'discover.title': 'Discover',
  'discover.morning': 'Good morning',
  'discover.afternoon': 'Good afternoon',
  'discover.evening': 'Good evening',
  'discover.sabbath': 'Happy Sabbath',
  'discover.shuffle': 'Show other hymns',
  'discover.today': 'Hymn of the day',
  'discover.sing': 'Sing',
  'discover.story': 'The story behind the hymn',
  'discover.readHymn': 'Open hymn {n}',
  'discover.writer': 'Meet the writer',
  'discover.writerCount': '{n} hymns in the book',
  'discover.forMorning': 'For the morning',
  'discover.forEvening': 'For the evening',
  'discover.forSabbath': 'For the Sabbath',
  'discover.forPraise': 'Songs of praise',
  'discover.browse': 'Browse by topic',
  'discover.range': 'Hymns {a}–{b}',
  'discover.topics': '{n} topics',

  'fav.title': 'Favourites',
  'fav.edit': 'Edit',
  'fav.done': 'Done',
  'fav.remove': 'Remove',
  'fav.removeAll': 'Remove all',
  'fav.cleared': 'Favourites cleared',
  'fav.emptyTitle': 'No favourites yet',
  'fav.emptyBody': 'Tap the heart on a hymn to keep it here.',
  'fav.browse': 'Browse the hymnal',
  'fav.byNumber': 'By number',
  'fav.byAdded': 'Recently added',

  'settings.title': 'Settings',
  'settings.appearance': 'Appearance',
  'settings.language': 'Language',
  'settings.favourites': 'Favourites',
  'settings.share': 'Share this app',
  'settings.shareMessage': 'SDA Hymnal: all {n} hymns of the Seventh-day Adventist Hymnal, on your phone and offline.',
  'settings.rate': 'Rate this app',
  'settings.rateFailed': "The App Store can't be opened here",
  'settings.about': 'About',
  'settings.credits': 'Licences and credits',
  'settings.system': 'System',
  'settings.light': 'Light',
  'settings.dark': 'Dark',
  'settings.systemSub': "Follows your phone's light or dark setting",
  'settings.languageSub': "Menus and buttons change language. The hymns and their stories are in English.",

  'about.version': 'Version {v}',
  'about.hymns': 'Hymns',
  'about.words': 'With words in the app',
  'about.offline': 'Works offline',
  'about.yes': 'Yes',

  'credits.hymns': 'Hymns',
  'credits.hymnsBody': 'Hymns are numbered as in the Seventh-day Adventist Hymnal (1985). The app shows the words of hymns in the public domain; for the rest it shows the title and writer and links to Hymnary.org. Tunes and arrangements belong to their publishers.',
  'credits.photos': 'Photos',
  'credits.photosBody': 'Photographs by David Beale, Kelly Sikkema, Sven Pieren, Tim Wildsmith, Kyler Nixon, Mateus Campos Felipe, khampha phimmachak, Aaron Burden and Cathryn Lavery.',
  'credits.fonts': 'Fonts',
  'credits.logo': 'Logo',
  'credits.logoBody': 'The Seventh-day Adventist logo is a trademark of the General Conference of Seventh-day Adventists.',

  'part.range': 'Hymns {a}–{b}',
  'common.close': 'Close',
  'common.clear': 'Clear',
} as const;

export type Key = keyof typeof en;
type Dict = Partial<Record<Key, string>>;

const es: Dict = {
  'tab.hymnal': 'Himnario', 'tab.discover': 'Descubrir', 'tab.favourites': 'Favoritos', 'tab.settings': 'Ajustes',
  'home.subtitle': 'Himnario Adventista del Séptimo Día', 'home.search': 'Número, título o primera línea', 'home.searchLabel': 'Buscar en el himnario', 'home.recent': 'Abiertos recientemente', 'home.favourites': 'Favoritos', 'home.openHymn': 'Abrir himno {n}', 'home.noMatch': 'Ningún himno coincide', 'home.elsewhere': 'Por autor o primera línea', 'home.footer': 'Numerados como en el himnario adventista en inglés (1985)', 'home.goTo': 'Ir al número de himno',
  'hymn.back': 'Atrás', 'hymn.like': 'Añadir a favoritos', 'hymn.unlike': 'Quitar de favoritos', 'hymn.liked': 'Añadido a favoritos', 'hymn.unliked': 'Quitado de favoritos', 'hymn.share': 'Compartir', 'hymn.smaller': 'Texto más pequeño', 'hymn.larger': 'Texto más grande', 'hymn.refrain': 'Coro', 'hymn.noWords': 'La letra de este himno tiene derechos de autor, así que no está en la app. La encontrará en el himnario impreso, número {n}.', 'hymn.hymnary': 'Verlo en Hymnary.org', 'hymn.goTo': 'Himno {n}. Ir a otro número', 'hymn.prev': 'Himno anterior', 'hymn.next': 'Himno siguiente', 'hymn.story': 'La historia del himno',
  'share.hymn': 'Compartir himno {n}', 'share.verse': 'Compartir estrofa {n}', 'share.refrain': 'Compartir el coro', 'share.picture': 'Compartir como imagen', 'share.pictureSub': 'Con la primera estrofa', 'share.words': 'Compartir la letra', 'share.copy': 'Copiar la letra', 'share.link': 'Copiar enlace a Hymnary.org', 'share.linkSub': 'Su número, título y un enlace', 'share.copied': 'Copiado', 'share.linkCopied': 'Enlace copiado', 'share.failed': 'No se pudo crear la imagen', 'share.unavailable': 'No se puede compartir aquí',
  'number.title': 'Ir al himno', 'number.range': 'Del 1 al {n}', 'number.open': 'Abrir', 'number.openN': 'Abrir himno {n}', 'number.delete': 'Borrar',
  'discover.title': 'Descubrir', 'discover.morning': 'Buenos días', 'discover.afternoon': 'Buenas tardes', 'discover.evening': 'Buenas noches', 'discover.sabbath': 'Feliz sábado', 'discover.shuffle': 'Ver otros himnos', 'discover.today': 'Himno del día', 'discover.sing': 'Cantar', 'discover.story': 'La historia del himno', 'discover.readHymn': 'Abrir himno {n}', 'discover.writer': 'Conozca al autor', 'discover.writerCount': '{n} himnos en el libro', 'discover.forMorning': 'Para la mañana', 'discover.forEvening': 'Para la tarde', 'discover.forSabbath': 'Para el sábado', 'discover.forPraise': 'Himnos de alabanza', 'discover.browse': 'Por tema', 'discover.range': 'Himnos {a}–{b}', 'discover.topics': '{n} temas',
  'fav.title': 'Favoritos', 'fav.edit': 'Editar', 'fav.done': 'Listo', 'fav.remove': 'Quitar', 'fav.removeAll': 'Quitar todos', 'fav.cleared': 'Favoritos borrados', 'fav.emptyTitle': 'Aún no hay favoritos', 'fav.emptyBody': 'Toque el corazón de un himno para guardarlo aquí.', 'fav.browse': 'Ver el himnario', 'fav.byNumber': 'Por número', 'fav.byAdded': 'Añadidos recientemente',
  'settings.title': 'Ajustes', 'settings.appearance': 'Apariencia', 'settings.language': 'Idioma', 'settings.favourites': 'Favoritos', 'settings.share': 'Compartir esta app', 'settings.shareMessage': 'SDA Hymnal: los {n} himnos del himnario adventista, en su teléfono y sin conexión.', 'settings.rate': 'Valorar esta app', 'settings.rateFailed': 'No se puede abrir la App Store aquí', 'settings.about': 'Acerca de', 'settings.credits': 'Licencias y créditos', 'settings.system': 'Sistema', 'settings.light': 'Claro', 'settings.dark': 'Oscuro', 'settings.systemSub': 'Sigue el modo claro u oscuro del teléfono', 'settings.languageSub': 'Los menús y botones cambian de idioma. Los himnos y sus historias están en inglés.',
  'about.version': 'Versión {v}', 'about.hymns': 'Himnos', 'about.words': 'Con letra en la app', 'about.offline': 'Funciona sin conexión', 'about.yes': 'Sí',
  'credits.hymns': 'Himnos', 'credits.photos': 'Fotos', 'credits.fonts': 'Tipografías', 'credits.logo': 'Logotipo', 'part.range': 'Himnos {a}–{b}', 'common.close': 'Cerrar', 'common.clear': 'Borrar',
};

const fr: Dict = {
  'tab.hymnal': 'Recueil', 'tab.discover': 'Découvrir', 'tab.favourites': 'Favoris', 'tab.settings': 'Réglages',
  'home.subtitle': 'Recueil de cantiques adventiste', 'home.search': 'Numéro, titre ou premier vers', 'home.searchLabel': 'Chercher dans le recueil', 'home.recent': 'Ouverts récemment', 'home.favourites': 'Favoris', 'home.openHymn': 'Ouvrir le cantique {n}', 'home.noMatch': 'Aucun cantique ne correspond', 'home.elsewhere': 'Par auteur ou premier vers', 'home.footer': 'Numérotés comme dans le recueil adventiste anglais (1985)', 'home.goTo': 'Aller à un numéro',
  'hymn.back': 'Retour', 'hymn.like': 'Ajouter aux favoris', 'hymn.unlike': 'Retirer des favoris', 'hymn.liked': 'Ajouté aux favoris', 'hymn.unliked': 'Retiré des favoris', 'hymn.share': 'Partager', 'hymn.smaller': 'Texte plus petit', 'hymn.larger': 'Texte plus grand', 'hymn.refrain': 'Refrain', 'hymn.noWords': "Les paroles de ce cantique sont protégées par le droit d'auteur et ne figurent donc pas dans l'app. Vous les trouverez dans le recueil imprimé, au numéro {n}.", 'hymn.hymnary': 'Voir sur Hymnary.org', 'hymn.goTo': 'Cantique {n}. Aller à un autre numéro', 'hymn.prev': 'Cantique précédent', 'hymn.next': 'Cantique suivant', 'hymn.story': "L'histoire du cantique",
  'share.hymn': 'Partager le cantique {n}', 'share.verse': 'Partager la strophe {n}', 'share.refrain': 'Partager le refrain', 'share.picture': 'Partager en image', 'share.pictureSub': 'Avec la première strophe', 'share.words': 'Partager les paroles', 'share.copy': 'Copier les paroles', 'share.link': 'Copier le lien Hymnary.org', 'share.linkSub': 'Son numéro, son titre et un lien', 'share.copied': 'Copié', 'share.linkCopied': 'Lien copié', 'share.failed': "Impossible de créer l'image", 'share.unavailable': 'Partage indisponible ici',
  'number.title': 'Aller au cantique', 'number.range': 'De 1 à {n}', 'number.open': 'Ouvrir', 'number.openN': 'Ouvrir le cantique {n}', 'number.delete': 'Effacer',
  'discover.title': 'Découvrir', 'discover.morning': 'Bonjour', 'discover.afternoon': 'Bon après-midi', 'discover.evening': 'Bonsoir', 'discover.sabbath': 'Joyeux sabbat', 'discover.shuffle': "Voir d'autres cantiques", 'discover.today': 'Cantique du jour', 'discover.sing': 'Chanter', 'discover.story': "L'histoire du cantique", 'discover.readHymn': 'Ouvrir le cantique {n}', 'discover.writer': "À la rencontre de l'auteur", 'discover.writerCount': '{n} cantiques dans le recueil', 'discover.forMorning': 'Pour le matin', 'discover.forEvening': 'Pour le soir', 'discover.forSabbath': 'Pour le sabbat', 'discover.forPraise': 'Chants de louange', 'discover.browse': 'Par thème', 'discover.range': 'Cantiques {a}–{b}', 'discover.topics': '{n} thèmes',
  'fav.title': 'Favoris', 'fav.edit': 'Modifier', 'fav.done': 'OK', 'fav.remove': 'Retirer', 'fav.removeAll': 'Tout retirer', 'fav.cleared': 'Favoris effacés', 'fav.emptyTitle': 'Pas encore de favoris', 'fav.emptyBody': 'Touchez le cœur sur un cantique pour le garder ici.', 'fav.browse': 'Parcourir le recueil', 'fav.byNumber': 'Par numéro', 'fav.byAdded': 'Ajoutés récemment',
  'settings.title': 'Réglages', 'settings.appearance': 'Apparence', 'settings.language': 'Langue', 'settings.favourites': 'Favoris', 'settings.share': "Partager l'app", 'settings.shareMessage': 'SDA Hymnal : les {n} cantiques du recueil adventiste, sur votre téléphone et hors ligne.', 'settings.rate': "Noter l'app", 'settings.rateFailed': "L'App Store ne peut pas s'ouvrir ici", 'settings.about': 'À propos', 'settings.credits': 'Licences et crédits', 'settings.system': 'Système', 'settings.light': 'Clair', 'settings.dark': 'Sombre', 'settings.systemSub': 'Suit le mode clair ou sombre du téléphone', 'settings.languageSub': 'Les menus et boutons changent de langue. Les cantiques et leurs histoires sont en anglais.',
  'about.version': 'Version {v}', 'about.hymns': 'Cantiques', 'about.words': "Avec les paroles dans l'app", 'about.offline': 'Fonctionne hors ligne', 'about.yes': 'Oui',
  'credits.hymns': 'Cantiques', 'credits.photos': 'Photos', 'credits.fonts': 'Polices', 'credits.logo': 'Logo', 'part.range': 'Cantiques {a}–{b}', 'common.close': 'Fermer', 'common.clear': 'Effacer',
};

const pt: Dict = {
  'tab.hymnal': 'Hinário', 'tab.discover': 'Descobrir', 'tab.favourites': 'Favoritos', 'tab.settings': 'Ajustes',
  'home.subtitle': 'Hinário Adventista do Sétimo Dia', 'home.search': 'Número, título ou primeira linha', 'home.searchLabel': 'Pesquisar no hinário', 'home.recent': 'Abertos recentemente', 'home.favourites': 'Favoritos', 'home.openHymn': 'Abrir hino {n}', 'home.noMatch': 'Nenhum hino encontrado', 'home.elsewhere': 'Por autor ou primeira linha', 'home.footer': 'Numerados como no hinário adventista em inglês (1985)', 'home.goTo': 'Ir para o número do hino',
  'hymn.back': 'Voltar', 'hymn.like': 'Adicionar aos favoritos', 'hymn.unlike': 'Remover dos favoritos', 'hymn.liked': 'Adicionado aos favoritos', 'hymn.unliked': 'Removido dos favoritos', 'hymn.share': 'Partilhar', 'hymn.smaller': 'Texto menor', 'hymn.larger': 'Texto maior', 'hymn.refrain': 'Coro', 'hymn.noWords': 'A letra deste hino tem direitos de autor, por isso não está no app. Pode encontrá-la no hinário impresso, número {n}.', 'hymn.hymnary': 'Ver no Hymnary.org', 'hymn.goTo': 'Hino {n}. Ir para outro número', 'hymn.prev': 'Hino anterior', 'hymn.next': 'Próximo hino', 'hymn.story': 'A história do hino',
  'share.hymn': 'Partilhar hino {n}', 'share.verse': 'Partilhar estrofe {n}', 'share.refrain': 'Partilhar o coro', 'share.picture': 'Partilhar como imagem', 'share.pictureSub': 'Com a primeira estrofe', 'share.words': 'Partilhar a letra', 'share.copy': 'Copiar a letra', 'share.link': 'Copiar link do Hymnary.org', 'share.linkSub': 'O número, o título e um link', 'share.copied': 'Copiado', 'share.linkCopied': 'Link copiado', 'share.failed': 'Não foi possível criar a imagem', 'share.unavailable': 'Não é possível partilhar aqui',
  'number.title': 'Ir para o hino', 'number.range': 'De 1 a {n}', 'number.open': 'Abrir', 'number.openN': 'Abrir hino {n}', 'number.delete': 'Apagar',
  'discover.title': 'Descobrir', 'discover.morning': 'Bom dia', 'discover.afternoon': 'Boa tarde', 'discover.evening': 'Boa noite', 'discover.sabbath': 'Feliz sábado', 'discover.shuffle': 'Ver outros hinos', 'discover.today': 'Hino do dia', 'discover.sing': 'Cantar', 'discover.story': 'A história do hino', 'discover.readHymn': 'Abrir hino {n}', 'discover.writer': 'Conheça o autor', 'discover.writerCount': '{n} hinos no livro', 'discover.forMorning': 'Para a manhã', 'discover.forEvening': 'Para a noite', 'discover.forSabbath': 'Para o sábado', 'discover.forPraise': 'Hinos de louvor', 'discover.browse': 'Por tema', 'discover.range': 'Hinos {a}–{b}', 'discover.topics': '{n} temas',
  'fav.title': 'Favoritos', 'fav.edit': 'Editar', 'fav.done': 'OK', 'fav.remove': 'Remover', 'fav.removeAll': 'Remover todos', 'fav.cleared': 'Favoritos apagados', 'fav.emptyTitle': 'Ainda sem favoritos', 'fav.emptyBody': 'Toque no coração de um hino para o guardar aqui.', 'fav.browse': 'Ver o hinário', 'fav.byNumber': 'Por número', 'fav.byAdded': 'Adicionados recentemente',
  'settings.title': 'Ajustes', 'settings.appearance': 'Aparência', 'settings.language': 'Idioma', 'settings.favourites': 'Favoritos', 'settings.share': 'Partilhar este app', 'settings.shareMessage': 'SDA Hymnal: os {n} hinos do hinário adventista, no seu telemóvel e sem internet.', 'settings.rate': 'Avaliar este app', 'settings.rateFailed': 'Não é possível abrir a App Store aqui', 'settings.about': 'Sobre', 'settings.credits': 'Licenças e créditos', 'settings.system': 'Sistema', 'settings.light': 'Claro', 'settings.dark': 'Escuro', 'settings.systemSub': 'Segue o modo claro ou escuro do telefone', 'settings.languageSub': 'Os menus e botões mudam de idioma. Os hinos e as suas histórias estão em inglês.',
  'about.version': 'Versão {v}', 'about.hymns': 'Hinos', 'about.words': 'Com letra no app', 'about.offline': 'Funciona sem internet', 'about.yes': 'Sim',
  'credits.hymns': 'Hinos', 'credits.photos': 'Fotos', 'credits.fonts': 'Tipos de letra', 'credits.logo': 'Logótipo', 'part.range': 'Hinos {a}–{b}', 'common.close': 'Fechar', 'common.clear': 'Apagar',
};

const de: Dict = {
  'tab.hymnal': 'Gesangbuch', 'tab.discover': 'Entdecken', 'tab.favourites': 'Favoriten', 'tab.settings': 'Einstellungen',
  'home.subtitle': 'Adventistisches Gesangbuch', 'home.search': 'Nummer, Titel oder erste Zeile', 'home.searchLabel': 'Im Gesangbuch suchen', 'home.recent': 'Zuletzt geöffnet', 'home.favourites': 'Favoriten', 'home.openHymn': 'Lied {n} öffnen', 'home.noMatch': 'Kein passendes Lied', 'home.elsewhere': 'Nach Verfasser oder erster Zeile', 'home.footer': 'Nummeriert wie im englischen adventistischen Gesangbuch (1985)', 'home.goTo': 'Zu einer Liednummer',
  'hymn.back': 'Zurück', 'hymn.like': 'Zu Favoriten hinzufügen', 'hymn.unlike': 'Aus Favoriten entfernen', 'hymn.liked': 'Zu Favoriten hinzugefügt', 'hymn.unliked': 'Aus Favoriten entfernt', 'hymn.share': 'Teilen', 'hymn.smaller': 'Kleinere Schrift', 'hymn.larger': 'Größere Schrift', 'hymn.refrain': 'Refrain', 'hymn.noWords': 'Der Text dieses Liedes ist urheberrechtlich geschützt und daher nicht in der App. Sie finden ihn im gedruckten Gesangbuch unter Nummer {n}.', 'hymn.hymnary': 'Auf Hymnary.org ansehen', 'hymn.goTo': 'Lied {n}. Zu einer anderen Nummer', 'hymn.prev': 'Vorheriges Lied', 'hymn.next': 'Nächstes Lied', 'hymn.story': 'Die Geschichte des Liedes',
  'share.hymn': 'Lied {n} teilen', 'share.verse': 'Strophe {n} teilen', 'share.refrain': 'Refrain teilen', 'share.picture': 'Als Bild teilen', 'share.pictureSub': 'Mit der ersten Strophe', 'share.words': 'Text teilen', 'share.copy': 'Text kopieren', 'share.link': 'Link zu Hymnary.org kopieren', 'share.linkSub': 'Nummer, Titel und ein Link', 'share.copied': 'Kopiert', 'share.linkCopied': 'Link kopiert', 'share.failed': 'Das Bild konnte nicht erstellt werden', 'share.unavailable': 'Teilen ist hier nicht möglich',
  'number.title': 'Zum Lied', 'number.range': '1 bis {n}', 'number.open': 'Öffnen', 'number.openN': 'Lied {n} öffnen', 'number.delete': 'Löschen',
  'discover.title': 'Entdecken', 'discover.morning': 'Guten Morgen', 'discover.afternoon': 'Guten Tag', 'discover.evening': 'Guten Abend', 'discover.sabbath': 'Gesegneten Sabbat', 'discover.shuffle': 'Andere Lieder zeigen', 'discover.today': 'Lied des Tages', 'discover.sing': 'Singen', 'discover.story': 'Die Geschichte des Liedes', 'discover.readHymn': 'Lied {n} öffnen', 'discover.writer': 'Der Verfasser', 'discover.writerCount': '{n} Lieder im Buch', 'discover.forMorning': 'Für den Morgen', 'discover.forEvening': 'Für den Abend', 'discover.forSabbath': 'Für den Sabbat', 'discover.forPraise': 'Loblieder', 'discover.browse': 'Nach Thema', 'discover.range': 'Lieder {a}–{b}', 'discover.topics': '{n} Themen',
  'fav.title': 'Favoriten', 'fav.edit': 'Bearbeiten', 'fav.done': 'Fertig', 'fav.remove': 'Entfernen', 'fav.removeAll': 'Alle entfernen', 'fav.cleared': 'Favoriten gelöscht', 'fav.emptyTitle': 'Noch keine Favoriten', 'fav.emptyBody': 'Tippen Sie bei einem Lied auf das Herz, um es hier zu behalten.', 'fav.browse': 'Gesangbuch ansehen', 'fav.byNumber': 'Nach Nummer', 'fav.byAdded': 'Zuletzt hinzugefügt',
  'settings.title': 'Einstellungen', 'settings.appearance': 'Darstellung', 'settings.language': 'Sprache', 'settings.favourites': 'Favoriten', 'settings.share': 'App teilen', 'settings.shareMessage': 'SDA Hymnal: alle {n} Lieder des adventistischen Gesangbuchs, auf dem Handy und offline.', 'settings.rate': 'App bewerten', 'settings.rateFailed': 'Der App Store kann hier nicht geöffnet werden', 'settings.about': 'Über die App', 'settings.credits': 'Lizenzen und Danksagungen', 'settings.system': 'System', 'settings.light': 'Hell', 'settings.dark': 'Dunkel', 'settings.systemSub': 'Folgt der hellen oder dunklen Einstellung des Telefons', 'settings.languageSub': 'Menüs und Schaltflächen wechseln die Sprache. Die Lieder und ihre Geschichten sind auf Englisch.',
  'about.version': 'Version {v}', 'about.hymns': 'Lieder', 'about.words': 'Mit Text in der App', 'about.offline': 'Funktioniert offline', 'about.yes': 'Ja',
  'credits.hymns': 'Lieder', 'credits.photos': 'Fotos', 'credits.fonts': 'Schriften', 'credits.logo': 'Logo', 'part.range': 'Lieder {a}–{b}', 'common.close': 'Schließen', 'common.clear': 'Löschen',
};

const sw: Dict = {
  'tab.hymnal': 'Nyimbo', 'tab.discover': 'Gundua', 'tab.favourites': 'Pendwa', 'tab.settings': 'Mipangilio',
  'home.subtitle': 'Nyimbo za Waadventista Wasabato', 'home.search': 'Namba, kichwa au mstari wa kwanza', 'home.searchLabel': 'Tafuta wimbo', 'home.recent': 'Ulizofungua karibuni', 'home.favourites': 'Pendwa', 'home.openHymn': 'Fungua wimbo {n}', 'home.noMatch': 'Hakuna wimbo unaolingana', 'home.elsewhere': 'Kwa mtunzi au mstari wa kwanza', 'home.footer': 'Namba kama katika kitabu cha nyimbo cha Kiingereza (1985)', 'home.goTo': 'Nenda kwa namba ya wimbo',
  'hymn.back': 'Rudi', 'hymn.like': 'Weka kwenye pendwa', 'hymn.unlike': 'Ondoa kwenye pendwa', 'hymn.liked': 'Imewekwa kwenye pendwa', 'hymn.unliked': 'Imeondolewa kwenye pendwa', 'hymn.share': 'Shiriki', 'hymn.smaller': 'Maandishi madogo', 'hymn.larger': 'Maandishi makubwa', 'hymn.refrain': 'Kiitikio', 'hymn.noWords': 'Maneno ya wimbo huu yana hakimiliki, kwa hiyo hayamo kwenye programu. Utayapata kwenye kitabu cha nyimbo, namba {n}.', 'hymn.hymnary': 'Tazama kwenye Hymnary.org', 'hymn.goTo': 'Wimbo {n}. Nenda kwa namba nyingine', 'hymn.prev': 'Wimbo uliotangulia', 'hymn.next': 'Wimbo unaofuata', 'hymn.story': 'Historia ya wimbo',
  'share.hymn': 'Shiriki wimbo {n}', 'share.verse': 'Shiriki ubeti {n}', 'share.refrain': 'Shiriki kiitikio', 'share.picture': 'Shiriki kama picha', 'share.pictureSub': 'Pamoja na ubeti wa kwanza', 'share.words': 'Shiriki maneno', 'share.copy': 'Nakili maneno', 'share.link': 'Nakili kiungo cha Hymnary.org', 'share.linkSub': 'Namba, kichwa na kiungo', 'share.copied': 'Imenakiliwa', 'share.linkCopied': 'Kiungo kimenakiliwa', 'share.failed': 'Imeshindikana kutengeneza picha', 'share.unavailable': 'Kushiriki hakuwezekani hapa',
  'number.title': 'Nenda kwa wimbo', 'number.range': '1 hadi {n}', 'number.open': 'Fungua', 'number.openN': 'Fungua wimbo {n}', 'number.delete': 'Futa',
  'discover.title': 'Gundua', 'discover.morning': 'Habari za asubuhi', 'discover.afternoon': 'Habari za mchana', 'discover.evening': 'Habari za jioni', 'discover.sabbath': 'Sabato njema', 'discover.shuffle': 'Onyesha nyimbo nyingine', 'discover.today': 'Wimbo wa leo', 'discover.sing': 'Imba', 'discover.story': 'Historia ya wimbo', 'discover.readHymn': 'Fungua wimbo {n}', 'discover.writer': 'Mfahamu mtunzi', 'discover.writerCount': 'Nyimbo {n} kitabuni', 'discover.forMorning': 'Za asubuhi', 'discover.forEvening': 'Za jioni', 'discover.forSabbath': 'Za Sabato', 'discover.forPraise': 'Nyimbo za sifa', 'discover.browse': 'Kwa mada', 'discover.range': 'Nyimbo {a}–{b}', 'discover.topics': 'Mada {n}',
  'fav.title': 'Pendwa', 'fav.edit': 'Hariri', 'fav.done': 'Tayari', 'fav.remove': 'Ondoa', 'fav.removeAll': 'Ondoa zote', 'fav.cleared': 'Pendwa zimefutwa', 'fav.emptyTitle': 'Bado hakuna pendwa', 'fav.emptyBody': 'Gusa moyo kwenye wimbo ili kuuweka hapa.', 'fav.browse': 'Tazama nyimbo', 'fav.byNumber': 'Kwa namba', 'fav.byAdded': 'Zilizoongezwa karibuni',
  'settings.title': 'Mipangilio', 'settings.appearance': 'Mwonekano', 'settings.language': 'Lugha', 'settings.favourites': 'Pendwa', 'settings.share': 'Shiriki programu hii', 'settings.shareMessage': 'SDA Hymnal: nyimbo zote {n} za kitabu cha nyimbo cha Waadventista, kwenye simu yako bila intaneti.', 'settings.rate': 'Ipe programu hii alama', 'settings.rateFailed': 'App Store haiwezi kufunguliwa hapa', 'settings.about': 'Kuhusu', 'settings.credits': 'Leseni na shukrani', 'settings.system': 'Mfumo', 'settings.light': 'Mwanga', 'settings.dark': 'Giza', 'settings.systemSub': 'Hufuata mpangilio wa mwanga au giza wa simu yako', 'settings.languageSub': 'Menyu na vitufe hubadilika lugha. Nyimbo na historia zake ziko kwa Kiingereza.',
  'about.version': 'Toleo {v}', 'about.hymns': 'Nyimbo', 'about.words': 'Zenye maneno kwenye programu', 'about.offline': 'Inafanya kazi bila intaneti', 'about.yes': 'Ndiyo',
  'credits.hymns': 'Nyimbo', 'credits.photos': 'Picha', 'credits.fonts': 'Fonti', 'credits.logo': 'Nembo', 'part.range': 'Nyimbo {a}–{b}', 'common.close': 'Funga', 'common.clear': 'Futa',
};

const DICTS: Record<Language, Dict> = { en, es, fr, pt, de, sw };

/** Each language's own name, as it is shown in the Language list. */
export const LANGUAGE_NAMES: Record<Language, string> = { en: 'English', es: 'Español', fr: 'Français', pt: 'Português', de: 'Deutsch', sw: 'Kiswahili' };

export function t(key: Key, vars?: Record<string, string | number>): string {
  const text = DICTS[getPrefs().language]?.[key] ?? en[key];
  return vars ? text.replace(/\{(\w+)\}/g, (_, k) => String(vars[k] ?? '')) : text;
}

/** t(), redrawing the screen when the language changes. */
export function useT() {
  usePrefs();
  return t;
}

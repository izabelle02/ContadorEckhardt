/// Cores que o usuário pode escolher para cada evento (ARGB).
/// Todas escuras o bastante para o texto branco dos widgets ficar legível.
const eventColors = <int>[
  0xFF6750A4, // roxo
  0xFF4527A0, // roxo escuro
  0xFF8E24AA, // violeta
  0xFF3949AB, // índigo
  0xFF1E6FD9, // azul
  0xFF0D47A1, // azul-marinho
  0xFF0277BD, // azul-céu
  0xFF00838F, // ciano
  0xFF00897B, // verde-água
  0xFF2E7D32, // verde
  0xFF1B5E20, // verde-floresta
  0xFF558B2F, // verde-oliva
  0xFF9E9D24, // lima
  0xFFF9A825, // amarelo
  0xFFEF6C00, // laranja
  0xFFE64A19, // laranja-tijolo
  0xFFC62828, // vermelho
  0xFF880E4F, // vinho
  0xFFD81B60, // rosa
  0xFFEC407A, // rosa-chiclete
  0xFFAD1457, // magenta
  0xFF6D4C41, // marrom
  0xFF5D4037, // café
  0xFF546E7A, // azul-acinzentado
  0xFF37474F, // grafite
  0xFF212121, // preto
];

/// Emojis agrupados por tema, exibidos em seções no editor.
const emojiCategories = <String, List<String>>{
  'Celebração': [
    '🎉', '🎊', '🥳', '🎂', '🍰', '🎁', '🎈', '🍾',
    '🥂', '🎆', '🎇', '✨', '🪅', '🕯️',
  ],
  'Amor e família': [
    '❤️', '💕', '💖', '💍', '💒', '👰', '🤵', '💐',
    '🌹', '👶', '🍼', '👨‍👩‍👧', '🐶', '🐱',
  ],
  'Viagem': [
    '✈️', '🏖️', '🏝️', '🌴', '🗺️', '🧳', '🏔️', '⛺',
    '🚗', '🚢', '🚆', '🗽', '🗼', '🎡',
  ],
  'Datas do ano': [
    '🎄', '🎅', '🐰', '🥚', '🎃', '👻', '🦃', '🎋',
    '🎏', '🇧🇷', '🌸', '☀️', '🍂', '❄️',
  ],
  'Estudo e trabalho': [
    '🎓', '📚', '✏️', '📝', '💼', '💻', '📈', '🏢',
    '🧪', '🩺', '⚖️', '🏆', '🥇', '🎯',
  ],
  'Esporte e lazer': [
    '⚽', '🏀', '🏐', '🎾', '🏃', '🚴', '🏊', '🧘',
    '🎵', '🎸', '🎤', '🎬', '🎮', '🎨',
  ],
  'Outros': [
    '⏳', '⏰', '📅', '🏠', '🔑', '💰', '🍕', '☕',
    '🌙', '⭐', '🌈', '🔥', '🚀', '💪',
  ],
};

final eventEmojis = [for (final list in emojiCategories.values) ...list];
